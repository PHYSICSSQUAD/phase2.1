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
	endfunction : connect_phase

endclass : environment
