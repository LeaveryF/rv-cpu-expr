`timescale 1ns / 1ps

module myCPU (
    input  logic         cpu_rst,
    input  logic         cpu_clk,

    // Interface to IROM
    output logic [31:0]  irom_addr,
    input  logic [31:0]  irom_data,

    // Interface to DRAM
    output logic [31:0]  dram_addr,
    output logic [31:0]  dram_wdata,
    output logic         dram_wen,
    input  logic [31:0]  dram_rdata,

    // Debug Interface
    output logic         debug_wb_have_inst,
    output logic [31:0]  debug_wb_pc,
    output logic         debug_wb_ena,
    output logic [ 4:0]  debug_wb_reg,
    output logic [31:0]  debug_wb_value
);
    // ========================================================================
    // Internal signals
    // ========================================================================
    logic [31:0] pc_out, npc, pcadd4;
    logic [31:0] instr;
    logic [6:0]  opcode;
    logic [3:0]  funct;          // {funct7[5], funct3}

    // Control signals
    logic [1:0]  NpcOp;
    logic        RegWrite;
    logic [1:0]  MemToReg;
    logic        MemWrite;
    logic        OffsetOrigin;
    logic        ALUSrc;
    logic        ALUSrcA;

    // ALU signals
    logic [3:0]  ALUControl;
    logic [31:0] alu_a, alu_b, alu_result;
    logic        isTrue;

    // RF signals
    logic [4:0]  rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_rdata, rs2_rdata, wb_data;

    // IMMGEN
    logic [31:0] imm;

    // NPC offset
    logic [31:0] npc_offset;

    // Load/Store extension
    logic [2:0]  funct3;
    logic [1:0]  addr_low;
    logic [31:0] load_data;
    logic [31:0] store_data;

    // ========================================================================
    // Decode
    // ========================================================================
    assign instr    = irom_data;
    assign opcode   = instr[6:0];
    assign funct    = {instr[30], instr[14:12]};
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign rd_addr  = instr[11:7];

    // ========================================================================
    // PC
    // ========================================================================
    PC #(
        .DATAWIDTH(32)
    ) pc_inst (
        .clk    (cpu_clk),
        .rst    (cpu_rst),
        .npc    (npc),
        .pc_out (pc_out)
    );

    assign irom_addr = pc_out;
    assign funct3   = instr[14:12];
    assign addr_low = alu_result[1:0];

    // ========================================================================
    // Control Unit
    // ========================================================================
    Control control_inst (
        .opcode       (opcode),
        .NpcOp        (NpcOp),
        .RegWrite     (RegWrite),
        .MemToReg     (MemToReg),
        .MemWrite     (MemWrite),
        .OffsetOrigin (OffsetOrigin),
        .ALUSrc       (ALUSrc),
        .ALUSrcA      (ALUSrcA)
    );

    // ========================================================================
    // ALU Controller
    // ========================================================================
    ACTL ACTL_inst (
        .opcode     (opcode),
        .funct      (funct),
        .ALUControl (ALUControl)
    );

    // ========================================================================
    // Register File
    // ========================================================================
    RF #(
        .ADDR_WIDTH(5),
        .DATAWIDTH (32)
    ) rf_inst (
        .clk      (cpu_clk),
        .rst      (cpu_rst),
        .wen      (RegWrite),
        .waddr    (rd_addr),
        .wdata    (wb_data),
        .rR1      (rs1_addr),
        .rR2      (rs2_addr),
        .rR1_data (rs1_rdata),
        .rR2_data (rs2_rdata)
    );

    // ========================================================================
    // Immediate Generator
    // ========================================================================
    IMMGEN #(
        .DATAWIDTH(32)
    ) imm_gen_inst (
        .instr (instr),
        .imm   (imm)
    );

    // ========================================================================
    // ALU A input MUX (rs1 vs PC, for auipc)
    // ========================================================================
    MUX2_1 #(
        .WIDTH(32)
    ) mux_alu_a (
        .A       (rs1_rdata),
        .B       (pc_out),
        .Control (ALUSrcA),
        .Result  (alu_a)
    );

    // ========================================================================
    // ALU B input MUX (rs2 vs imm)
    // ========================================================================
    MUX2_1 #(
        .WIDTH(32)
    ) mux_alu_b (
        .A       (rs2_rdata),
        .B       (imm),
        .Control (ALUSrc),
        .Result  (alu_b)
    );

    // ========================================================================
    // ALU
    // ========================================================================
    ALU #(
        .DATAWIDTH(32)
    ) alu_inst (
        .A          (alu_a),
        .B          (alu_b),
        .ALUControl (ALUControl),
        .Result     (alu_result),
        .isTrue     (isTrue)
    );

    // ========================================================================
    // NPC Offset MUX (imm vs ALU result, for jalr)
    // ========================================================================
    MUX2_1 #(
        .WIDTH(32)
    ) mux_npc_offset (
        .A       (imm),
        .B       (alu_result),
        .Control (OffsetOrigin),
        .Result  (npc_offset)
    );

    // ========================================================================
    // NPC
    // ========================================================================
    NPC #(
        .DATAWIDTH(32)
    ) npc_inst (
        .isTrue (isTrue),
        .npc_op (NpcOp),
        .pc     (pc_out),
        .offset (npc_offset),
        .npc    (npc),
        .pcadd4 (pcadd4)
    );

    // ========================================================================
    // Load extension: extract byte/halfword, sign/zero extend
    // ========================================================================
    always_comb begin
        unique case (opcode)
            7'b0000011: begin  // Load instructions
                unique case (funct3)
                    3'b000: begin  // lb
                        unique case (addr_low)
                            2'b00: load_data = { {24{dram_rdata[ 7]}}, dram_rdata[ 7: 0] };
                            2'b01: load_data = { {24{dram_rdata[15]}}, dram_rdata[15: 8] };
                            2'b10: load_data = { {24{dram_rdata[23]}}, dram_rdata[23:16] };
                            2'b11: load_data = { {24{dram_rdata[31]}}, dram_rdata[31:24] };
                        endcase
                    end
                    3'b001: begin  // lh
                        if (addr_low[1])
                            load_data = { {16{dram_rdata[31]}}, dram_rdata[31:16] };
                        else
                            load_data = { {16{dram_rdata[15]}}, dram_rdata[15: 0] };
                    end
                    3'b010: load_data = dram_rdata;  // lw
                    3'b100: begin  // lbu
                        unique case (addr_low)
                            2'b00: load_data = { 24'b0, dram_rdata[ 7: 0] };
                            2'b01: load_data = { 24'b0, dram_rdata[15: 8] };
                            2'b10: load_data = { 24'b0, dram_rdata[23:16] };
                            2'b11: load_data = { 24'b0, dram_rdata[31:24] };
                        endcase
                    end
                    3'b101: begin  // lhu
                        if (addr_low[1])
                            load_data = { 16'b0, dram_rdata[31:16] };
                        else
                            load_data = { 16'b0, dram_rdata[15: 0] };
                    end
                    default: load_data = dram_rdata;
                endcase
            end
            default: load_data = dram_rdata;
        endcase
    end

    // ========================================================================
    // Store merge: read-modify-write for sb/sh
    // ========================================================================
    always_comb begin
        unique case (opcode)
            7'b0100011: begin  // Store instructions
                unique case (funct3)
                    3'b000: begin  // sb
                        unique case (addr_low)
                            2'b00: store_data = { dram_rdata[31: 8], rs2_rdata[ 7: 0] };
                            2'b01: store_data = { dram_rdata[31:16], rs2_rdata[ 7: 0], dram_rdata[ 7: 0] };
                            2'b10: store_data = { dram_rdata[31:24], rs2_rdata[ 7: 0], dram_rdata[15: 0] };
                            2'b11: store_data = { rs2_rdata[ 7: 0], dram_rdata[23: 0] };
                        endcase
                    end
                    3'b001: begin  // sh
                        if (addr_low[1])
                            store_data = { rs2_rdata[15: 0], dram_rdata[15: 0] };
                        else
                            store_data = { dram_rdata[31:16], rs2_rdata[15: 0] };
                    end
                    3'b010: store_data = rs2_rdata;  // sw
                    default: store_data = rs2_rdata;
                endcase
            end
            default: store_data = rs2_rdata;
        endcase
    end

    // ========================================================================
    // Write-back MUX (4-to-1): ALU / DM / IMM / PC+4
    // ========================================================================
    MUX4_1 #(
        .WIDTH(32)
    ) mux_wb (
        .A       (alu_result),   // 00: ALU
        .B       (load_data),    // 01: DM (with load extension)
        .C       (imm),          // 10: IMM (for lui)
        .D       (pcadd4),       // 11: PC+4 (for jal/jalr)
        .Control (MemToReg),
        .Result  (wb_data)
    );

    // ========================================================================
    // DRAM interface
    // ========================================================================
    assign dram_addr  = alu_result;
    assign dram_wdata = store_data;
    assign dram_wen   = MemWrite;

    // ========================================================================
    // Debug Interface (registered to capture results of the committed inst)
    // ========================================================================
    always_ff @(posedge cpu_clk, posedge cpu_rst) begin
        if (cpu_rst) begin
            debug_wb_have_inst <= 1'b0;
            debug_wb_pc        <= '0;
            debug_wb_ena       <= 1'b0;
            debug_wb_reg       <= '0;
            debug_wb_value     <= '0;
        end else begin
            debug_wb_have_inst <= 1'b1;
            debug_wb_pc        <= pc_out;
            debug_wb_ena       <= RegWrite;
            debug_wb_reg       <= rd_addr;
            debug_wb_value     <= wb_data;
        end
    end

endmodule
