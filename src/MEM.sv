`timescale 1ns / 1ps

module MEM(
    input  logic        en_i,
    input  logic        is_load_i,
    input  logic        is_store_i,
    input  logic [2:0]  mem_op_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] store_data_i,
    output logic [31:0] addr_o,
    output logic [3:0]  store_strb_o,
    output logic [31:0] store_data_o,
    output logic        we_o,
    output logic        re_o,
    output logic [1:0] byte_lane_o,
    output logic [1:0] access_size_o, // 00=byte, 01=halfword, 10=word
    output logic       unsigned_load_o,
    output logic       align_err_o
);

    always_comb begin  // access only if Stage == activ and NO Alignment-Error
        {we_o, re_o} = 2'b00;
        if (en_i && !align_err_o) begin
            {we_o, re_o} = {is_store_i, is_load_i};
        end
    end    
  
    lsu u_lsu (
        .is_load_i      (is_load_i),
        .is_store_i     (is_store_i),
        .mem_op_i       (mem_op_i),
        .addr_i         (addr_i),
        .store_data_i   (store_data_i),
        .addr_o         (addr_o),
        .store_strb_o   (store_strb_o),
        .store_data_o   (store_data_o),
        .byte_lane_o    (byte_lane_o),
        .access_size_o  (access_size_o),
        .unsigned_load_o(unsigned_load_o),
        .align_err_o    (align_err_o)
    );
      
endmodule
