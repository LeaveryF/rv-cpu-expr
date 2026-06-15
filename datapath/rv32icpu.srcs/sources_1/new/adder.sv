`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/06 20:26:59
// Design Name: 
// Module Name: adder
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


module adder#(
    parameter   DATAWIDTH = 32
)(
    input  logic [DATAWIDTH - 1:0] A          ,
    input  logic [DATAWIDTH - 1:0] B          ,
    output logic [DATAWIDTH - 1:0] Result     
);
endmodule
