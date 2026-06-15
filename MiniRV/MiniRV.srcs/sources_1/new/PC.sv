`timescale 1ns / 1ps

module PC #(
    parameter DATAWIDTH = 32
) (
    input  logic                   clk,
    input  logic                   rst,
    input  logic [DATAWIDTH - 1:0] npc,
    output logic [DATAWIDTH - 1:0] pc_out
);
    always_ff @(posedge clk, posedge rst) begin
        if (rst) pc_out <= '0;
        else     pc_out <= npc;
    end
endmodule
