/* Matthew Pearl - pearlm, Nathan Baker - nater */

`include "global_modules.v"

`timescale 1ns / 1ps
`default_nettype none

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);

      /*** YOUR CODE HERE ***/

endmodule // lc4_divider

module lc4_divider_one_iter(input  wire [15:0] i_dividend,
                            input  wire [15:0] i_divisor,
                            input  wire [15:0] i_remainder,
                            input  wire [15:0] i_quotient,
                            output wire [15:0] o_dividend,
                            output wire [15:0] o_remainder,
                            output wire [15:0] o_quotient);

      // REMAINDER CIRCUIT
      wire [15:0] rem_shifted = i_remainder << 1;
      wire [15:0] rem_shifted_plus_1 = rem_shifted + 1;
      wire [15:0] rem_mux_out_1;

      mux2to1_16 rem_mux_1(.S(i_dividend[15]), .A(rem_shifted), .B(rem_shifted_plus_1), .Out(rem_mux_out_1));

      wire signed [16:0] rem_sub = rem_mux_out_1 - i_divisor;
      wire rem_sub_non_negative = rem_sub >= 0;

      mux2to1_16 rem_mux_2(.S(rem_sub_non_negative), .A(rem_mux_out_1), .B(rem_sub), .Out(o_remainder));

      // QUOTIENT CIRCUIT
      wire [15:0] quot_shifted = i_quotient << 1;
      wire [15:0] quot_shifted_plus_1 = quot_shifted + 1;

      mux2to1_16 quot_mux(.S(rem_sub_non_negative), .A(quot_shifted), .B(quot_shifted_plus_1), .Out(o_quotient));

      // DIVIDEND CIRCUIT
      assign o_dividend = i_dividend << 1;
endmodule
