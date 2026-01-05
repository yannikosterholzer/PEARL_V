`timescale 1ns / 1ps

module i_mem #( 
    parameter MSIZE = 255, 
    parameter string instr_path = "filename"
)
(
    input  logic [31:0] mem_addr_i,
    output logic [31:0] mem_R_data_o
);
    
    logic [29:0] word_addr;
    logic [31:0] memory [0 : MSIZE];
    
    assign word_addr = mem_addr_i[31:2];
    
    always_comb begin: MEM_READ
        if (word_addr <= MSIZE) begin
            mem_R_data_o = memory[word_addr];
        end else begin
            mem_R_data_o = 32'h30200073;  // returns MRET @ invalid address just for testing otherwise (in future) nop
        end
    end 
    
    initial begin: INIT_MEM   
        $readmemh(instr_path, memory);
    end
 
endmodule
