`timescale 1ns / 1ps

module d_mem #( 
    parameter MSIZE = 255
)
(
    input  logic        clk,
    input  logic [31:0] mem_addr_i,
    input  logic        we_i, 
    input  logic        re_i,
    input  logic [31:0] mem_W_data_i,
    input  logic [3:0]  mem_W_mask_i,
    output logic [31:0] mem_R_data_o
);
    logic [29:0] word_addr;
    logic [31:0] memory [0:MSIZE];
    
    assign word_addr = mem_addr_i[31:2];
    
    
    always_ff @(posedge clk) begin // Read with bounds check
        if (re_i) begin
            if (word_addr <= MSIZE) begin
                mem_R_data_o <= memory[word_addr];
            end else begin
                mem_R_data_o <= 32'hAAAAAAAA;  // Pattern @ invalid memory address
            end
        end
    end
    
    
  always_ff @(posedge clk) begin // Write with bounds check
    if (we_i && word_addr <= MSIZE) begin  // write only when valid!
            if (mem_W_mask_i[0]) memory[word_addr][ 7:0 ] <= mem_W_data_i[ 7:0 ];
            if (mem_W_mask_i[1]) memory[word_addr][15:8 ] <= mem_W_data_i[15:8 ];
            if (mem_W_mask_i[2]) memory[word_addr][23:16] <= mem_W_data_i[23:16];
            if (mem_W_mask_i[3]) memory[word_addr][31:24] <= mem_W_data_i[31:24];
        end
    end  

endmodule
