class environment extends uvm_env;
	`uvm_component_utils(environment)

	// components
	instruction_agent instr_agt;
	data_agent        data_agt;
	reset_agent       rst_agt;
	debug_agent       dbg_agt;
	predictor         pdt;

	// virtual sequencer
	virtual_sequencer vsqr;

	// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 BEGIN MULDIV environment fields 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
	// Passive RV32M agent and its private checking/coverage components.
	muld_agent      muld_agt;
	muld_config     muld_cfg;
	muld_scoreboard muld_scb;
	muld_coverage   muld_cov;
	virtual muld_if muld_vif;

	// Public analysis exports for the team's shared scoreboard.
	uvm_analysis_export #(muld_seq_item) muld_actual_export;
	uvm_analysis_export #(muld_seq_item) muld_expected_export;
	// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 END MULDIV environment fields 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥

	function new(string name = "environment", uvm_component parent=null);
		super.new(name, parent);
	endfunction : new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		instr_agt = instruction_agent::type_id::create("instr_agt", this);
		data_agt  = data_agent::type_id::create("data_agt", this);
		rst_agt   = reset_agent::type_id::create("rst_agt", this);
		dbg_agt   = debug_agent::type_id::create("dbg_agt", this);
		pdt       = predictor::type_id::create("pdt", this);

		vsqr = virtual_sequencer::type_id::create("vsqr", this);

		// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 BEGIN MULDIV build/configuration 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
		muld_actual_export   = new("muld_actual_export", this);
		muld_expected_export = new("muld_expected_export", this);
		muld_cfg             = muld_config::type_id::create("muld_cfg");
		if (!uvm_config_db#(virtual muld_if)::get(this, "", "muld_vif", muld_vif)) begin
			`uvm_fatal(get_full_name(), "Could not get 'muld_vif' from uvm_config_db; check muld_bind and its top-level instance")
		end
		muld_cfg.set_vif(muld_vif);
		muld_cfg.set_mode(UVM_PASSIVE);
		uvm_config_db#(muld_config)::set(this, "muld_agt", "muld_cfg", muld_cfg);

		muld_agt = muld_agent::type_id::create("muld_agt", this);
		muld_scb = muld_scoreboard::type_id::create("muld_scb", this);
		muld_cov = muld_coverage::type_id::create("muld_cov", this);
		// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 END MULDIV build/configuration 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
	endfunction : build_phase

	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		// mon to scb
		// instr_agt.out_mon_ap.connect(scb.act_exp);
		// mon to pdt
		// instr_agt.in_mon_ap.connect(pdt.data_imp);
		// pdt to scb
		// pdt.ap.connect(scb.exp_exp);
		// mon to cov
		// instr_agt.in_mon_ap.connect( cov.in_exp);
		// instr_agt.out_mon_ap.connect(cov.out_exp);
		// pdt
		instr_agt.mon_ap.connect(pdt.instr_imp);
		// rst
		rst_agt.rst_ap.connect(pdt.rst_imp);
		// rst_agt.rst_ap.connect(scb.rst_imp);
		// rst_agt.rst_ap.connect(cov.rst_imp);

		// connect virtual sequencer to agent sequencers
		vsqr.instr_sqr = instr_agt.sqr;
		vsqr.data_sqr  = data_agt.sqr;
		vsqr.rst_sqr   = rst_agt.rst_sqr;

		// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 BEGIN MULDIV analysis wiring 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
		// The monitor feeds both the operation-specific reference model and
		// the local checker. The predictor exports expected RV32M transactions
		// through a separate public tap for the team's shared scoreboard.
		muld_agt.mon_ap.connect(pdt.muld_imp);
		muld_agt.mon_ap.connect(muld_scb.actual_export);
		muld_agt.mon_ap.connect(muld_cov.analysis_export);
		muld_agt.cycle_ap.connect(muld_scb.cycle_export);
		pdt.muld_expected_ap.connect(muld_scb.expected_export);
		muld_agt.mon_ap.connect(muld_actual_export);
		pdt.muld_expected_ap.connect(muld_expected_export);
		rst_agt.rst_ap.connect(muld_scb.rst_imp);
		// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥 END MULDIV analysis wiring 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
	endfunction : connect_phase

endclass : environment
