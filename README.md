# RISC-V CPU 数字 IC 设计实验

基于 SystemVerilog 的单周期 RISC-V 处理器设计，涵盖前端 RTL → 逻辑综合 → 版图物理设计的完整流程。

## 实验列表

| 序号 | 实验名称 | 目录 | 说明 |
|:---:|:---|:---|:---|
| 一 | 前端 RTL 设计 | [alu/](alu/) [datapath/](datapath/) [MemExt/](MemExt/) [rv32icpu/](rv32icpu/) [MiniRV/](MiniRV/) | 5 个子实验：ALU → 数据通路 → 存储器扩展 → 控制器 → MiniRV CPU (37 指令) |
| 二 | 逻辑综合 | [expr-2/](expr-2/) | DC 综合 + PAD 设计 + 时序/面积/功耗分析 |
| 三 | 版图设计 | [expr-3/](expr-3/) | ICC2 布局布线 + PT SDF + VCS 门级后仿真 |

## 项目结构

```
.
├── alu/            # 前端子实验：ALU
├── datapath/       # 前端子实验：数据通路
├── MemExt/         # 前端子实验：存储器扩展
├── rv32icpu/       # 前端子实验：控制器+CPU集成
├── MiniRV/         # 前端子实验：MiniRV CPU验证
├── cdp-tests/      # Trace 差分测试框架
├── expr-2/         # 实验二：逻辑综合 (DC)
│   ├── syn/        #   综合脚本、RTL、输出
│   └── docs/       #   实验报告
├── expr-3/         # 实验三：版图设计 (ICC2+PT+VCS)
│   ├── run/        #   运行脚本 + MW 库
│   ├── scripts/    #   ICC2/PT 脚本
│   ├── output/     #   版图后网表 + SPEF + SDF
│   └── docs/       #   实验报告
├── docs/           # 综合报告
│   ├── frontend.md         # 前端设计综合报告
│   ├── eda-expr.md         # 三大实验总报告
│   └── alu.md ...          # 各子实验报告
└── tasks/          # 实验指导书
```

## 实验环境

| 工具 | 用途 | 版本 |
|:---|:---|:---|
| Xilinx Vivado | 前端 RTL 仿真 | 2024.2 |
| Verilator | Trace 差分测试 | 5.020 |
| Synopsys Design Compiler | 逻辑综合 | R-2020.09-SP4 |
| Synopsys ICC2 | 布局布线 (版图设计) | T-2022.03 |
| Synopsys PrimeTime | 时序签核 / SDF 生成 | T-2022.03 |
| Synopsys VCS | 门级后仿真 | T-2022.06 |

- **设计语言**：SystemVerilog / Verilog
- **工艺**：SMIC 0.13µm, 1P8M, typical 1.2V 25°C
- **目标器件**：xc7k325tffg900-2 (前端)

## MiniRV 指令集

最终实现的 MiniRV 指令集为 RV32I 子集，共 37 条指令，全部通过 Trace 差分测试：

| 类别 | 指令 | 数量 |
|:---|:---|:-:|
| R-type | add, sub, and, or, xor, sll, srl, sra, slt, sltu | 10 |
| I-type ALU | addi, andi, ori, xori, slli, srli, srai, slti, sltiu | 9 |
| Load | lb, lbu, lh, lhu, lw | 5 |
| Store | sb, sh, sw | 3 |
| Branch | beq, bne, blt, bltu, bge, bgeu | 6 |
| U-type | lui, auipc | 2 |
| J-type | jal, jalr | 2 |

## 测试

**前端差分测试**（cdp-tests）：
```bash
cd cdp-tests
make TEST=add       # 编译并运行单个测试
make run TEST=add   # 仅运行（已编译）
```

所有 37 个 MiniRV 指令测试均通过：

```
✅ add addi and andi auipc beq bge bgeu blt bltu bne
✅ jal jalr lb lbu lh lhu lui lw or ori sb sh
✅ sll slli slt slti sltiu sltu sra srai srl srli sub sw xor xori
```

**逻辑综合**（DC）：
```bash
cd expr-2/syn && dc_shell -f ./scripts/dc_scripts.tcl
```

**版图设计**（ICC2）：
```bash
cd expr-3/run && ./run_all.sh     # 一键全流程
./view_layout.sh route            # GUI 查看版图
```
