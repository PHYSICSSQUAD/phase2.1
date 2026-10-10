// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_monitor.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
class muld_monitor extends monitor_base#(muld_seq_item);

    `uvm_component_utils(muld_monitor)

    typedef struct {
        logic [31:0] raw_instr;
        instr_e      op;
        int unsigned issue_cycle;
    } pending_op_t;

    virtual muld_if vif;
    uvm_analysis_port #(muld_cycle_item) cycle_ap;

    pending_op_t pending[$];
    int unsigned cycle_count;
    int unsigned num_items;
    int unsigned num_cycle_samples;

    function new(string name = "muld_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cycle_ap = new("cycle_ap", this);
    endfunction

    protected virtual task collect_txn();
        muld_cycle_item cycle_item;
        pending_op_t    issued;
        instr_e         decoded_op;

        @(vif.mon_cb);

        if (vif.mon_cb.rst_n !== 1'b1) begin
            pending.delete();
        end
        else begin
            cycle_count++;
            num_cycle_samples++;

            // Preserve a per-cycle view for the local internal-signal checker.
            cycle_item                  = muld_cycle_item::type_id::create("cycle_item");
            cycle_item.cycle            = cycle_count;
            cycle_item.rst_n             = vif.mon_cb.rst_n;
            cycle_item.id_valid          = vif.mon_cb.id_valid;
            cycle_item.id_instr_valid    = vif.mon_cb.id_instr_valid;
            cycle_item.id_instr          = vif.mon_cb.id_instr;
            cycle_item.pending_valid     = (pending.size() != 0);
            cycle_item.pending_op        = (pending.size() != 0) ? pending[0].op : ILLEGAL;
            cycle_item.pending_age       = (pending.size() != 0) ? cycle_count - pending[0].issue_cycle : 0;
            cycle_item.mult_en           = vif.mon_cb.mult_en;
            cycle_item.mult_multicycle   = vif.mon_cb.mult_multicycle;
            cycle_item.mult_operand_a    = vif.mon_cb.mult_operand_a;
            cycle_item.mult_operand_b    = vif.mon_cb.mult_operand_b;
            cycle_item.alu_en            = vif.mon_cb.alu_en;
            cycle_item.alu_operator      = vif.mon_cb.alu_operator;
            cycle_item.alu_operand_a     = vif.mon_cb.alu_operand_a;
            cycle_item.alu_operand_b     = vif.mon_cb.alu_operand_b;
            cycle_item.ex_valid          = vif.mon_cb.ex_valid;
            cycle_item.wb_we             = vif.mon_cb.wb_we;
            cycle_item.wb_waddr          = vif.mon_cb.wb_waddr;
            cycle_item.wb_wdata          = vif.mon_cb.wb_wdata;
            cycle_ap.write(cycle_item);

            // An M instruction already accepted into ID/EX completes in order.
            // Handle the old EX operation before recording a new ID issue from
            // this same sampled cycle.
            if ((pending.size() != 0) && (vif.mon_cb.ex_valid === 1'b1)) begin
                if (is_mul_op(pending[0].op) && (vif.mon_cb.mult_en !== 1'b1)) begin
                    `uvm_error(get_type_name(),
                        $sformatf("%s completed without mult_en; %s",
                                  pending[0].op.name(), cycle_item.convert2string()))
                end
                if (is_div_op(pending[0].op) && (vif.mon_cb.alu_en !== 1'b1)) begin
                    `uvm_error(get_type_name(),
                        $sformatf("%s completed without alu_en; %s",
                                  pending[0].op.name(), cycle_item.convert2string()))
                end
                publish_item(pending[0]);
                void'(pending.pop_front());
            end

            if ((vif.mon_cb.id_valid === 1'b1) &&
                (vif.mon_cb.id_instr_valid === 1'b1)) begin
                decoded_op = decode_instr(vif.mon_cb.id_instr);
                if (is_rv32m_op(decoded_op)) begin
                    issued.raw_instr  = vif.mon_cb.id_instr;
                    issued.op         = decoded_op;
                    issued.issue_cycle = cycle_count;
                    pending.push_back(issued);
                end
            end
        end
    endtask : collect_txn

    function bit is_rv32m_op(instr_e op);
        return op inside {MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU};
    endfunction

    function bit is_mul_op(instr_e op);
        return op inside {MUL, MULH, MULHSU, MULHU};
    endfunction

    function bit is_div_op(instr_e op);
        return op inside {DIV, DIVU, REM, REMU};
    endfunction

    function void publish_item(pending_op_t entry);
        muld_seq_item item;

        item           = muld_seq_item::type_id::create("item");
        item.instr.raw = entry.raw_instr;
        item.op        = entry.op;
        item.rd        = entry.raw_instr[11:7];

        if (is_mul_op(entry.op)) begin
            item.rs1_val = vif.mon_cb.mult_operand_a;
            item.rs2_val = vif.mon_cb.mult_operand_b;
        end
        else begin
            // The CV32E40P divider internally receives rs1 in alu_operand_b
            // and rs2 in alu_operand_a (the decoder swaps these ALU muxes).
            item.rs1_val = vif.mon_cb.alu_operand_b;
            item.rs2_val = vif.mon_cb.alu_operand_a;
        end

        item.result         = vif.mon_cb.wb_wdata;
        item.wb_we          = vif.mon_cb.wb_we;
        item.wb_waddr       = vif.mon_cb.wb_waddr;
        item.latency_cycles = cycle_count - entry.issue_cycle;

        num_items++;
        `uvm_info(get_type_name(), {"RV32M completion: ", item.convert2string()}, UVM_HIGH)
        ap.write(item);
    endfunction

    virtual function void handle_reset(uvm_phase phase);
        super.handle_reset(phase);
        pending.delete();
        cycle_count = 0;
    endfunction : handle_reset

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(),
            $sformatf("Observed %0d RV32M completions in %0d active cycles",
                      num_items, num_cycle_samples), UVM_LOW)
    endfunction : report_phase

endclass : muld_monitor
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_monitor.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
