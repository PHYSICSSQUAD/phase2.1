class coverage_collector extends uvm_component;
    `uvm_component_utils(coverage_collector)

    // items
    drv_item drv_item_inst;
    mon_item mon_item_inst;

    // exports
    uvm_analysis_export#(drv_item)  in_exp;
    uvm_analysis_export#(mon_item) out_exp;

    // fifos
    uvm_tlm_analysis_fifo#(drv_item)  in_fifo;
    uvm_tlm_analysis_fifo#(mon_item) out_fifo;

    // Event to handle the reset interruption
    uvm_analysis_imp#(reset_item, coverage_collector) rst_imp;
    uvm_event rst_event;

    covergroup covgp;
        // enable Signals
        // ALU_15
        alu_en_cp : coverpoint drv_item_inst.alu_en{
            illegal_bins zero = {0};
        }

        // ALU_05
        a_en_cp : coverpoint drv_item_inst.a_en;
        b_en_cp : coverpoint drv_item_inst.b_en;
        // Operations
        // ALU_06
        a_op_cp : coverpoint drv_item_inst.a_op  iff( drv_item_inst.a_en && !drv_item_inst.b_en && drv_item_inst.alu_en);
        // ALU_07
        b_op_cp : coverpoint drv_item_inst.b_op  iff(!drv_item_inst.a_en &&  drv_item_inst.b_en && drv_item_inst.alu_en);
        ab_op_cp: coverpoint drv_item_inst.b_op2 iff( drv_item_inst.a_en &&  drv_item_inst.b_en && drv_item_inst.alu_en);
        // Input Values
        // ALU_03
        A_cp : coverpoint drv_item_inst.A {
            bins min_val = {-16};
            bins max_val = { 15};
            bins neg[]   = {[-15:-1]};
            bins zero    = {0};
            bins pos[]   = {[1:14]};
        }
        B_cp : coverpoint drv_item_inst.B {
            bins min_val = {-16};
            bins max_val = { 15};
            bins neg[]   = {[-15:-1]};
            bins zero    = {0};
            bins pos[]   = {[1:14]};
        }
        // Output Values
        // ALU_08
        C_cp : coverpoint mon_item_inst.C {
            bins min_val = {-32};
            bins neg[]   = {[-31:-1]};
            bins zero    = {0};
            bins pos[]   = {[1:30]};
        }
        // Crosses
        // All enable combinations
        // ALU_09
        cross_en : cross a_en_cp, b_en_cp;
        // Every op tested
        // ALU_10
        cross_aop_en: cross a_op_cp, a_en_cp iff(drv_item_inst.alu_en) {
            ignore_bins no_enable = binsof(a_en_cp) intersect {0};
        }
        // ALU_11
        cross_bop_en: cross b_op_cp, b_en_cp iff(drv_item_inst.alu_en) {
            ignore_bins no_enable = binsof(b_en_cp) intersect {0};
        }
        // ALU_12
        cross_abop  : cross ab_op_cp, a_en_cp, b_en_cp iff(drv_item_inst.alu_en) {
            ignore_bins no_enable  = binsof(a_en_cp) intersect {0};
            ignore_bins no_enable2 = binsof(b_en_cp) intersect {0};
        }
        // all Operand sign combinations
        // ALU_13
        cross_signs : cross A_cp, B_cp;
    endgroup

    function new(string name = "coverage_collector", uvm_component parent=null);
        super.new(name, parent);
        covgp = new();
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

         in_exp = new("in_exp",  this);
        out_exp = new("out_exp", this);
        rst_imp = new("rst_imp", this);

         in_fifo = new("in_fifo",  this);
        out_fifo = new("out_fifo", this);

        rst_event = new("rst_event");
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
         in_exp.connect( in_fifo.analysis_export);
        out_exp.connect(out_fifo.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin

            drv_item in_txn;
            mon_item out_txn;

            fork
                begin
                    forever begin
                         in_fifo.get( in_txn);
                        out_fifo.get(out_txn);

                        drv_item_inst = drv_item::type_id::create("drv_item_inst");
                        mon_item_inst = mon_item::type_id::create("mon_item_inst");

                        drv_item_inst.A      = in_txn.A;
                        drv_item_inst.B      = in_txn.B;
                        drv_item_inst.alu_en = in_txn.alu_en;
                        drv_item_inst.a_en   = in_txn.a_en;
                        drv_item_inst.b_en   = in_txn.b_en;
                        drv_item_inst.a_op   = in_txn.a_op;
                        drv_item_inst.b_op   = in_txn.b_op;
                        drv_item_inst.b_op2  = in_txn.b_op2;

                        mon_item_inst.C      = out_txn.C;

                        covgp.sample();
                    end
                end
                begin

                    rst_event.wait_trigger();

                     in_fifo.flush();
                    out_fifo.flush();

                    drv_item_inst = drv_item::type_id::create("drv_item_inst");
                    mon_item_inst = mon_item::type_id::create("mon_item_inst");

                    `uvm_info("COV_RST", "Coverage FIFOs flushed and state cleared due to reset", UVM_HIGH)
                end
            join_any

            disable fork;
        end
    endtask : run_phase

    virtual function void write(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            rst_event.trigger();
        end
    endfunction

endclass : coverage_collector
