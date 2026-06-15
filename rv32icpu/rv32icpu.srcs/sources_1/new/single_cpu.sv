`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/03/18 15:58:46
// Design Name:
// Module Name: single_cpu
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 单周期 RISC-V CPU 顶层集成
//              连接 PC, IM, RF, IMMGen, ALU, ALU_controller,
//              Control, DM, MUX 等模块，实现 7 条指令的完整数据通路
//
// Dependencies: pc, pc_add1, pc_add2, instr_rom, reg_file, imm_gen,
//               control, ALU_controller, alu, data_ram, mux
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module single_cpu #(
    parameter DATAWIDTH = 32
) (
    input  logic                   clk,
    input  logic                   rst,
    output logic [DATAWIDTH - 1:0] pc_out
);

  // ── Instruction bus ──
  logic [DATAWIDTH - 1:0] instr;
  logic [            6:0] opcode;
  logic [            3:0] funct;

  // ── Register file ──
  logic [4:0] rs1_addr, rs2_addr, rd_addr;
  logic [31:0] rs1_rdata, rs2_rdata;
  logic [31:0] wr_wdata;

  // ── Immediate ──
  logic [31:0] imm;

  // ── Control signals ──
  logic Branch, MemToReg, MemWrite, ALUSrc, RegWrite;
  logic [1:0] ALUOP;

  // ── ALU ──
  logic [1:0] ALUControl;
  logic [31:0] alu_a, alu_b, alu_result;
  logic Zero;

  // ── PC / NPC ──
  logic [31:0] pc, npc, pc_plus_4, pc_plus_imm;
  logic        PcSrc;

  // ── Data memory ──
  logic [31:0] dm_dout;

  // ── Derived signals ──
  assign opcode   = instr[6:0];
  assign rs1_addr = instr[19:15];
  assign rs2_addr = instr[24:20];
  assign rd_addr  = instr[11:7];
  assign funct    = {instr[30], instr[14:12]};  // {funct7[5], funct3}
  assign PcSrc    = Branch & Zero;

  // ─────────────────────────────────────────
  //  Module Instantiations
  // ─────────────────────────────────────────

  // --- PC + 4 ---
  pc_add1 #(
      .DATAWIDTH(DATAWIDTH)
  ) adder_left (
      .A     (pc),
      .B     (32'd4),
      .Result(pc_plus_4)
  );

  // --- PC + immediate (branch target) ---
  pc_add2 #(
      .DATAWIDTH(DATAWIDTH)
  ) adder_right (
      .A     (pc),
      .B     (imm),
      .Result(pc_plus_imm)
  );

  // --- NPC mux: PcSrc selects branch target vs. sequential ---
  mux #(
      .WIDTH(DATAWIDTH)
  ) mux_npc (
      .A      (pc_plus_4),
      .B      (pc_plus_imm),
      .Control(PcSrc),
      .Result (npc)
  );

  // --- Program Counter ---
  pc #(
      .DATAWIDTH(DATAWIDTH)
  ) pc_inst (
      .clk   (clk),
      .rst   (rst),
      .npc   (npc),
      .pc_out(pc)
  );

  assign pc_out = pc;

  // --- Instruction Memory ---
  instr_rom #(
      .DATAWIDTH(DATAWIDTH),
      .RAMWIDTH (8),
      .RAMDEPTH (8)
  ) instr_rom_inst (
      .ena  (1'b1),
      .daddr(pc),
      .dout (instr)
  );

  // --- Register File ---
  reg_file #(
      .ADDR_WIDTH(5),
      .DATAWIDTH (DATAWIDTH)
  ) reg_file_inst (
      .clk          (clk),
      .rst          (rst),
      .wr_reg_en    (RegWrite),
      .wr_reg_addr  (rd_addr),
      .wr_wdata     (wr_wdata),
      .rs_reg1_addr (rs1_addr),
      .rs_reg2_addr (rs2_addr),
      .rs_reg1_rdata(rs1_rdata),
      .rs_reg2_rdata(rs2_rdata)
  );

  // --- Immediate Generator ---
  imm_gen #(
      .DATAWIDTH(DATAWIDTH)
  ) imm_gen_inst (
      .instr(instr),
      .imm  (imm)
  );

  // --- Main Control Unit ---
  control control_inst (
      .opcode  (opcode),
      .Branch  (Branch),
      .MemToReg(MemToReg),
      .MemWrite(MemWrite),
      .ALUOP   (ALUOP),
      .ALUSrc  (ALUSrc),
      .RegWrite(RegWrite)
  );

  // --- ALU Controller ---
  ALU_controller ALU_controller_inst (
      .funct     (funct),
      .ALUOP     (ALUOP),
      .ALUControl(ALUControl)
  );

  // --- ALU B-source mux ---
  mux #(
      .WIDTH(DATAWIDTH)
  ) mux_alusrc (
      .A      (rs2_rdata),
      .B      (imm),
      .Control(ALUSrc),
      .Result (alu_b)
  );

  assign alu_a = rs1_rdata;

  // --- ALU ---
  alu #(
      .DATAWIDTH(DATAWIDTH)
  ) alu_inst (
      .A         (alu_a),
      .B         (alu_b),
      .ALUControl(ALUControl),
      .Result    (alu_result),
      .N         (),
      .Z         (Zero),
      .V         (),
      .C         ()
  );

  // --- Data Memory ---
  data_ram #(
      .DATAWIDTH(DATAWIDTH),
      .RAMWIDTH (8),
      .RAMDEPTH (8)
  ) data_ram_inst (
      .clk  (clk),
      .rst  (rst),
      .ena  (1'b1),
      .wen  (MemWrite),
      .din  (rs2_rdata),
      .daddr(alu_result),
      .dout (dm_dout)
  );

  // --- Write-back mux: MemToReg selects ALU result vs. DM output ---
  mux #(
      .WIDTH(DATAWIDTH)
  ) mux_dout (
      .A      (alu_result),
      .B      (dm_dout),
      .Control(MemToReg),
      .Result (wr_wdata)
  );

endmodule
