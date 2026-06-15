`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/11 11:03:01
// Design Name: 
// Module Name: tb_imm_gen
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


module tb_imm_gen;

localparam DATAWIDTH = 32;

logic [31:0]            instr   ;
logic [DATAWIDTH - 1:0] imm     ;

initial begin
    instr = 32'h00112623; // sw x1, 12(sp)
    #1
    assert(imm == 32'd12) else $fatal("instrution is {32'h00112623} and {imm} is  {%d}, but expected {12}.", imm);

    instr = 32'h00812403; // lw x8, 8(sp)
    #1
    assert(imm == 32'd8) else $fatal("instrution is {32'h00812403} and {imm} is  {%d}, but expected {8}.", imm);

    instr = 32'h01e40863; // beq x8, x30, 16
    #1
    assert(imm == 32'd16) else $fatal("instrution is {32'h01e40863} and {imm} is  {%d}, but expected {16}.", imm);
    $finish;
end


imm_gen#(
    .DATAWIDTH  (DATAWIDTH)	
) imm_gen_inst (
    .instr      (instr),
    .imm        (imm)       
);

endmodule
