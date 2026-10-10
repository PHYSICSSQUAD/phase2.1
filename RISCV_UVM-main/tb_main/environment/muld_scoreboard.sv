// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_scoreboard.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
`uvm_analysis_imp_decl(_muld_reset)

class muld_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(muld_scoreboard)

    // Actual completions come from the passive agent; predicted completions
    // come from the reference model owned by predictor. The separate FIFOs
    // allow the comparison worker to block safely in run_phase.
    uvm_analysis_export #(muld_seq_item) actual_export;
    uvm_analysis_export #(muld_seq_item) expected_export;
    uvm_analysis_export #(muld_cycle_item) cycle_export;

    uvm_tlm_analysis_fifo #(muld_seq_item) actual_fifo;
    uvm_tlm_analysis_fifo #(muld_seq_item) expected_fifo;
    uvm_tlm_analysis_fifo #(muld_cycle_item) cycle_fifo;

    uvm_analysis_imp_muld_reset #(reset_item, muld_scoreboard) rst_imp;

    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned cycle_sample_count;
    int unsigned mul_multicycle_count;
    int unsigned div_busy_count;
    int unsigned reset_epoch;
    int unsigned op_count[instr_e];

    function new(string name = "muld_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        actual_export   = new("actual_export", this);
        expected_export = new("expected_export", this);
        cycle_export    = new("cycle_export", this);
        actual_fifo     = new("actual_fifo", this);
        expected_fifo   = new("expected_fifo", this);
        cycle_fifo      = new("cycle_fifo", this);
        rst_imp         = new("rst_imp", this);
        pass_count      = 0;
        fail_count      = 0;
        reset_epoch     = 0;
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        actual_export.connect(actual_fifo.analysis_export);
        expected_export.connect(expected_fifo.analysis_export);
        cycle_export.connect(cycle_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        fork
            compare_transactions();
            inspect_cycles();
        join
    endtask

    protected task compare_transactions();
        muld_seq_item actual_item;
        muld_seq_item expected_item;

        forever begin
            expected_fifo.get(expected_item);
            actual_fifo.get(actual_item);

            if (expected_item.compare(actual_item)) begin
                pass_count++;
                if (op_count.exists(actual_item.op)) op_count[actual_item.op]++;
                else                                op_count[actual_item.op] = 1;
                `uvm_info(get_type_name(),
                    $sformatf("PASS %s", actual_item.convert2string()), UVM_MEDIUM)
            end
            else begin
                fail_count++;
                if (op_count.exists(actual_item.op)) op_count[actual_item.op]++;
                else                                op_count[actual_item.op] = 1;
                `uvm_error(get_type_name(),
                    $sformatf("RV32M mismatch\n  expected: %s\n  actual:   %s",
                              expected_item.convert2string(), actual_item.convert2string()))
            end
        end
    endtask : compare_transactions

    protected task inspect_cycles();
        muld_cycle_item current;
        muld_cycle_item previous;
        bit             have_previous;
        int unsigned    observed_epoch;

        have_previous = 1'b0;
        observed_epoch = reset_epoch;

        forever begin
            cycle_fifo.get(current);

            if (observed_epoch != reset_epoch) begin
                have_previous = 1'b0;
                observed_epoch = reset_epoch;
            end

            cycle_sample_count++;
            if (current.pending_valid) begin
                if ((current.pending_op inside {MUL, MULH, MULHSU, MULHU}) &&
                    (current.mult_en !== 1'b1)) begin
                    `uvm_error(get_type_name(),
                        $sformatf("Internal-cycle check: %s pending without mult_en: %s",
                                  current.pending_op.name(), current.convert2string()))
                end
                if ((current.pending_op inside {DIV, DIVU, REM, REMU}) &&
                    (current.alu_en !== 1'b1)) begin
                    `uvm_error(get_type_name(),
                        $sformatf("Internal-cycle check: %s pending without alu_en: %s",
                                  current.pending_op.name(), current.convert2string()))
                end
                if ((current.mult_en === 1'b1) && (current.alu_en === 1'b1)) begin
                    `uvm_error(get_type_name(),
                        $sformatf("Multiplier and ALU enables were both asserted for one RV32M operation: %s",
                                  current.convert2string()))
                end
                if ((current.pending_op inside {MUL, MULH, MULHSU, MULHU}) &&
                    (current.mult_multicycle === 1'b1)) begin
                    mul_multicycle_count++;
                end
                if ((current.pending_op inside {DIV, DIVU, REM, REMU}) &&
                    (current.ex_valid !== 1'b1)) begin
                    div_busy_count++;
                end

                // Verify that the selected EX operands stay stable while a
                // multi-cycle operation remains in flight.
                if (have_previous && previous.pending_valid &&
                    (previous.ex_valid !== 1'b1) &&
                    (previous.pending_op == current.pending_op)) begin
                    if (current.pending_op inside {MUL, MULH, MULHSU, MULHU}) begin
                        if ((current.mult_operand_a !== previous.mult_operand_a) ||
                            (current.mult_operand_b !== previous.mult_operand_b)) begin
                            `uvm_error(get_type_name(),
                                $sformatf("Multiplier operands changed while %s was in EX: %s",
                                          current.pending_op.name(), current.convert2string()))
                        end
                    end
                    else if (current.pending_op inside {DIV, DIVU, REM, REMU}) begin
                        if ((current.alu_operand_a !== previous.alu_operand_a) ||
                            (current.alu_operand_b !== previous.alu_operand_b) ||
                            (current.alu_operator  !== previous.alu_operator)) begin
                            `uvm_error(get_type_name(),
                                $sformatf("Divider operands/operator changed while %s was in EX: %s",
                                          current.pending_op.name(), current.convert2string()))
                        end
                    end
                end
            end

            previous = current;
            have_previous = 1'b1;
        end
    endtask : inspect_cycles

    virtual function void write_muld_reset(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            actual_fifo.flush();
            expected_fifo.flush();
            cycle_fifo.flush();
            reset_epoch++;
        end
    endfunction : write_muld_reset

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (pass_count + fail_count == 0) begin
            `uvm_warning(get_type_name(), "No completed RV32M operation reached the local scoreboard")
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        string summary;
        super.report_phase(phase);
        summary = $sformatf(
            "\n---------------- RV32M LOCAL SCOREBOARD ----------------\n  Checked: %0d  PASS: %0d  FAIL: %0d\n  Cycle samples: %0d\n  MULH multi-cycle samples: %0d\n  DIV/REM busy samples: %0d\n",
            pass_count + fail_count, pass_count, fail_count, cycle_sample_count,
            mul_multicycle_count, div_busy_count);
        foreach (op_count[op]) begin
            summary = {summary, $sformatf("  %-7s: %0d\n", op.name(), op_count[op])};
        end
        summary = {summary, "----------------------------------------------------------"};
        `uvm_info(get_type_name(), summary, UVM_NONE)
    endfunction

endclass : muld_scoreboard
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_scoreboard.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
