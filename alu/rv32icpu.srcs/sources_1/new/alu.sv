`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/05 13:26:52
// Design Name: 
// Module Name: alu
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


module alu #(
    parameter DATAWIDTH = 32
) (
    input  logic [DATAWIDTH - 1:0] A,
    input  logic [DATAWIDTH - 1:0] B,
    input  logic [            1:0] ALUControl,
    output logic [DATAWIDTH - 1:0] Result,
    output logic                   N,
    output logic                   Z,
    output logic                   V,
    output logic                   C
);

  // Extended-width signal for carry-out computation in addition
  logic [DATAWIDTH:0] add_extended;

  always_comb begin
    case (ALUControl)
      2'b00: begin  // Add
        add_extended = {1'b0, A} + {1'b0, B};
        Result = add_extended[DATAWIDTH-1:0];
        C = add_extended[DATAWIDTH];
        // Overflow for signed addition: same sign operands, result sign differs
        V = (A[DATAWIDTH-1] == B[DATAWIDTH-1]) && (Result[DATAWIDTH-1] != A[DATAWIDTH-1]);
      end
      2'b01: begin  // Sub
        Result = A - B;
        // Subtract with carry: C=1 if A>=B (unsigned), C=0 otherwise
        C = (A >= B);
        // Overflow for signed subtraction: different sign operands, result sign differs from A
        V = (A[DATAWIDTH-1] != B[DATAWIDTH-1]) && (Result[DATAWIDTH-1] != A[DATAWIDTH-1]);
      end
      2'b10: begin  // And
        Result = A & B;
        C = 1'b0;
        V = 1'b0;
      end
      2'b11: begin  // Or
        Result = A | B;
        C = 1'b0;
        V = 1'b0;
      end
      default: begin
        Result = '0;
        C = 1'b0;
        V = 1'b0;
      end
    endcase

    // Flag outputs — common to all operations
    N = Result[DATAWIDTH-1];  // Negative: MSB of result
    Z = (Result == '0);  // Zero: result is all zeros
  end

endmodule
