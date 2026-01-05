`timescale 1ns / 1ps

module pipe_mem_wb(
    input  logic        clk,
    input  logic        rstn,
    input  logic        flush_i,
    input  logic [31:0] pc_mem,
    input  logic [31:0] alu_result_mem,
    input  logic        is_load_mem,
    input  logic [1:0]  byte_lane_mem,
    input  logic [1:0]  access_size_mem,
    input  logic        unsigned_load_mem,
    input  logic        align_err_mem,
    input  logic [4:0]  rd_addr_mem,
    input  logic        rd_we_mem,
    output logic [31:0] pc_wb,
    output logic [31:0] alu_result_wb,
    output logic        is_load_wb,
    output logic [1:0]  byte_lane_wb,
    output logic [1:0]  access_size_wb,
    output logic        unsigned_load_wb,
    output logic        align_err_wb,
    output logic [4:0]  rd_addr_wb,
    output logic        rd_we_wb
);
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_wb           <= 32'd0;
            alu_result_wb   <= 32'd0;
            is_load_wb      <= 1'b0;
            byte_lane_wb    <= 2'd0;
            access_size_wb  <= 2'd0;
            unsigned_load_wb<= 1'b0;
            align_err_wb    <= 1'b0;
            rd_addr_wb      <= 5'd0;
            rd_we_wb        <= 1'b0;

        end else if (flush_i) begin
            pc_wb           <= 32'd0;
            alu_result_wb   <= 32'd0;
            is_load_wb      <= 1'b0;
            byte_lane_wb    <= 2'd0;
            access_size_wb  <= 2'd0;
            unsigned_load_wb<= 1'b0;
            align_err_wb    <= 1'b0;
            rd_addr_wb      <= 5'd0;
            rd_we_wb        <= 1'b0;

        end else begin
            pc_wb           <= pc_mem;
            alu_result_wb   <= alu_result_mem;
            is_load_wb      <= is_load_mem;
            byte_lane_wb    <= byte_lane_mem;
            access_size_wb  <= access_size_mem;
            unsigned_load_wb<= unsigned_load_mem;
            align_err_wb    <= align_err_mem;
            rd_addr_wb      <= rd_addr_mem;
            rd_we_wb        <= rd_we_mem;
        end
    end

endmodule
