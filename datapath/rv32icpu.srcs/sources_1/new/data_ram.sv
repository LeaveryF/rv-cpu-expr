`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/13 09:59:48
// Design Name: 
// Module Name: data_ram
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


module data_ram #(
    parameter DATAWIDTH = 32,
    parameter RAMWIDTH  = 8,
    parameter RAMDEPTH  = 8
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   ena,
    input  logic                   wen,
    input  logic [DATAWIDTH - 1:0] din,
    input  logic [DATAWIDTH - 1:0] daddr,
    output logic [DATAWIDTH - 1:0] dout
);
  // 先用reg进行最简单的模拟，这段代码不会将reg综合为bram
  // 用reg进行模拟，由于测试需要使用该变量，请不要修改
  reg [RAMWIDTH - 1:0] ram[2**(RAMDEPTH) - 1:0];

  // Async reset and sequential write (gated by ena & wen)
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      for (int i = 0; i < 2 ** RAMDEPTH; i++) ram[i] <= '0;
    end else if (ena && wen) begin
      // Write 32-bit word as 4 bytes (little-endian)
      ram[daddr]   <= din[7:0];
      ram[daddr+1] <= din[15:8];
      ram[daddr+2] <= din[23:16];
      ram[daddr+3] <= din[31:24];
    end
  end

  // Combinational read: assemble 4 bytes into a 32-bit word (little-endian)
  always_comb begin
    if (ena) dout = {ram[daddr+3], ram[daddr+2], ram[daddr+1], ram[daddr]};
    else dout = '0;
  end

endmodule
