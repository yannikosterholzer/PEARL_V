`timescale 1ns / 1ps

module csr (
    input  logic        clk,
    input  logic        rstn,
    input  logic        trap_i,           
    input  logic [31:0] trap_pc_i,        
    input  logic [3:0]  trap_cause_i,     // Trap-cause (3=EBREAK, 11=ECALL)
    input  logic        mret_i,           // not yet used according to the specification (RISC-V Privileged Spec)
    input  logic [11:0] csr_addr_i,       
    input  logic [31:0] csr_wdata_i,      
    input  logic        csr_we_i,         
    output logic [31:0] csr_rdata_o,      
    output logic [31:0] mtvec_o,          
    output logic [31:0] mepc_o           
);

    // CSR Addrs (RISC-V Privileged Spec)
    // RISC-V Privileged Specification, Version 20250508: Table @ Page 18
    localparam logic [11:0] CSR_MSTATUS = 12'h300;
    localparam logic [11:0] CSR_MTVEC   = 12'h305;
    localparam logic [11:0] CSR_MEPC    = 12'h341;
    localparam logic [11:0] CSR_MCAUSE  = 12'h342;

    // Trap Cause Codes (RISC-V Privileged Spec)
    localparam logic [3:0] CAUSE_BREAKPOINT = 4'd3;
    localparam logic [3:0] CAUSE_ECALL_M    = 4'd11;

    // CSR Register
    logic [31:0] mstatus;    // Machine Status (Placeholder)
    logic [31:0] mtvec;      // Machine Trap Vector
    logic [31:0] mepc;       // Machine Exception PC
    logic [31:0] mcause;     // Machine Cause

    // Hardcoded Trap Vector (temporary(!) workaround to achieve minimal working state)
    localparam logic [31:0] MTVEC_DEFAULT = 32'hFFFFFF00;

    //outputs
    assign mtvec_o = mtvec; // RISC-V Privileged Spec @ Page 39
    assign mepc_o  = mepc;

    always_ff @(posedge clk or negedge rstn) begin: WRITE_CSR
        if (!rstn) begin
            mstatus <= 32'h0;
            mtvec   <= MTVEC_DEFAULT;  // currently: Hardcoded Trap Handler
            mepc    <= 32'h0;
            mcause  <= 32'h0;
        end else if (trap_i) begin
            // @ Trap: save PC and Cause speichern
            // ECALL: mepc = pc + 4 (ret to next instr.)
            // EBREAK: mepc = pc (ret to same instr.)
            if (trap_cause_i == CAUSE_ECALL_M)
                mepc <= trap_pc_i + 32'd4; // simplified -> does not correspond to the specification, correct in future revisions
            else
                mepc <= trap_pc_i;
            mcause <= {28'h0, trap_cause_i};
            /* RISC-V Privileged Spec @ Page 47
            "The mcause register is an MXLEN-bit read-write register formatted as shown in Figure 22. When a trap
            is taken into M-mode, mcause is written with a code indicating the event that caused the trap.
            Otherwise, mcause is never written by the implementation, though it may be explicitly written by
            software."
            */
        end else if (csr_we_i) begin
           // CSR Write (for future updates)
            case (csr_addr_i)
                CSR_MSTATUS: mstatus <= csr_wdata_i;
                CSR_MTVEC:   mtvec   <= csr_wdata_i;
                CSR_MEPC:    mepc    <= csr_wdata_i;
                CSR_MCAUSE:  mcause  <= csr_wdata_i;
                default: ; // Ignore
            endcase
        end
    end

    always_comb begin:    READ_CSR               // for future updates
        case (csr_addr_i)
            CSR_MSTATUS: csr_rdata_o = mstatus;
            CSR_MTVEC:   csr_rdata_o = mtvec;
            CSR_MEPC:    csr_rdata_o = mepc;
            CSR_MCAUSE:  csr_rdata_o = mcause;
            default:     csr_rdata_o = 32'h0;
        endcase
    end

endmodule
