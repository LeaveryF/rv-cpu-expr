# 实验二：逻辑综合

对 MiniRV CPU 前端 RTL 进行逻辑综合（Design Compiler），添加 IO PAD，生成门级网表、时序/面积/功耗报告和 SDF 文件。

## 逻辑综合核心概念

### 什么是逻辑综合

逻辑综合是将 **RTL 代码（硬件描述语言）** 自动转换为 **门级网表（标准单元实例+连线）** 的过程。综合器（DC）做三件事：

1. **翻译（Translation）**：将 RTL 转为与工艺无关的布尔逻辑表达式（GTECH 格式）
2. **优化（Optimization）**：化简逻辑、消除冗余、合并等价项
3. **映射（Mapping）**：从工艺库中选择具体的标准单元（AND2X4、DFFRXL 等），形成门级网表

### 关键概念

#### 1. 标准单元库（Standard Cell Library）

工艺厂商提供的预设计单元集合，包含：

| 内容 | 说明 |
|:---|:---|
| `.db` 文件 | 单元的时序、功耗、面积信息（DC 读这个） |
| `.v` 模型 | 单元的 Verilog 行为模型（仿真用） |
| 单元类型 | 组合逻辑（AND/OR/INV/MUX...）+ 时序逻辑（DFF/DLAT...） |
| PVT 条件 | Process (工艺角)、Voltage (电压)、Temperature (温度) |

常用 PVT corners：`typical_1v2c25`（典型值）、`slow_1v08c125`（最慢，建立时间检查）、`fast_1v32cm40`（最快，保持时间检查）。

#### 2. 时序约束（Timing Constraints）

DC 根据约束决定何时需要"更大更快"的单元。核心约束：

| 约束 | 含义 | 本实验的设置 |
|:---|:---|:---|
| `create_clock` | 定义时钟频率 | 20ns (50MHz)，端口 `clk_pad` |
| `set_clock_uncertainty` | 时钟抖动+偏差余量 | 0.2ns |
| `set_input_delay` | 芯片外的前级延迟 | 0.1ns (max) |
| `set_output_delay` | 芯片外的后级路径 | 1.0ns (max) |
| `set_driving_cell` | 输入端口的前级驱动能力 | AND2X4（最小驱动） |
| `set_load` | 输出端口的负载电容 | 15×AND2X4 输入电容 |

**关键公式**：时钟周期 ≥ 时钟 uncertainty + 输入 delay + 最长组合路径延迟 + 输出 delay + 建立时间

#### 3. Setup Time / Hold Time（建立时间 / 保持时间）

这是时序分析最基础的概念。以一个 D 触发器为例：

```
         ┌──────┐
  D ─────┤  D Q ├──── Q
         │      │
  CLK ───┤>     │
         └──────┘

            ← ts → ← th →
            ┌─────┬─────┐
  CLK       │     │     │
       ─────┘     └─────┘
            ↑     ↑
          数据必须  数据必须
          在此之前  在此之后
           稳定     稳定
```

- **Setup Time (ts, 建立时间)**：时钟有效沿**到来之前**，数据必须稳定保持的最小时间。本质是 DFF 内部传输门打开前，数据要给内部电容足够的充电时间。
  - 如果数据**到得太晚**（路径太慢）→ Setup 违例 → **频率上不去**

- **Hold Time (th, 保持时间)**：时钟有效沿**到来之后**，数据必须继续稳定的最小时间。本质是时钟沿来临时，旧数据不能被新数据太快"冲掉"。
  - 如果数据**走得太快**（路径太短）→ Hold 违例 → **芯片功能错误**（不能靠降频修复）

**通俗比喻**：你往信箱里投信：
- **Setup** = 邮递员来之前，信必须已经在信箱口准备好了
- **Hold** = 邮递员拿走信的瞬间，你不能把手抽回来（否则信跟着手回来了）

**检查公式**：

| 检查 | 公式 | 违例含义 |
|:---|:---|:---|
| Setup | Tclk ≥ ts + tpath_max + tuncertainty | 路径太长，降频或用更快的单元 |
| Hold | th ≤ tpath_min - tuncertainty | 路径太短，插 buffer 延迟数据 |

其中 tpath_max/min 是最长/最短的组合逻辑路径延迟。

#### 4. Slack = 时序余量

```
Slack = Data Required Time - Data Arrival Time
```

- **Slack > 0**：满足时序，有余量
- **Slack = 0**：刚好满足
- **Slack < 0**：时序违例！`Worst Negative Slack (WNS)` = 最差的负 slack

综合报告中最先看的就是 **Slack** 是否 ≥ 0。

#### 5. Compile 策略

