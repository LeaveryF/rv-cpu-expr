`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/15 08:22:59
// Design Name: 
// Module Name: tb_instr_rom
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


module tb_instr_rom();

localparam DATAWIDTH   =   32 ;
localparam RAMWIDTH    =   8  ;
localparam RAMDEPTH    =   16 ;

logic                   ena   ;
logic [DATAWIDTH - 1:0] daddr ;
logic [DATAWIDTH - 1:0] dout  ;

instr_rom #(
    .DATAWIDTH  (32),
    .RAMWIDTH   (8),
    .RAMDEPTH   (16)
)instr_rom_inst(
    .ena        (ena    ),  
    .daddr      (daddr  ),   
    .dout       (dout   )    
);


initial begin
    ena = 1;
    $readmemh("/home/ketted/Desktop/cs2022_2/rv32icpu/rv32icpu.srcs/sources_1/new/first_4_byte.txt", instr_rom_inst.rom, 0);
    $readmemh("/home/ketted/Desktop/cs2022_2/rv32icpu/rv32icpu.srcs/sources_1/new/last_4_byte.txt", instr_rom_inst.rom, 65532);

    daddr = 32'd0;
    #2;
    assert(dout == 32'h01efcdab) else $fatal("Result Error: initial {abcd} to address 0, but {dout} is  {%x}.", dout);

    daddr = 32'd65532;
    #2;
    assert(dout == 32'habcdef01) else $fatal("Result Error: initial {abcd} to address 65532, but {dout} is  {%x}.", dout);

    $finish;
end    

endmodule
