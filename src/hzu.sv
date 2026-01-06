`timescale 1ns / 1ps

module hzu (
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

    typedef enum logic [1:0] {
        FWD_REGFILE = 2'b00,
        FWD_MEM     = 2'b01,
        FWD_WB      = 2'b10
    } forward_src_t;
    
    typedef enum logic [1:0] {
        FWD_STORE_NORMAL = 2'b00,
        FWD_STORE_WB     = 2'b01
    } forward_store_t;

    // Match Detection
    logic match_rs1_id_ex, match_rs2_id_ex;
    logic match_rs1_id_mem, match_rs2_id_mem;
    logic match_rs1_id_wb, match_rs2_id_wb;
    logic match_rs1_ex_mem, match_rs2_ex_mem;
    logic match_rs1_ex_wb, match_rs2_ex_wb;
    logic match_rs2_mem_wb;
    
    // Hazard Classification
    logic load_use_hazard_rs1, load_use_hazard_rs2;
    logic load_store_data_hazard_ex;   // Store in ID, Load in EX
    logic load_store_data_hazard_mem;  // Store in ID, Load in MEM
    logic load_store_data_hazard_wb;   // Store in ID, Load in WB
    logic load_store_data_hazard;      // combined
    logic load_use_hazard;
    logic raw_hazard_ex_rs1_from_mem, raw_hazard_ex_rs1_from_wb;
    logic raw_hazard_ex_rs2_from_mem, raw_hazard_ex_rs2_from_wb;
    logic store_hazard;
    logic any_raw_hazard_ex, any_hazard_detected;

    // Match Detection Logic
    always_comb begin: MATCH_DETECTION
        // ID Stage Consumer vs Producers
        match_rs1_id_ex  = (rs1_addr_id  == rd_addr_ex)  && (rd_addr_ex  != 5'd0)  && rd_we_ex;
        match_rs2_id_ex  = (rs2_addr_id  == rd_addr_ex)  && (rd_addr_ex  != 5'd0)  && rd_we_ex;
        match_rs1_id_mem = (rs1_addr_id  == rd_addr_mem) && (rd_addr_mem != 5'd0)  && rd_we_mem;
        match_rs2_id_mem = (rs2_addr_id  == rd_addr_mem) && (rd_addr_mem != 5'd0)  && rd_we_mem;
        match_rs1_id_wb  = (rs1_addr_id  == rd_addr_wb)  && (rd_addr_wb  != 5'd0)  && rd_we_wb;
        match_rs2_id_wb  = (rs2_addr_id  == rd_addr_wb)  && (rd_addr_wb  != 5'd0)  && rd_we_wb;     
        // EX Stage Consumer vs Producers
        match_rs1_ex_mem = (rs1_addr_ex  == rd_addr_mem) && (rd_addr_mem != 5'd0) && rd_we_mem;
        match_rs2_ex_mem = (rs2_addr_ex  == rd_addr_mem) && (rd_addr_mem != 5'd0) && rd_we_mem;
        match_rs1_ex_wb  = (rs1_addr_ex  == rd_addr_wb)  && (rd_addr_wb  != 5'd0) && rd_we_wb;
        match_rs2_ex_wb  = (rs2_addr_ex  == rd_addr_wb)  && (rd_addr_wb  != 5'd0) && rd_we_wb;
        // MEM Stage Consumer (Store) vs Producers
        match_rs2_mem_wb = (rs2_addr_mem == rd_addr_wb) && (rd_addr_wb   != 5'd0) && rd_we_wb;
    end

    always_comb begin: HAZARD_CLASSIFICATION
        // Load-Use Hazards (for ALU-Operations)
        load_use_hazard_rs1 = match_rs1_id_ex && is_load_ex;
        load_use_hazard_rs2 = match_rs2_id_ex && is_load_ex && !is_store_id;      
        // Load-Store Data Hazard: Store in ID needs rs2-Daten from Load
        // Case 1: Load in EX : Stall necessaary 
        load_store_data_hazard_ex = is_store_id && is_load_ex && (rs2_addr_id == rd_addr_ex) && (rd_addr_ex != 5'd0);
        // Case 2: Load in MEM : Stall necessary
        load_store_data_hazard_mem = is_store_id && is_load_mem && (rs2_addr_id == rd_addr_mem) && (rd_addr_mem != 5'd0);
        // Case 3: Load in WB : Stall necessary! 
        load_store_data_hazard_wb = is_store_id && (rs2_addr_id == rd_addr_wb) && (rd_addr_wb != 5'd0) && rd_we_wb;
        // Combine all Load-Store Hazards 
        load_store_data_hazard = load_store_data_hazard_ex || load_store_data_hazard_mem || load_store_data_hazard_wb;
        // Combine all Stall generating - Hazards 
        load_use_hazard = load_use_hazard_rs1 || load_use_hazard_rs2 || load_store_data_hazard;
        // RAW Hazards from MEM (for Forwarding)
        raw_hazard_ex_rs1_from_mem = match_rs1_ex_mem && !is_load_mem;
        raw_hazard_ex_rs2_from_mem = match_rs2_ex_mem && !is_load_mem;
        // RAW Hazards from WB (only if not yet from MEM)
        raw_hazard_ex_rs1_from_wb = match_rs1_ex_wb && !raw_hazard_ex_rs1_from_mem;
        raw_hazard_ex_rs2_from_wb = match_rs2_ex_wb && !raw_hazard_ex_rs2_from_mem;
        // Store Hazard: Store in MEM neets Data from WB
        store_hazard = match_rs2_mem_wb && is_store_mem;
        // Combined Flags
        any_raw_hazard_ex   = raw_hazard_ex_rs1_from_mem || raw_hazard_ex_rs2_from_mem || raw_hazard_ex_rs1_from_wb  || raw_hazard_ex_rs2_from_wb;
        any_hazard_detected = load_use_hazard || any_raw_hazard_ex || store_hazard;
    end

    always_comb begin: GEN_STALL_FLUSH //Generate Stall & Flush Control Signals
        stall       = load_use_hazard;
        flush_if_id = tk_brnch_ex;
        flush_id_ex = tk_brnch_ex || load_use_hazard;
    end

    // Generate Control Signals for Forwarding
    always_comb begin: GEN_FORWARD_A 
        if (raw_hazard_ex_rs1_from_mem)
            forward_a_sel = FWD_MEM;
        else if (raw_hazard_ex_rs1_from_wb) 
            forward_a_sel = FWD_WB;
        else
            forward_a_sel = FWD_REGFILE;
    end
    
    always_comb begin: GEN_FORWARD_B
        if (raw_hazard_ex_rs2_from_mem)
            forward_b_sel = FWD_MEM;
        else if (raw_hazard_ex_rs2_from_wb) 
            forward_b_sel = FWD_WB;
        else
            forward_b_sel = FWD_REGFILE;
    end
    
    always_comb begin: GEN_FORWARD_STORE
        if (store_hazard)
            forward_store_sel = FWD_STORE_WB;
        else
            forward_store_sel = FWD_STORE_NORMAL;
    end

endmodule
