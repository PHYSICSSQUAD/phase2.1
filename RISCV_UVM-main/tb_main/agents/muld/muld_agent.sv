// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_agent.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
class muld_agent extends agent_base#(muld_seq_item);

    `uvm_component_utils(muld_agent)

    muld_monitor mon;
    muld_config  cfg;

    uvm_analysis_port #(muld_cycle_item) cycle_ap;

    function new(string name = "muld_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(muld_config)::get(this, "", "muld_cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "muld_config 'muld_cfg' not found in uvm_config_db")
        end
        super.cfg = cfg;

        // RV32M is observed passively; it has no sequencer or driver.
        cfg.set_mode(UVM_PASSIVE);
        mon      = muld_monitor::type_id::create("mon", this);
        cycle_ap = new("cycle_ap", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.set_cfg(cfg);
        mon.vif = cfg.get_vif();
        mon.ap.connect(mon_ap);
        mon.cycle_ap.connect(cycle_ap);
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        if (cfg.get_vif() == null) begin
            `uvm_fatal(get_type_name(), "MULD virtual interface was not configured")
        end
    endfunction

endclass : muld_agent
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_agent.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
