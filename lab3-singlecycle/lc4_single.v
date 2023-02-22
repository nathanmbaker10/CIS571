/* TODO: name and PennKeys of all group members here
 *
 * lc4_single.v
 * Implements a single-cycle data path
 *
 */

`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module mux2to1(S, A, B, Out); 
    input wire S, A, B; 
    output wire Out; 

    assign Out = S ? B : A;
endmodule

module mux2to1_16(S, A, B, Out);
    input wire S;
    input wire [15:0] A, B;
    output wire [15:0] Out;

    genvar i;  
    for (i = 0; i < 16; i = i+1) begin
        mux2to1 m(.S(S), .A(A[i]), .B(B[i]), .Out(Out[i]));
    end    
endmodule

module mux8to1
    (
        input  wire [2:0] sel,
        input  wire       a,
        input  wire       b,
        input  wire       c,
        input  wire       d,
        input  wire       e,
        input  wire       f,
        input  wire       g,
        input  wire       h,
        output wire       out
    );

    assign out = sel == 3'd0 ? a : 
        (sel == 3'd1 ? b :
        (sel == 3'd2 ? c :
        (sel == 3'd3 ? d :
        (sel == 3'd4 ? e :
        (sel == 3'd5 ? f :
        (sel == 3'd6 ? g : h))))));
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
   assign out[1] = in == 16'b0;
   assign out[2] = in[15] == 1'b1;
   assign out[0] = in == (~out[1] & ~out[2]);
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

   
   /* DO NOT MODIFY THIS CODE */
   // Always execute one instruction each cycle (test_stall will get used in your pipelined processor)
   assign test_stall = 2'b0; 

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
   assign test_cur_pc = pc;

   // +1
   wire [15:0] pc_plus_one;

   cla16 adder (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_plus_one));

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
      .insn(i_cur_insn), 
      .r1sel(r1sel), 
      .r1re(r1re), 
      .r2sel(r2sel), 
      .r2re(r2re), 
      .wsel(wsel), 
      .regfile_we(regfile_we), 
      .nzp_we(nzp_we), 
      .select_pc_plus_one(select_pc_plus_one), 
      .is_load(is_load), .is_store(is_store), 
      .is_branch(is_branch), 
      .is_control_insn(is_control_insn)
   );

   assign test_cur_insn = i_cur_insn;

   assign o_dmem_we = is_store;
   assign test_dmem_we = is_store;

   // NZP REG
   wire [2:0] nzp_reg_out;
   wire [2:0] nzp_reg_in; 

   Nbit_reg #(3, 3'b0) nzp_reg (.in(nzp_reg_in), .out(nzp_reg_out), .clk(clk), .we(nzp_we), .gwe(gwe), .rst(rst));

   // BRANCH LOGIC
   wire branch_logic_out;

   lc4_branch_logic branch_logic (.insn_11_9(i_cur_insn[11:9]), .is_branch(is_branch), .nzp_reg_out(nzp_reg_out), .branch_logic_out(branch_logic_out));

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
      .i_rd(wsel),
      .i_wdata(i_wdata),
      .i_rd_we(regfile_we)
   );

   assign o_dmem_towrite = o_rt_data;
   assign test_dmem_data = o_rt_data;

   // ALU
   wire [15:0] alu_output;

   lc4_alu alu (
      .i_insn(i_cur_insn),
      .i_pc(pc),
      .i_r1data(o_rs_data),
      .i_r2data(o_rt_data),
      .o_result(alu_output)
   );    

   mux2to1_16 next_pc_mux (.S(branch_logic_out), .A(pc_plus_one), .B(alu_output), .Out(next_pc));

   wire [15:0] alu_mux_output;
   mux2to1_16 alu_mux (.S(select_pc_plus_one), .A(alu_output), .B(pc_plus_one), .Out(alu_mux_output));

   assign o_dmem_addr = alu_mux_output;
   assign test_dmem_addr = alu_mux_output;

   wire [15:0] load_mux_output;
   mux2to1_16 load_mux (.S(is_load), .A(alu_mux_output), .B(i_cur_dmem_data), .Out(load_mux_output));

   assign test_dmem_data = i_cur_dmem_data;
   assign test_regfile_data = load_mux_output;
   assign i_wdata = load_mux_output;

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
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
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
