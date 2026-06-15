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
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mini_ram_wortext #(
    parameter   DATAWIDTH   =   8  ,
    parameter   RAMDEPTH    =   10  
)(
    input  logic                   clk         ,
    input  logic                   wen         ,          
	input  logic                   ena         ,
    input  logic [RAMDEPTH  - 1:0] ram_addr_i  ,
    input  logic [DATAWIDTH - 1:0] ram_data_i  ,
    output logic [DATAWIDTH - 1:0] ram_data_o
);
endmodule
