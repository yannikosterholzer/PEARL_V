`timescale 1ns / 1ps

module top #(
    parameter IMEM_SIZE = 255,
    parameter DMEM_SIZE = 255,
    parameter string PROGRAM_FILE = "Instructions.mem"
)(
    input  logic clk,
    input  logic arstn
);


    // Instruction Memory 
    logic [31:0] imem_addr;
    logic [31:0] imem_data;

    // Data Memory 
    logic [31:0] dmem_addr;
    logic        dmem_we;
    logic        dmem_re;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_wmask;
    logic [31:0] dmem_rdata;

    
    i_mem #(
        .MSIZE      (IMEM_SIZE),
        .instr_path (PROGRAM_FILE)
    ) u_imem (
        .mem_addr_i   (imem_addr),
        .mem_R_data_o (imem_data)
    );
      
    d_mem #(
        .MSIZE (DMEM_SIZE)
    ) u_dmem (
        .clk           (clk),
        .mem_addr_i    (dmem_addr),
        .we_i          (dmem_we),
        .re_i          (dmem_re),
        .mem_W_data_i  (dmem_wdata),
        .mem_W_mask_i  (dmem_wmask),
        .mem_R_data_o  (dmem_rdata)
    );
    
    core u_core (
        .clk          (clk),
        .arstn        (arstn),
        .imem_addr_o  (imem_addr),
        .imem_data_i  (imem_data),
        .dmem_addr_o  (dmem_addr),
        .dmem_we_o    (dmem_we),
        .dmem_re_o    (dmem_re),
        .dmem_wdata_o (dmem_wdata),
        .dmem_wmask_o (dmem_wmask),
        .dmem_rdata_i (dmem_rdata)
    );

endmodule
