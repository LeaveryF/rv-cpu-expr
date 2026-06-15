`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 16:18:52
// Design Name: 
// Module Name: control
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


module control(
    input  logic [6:0]  opcode      ,
    output logic        Branch      ,
    output logic        MemToReg    ,
    output logic        MemWrite    ,
    output logic [1:0]  ALUOP       ,
    output logic        ALUSrc      ,
    output logic        RegWrite    
);
endmodule
