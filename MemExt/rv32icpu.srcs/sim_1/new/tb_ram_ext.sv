`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/18/2025 02:11:21 PM
// Design Name: 
// Module Name: tb_ram_ext
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


module tb_ram_ext();

localparam DATAWIDTH   =   32 ;
localparam RAMDEPTH    =   10 ;

logic                   clk   ;
logic                   ena   ;
logic                   wen   ;
logic [DATAWIDTH - 1:0] ram_data_i, ram_data_o;
logic [RAMDEPTH  - 1:0] ram_addr_i  ;

mini_ram_bitext #(
    .DATAWIDTH  (DATAWIDTH),
    .RAMDEPTH   (RAMDEPTH)
) mini_ram_inst(
    .clk        (clk    ),
    .wen        (wen    ),
    .ena        (ena    ),    
    .ram_addr_i (ram_addr_i),
    .ram_data_i (ram_data_i),
    .ram_data_o (ram_data_o) 
);

always #1 clk = ~clk;

initial begin
    clk = 0;
    ena = 1;
    wen = 1;

    ram_addr_i = 10'h1F0;
    ram_data_i = 32'd114514;
    #2;
    wen = 0;
    assert(ram_data_o == 32'd114514) else $fatal("Result Error: write 32'd114514 to addr 0x1F0 , but {out} is  {%x}.", ram_data_o);

    wen = 1;
    ram_addr_i = 10'h1F5;
    ram_data_i = 32'd514115;
    #2;
    wen = 0;
    assert(ram_data_o == 32'd514115) else $fatal("Result Error: write 32'd514115 to addr 0x1F5 , but {out} is  {%x}.", ram_data_o);
    
    wen = 1;
    ram_addr_i = 10'h2FF;
    ram_data_i = 32'd114114;
    #2;
    wen = 0;
    assert(ram_data_o == 32'd114114) else $fatal("Result Error: write 32'd114114 to addr 0x2FF , but {out} is  {%x}.", ram_data_o);
    
    wen = 0;
    ram_addr_i = 10'h1F5;
    ram_data_i = 32'd0;
    #2;
    assert(ram_data_o == 32'd514115) else $fatal("Result Error: addr 0x1F5=32'd514115 , but {out} is  {%x}.", ram_data_o);
    
    ena = 0;
    ram_addr_i = 10'h1F0;
    ram_data_i = 32'd0;
    #2;
    assert(ram_data_o == 32'd114514) else $fatal("Result Error: addr 0x1F0=32'd114514 , but {out} is  {%x}.", ram_data_o);

    $finish;
end    

endmodule
