# RISC-V CPU 课程实验

基于 SystemVerilog 的单周期 RISC-V 处理器前端设计，从 ALU 出发逐步实现支持 MiniRV 指令集（37 条指令）的完整 CPU。

## 实验列表

| 序号 | 实验名称 | 目录 | 说明 |
|:---:|:---|:---|:---|
| 1 | ALU 设计 | [alu/](alu/) | 32 位 ALU，4 种运算 + N/Z/C/V 标志位 |
| 2 | 数据通路 | [datapath/](datapath/) | PC、RegFile、ImmGen、IM、DM 等 8 个核心部件 |
| 3 | 存储器扩展 | [MemExt/](MemExt/) | 字扩展+位扩展，256×8bit → 1024×32bit |
| 4 | 控制器与 CPU 集成 | [rv32icpu/](rv32icpu/) | 两级译码控制器，13 模块集成，7 指令单周期 CPU |
| 5 | MiniRV CPU 验证 | [MiniRV/](MiniRV/) | 升级至 37 指令，Trace 差分测试全通过 |

## 项目结构

```
.
├── alu/            # 实验一：ALU
├── datapath/       # 实验二：数据通路
├── MemExt/         # 实验三：存储器扩展
├── rv32icpu/       # 实验四：控制器+CPU集成
├── MiniRV/         # 实验五：MiniRV CPU验证
├── cdp-tests/      # Trace 差分测试框架
├── docs/           # 实验报告
│   ├── alu.md
│   ├── datapath.md
│   ├── memext.md
│   ├── controller.md
│   ├── verification.md
│   └── frontend.md      # 前端设计综合报告
└── tasks/          # 实验指导书
```

每个实验目录内包含 Vivado 工程（`.xpr`），源码位于 `*/rv32icpu.srcs/sources_1/new/`（实验五为 `MiniRV.srcs/sources_1/new/`）。

## 实验环境

- **设计语言**：SystemVerilog
- **开发工具**：Xilinx Vivado 2024.2
- **仿真工具**：Vivado Simulator (XSim)、Verilator 5.020
- **测试框架**：cdp-tests 差分测试
- **目标器件**：xc7k325tffg900-2

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

实验五使用 cdp-tests 差分测试框架进行验证：

```bash
cd cdp-tests
make TEST=add       # 编译并运行单个测试
make run TEST=add   # 仅运行（已编译）
```

所有 37 个测试均通过：
```
✅ add addi and andi auipc beq bge bgeu blt bltu bne
✅ jal jalr lb lbu lh lhu lui lw or ori sb sh
✅ sll slli slt slti sltiu sltu sra srai srl srli sub sw xor xori
```
