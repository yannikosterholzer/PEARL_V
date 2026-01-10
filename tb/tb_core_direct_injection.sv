`timescale 1ns / 1ps

module tb_core_direct_injection;

	/*
	
	This testbench validates the core by directly injecting instruction opcodes into the instruction memory bus, bypassing the need for a full software binary.
	
	*/

    logic clk, arstn;
    logic [31:0] imem_addr, imem_data;

    localparam NOP = 32'h00000013;

    string  test_name[32];
    logic     test_pass[32];
    logic [31:0] got_pc[32], want_pc[32];
    logic [31:0] got_val[32], want_val[32];
    int idx = 0;

    initial begin 
      clk = 0; 
      forever #5 clk = ~clk; 
    end

    core dut (
        .clk(clk), 
        .arstn(arstn),
        .imem_addr_o(imem_addr), 
        .imem_data_i(imem_data),
        .dmem_rdata_i(32'h0)
    );

    function automatic logic [31:0] reg_val(int r);
        return dut.u_id.IntRegFile.regs[r];
    endfunction

    task automatic reset();
        arstn = 0;
        imem_data = NOP;
        repeat(5) @(posedge clk);
        #1; arstn = 1;
        wait(imem_addr === 32'h0); // === -> 4 State comparison
        $display("[TB] reset done");
    endtask

    task automatic test_imm(string name, logic [31:0] instr, logic [31:0] exp, int rd);
        logic [31:0] pc_start;
        
        test_name[idx] = name;
        want_val[idx] = exp;
        
        pc_start = imem_addr;
        want_pc[idx] = pc_start;
        
        @(posedge clk); #1;
        imem_data = instr;
        @(posedge clk); #1;
        imem_data = NOP;
        
        repeat(5) @(posedge clk);
        
        got_val[idx] = reg_val(rd);
        got_pc[idx] = pc_start;
        test_pass[idx] = (got_val[idx] === exp);
        
        $display("[%s] %s", test_pass[idx] ? "OK" : "FAIL", name);
        idx++;
    endtask

    task automatic test_jal(string name, logic [31:0] instr, int rd);
        logic [31:0] start_pc, imm, exp_pc, exp_link;
        bit found_pc, found_reg;
        
        test_name[idx] = name;
        
        @(posedge clk); #1;
        start_pc = imem_addr;
        imem_data = instr;
        
        imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        exp_pc = start_pc + imm;
        exp_link = start_pc + 4;
        
        want_pc[idx] = exp_pc;
        want_val[idx] = exp_link;
        
        @(posedge clk); #1;
        imem_data = NOP;
        
        found_pc = 0; found_reg = 0;
        for (int i = 0; i < 20; i++) begin
            @(posedge clk); #2;
            if (!found_pc && imem_addr === exp_pc) begin
                found_pc = 1;
                got_pc[idx] = imem_addr;
            end
            if (!found_reg && reg_val(rd) === exp_link) begin
                found_reg = 1;
                got_val[idx] = exp_link;
            end
            if (found_pc && found_reg) break;
        end
        
        if (!found_pc)  got_pc[idx] = imem_addr;
        if (!found_reg) got_val[idx] = reg_val(rd);
        
        test_pass[idx] = found_pc && found_reg;
        $display("[%s] %s", test_pass[idx] ? "OK" : "FAIL", name);
        idx++;
    endtask

    task automatic test_jalr(string name, logic [31:0] instr, logic [31:0] exp_pc, int rd);
        logic [31:0] start_pc, exp_link;
        bit found_pc, found_reg;
        
        test_name[idx] = name;
        
        @(posedge clk); #1;
        start_pc = imem_addr;
        imem_data = instr;
        exp_link = start_pc + 4;
        
        want_pc[idx] = exp_pc;
        want_val[idx] = exp_link;
        
        @(posedge clk); #1;
        imem_data = NOP;
        
        found_pc = 0; found_reg = 0;
        for (int i = 0; i < 20; i++) begin
            @(posedge clk); #2;
            if (!found_pc && imem_addr === exp_pc) begin
                found_pc = 1;
                got_pc[idx] = imem_addr;
            end
            if (!found_reg && reg_val(rd) === exp_link) begin
                found_reg = 1;
                got_val[idx] = exp_link;
            end
            if (found_pc && found_reg) break;
        end
        
        if (!found_pc)  got_pc[idx] = imem_addr;
        if (!found_reg) got_val[idx] = reg_val(rd);
        
        test_pass[idx] = found_pc && found_reg;
        $display("[%s] %s", test_pass[idx] ? "OK" : "FAIL", name);
        idx++;
    endtask

    task automatic test_branch(string name, logic [31:0] instr, bit taken);
        logic [31:0] start_pc, imm, target;
        bit ok;
        
        test_name[idx] = name;
        want_val[idx] = 0;
        got_val[idx] = 0;
        
        @(posedge clk); #1;
        start_pc = imem_addr;
        imem_data = instr;
        
        imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        target = start_pc + imm;
        
        @(posedge clk); #1;
        imem_data = NOP;
        
        ok = 0;
        if (taken) begin
            want_pc[idx] = target;
            for (int i = 0; i < 20; i++) begin
                @(posedge clk); #2;
                if (imem_addr === target) begin ok = 1; break; end
            end
            got_pc[idx] = ok ? target : imem_addr;
        end else begin
            want_pc[idx] = start_pc + 4;
            ok = 1;
            repeat(5) begin
                @(posedge clk); #2;
                if (imem_addr === target && imm != 32'd4) ok = 0;
            end
            got_pc[idx] = ok ? (start_pc + 4) : target;
        end
        
        test_pass[idx] = ok;
        $display("[%s] %s", ok ? "OK" : "FAIL", name);
        idx++;
    endtask

    task automatic summary();
        int passed = 0;
        $display("------------------------------------------------------------------------");
        $display(" #  | RESULT | TEST                   | PC got/want         | VAL got/want");
        $display("------------------------------------------------------------------------");
        for (int i = 0; i < idx; i++) begin
            $display(" %2d | %s | %-22s | %h/%h | %h/%h",
                i+1, test_pass[i] ? "PASS  " : "FAIL  ", test_name[i],
                got_pc[i], want_pc[i], got_val[i], want_val[i]);
            if (test_pass[i]) passed++;
        end
        $display("------------------------------------------------------------------------");
        $display(" %0d/%0d passed\n", passed, idx);
    endtask

    initial begin
        $display("\n[TB] Core Direct Injection Testbench\n");
        reset();

        test_jal("jal x1, +32", 32'h020000ef, 1);
        repeat(5) @(posedge clk);
        
        test_jal("jal x2, -16", 32'hff1ff16f, 2);
        repeat(5) @(posedge clk);

        test_imm("addi x4, x0, 10", 32'h00a00213, 32'd10, 4);
        test_imm("addi x5, x0, 10", 32'h00a00293, 32'd10, 5);
        test_imm("addi x7, x0, 20", 32'h01400393, 32'd20, 7);

        test_branch("beq x4,x5 taken", 32'h00520863, 1);
        repeat(5) @(posedge clk);
        
        test_branch("bne x4,x5 not taken", 32'h02521063, 0);  // bne x4,x5, +32 
        repeat(5) @(posedge clk);
        
        test_branch("bne x4,x7 taken", 32'h00721863, 1);
        repeat(5) @(posedge clk);
        
        test_branch("blt x4,x7 taken", 32'h00724863, 1);
        repeat(5) @(posedge clk);
        
        test_branch("bge x7,x4 taken", 32'h00435863, 1);
        repeat(5) @(posedge clk);

        test_imm("addi x6, x0, 0x200", 32'h20000313, 32'h200, 6);
        test_jalr("jalr x1, x6, 8", 32'h008300e7, 32'h208, 1);
        repeat(5) @(posedge clk);

        test_imm("addi x10, x0, 42", 32'h02a00513, 32'd42, 10);
        test_imm("addi x11, x10, 1", 32'h00150593, 32'd43, 11);

        summary();
        $finish;
    end

endmodule
