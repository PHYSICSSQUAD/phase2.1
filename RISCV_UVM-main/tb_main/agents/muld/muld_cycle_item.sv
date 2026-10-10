// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_cycle_item.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
class muld_cycle_item extends uvm_sequence_item;

    `uvm_object_utils(muld_cycle_item)

    int unsigned cycle;
    logic        rst_n;

    logic        id_valid;
    logic        id_instr_valid;
    logic [31:0] id_instr;

    logic        pending_valid;
    instr_e      pending_op;
    int unsigned pending_age;

    logic        mult_en;
    logic        mult_multicycle;
    logic [31:0] mult_operand_a;
    logic [31:0] mult_operand_b;

    logic        alu_en;
    logic [6:0]  alu_operator;
    logic [31:0] alu_operand_a;
    logic [31:0] alu_operand_b;

    logic        ex_valid;
    logic        wb_we;
    logic [5:0]  wb_waddr;
    logic [31:0] wb_wdata;

    function new(string name = "muld_cycle_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "cycle=%0d pending=%0b/%s age=%0d id_valid=%0b id_instr_valid=%0b id_instr=0x%08h mult_en=%0b multicycle=%0b alu_en=%0b alu_op=0x%02h ex_valid=%0b wb_we=%0b wb_addr=%0d wb_data=0x%08h",
            cycle, pending_valid, pending_op.name(), pending_age, id_valid,
            id_instr_valid, id_instr, mult_en, mult_multicycle, alu_en, alu_operator,
            ex_valid, wb_we, wb_waddr, wb_wdata
        );
    endfunction

endclass : muld_cycle_item
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_cycle_item.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
