`uvm_analysis_imp_decl(_instr)
`uvm_analysis_imp_decl(_rst)

class predictor extends uvm_component;
    `uvm_component_utils(predictor)

    // Analysis imps
    uvm_analysis_imp_instr#(instruction_seq_item, predictor) instr_imp;
    uvm_analysis_imp_rst  #(reset_item,           predictor) rst_imp;

    // Analysis port to scoreboard
    uvm_analysis_port#(data_seq_item) data_ap;

    shadow_data_memory shadow_data_mem;

    // Model State
    bit [31:0] target_address;
    bit [31:0] predicted_load_data;
    bit in_reset;
    
    // Shadow Register File to track 32-bit register contents
    bit [31:0] shadow_reg_file [32];

    function new(string name = "predictor", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        instr_imp = new("instr_imp", this);
        rst_imp   = new("rst_imp", this);
        data_ap   = new("data_ap", this);

        shadow_data_mem = new();
    endfunction

    // Helper: Compute Byte Enable mask based on operation and address offset
    function automatic logic [3:0] get_byte_enable(instr_e op, logic [1:0] offset);
        case (op)
            LB, LBU, SB: return (4'b0001 << offset);
            LH, LHU, SH: return (4'b0011 << offset);
            LW, SW:      return 4'b1111;
            default:     return 4'b0000;
        endcase
    endfunction

    // Reset handler
    virtual function void write_rst(reset_item rst_item);
        if (rst_item.reset_state == 1'b0) begin
            in_reset = 1'b1;
            shadow_data_mem.flush_memory();
            foreach (shadow_reg_file[i]) shadow_reg_file[i] = '0;
            shadow_reg_file[1] = 32'hA5A5_A5A5; // seed non-zero data source for store/load validation
            target_address = '0;
            predicted_load_data = '0;
            `uvm_info("PRED_RST", "Predictor state cleared due to async reset", UVM_NONE)
        end else begin
            in_reset = 1'b0;
        end
    endfunction

    // Instruction handler
    virtual function void write_instr(instruction_seq_item item);
        instr_t data;
        instr_e op;
        data_seq_item txn;

        bit [31:0] sign_extended_imm;
        bit [31:0] rs1_value;
        bit [31:0] rs2_value;

        if (in_reset) return;

        data.raw = item.data;
        op = decode_instr(data.raw);

        if (op inside {LB, LH, LW, LBU, LHU, SB, SH, SW}) begin
            txn = data_seq_item::type_id::create("txn");

            // 1. Decode Immediate and Read Register Contents
            if (op inside {LB, LH, LW, LBU, LHU}) begin
                sign_extended_imm = {{20{data.i_type.imm_11_0[11]}}, data.i_type.imm_11_0};
                rs1_value         = shadow_reg_file[data.i_type.rs1];
                rs2_value         = 32'b0;
            end else begin
                sign_extended_imm = {{20{data.s_type.imm_11_5[6]}}, data.s_type.imm_11_5, data.s_type.imm_4_0};
                rs1_value         = shadow_reg_file[data.s_type.rs1];
                rs2_value         = shadow_reg_file[data.s_type.rs2];
            end

            // 2. Compute Target Address and Memory Bus Attributes
            target_address = rs1_value + sign_extended_imm;
            
            txn.addr  = target_address;
            txn.we    = (op inside {SB, SH, SW});
            txn.be    = get_byte_enable(op, target_address[1:0]);
            txn.wdata = rs2_value;

            // 3. Execute LSU in Shadow Memory
            predicted_load_data = shadow_data_mem.execute_lsu(op, target_address, rs2_value);

            // 4. Update Register File on Loads (for dependent instructions)
            if (op inside {LB, LH, LW, LBU, LHU}) begin
                txn.rdata = predicted_load_data;
                if (data.i_type.rd != 5'b0) begin
                    shadow_reg_file[data.i_type.rd] = predicted_load_data;
                end
            end

            // 5. Broadcast predicted transaction (for both Loads & Stores)
            data_ap.write(txn);
            `uvm_info("PRED", $sformatf("Predicted LSU Txn: %s", txn.convert2string()), UVM_NONE)
        end
    endfunction

endclass : predictor