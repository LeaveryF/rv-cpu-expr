`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 15:48:39
// Design Name: 
// Module Name: ALU_controller
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


module ALU_controller (
    input  logic [3:0] funct,      // {funct7[5], funct3[2:0]}
    input  logic [1:0] ALUOP,
    output logic [1:0] ALUControl
);

  // funct[2:0] = funct3, funct[3] = funct7[5]
  always_comb begin
    case (ALUOP)
      2'b00:  // lw / sw → ALU does addition
      ALUControl = 2'b00;
      2'b01:  // beq → ALU does subtraction
      ALUControl = 2'b01;
      2'b10:  // R-type → check funct3 and funct7[5]
      case (funct)
        4'b0000: ALUControl = 2'b00;  // funct3=000, funct7[5]=0 → add
        4'b1000: ALUControl = 2'b01;  // funct3=000, funct7[5]=1 → sub
        4'b0111: ALUControl = 2'b10;  // funct3=111, funct7[5]=0 → and
        4'b0110: ALUControl = 2'b11;  // funct3=110, funct7[5]=0 → or
        default: ALUControl = 2'b00;  // unknown → add (safe default)
      endcase
      default: ALUControl = 2'b00;
    endcase
  end

endmodule
