`timescale 1ns / 1ps

module pipe_ex_mem(
    input  logic        clk,
    input  logic        rstn,
    input  logic        flush_i,
    input  logic [31:0] pc_ex,
    input  logic [31:0] alu_result_ex,      
    input  logic [31:0] rs2_data_ex,        
    input  logic [2:0]  mem_op_ex,
    input  logic        is_load_ex,
    input  logic        is_store_ex,
    input  logic [4:0]  rd_addr_ex,
    input  logic        rd_we_ex,
    output logic [31:0] pc_mem,
    output logic [31:0] alu_result_mem,
    output logic [31:0] rs2_data_mem,
    output logic [2:0]  mem_op_mem,
    output logic        is_load_mem,
    output logic        is_store_mem,
    output logic [4:0]  rd_addr_mem,
    output logic        rd_we_mem,
    input  logic [4:0]  rs2_addr_ex,
    output logic [4:0]  rs2_addr_mem
);
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_mem          <= 32'd0;
            alu_result_mem  <= 32'd0;
            rs2_data_mem    <= 32'd0;
            mem_op_mem      <= 3'd0;
            is_load_mem     <= 1'b0;
            is_store_mem    <= 1'b0;
            rd_addr_mem     <= 5'd0;
            rd_we_mem       <= 1'b0;
            rs2_addr_mem    <= 5'd0;  

        end else if (flush_i) begin
            pc_mem          <= 32'd0;
            alu_result_mem  <= 32'd0;
            rs2_data_mem    <= 32'd0;
            mem_op_mem      <= 3'd0;
            is_load_mem     <= 1'b0;
            is_store_mem    <= 1'b0;
            rd_addr_mem     <= 5'd0;
            rd_we_mem       <= 1'b0;
            rs2_addr_mem    <= 5'd0;  

        end else begin
            pc_mem          <= pc_ex;
            alu_result_mem  <= alu_result_ex;
            rs2_data_mem    <= rs2_data_ex;
            mem_op_mem      <= mem_op_ex;
            is_load_mem     <= is_load_ex;
            is_store_mem    <= is_store_ex;
            rd_addr_mem     <= rd_addr_ex;
            rd_we_mem       <= rd_we_ex;
            rs2_addr_mem    <= rs2_addr_ex;  
        end
    end
    
endmodule
