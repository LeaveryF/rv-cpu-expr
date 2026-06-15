`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/09 09:49:24
// Design Name: 
// Module Name: reg_file
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


module reg_file #(
    parameter   ADDR_WIDTH = 5  ,
    parameter   DATAWIDTH  = 32
)(
    input  logic                    clk            ,
    input  logic                    rst            ,
    // Write rd                   
    input  logic                    wr_reg_en      ,
    input  logic [ADDR_WIDTH - 1:0] wr_reg_addr    ,
    input  logic [DATAWIDTH - 1:0]  wr_wdata       ,
    // Read  rs1 rs2
    input  logic [ADDR_WIDTH - 1:0] rs_reg1_addr   ,
    input  logic [ADDR_WIDTH - 1:0] rs_reg2_addr   ,

    output logic [DATAWIDTH - 1:0]  rs_reg1_rdata  ,
    output logic [DATAWIDTH - 1:0]  rs_reg2_rdata
);
    logic [DATAWIDTH - 1:0] reg_bank [31:0];
endmodule
