`timescale 1ns / 1ns

//===========================================================================
// cpu_pad — MiniRV CPU with IO PAD cells (top module for synthesis)
//===========================================================================
module cpu_pad (
    // External pads (chip pins)
    input  wire        rst_n_pad,           // async reset (active low, per PAD convention)
    input  wire        clk_pad,             // system clock

    // IROM interface pads
    output wire [31:0] irom_addr_pad,       // instruction address → IROM
    input  wire [31:0] irom_data_pad,       // instruction data ← IROM

    // DRAM interface pads
    output wire [31:0] dram_addr_pad,       // data address → DRAM
    output wire [31:0] dram_wdata_pad,      // write data → DRAM
    output wire        dram_wen_pad,        // write enable → DRAM
    input  wire [31:0] dram_rdata_pad,      // read data ← DRAM

    // Debug pads (optional, for verification)
    output wire        debug_wb_have_inst_pad,
    output wire [31:0] debug_wb_pc_pad,
    output wire        debug_wb_ena_pad,
    output wire [4:0]  debug_wb_reg_pad,
    output wire [31:0] debug_wb_value_pad
);

    //===========================================================================
    // Internal nets (core side of PAD)
    //===========================================================================
    wire        rst_n_core;       // reset after PI pad (active low)
    wire        cpu_rst;          // active high after inversion
    wire        cpu_clk;
    wire [31:0] irom_addr;
    wire [31:0] irom_data;
    wire [31:0] dram_addr;
    wire [31:0] dram_wdata;
    wire        dram_wen;
    wire [31:0] dram_rdata;
    wire        debug_wb_have_inst;
    wire [31:0] debug_wb_pc;
    wire        debug_wb_ena;
    wire [4:0]  debug_wb_reg;
    wire [31:0] debug_wb_value;

    //===========================================================================
    // Input PADs (PI: external pad → core)
    //===========================================================================

    // Reset: external active-low → internal active-high
    PI i_rst (.PAD(rst_n_pad), .C(rst_n_core));
    // Invert reset to active-high
    assign cpu_rst = ~rst_n_core;

    // Clock
    PI i_clk (.PAD(clk_pad), .C(cpu_clk));

    // IROM data bus (32-bit input)
    genvar ii;
    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_pi_irom
            PI i_irom (.PAD(irom_data_pad[ii]), .C(irom_data[ii]));
        end
    endgenerate

    // DRAM read data bus (32-bit input)
    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_pi_dram_r
            PI i_dram_r (.PAD(dram_rdata_pad[ii]), .C(dram_rdata[ii]));
        end
    endgenerate

    //===========================================================================
    // Output PADs (PO8: core → external pad, 8mA drive)
    //===========================================================================

    // IROM address bus (32-bit output)
    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_po_irom
            PO8 o_irom (.I(irom_addr[ii]), .PAD(irom_addr_pad[ii]));
        end
    endgenerate

    // DRAM address bus (32-bit output)
    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_po_dram_a
            PO8 o_dram_a (.I(dram_addr[ii]), .PAD(dram_addr_pad[ii]));
        end
    endgenerate

    // DRAM write data bus (32-bit output)
    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_po_dram_w
            PO8 o_dram_w (.I(dram_wdata[ii]), .PAD(dram_wdata_pad[ii]));
        end
    endgenerate

    // DRAM write enable
    PO8 o_dram_wen (.I(dram_wen), .PAD(dram_wen_pad));

    // Debug signals
    PO8 o_dbg_inst (.I(debug_wb_have_inst), .PAD(debug_wb_have_inst_pad));

    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_po_dbg_pc
            PO8 o_dbg_pc (.I(debug_wb_pc[ii]), .PAD(debug_wb_pc_pad[ii]));
        end
    endgenerate

    PO8 o_dbg_ena (.I(debug_wb_ena), .PAD(debug_wb_ena_pad));

    generate
        for (ii = 0; ii < 5; ii = ii + 1) begin : gen_po_dbg_reg
            PO8 o_dbg_reg (.I(debug_wb_reg[ii]), .PAD(debug_wb_reg_pad[ii]));
        end
    endgenerate

    generate
        for (ii = 0; ii < 32; ii = ii + 1) begin : gen_po_dbg_val
            PO8 o_dbg_val (.I(debug_wb_value[ii]), .PAD(debug_wb_value_pad[ii]));
        end
    endgenerate

    //===========================================================================
    // CPU Core (without IROM / DRAM)
    //===========================================================================
    myCPU Core_cpu (
        .cpu_rst            (cpu_rst),
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

endmodule