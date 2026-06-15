`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/11 10:39:54
// Design Name: 
// Module Name: imm_gen
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


module imm_gen #(
    parameter DATAWIDTH = 32
) (
    input  logic [           31:0] instr,
    output logic [DATAWIDTH - 1:0] imm
);

  // Instruction opcode determines the immediate format
  // Only I-type (lw), S-type (sw), B-type (beq) are used in the core subset
  always_comb begin
    unique case (instr[6:0])
      7'b0000011:  // I-type: lw — 12-bit signed immediate in instr[31:20]
      imm = {{20{instr[31]}}, instr[31:20]};
      7'b0100011:  // S-type: sw — 12-bit signed immediate
      imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      7'b1100011:  // B-type: beq — 13-bit signed immediate (bit 0 always 0)
      imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      default:  // R-type or others — immediate not used
      imm = '0;
    endcase
  end

endmodule
