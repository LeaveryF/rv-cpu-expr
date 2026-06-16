`timescale 1ns / 1ps

module MUX2_1 #(
    parameter WIDTH = 32
) (
    input  logic [WIDTH - 1:0] A,
    input  logic [WIDTH - 1:0] B,
    input  logic               Control,
    output logic [WIDTH - 1:0] Result
);
    assign Result = Control ? B : A;
endmodule
