`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/18/2025 02:38:44 PM
// Design Name:
// Module Name: top_ram_ext
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 顶层 RAM 扩展模块，例化 mini_ram_bitext
//
// Dependencies: mini_ram_bitext
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module top_ram_ext #(
    parameter DATAWIDTH = 32,
    parameter RAMDEPTH  = 10
) (
    input  logic                   clk,
    input  logic                   wen,
    input  logic                   ena,
    input  logic [RAMDEPTH  - 1:0] ram_addr_i,
    input  logic [DATAWIDTH - 1:0] ram_data_i,
    output logic [DATAWIDTH - 1:0] ram_data_o
);

  mini_ram_bitext #(
      .DATAWIDTH(DATAWIDTH),
      .RAMDEPTH (RAMDEPTH)
  ) mini_ram_inst (
      .clk       (clk),
      .wen       (wen),
      .ena       (ena),
      .ram_addr_i(ram_addr_i),
      .ram_data_i(ram_data_i),
      .ram_data_o(ram_data_o)
  );

endmodule
