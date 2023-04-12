`timescale 1ns / 1ps

// Prevent implicit wire declaration
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

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   assign led_data = switch_data;

   // pc wires attached to the PC register's ports
   wire [15:0]   pc;      // Current program counter (read out from pc_reg)
   wire [15:0]   next_pc; // Next program counter (you compute this and feed it into next_pc)

   // Program counter register, starts at 8200h at bootup
   Nbit_reg #(16, 16'h8200) pc_reg (.in(stall_A ? pc : (stall_B | hazard_B ? pc_B : stall_out_x_B != 2'd0 ? next_pc_B : next_pc_A)), .out(pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   /* END DO NOT MODIFY THIS CODE */


   /*******************************
    * TODO: INSERT YOUR CODE HERE *
    *******************************/

   assign o_cur_pc = pc;

   wire [15:0] pc_B;
   cla16 adder_pc_B_plus_one (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_B));

   // d_separator 
   wire [15:0] pc_out_d_A;
   wire [15:0] insn_out_d_A;
   wire [1:0]  stall_out_d_A;
   Nbit_reg #(16) pc_reg_d_A (.in(stall_A ? pc_out_d_A : (stall_B | hazard_B ? pc_out_d_B : pc)), .out(pc_out_d_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_d_A (.in(misprediction_A ? 16'b0 : (stall_A ? insn_out_d_A : (stall_B | hazard_B ? insn_out_d_B : i_cur_insn_A))), .out(insn_out_d_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2)  stall_reg_d_A (.in(misprediction_A | misprediction_B ? 2'd2 : 2'd0), .out(stall_out_d_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // DECODER
   wire [ 2:0] r1sel_A;
   wire        r1re_A;              
   wire [ 2:0] r2sel_A;              
   wire        r2re_A;               
   wire [ 2:0] wsel_A;               
   wire        regfile_we_A;         
   wire        nzp_we_A;             
   wire        select_pc_plus_one_A; 
   wire        is_load_A;            
   wire        is_store_A;          
   wire        is_branch_A;         
   wire        is_control_insn_A;  

   lc4_decoder decode_A (
      .insn(insn_out_d_A), 
      .r1sel(r1sel_A), 
      .r1re(r1re_A), 
      .r2sel(r2sel_A), 
      .r2re(r2re_A), 
      .wsel(wsel_A), 
      .regfile_we(regfile_we_A), 
      .nzp_we(nzp_we_A), 
      .select_pc_plus_one(select_pc_plus_on_A), 
      .is_load(is_load_A), 
      .is_store(is_store_A), 
      .is_branch(is_branch_A), 
      .is_control_insn(is_control_insn_A)
   );

   wire stall_A;
   assign stall_A = (control_x_A[4] & (r1sel_A == control_x_A[9:7] & r1re_A & ~(r1sel_A == control_x_B[9:7] & control_x_B[6])| ((r2sel_A == control_x_A[9:7]) & r2re_A & ~(r2sel_A == control_x_B[9:7] & control_x_B[6]) & ~is_store_A) | is_branch_A)) 
      | (control_x_B[4] & (r1sel_A == control_x_B[9:7] & r1re_A | ((r2sel_A == control_x_B[9:7]) & r2re_A & ~is_store_A) | is_branch_A));

   wire [15:0] pc_out_d_B;
   wire [15:0] insn_out_d_B;
   wire [1:0]  stall_out_d_B;
   Nbit_reg #(16) pc_reg_d_B (.in(stall_A ? pc_out_d_B : pc_B), .out(pc_out_d_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_d_B (.in(misprediction_B ? 16'b0 : (stall_A ? insn_out_d_B : i_cur_insn_B)), .out(insn_out_d_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2'd2)  stall_reg_d_B (.in(misprediction_B ? 2'd2 : 2'd0), .out(stall_out_d_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // DECODER
   wire [ 2:0] r1sel_B;
   wire        r1re_B;              
   wire [ 2:0] r2sel_B;              
   wire        r2re_B;               
   wire [ 2:0] wsel_B;               
   wire        regfile_we_B;         
   wire        nzp_we_B;             
   wire        select_pc_plus_one_B; 
   wire        is_load_B;            
   wire        is_store_B;          
   wire        is_branch_B;         
   wire        is_control_insn_B;  

   lc4_decoder decode_B (
      .insn(insn_out_d_B), 
      .r1sel(r1sel_B), 
      .r1re(r1re_B), 
      .r2sel(r2sel_B), 
      .r2re(r2re_B), 
      .wsel(wsel_B), 
      .regfile_we(regfile_we_B), 
      .nzp_we(nzp_we_B), 
      .select_pc_plus_one(select_pc_plus_on_B), 
      .is_load(is_load_B), 
      .is_store(is_store_B), 
      .is_branch(is_branch_B), 
      .is_control_insn(is_control_insn_B)
   );

   wire hazard_B;
   assign hazard_B = ~stall_A & (((is_store_A | is_load_A) & (is_store_B | is_load_B)) | (r1sel_B == wsel_A & r1re_B & regfile_we_A) | (r2sel_B == wsel_A & r2re_B & regfile_we_A));
   wire stall_B;
   assign stall_B = ~stall_A & ~hazard_B & ((control_x_A[4] & (r1sel_B == control_x_A[9:7] & r1re_B & ~(r1sel_B == control_x_B[9:7] & control_x_B[6])| ((r2sel_B == control_x_A[9:7]) & r2re_B & ~is_store_B) | is_branch_B)) 
      | (control_x_B[4] & (r1sel_B == control_x_B[9:7] & r1re_B | ((r2sel_B == control_x_B[9:7]) & r2re_B & ~is_store_B) | is_branch_B)));

   // REGISTER FILE
   wire [15:0] o_rs_data_A;
   wire [15:0] o_rt_data_A;

   wire [15:0] o_rs_data_B;
   wire [15:0] o_rt_data_B;

   wire [15:0] i_wdata_A;
   wire [15:0] i_wdata_B;

   lc4_regfile_ss #(16) regfile (
      .clk(clk),
      .gwe(gwe),
      .rst(rst),
      .i_rs_A(r1sel_A),
      .o_rs_data_A(o_rs_data_A),
      .i_rt_A(r2sel_A),
      .o_rt_data_A(o_rt_data_A),
      .i_rd_A(control_w_A[6:4]),
      .i_wdata_A(i_wdata_A),
      .i_rd_we_A(control_w_A[3]),
      .i_rs_B(r1sel_B),
      .o_rs_data_B(o_rs_data_B),
      .i_rt_B(r2sel_B),
      .o_rt_data_B(o_rt_data_B),
      .i_rd_B(control_w_B[6:4]),
      .i_wdata_B(i_wdata_B),
      .i_rd_we_B(control_w_B[3])
   );

   // x_separator
   wire [15:0] pc_out_x_A;
   wire [15:0] insn_out_x_A;
   wire [15:0] a_out_x_A;
   wire [15:0] b_out_x_A;
   wire [2:0]  r1sel_out_x_A;
   wire [2:0]  r2sel_out_x_A;
   wire [9:0]  control_x_A;
   wire [1:0]  stall_out_x_A;
   Nbit_reg #(16) pc_reg_x_A (.in(pc_out_d_A), .out(pc_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_x_A (.in((misprediction_A | stall_A | misprediction_B) ? 16'b0 : insn_out_d_A), .out(insn_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) a_reg_x_A (.in(o_rs_data_A), .out(a_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) b_reg_x_A (.in(o_rt_data_A), .out(b_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r1sel_reg_x_A (.in(r1sel_A), .out(r1sel_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r2sel_reg_x_A (.in(r2sel_A), .out(r2sel_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(10)  control_reg_x_A (
      .in((misprediction_A | stall_A | misprediction_B) ? 12'b0 : ({wsel_A, regfile_we_A, nzp_we_A, is_load_A, is_store_A, select_pc_plus_one_A, is_branch_A, is_control_insn_A})),
      .out(control_x_A),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );
   Nbit_reg #(2, 2'd2)  stall_reg_x_A (.in(misprediction_A | misprediction_B ? 2'd2 : (stall_A ? 2'd3 : stall_out_d_A)), .out(stall_out_x_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // BRANCH LOGIC ***
   wire branch_logic_out_A;

   lc4_branch_logic branch_logic_A (.insn_11_9(insn_out_x_A[11:9]), .is_branch(control_x_A[1]), .nzp_reg_out(choose_nzp_reg_out_A ? nzp_reg_out_A : nzp_reg_out_B), .branch_logic_out(branch_logic_out_A));

   wire misprediction_A = branch_logic_out_A | control_x_A[0];

   // ALU
   wire [15:0] alu_output_A;

   wire [15:0] alu_in_a_A;
   Nbit_mux8to1 alu_in_a_mux_A (
      .sel(r1sel_out_x_A == control_m_B[6:4] & control_m_B[3] ? 2'd0 : (r1sel_out_x_A == control_m_A[6:4] & control_m_A[3] ? 2'd1 : (r1sel_out_x_A == control_w_B[6:4] & control_w_B[3] ? 2'd2 : r1sel_out_x_A == control_w_A[6:4] & control_w_A[3] ? 2'd3) : 2d'4)), 
      .a(o_out_m_B), 
      .b(o_out_m_A), 
      .c(load_mux_output_B), 
      .d(load_mux_output_A), 
      .e(a_out_x_A), 
      .f(a_out_x_A), 
      .g(a_out_x_A), 
      .h(a_out_x_A), 
      .out(alu_in_a_A)
   );

   wire [15:0] alu_in_b_A;
   Nbit_mux8to1 alu_in_b_mux_A (
      .sel(r2sel_out_x_A == control_m_B[6:4] & control_m_B[3] ? 2'd0 : (r2sel_out_x_A == control_m_A[6:4] & control_m_A[3] ? 2'd1 : (r2sel_out_x_A == control_w_B[6:4] & control_w_B[3] ? 2'd2 : r2sel_out_x_A == control_w_A[6:4] & control_w_A[3] ? 2'd3) : 2d'4)), 
      a(o_out_m_B), 
      .b(o_out_m_A), 
      .c(load_mux_output_B), 
      .d(load_mux_output_A), 
      .e(b_out_x_A),
      .f(b_out_x_A),
      .g(b_out_x_A),
      .h(b_out_x_A),
      .out(alu_in_b_A)
   );

   lc4_alu alu_A (
      .i_insn(insn_out_x_A),
      .i_pc(pc_out_x_A),
      .i_r1data(alu_in_a_A),
      .i_r2data(alu_in_b_A),
      .o_result(alu_output_A)
   );   

   // NZP REG
   wire [2:0] nzp_reg_out_A;
   wire [2:0] nzp_reg_in_A; 

   Nbit_reg #(3, 3'b0) nzp_reg_A (.in(nzp_reg_in_A), .out(nzp_reg_out_A), .clk(clk), .we(control_x_A[5] | control_m_A[1]), .gwe(gwe), .rst(rst));

   // N/Z/P
   wire choose_B_NZP;
   assign choose_B_NZP = control_x_B[5] | (~control_x_A[5] & control_m_B[1]);

   wire choose_A_NZP;
   assign choose_A_NZP = (control_x_A[5] & ~control_x_B[5]) | (control_m_A[1] & ~control_m_B[1] & ~control_x_A[5] & ~control_x_B[5]); 

   wire choose_nzp_reg_out_A;

   NBit_red #(1) choose_nzp_reg_A (.in(choose_B_NZP ? 1'b0 : (choose_A_NZP ? 1'b1 : choose_nzp_reg_out_A)), .out(choose_nzp_reg_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   nzp nzp_x_A (.in(control_x_A[5] ? alu_mux_output_A : i_cur_dmem_data), .out(nzp_reg_in_A));

   // +1
   wire [15:0] pc_x_plus_one_A;
   wire [15:0] pc_f_plus_one_A;

   cla16 adder_pc_x_plus_one_A (.a(pc_out_x_A), .b(16'b1), .cin(1'b0), .sum(pc_x_plus_one_A)); 
   cla16 adder_pc_f_plus_one_B (.a(pc), .b(16'b1), .cin(1'b0), .sum(pc_f_plus_one_A)); // CHECK PC

   wire [15:0] next_pc_A;
   mux2to1_16 next_pc_mux_A (.S(branch_logic_out_A | control_x_A[0]), .A(pc_f_plus_one_A), .B(alu_output_A), .Out(next_pc_A));

   wire [15:0] alu_mux_output_A;
   mux2to1_16 alu_mux_A (.S(control_x_A[2]), .A(alu_output_A), .B(pc_x_plus_one_A), .Out(alu_mux_output_A));

   wire [15:0] o_dmem_addr_in_A;
   assign o_dmem_addr_in_A = (control_x_A[4] | control_x_A[3]) ? alu_output_A : 16'b0;

   wire [15:0] pc_out_x_B;
   wire [15:0] insn_out_x_B;
   wire [15:0] a_out_x_B;
   wire [15:0] b_out_x_B;
   wire [2:0]  r1sel_out_x_B;
   wire [2:0]  r2sel_out_x_B;
   wire [9:0]  control_x_B;
   wire [1:0]  stall_out_x_B;
   Nbit_reg #(16) pc_reg_x_B (.in(pc_out_d_B), .out(pc_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_x_B (.in((misprediction_A | stall_A | misprediction_B | stall_B) ? 16'b0 : insn_out_d_B), .out(insn_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) a_reg_x_B (.in(o_rs_data_B), .out(a_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) b_reg_x_B (.in(o_rt_data_B), .out(b_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r1sel_reg_x_B (.in(r1sel_B), .out(r1sel_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r2sel_reg_x_B (.in(r2sel_B), .out(r2sel_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(10)  control_reg_x_B (
      .in((misprediction_A | stall_A | misprediction_B | stall_B) ? 12'b0 : ({wsel_B, regfile_we_B, nzp_we_B, is_load_B, is_store_B, select_pc_plus_one_B, is_branch_B, is_control_insn_B})),
      .out(control_x_B),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );
   Nbit_reg #(2, 2'd2)  stall_reg_x_B (.in(misprediction_A | misprediction_B ? 2'd2 : (stall_A | hazard_B ? 2'd1 : (stall_B ? 2'd3 : stall_out_d_B))), .out(stall_out_x_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   // BRANCH LOGIC ***
   wire branch_logic_out_B;

   lc4_branch_logic branch_logic_B (.insn_11_9(insn_out_x_B[11:9]), .is_branch(control_x_B[1]), .nzp_reg_out(choose_nzp_reg_out_A ? nzp_reg_out_A : nzp_reg_out_B), .branch_logic_out(branch_logic_out_B));

   wire misprediction_B = branch_logic_out_B | control_x_B[0];

   // ALU
   wire [15:0] alu_output_B;

   wire [15:0] alu_in_a_B;
   Nbit_mux8to1 alu_in_a_mux_B (
      .sel(r1sel_out_x_B == control_m_B[6:4] & control_m_B[3] ? 2'd0 : (r1sel_out_x_B == control_m_A[6:4] & control_m_A[3] ? 2'd1 : (r1sel_out_x_B == control_w_B[6:4] & control_w_B[3] ? 2'd2 : r1sel_out_x_B == control_w_A[6:4] & control_w_A[3] ? 2'd3) : 2d'4)), 
      .a(o_out_m_B), 
      .b(o_out_m_A), 
      .c(load_mux_output_B), 
      .d(load_mux_output_A), 
      .e(a_out_x_B), 
      .f(a_out_x_B), 
      .g(a_out_x_B), 
      .h(a_out_x_B), 
      .out(alu_in_a_B)
   );

   wire [15:0] alu_in_b_B;
   Nbit_mux8to1 alu_in_b_mux_B (
      .sel(r2sel_out_x_B == control_m_B[6:4] & control_m_B[3] ? 2'd0 : (r2sel_out_x_B == control_m_A[6:4] & control_m_A[3] ? 2'd1 : (r2sel_out_x_B == control_w_B[6:4] & control_w_B[3] ? 2'd2 : r2sel_out_x_B == control_w_A[6:4] & control_w_A[3] ? 2'd3) : 2d'4)), 
      a(o_out_m_B), 
      .b(o_out_m_A), 
      .c(load_mux_output_B), 
      .d(load_mux_output_A), 
      .e(b_out_x_B),
      .f(b_out_x_B),
      .g(b_out_x_B),
      .h(b_out_x_B),
      .out(alu_in_b_B)
   );

   lc4_alu alu_B (
      .i_insn(insn_out_x_B),
      .i_pc(pc_out_x_B),
      .i_r1data(alu_in_a_B),
      .i_r2data(alu_in_b_B),
      .o_result(alu_output_B)
   );   

   // NZP REG
   wire [2:0] nzp_reg_out_B;
   wire [2:0] nzp_reg_in_B; 

   Nbit_reg #(3, 3'b0) nzp_reg_B (.in(nzp_reg_in_B), .out(nzp_reg_out_B), .clk(clk), .we(control_x_B[5] | control_m_B[1]), .gwe(gwe), .rst(rst));

   // N/Z/P
   nzp nzp_x_B (.in(control_x_B[5] ? alu_mux_output_B : i_cur_dmem_data), .out(nzp_reg_in_B));

   // +1
   wire [15:0] pc_x_plus_one_B;
   wire [15:0] pc_f_plus_one_B;
   
   cla16 adder_pc_x_plus_one_B (.a(pc_out_x_B), .b(16'b1), .cin(1'b0), .sum(pc_x_plus_one_B)); 
   cla16 adder_pc_f_plus_one_B (.a(pc_B), .b(16'b1), .cin(1'b0), .sum(pc_f_plus_one_B)); // CHECK PC

   wire [15:0] next_pc_B;
   mux2to1_16 next_pc_mux_B (.S(branch_logic_out_B | control_x_B[0]), .A(pc_f_plus_one_B), .B(alu_output_B), .Out(next_pc_B));

   wire [15:0] alu_mux_output_B;
   mux2to1_16 alu_mux_B (.S(control_x_B[2]), .A(alu_output_B), .B(pc_x_plus_one_B), .Out(alu_mux_output_B));

   wire [15:0] o_dmem_addr_in_B;
   assign o_dmem_addr_in_B = (control_x_B[4] | control_x_B[3]) ? alu_output_B : 16'b0;

   // m_separator
   wire [15:0] pc_out_m_A;
   wire [15:0] insn_out_m_A;
   wire [15:0] o_out_m_A;
   wire [15:0] b_out_m_A;
   wire [6:0]  control_m_A
   wire [1:0]  stall_out_m_A;
   wire [2:0]  r2sel_out_m_A;
   wire [15:0] o_dmem_addr_A;
   Nbit_reg #(16) pc_reg_m_A (.in(pc_out_x_A), .out(pc_out_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_m_A (.in(insn_out_x_A), .out(insn_out_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_reg_m_A (.in(alu_mux_output_A), .out(o_out_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) b_reg_m_A (.in(alu_in_b_A), .out(b_out_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_dmem_addr_reg_m_A (.in(o_dmem_addr_in_A), .out(o_dmem_addr_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r2sel_reg_m_A (.in(r2sel_out_x_A), .out(r2sel_out_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(7) control_reg_m_A (
      .in(control_x_A[9:3]),
      .out(control_m_A),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );
   Nbit_reg #(2, 2'd2)  stall_reg_m_A (.in(stall_out_x_A), .out(stall_out_m_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   wire [15:0] dmem_data_mux_out_A;
   Nbit_mux4to1 dmem_data_mux_A (.sel(control_m_A[0] ? (control_w_B[1] & control_w_B[6:4] == control_m_A[6:4] ? 2'd0 : (control_w_A[1] & control_w_A[6:4] == control_m_A[6:4] ? 2'd1 : 2'd2)) : 2'd2), 
      .a(load_mux_output_B), 
      .b(load_mux_output_A), 
      .c(b_out_m_A),
      .d(b_out_m_A),
      .out(dmem_data_mux_out_A)
   );

   wire [15:0] pc_out_m_B;
   wire [15:0] insn_out_m_B;
   wire [15:0] o_out_m_B;
   wire [15:0] b_out_m_B;
   wire [6:0]  control_m_B;
   wire [1:0]  stall_out_m_B;
   wire [2:0]  r2sel_out_m_B;
   wire [15:0] o_dmem_addr_B;
   Nbit_reg #(16) pc_reg_m_B (.in(pc_out_x_B), .out(pc_out_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_m_B (.in(misprediction_A ? 16'b0 : insn_out_x_B), .out(insn_out_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_reg_m_B (.in(alu_mux_output_B), .out(o_out_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) b_reg_m_B (.in(alu_in_b_B), .out(b_out_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_dmem_addr_reg_m_B (.in(o_dmem_addr_in_B), .out(o_dmem_addr_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(3)  r2sel_reg_m_B (.in(r2sel_out_x_B), .out(r2sel_out_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(7) control_reg_m_B (
      .in(misprediction_A ? 16'b0 : control_x_B[9:3]),
      .out(control_m_B),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );
   Nbit_reg #(2, 2'd2)  stall_reg_m_B (.in(misprediction_A ? 2'd2 : stall_out_x_B), .out(stall_out_m_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   assign o_dmem_we = control_m_A[0] | control_m_B[0];
   assign o_dmem_addr = control_m_A[0] | control_m_A[1] ? o_dmem_addr_A : (control_m_B[0] | control_m_B[1] ? o_dmem_addr_B : 16'b0);

   wire [15:0] dmem_data_mux_out_B;
   Nbit_mux4to1 dmem_data_mux_B (.sel(control_m_B[0] ? (control_m_A[6:4] == control_m_B[6:4] & control_m_A[3] ? 2'd0 : (control_w_B[1] & control_w_B[6:4] == control_m_A[6:4] ? 2'd1 : (control_w_A[1] & control_w_A[6:4] == control_m_A[6:4] ? 2'd2 : 2'd3))) : 2'd3), 
      .a(dmem_data_mux_out_A), 
      .b(load_mux_output_B), 
      .c(load_mux_output_A),
      .d(b_out_m_A),
      .out(dmem_data_mux_out_B)
   );

   assign o_dmem_towrite = control_m_A[0] ? dmem_data_mux_out_A : (control_m_B[0] ? dmem_data_mux_out_B : 16'b0);

   // w_separator
   wire [15:0] o_out_w_A;
   wire [15:0] d_out_w_A;
   wire [15:0] test_dmem_towrite_w_A;
   wire [6:0]  control_w_A;
   Nbit_reg #(16) pc_reg_w_A (.in(pc_out_m_A), .out(test_cur_pc_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_w_A (.in(insn_out_m_A), .out(test_cur_insn_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_reg_w_A (.in(o_out_m_A), .out(o_out_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) d_reg_w_A (.in(i_cur_dmem_data), .out(d_out_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) test_dmem_towrite_reg_w_A (.in(o_dmem_towrite), .out(test_dmem_towrite_w_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) test_dmem_addr_reg_w_A (.in(o_dmem_addr), .out(test_dmem_addr_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(7) control_reg_w_A (
      .in(control_m_A),
      .out(control_w_A),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );
   Nbit_reg #(2, 2'd2)  stall_reg_w_A (.in(stall_out_m_A), .out(test_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   assign test_dmem_we_A = control_w_A[0];
   assign test_nzp_we_A = control_w_A[2];
   assign test_regfile_we_A = control_w_A[3];
   assign test_regfile_wsel_A = control_w_A[6:4];

   assign test_dmem_data_A = control_w_A[1] ? d_out_w_A : test_dmem_towrite_w_A;

   wire [15:0] load_mux_output_A;
   mux2to1_16 load_mux_A (.S(control_w_A[1]), .A(o_out_w_A), .B(d_out_w_A), .Out(load_mux_output_A));

   assign test_regfile_data_A = load_mux_output_A;
   assign i_wdata_A = load_mux_output_A;

   // N/Z/P
   nzp nzp_w_A (.in(load_mux_output_A), .out(test_nzp_new_bits_A));

   wire [15:0] o_out_w_B;
   wire [15:0] d_out_w_B;
   wire [15:0] test_dmem_towrite_w_B;
   wire [6:0]  control_w_B;
   Nbit_reg #(16) pc_reg_w_B (.in(pc_out_m_B), .out(test_cur_pc_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) insn_reg_w_B (.in(insn_out_m_B), .out(test_cur_insn_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) o_reg_w_B (.in(o_out_m_B), .out(o_out_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) d_reg_w_B (.in(i_cur_dmem_data), .out(d_out_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) test_dmem_towrite_reg_w_B (.in(o_dmem_towrite), .out(test_dmem_towrite_w_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(16) test_dmem_addr_reg_w_B (.in(o_dmem_addr), .out(test_dmem_addr_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(7) control_reg_w_B (
      .in(control_m_B),
      .out(control_w_B),
      .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)
   );
   Nbit_reg #(2, 2'd2)  stall_reg_w_B (.in(stall_out_m_B), .out(test_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

   assign test_dmem_we_B = control_w_B[0];
   assign test_nzp_we_B = control_w_B[2];
   assign test_regfile_we_B = control_w_B[3];
   assign test_regfile_wsel_B = control_w_B[6:4];

   assign test_dmem_data_B = control_w_B[1] ? d_out_w_B : test_dmem_towrite_w_B;

   wire [15:0] load_mux_output_B;
   mux2to1_16 load_mux_B (.S(control_w_B[1]), .A(o_out_w_B), .B(d_out_w_B), .Out(load_mux_output_B));

   assign test_regfile_data_B = load_mux_output_B;
   assign i_wdata_B = load_mux_output_B;

   // N/Z/P
   nzp nzp_w_B (.in(load_mux_output_B), .out(test_nzp_new_bits_B));


   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
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
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      //$display();
   end
endmodule
