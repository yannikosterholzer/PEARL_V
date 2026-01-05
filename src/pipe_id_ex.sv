`timescale 1ns / 1ps

module pipe_id_ex(
    input  logic        clk,
    input  logic        rstn,
    input  logic        flush_i,
    input logic         stall_i,
    input  logic [31:0] pc_id,
    input  logic [31:0] rs1_data_id,
    input  logic [31:0] rs2_data_id,
    input  logic [31:0] op1_id,
    input  logic [31:0] op2_id,
    input  logic [31:0] imm_id,
    input  logic [2:0]  ex_op_id,
    input  logic [2:0]  mem_op_id,
    input  logic [4:0]  shamt_id,
    input  logic        shdir_id,
    input  logic        sbtr_id,
    input  logic        isBRNCH_id,
    input  logic        isJAL_id,
    input  logic        isJALR_id,
    input  logic        is_load_id,
    input  logic        is_store_id,
    input  logic [4:0]  rd_addr_id,
    input  logic        rd_we_id,
    input  logic        is_ecall_id,
    input  logic        is_ebreak_id,
    input  logic        is_mret_id, 
    output logic [31:0] pc_ex,
    output logic [31:0] rs1_data_ex,
    output logic [31:0] rs2_data_ex,
    output logic [31:0] op1_ex,
    output logic [31:0] op2_ex,
    output logic [31:0] imm_ex,
    output logic [2:0]  ex_op_ex,
    output logic [2:0]  mem_op_ex,
    output logic [4:0]  shamt_ex,
    output logic        shdir_ex,
    output logic        sbtr_ex,
    output logic        isBRNCH_ex,
    output logic        isJAL_ex,
    output logic        isJALR_ex,
    output logic        is_load_ex,
    output logic        is_store_ex,
    output logic        is_ecall_ex,
    output logic        is_ebreak_ex,
    output logic        is_mret_ex,      
    output logic [4:0]  rd_addr_ex,
    output logic        rd_we_ex,
    input  logic [4:0] rs1_addr_id,
    input  logic [4:0] rs2_addr_id,
    output logic [4:0] rs1_addr_ex,
    output logic [4:0] rs2_addr_ex
);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_ex           <= 32'd0;
            rs1_data_ex     <= 32'd0;
            rs2_data_ex     <= 32'd0;
            op1_ex          <= 32'd0;
            op2_ex          <= 32'd0;
            imm_ex          <= 32'd0;
            ex_op_ex        <= 3'd0;
            mem_op_ex       <= 3'd0;
            shamt_ex        <= 5'd0;
            shdir_ex        <= 1'b0;
            sbtr_ex         <= 1'b0;
            isBRNCH_ex      <= 1'b0;
            isJAL_ex        <= 1'b0;
            isJALR_ex       <= 1'b0;
            is_load_ex      <= 1'b0;
            is_store_ex     <= 1'b0;
            rd_addr_ex      <= 5'd0;
            rd_we_ex        <= 1'b0;
            rs1_addr_ex     <= 5'd0;  
            rs2_addr_ex     <= 5'd0;  
            is_ecall_ex  <= 1'b0;
            is_ebreak_ex <= 1'b0;
            is_mret_ex   <= 1'b0; 
            
        end else if (flush_i) begin
            pc_ex           <= 32'd0;
            rs1_data_ex     <= 32'd0;
            rs2_data_ex     <= 32'd0;
            op1_ex          <= 32'd0;
            op2_ex          <= 32'd0;
            imm_ex          <= 32'd0;
            ex_op_ex        <= 3'd0;
            mem_op_ex       <= 3'd0;
            shamt_ex        <= 5'd0;
            shdir_ex        <= 1'b0;
            sbtr_ex         <= 1'b0;
            isBRNCH_ex      <= 1'b0;
            isJAL_ex        <= 1'b0;
            isJALR_ex       <= 1'b0;
            is_load_ex      <= 1'b0;
            is_store_ex     <= 1'b0;
            rd_addr_ex      <= 5'd0;
            rd_we_ex        <= 1'b0;
            rs1_addr_ex     <= 5'd0;  
            rs2_addr_ex     <= 5'd0;  
            is_ecall_ex     <= 1'b0;
            is_ebreak_ex    <= 1'b0;
            is_mret_ex      <= 1'b0; 
            
        end else if (!stall_i) begin 
            pc_ex           <= pc_id;
            rs1_data_ex     <= rs1_data_id;
            rs2_data_ex     <= rs2_data_id;
            op1_ex          <= op1_id;
            op2_ex          <= op2_id;
            imm_ex          <= imm_id;
            ex_op_ex        <= ex_op_id;
            mem_op_ex       <= mem_op_id;
            shamt_ex        <= shamt_id;
            shdir_ex        <= shdir_id;
            sbtr_ex         <= sbtr_id;
            isBRNCH_ex      <= isBRNCH_id;
            isJAL_ex        <= isJAL_id;
            isJALR_ex       <= isJALR_id;
            is_load_ex      <= is_load_id;
            is_store_ex     <= is_store_id;
            rd_addr_ex      <= rd_addr_id;
            rd_we_ex        <= rd_we_id;
            rs1_addr_ex     <= rs1_addr_id;  
            rs2_addr_ex     <= rs2_addr_id;  
            is_ecall_ex     <= is_ecall_id;
            is_ebreak_ex    <= is_ebreak_id;
            is_mret_ex      <= is_mret_id; 
        end
    end
    
endmodule
