// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_coverage.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
class muld_coverage extends uvm_subscriber #(muld_seq_item);

    `uvm_component_utils(muld_coverage)

    muld_seq_item item;
    int unsigned  num_sampled;

    covergroup rv32m_cg;
        option.per_instance = 1;

        cp_op: coverpoint item.op {
            bins mul    = {MUL};
            bins mulh   = {MULH};
            bins mulhsu = {MULHSU};
            bins mulhu  = {MULHU};
            bins div    = {DIV};
            bins divu   = {DIVU};
            bins rem    = {REM};
            bins remu   = {REMU};
        }

        cp_rs1_zero: coverpoint (item.rs1_val == 32'b0) {
            bins zero    = {1'b1};
            bins nonzero = {1'b0};
        }
        cp_rs2_zero: coverpoint (item.rs2_val == 32'b0) {
            bins zero    = {1'b1};
            bins nonzero = {1'b0};
        }
        cp_rs1_sign: coverpoint item.rs1_val[31] {
            bins nonnegative = {1'b0};
            bins negative    = {1'b1};
        }
        cp_rs2_sign: coverpoint item.rs2_val[31] {
            bins nonnegative = {1'b0};
            bins negative    = {1'b1};
        }

        cx_op_rs2_zero: cross cp_op, cp_rs2_zero;
        cx_op_signs:    cross cp_op, cp_rs1_sign, cp_rs2_sign;
    endgroup

    function new(string name = "muld_coverage", uvm_component parent = null);
        super.new(name, parent);
        rv32m_cg = new();
    endfunction

    virtual function void write(muld_seq_item t);
        item = t;
        num_sampled++;
        rv32m_cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("RV32M functional coverage = %0.2f%% (%0d completed ops)",
                      rv32m_cg.get_inst_coverage(), num_sampled), UVM_NONE)
    endfunction

endclass : muld_coverage
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_coverage.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
