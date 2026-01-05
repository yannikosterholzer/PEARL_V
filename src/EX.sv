`timescale 1ns / 1ps

module EX
(
    input  logic [2:0]  ex_op_i,
    input  logic        isBRNCH_i, 
    input  logic        isJAL_i, 
    input  logic        isJALR_i,
    input  logic [31:0] op1_i,
    input  logic [31:0] op2_i,
    input  logic [4:0]  shamt_i,
    input  logic        shdir_i,
    input  logic        sbtr_i,
    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    input  logic [31:0] imm_i,       
    input  logic [31:0] pc_i,
    output logic        tk_brnch_o,
    output logic [31:0] target_o,
    output logic [31:0] res_o
);
    logic [31:0] alu_res;
    logic tk_brnch;
    logic [31:0] addr;
    logic [31:0] pc_temp;

    assign tk_brnch_o = (isJAL_i | isJALR_i) ? 1'b1 : isBRNCH_i ? tk_brnch : 1'b0;                            
    assign addr    = isJALR_i ? rs1_i : pc_i;          
    assign pc_temp = addr + imm_i;
    assign target_o = isJALR_i ? {pc_temp[31:1], 1'b0} : pc_temp;  
    
    always_comb begin
        if (isJAL_i | isJALR_i)
            res_o = pc_i + 32'd4;  
        else
            res_o = alu_res;        
    end
  
    alu IntAlu (
        .op1_i    (op1_i),
        .op2_i    (op2_i),
        .alu_op_i (ex_op_i),
        .shamt_i  (shamt_i),
        .shdir_i  (shdir_i),
        .sbtr_i   (sbtr_i),
        .alu_o    (alu_res)
    );
      
    bcu BranchCompUnit (
        .rs1_i      (rs1_i),
        .rs2_i      (rs2_i),
        .bcu_op_i   (ex_op_i),
        .tk_brnch_o (tk_brnch)
    ); 

endmodule
