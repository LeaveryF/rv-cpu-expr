`timescale 1ns / 1ps

module Control (
    input  logic [6:0]  opcode,
    output logic [1:0]  NpcOp,         // 00:pc+4, 01:cond-branch, 10:jalr, 11:jal
    output logic        RegWrite,      // register file write enable
    output logic [1:0]  MemToReg,      // 00:ALU, 01:DM, 10:IMM, 11:PC+4
    output logic        MemWrite,      // data memory write enable
    output logic        OffsetOrigin,  // 0:imm, 1:ALU result (for jalr)
    output logic        ALUSrc,        // ALU B source: 0:rs2, 1:imm
    output logic        ALUSrcA        // ALU A source: 0:rs1, 1:PC (for auipc)
);
    always_comb begin
        unique case (opcode)
            // R-type: add, sub, and, or, xor, sll, srl, sra, slt, sltu
            7'b0110011: begin
                NpcOp       = 2'b00;   // pc + 4
                RegWrite    = 1'b1;
                MemToReg    = 2'b00;   // from ALU
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b0;    // from rs2
                ALUSrcA     = 1'b0;    // from rs1
            end

            // I-type ALU: addi, andi, ori, xori, slli, srli, srai, slti, sltiu
            7'b0010011: begin
                NpcOp       = 2'b00;
                RegWrite    = 1'b1;
                MemToReg    = 2'b00;   // from ALU
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b1;    // from imm
                ALUSrcA     = 1'b0;    // from rs1
            end

            // Load: lb, lbu, lh, lhu, lw
            7'b0000011: begin
                NpcOp       = 2'b00;
                RegWrite    = 1'b1;
                MemToReg    = 2'b01;   // from DM
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b1;    // from imm
                ALUSrcA     = 1'b0;    // from rs1
            end

            // Store: sb, sh, sw
            7'b0100011: begin
                NpcOp       = 2'b00;
                RegWrite    = 1'b0;
                MemToReg    = 2'b00;   // don't care
                MemWrite    = 1'b1;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b1;    // from imm
                ALUSrcA     = 1'b0;    // from rs1
            end

            // Branch: beq, bne, blt, bltu, bge, bgeu
            7'b1100011: begin
                NpcOp       = 2'b01;   // conditional: isTrue ? pc+offset : pc+4
                RegWrite    = 1'b0;
                MemToReg    = 2'b00;   // don't care
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;    // offset from imm
                ALUSrc      = 1'b0;    // from rs2 (for comparison)
                ALUSrcA     = 1'b0;    // from rs1
            end

            // LUI
            7'b0110111: begin
                NpcOp       = 2'b00;
                RegWrite    = 1'b1;
                MemToReg    = 2'b10;   // from IMM (bypass ALU)
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b0;    // don't care
                ALUSrcA     = 1'b0;    // don't care
            end

            // AUIPC
            7'b0010111: begin
                NpcOp       = 2'b00;
                RegWrite    = 1'b1;
                MemToReg    = 2'b00;   // from ALU (PC + imm)
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b1;    // from imm
                ALUSrcA     = 1'b1;    // from PC
            end

            // JAL
            7'b1101111: begin
                NpcOp       = 2'b11;   // pc + offset
                RegWrite    = 1'b1;
                MemToReg    = 2'b11;   // from PC+4
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;    // offset from imm
                ALUSrc      = 1'b0;    // don't care
                ALUSrcA     = 1'b0;    // don't care
            end

            // JALR
            7'b1100111: begin
                NpcOp       = 2'b10;   // (rs1+imm) & ~1
                RegWrite    = 1'b1;
                MemToReg    = 2'b11;   // from PC+4
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b1;    // offset from ALU result
                ALUSrc      = 1'b1;    // from imm
                ALUSrcA     = 1'b0;    // from rs1
            end

            default: begin
                NpcOp       = 2'b00;
                RegWrite    = 1'b0;
                MemToReg    = 2'b00;
                MemWrite    = 1'b0;
                OffsetOrigin = 1'b0;
                ALUSrc      = 1'b0;
                ALUSrcA     = 1'b0;
            end
        endcase
    end
endmodule
