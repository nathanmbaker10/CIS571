/* Matthew Pearl - pearlm, Nathan Baker - nater */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
   assign g = a & b;
   assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);
    
    wire g_1_0 = gin[1] | (pin[1] & gin[0]);
    wire p_1_0 = pin[1] & pin[0];
    wire c_1 = gin[0] | (pin[0] & cin);

    wire g_3_2 = gin[3] | (pin[3] & gin[2]);
    wire p_3_2 = pin[3] & pin[2];
    wire c_2 = g_1_0 | (p_1_0 & cin);
    wire c_3 = gin[2] | (pin[2] & c_2);

    wire g_3_0 = g_3_2 | (p_3_2 & g_1_0);
    wire p_3_0 = p_3_2 & p_1_0;

    assign gout = g_3_0;
    assign pout = p_3_0;

    assign cout = {c_3, c_2, c_1};

endmodule

// module one_bit_adder(input wire a, b, c_in, 
//                      output wire s);
//     assign s = (a ^ b ^ c_in) | (a & b & c_in);
// endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

    wire [15:0] gin;
    wire [15:0] pin;

    wire [15:0] gout;
    wire [15:0] pout;

    wire g_3_0, g_7_4, g_11_8, g_15_12;
    wire p_3_0, p_7_4, p_11_8, p_15_12;

    wire [15:0] carry;

    genvar i;
    for (i = 0; i < 16; i = i + 1) begin
        gp1 g(.a(a[i]), .b(b[i]), .g(gin[i]), .p(pin[i]));
    end

    assign carry[0] = cin;
    gp4 gp4_1(.gin(gin[3:0]), .pin(pin[3:0]), .cin(cin), .gout(g_3_0), .pout(p_3_0), .cout(carry[3:1]));
    assign carry[4] = g_3_0 | (p_3_0 & cin);

    gp4 gp4_2(.gin(gin[7:4]), .pin(pin[7:4]), .cin(carry[4]), .gout(g_7_4), .pout(p_7_4), .cout(carry[7:5]));
    assign carry[8] = g_7_4 | (p_7_4 & carry[4]);

    gp4 gp4_3(.gin(gin[11:8]), .pin(pin[11:8]), .cin(carry[8]), .gout(g_11_8), .pout(p_11_8), .cout(carry[11:9]));
    assign carry[12] = g_11_8 | (p_11_8 & carry[8]);

    gp4 gp4_4(.gin(gin[15:12]), .pin(pin[15:12]), .cin(carry[12]), .gout(g_15_12), .pout(p_15_12), .cout(carry[15:13]));
    
    genvar j;
    for (j = 0; j < 16; j = j + 1) begin
        assign sum[j] = (a[j] ^ b[j] ^ carry[j]) | (a[j] & b[j] & carry[j]);
    end
    
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
 
endmodule
