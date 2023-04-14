`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

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

module Nbit_mux8to1 #(parameter n = 16)
    (
        input  wire [2:0] sel,
        input  wire [n-1:0] a,
        input  wire [n-1:0] b,
        input  wire [n-1:0] c,
        input  wire [n-1:0] d,
        input  wire [n-1:0] e,
        input  wire [n-1:0] f,
        input  wire [n-1:0] g,
        input  wire [n-1:0] h,
        output wire [n-1:0] out
    );

    genvar i;
    for (i = 0; i < n; i = i+1) begin
        mux8to1 m(
            .sel(sel), 
            .a(a[i]), 
            .b(b[i]), 
            .c(c[i]), 
            .d(d[i]), 
            .e(e[i]),
            .f(f[i]), 
            .g(g[i]), 
            .h(h[i]), 
            .out(out[i])
        );
    end

endmodule

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;

   wire [7:0] rd_B_we_1_hot;
   assign rd_B_we_1_hot = {8{i_rd_we_B}} & {i_rd_B == 3'd7, i_rd_B == 3'd6, i_rd_B == 3'd5, i_rd_B == 3'd4, i_rd_B == 3'd3, i_rd_B == 3'd2, i_rd_B == 3'd1, i_rd_B == 3'd0};
   
   wire [7:0] rd_A_we_1_hot;
   assign rd_A_we_1_hot = {8{i_rd_we_A}} & {i_rd_A == 3'd7, i_rd_A == 3'd6, i_rd_A == 3'd5, i_rd_A == 3'd4, i_rd_A == 3'd3, i_rd_A == 3'd2, i_rd_A == 3'd1, i_rd_A == 3'd0};

   Nbit_reg # (n) r0 (.in(i_rd_B == 3'd0 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r0v), .clk(clk), .we(rd_A_we_1_hot[0] | rd_B_we_1_hot[0]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r1 (.in(i_rd_B == 3'd1 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r1v), .clk(clk), .we(rd_A_we_1_hot[1] | rd_B_we_1_hot[1]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r2 (.in(i_rd_B == 3'd2 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r2v), .clk(clk), .we(rd_A_we_1_hot[2] | rd_B_we_1_hot[2]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r3 (.in(i_rd_B == 3'd3 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r3v), .clk(clk), .we(rd_A_we_1_hot[3] | rd_B_we_1_hot[3]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r4 (.in(i_rd_B == 3'd4 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r4v), .clk(clk), .we(rd_A_we_1_hot[4] | rd_B_we_1_hot[4]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r5 (.in(i_rd_B == 3'd5 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r5v), .clk(clk), .we(rd_A_we_1_hot[5] | rd_B_we_1_hot[5]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r6 (.in(i_rd_B == 3'd6 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r6v), .clk(clk), .we(rd_A_we_1_hot[6] | rd_B_we_1_hot[6]), .gwe(gwe), .rst(rst));
   Nbit_reg # (n) r7 (.in(i_rd_B == 3'd7 & i_rd_we_B ? i_wdata_B : i_wdata_A), .out(r7v), .clk(clk), .we(rd_A_we_1_hot[7] | rd_B_we_1_hot[7]), .gwe(gwe), .rst(rst));

   wire [n-1:0] mux1_A_out;
   wire [n-1:0] mux2_A_out;
   wire [n-1:0] mux1_B_out;
   wire [n-1:0] mux2_B_out;

   Nbit_mux8to1 # (n) mux1_A (.sel(i_rs_A), .a(r0v), .b(r1v), .c(r2v), .d(r3v), .e(r4v), .f(r5v), .g(r6v), .h(r7v), .out(mux1_A_out));
   Nbit_mux8to1 # (n) mux2_A (.sel(i_rt_A), .a(r0v), .b(r1v), .c(r2v), .d(r3v), .e(r4v), .f(r5v), .g(r6v), .h(r7v), .out(mux2_A_out));

   Nbit_mux4to1 # (n) o_rs_mux_A (.sel(i_rd_B == i_rs_A & i_rd_we_B ? 2'd0 : (i_rd_A == i_rs_A & i_rd_we_A ? 2'd1 : 2'd2)), .a(i_wdata_B), .b(i_wdata_A), .c(mux1_A_out), .d(mux1_A_out), .out(o_rs_data_A));
   Nbit_mux4to1 # (n) o_rt_mux_A (.sel(i_rd_B == i_rt_A & i_rd_we_B ? 2'd0 : (i_rd_A == i_rt_A & i_rd_we_A ? 2'd1 : 2'd2)), .a(i_wdata_B), .b(i_wdata_A), .c(mux2_A_out), .d(mux2_A_out), .out(o_rt_data_A));

   Nbit_mux8to1 # (n) mux1_B (.sel(i_rs_B), .a(r0v), .b(r1v), .c(r2v), .d(r3v), .e(r4v), .f(r5v), .g(r6v), .h(r7v), .out(mux1_B_out));
   Nbit_mux8to1 # (n) mux2_B (.sel(i_rt_B), .a(r0v), .b(r1v), .c(r2v), .d(r3v), .e(r4v), .f(r5v), .g(r6v), .h(r7v), .out(mux2_B_out));

   Nbit_mux4to1 # (n) o_rs_mux_B (.sel(i_rd_B == i_rs_B & i_rd_we_B ? 2'd0 : (i_rd_A == i_rs_B & i_rd_we_A ? 2'd1 : 2'd2)), .a(i_wdata_B), .b(i_wdata_A), .c(mux1_B_out), .d(mux1_B_out), .out(o_rs_data_B));
   Nbit_mux4to1 # (n) o_rt_mux_B (.sel(i_rd_B == i_rt_B & i_rd_we_B ? 2'd0 : (i_rd_A == i_rt_B & i_rd_we_A ? 2'd1 : 2'd2)), .a(i_wdata_B), .b(i_wdata_A), .c(mux2_B_out), .d(mux2_B_out), .out(o_rt_data_B));

endmodule
