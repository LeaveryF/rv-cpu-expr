`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/18/2025 11:34:19 AM
// Design Name:
// Module Name: mini_ram_wortext
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 字扩展：4 片 256x8bit mini_ram → 1024x8bit
//              高 2 位地址线用作片选 (CS)，低 8 位地址线连接各片
//
// Dependencies: mini_ram
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module mini_ram_wortext #(
    parameter DATAWIDTH = 8,
    parameter RAMDEPTH  = 10
) (
    input  logic                   clk,
    input  logic                   wen,
    input  logic                   ena,
    input  logic [RAMDEPTH  - 1:0] ram_addr_i,
    input  logic [DATAWIDTH - 1:0] ram_data_i,
    output logic [DATAWIDTH - 1:0] ram_data_o
);

  // Chip select decoded from upper 2 address bits
  logic [3:0] cs;
  logic [7:0] chip_addr;
  logic [7:0] chip_data_o[3:0];

  assign chip_addr = ram_addr_i[7:0];

  // 2-to-4 decoder
  assign cs = (ram_addr_i[9:8] == 2'd0) ? 4'b0001 :
                (ram_addr_i[9:8] == 2'd1) ? 4'b0010 :
                (ram_addr_i[9:8] == 2'd2) ? 4'b0100 :
                                             4'b1000;

  genvar i;
  generate
    for (i = 0; i < 4; i++) begin : gen_mini_ram
      mini_ram #(
          .DATAWIDTH(8),
          .RAMDEPTH (8)
      ) mini_ram_inst (
          .clk       (clk),
          .wen       (wen),
          .ena       (ena && cs[i]),
          .ram_addr_i(chip_addr),
          .ram_data_i(ram_data_i),
          .ram_data_o(chip_data_o[i])
      );
    end
  endgenerate

  // Mux: output from the selected chip
  assign ram_data_o = cs[0] ? chip_data_o[0] :
                        cs[1] ? chip_data_o[1] :
                        cs[2] ? chip_data_o[2] :
                                 chip_data_o[3];

endmodule
