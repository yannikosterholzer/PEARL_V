`timescale 1ns / 1ps

module pipe_if_id(
    input  logic        clk,
    input  logic        rstn,
    input  logic        flush_i,     
    input logic         stall_i,     
    input  logic [31:0] pc_if,
    input  logic [31:0] instr_if,
    output logic [31:0] pc_id,
    output logic [31:0] instr_id
);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_id    <= 32'd0;
            instr_id <= 32'h0000_0013;  // NOP
        end else if (flush_i) begin
            pc_id    <= 32'd0;          // zeroing PC for debug purposes
            instr_id <= 32'h0000_0013;  // NOP e.g @ Branch
        end else if (!stall_i) begin     
            pc_id    <= pc_if;
            instr_id <= instr_if;
        end
    end

endmodule
