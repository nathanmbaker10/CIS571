/* Matthew Pearl - pearlm, Nathan Baker - nater
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module Nbit_mux2to1 #(parameter n = 16)
    (
        input  wire         sel,
        input  wire [n-1:0] a,
        input  wire [n-1:0] b,
        output wire [n-1:0] out
    );

    genvar i;
    for (i = 0; i < n; i = i+1) begin
        mux2to1 m(
            .S(sel), 
            .A(a[i]), 
            .B(b[i]), 
            .Out(out[i])
        );
    end
endmodule

module mux4to1
    (
        input  wire [1:0] sel,
        input  wire       a,
        input  wire       b,
        input  wire       c,
        input  wire       d,
        output wire       out
    );

    assign out = sel == 2'd0 ? a : 
        (sel == 2'd1 ? b :
        (sel == 2'd2 ? c : d));
endmodule

module Nbit_mux4to1 #(parameter n = 16)
    (
        input  wire [  1:0] sel,
        input  wire [n-1:0] a,
        input  wire [n-1:0] b,
        input  wire [n-1:0] c,
        input  wire [n-1:0] d,
        output wire [n-1:0] out
    );

    genvar i;
    for (i = 0; i < n; i = i+1) begin
        mux4to1 m(
            .sel(sel), 
            .a(a[i]), 
            .b(b[i]), 
            .c(c[i]), 
            .d(d[i]), 
            .out(out[i])
        );
    end
endmodule

module lc4_branch_logic
   (input  wire [2:0] insn_11_9,
    input  wire       is_branch,
    input  wire [2:0] nzp_reg_out,
    output wire       branch_logic_out
   );

   wire mux_out;

   mux8to1 m (
      .sel(insn_11_9), 
      .a(1'b0), 
      .b(nzp_reg_out[0]),
      .c(nzp_reg_out[1]),
      .d(nzp_reg_out[0] | nzp_reg_out[1]),
      .e(nzp_reg_out[2]),
      .f(nzp_reg_out[0] | nzp_reg_out[2]),
      .g(nzp_reg_out[1] | nzp_reg_out[2]),
      .h(nzp_reg_out[0] | nzp_reg_out[1] | nzp_reg_out[2]),
      .out(mux_out)
   );

   assign branch_logic_out = mux_out & is_branch;
endmodule

module nzp
   (
      input  wire [15:0] in,
      output wire [2:0]  out
   );
   assign out[1] = (in == 16'b0 ? 1'b1 : 1'b0);
   assign out[2] = (in[15] == 1'b1 ? 1'b1 : 1'b0);
   assign out[0] = ~out[1] & ~out[2];
endmodule

module lc4_processor
   (input  wire        clk,                // Main clock
    input  wire        rst,                // Global reset
    input  wire        gwe,                // Global we for single-step clock
   
    output wire [15:0] o_cur_pc,           // Address to read from instruction memory
    input  wire [15:0] i_cur_insn,         // Output of instruction memory
    output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory; SET TO 0x0000 FOR NON LOAD/STORE INSNS
    input  wire [15:0] i_cur_dmem_data,    // Output of data memory
    output wire        o_dmem_we,          // Data memory write enable
    output wire [15:0] o_dmem_towrite,     // Value to write to data memory

    // Testbench signals are used by the testbench to verify the correctness of your datapath.
    // Many of these signals simply export internal processor state for verification (such as the PC).
    // Some signals are duplicate output signals for clarity of purpose.
    //
    // Don't forget to include these in your schematic!

    output wire [1:0]  test_stall,         // Testbench: is this a stall cycle? (don't compare the test values)
    output wire [15:0] test_cur_pc,        // Testbench: program counter
    output wire [15:0] test_cur_insn,      // Testbench: instruction bits
    output wire        test_regfile_we,    // Testbench: register file write enable
    output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
    output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
    output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
    output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
    output wire        test_dmem_we,       // Testbench: data memory write enable
    output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
    output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory
   
    input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
    output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?
    );

   // By default, assign LEDs to display switch inputs to avoid warnings about
   // disconnected ports. Feel free to use this for debugging input/output if
   // you desire.
   assign led_data = switch_data;

   assign test_stall = pc_out_w == 16'b0 ? 2'd2 : 2'b0; 

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/

   assign o_cur_pc = pc;

   // +4
   wire [15:0] pc_plus_four;
   wire [15:0] four;

   cla16 adder_plus_four (.a(pc), .b(16'd4), .cin(1'b0), .sum(pc_plus_four)); 

   // d_separator 
   wire [15:0] pc_out_d;
   wire [15:0] insn_out_d;
   Nbit_reg #(16) pc_reg_d (.in(pc_plus_four), .out(pc_out_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_d (.in(i_cur_insn), .out(insn_out_d), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // DECODER
   wire [ 2:0] r1sel;
   wire        r1re;              
   wire [ 2:0] r2sel;              
   wire        r2re;               
   wire [ 2:0] wsel;               
   wire        regfile_we;         
   wire        nzp_we;             
   wire        select_pc_plus_one; 
   wire        is_load;            
   wire        is_store;          
   wire        is_branch;         
   wire        is_control_insn;  

   lc4_decoder decode (
      .insn(insn_out_d), 
      .r1sel(r1sel), 
      .r1re(r1re), 
      .r2sel(r2sel), 
      .r2re(r2re), 
      .wsel(wsel), 
      .regfile_we(regfile_we), 
      .nzp_we(nzp_we), 
      .select_pc_plus_one(select_pc_plus_one), 
      .is_load(is_load), 
      .is_store(is_store), 
      .is_branch(is_branch), 
      .is_control_insn(is_control_insn)
   );

   // REGISTER FILE
   wire [15:0] o_rs_data;
   wire [15:0] o_rt_data;

   wire [15:0] i_wdata; 

   lc4_regfile #(16) regfile (
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs(r1sel),
      .o_rs_data(o_rs_data),
      .i_rt(r2sel),
      .o_rt_data(o_rt_data),
      .i_rd(control_w[6:4]),
      .i_wdata(i_wdata),
      .i_rd_we(control_w[3])
   );

   wire [15:0] reg_1_mux_out; 
   wire [15:0] reg_2_mux_out;
   Nbit_mux2to1 reg_1_mux (.sel(control_w[6:4] == r1sel & control_w[3] & r1re), .a(o_rs_data), .b(load_mux_output), .out(reg_1_mux_out));
   Nbit_mux2to1 reg_2_mux (.sel(control_w[6:4] == r2sel & control_w[3] & r2re1), .a(o_rt_data), .b(load_mux_output), .out(reg_2_mux_out));

   // x_separator
   wire [15:0] pc_out_x;
   wire [15:0] insn_out_x;
   wire [15:0] a_out_x;
   wire [15:0] b_out_x;
   wire [2:0]  r1sel_out_x;
   wire [2:0]  r2sel_out_x;
   wire [11:0]  control_x;
   Nbit_reg #(16) pc_reg_x (.in(pc_out_d), .out(pc_out_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_x (.in(insn_out_d), .out(insn_out_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) a_reg_x (.in(reg_1_mux_out), .out(a_out_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) b_reg_x (.in(reg_2_mux_out), .out(b_out_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r1sel_reg_x (.in(r1sel), .out(r1sel_out_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r2sel_reg_x (.in(r2sel), .out(r2sel_out_x), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(12)  control_reg_x (
      .in({r1re, r2re, wsel, regfile_we, nzp_we, is_load, is_store, select_pc_plus_one, is_branch, is_control_insn}),
      .out(control_x),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );

   // BRANCH LOGIC
   wire branch_logic_out;

   lc4_branch_logic branch_logic (.insn_11_9(insn_out_x[11:9]), .is_branch(control_x[1]), .nzp_reg_out(nzp_reg_out), .branch_logic_out(branch_logic_out));

   // ALU
   wire [15:0] alu_output;

   wire [15:0] alu_in_a;
   Nbit_mux4to1 alu_in_a_mux (
      .sel(control_x[11] ? (r1sel_out_x == control_m[6:4] & control_m[3] ? 2'b0 : (r1sel_out_x == control_w[6:4] & control_w[3] ? 2'b1 : 2'd2)): 2'd2), 
      .a(o_out_m), .b(load_mux_output), .c(a_out_x), .d(a_out_x), .out(alu_in_a)
   );

   wire [15:0] alu_in_b;
   Nbit_mux4to1 alu_in_b_mux (
      .sel(control_x[10] ? (r2sel_out_x == control_m[6:4] & control_m[3] ? 2'b0 : (r2sel_out_x == control_w[6:4] & control_w[3] ? 2'b1 : 2'd2)): 2'd2), 
      .a(o_out_m), .b(load_mux_output), .c(b_out_x), .d(b_out_x), .out(alu_in_b)
   );

   lc4_alu alu (
      .i_insn(insn_out_x),
      .i_pc(pc_out_x),
      .i_r1data(alu_in_a),
      .i_r2data(alu_in_b),
      .o_result(alu_output)
   );   

   // +1
   wire [15:0] pc_plus_one;

   cla16 adder_plus_one (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_plus_one)); 

   mux2to1_16 next_pc_mux (.S(branch_logic_out | control_x[0]), .A(pc_plus_one), .B(alu_output), .Out(next_pc));

   wire [15:0] alu_mux_output;
   mux2to1_16 alu_mux (.S(control_x[2]), .A(alu_output), .B(pc_plus_one), .Out(alu_mux_output));

   wire [15:0] o_dmem_addr_in; 
   assign o_dmem_addr_in = (control_x[4] | control_x[3]) ? alu_output : 16'b0;

   // m_separator
   wire [15:0] pc_out_m;
   wire [15:0] insn_out_m;
   wire [15:0] o_out_m;
   wire [15:0] b_out_m;
   wire [6:0]  control_m;
   Nbit_reg #(16) pc_reg_m (.in(pc_out_x), .out(pc_out_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_m (.in(insn_out_x), .out(insn_out_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_reg_m (.in(alu_mux_output), .out(o_out_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) b_reg_m (.in(alu_in_b), .out(b_out_m), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_dmem_addr_reg_m (.in(o_dmem_addr_in), .out(o_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(7) control_reg_m (
      .in(control_x[9:3]),
      .out(control_m),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );

   assign o_dmem_we = control_m[0];

   wire [15:0] dmem_data_mux_out;
   Nbit_mux2to1 dmem_data_mux(.sel(control_w[1] & control_m[0] & control_m[6:4] == control_w[6:4]), 
      .a(load_mux_output), 
      .b(b_out_m), 
      .out(dmem_data_mux_out)
   );

   assign o_dmem_towrite = control_m[0] ? dmem_data_mux_out : 16'b0;

   // w_separator
   wire [15:0] pc_out_w;
   wire [15:0] o_out_w;
   wire [15:0] d_out_w;
   wire [15:0] test_dmem_towrite_w;
   wire [6:0]  control_w;
   Nbit_reg #(16) pc_reg_w (.in(pc_out_m), .out(pc_out_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_w (.in(insn_out_m), .out(test_cur_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_reg_w (.in(o_out_m), .out(o_out_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) d_reg_w (.in(i_cur_dmem_data), .out(d_out_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) test_dmem_towrite_reg_w (.in(o_dmem_towrite), .out(test_dmem_towrite_w), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) test_dmem_addr_reg_w (.in(o_dmem_addr), .out(test_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(7) control_reg_w (
      .in(control_m),
      .out(control_w),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );

   assign test_dmem_we = control_w[0];
   assign test_nzp_we = control_w[2];
   assign test_regfile_we = control_w[3];
   assign test_regfile_wsel = control_w[6:4];

   assign test_dmem_data = control_w[1] ? d_out_w : test_dmem_towrite_w;

   cla16 adder_minus_four (.a(pc_out_w), .b(-16'd4), .cin(1'b0), .sum(test_cur_pc)); 

   wire [15:0] load_mux_output;
   mux2to1_16 load_mux (.S(control_w[0]), .A(o_out_w), .B(d_out_w), .Out(load_mux_output));

   assign test_regfile_data = load_mux_output;
   assign i_wdata = load_mux_output;

   // NZP REG
   wire [2:0] nzp_reg_out;
   wire [2:0] nzp_reg_in; 

   Nbit_reg #(3, 3'b0) nzp_reg (.in(nzp_reg_in), .out(nzp_reg_out), .clk(clk), .we(control_w[2]), .gwe(gwe), .rst(rst));

   // N/Z/P
   nzp nzp (.in(load_mux_output), .out(nzp_reg_in));
   assign test_nzp_new_bits = nzp_reg_in;

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    *
    * You do not need to resynthesize and re-implement if this is all you change;
    * just restart the simulation.
    * 
    * To disable the entire block add the statement
    * `define NDEBUG
    * to the top of your file.  We also define this symbol
    * when we run the grading scripts.
    */
`ifndef NDEBUG
   always @(posedge gwe) begin
      // $display("pc: %h, branch logic: %b, pc+1: %h, alu output: %h, next pc: %h", pc, branch_logic_out, pc_plus_one, alu_output, next_pc);
     //$display("test_cur_pc %h r1_sel %h r2_sel %h o_rs_data %h o_rt_data %h | alu_in_a %h alu_in_b %h r1sel_out_x %h r2sel_out_x %h control_x_6_4 %h | o_out_m %h control_m_6_4 %h | load_mux_output %h control_w_6_4 %h regfile_we %h", test_cur_pc, r1sel, r2sel, o_rs_data, o_rt_data, alu_in_a, alu_in_b, r1sel_out_x, r2sel_out_x, control_x[6:4], o_out_m, control_m[6:4], load_mux_output, control_w[6:4], regfile_we);
      //$display("load_mux_output %h", load_mux_output);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nano-seconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecial.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      // $display();
   end
`endif
endmodule
