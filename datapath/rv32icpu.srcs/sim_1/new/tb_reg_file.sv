`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/09 10:19:33
// Design Name: 
// Module Name: tb_reg_file
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


/* 
测试思路：
1. 是否能将txt文件中设置的值给读出来
2. 使用rst清空后，比较所有寄存器是否为0
3. 写入x31寄存器，查看读出结果
4. 写入x0寄存器非0值后，查看读出来结果

*/
module tb_reg_file();

parameter   ADDR_WIDTH = 5  ;
parameter   DATAWIDTH  = 32 ;

logic                    clk            ;
logic                    rst            ;           
logic                    wr_reg_en      ;
logic [ADDR_WIDTH - 1:0] wr_reg_addr    ;
logic [DATAWIDTH - 1:0]  wr_wdata       ;
logic [ADDR_WIDTH - 1:0] rs_reg1_addr   ;
logic [ADDR_WIDTH - 1:0] rs_reg2_addr   ;
logic [DATAWIDTH - 1:0]  rs_reg1_rdata  ; 
logic [DATAWIDTH - 1:0]  rs_reg2_rdata  ;

logic [DATAWIDTH - 1:0]  reg_bank [4:0];

always #1 clk = ~clk;


initial begin
    // 测试1：是否能将txt文件中设置的值给读出来
    clk = 0;
    rst = 0;
    wr_reg_en = 0;
    rs_reg1_addr = 0;
    rs_reg2_addr = 0;
    $readmemh("/home/ketted/Desktop/cs2022_2/2 数据通路实验/学生版/datapath/rv32icpu.srcs/sources_1/new/reg_file.txt", reg_file_inst.reg_bank, 0, 4);
    $readmemh("/home/ketted/Desktop/cs2022_2/2 数据通路实验/学生版/datapath/rv32icpu.srcs/sources_1/new/reg_file.txt", reg_bank, 0, 4);
    repeat (5) begin
        // 等待一个时钟上升沿
        @(posedge clk);

        assert(reg_bank[rs_reg1_addr] == rs_reg1_rdata) else $fatal("Result Error: read reg_bank[%d] and {Result} is  {%x}, but expected {%x}.", rs_reg1_addr, rs_reg1_rdata, reg_bank[rs_reg1_addr]);
        assert(reg_bank[rs_reg2_addr] == rs_reg2_rdata) else $fatal("Result Error: read reg_bank[%d] and {Result} is  {%x}, but expected {%x}.", rs_reg2_addr, rs_reg2_rdata, reg_bank[rs_reg2_addr]);

        rs_reg1_addr <= rs_reg1_addr + 1;
        rs_reg2_addr <= rs_reg2_addr + 1;
    end
    // 测试2：使用rst清空后，比较所有寄存器是否为0
    rst = 1;
    #2 rst = 0;
    rs_reg1_addr = 0;
    rs_reg2_addr = 0;
   
    repeat (32) begin
        @(posedge clk);

        assert(rs_reg1_rdata == 32'd0) else $fatal("Result Error: rst all registers and read register[%d]. {Result} is  {%x}, but expected {0000}.", rs_reg1_addr, rs_reg1_rdata);
        assert(rs_reg2_rdata == 32'd0) else $fatal("Result Error: rst all registers and read register[%d]. {Result} is  {%x}, but expected {0000}.", rs_reg2_addr, rs_reg2_rdata);

        rs_reg1_addr <= rs_reg1_addr + 1;
        rs_reg2_addr <= rs_reg2_addr + 1;
    end 
    // 测试3：写入x31和x0寄存器，查看读出结果
    
    repeat (1) begin
        @(posedge clk);
        wr_reg_en <= 1;
        wr_reg_addr <= 5'd31;
        wr_wdata <= 32'h0100_0f0a;
    end
    
    repeat (1) begin
        @(posedge clk);
        wr_reg_en <= 1;
        wr_reg_addr <= 5'd0;
        wr_wdata <= 32'h0000_0fff;
    end
    #2;
    wr_reg_en = 0;
    rs_reg1_addr = 5'd31;
    rs_reg2_addr = 5'd31;
    #1;
    assert(rs_reg1_rdata == 32'h0100_0f0a) else $fatal("Result Error: write {0100_0f0a} to register[%d]. {Result} is  {%x}, but expected {0100_0f0a}.", rs_reg1_addr, rs_reg1_rdata);
    assert(rs_reg2_rdata == 32'h0100_0f0a) else $fatal("Result Error: write {0100_0f0a} to register[%d]. {Result} is  {%x}, but expected {0100_0f0a}.", rs_reg2_addr, rs_reg2_rdata);
    rs_reg1_addr = 0;
    rs_reg2_addr = 0;
    #1; 
    assert(rs_reg1_rdata == 32'd0) else $fatal("Result Error: write {%h} to register[%d]. {Result} is  {%x}, but expected {00000000}.", wr_wdata, rs_reg1_addr, rs_reg1_rdata);
    assert(rs_reg1_rdata == 32'd0) else $fatal("Result Error: write {%h} to register[%d]. {Result} is  {%x}, but expected {00000000}.", wr_wdata, rs_reg2_addr, rs_reg2_rdata);
    
    $finish;
end

reg_file #(
    .ADDR_WIDTH (5)  ,
    .DATAWIDTH  (32)
) reg_file_inst(
    .clk           (clk          ),
    .rst           (rst          ),
    .wr_reg_en     (wr_reg_en    ),
    .wr_reg_addr   (wr_reg_addr  ),
    .wr_wdata      (wr_wdata     ),
    .rs_reg1_addr  (rs_reg1_addr ),
    .rs_reg2_addr  (rs_reg2_addr ),
    .rs_reg1_rdata (rs_reg1_rdata),
    .rs_reg2_rdata (rs_reg2_rdata)
);

endmodule
