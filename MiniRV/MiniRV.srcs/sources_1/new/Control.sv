`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/30 8:26:09
// Design Name: 
// Module Name: Control
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

module Control(
    input  logic [6:0]  opcode      ,
    output logic [1:0]  NpcOp       ,
    output logic        RegWrite    ,
    output logic [1:0]  MemToReg    ,
    output logic        MemWrite    ,
    output logic        OffsetOrigin,
    output logic        ALUSrc      
);
   // controller module
endmodule
