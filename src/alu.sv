`timescale 1ns / 1ps

module alu(
        input  logic [31:0] op1_i, 
        input  logic [31:0] op2_i,
        input  logic [2:0]  alu_op_i,
        input  logic [4:0]  shamt_i,
        input  logic        shdir_i,
        input  logic        sbtr_i,
        output logic [31:0] alu_o
     );
    
    always_comb begin
        alu_o = 32'b0;
        unique casez(alu_op_i)
            3'b000 : alu_o = (sbtr_i) ? (op1_i - op2_i) : (op1_i + op2_i);
            3'b001 : alu_o = op1_i << shamt_i;
            3'b010 : alu_o = {31'b0, ($signed(op1_i) < $signed(op2_i))};
            3'b011 : alu_o = {31'b0, (op1_i < op2_i)};
            3'b100 : alu_o = (op1_i ^ op2_i);   
            3'b101 : begin
                        if (shdir_i) 
                            alu_o = $unsigned($signed(op1_i) >>> shamt_i); // $unsigned is necessary!!! when using only $signed(op1_i) >>> shamt_i) -> nasty bugs will appear
                        else         
                            alu_o = op1_i >> shamt_i;
                     end     
            3'b110 : alu_o = (op1_i | op2_i);
            3'b111 : alu_o = (op1_i & op2_i);
            default: alu_o = 32'b0;
        endcase
     end
     
endmodule
