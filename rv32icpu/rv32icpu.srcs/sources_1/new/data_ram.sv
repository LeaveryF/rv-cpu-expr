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
    parameter   DATAWIDTH   =   32  ,
    parameter   RAMWIDTH    =   8   ,
    parameter   RAMDEPTH    =   8  
)(
    input  logic                   clk      ,
    input  logic                   rst      ,
    input  logic                   ena      ,
    input  logic                   wen      ,
    input  logic [DATAWIDTH - 1:0] din      ,
    input  logic [DATAWIDTH - 1:0] daddr    ,
    output logic [DATAWIDTH - 1:0] dout     
);
    // 先用reg进行最简单的模拟，这段代码不会将reg综合为bram
    reg [RAMWIDTH - 1:0] ram [2**(RAMDEPTH) - 1:0];
endmodule
