`timescale 1ns / 1ps

module IMMGEN #(
    parameter DATAWIDTH = 32
) (
    input  logic [31:0]            instr,
    output logic [DATAWIDTH - 1:0] imm
);
    always_comb begin
        unique case (instr[6:0])
            // I-type: lw, lb, lbu, lh, lhu, addi, andi, ori, xori,
            //         slli, srli, srai, slti, sltiu, jalr
            7'b0000011,  // load
            7'b0010011,  // ALU immediate
            7'b1100111:  // jalr
                imm = { {20{instr[31]}}, instr[31:20] };

            // S-type: sb, sh, sw
            7'b0100011:
                imm = { {20{instr[31]}}, instr[31:25], instr[11:7] };

            // B-type: beq, bne, blt, bltu, bge, bgeu
            7'b1100011:
                imm = { {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 };

            // U-type: lui, auipc
            7'b0110111,  // lui
            7'b0010111:  // auipc
                imm = { instr[31:12], 12'b0 };

            // J-type: jal
            7'b1101111:
                imm = { {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 };

            default:
                imm = '0;
        endcase
    end
endmodule
