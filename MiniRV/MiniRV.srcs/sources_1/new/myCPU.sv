`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/24 10:51:04
// Design Name: 
// Module Name: myCPU
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

module myCPU (
    input  logic         cpu_rst,
    input  logic         cpu_clk,

    // Interface to IROM, you need add some signals
    
    // Interface to DRAM, you need add some signals

    output logic         debug_wb_have_inst,   // WB阶段是否有指令 (对单周期CPU，可在复位后恒为1)
    output logic [31:0]  debug_wb_pc,          // WB阶段的PC (若wb_have_inst=0，此项可为任意值)
    output logic         debug_wb_ena,         // WB阶段的寄存器写使能 (若wb_have_inst=0，此项可为任意值)
    output logic [ 4:0]  debug_wb_reg,         // WB阶段写入的寄存器号 (若wb_ena或wb_have_inst=0，此项可为任意值)
    output logic [31:0]  debug_wb_value        // WB阶段写入寄存器的值 (若wb_ena或wb_have_inst=0，此项可为任意值)
);

    // TODO: 完成你自己的单周期CPU设计
    
   
    // Debug Interface
    assign debug_wb_have_inst = 0;
    assign debug_wb_pc        = 0;
    assign debug_wb_ena       = 0;
    assign debug_wb_reg       = 0;
    assign debug_wb_value     = 0;
endmodule

