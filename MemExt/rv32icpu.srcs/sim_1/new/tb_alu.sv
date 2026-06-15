`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/05 13:39:43
// Design Name: 
// Module Name: tb_alu
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


module tb_alu();

parameter DATAWIDTH = 8;

logic [DATAWIDTH - 1:0] A                ;
logic [DATAWIDTH - 1:0] B                ;
logic [2:0]             alucontrol       ;
logic [DATAWIDTH:0] a                    ;
logic [DATAWIDTH:0] b                    ;
logic [1:0]             ALUControl       ;

logic [DATAWIDTH - 1:0] Result           ;
logic [DATAWIDTH - 1:0] result           ;
logic N, Z, V, C                         ;
logic overflow, carry                    ;

initial begin
    // 结果测试
    for (alucontrol = 3'b0; alucontrol <= 2'b11; alucontrol = alucontrol + 1) begin
        for (a = 9'h0; a <= 8'hff; a = a + 1) begin
            for (b = 9'h0; b <= 8'hff; b = b + 1) begin
                A = a[7:0];
                B = b[7:0];
                ALUControl = alucontrol[1:0];
                if (ALUControl == 2'b0) begin
                    #1 assert(Result == A + B) else $fatal("Result Error: {A, B, ALUControl} is {%x, %x, %x} and {Result} is  {%x}, but expected {%x}.", A, B, ALUControl, Result, A + B);
                    overflow = A[DATAWIDTH - 1] == B[DATAWIDTH - 1] && A[DATAWIDTH - 1] != Result[DATAWIDTH - 1];
                    assert(V == overflow) else $fatal("V flag Error: {A, B, ALUControl} is {%x, %x, %x} and {V} is  {%x}, but expected {%x}.", A, B, ALUControl, V, overflow);
                    {carry, result} = A + B;
                    assert(C == carry) else $fatal("C flag Error: {A, B, ALUControl} is {%x, %x, %x} and {C} is  {%x}, but expected {%x}.", A, B, ALUControl, C, carry);
                end else if (ALUControl == 2'b1) begin
                    #1 assert(Result == A - B) else $fatal("Result Error: {A, B, ALUControl} is {%x, %x, %x} and {Result} is  {%x}, but expected {%x}.", A, B, ALUControl, Result, A - B);
                    overflow = A[DATAWIDTH - 1] != B[DATAWIDTH - 1] && A[DATAWIDTH - 1] != Result[DATAWIDTH - 1];
                    assert(V == overflow) else $fatal("V flag Error: {A, B, ALUControl} is {%x, %x, %x} and {V} is  {%x}, but expected {%x}.", A, B, ALUControl, V, overflow);
                    carry = A >= B;
                    assert(C == carry) else $fatal("C flag Error: {A, B, ALUControl} is {%x, %x, %x} and {C} is  {%x}, but expected {%x}.", A, B, ALUControl, C, carry);
                end else if (ALUControl == 2'b10)
                    #1 assert(Result == (A & B)) else $fatal("Result Error: {A, B, ALUControl} is {%x, %x, %x} and {Result} is  {%x}, but expected {%x}.", A, B, ALUControl, Result, A & B);
                else if (ALUControl == 2'b11)
                    #1 assert(Result == (A | B)) else $fatal("Result Error: {A, B, ALUControl} is {%x, %x, %x} and {Result} is  {%x}, but expected {%x}.", A, B, ALUControl, Result, A | B);

                assert((Result != 0) ^ Z) else $fatal("Z flag Error: {A, B, ALUControl} is {%x, %x, %x} and {Z} is  {%x}, but expected {%x}.", A, B, ALUControl, Z, ~(Result == 0));
                assert((Result[DATAWIDTH - 1] == 0) ^ N) else $fatal("N flag Error: {A, B, ALUControl} is {%x, %x, %x} and {N} is  {%x}, but expected {%x}.", A, B, ALUControl, N, Result[DATAWIDTH - 1] == 1);
            end
        end
    end
    $finish;
end


alu#(
    .DATAWIDTH   (DATAWIDTH)
)
alu_inst(
    .A           (A         ),
    .B           (B         ),
    .ALUControl  (ALUControl),
    .Result      (Result    ),
    .N           (N         ),
    .Z           (Z         ),
    .V           (V         ),
    .C           (C         )
);

endmodule