| 命令 | 特点 | 适用场景 |
|:---|:---|:---|
| `compile` | 基础编译 | 老版本 DC |
| `compile_ultra` | 顶级优化（时序+面积+功耗） | 本实验使用，现代标准 |
| `compile_ultra -retime` | 含寄存器重定时 | 流水线设计 |
| `compile_ultra -spg` | 含扫描链优化 | DFT 设计 |

#### 6. PAD（IO Pad）

芯片内部逻辑与外部引脚的接口单元：
- **PI**：输入 PAD → ESD 保护 + 电平转换
- **PO8**：输出 PAD (8mA 驱动) → 驱动片外负载
- **PCORNER**：Corner cell → 保证 PAD 环的物理连续性
- **PVDD1/PVSS1**：Core 电源 PAD
- **PVDD2/PVSS2**：IO 电源 PAD

综合时 PAD 必须设为 **`dont_touch`**，因为它们是预先设计的硬核，综合器不能改动。

#### 7. 面积与功耗 Trade-off

DC 根据时序约束在面积和速度之间权衡：
- **约束紧**（高频）→ 用大驱动、低延迟的单元 → 面积大、功耗高
- **约束松**（低频）→ 用小面积、慢速单元 → 面积小、功耗低

这是数字 IC 设计的核心 trade-off：**频率 ↔ 面积 ↔ 功耗**。

### 综合流程总结

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌──────────┐
│ RTL 读入 │ → │ 约束设置   │ → │ compile_ultra│ → │ 写输出    │
│ analyze  │    │ create_clock│    │ (翻译+优化   │    │ 网表.v    │
│ elaborate│    │ set_input_ │    │  +映射)     │    │ .sdf .sdc │
└──────────┘    │ set_output_│    └────────────┘    └──────────┘
                │ set_load   │         ↓
                └───────────┘    ┌──────────┐
                                 │ 分析报告  │
                                 │ 时序/面积 │
                                 │ /功耗/QoR │
                                 └──────────┘
```

## 目录结构

```
expr-2/
├── task.txt                  # 实验说明
├── README.md
├── .gitignore
└── syn/
    ├── .synopsys_dc.setup    # DC 启动自动加载配置
    ├── common_setup.tcl       # 库路径 → target_library / link_library
    ├── dc_setup.tcl           # DC 杂项配置（消息抑制、多核等）
    ├── ref/                   # (手动放入) 标准单元和 IO 库 .db/.sdb
    ├── rtl/                   # ── 输入：RTL 源码 ──
    │   ├── cpu_pad.sv         #   PAD 顶层 wrapper (PI/PO8 + myCPU)
    │   ├── myCPU.sv           #   CPU 核心 (不含 IROM/DRAM)
    │   └── PC.sv ... MUX*.sv  #   10 个子模块
    ├── scripts/               # ── 输入：综合 Tcl 脚本 ──
    │   ├── dc_scripts.tcl     #   默认 50MHz (20ns)
    │   ├── dc_scripts_fast.tcl#   收紧 200MHz (5ns)
    │   └── dc_scripts_slow.tcl#   放宽 25MHz (40ns)
    ├── unmapped/              # ── 中间产物：elaborate 后的 .ddc
    ├── work/                  # ── DC analyze 中间文件 (.mr, .pvl, .syn)
    ├── mapped/                # ── 最终产物（见下）──
    └── rpt/                   # ── 综合报告（见下）──
```

## 使用方法

### 前置条件

远程服务器 `yan12@10.112.86.27`，库文件路径：

| 文件 | 路径 |
|:---|:---|
| 标准单元库 | `/home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db` |
| IO PAD 库 | `/home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db` |
| 符号库 | `/home/eda/lib/smic/aci/sc-x/synopsys/smic13g.sdb` |

### 运行

```bash
ssh yan12@10.112.86.27
cd ~/proj/rv-cpu-expr/expr-2/syn

# 默认 50MHz 综合
dc_shell -f ./scripts/dc_scripts.tcl

# 收紧约束 (200MHz)
dc_shell -f ./scripts/dc_scripts_fast.tcl

