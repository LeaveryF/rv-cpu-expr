`timescale 1ns / 1ps

module ACTL (
    input  logic [6:0] opcode,
    input  logic [3:0] funct,        // {instr[30], instr[14:12]}
    output logic [3:0] ALUControl
);
    always_comb begin
        unique case (opcode)
            // R-type: decode funct = {funct7[5], funct3}
            7'b0110011: begin
                unique case (funct)
                    4'b0000: ALUControl = 4'b0000;  // add
                    4'b1000: ALUControl = 4'b0001;  // sub
                    4'b0111: ALUControl = 4'b0010;  // and
                    4'b0110: ALUControl = 4'b0011;  // or
                    4'b0100: ALUControl = 4'b0100;  // xor
                    4'b0001: ALUControl = 4'b0101;  // sll
                    4'b0101: ALUControl = 4'b0110;  // srl
                    4'b1101: ALUControl = 4'b0111;  // sra
                    4'b0010: ALUControl = 4'b1010;  // slt  (signed <)
                    4'b0011: ALUControl = 4'b1100;  // sltu (unsigned <)
                    default: ALUControl = 4'b0000;
                endcase
            end

            // I-type ALU immediate
            7'b0010011: begin
                unique case (funct[2:0])  // funct3 only
                    3'b000:  ALUControl = 4'b0000;  // addi
                    3'b111:  ALUControl = 4'b0010;  // andi
                    3'b110:  ALUControl = 4'b0011;  // ori
                    3'b100:  ALUControl = 4'b0100;  // xori
                    3'b001:  ALUControl = 4'b0101;  // slli
                    3'b101:  ALUControl = funct[3] ? 4'b0111 : 4'b0110;  // srai/srli
                    3'b010:  ALUControl = 4'b1010;  // slti  (signed <)
                    3'b011:  ALUControl = 4'b1100;  // sltiu (unsigned <)
                    default: ALUControl = 4'b0000;
                endcase
            end

            // Load / Store: address calculation uses ADD
            7'b0000011,   // lb, lbu, lh, lhu, lw
            7'b0100011:   // sb, sh, sw
                ALUControl = 4'b0000;  // add

            // jalr: rs1 + imm, same as add
            7'b1100111:
                ALUControl = 4'b0000;  // add

            // B-type branches
            7'b1100011: begin
                unique case (funct[2:0])
                    3'b000:  ALUControl = 4'b1000;  // beq
                    3'b001:  ALUControl = 4'b1001;  // bne
                    3'b100:  ALUControl = 4'b1010;  // blt  (signed <)
                    3'b110:  ALUControl = 4'b1100;  // bltu (unsigned <)
                    3'b101:  ALUControl = 4'b1011;  // bge  (signed >=)
                    3'b111:  ALUControl = 4'b1101;  // bgeu (unsigned >=)
                    default: ALUControl = 4'b0000;
                endcase
            end

            // U-type: lui, auipc — ALU does addition
            7'b0110111,   // lui — ALU result not used, but safe default
            7'b0010111:   // auipc — ALU does PC + imm
                ALUControl = 4'b0000;  // add

            // J-type: jal — ALU not used
            7'b1101111:
                ALUControl = 4'b0000;  // unused, safe default

            default:
                ALUControl = 4'b0000;
        endcase
    end
endmodule
