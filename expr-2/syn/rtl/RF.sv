`timescale 1ns / 1ps

module RF #(
    parameter ADDR_WIDTH = 5,
    parameter DATAWIDTH  = 32
) (
    input  logic                    clk,
    input  logic                    rst,
    input  logic                    wen,
    input  logic [ADDR_WIDTH - 1:0] waddr,
    input  logic [DATAWIDTH - 1:0]  wdata,
    input  logic [ADDR_WIDTH - 1:0] rR1,
    input  logic [ADDR_WIDTH - 1:0] rR2,
    output logic [DATAWIDTH - 1:0]  rR1_data,
    output logic [DATAWIDTH - 1:0]  rR2_data
);
    logic [DATAWIDTH - 1:0] reg_bank [31:0];

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) reg_bank[i] <= '0;
        end else if (wen) begin
            if (waddr != 5'd0) reg_bank[waddr] <= wdata;
        end
    end

    assign rR1_data = (rR1 == 5'd0) ? '0 : reg_bank[rR1];
    assign rR2_data = (rR2 == 5'd0) ? '0 : reg_bank[rR2];
endmodule
