# 实验二：逻辑综合

对 MiniRV CPU 前端 RTL 进行逻辑综合（Design Compiler），添加 IO PAD，生成门级网表、时序/面积/功耗报告和 SDF 文件。

## 目录结构

```
expr-2/syn/
├── .synopsys_dc.setup      # DC 启动自动加载配置
├── common_setup.tcl         # 库路径和搜索目录
├── dc_setup.tcl             # DC 特定配置
├── ref/                     # (手动放入) .db 库文件
├── rtl/                     # RTL 源码
│   ├── cpu_pad.sv           # PAD 顶层 wrapper
│   ├── myCPU.sv             # CPU 核心
│   ├── PC.sv NPC.sv         # 基础模块
│   ├── Control.sv ACTL.sv   # 控制器
│   ├── ALU.sv IMMGEN.sv     # 运算单元
│   ├── RF.sv                # 寄存器堆
│   └── MUX2_1.sv MUX4_1.sv  # 多路选择器
├── scripts/
│   ├── dc_scripts.tcl       # 默认综合脚本 (50MHz)
│   ├── dc_scripts_fast.tcl  # 收紧约束 (200MHz)
│   └── dc_scripts_slow.tcl  # 放宽约束 (25MHz)
├── unmapped/                # 未映射的 .ddc
├── mapped/                  # 综合输出: 网表 .v, .sdf, .sdc, .ddc
└── rpt/                     # 综合报告: 时序/面积/功耗
```

## 使用方法

### 前置条件

在远程服务器上，确认以下库文件存在：

| 文件 | 路径 |
|:---|:---|
| 标准单元库 | `/home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db` |
| IO PAD 库 | `/home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db` |
| 符号库 | `/home/eda/lib/smic/aci/sc-x/synopsys/smic13g.sdb` |

### 综合步骤

```bash
# 1. 进入综合目录
cd expr-2/syn

# 2. (可选) 拷贝库文件到 ref/
cp /home/eda/lib/smic/aci/sc-x/synopsys/typical_1v2c25.db ref/
cp /home/eda/lib/smic/SP013D3_V1p4/syn/SP013D3_V1p2_typ.db ref/
cp /home/eda/lib/smic/aci/sc-x/synopsys/smic13g.sdb ref/

# 3. 启动 Design Compiler
dc_shell-64

# 4. 在 DC 中运行综合
source ./scripts/dc_scripts.tcl

# 5. (可选) 运行不同约束条件的综合
remove_design -designs
source ./scripts/dc_scripts_fast.tcl
```

### 约束条件对比

| 脚本 | 时钟周期 | 频率 | 用途 |
|:---|:-:|:-:|:---|
| `dc_scripts.tcl` | 20ns | 50MHz | 默认约束 |
| `dc_scripts_fast.tcl` | 5ns | 200MHz | 分析时序压力对面积/功耗的影响 |
| `dc_scripts_slow.tcl` | 40ns | 25MHz | 分析宽松约束下的面积优化 |

## 输出文件

| 文件 | 说明 |
|:---|:---|
| `mapped/cpu_pad_netlist.v` | 门级网表 |
| `mapped/cpu_pad.sdf` | 标准延迟格式 (用于门级仿真反标) |
| `mapped/cpu_pad.sdc` | 时序约束 (用于布局布线) |
| `rpt/rpt_timing.rpt` | 时序分析报告 |
| `rpt/rpt_area.rpt` | 面积分析报告 |
| `rpt/rpt_power.rpt` | 功耗分析报告 |

## 门级仿真 (后仿)

使用综合生成的网表和 SDF 文件进行门级仿真：

```systemverilog
initial begin
    $sdf_annotate("cpu_pad.sdf", u_cpu_pad);
end
```

## PAD 说明

`cpu_pad.sv` 为顶层模块，在 `myCPU` 外添加 IO PAD：
- **输入 PAD (PI)**：rst_n, clk, irom_data[31:0], dram_rdata[31:0]
- **输出 PAD (PO8)**：irom_addr[31:0], dram_addr[31:0], dram_wdata[31:0], dram_wen, debug 信号

PAD 在综合时设为 `dont_touch`，DC 不会优化或移除它们。