# 放宽约束 (25MHz)
dc_shell -f ./scripts/dc_scripts_slow.tcl
```

### 约束条件对比

| 脚本 | 周期 | 频率 | 用途 |
|:---|:-:|:-:|:---|
| `dc_scripts.tcl` | 20ns | 50MHz | 默认约束 |
| `dc_scripts_fast.tcl` | 5ns | 200MHz | 分析时序收紧对面积/功耗的影响 |
| `dc_scripts_slow.tcl` | 40ns | 25MHz | 分析约束放宽后的面积优化空间 |

## 生成文件说明

DC 综合运行后，除原始的 `rtl/`、`scripts/` 和配置 `.tcl` 外，会生成以下文件：

### 最终产物 — `mapped/` 目录

综合成功后的输出，这些是后续流程的输入：

| 文件 | 用途 | 下游工具 |
|:---|:---|:---|
| `cpu_pad_netlist.v` | 门级网表（标准单元 + PAD 实例连接） | ICC2/Innovus (布局布线), VCS (后仿) |
| `cpu_pad.sdf` | 标准延迟格式，含每个门的 pin-to-pin 延迟 | VCS/ModelSim (门级后仿反标) |
| `cpu_pad.sdc` | 综合后的时序约束（时钟定义、输入输出延迟等） | ICC2/Innovus (布局布线输入约束) |
| `cpu_pad_mapped.ddc` | DC 二进制数据库，含映射后的设计 | DC (继续优化), Formality (形式验证) |

### 综合报告 — `rpt/` 目录

| 文件 | 关键内容 | 怎么看 |
|:---|:---|:---|
| `rpt_qor.rpt` | 一页总结：Slack、面积、总违例数 | **最先看这个** |
| `rpt_timing.rpt` | 最长路径的详细时序路径 | 检查关键路径是否合理 |
| `rpt_timing_max.rpt` | 前 10 条最长路径 | 定位时序瓶颈 |
| `rpt_area.rpt` | 端口数、单元数、组合/时序/宏面积 | 评估芯片面积 |
| `rpt_power.rpt` | 动态功耗、漏电功耗 | 粗略功耗估算 |
| `rpt_constraints.rpt` | 所有设计规则违例（max_transition, max_cap 等） | 需要清零或评估是否可接受 |
| `rpt_cell.rpt` | 每个例化单元的面积/功耗明细 | 查找面积大户 |
| `rpt_resource.rpt` | DC 使用的硬件资源统计 | 调试用 |

### 中间文件 — `unmapped/` 目录

| 文件 | 说明 |
|:---|:---|
| `cpu_pad_unmapped.ddc` | elaborate 后、compile 前的未映射设计，用于中断恢复 |

### DC 工作文件 — `syn/work/` 目录

这些是 DC 在 `analyze` 阶段自动产生的中间文件，通过脚本中 `define_design_lib` 统一放入 `work/`，**不需要手动管理**：

| 文件 | 说明 |
|:---|:---|
| `*.mr` | 每个模块的 Master Register 文件（DC 内部中间格式） |
| `*-verilog.pvl` | 已解析的 RTL 内部表示 |
| `*-verilog.syn` | 综合后的设计内部表示 |

### DC 日志文件 — `syn/` 根目录

| 文件 | 说明 |
|:---|:---|
| `command.log` | DC 会话中所有命令和输出的完整记录 |
| `filenames.log` | DC 访问过的所有文件列表（含读写状态） |
| `default.svf` | **SVF (Setup Verification File)** — 记录综合中的优化操作，Formality 形式验证时需要它来比对综合前后逻辑等价性 |

## 门级仿真 (后仿)

使用综合生成的网表和 SDF 进行反标仿真：

```systemverilog
// 在 testbench 中
initial begin
    $sdf_annotate("../expr-2/syn/mapped/cpu_pad.sdf", u_cpu_pad);
end
```

需要将 `mapped/cpu_pad_netlist.v` 和工艺库的 Verilog 模型一起编译仿真。

## PAD 说明

`cpu_pad.sv` 为顶层模块，在 `myCPU` RTL 外添加 IO PAD cell：

- **输入 PAD (PI)**：rst_n, clk, irom_data[31:0], dram_rdata[31:0]
- **输出 PAD (PO8, 8mA 驱动)**：irom_addr[31:0], dram_addr[31:0], dram_wdata[31:0], dram_wen, debug 信号

综合时所有 PAD cell 设为 `dont_touch`，DC 不会优化或移除。PAD 面积约 161 万 µm²，占芯片总面积 96%，这在工程上是正常的——IO PAD 的物理尺寸由 ESD 保护和焊盘决定。

## 综合结果速查 (50MHz @ SMIC 0.13µm)

| 指标 | 数值 |
|:---|:---|
| Slack | 0.00ns (刚好满足) |
| 关键路径 | 18.70ns, 47 级逻辑 |
| 标准单元面积 | 73,175 µm² (~5,600 等效门) |
| PAD 面积 | 1,613,430 µm² |
| 时序单元数 | 1,093 (32×32 RF + 32 PC + debug regs) |
| 组合单元数 | 4,463 |
| 单元内功耗 | ~179 mW |
