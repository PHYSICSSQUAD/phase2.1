class mul_ref_model extends uvm_object;

    `uvm_object_utils(mul_ref_model)

    function new(string name = "mul_ref_model");
        super.new(name);
    endfunction

    function logic [31:0] predict(instr_e op, logic [31:0] rs1_val, logic [31:0] rs2_val);
        longint signed   a_s, b_s;  
        longint unsigned a_u, b_u;  
        logic   [63:0]   product;

        a_s = longint'($signed(rs1_val));   
        b_s = longint'($signed(rs2_val));
        a_u = {32'b0, rs1_val};           
        b_u = {32'b0, rs2_val};

        case (op)
            MUL   : begin product = a_s * b_s; return product[31:0];  end
            MULH  : begin product = a_s * b_s; return product[63:32]; end
            MULHSU: begin product = a_s * longint'(b_u); return product[63:32]; end
            MULHU : begin product = a_u * b_u; return product[63:32]; end
            default: begin
                `uvm_error(get_type_name(), $sformatf("predict() called with non-MUL op %s", op.name()))
                return 'x;
            end
        endcase
    endfunction

endclass
