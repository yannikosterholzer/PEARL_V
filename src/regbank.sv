`timescale 1ns / 1ps

module regbank(
      input  logic        clk,
      input  logic        we_i,
      input  logic [4:0]  rs1_addr_i, 
      input  logic [4:0]  rs2_addr_i, 
      input  logic [4:0]  rd_addr_i,
      input  logic [31:0] rd_data_i,
      output logic [31:0] rs1_data_o,
      output logic [31:0] rs2_data_o
);
    logic [31:0] regs [0:31];    
    
    always_ff @(posedge clk)
        if(we_i && (rd_addr_i != 0))
            regs[rd_addr_i] <= rd_data_i;
    
    always_comb begin: Read_RS1 //with write-first bypass
        if(rs1_addr_i == 5'd0)
            rs1_data_o = 32'b0;
        else if((rs1_addr_i == rd_addr_i) && we_i)
            rs1_data_o = rd_data_i;
        else
            rs1_data_o = regs[rs1_addr_i];
    end  

    always_comb begin: Read_RS2 
        if(rs2_addr_i == 5'd0)               
            rs2_data_o = 32'b0;              
        else if((rs2_addr_i == rd_addr_i) && we_i)
            rs2_data_o = rd_data_i;          
        else
            rs2_data_o = regs[rs2_addr_i];   
    end
       
endmodule
