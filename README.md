# RISC-V CPU 课程实验

基于 SystemVerilog 的 RISC-V 处理器设计，逐步实现一个完整的 RV32I CPU。

## 实验列表

| 序号 | 实验名称 | 目录 | 说明 |
|:---:|:---|:---|:---|
| 1 | ALU 算术逻辑单元 | [alu/](alu/) | 实现支持 add/sub/and/or 的 32 位 ALU，含 N/Z/C/V 标志位 |
| 2 | 数据通路 | datapath/ | 构建 CPU 数据通路 |
| 3 | 存储器扩展 | MemExt/ | 存储器接口扩展 |
| 4 | MiniRV | MiniRV/ | MiniRV 简易处理器实现 |
| 5 | RV32I CPU | rv32icpu/ | 完整 RV32I CPU 集成 |

## 项目结构

```
.
├── alu/            # 实验一：ALU
├── datapath/       # 实验二：数据通路
├── MemExt/         # 实验三：存储器扩展
├── MiniRV/         # 实验四：MiniRV
├── rv32icpu/       # 实验五：完整CPU
├── docs/           # 实验报告
│   └── alu.md
└── tasks/          # 实验指导书
    └── alu.txt
```

每个实验目录内包含 Vivado 工程，源码位于 `*/rv32icpu.srcs/sources_1/new/`，仿真代码位于 `*/rv32icpu.srcs/sim_1/new/`。

## 实验环境

- **设计语言**：SystemVerilog
- **开发工具**：Xilinx Vivado 2024.2
- **仿真工具**：Vivado Simulator (XSim)
- **目标器件**：xc7k325tffg900-2

## 指令集

最终实现的 RV32I 核心子集包含 7 条指令：

| 类型 | 指令 | 说明 |
|:---|:---|:---|
| 存储器访问 | lw, sw | 加载/存储字 |
| 算术逻辑 | add, sub, and, or | 加减与或 |
| 条件分支 | beq | 相等跳转 |