`timescale 1ns / 1ps

module MUX4_1 #(
    parameter WIDTH = 32
) (
    input  logic [WIDTH - 1:0] A,
    input  logic [WIDTH - 1:0] B,
    input  logic [WIDTH - 1:0] C,
    input  logic [WIDTH - 1:0] D,
    input  logic [1:0]         Control,
    output logic [WIDTH - 1:0] Result
);
    always_comb begin
        unique case (Control)
            2'b00:   Result = A;
            2'b01:   Result = B;
            2'b10:   Result = C;
            2'b11:   Result = D;
            default: Result = A;
        endcase
    end
endmodule
