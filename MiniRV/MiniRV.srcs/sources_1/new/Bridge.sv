`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/08 10:32:41
// Design Name: 
// Module Name: Bridge
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


module Bridge (
    // Interface to CPU
    input  logic         rst_from_cpu,
    input  logic         clk_from_cpu,
    input  logic [15:0]  addr_from_cpu,
    input  logic         wen_from_cpu,
    input  logic [31:0]  wdata_from_cpu,
    output logic [31:0]  rdata_to_cpu,
    
    // Interface to DRAM
    output logic         clk_to_dram,
    output logic [13:0]  addr_to_dram,
    input  logic [31:0]  rdata_from_dram,
    output logic         wen_to_dram,
    output logic [31:0]  wdata_to_dram,
    
    // Interface to 7-seg digital LEDs
    output logic         rst_to_dig,
    output logic         clk_to_dig,
    output logic [15:0]  addr_to_dig,
    input  logic [3:0]   rdata_from_dig, // 总线读取到的数据位1位16进制数，0~F
    output logic         wen_to_dig,
    output logic [4:0]   wdata_to_dig, // 用5位，当wdata_to_dig > 0xF，使用特殊字符

    // Interface to LEDs
    output logic         rst_to_led,
    output logic         clk_to_led,
    output logic [15:0]  addr_to_led,
    input  logic [31:0]  rdata_from_led,
    output logic         wen_to_led,
    output logic [31:0]  wdata_to_led,

    // Interface to switches
    output logic [15:0]  addr_to_sw,
    input  logic [31:0]  rdata_from_sw,

    // Interface to key
    output logic [15:0]  addr_to_key,
    input  logic [7:0]   rdata_from_key
);
    logic access_mem; 
    logic access_dig;
    logic access_led;
    logic access_sw;
    logic access_key;
    logic [4:0] access_bit;

    assign access_bit = { access_mem,
                        access_dig,
                        access_led,
                        access_sw,
                        access_key };

    // Select read data towards CPU
    always @(*) begin
        case (access_bit)
            5'b10000: rdata_to_cpu = rdata_from_dram;
            5'b01000: rdata_to_cpu = rdata_from_dig;
            5'b00100: rdata_to_cpu = rdata_from_led;
            5'b00010: rdata_to_cpu = rdata_from_sw;
            5'b00001: rdata_to_cpu = rdata_from_key;
            default:  rdata_to_cpu = 'hX;
        endcase
    end

    // 地址选择电路
    assign access_mem = (addr_from_cpu[15:12] != 4'b1111) ? 1'b1 : 1'b0;
    assign access_dig = (addr_from_cpu <= 16'hF03C && addr_from_cpu >= 16'hF020) ? 1'b1 : 1'b0;
    assign access_led = (addr_from_cpu == 16'hF040) ? 1'b1 : 1'b0;
    assign access_sw  = (addr_from_cpu == 16'hF000 || addr_from_cpu == 16'hF004) ? 1'b1 : 1'b0;
    assign access_key = (addr_from_cpu == 16'hF010) ? 1'b1 : 1'b0;

    // DRAM
    assign clk_to_dram   = clk_from_cpu;
    // dram 地址起始从data段0X4000开始
    assign addr_to_dram  = addr_from_cpu[15:2] - 14'h1000;
    assign wen_to_dram   = wen_from_cpu & access_mem;
    assign wdata_to_dram = wdata_from_cpu;

    // 7-seg LEDs
    assign rst_to_dig    = rst_from_cpu;
    assign clk_to_dig    = clk_from_cpu;
    assign addr_to_dig   = addr_from_cpu;
    assign wen_to_dig    = wen_from_cpu & access_dig;
    assign wdata_to_dig  = wdata_from_cpu;

    // LEDs
    assign rst_to_led    = rst_from_cpu;
    assign clk_to_led    = clk_from_cpu;
    assign addr_to_led   = addr_from_cpu;
    assign wen_to_led    = wen_from_cpu & access_led;
    assign wdata_to_led  = wdata_from_cpu;
    
    // Switches
    assign addr_to_sw    = addr_from_cpu;

    // Keys
    assign addr_to_key   = addr_from_cpu;

endmodule
