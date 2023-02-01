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