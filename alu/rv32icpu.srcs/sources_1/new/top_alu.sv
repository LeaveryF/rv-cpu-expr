`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/06 10:37:47
// Design Name: 
// Module Name: top_alu
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


module top_alu#(
    parameter   DATAWIDTH = 8	
)(
    input  logic [DATAWIDTH - 1:0]  A           ,
    input  logic [DATAWIDTH - 1:0]  B           ,
    input  logic [1:0]              ALUControl  ,
    output logic [DATAWIDTH - 1:0]  Result      ,
    output logic                    N           ,
    output logic                    Z           ,
    output logic                    V           ,
    output logic                    C           
);

    alu#(
        .DATAWIDTH   (DATAWIDTH)
    )
    alu_inst(
        .A           (A         ),
        .B           (B         ),
        .ALUControl  (ALUControl),
        .Result      (Result    ),
        .N           (N         ),
        .Z           (Z         ),
        .V           (V         ),
        .C           (C         )
    );
    
endmodule
