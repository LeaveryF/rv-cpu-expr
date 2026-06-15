`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/06 20:09:18
// Design Name: 
// Module Name: pc
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


module pc #(
    parameter DATAWIDTH = 32
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic [DATAWIDTH - 1:0] npc,
    output logic [DATAWIDTH - 1:0] pc_out
);

  // Async reset: when rst is high, pc_out = 0 immediately
  // On posedge clk: pc_out <= npc
  always_ff @(posedge clk, posedge rst) begin
    if (rst) pc_out <= '0;
    else pc_out <= npc;
  end

endmodule
