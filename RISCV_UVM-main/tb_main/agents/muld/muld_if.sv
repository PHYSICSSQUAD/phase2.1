// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_if.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
`timescale 1ns/1ps

// Passive taps on the CV32E40P ID/EX and EX/writeback signals used by the
// RV32M monitor. This interface has no driver: it observes the DUT only.
interface muld_if (
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

    clocking mon_cb @(posedge clk);
        default input #1step;
        input rst_n;
        input id_valid, id_instr_valid, id_instr;
        input mult_en, mult_multicycle, mult_operand_a, mult_operand_b;
        input alu_en, alu_operator, alu_operand_a, alu_operand_b;
        input ex_valid, wb_we, wb_waddr, wb_wdata;
    endclocking

    modport MONITOR (
        clocking mon_cb,
        input clk,
        input rst_n
    );

endinterface : muld_if
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_if.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
