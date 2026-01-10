`timescale 1ns / 1ps

module tb_stld_injection;


  	/*
	  This testbench validates the core by directly injecting Store and Load instructionss into the instruction memory bus.	
	  */

    logic clk, arstn;
    logic [31:0] imem_addr, imem_data;
    logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic        dmem_we;

    localparam NOP = 32'h00000013;

    string  test_name[20];
    logic   test_pass[20];
    logic [31:0] got[20], want[20];
    int idx = 0;

    initial begin clk = 0; forever #5 clk = ~clk; end

    core dut (
        .clk(clk), 
        .arstn(arstn),
        .imem_addr_o(imem_addr), 
        .imem_data_i(imem_data),
        .dmem_addr_o(dmem_addr), 
        .dmem_wdata_o(dmem_wdata),
        .dmem_we_o(dmem_we), 
        .dmem_rdata_i(dmem_rdata)
    );

    function automatic logic [31:0] reg_val(int r);
        return dut.u_id.IntRegFile.regs[r];
    endfunction

    task automatic reset();
        arstn = 0;
        dmem_rdata = 0;
        imem_data = NOP;
        repeat(10) @(posedge clk);
        #1; arstn = 1;
        wait(imem_addr === 32'h0);
    endtask

    task automatic inject(logic [31:0] instr);
        @(posedge clk); #1;
        imem_data = instr;
        @(posedge clk); #1;
        imem_data = NOP;
    endtask

    task automatic setup(logic [31:0] instr);
        inject(instr);
        repeat(8) @(posedge clk);
    endtask

    task automatic test_store(string name, logic [31:0] instr, logic [31:0] exp_addr, logic [31:0] exp_data);
        logic ok;
        
        test_name[idx] = name;
        want[idx] = exp_data;
        ok = 0;  
        inject(instr);
        
        for (int i = 0; i < 15; i++) begin
            @(posedge clk);
            if (dmem_we) begin
                got[idx] = dmem_wdata;
                ok = (dmem_addr === exp_addr) && (dmem_wdata === exp_data);
                break;
            end
        end    
        test_pass[idx] = ok;
        $display("[%s] %s | addr=%h data=%h", ok ? "OK" : "FAIL", name, dmem_addr, dmem_wdata);
        idx++;
        repeat(2) @(posedge clk);
    endtask

    task automatic test_load(string name, logic [31:0] instr, logic [31:0] feed, logic [31:0] exp, int rd);
        test_name[idx] = name;
        want[idx] = exp;
        inject(instr);   
        fork
            begin
                wait(dmem_addr !== 32'h0);
                #1; dmem_rdata = feed;
                repeat(12) @(posedge clk);
                #1; dmem_rdata = 32'h0;
            end
        join_none   
        repeat(15) @(posedge clk);
        #2;   
        got[idx] = reg_val(rd);
        test_pass[idx] = (got[idx] === exp);
        $display("[%s] %s | x%0d=%h (want %h)", test_pass[idx] ? "OK" : "FAIL", name, rd, got[idx], exp);
        idx++;
        @(posedge clk); #1;
        imem_data = NOP;
    endtask

    task automatic summary();
        int passed = 0;
        $display("------------------------------------------------------------------------");
        $display(" #  | RESULT | TEST                    | GOT        | WANT              ");
        $display("------------------------------------------------------------------------");
        for (int i = 0; i < idx; i++) begin
            $display(" %2d | %s | %-23s | %h | %h",
                i+1, test_pass[i] ? "PASS  " : "FAIL  ", test_name[i], got[i], want[i]);
            if (test_pass[i]) passed++;
        end
        $display("------------------------------------------------------------------------");
        $display(" %0d/%0d passed\n", passed, idx);
    endtask

    initial begin
        $display("\n[TB] Load/Store Injection Testbench\n");
        reset();

        // word access
        setup(32'h10000513);  // addi x10, x0, 0x100
        setup(32'h02a00593);  // addi x11, x0, 42
        
        test_store("sw x11, 4(x10)", 32'h00b52223, 32'h104, 32'h2a);
        test_load("lw x12, 8(x10)", 32'h00852603, 32'hDEADBEEF, 32'hDEADBEEF, 12);

        // byte access
        setup(32'h20000513);  // addi x10, x0, 0x200
        setup(32'h08000593);  // addi x11, x0, 0x80
        
        test_store("sb x11, 0(x10)", 32'h00b50023, 32'h200, 32'h80);
        test_load("lbu x12, 0(x10)", 32'h00054603, 32'h80, 32'h80, 12);
        test_load("lb x13, 0(x10)", 32'h00050683, 32'h80, 32'hffffff80, 13);

        // halfword access
        setup(32'h30000513);  // addi x10, x0, 0x300
        setup(32'h000085b7);  // lui x11, 8
        setup(32'h00158593);  // addi x11, x11, 1 -> x11 = 0x8001
        
        test_store("sh x11, 0(x10)", 32'h00b51023, 32'h300, 32'h8001);
        test_load("lhu x14, 0(x10)", 32'h00055703, 32'h8001, 32'h8001, 14);
        test_load("lh x15, 0(x10)", 32'h00051783, 32'h8001, 32'hffff8001, 15);

        summary();
        $finish;
    end

endmodule
