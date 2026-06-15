`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/06 20:30:48
// Design Name: 
// Module Name: pc_add2
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


module pc_add2 #(
    parameter DATAWIDTH = 32
) (
    input  logic [DATAWIDTH - 1:0] A,
    input  logic [DATAWIDTH - 1:0] B,
    output logic [DATAWIDTH - 1:0] Result
);
  adder #(
      .DATAWIDTH(DATAWIDTH)
  ) adder2 (
      .A     (A),
      .B     (B),
      .Result(Result)
  );
endmodule
