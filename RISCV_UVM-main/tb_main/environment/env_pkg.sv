package env_pkg;
	import uvm_pkg::*;
	import shared_pkg::*;
	import base_pkg::*;
	import instruction_pkg::*;
	import data_pkg::*;
	import reset_pkg::*;
	import debug_pkg::*;

    `include "shadow_data_memory.sv"

	`include "predictor.sv"
	// `include "scoreboard.sv"
	// `include "coverage_collector.sv"

	`include "virtual_sequencer.sv"

endpackage : env_pkg
