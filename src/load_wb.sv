`timescale 1ns / 1ps

module load_wb (
  input  logic        is_load_i,
  input  logic        align_err_i,
  input  logic [31:0] rdata_i,
  input  logic [1:0]  byte_lane_i,
  input  logic [1:0]  access_size_i,   // 00=byte, 01=halfword, 10=word
  input  logic        unsigned_load_i,
  output logic [31:0] load_data_o
);


  logic [15:0] halfword;
  logic [7:0]  byte_val;
  logic        sign;
  always_comb begin
    load_data_o = 32'b0;
    if (is_load_i && !align_err_i) begin
      halfword = byte_lane_i[1] ? rdata_i[31:16] : rdata_i[15:0];
      byte_val = byte_lane_i[0] ? halfword[15:8] : halfword[7:0];
      sign = !unsigned_load_i &&
             ((access_size_i == 2'b00) ? byte_val[7] : halfword[15]);
      unique case (access_size_i)
        2'b00:   load_data_o = {{24{sign}}, byte_val};  // LB / LBU
        2'b01:   load_data_o = {{16{sign}}, halfword};  // LH / LHU
        default: load_data_o = rdata_i;                 // LW
      endcase
    end
  end

endmodule
