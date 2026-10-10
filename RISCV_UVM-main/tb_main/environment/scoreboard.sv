
class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    // data exports
    uvm_analysis_export #(mon_item) act_exp;
    uvm_analysis_export #(mon_item) exp_exp;

    // data fifos
    uvm_tlm_analysis_fifo #(mon_item) act_fifo;
    uvm_tlm_analysis_fifo #(mon_item) exp_fifo;

    // reset imp
    uvm_analysis_imp_rst #(reset_item, scoreboard) rst_imp;

    // vars
    int correct, error;

    // Add a UVM event to synchronize the reset
    uvm_event rst_event;

    function new(string name = "scoreboard", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        act_exp  = new("act_exp", this);
        exp_exp  = new("exp_exp", this);
        rst_imp  = new("rst_imp", this);

        act_fifo = new("act_fifo", this);
        exp_fifo = new("exp_fifo", this);

        rst_event = new("rst_event");
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        act_exp.connect(act_fifo.analysis_export);
        exp_exp.connect(exp_fifo.analysis_export);
    endfunction

    // reset handler
    virtual function void write_rst(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            act_fifo.flush();
            exp_fifo.flush();
            rst_event.trigger();
            `uvm_info("SCB_RST", "Scoreboard pipeline FIFOs flushed due to reset", UVM_HIGH)
        end
    endfunction

    // compare
    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            mon_item act_item, exp_item;

            fork
                begin
                    // Predictor produces expected item earlier; grab expected first
                    exp_fifo.get(exp_item);
                    act_fifo.get(act_item);

                    // Compare
                    if (exp_item.compare(act_item)) begin
                        correct++;
                        `uvm_info("SCB_PASS", $sformatf("Match! %0b  vs  %0b", act_item.convert2string(), exp_item.convert2string()), UVM_FULL)
                    end
                    else begin
                        error++;
                        `uvm_error("SCB_FAIL", $sformatf("Mismatch on %0s: \nExpected C: %0d \nActual C: %0d", act_item.get_full_name(), exp_item.convert2string(), act_item.convert2string()))
                    end
                end
                // begin
                    
                // end
                begin
                    rst_event.wait_trigger();
                end
            join_any

            disable fork;
        end
    endtask : run_phase

endclass : scoreboard
