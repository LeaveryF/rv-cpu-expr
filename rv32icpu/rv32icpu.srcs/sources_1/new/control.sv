`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 16:18:52
// Design Name: 
// Module Name: control
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


module control (
    input  logic [6:0] opcode,
    output logic       Branch,
    output logic       MemToReg,
    output logic       MemWrite,
    output logic [1:0] ALUOP,
    output logic       ALUSrc,
    output logic       RegWrite
);

  // Control signal decode table (Figure 4-8)
  // R-type:  0110011 → ALUSrc=0, MemToReg=0, RegWrite=1, MemWrite=0, Branch=0, ALUOP=10
  // lw:      0000011 → ALUSrc=1, MemToReg=1, RegWrite=1, MemWrite=0, Branch=0, ALUOP=00
  // sw:      0100011 → ALUSrc=1, MemToReg=0, RegWrite=0, MemWrite=1, Branch=0, ALUOP=00
  // beq:     1100011 → ALUSrc=0, MemToReg=0, RegWrite=0, MemWrite=0, Branch=1, ALUOP=01
  always_comb begin
    unique case (opcode)
      7'b0110011: begin  // R-type
        ALUSrc   = 1'b0;
        MemToReg = 1'b0;
        RegWrite = 1'b1;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOP    = 2'b10;
      end
      7'b0000011: begin  // lw (I-type load)
        ALUSrc   = 1'b1;
        MemToReg = 1'b1;
        RegWrite = 1'b1;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOP    = 2'b00;
      end
      7'b0100011: begin  // sw (S-type store)
        ALUSrc   = 1'b1;
        MemToReg = 1'b0;
        RegWrite = 1'b0;
        MemWrite = 1'b1;
        Branch   = 1'b0;
        ALUOP    = 2'b00;
      end
      7'b1100011: begin  // beq (B-type branch)
        ALUSrc   = 1'b0;
        MemToReg = 1'b0;
        RegWrite = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b1;
        ALUOP    = 2'b01;
      end
      default: begin
        ALUSrc   = 1'b0;
        MemToReg = 1'b0;
        RegWrite = 1'b0;
        MemWrite = 1'b0;
        Branch   = 1'b0;
        ALUOP    = 2'b00;
      end
    endcase
  end

endmodule
