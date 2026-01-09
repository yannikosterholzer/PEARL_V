`timescale 1ns / 1ps

module hzu // Hazard and Forwarding Unit
    (
    input  logic [4:0]  rs1_addr_id,
    input  logic [4:0]  rs2_addr_id,
    input  logic        is_store_id,
    input  logic [4:0]  rd_addr_ex,
    input  logic        rd_we_ex,
    input  logic        is_load_ex,
    input  logic [4:0]  rs1_addr_ex,
    input  logic [4:0]  rs2_addr_ex,
    input  logic        tk_brnch_ex,
    input  logic [4:0]  rd_addr_mem,
    input  logic        rd_we_mem,
    input  logic        is_load_mem,
    input  logic [4:0]  rs2_addr_mem,
    input  logic        is_store_mem,
    input  logic [4:0]  rd_addr_wb,
    input  logic        rd_we_wb,
    output logic [1:0]  forward_a_sel,
    output logic [1:0]  forward_b_sel,
    output logic [1:0]  forward_store_sel,
    output logic        stall,
    output logic        flush_if_id,
    output logic        flush_id_ex
    );

    /*
    Code is split into layers (makes it easier to read and debug while building this unit):
    1. Dependency:       Consumer (rs1 or rs2 in a stage) matches Producer (rd) in a later pipeline stage (*not later in program order)
    2. Hazard:           Dependency (1) + instruction type of the producer tells us the hazard type
    3. Stall/Forwarding: Hazard type decides if we need a stall or forwarding
    */
   
    // ID stage consumer 
    logic raw_id_rs1_ex;    // ID.rs1 depends on EX.rd
    logic raw_id_rs2_ex;    // ID.rs2 depends on EX.rd
    logic raw_id_rs2_mem;   // ""     depends on MEM.rd
    logic raw_id_rs2_wb;    // etc.    
    // EX stage consumer 
    logic raw_ex_rs1_mem;   // EX.rs1 depends on MEM.rd
    logic raw_ex_rs2_mem;   // EX.rs2 depends on MEM.rd
    logic raw_ex_rs1_wb;    // ...
    logic raw_ex_rs2_wb;    // ...    
    // MEM stage consumer dependencies (for Store data)
    logic raw_mem_rs2_wb;   // MEM.rs2 (store data) depends on WB.rd
    // Load-Use Hazards: Consumer in ID needs data from Load in EX, data not ready until MEM completes!!!
    // -> therefore pipeline must stall 1 cycle, then forward from WB
    logic hazard_load_use_rs1;
    logic hazard_load_use_rs2;
    // Store-Data Hazards:  Store in ID needs rs2 as store-data from producer in pipeline
    logic hazard_store_data_ex;    // Producer is Load in EX
    logic hazard_store_data_mem;   // Producer is Load in MEM
    logic hazard_store_data_wb;    // Producer in WB (currently conservative stall, not the most efficient solution -> to be improved in future revisions)
    // Forwardable RAW Hazards: Consumer can get data via forwarding (no stall needed!)
    logic hazard_fwd_rs1_mem;      // Forward from MEM to EX.rs1
    logic hazard_fwd_rs2_mem;      // Forward from MEM to EX.rs2
    logic hazard_fwd_rs1_wb;       // ...
    logic hazard_fwd_rs2_wb;       // ...
    logic hazard_fwd_store_wb;     // Forward from WB to MEM! (store data)
    // Stall: for any hazard that isn´t solved by forwarding  
    logic stall_needed;  
    
    typedef enum logic [1:0] {
        FWD_REGFILE = 2'b00,
        FWD_MEM     = 2'b01,
        FWD_WB      = 2'b10
    } forward_src_t;
    
    typedef enum logic [1:0] {
        FWD_STORE_NORMAL = 2'b00,
        FWD_STORE_WB     = 2'b01
    } forward_store_t; // one bit Signal would be enough -> to be fixed in the future

    function automatic logic detect_reg_dependency(
        input logic [4:0] consumer_rs,
        input logic [4:0] producer_rd,
        input logic       producer_we // if there´s we == 0 -> obviously no match!
    );
        return (consumer_rs == producer_rd) && (producer_rd != 5'd0) && producer_we; // if producer.rd == 0, doesn´t matter, since x0 is always zero!
    endfunction

    always_comb begin : DEPENDENCY_DETECTION // only register matches (RAW) -> WAR shoudln´t be a problem @ In-Order-Processors 
        raw_id_rs1_ex  = detect_reg_dependency(rs1_addr_id,  rd_addr_ex,  rd_we_ex);
        raw_id_rs2_ex  = detect_reg_dependency(rs2_addr_id,  rd_addr_ex,  rd_we_ex);
        raw_id_rs2_mem = detect_reg_dependency(rs2_addr_id,  rd_addr_mem, rd_we_mem);
        raw_id_rs2_wb  = detect_reg_dependency(rs2_addr_id,  rd_addr_wb,  rd_we_wb);
        raw_ex_rs1_mem = detect_reg_dependency(rs1_addr_ex,  rd_addr_mem, rd_we_mem);
        raw_ex_rs2_mem = detect_reg_dependency(rs2_addr_ex,  rd_addr_mem, rd_we_mem);
        raw_ex_rs1_wb  = detect_reg_dependency(rs1_addr_ex,  rd_addr_wb,  rd_we_wb);
        raw_ex_rs2_wb  = detect_reg_dependency(rs2_addr_ex,  rd_addr_wb,  rd_we_wb);
        raw_mem_rs2_wb = detect_reg_dependency(rs2_addr_mem, rd_addr_wb,  rd_we_wb);
    end
    
    always_comb begin : HAZARD_CLASSIFICATION // dependencies && instruction types to identify hazards
        hazard_load_use_rs1   = raw_id_rs1_ex && is_load_ex;        
        hazard_load_use_rs2   = raw_id_rs2_ex && is_load_ex && !is_store_id; // For rs2: NOT if Store in ID (Store uses rs2 as data, handled separately)
        hazard_store_data_ex  = is_store_id && is_load_ex  && raw_id_rs2_ex;
        hazard_store_data_mem = is_store_id && is_load_mem && raw_id_rs2_mem;
        hazard_store_data_wb  = is_store_id && raw_id_rs2_wb;  // as said above -> conservative implementation: stall for any WB producer       
        // Forwardable from MEM: Only NON-Load (Load data not in MEM yet, MEM issues Memory-Read, but Data will be available in WB)
        hazard_fwd_rs1_mem = raw_ex_rs1_mem && !is_load_mem;
        hazard_fwd_rs2_mem = raw_ex_rs2_mem && !is_load_mem;    
        // Forwardable from WB: Only if not already from MEM, since MEM-Data is newer
        hazard_fwd_rs1_wb = raw_ex_rs1_wb && !hazard_fwd_rs1_mem;
        hazard_fwd_rs2_wb = raw_ex_rs2_wb && !hazard_fwd_rs2_mem;    
        // Store data forwarding: Store in MEM needs data from WB
        hazard_fwd_store_wb = raw_mem_rs2_wb && is_store_mem;     // TODO: Test whether current WB->MEM forwarding is sufficient for STORE->LOAD sequences
                                                                  //       (e.g., for memcpy() running 1 cycle per word, BEN LEVY optimization-Ideas).
    end

    always_comb begin : STALL_GENERATION 
        stall_needed = hazard_load_use_rs1   || hazard_load_use_rs2  || hazard_store_data_ex ||
                       hazard_store_data_mem || hazard_store_data_wb;
    end

    assign stall       = stall_needed;
    assign flush_if_id = tk_brnch_ex;
    assign flush_id_ex = tk_brnch_ex || stall_needed;
        
    always_comb begin : OUTPUT_FORWARD_A // rs1 to EX
        if (hazard_fwd_rs1_mem)
            forward_a_sel = FWD_MEM;
        else if (hazard_fwd_rs1_wb)
            forward_a_sel = FWD_WB;
        else
            forward_a_sel = FWD_REGFILE;
    end
       
    always_comb begin : OUTPUT_FORWARD_B // rs2 to EX
        if (hazard_fwd_rs2_mem)
            forward_b_sel = FWD_MEM;
        else if (hazard_fwd_rs2_wb)
            forward_b_sel = FWD_WB;
        else
            forward_b_sel = FWD_REGFILE;
    end
     
    always_comb begin : OUTPUT_FORWARD_STORE // rs2 in MEM 
        if (hazard_fwd_store_wb)
            forward_store_sel = FWD_STORE_WB;
        else
            forward_store_sel = FWD_STORE_NORMAL;
    end

endmodule
