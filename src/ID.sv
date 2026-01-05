`timescale 1ns / 1ps

module ID (
            input  logic        clk_i,
            input  logic [31:0] pc_i,
            input  logic [31:0] ifetched_i,
            input  logic [4:0]  rd_addr_i,
            input  logic [31:0] rd_data_i,
            input  logic        we_i, 
            output logic [31:0] rs1_data_o,
            output logic [31:0] rs2_data_o,
            output logic [2:0]  ex_op_o,
            output logic [2:0]  mem_op_o,
            output logic        isBRNCH_o,
            output logic        isJAL_o,
            output logic        isJALR_o,
            output logic        isLUI_o,
            output logic        isAUIPC_o,
            output logic        is_fence_o,
            output logic        is_fence_i_o,
            output logic        is_ecall_o,    
            output logic        is_ebreak_o,   
            output logic        is_mret_o, 
            output logic [31:0] op1_o,
            output logic [31:0] op2_o,
            output logic [4:0]  shamt_o,
            output logic        shdir_o,
            output logic        sbtr_o,
            output logic [31:0] imm_o,
            output logic        is_load_o,
            output logic        is_store_o,
            output logic        rd_we_o,
            output logic [4:0]  rd_addr_o,
            output logic [31:0] pc_o,
            output logic [4:0] rs1_addr_o,
            output logic [4:0] rs2_addr_o
        );
    
    import i_formats::*;
  
    instr_base_t instr;
    assign instr = ifetched_i;
    assign pc_o = pc_i;
    
    instr_r_rv32i_t  instr_r_rv32i;
    instr_i_rv32i_t  instr_i_rv32i;
    instr_s_rv32i_t  instr_s_rv32i;
    instr_b_rv32i_t  instr_b_rv32i;
    instr_u_rv32i_t  instr_u_rv32i;
    instr_j_rv32i_t  instr_j_rv32i;
    
    assign instr_r_rv32i = instr_r_rv32i_t'(instr.i_rest);
    assign instr_i_rv32i = instr_i_rv32i_t'(instr.i_rest);
    assign instr_s_rv32i = instr_s_rv32i_t'(instr.i_rest);
    assign instr_b_rv32i = instr_b_rv32i_t'(instr.i_rest);
    assign instr_u_rv32i = instr_u_rv32i_t'(instr.i_rest);
    assign instr_j_rv32i = instr_j_rv32i_t'(instr.i_rest);
    
    instr_fields_t fields;
    
    regbank IntRegFile(
        .clk        (clk_i),
        .we_i       (we_i),
        .rs1_addr_i (fields.rs1),
        .rs2_addr_i (fields.rs2),
        .rd_addr_i  (rd_addr_i),
        .rd_data_i  (rd_data_i),
        .rs1_data_o (rs1_data_o), 
        .rs2_data_o (rs2_data_o)
    );
    

     
    always_comb begin: DECODE // detect Instruction Types and extract Fields     
        fields = '0;
        fields.opcode = instr.opcode;
        isBRNCH_o  = 1'b0;
        isJAL_o    = 1'b0;
        isJALR_o   = 1'b0;
        isLUI_o    = 1'b0;
        isAUIPC_o  = 1'b0;
        is_load_o  = 1'b0;
        is_store_o = 1'b0;
        rd_we_o    = 1'b0;
        
        case (instr.opcode)
            RV32I_R_OP: begin  
                fields.rd     = instr_r_rv32i.rd;     
                fields.rs1    = instr_r_rv32i.rs1;    
                fields.rs2    = instr_r_rv32i.rs2;    
                fields.funct3 = instr_r_rv32i.funct3; 
                fields.funct7 = instr_r_rv32i.funct7;
                rd_we_o       = 1'b1;
            end
            
            RV32I_IALU: begin  
                fields.rd     = instr_i_rv32i.rd;     
                fields.rs1    = instr_i_rv32i.rs1;    
                fields.funct3 = instr_i_rv32i.funct3; 
                fields.imm    = I_imm(instr_i_rv32i);
                rd_we_o       = 1'b1;
            end
            
            RV32I_LOAD: begin  
                fields.rd     = instr_i_rv32i.rd;     
                fields.rs1    = instr_i_rv32i.rs1;    
                fields.funct3 = instr_i_rv32i.funct3; 
                fields.imm    = I_imm(instr_i_rv32i);
                is_load_o     = 1'b1;
                rd_we_o       = 1'b1;
            end
            
            RV32I_JALR: begin  
                fields.rd     = instr_i_rv32i.rd;     
                fields.rs1    = instr_i_rv32i.rs1;    
                fields.funct3 = instr_i_rv32i.funct3; 
                fields.imm    = I_imm(instr_i_rv32i);
                isJALR_o      = 1'b1;
                rd_we_o       = 1'b1;
            end
            
            RV32I_S_OP: begin  
                fields.rs1    = instr_s_rv32i.rs1;    
                fields.rs2    = instr_s_rv32i.rs2;    
                fields.funct3 = instr_s_rv32i.funct3; 
                fields.imm    = S_imm(instr_s_rv32i);
                is_store_o    = 1'b1;
            end
            
            RV32I_B_OP: begin  
                fields.rs1    = instr_b_rv32i.rs1;    
                fields.rs2    = instr_b_rv32i.rs2;    
                fields.funct3 = instr_b_rv32i.funct3; 
                fields.imm    = B_imm(instr_b_rv32i);
                isBRNCH_o     = 1'b1;
            end
            
            RV32I_LUI: begin  
                fields.rd  = instr_u_rv32i.rd;     
                fields.imm = U_imm(instr_u_rv32i);
                isLUI_o    = 1'b1;
                rd_we_o    = 1'b1;
            end
            
            RV32I_AUIPC: begin  
                fields.rd  = instr_u_rv32i.rd;     
                fields.imm = U_imm(instr_u_rv32i);
                isAUIPC_o  = 1'b1;
                rd_we_o    = 1'b1;
            end
            
            RV32I_JAL: begin  
                fields.rd  = instr_j_rv32i.rd;     
                fields.imm = J_imm(instr_j_rv32i);
                isJAL_o    = 1'b1;
                rd_we_o    = 1'b1;
            end
            
            RV32I_FENCE: begin  // FENCE / FENCE.I -> NOP for Single-Core
              fields.funct3 = 3'b000;  // Force ADD-Operation (== NOP)
                // all other fields == 0
            end
            
            RV32I_SYSTEM: begin  // ECALL / EBREAK -> Trap
                fields.funct3 = 3'b000;  // like a NOP
                // No Register-usage + no Writeback
            end
            
            default: begin
                fields = '0;
            end
        endcase
    end
    
    always_comb begin: GEN_CTRL_SIGS
        imm_o        = fields.imm;
        rd_addr_o    = fields.rd;
        ex_op_o      = fields.funct3;
        mem_op_o     = 3'b000;
        shdir_o      = instr[30];              
        sbtr_o       = instr[30] & instr[5];   
        shamt_o      = instr[24:20];
        op1_o        = rs1_data_o;
        op2_o        = fields.imm;
        rs1_addr_o   = fields.rs1;  
        rs2_addr_o   = fields.rs2;  
        is_fence_o   = (instr.opcode == RV32I_FENCE)  && (instr_i_rv32i.funct3 == 3'b000);
        is_fence_i_o = (instr.opcode == RV32I_FENCE)  && (instr_i_rv32i.funct3 == 3'b001);
        is_ecall_o   = (instr.opcode == RV32I_SYSTEM) && (instr_i_rv32i.funct3 == 3'b000) && (instr_i_rv32i.imm12 == 12'h000);
        is_ebreak_o  = (instr.opcode == RV32I_SYSTEM) && (instr_i_rv32i.funct3 == 3'b000) && (instr_i_rv32i.imm12 == 12'h001);
        is_mret_o    = (instr.opcode == RV32I_SYSTEM) && (instr_i_rv32i.funct3 == 3'b000) && (instr_i_rv32i.imm12 == 12'h302);
        
        // R-Type Shift: shamt from rs2
        if (instr.opcode == RV32I_R_OP && (fields.funct3 == 3'b001 || fields.funct3 == 3'b101))
            shamt_o = rs2_data_o[4:0];
        
        
        if (isLUI_o || isAUIPC_o) begin
            ex_op_o  = 3'b000; // Clear ALU control
            sbtr_o   = 1'b0;
            shdir_o  = 1'b0;
            shamt_o  = 5'd0;
        end
        
        // Load/Store: ALU for address, mem_op for "accesstype"
        if (is_store_o || is_load_o) begin
            ex_op_o  = 3'b000;        // addition for address-calc.
            mem_op_o = fields.funct3; // Byte/Half/Word Info
        end
        
        if (isLUI_o)
            op1_o = 32'd0;
        else if (isAUIPC_o || isJAL_o)
            op1_o = pc_i;
        
        if (instr.opcode == RV32I_R_OP || isBRNCH_o)
            op2_o = rs2_data_o;
    end
        
endmodule
