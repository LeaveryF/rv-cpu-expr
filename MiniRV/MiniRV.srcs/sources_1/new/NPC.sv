`timescale 1ns / 1ps

module NPC #(
    parameter DATAWIDTH = 32
) (
    input  logic                   isTrue,
    input  logic [1:0]             npc_op,
    input  logic [DATAWIDTH - 1:0] pc,
    input  logic [DATAWIDTH - 1:0] offset,
    output logic [DATAWIDTH - 1:0] npc,
    output logic [DATAWIDTH - 1:0] pcadd4
);
    // pcadd4 is always pc + 4, used for jal/jalr write-back
    assign pcadd4 = pc + 32'd4;

    always_comb begin
        unique case (npc_op)
            2'b00:   npc = pc + 32'd4;                         // sequential
            2'b01:   npc = isTrue ? (pc + offset) : (pc + 32'd4); // conditional branch
            2'b10:   npc = offset & 32'hFFFFFFFE;              // jalr: (rs1+imm) & ~1
            2'b11:   npc = pc + offset;                        // jal: pc + imm
            default: npc = pc + 32'd4;
        endcase
    end
endmodule
