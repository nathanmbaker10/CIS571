/* Matthew Pearl - pearlm, Nathan Baker - nater */

`timescale 1ns / 1ps
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

module lc4_divider(input  wire [15:0] i_dividend,
                   input  wire [15:0] i_divisor,
                   output wire [15:0] o_remainder,
                   output wire [15:0] o_quotient);



      
      //creating an array of busses for the daisy chain interconnect between the div iters
      //o_dividend_arr[i] is the o_divident for div_iter i. etc.
      wire [15: 0] o_dividend_arr[15: 0];
      wire [15: 0] o_remainder_arr[15: 0];
      wire [15: 0] o_quotient_arr[15: 0];


      //must do initial case for input to first div_iter
      lc4_divider_one_iter iter0(.i_dividend(i_dividend), .i_divisor(i_divisor), .i_remainder(16'b0), .i_quotient(16'b0), 
                                     .o_dividend(o_dividend_arr[0]), .o_remainder(o_remainder_arr[0]), 
                                     .o_quotient(o_quotient_arr[0]));
      
      //looping through. input for iter i is output from iter i - 1
      genvar i;
      for (i = 1; i < 16; i=i+1) begin
            lc4_divider_one_iter iterdiv(.i_dividend(o_dividend_arr[i - 1]), .i_divisor(i_divisor), .i_remainder(o_remainder_arr[i -1]), 
            .i_quotient(o_quotient_arr[i - 1]), .o_dividend(o_dividend_arr[i]), 
            .o_remainder(o_remainder_arr[i]), .o_quotient(o_quotient_arr[i]));
      end

      //muxes to check for corner case (x / 0). Ouptut should be 0 for quotient and dividend.
      wire divbyzero = i_divisor == 0;
      mux2to1_16 remainder_mux(.S(divbyzero), .A(o_remainder_arr[15]), .B(16'b0), .Out(o_remainder));
      mux2to1_16 quotient_mux(.S(divbyzero), .A(o_quotient_arr[15]), .B(16'b0), .Out(o_quotient));



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

      mux2to1_16 rem_mux_2(.S(rem_sub_non_negative), .A(rem_mux_out_1), .B(rem_sub[15: 0]), .Out(o_remainder));

      // QUOTIENT CIRCUIT
      wire [15:0] quot_shifted = i_quotient << 1;
      wire [15:0] quot_shifted_plus_1 = quot_shifted + 1;

      mux2to1_16 quot_mux(.S(rem_sub_non_negative), .A(quot_shifted), .B(quot_shifted_plus_1), .Out(o_quotient));

      // DIVIDEND CIRCUIT
      assign o_dividend = i_dividend << 1;
endmodule
