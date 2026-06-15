`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/18/2025 11:34:19 AM
// Design Name:
// Module Name: mini_ram
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 256x8bit 基础 RAM 模块 (用于字扩展和位扩展)
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module mini_ram #(
    parameter DATAWIDTH = 8,
    parameter RAMDEPTH  = 8
) (
    input  logic                   clk,
    input  logic                   wen,
    input  logic                   ena,
    input  logic [RAMDEPTH  - 1:0] ram_addr_i,
    input  logic [DATAWIDTH - 1:0] ram_data_i,
    output logic [DATAWIDTH - 1:0] ram_data_o
);

  reg [DATAWIDTH - 1:0] ram[2**(RAMDEPTH) - 1:0];

  // Sequential write: gated by ena && wen
  always_ff @(posedge clk) begin
    if (ena && wen) ram[ram_addr_i] <= ram_data_i;
  end

  // Combinational read: always active (ena only gates write)
  assign ram_data_o = ram[ram_addr_i];

endmodule
