package i_formats;


     /* 
     Encapsulated via 'Divide & Conquer' to decouple bitwizardy from the Decoder-Implementation,
     therefore making the Decoder (ID) more readable.
     + Uses packed structs for type-safety.

     will perhaps outsource further functions to this package in the future for improved readability.
     */

    
    localparam logic [6:0] RV32I_R_OP   = 7'b0110011;  // R-Type ALU
    localparam logic [6:0] RV32I_LOAD   = 7'b0000011;  // I-Type Load
    localparam logic [6:0] RV32I_IALU   = 7'b0010011;  // I-Type ALU imm
    localparam logic [6:0] RV32I_JALR   = 7'b1100111;  // I-Type JALR
    localparam logic [6:0] RV32I_S_OP   = 7'b0100011;  // S-Type Store
    localparam logic [6:0] RV32I_B_OP   = 7'b1100011;  // B-Type Branch
    localparam logic [6:0] RV32I_LUI    = 7'b0110111;  // U-Type LUI
    localparam logic [6:0] RV32I_AUIPC  = 7'b0010111;  // U-Type AUIPC
    localparam logic [6:0] RV32I_JAL    = 7'b1101111;  // J-Type JAL
    localparam logic [6:0] RV32I_FENCE  = 7'b0001111;  // FENCE & FENCE.I
    localparam logic [6:0] RV32I_SYSTEM = 7'b1110011;  // ECALL, EBREAK, CSRs
    
    typedef struct packed {        
          logic [24:0]  i_rest;   
          logic [6:0]   opcode;   
    } instr_base_t;
    
    typedef struct packed {
          logic [6:0]   funct7;
          logic [4:0]   rs2;
          logic [4:0]   rs1; 
          logic [2:0]   funct3;
          logic [4:0]   rd;                  
    } instr_r_rv32i_t;
    
    typedef struct packed {
          logic [11:0]  imm12;
          logic [4:0]   rs1;
          logic [2:0]   funct3;
          logic [4:0]   rd;                 
    } instr_i_rv32i_t;    
    
    typedef struct packed {
      logic [6:0]  imm7;
      logic [4:0]  rs2;
      logic [4:0]  rs1;
      logic [2:0]  funct3;
      logic [4:0]  imm5;
    } instr_s_rv32i_t;
    
    typedef struct packed {
      logic [6:0]  imm7;
      logic [4:0]  rs2;
      logic [4:0]  rs1;
      logic [2:0]  funct3;
      logic [4:0]  imm5;
    } instr_b_rv32i_t;
    
    typedef struct packed {
      logic [19:0] imm20;
      logic [4:0]  rd;
    } instr_u_rv32i_t;
    
    typedef struct packed {
      logic [19:0] imm20;
      logic [4:0]  rd;
    } instr_j_rv32i_t;
    
    typedef struct packed {
      logic [6:0]  opcode;          // for i-type detection
      logic [4:0]  rd, rs1, rs2;    // for RegFile access
      logic [2:0]  funct3;          // for ALU/BCU/LSU Control
      logic [6:0]  funct7;          // for sbtr/shdir Berechnung
      logic [31:0] imm;             // Immediate
    } instr_fields_t;
         
    function automatic logic [31:0] I_imm(input instr_i_rv32i_t instr);
        I_imm = {{20{instr.imm12[11]}}, instr.imm12};  
    endfunction : I_imm;
     
    function automatic logic [31:0] S_imm(input instr_s_rv32i_t instr);
        S_imm = {{21{instr.imm7[6]}}, instr.imm7[5:0], instr.imm5[4:0]};
    endfunction : S_imm;
    
    function automatic logic [31:0] B_imm(input instr_b_rv32i_t instr);
        B_imm = {{21{instr.imm7[6]}}, instr.imm5[0], instr.imm7[5:0], instr.imm5[4:1], 1'b0};
    endfunction : B_imm;
    
    function automatic logic [31:0] U_imm(input instr_u_rv32i_t instr);
        U_imm = {instr.imm20[19:0], {12{1'b0}}};
    endfunction : U_imm;
    
    function automatic logic [31:0] J_imm(input instr_j_rv32i_t instr);
        J_imm = {{12{instr.imm20[19]}}, instr.imm20[7:0], instr.imm20[8], instr.imm20[18:9], 1'b0};
    endfunction : J_imm;
   
endpackage : i_formats
