`timescale 1ns / 1ps

module WB (
      input  logic        en_i,
      input  logic        is_load_i,
      input  logic        align_err_i,
      input  logic [31:0] rdata_i,
      input  logic [31:0] alu_res_i,
      input  logic [1:0]  byte_lane_i,
      input  logic [1:0]  access_size_i,   // 00=byte, 01=halfword, 10=word
      input  logic        unsigned_load_i,
      input  logic        rd_we_i,
      input  logic [4:0]  rd_addr_i,
      output logic [4:0]  rd_addr_o,
      output logic [31:0] rd_data_o,
      output logic        rd_we_o
    );
    
    logic [31:0] load_data;
    
    assign rd_we_o = en_i && rd_we_i && !(is_load_i && align_err_i);
    assign rd_addr_o = rd_we_o ? rd_addr_i : 5'b0;
    assign rd_data_o = rd_we_o ? (is_load_i ? load_data : alu_res_i) : 32'b0;

    
    load_wb u_load_wb (
        .is_load_i        (is_load_i),
        .align_err_i      (align_err_i),
        .rdata_i          (rdata_i),
        .byte_lane_i      (byte_lane_i),
        .access_size_i    (access_size_i),
        .unsigned_load_i  (unsigned_load_i),
        .load_data_o      (load_data)
    );
    
endmodule    
