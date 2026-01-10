`timescale 1ns / 1ps

module core (
    input  logic        clk,
    input  logic        arstn,
    output logic [31:0] imem_addr_o,      
    input  logic [31:0] imem_data_i,      
    output logic [31:0] dmem_addr_o,      
    output logic        dmem_we_o,        
    output logic        dmem_re_o,        
    output logic [31:0] dmem_wdata_o,     
    output logic [3:0]  dmem_wmask_o,     
    input  logic [31:0] dmem_rdata_i   // Attention: Read-Request in MEM, but Data will be available in WB one cycle later!   
);

    // Pipeline Control Signals
    logic flush_if_id, flush_id_ex;              
    
    // IF Stage Signals
    logic [31:0] pc_if;                           
    logic [31:0] target_ex;                       
    logic        tk_brnch_ex;                     
    
    // IF/ID Pipeline Register Outputs
    logic [31:0] pc_id;                           
    logic [31:0] instr_id;                       
    
    // ID Stage Signals
    // Register File Outputs
    logic [31:0] rs1_data_id, rs2_data_id;        
    logic [4:0]  rs1_addr_id, rs2_addr_id;        //  for Hazard Detection
    // Decoded Control Signals
    logic [2:0]  ex_op_id, mem_op_id;             
    logic        isBRNCH_id, isJAL_id, isJALR_id; 
    logic        isLUI_id, isAUIPC_id;           
    logic        is_load_id, is_store_id;         
    logic        rd_we_id;                        
    logic [4:0]  rd_addr_id;                      
    
    // ALU Operands & Control
    logic [31:0] op1_id, op2_id;                  
    logic [4:0]  shamt_id;                        
    logic        shdir_id, sbtr_id;               
    
    // Immediate & PC
    logic [31:0] imm_id;                          
    logic [31:0] pc_id_out;                       
        
    // ID/EX Pipeline Register Outputs
    logic [31:0] pc_ex;                           
    logic [31:0] rs1_data_ex, rs2_data_ex;        
    logic [4:0]  rs1_addr_ex, rs2_addr_ex;        
    logic [31:0] op1_ex, op2_ex;                  
    logic [31:0] imm_ex;                          
    logic [2:0]  ex_op_ex, mem_op_ex;             
    logic [4:0]  shamt_ex;                        
    logic        shdir_ex, sbtr_ex;               
    logic        isBRNCH_ex, isJAL_ex, isJALR_ex; 
    logic        is_load_ex, is_store_ex;         
    logic [4:0]  rd_addr_ex;                      
    logic        rd_we_ex;                        

    logic is_ecall_id, is_ebreak_id;
    logic is_ecall_ex, is_ebreak_ex;
    logic is_mret_id,  is_mret_ex;
    // CSR Outputs
    logic [31:0] mtvec;    // Trap Handler adress
    logic [31:0] mepc;     // Return adress
    
    // Trap Signal 
    logic trap_ex;
    
    // EX Stage Signals
    logic [31:0] alu_result_ex;                   
    logic [31:0] op1_ex_forwarded;                
    logic [31:0] op2_ex_forwarded; 
    logic [31:0] rs1_ex_forwarded;
    logic [31:0] rs2_ex_forwarded;
        
    // EX/MEM Pipeline Register Outputs
    logic [31:0] pc_mem;                          
    logic [31:0] alu_result_mem;                  
    logic [31:0] rs2_data_mem;                   
    logic [4:0]  rs2_addr_mem;                    
    logic [2:0]  mem_op_mem;                      
    logic        is_load_mem, is_store_mem;       
    logic [4:0]  rd_addr_mem;                     
    logic        rd_we_mem;                      
    
    // MEM Stage Signals
    logic [1:0]  byte_lane_mem;                   
    logic [1:0]  access_size_mem;                
    logic        unsigned_load_mem;               
    logic        align_err_mem;                   
    logic [31:0] store_data_forwarded;            
    
    // MEM/WB Pipeline Register Outputs
    logic [31:0] pc_wb;                          
    logic [31:0] alu_result_wb;                   
    logic        is_load_wb;                      
    logic [1:0]  byte_lane_wb;                    
    logic [1:0]  access_size_wb;                  
    logic        unsigned_load_wb;                
    logic        align_err_wb;                    
    logic [4:0]  rd_addr_wb_pipe;                 
    logic        rd_we_wb_pipe;                   
    
    // WB Stage Signals (final outputs)
    logic [4:0]  rd_addr_wb;                      
    logic [31:0] rd_data_wb;                      
    logic        rd_we_wb;                       
    
    // Hazard Control Unit Signals
    logic [1:0]  forward_a_sel;                   // for op1
    logic [1:0]  forward_b_sel;                   // for op2
    logic [1:0]  forward_store_sel;               
    logic        stall_hzu;                       // from Hazard Detection Unit
    logic        flush_if_id_hzu;                 
    logic        flush_id_ex_hzu;                 

    assign flush_if_id = flush_if_id_hzu || trap_ex || is_mret_ex;
    assign flush_id_ex = flush_id_ex_hzu || trap_ex || is_mret_ex;
    assign imem_addr_o = pc_if;    
    assign trap_ex = is_ecall_ex || is_ebreak_ex;

    // Trap/MRET Target Mux
    logic [31:0] next_pc_target;
    logic        take_trap_or_mret;
    
    always_comb begin
        if (trap_ex) begin
            next_pc_target = mtvec;      // Go to Trap Handler
            take_trap_or_mret = 1'b1;
        end else if (is_mret_ex) begin
            next_pc_target = mepc;       // Return from Trap
            take_trap_or_mret = 1'b1;
        end else begin
            next_pc_target = target_ex;  // Normal (Branch/Jump)
            take_trap_or_mret = 1'b0;
        end
    end
    
    IF u_if (
        .clk_i      (clk),
        .arstn_i    (arstn),
        .en_i       (!stall_hzu),
        .target_i   (next_pc_target),
        .tk_brnch_i (tk_brnch_ex || take_trap_or_mret),
        .pc_o       (pc_if)
    );
    
    pipe_if_id u_pipe_if_id (
        .clk        (clk),
        .rstn       (arstn),
        .flush_i    (flush_if_id),
        .stall_i    (stall_hzu),
        .pc_if      (pc_if),
        .instr_if   (imem_data_i),
        .pc_id      (pc_id),
        .instr_id   (instr_id)
    );
    
    ID u_id (
        .clk_i          (clk),
        .pc_i           (pc_id),
        .ifetched_i     (instr_id),
        .rd_addr_i      (rd_addr_wb),
        .rd_data_i      (rd_data_wb),
        .we_i           (rd_we_wb),
        .rs1_data_o     (rs1_data_id),
        .rs2_data_o     (rs2_data_id),
        .ex_op_o        (ex_op_id),
        .mem_op_o       (mem_op_id),
        .isBRNCH_o      (isBRNCH_id),
        .isJAL_o        (isJAL_id),
        .isJALR_o       (isJALR_id),
        .isLUI_o        (isLUI_id),
        .isAUIPC_o      (isAUIPC_id),
        .is_mret_o      (is_mret_id),
        .op1_o          (op1_id),
        .op2_o          (op2_id),
        .shamt_o        (shamt_id),
        .shdir_o        (shdir_id),
        .sbtr_o         (sbtr_id),
        .imm_o          (imm_id),
        .is_load_o      (is_load_id),
        .is_store_o     (is_store_id),
        .rd_we_o        (rd_we_id),
        .rd_addr_o      (rd_addr_id),
        .pc_o           (pc_id_out),
        .rs1_addr_o     (rs1_addr_id),  
        .rs2_addr_o     (rs2_addr_id),   
        .is_ecall_o     (is_ecall_id),
        .is_ebreak_o    (is_ebreak_id)
    );
    
    pipe_id_ex u_pipe_id_ex (
        .clk            (clk),
        .rstn           (arstn),
        .flush_i        (flush_id_ex),
        .stall_i        (1'b0),
        .pc_id          (pc_id_out),
        .rs1_data_id    (rs1_data_id),
        .rs2_data_id    (rs2_data_id),
        .op1_id         (op1_id),
        .op2_id         (op2_id),
        .imm_id         (imm_id),
        .ex_op_id       (ex_op_id),
        .mem_op_id      (mem_op_id),
        .shamt_id       (shamt_id),
        .shdir_id       (shdir_id),
        .sbtr_id        (sbtr_id),
        .isBRNCH_id     (isBRNCH_id),
        .isJAL_id       (isJAL_id),
        .isJALR_id      (isJALR_id),
        .is_load_id     (is_load_id),
        .is_store_id    (is_store_id),
        .is_mret_id     (is_mret_id),
        .is_mret_ex     (is_mret_ex),
        .rd_addr_id     (rd_addr_id),
        .rd_we_id       (rd_we_id),
        .pc_ex          (pc_ex),
        .rs1_data_ex    (rs1_data_ex),
        .rs2_data_ex    (rs2_data_ex),
        .op1_ex         (op1_ex),
        .op2_ex         (op2_ex),
        .imm_ex         (imm_ex),
        .ex_op_ex       (ex_op_ex),
        .mem_op_ex      (mem_op_ex),
        .shamt_ex       (shamt_ex),
        .shdir_ex       (shdir_ex),
        .sbtr_ex        (sbtr_ex),
        .isBRNCH_ex     (isBRNCH_ex),
        .isJAL_ex       (isJAL_ex),
        .isJALR_ex      (isJALR_ex),
        .is_load_ex     (is_load_ex),
        .is_store_ex    (is_store_ex),
        .rd_addr_ex     (rd_addr_ex),
        .rd_we_ex       (rd_we_ex),
        .rs1_addr_id    (rs1_addr_id), 
        .rs2_addr_id    (rs2_addr_id),  
        .rs1_addr_ex    (rs1_addr_ex),  
        .rs2_addr_ex    (rs2_addr_ex),   
        .is_ecall_id    (is_ecall_id),
        .is_ebreak_id   (is_ebreak_id),
        .is_ecall_ex    (is_ecall_ex),
        .is_ebreak_ex   (is_ebreak_ex)
    );
    
 
    always_comb begin
        case (forward_a_sel)
            2'b00:   op1_ex_forwarded = op1_ex;         
            2'b01:   op1_ex_forwarded = alu_result_mem;
            2'b10:   op1_ex_forwarded = rd_data_wb;
            default: op1_ex_forwarded = op1_ex;
        endcase
    end
    
    always_comb begin
        if (is_store_ex || is_load_ex) begin
            // Load/Store: op2 == Immediate Offset therefore no Forwarding!
            op2_ex_forwarded = op2_ex;
        end else begin
            case (forward_b_sel)
                2'b00:   op2_ex_forwarded = op2_ex;
                2'b01:   op2_ex_forwarded = alu_result_mem;
                2'b10:   op2_ex_forwarded = rd_data_wb;
                default: op2_ex_forwarded = op2_ex;
            endcase
        end
    end

    
    always_comb begin
        case (forward_a_sel)
            2'b01:   rs1_ex_forwarded = alu_result_mem;
            2'b10:   rs1_ex_forwarded = rd_data_wb;
            default: rs1_ex_forwarded = rs1_data_ex;
        endcase
    end
    
    always_comb begin
        case (forward_b_sel)
            2'b01:   rs2_ex_forwarded = alu_result_mem;
            2'b10:   rs2_ex_forwarded = rd_data_wb;
            default: rs2_ex_forwarded = rs2_data_ex;
        endcase
    end

    EX u_ex (
        .ex_op_i    (ex_op_ex),
        .isBRNCH_i  (isBRNCH_ex),
        .isJAL_i    (isJAL_ex),
        .isJALR_i   (isJALR_ex),
        .op1_i      (op1_ex_forwarded),
        .op2_i      (op2_ex_forwarded),
        .shamt_i    (shamt_ex),
        .shdir_i    (shdir_ex),
        .sbtr_i     (sbtr_ex),
        .rs1_i      (rs1_ex_forwarded),
        .rs2_i      (rs2_ex_forwarded),
        .imm_i      (imm_ex),
        .pc_i       (pc_ex),
        .tk_brnch_o (tk_brnch_ex),
        .target_o   (target_ex),
        .res_o      (alu_result_ex)
    );
    
    
    pipe_ex_mem u_pipe_ex_mem (
        .clk            (clk),
        .rstn           (arstn),
        .flush_i        (1'b0),           
        .pc_ex          (pc_ex),
        .rs2_addr_ex    (rs2_addr_ex),    
        .alu_result_ex  (alu_result_ex),
        .rs2_data_ex    (rs2_data_ex),
        .mem_op_ex      (mem_op_ex),
        .is_load_ex     (is_load_ex),
        .is_store_ex    (is_store_ex),
        .rd_addr_ex     (rd_addr_ex),
        .rd_we_ex       (rd_we_ex),
        .pc_mem         (pc_mem),
        .alu_result_mem (alu_result_mem),
        .rs2_data_mem   (rs2_data_mem),
        .mem_op_mem     (mem_op_mem),
        .is_load_mem    (is_load_mem),
        .is_store_mem   (is_store_mem),
        .rd_addr_mem    (rd_addr_mem),
        .rd_we_mem      (rd_we_mem),
        .rs2_addr_mem   (rs2_addr_mem)   
    );
  
    always_comb begin
        case (forward_store_sel)
            2'b00:   store_data_forwarded = rs2_data_mem;  
            2'b01:   store_data_forwarded = rd_data_wb;    
            default: store_data_forwarded = rs2_data_mem;
        endcase
    end
    
    MEM u_mem (
        .en_i           (1'b1),           
        .is_load_i      (is_load_mem),
        .is_store_i     (is_store_mem),
        .mem_op_i       (mem_op_mem),
        .addr_i         (alu_result_mem),
        .store_data_i   (store_data_forwarded),
        .addr_o         (dmem_addr_o),
        .store_strb_o   (dmem_wmask_o),
        .store_data_o   (dmem_wdata_o),
        .we_o           (dmem_we_o),
        .re_o           (dmem_re_o),
        .byte_lane_o    (byte_lane_mem),
        .access_size_o  (access_size_mem),
        .unsigned_load_o(unsigned_load_mem),
        .align_err_o    (align_err_mem)
    );
    
    pipe_mem_wb u_pipe_mem_wb (
        .clk            (clk),
        .rstn           (arstn),
        .flush_i        (1'b0),           
        .pc_mem         (pc_mem),
        .alu_result_mem (alu_result_mem),
        .is_load_mem    (is_load_mem),
        .byte_lane_mem  (byte_lane_mem),
        .access_size_mem(access_size_mem),
        .unsigned_load_mem(unsigned_load_mem),
        .align_err_mem  (align_err_mem),
        .rd_addr_mem    (rd_addr_mem),
        .rd_we_mem      (rd_we_mem),
        .pc_wb          (pc_wb),
        .alu_result_wb  (alu_result_wb),
        .is_load_wb     (is_load_wb),
        .byte_lane_wb   (byte_lane_wb),
        .access_size_wb (access_size_wb),
        .unsigned_load_wb(unsigned_load_wb),
        .align_err_wb   (align_err_wb),
        .rd_addr_wb     (rd_addr_wb_pipe),
        .rd_we_wb       (rd_we_wb_pipe)
    );
    

    WB u_wb (
        .en_i           (1'b1),
        .is_load_i      (is_load_wb),
        .align_err_i    (align_err_wb),
        .rdata_i        (dmem_rdata_i),
        .alu_res_i      (alu_result_wb),
        .byte_lane_i    (byte_lane_wb),
        .access_size_i  (access_size_wb),
        .unsigned_load_i(unsigned_load_wb),
        .rd_we_i        (rd_we_wb_pipe),
        .rd_addr_i      (rd_addr_wb_pipe),
        .rd_addr_o      (rd_addr_wb),
        .rd_data_o      (rd_data_wb),
        .rd_we_o        (rd_we_wb)
    );
    
    hzu u_hzu (
        .rs1_addr_id        (rs1_addr_id),
        .rs2_addr_id        (rs2_addr_id),
        .is_store_id        (is_store_id),
        .rd_addr_ex         (rd_addr_ex),
        .rd_we_ex           (rd_we_ex),
        .is_load_ex         (is_load_ex),
        .rs1_addr_ex        (rs1_addr_ex),
        .rs2_addr_ex        (rs2_addr_ex),
        .tk_brnch_ex        (tk_brnch_ex),
        .rd_addr_mem        (rd_addr_mem),
        .rd_we_mem          (rd_we_mem),
        .is_load_mem        (is_load_mem),
        .rs2_addr_mem       (rs2_addr_mem),
        .is_store_mem       (is_store_mem),
        .rd_addr_wb         (rd_addr_wb),
        .rd_we_wb           (rd_we_wb),
        .forward_a_sel      (forward_a_sel),
        .forward_b_sel      (forward_b_sel),
        .forward_store_sel  (forward_store_sel),
        .stall              (stall_hzu),
        .flush_if_id        (flush_if_id_hzu),
        .flush_id_ex        (flush_id_ex_hzu)
    );
    
    csr u_csr (
        .clk            (clk),
        .rstn           (arstn),
        .trap_i         (trap_ex),
        .trap_pc_i      (pc_ex),
        .trap_cause_i   (is_ecall_ex ? 4'd11 : 4'd3),  // 11=ECALL, 3=EBREAK
        .mret_i         (is_mret_ex),
        .csr_addr_i     (12'h0),
        .csr_wdata_i    (32'h0),
        .csr_we_i       (1'b0),
        .csr_rdata_o    (),                            // currently floating
        .mtvec_o        (mtvec),
        .mepc_o         (mepc)
    );

endmodule
