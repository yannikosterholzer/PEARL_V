`timescale 1ns / 1ps

module hzu_tb;

	/*
	The HZU testbench checks stall & forward signals of the Hazard Detection and Forwarding Unit.
	*/

    logic [4:0] rs1_addr_id, rs2_addr_id;
    logic       is_store_id;
    logic [4:0] rd_addr_ex, rs1_addr_ex, rs2_addr_ex;
    logic       rd_we_ex, is_load_ex, tk_brnch_ex;
    logic [4:0] rd_addr_mem, rs2_addr_mem;
    logic       rd_we_mem, is_load_mem, is_store_mem;
    logic [4:0] rd_addr_wb;
    logic       rd_we_wb;
    
    logic [1:0] forward_a_sel, forward_b_sel, forward_store_sel;
    logic       stall, flush_if_id, flush_id_ex;

    localparam FWD_REG = 2'b00, FWD_MEM = 2'b01, FWD_WB = 2'b10;
    localparam FWD_ST_NORM = 2'b00, FWD_ST_WB = 2'b01;

    int pass_cnt = 0, error_cnt = 0;

        hzu dut (
        .rs1_addr_id    (rs1_addr_id),
        .rs2_addr_id    (rs2_addr_id),
        .is_store_id    (is_store_id),
        .rd_addr_ex     (rd_addr_ex),
        .rd_we_ex       (rd_we_ex),
        .is_load_ex     (is_load_ex),
        .rs1_addr_ex    (rs1_addr_ex),
        .rs2_addr_ex    (rs2_addr_ex),
        .tk_brnch_ex    (tk_brnch_ex),
        .rd_addr_mem    (rd_addr_mem),
        .rd_we_mem      (rd_we_mem),
        .is_load_mem    (is_load_mem),
        .rs2_addr_mem   (rs2_addr_mem),
        .is_store_mem   (is_store_mem),
        .rd_addr_wb     (rd_addr_wb),
        .rd_we_wb       (rd_we_wb),
        .forward_a_sel  (forward_a_sel),
        .forward_b_sel  (forward_b_sel),
        .forward_store_sel (forward_store_sel),
        .stall          (stall),
        .flush_if_id    (flush_if_id),
        .flush_id_ex    (flush_id_ex)
    );


    task clear_sigs();
    rs1_addr_id  = 0; 
		rs2_addr_id  = 0; 
		is_store_id  = 0;
    rd_addr_ex   = 0; 
		rd_we_ex     = 0; 
		is_load_ex   = 0;
    rs1_addr_ex  = 0; 
		rs2_addr_ex  = 0; 
		tk_brnch_ex  = 0;
    rd_addr_mem  = 0; 
		rd_we_mem    = 0; 
		is_load_mem  = 0;
    rs2_addr_mem = 0; 
		is_store_mem = 0;
    rd_addr_wb   = 0; 
		rd_we_wb     = 0;
    endtask

    task check(string name, logic cond);
        if (cond) begin
            pass_cnt++;
            $display("[OK]   %s", name);
        end else begin
            error_cnt++;
            $display("[FAIL] %s", name);
            $display("       stall=%b flush_if=%b flush_ex=%b fwd_a=%b fwd_b=%b fwd_st=%b",
                     stall, flush_if_id, flush_id_ex, forward_a_sel, forward_b_sel, forward_store_sel);
        end
    endtask

    initial begin
        $display("\n HZU Testbench \n");
        clear_sigs(); 
		#5;

    // load-use hazards
		/*
		When a load in EX writes to a register that the instruction in ID needs, we must stall one cycle since the load data isn't available until MEM completes. 
		We test this for rs1, rs2, and both store address and store data dependencies.
		*/
    clear_sigs(); 
		rd_addr_ex  = 10; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs1_addr_id = 10; 
		#1;
    check("load-use rs1", stall && flush_id_ex && !flush_if_id);

    clear_sigs(); 
		rd_addr_ex  = 10; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs2_addr_id = 10; 
		#1;
    check("load-use rs2 (alu)", stall);

    clear_sigs(); 
		rd_addr_ex = 10; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs2_addr_id = 10; 
		is_store_id = 1; 
		#1;
    check("load-use store data", stall);

    clear_sigs(); 
		rd_addr_ex  = 10; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs1_addr_id = 10; 
		is_store_id = 1; 
		#1;
    check("load-use store addr", stall);
		
		//Forwarding
		/*
		ALU results can be forwarded from MEM or WB to avoid stalls. 
		We verify both paths work for rs1 and rs2, and that MEM takes priority when both stages have the value, because the MEM-value is newer.
		*/
    
    // forwarding mem->ex
    clear_sigs(); 
		rd_addr_mem = 5; 
		rd_we_mem   = 1; 
		rs1_addr_ex = 5; 
		#1;
    check("fwd mem->ex rs1", forward_a_sel == FWD_MEM && !stall);

    clear_sigs(); 
		rd_addr_mem = 5; 
		rd_we_mem   = 1; 
		rs2_addr_ex = 5; 
		#1;
    check("fwd mem->ex rs2", forward_b_sel == FWD_MEM && !stall);

    // forwarding wb->ex
    clear_sigs(); 
		rd_addr_wb  = 5; 
		rd_we_wb    = 1; 
		rs1_addr_ex = 5; 
		#1;
    check("fwd wb->ex rs1", forward_a_sel == FWD_WB && !stall);

    clear_sigs(); 
		rd_addr_wb  = 5; 
		rd_we_wb    = 1; 
		rs2_addr_ex = 5; 
		#1;
    check("fwd wb->ex rs2", forward_b_sel == FWD_WB && !stall);

    // mem has priority over wb
    clear_sigs(); 
		rd_addr_mem = 5; 
		rd_we_mem   = 1; 
		rd_addr_wb  = 5; 
		rd_we_wb    = 1; 
		rs1_addr_ex = 5; 
		#1;
    check("fwd priority mem > wb", forward_a_sel == FWD_MEM);

    // no forwarding from load in mem 
		/*
		Unlike ALU results, load data in MEM isn't ready yet - it still needs to be fetched from memory -> therefore the HZU must not forward from a load in MEM.
		*/
    clear_sigs(); 
		rd_addr_mem = 5; 
		rd_we_mem   = 1; 
		is_load_mem = 1; 
		rs1_addr_ex = 5; 
		#1;
    check("no fwd from load in mem", forward_a_sel == FWD_REG);

    // store-data forwarding
		/*
		Stores need their data in MEM stage, so we can forward from WB. 
		We also test the conservative stalls for store-data hazards from earlier pipeline stages.
		*/
    clear_sigs(); 
		rd_addr_wb   = 15; 
		rd_we_wb     = 1; 
		rs2_addr_mem = 15; 
		is_store_mem = 1; 
		#1;
    check("store-data fwd wb->mem", forward_store_sel == FWD_ST_WB);

    // store-data hazards
    clear_sigs(); 
		rd_addr_mem = 10; 
		rd_we_mem   = 1; 
		is_load_mem = 1; 
		rs2_addr_id = 10; 
		is_store_id = 1; 
		#1;
    check("store-data from load in mem", stall);

    clear_sigs(); 
		rd_addr_wb  = 10; 
		rd_we_wb    = 1; 
		rs2_addr_id = 10; 
		is_store_id = 1; 
		#1;
    check("store-data from wb (conservative)", stall);

    // branch flush
		/*	
		When a branch is taken, IF and ID contain wrong instructions and must be flushed.
		*/
    clear_sigs(); 
		tk_brnch_ex = 1; 
		#1;
    check("branch taken flush", flush_if_id && flush_id_ex);

    // x0 never causes hazards
    clear_sigs(); 
		rd_addr_ex  = 0; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs1_addr_id = 0; 
		#1;
    check("x0 no stall", !stall);

    clear_sigs(); 
		rd_addr_mem = 0; 
		rd_we_mem   = 1; 
		rs1_addr_ex = 0; 
		#1;
    check("x0 no fwd", forward_a_sel == FWD_REG);

    // rd_we=0 means no write, no hazard
    clear_sigs(); 
		rd_addr_ex  = 10; 
		rd_we_ex    = 0; 
		is_load_ex  = 1; 
		rs1_addr_id = 10; 
		#1;
    check("rd_we=0 no stall", !stall);

    clear_sigs(); 
		rd_addr_mem = 10; 
		rd_we_mem   = 0; 
		rs1_addr_ex = 10; 
		#1;
    check("rd_we=0 no fwd", forward_a_sel == FWD_REG);

    // combined cases -> Multiple hazards can occur simultaneously.
    clear_sigs(); 
    rd_addr_mem = 5; 
		rd_we_mem   = 1;
    rd_addr_wb  = 6; 
		rd_we_wb    = 1;
    rs1_addr_ex = 5; 
		rs2_addr_ex = 6; 
		#1;
    check("rs1 from mem, rs2 from wb", forward_a_sel == FWD_MEM && forward_b_sel == FWD_WB);

    clear_sigs(); 
		rd_addr_mem = 9; 
		rd_we_mem   = 1; 
		rs1_addr_ex = 9; 
		rs2_addr_ex = 9; 
		#1;
    check("same reg rs1+rs2", forward_a_sel == FWD_MEM && forward_b_sel == FWD_MEM);

    clear_sigs(); 
		tk_brnch_ex = 1; 
		rd_addr_ex  = 10; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs1_addr_id = 10; 
		#1;
    check("branch + load-use", stall && flush_if_id && flush_id_ex);

    clear_sigs(); 
		rd_addr_ex  = 15; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs1_addr_id = 15; 
		rs2_addr_id = 15; 
		#1;
    check("load-use rs1+rs2", stall);

    // no dependencies
    clear_sigs();
    rd_addr_ex  = 1; 
		rd_we_ex    = 1;
    rd_addr_mem = 2; 
		rd_we_mem   = 1;
    rd_addr_wb  = 3; 
		rd_we_wb    = 1;
    rs1_addr_id = 10; 
		rs2_addr_id = 11;
    rs1_addr_ex = 12; 
		rs2_addr_ex = 13; 
		#1;
    check("no hazard", !stall && !flush_if_id && !flush_id_ex && forward_a_sel == FWD_REG && forward_b_sel == FWD_REG);

    clear_sigs(); 
		rd_addr_ex  = 1; 
		rd_we_ex    = 1; 
		is_load_ex  = 1; 
		rs1_addr_id = 2; 
		rs2_addr_id = 3; 
		#1;
    check("no false stall", !stall);

    $display("\n%0d/%0d passed\n", pass_cnt, pass_cnt + error_cnt);
    if (error_cnt == 0) 
        $display("all tests passed!\n");
    else $display("%0d failed\n", error_cnt);
        $finish;
    end

endmodule
