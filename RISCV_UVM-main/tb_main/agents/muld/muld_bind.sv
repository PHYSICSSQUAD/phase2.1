// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_bind.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
`timescale 1ns/1ps

module muld_bind_wrap (
    input logic        clk,
    input logic        rst_n,
    input logic        id_valid,
    input logic        id_instr_valid,
    input logic [31:0] id_instr,
    input logic        mult_en,
    input logic        mult_multicycle,
    input logic [31:0] mult_operand_a,
    input logic [31:0] mult_operand_b,
    input logic        alu_en,
    input logic [6:0]  alu_operator,
    input logic [31:0] alu_operand_a,
    input logic [31:0] alu_operand_b,
    input logic        ex_valid,
    input logic        wb_we,
    input logic [5:0]  wb_waddr,
    input logic [31:0] wb_wdata
);
    import uvm_pkg::*;

    muld_if muld_vif (.*);

    initial begin
        uvm_config_db#(virtual muld_if)::set(null, "*", "muld_vif", muld_vif);
    end
endmodule : muld_bind_wrap

// This module must be instantiated by the main tb top. Its bind inserts one
// passive interface instance into each cv32e40p_core instance in the design.
module muld_bind;
    bind cv32e40p_core muld_bind_wrap muld_bind_i (
        .clk              (clk),
        .rst_n            (rst_ni),
        .id_valid         (id_valid),
        .id_instr_valid   (instr_valid_id),
        .id_instr         (instr_rdata_id),
        .mult_en          (mult_en_ex),
        .mult_multicycle  (mult_multicycle),
        .mult_operand_a   (mult_operand_a_ex),
        .mult_operand_b   (mult_operand_b_ex),
        .alu_en           (alu_en_ex),
        .alu_operator     (alu_operator_ex),
        .alu_operand_a    (alu_operand_a_ex),
        .alu_operand_b    (alu_operand_b_ex),
        .ex_valid         (ex_valid),
        .wb_we            (regfile_alu_we_fw),
        .wb_waddr         (regfile_alu_waddr_fw),
        .wb_wdata         (regfile_alu_wdata_fw)
    );
endmodule : muld_bind
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_bind.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
