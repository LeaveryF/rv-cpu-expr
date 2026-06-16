`timescale 1ns / 1ps

module tb_cpu_pad_post;

    // Clock and reset
    reg         clk_pad;
    reg         rst_n_pad;

    // IROM interface (connect to external pads)
    wire [31:0] irom_addr_pad;
    reg  [31:0] irom_data_pad;    // driven by testbench to simulate ROM read

    // DRAM interface
    wire [31:0] dram_addr_pad;
    wire [31:0] dram_wdata_pad;
    wire        dram_wen_pad;
    reg  [31:0] dram_rdata_pad;

    // Debug outputs
    wire        debug_wb_have_inst_pad;
    wire [31:0] debug_wb_pc_pad;
    wire        debug_wb_ena_pad;
    wire [4:0]  debug_wb_reg_pad;
    wire [31:0] debug_wb_value_pad;

    // Instantiate post-layout netlist (cpu_pad with PADs)
    cpu_pad u_cpu_pad (
        .clk_pad            (clk_pad),
        .rst_n_pad          (rst_n_pad),
        .irom_addr_pad      (irom_addr_pad),
        .irom_data_pad      (irom_data_pad),
        .dram_addr_pad      (dram_addr_pad),
        .dram_wdata_pad     (dram_wdata_pad),
        .dram_wen_pad       (dram_wen_pad),
        .dram_rdata_pad     (dram_rdata_pad),
        .debug_wb_have_inst_pad (debug_wb_have_inst_pad),
        .debug_wb_pc_pad        (debug_wb_pc_pad),
        .debug_wb_ena_pad       (debug_wb_ena_pad),
        .debug_wb_reg_pad       (debug_wb_reg_pad),
        .debug_wb_value_pad     (debug_wb_value_pad)
    );

    // SDF back-annotation
    initial begin
        $sdf_annotate("../output/cpu_pad_pt.sdf", tb_cpu_pad_post.u_cpu_pad);
    end

    // Clock generation: 50MHz (20ns period)
    always #10 clk_pad = ~clk_pad;

    // Simple test: reset + check basic operation
    initial begin
        clk_pad = 0;
        rst_n_pad = 1'b0;  // assert reset (active low)
        irom_data_pad = 32'h00000013;  // nop-ish: addi x0, x0, 0
        dram_rdata_pad = 32'h0;

        // Hold reset for 5 cycles
        repeat (5) @(posedge clk_pad);
        rst_n_pad = 1'b1;  // deassert reset

        // Run for 50 cycles, observe debug outputs
        repeat (50) @(posedge clk_pad);

        $display("Post-layout simulation completed.");
        $display("Debug: have_inst=%b pc=%h ena=%b reg=%d value=%h",
            debug_wb_have_inst_pad, debug_wb_pc_pad,
            debug_wb_ena_pad, debug_wb_reg_pad, debug_wb_value_pad);

        $finish;
    end

    // Dump VCD for waveform viewing
    initial begin
        $dumpfile("cpu_pad_post.vcd");
        $dumpvars(0, tb_cpu_pad_post);
    end

endmodule
