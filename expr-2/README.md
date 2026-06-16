# 实验二：逻辑综合

对 MiniRV CPU 前端 RTL 进行逻辑综合（Design Compiler），添加 IO PAD，生成门级网表、时序/面积/功耗报告和 SDF 文件。

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

### DC 工作文件 — `syn/` 根目录

这些是 DC 运行时自动产生的工作文件，**不需要手动管理**，通常加入 `.gitignore`：

| 文件 | 说明 |
|:---|:---|
| `command.log` | DC 会话中所有命令和输出的完整记录 |
| `filenames.log` | DC 访问过的所有文件列表（含读写状态） |
| `default.svf` | **SVF (Setup Verification File)** — 记录综合中的优化操作，Formality 形式验证时需要它来比对综合前后逻辑等价性 |
| `alib-52/` | DC 内部库缓存目录 |
| `*.mr` | 每个模块的 Master Register 文件（DC 内部中间格式） |
| `*-verilog.pvl` | 已解析的 RTL 内部表示 |
| `*-verilog.syn` | 综合后的设计内部表示 |

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
