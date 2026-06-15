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
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module single_cpu#(
    parameter DATAWIDTH = 32    
)(
    input  logic                    clk    ,
    input  logic                    rst    ,
    output logic [DATAWIDTH - 1:0]  pc_out     
);
// TODO: 提供了一些器件的例化，有可能有缺失，同学们需要自行补全完整

adder #(
    .DATAWIDTH  (DATAWIDTH)
) adder_left(
    .A          (),
    .B          (),
    .Result     ()
);

pc #(
    .DATAWIDTH  (DATAWIDTH)
) pc_inst(
    .clk        (),
    .rst        (),
    .npc        (),
    .pc_out     ()
);

instr_rom #(
   .DATAWIDTH   (DATAWIDTH)  ,
   .RAMWIDTH    (8 )         ,
   .RAMDEPTH    (8)  
) instr_rom_inst (
    .ena      (1'b1),
    .daddr    (),
    .dout     ()
);

reg_file #(
    .ADDR_WIDTH (5),
    .DATAWIDTH  (DATAWIDTH)
)reg_file_inst (
    .clk             (),
    .rst             (),
    .wr_reg_en       (),
    .wr_reg_addr     (),
    .wr_wdata        (),
    .rs_reg1_addr    (),
    .rs_reg2_addr    (),
    .rs_reg1_rdata   (),
    .rs_reg2_rdata   ()
);

imm_gen #(
    .DATAWIDTH  (32)	
)imm_gen_inst (
    .instr   (),
    .imm     ()  
);

control control_inst (
    .opcode      (),
    .Branch      (),
    .MemToReg    (),
    .MemWrite    (),
    .ALUOP       (),
    .ALUSrc      (),
    .RegWrite    ()
);

ALU_controller ALU_controller_inst(
    .funct        (),
    .ALUOP        (),
    .ALUControl   () 
);

alu# (
    .DATAWIDTH  (DATAWIDTH)	
) alu_inst (
    .A           (A),
    .B           (B),
    .ALUControl  (ALUControl),
    .Result      (Result),
    .N           (),
    .Z           (Zero),
    .V           (),
    .C           ()
);

data_ram #(
    .DATAWIDTH   (DATAWIDTH)  ,
    .RAMWIDTH    (8)         ,
    .RAMDEPTH    (8)  
)data_ram_inst(
    .clk      (),
    .rst      (),
    .ena      (),
    .wen      (),
    .din      (),
    .daddr    (),
    .dout     ()
);

mux #(
    .WIDTH      (DATAWIDTH)
) mux_dout(
    .A          (),
    .B          (),
    .Control    (),
    .Result     ()
);

endmodule
