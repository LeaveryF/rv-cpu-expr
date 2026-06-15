`timescale 1ns / 1ps

module miniRV_SoC (
    input  logic         fpga_rst,
    input  logic         fpga_clk,

    output logic         debug_wb_have_inst,
    output logic [31:0]  debug_wb_pc,
    output logic         debug_wb_ena,
    output logic [ 4:0]  debug_wb_reg,
    output logic [31:0]  debug_wb_value
);
    logic cpu_clk;
    assign cpu_clk = fpga_clk;

    // Signals between myCPU and IROM/DRAM
    logic [31:0] irom_addr;
    logic [31:0] irom_data;
    logic [31:0] dram_addr;
    logic [31:0] dram_wdata;
    logic        dram_wen;
    logic [31:0] dram_rdata;

    // ========================================================================
    // CPU Core
    // ========================================================================
    myCPU Core_cpu (
        .cpu_rst            (fpga_rst),
        .cpu_clk            (cpu_clk),

        .irom_addr          (irom_addr),
        .irom_data          (irom_data),

        .dram_addr          (dram_addr),
        .dram_wdata         (dram_wdata),
        .dram_wen           (dram_wen),
        .dram_rdata         (dram_rdata),

        .debug_wb_have_inst (debug_wb_have_inst),
        .debug_wb_pc        (debug_wb_pc),
        .debug_wb_ena       (debug_wb_ena),
        .debug_wb_reg       (debug_wb_reg),
        .debug_wb_value     (debug_wb_value)
    );

    // ========================================================================
    // Instruction ROM
    // PC is byte-addressed, IROM is word-addressed (32-bit words)
    // IROM.a = PC[17:2] selects word within 256KB address space
    // ========================================================================
    IROM Mem_IROM (
        .a   (irom_addr[17:2]),
        .spo (irom_data)
    );

    // ========================================================================
    // Data RAM
    // ALU result is byte-addressed, DRAM is word-addressed (32-bit words)
    // ========================================================================
    DRAM Mem_DRAM (
        .clk (cpu_clk),
        .a   (dram_addr[17:2]),
        .spo (dram_rdata),
        .we  (dram_wen),
        .d   (dram_wdata)
    );

endmodule
