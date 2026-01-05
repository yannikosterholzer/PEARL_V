`timescale 1ns / 1ps

module lsu (
    input  logic        is_load_i,
    input  logic        is_store_i,
    input  logic [2:0]  mem_op_i,
    input  logic [31:0] addr_i,
    input  logic [31:0] store_data_i,
    output logic [31:0] addr_o,
    output logic [3:0]  store_strb_o,
    output logic [31:0] store_data_o,
    output logic [1:0]  byte_lane_o,
    output logic [1:0]  access_size_o, // 00=byte, 01=halfword, 10=word
    output logic        unsigned_load_o,
    output logic        align_err_o
);
      
    always_comb begin
        byte_lane_o     = addr_i[1:0];
        unsigned_load_o = mem_op_i[2];
        unique case (mem_op_i[1:0])
            2'b00: access_size_o = 2'b00; // byte
            2'b01: access_size_o = 2'b01; // half
            2'b10: access_size_o = 2'b10; // word
            default: begin
                access_size_o = 2'b00;
                if (is_load_i || is_store_i) begin
                    assert (0)
                        else $fatal(1, "LSU: illegal mem_op encoding for load/store: %b", mem_op_i);
                end
            end
        endcase
    end
    
    assign addr_o = {addr_i[31:2], 2'b00}; // Word aligned address
    
    always_comb begin:    AL_ERR //only @ active access
        align_err_o = 1'b0;
        if (is_load_i || is_store_i) begin
            unique case (access_size_o)
                2'b00:   align_err_o = 1'b0;                   // Byte: always aligned
                2'b01:   align_err_o = addr_i[0];              // Halfword: addr[0] == 0 
                default: align_err_o = (addr_i[1:0] != 2'b00); // Word: addr[1:0]   == 0
            endcase
        end
    end
    
    always_comb begin:  STR_PCK
        store_strb_o = 4'b0000;
        store_data_o = 32'b0;
        if (is_store_i && !align_err_o) begin
            unique case (access_size_o)
                2'b00:   begin // SB
                    store_strb_o = (4'b0001 << byte_lane_o);
                    store_data_o = (store_data_i & 32'h0000_00FF) << (8 * byte_lane_o);
                end
                2'b01:   begin // SH
                    store_strb_o = byte_lane_o[1] ? 4'b1100 : 4'b0011;
                    store_data_o = (store_data_i & 32'h0000_FFFF) << (byte_lane_o[1] ? 16 : 0);
                end
                default: begin // SW
                    store_strb_o = 4'b1111;
                    store_data_o = store_data_i;
                end
            endcase
        end
    end
    
endmodule
