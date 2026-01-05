`timescale 1ns / 1ps

module IF(
    input  logic        clk_i,
    input  logic        arstn_i,
    input  logic        en_i,
    input  logic [31:0] target_i,
    input  logic        tk_brnch_i,
    output logic [31:0] pc_o
);

    logic [31:0] next_pc;
    assign next_pc = (tk_brnch_i)? target_i : pc_o + 32'd4;
    
    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (!arstn_i)
            pc_o <= 32'd0;
        else if (en_i)
            pc_o <= next_pc;
    end

endmodule
