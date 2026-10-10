// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_seq_item.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
class muld_seq_item extends uvm_sequence_item;

    `uvm_object_utils(muld_seq_item)

    // One completed standard RV32M operation, sampled at its EX result.
    instr_t      instr;
    instr_e      op;
    logic [4:0]  rd;
    logic [31:0] rs1_val;
    logic [31:0] rs2_val;
    logic [31:0] result;
    logic        wb_we;
    logic [5:0]  wb_waddr;
    int unsigned latency_cycles;

    function new(string name = "muld_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "%-7s rd=x%0d rs1=0x%08h rs2=0x%08h result=0x%08h wb_we=%0b wb_waddr=%0d latency=%0d instr=0x%08h",
            op.name(), rd, rs1_val, rs2_val, result, wb_we, wb_waddr,
            latency_cycles, instr.raw
        );
    endfunction

    function void do_copy(uvm_object rhs);
        muld_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal(get_type_name(), "do_copy: rhs is not a muld_seq_item")
        end
        super.do_copy(rhs);
        instr          = rhs_.instr;
        op             = rhs_.op;
        rd             = rhs_.rd;
        rs1_val        = rhs_.rs1_val;
        rs2_val        = rhs_.rs2_val;
        result         = rhs_.result;
        wb_we          = rhs_.wb_we;
        wb_waddr       = rhs_.wb_waddr;
        latency_cycles = rhs_.latency_cycles;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        muld_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            return 0;
        end

        return super.do_compare(rhs, comparer) &&
               (instr.raw === rhs_.instr.raw)     &&
               (op       === rhs_.op)            &&
               (rd       === rhs_.rd)            &&
               (rs1_val  === rhs_.rs1_val)       &&
               (rs2_val  === rhs_.rs2_val)       &&
               (result   === rhs_.result)        &&
               (wb_we    === rhs_.wb_we)         &&
               (wb_waddr === rhs_.wb_waddr);
    endfunction

endclass : muld_seq_item
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_seq_item.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
