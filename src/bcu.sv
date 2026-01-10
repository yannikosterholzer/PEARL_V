`timescale 1ns / 1ps

module bcu // Branch Compare Unit
    (
    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    input  logic [2:0]  bcu_op_i,
    output logic        tk_brnch_o  // take Branch
    );
    
    always_comb begin 
        case(bcu_op_i)
            3'b000:  tk_brnch_o = (rs1_i == rs2_i);
            3'b001:  tk_brnch_o = (rs1_i != rs2_i);
            3'b100:  tk_brnch_o = ($signed(rs1_i) <  $signed(rs2_i));
            3'b101:  tk_brnch_o = ($signed(rs1_i) >= $signed(rs2_i));
            3'b110:  tk_brnch_o = (rs1_i <  rs2_i);
            3'b111:  tk_brnch_o = (rs1_i >= rs2_i);
            default: tk_brnch_o = 1'b0;
        endcase
    end
endmodule
