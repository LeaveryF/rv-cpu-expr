`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/15 09:05:26
// Design Name: 
// Module Name: tb_data_ram
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


module tb_data_ram();

localparam DATAWIDTH   =   32 ;
localparam RAMWIDTH    =   8  ;
localparam RAMDEPTH    =   16 ;

logic                   clk      ;
logic                   rst      ;
logic                   ena      ;
logic                   wen      ;
logic [DATAWIDTH - 1:0] din      ;
logic [DATAWIDTH - 1:0] daddr    ;
logic [DATAWIDTH - 1:0] dout     ;

always #1 clk = ~clk;

initial begin
    // 1. 向RAM第一号和最后一号地址写入数据，并进行读出检查
    clk = 0;
    rst = 0;
    ena = 1;
    wen = 0;
    $readmemh("/home/ketted/Desktop/cs2022_2/rv32icpu/rv32icpu.srcs/sources_1/new/first_4_byte.txt", data_ram_inst.ram, 0);
    $readmemh("/home/ketted/Desktop/cs2022_2/rv32icpu/rv32icpu.srcs/sources_1/new/last_4_byte.txt", data_ram_inst.ram, 65532);

    daddr = 32'd0;
    #2;
    assert(dout == 32'h01efcdab) else $fatal("Result Error: initial {01efcdab} to address 0, but {dout} is  {%x}.", dout);

    daddr = 32'd65532;
    #2;
    assert(dout == 32'habcdef01) else $fatal("Result Error: initial {abcdef01} to address 65532, but {dout} is  {%x}.", dout);
    // 2. 修改第最后一号地址的数据，并进行写优先检查
    wen = 1;
    din = 32'hffffffff;
    
    #2;
    assert(dout == 32'hffffffff) else $fatal("Result Error: write {ffffffff} to address 65532, but {dout} is  {%x}, expect {ffffffff}.", dout);

    // 3. 使用rst复位，检查第一号和最后一号是否为0
    rst = 1;
    wen = 0;
    #2;
    rst = 0;
    daddr = 32'd0;
    #2;
    assert(dout == 32'h0) else $fatal("Result Error: use rst initial {0} to all addresses, and check address[0], but {dout} is  {%x}, expect {00000000}.", dout);

    daddr = 32'd65532;
    #2;
    assert(dout == 32'h0) else $fatal("Result Error: use rst initial {0} to all addresses, and check address[0], but {dout} is  {%x}, expect {00000000}.", dout);
    
    // 4. 关闭ena，尝试写入第一个地址，检查是否写入成功
    ena = 0;
    wen = 1;
    daddr = 32'd0;
    din = 32'h0a0a0a0a;
    #2;

    wen = 0;
    assert(dout == 32'h0) else $fatal("Result Error: disable wen  but could still write.");
    $finish;
end

data_ram #(
    .DATAWIDTH   (32)  ,
    .RAMWIDTH    (8 )  ,
    .RAMDEPTH    (16)  
)data_ram_inst(
    .clk      (clk  )    ,
    .rst      (rst  )    ,
    .ena      (ena  )    ,
    .wen      (wen  )    ,
    .din      (din  )    ,
    .daddr    (daddr)    ,
    .dout     (dout )    
);

endmodule
