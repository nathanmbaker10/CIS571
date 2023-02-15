/* Matthew Pearl - pearlm, Nathan Baker - nater
 * 
 *
 * lc4_regfile.v
 * Implements an 8-register register file parameterized on word size.
 *
 */

`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

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

module Nbit_mux8to1 #(parameter n = 16)
    (
        input  wire [  2:0] sel,
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

module lc4_regfile #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,
    input  wire [  2:0] i_rs,      // rs selector
    output wire [n-1:0] o_rs_data, // rs contents
    input  wire [  2:0] i_rt,      // rt selector
    output wire [n-1:0] o_rt_data, // rt contents
    input  wire [  2:0] i_rd,      // rd selector
    input  wire [n-1:0] i_wdata,   // data to write
    input  wire         i_rd_we    // write enable
    );

    wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;

    Nbit_reg # (n) r0 (.in(i_wdata), .out(r0v), .clk(clk), .we((i_rd == 3'd0) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r1 (.in(i_wdata), .out(r1v), .clk(clk), .we((i_rd == 3'd1) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r2 (.in(i_wdata), .out(r2v), .clk(clk), .we((i_rd == 3'd2) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r3 (.in(i_wdata), .out(r3v), .clk(clk), .we((i_rd == 3'd3) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r4 (.in(i_wdata), .out(r4v), .clk(clk), .we((i_rd == 3'd4) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r5 (.in(i_wdata), .out(r5v), .clk(clk), .we((i_rd == 3'd5) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r6 (.in(i_wdata), .out(r6v), .clk(clk), .we((i_rd == 3'd6) & i_rd_we), .gwe(gwe), .rst(rst));
    Nbit_reg # (n) r7 (.in(i_wdata), .out(r7v), .clk(clk), .we((i_rd == 3'd7) & i_rd_we), .gwe(gwe), .rst(rst));

    Nbit_mux8to1 # (n) mux1 (.sel(i_rs), .a(r0v), .b(r1v), .c(r2v), .d(r3v), .e(r4v), .f(r5v), .g(r6v), .h(r7v), .out(o_rs_data));
    Nbit_mux8to1 # (n) mux2 (.sel(i_rt), .a(r0v), .b(r1v), .c(r2v), .d(r3v), .e(r4v), .f(r5v), .g(r6v), .h(r7v), .out(o_rt_data));
endmodule