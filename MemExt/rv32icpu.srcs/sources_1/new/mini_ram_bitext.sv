`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/18/2025 11:34:19 AM
// Design Name:
// Module Name: mini_ram_bitext
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 位扩展：4 片 mini_ram_wortext (1024x8bit) → 1024x32bit
//              4 片共享地址线和控制信号，每片负责 8 位数据
//
// Dependencies: mini_ram_wortext
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module mini_ram_bitext #(
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

  logic [7:0] chip_data_o[3:0];

  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : gen_wortext
      mini_ram_wortext #(
          .DATAWIDTH(8),
          .RAMDEPTH (10)
      ) wortext_inst (
          .clk       (clk),
          .wen       (wen),
          .ena       (ena),
          .ram_addr_i(ram_addr_i),
          .ram_data_i(ram_data_i[i*8+:8]),
          .ram_data_o(chip_data_o[i])
      );
    end
  endgenerate

  // Assemble 32-bit output from 4 byte-slices (little-endian)
  assign ram_data_o = {chip_data_o[3], chip_data_o[2], chip_data_o[1], chip_data_o[0]};

endmodule
