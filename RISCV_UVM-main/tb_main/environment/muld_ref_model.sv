// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 BEGIN MULDIV implementation: muld_ref_model.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
class muld_ref_model extends uvm_object;

    `uvm_object_utils(muld_ref_model)

    function new(string name = "muld_ref_model");
        super.new(name);
    endfunction

    // Predict all eight standard RV32M integer multiply/divide/remainder ops.
    // Operands are in architectural instruction order: rs1 first, rs2 second.
    function automatic logic [31:0] predict(
        input instr_e      op,
        input logic [31:0] rs1_val,
        input logic [31:0] rs2_val
    );
        logic signed [63:0] rs1_s64;
        logic signed [63:0] rs2_s64;
        logic        [63:0] rs1_u64;
        logic        [63:0] rs2_u64;
        logic signed [63:0] product_ss;
        logic signed [63:0] product_hsu;
        logic        [63:0] product_uu;
        logic signed [31:0] dividend_s;
        logic signed [31:0] divisor_s;
        logic signed [31:0] quotient_s;
        logic signed [31:0] remainder_s;

        rs1_s64 = $signed({{32{rs1_val[31]}}, rs1_val});
        rs2_s64 = $signed({{32{rs2_val[31]}}, rs2_val});
        rs1_u64 = {32'b0, rs1_val};
        rs2_u64 = {32'b0, rs2_val};
        dividend_s = $signed(rs1_val);
        divisor_s  = $signed(rs2_val);

        case (op)
            MUL: begin
                product_ss = rs1_s64 * rs2_s64;
                return product_ss[31:0];
            end
            MULH: begin
                product_ss = rs1_s64 * rs2_s64;
                return product_ss[63:32];
            end
            MULHSU: begin
                product_hsu = rs1_s64 * $signed(rs2_u64);
                return product_hsu[63:32];
            end
            MULHU: begin
                product_uu = rs1_u64 * rs2_u64;
                return product_uu[63:32];
            end
            DIV: begin
                if (rs2_val == 32'b0) return 32'hffff_ffff;
                if ((rs1_val == 32'h8000_0000) && (rs2_val == 32'hffff_ffff))
                    return 32'h8000_0000;
                quotient_s = dividend_s / divisor_s;
                return $unsigned(quotient_s);
            end
            DIVU: begin
                if (rs2_val == 32'b0) return 32'hffff_ffff;
                return rs1_val / rs2_val;
            end
            REM: begin
                if (rs2_val == 32'b0) return rs1_val;
                if ((rs1_val == 32'h8000_0000) && (rs2_val == 32'hffff_ffff))
                    return 32'b0;
                remainder_s = dividend_s % divisor_s;
                return $unsigned(remainder_s);
            end
            REMU: begin
                if (rs2_val == 32'b0) return rs1_val;
                return rs1_val % rs2_val;
            end
            default: begin
                `uvm_error(get_type_name(),
                    $sformatf("predict() called with non-RV32M op %s", op.name()))
                return 'x;
            end
        endcase
    endfunction

endclass : muld_ref_model
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
// 🔥 END MULDIV implementation: muld_ref_model.sv 🔥
// 🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥🔥
