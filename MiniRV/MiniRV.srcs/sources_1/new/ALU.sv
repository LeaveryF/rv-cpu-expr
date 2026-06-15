`timescale 1ns / 1ps

module ALU #(
    parameter DATAWIDTH = 32
) (
    input  logic [DATAWIDTH - 1:0] A,
    input  logic [DATAWIDTH - 1:0] B,
    input  logic [3:0]             ALUControl,
    output logic [DATAWIDTH - 1:0] Result,
    output logic                   isTrue
);
    always_comb begin
        Result = '0;
        isTrue = 1'b0;

        unique case (ALUControl)
            4'b0000: Result = A + B;                                    // ADD

            4'b0001: Result = A - B;                                    // SUB

            4'b0010: Result = A & B;                                    // AND

            4'b0011: Result = A | B;                                    // OR

            4'b0100: Result = A ^ B;                                    // XOR

            4'b0101: Result = A << B[4:0];                              // SLL

            4'b0110: Result = A >> B[4:0];                              // SRL

            4'b0111: Result = $signed(A) >>> B[4:0];                   // SRA

            4'b1000: begin                                               // EQ (beq)
                isTrue = (A == B);
                Result = {31'b0, isTrue};
            end

            4'b1001: begin                                               // NE (bne)
                isTrue = (A != B);
                Result = {31'b0, isTrue};
            end

            4'b1010: begin                                               // signed < (blt, slt, slti)
                isTrue = ($signed(A) < $signed(B));
                Result = {31'b0, isTrue};
            end

            4'b1011: begin                                               // signed >= (bge)
                isTrue = ($signed(A) >= $signed(B));
                Result = {31'b0, isTrue};
            end

            4'b1100: begin                                               // unsigned < (bltu, sltu, sltiu)
                isTrue = (A < B);
                Result = {31'b0, isTrue};
            end

            4'b1101: begin                                               // unsigned >= (bgeu)
                isTrue = (A >= B);
                Result = {31'b0, isTrue};
            end

            default: Result = '0;
        endcase
    end
endmodule
