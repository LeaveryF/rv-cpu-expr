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
    parameter ADDR_WIDTH = 5,
    parameter DATAWIDTH  = 32
) (
    input logic                    clk,
    input logic                    rst,
    // Write rd
    input logic                    wr_reg_en,
    input logic [ADDR_WIDTH - 1:0] wr_reg_addr,
    input logic [ DATAWIDTH - 1:0] wr_wdata,
    // Read  rs1 rs2
    input logic [ADDR_WIDTH - 1:0] rs_reg1_addr,
    input logic [ADDR_WIDTH - 1:0] rs_reg2_addr,

    output logic [DATAWIDTH - 1:0] rs_reg1_rdata,
    output logic [DATAWIDTH - 1:0] rs_reg2_rdata
);
  // 寄存器堆的定义，由于测试需要使用该变量，请不要修改变量名称
  logic [DATAWIDTH - 1:0] reg_bank[31:0];

  // Async reset and sequential write
  always_ff @(posedge clk, posedge rst) begin
    if (rst) begin
      // Reset all registers to 0
      for (int i = 0; i < 32; i++) reg_bank[i] <= '0;
    end else if (wr_reg_en) begin
      // Write to register, but x0 is hardwired to 0
      if (wr_reg_addr != 5'd0) reg_bank[wr_reg_addr] <= wr_wdata;
    end
  end

  // Combinational read: x0 is always 0
  assign rs_reg1_rdata = (rs_reg1_addr == 5'd0) ? '0 : reg_bank[rs_reg1_addr];
  assign rs_reg2_rdata = (rs_reg2_addr == 5'd0) ? '0 : reg_bank[rs_reg2_addr];

endmodule
