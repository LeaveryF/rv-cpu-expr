`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/13 10:15:31
// Design Name: 
// Module Name: instr_rom
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


module instr_rom #(
    parameter DATAWIDTH = 32,
    parameter RAMWIDTH  = 8,
    parameter RAMDEPTH  = 8
) (
    input  logic                   ena,
    input  logic [DATAWIDTH - 1:0] daddr,
    output logic [DATAWIDTH - 1:0] dout
);
  // 先用reg进行最简单的模拟，这段代码不会将reg综合为bram
  // 用reg进行模拟，由于测试需要使用该变量，请不要修改
  reg [RAMWIDTH - 1:0] rom[2**(RAMDEPTH) - 1:0];

  // Combinational read: assemble 4 bytes into a 32-bit word (little-endian)
  always_comb begin
    if (ena) dout = {rom[daddr+3], rom[daddr+2], rom[daddr+1], rom[daddr]};
    else dout = '0;
  end

endmodule
