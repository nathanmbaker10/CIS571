`timescale 1ns / 1ps
`default_nettype none

module mux2to1(S, A, B, Out); 
    input S, A, B; 
    output Out; 
    wire S_, AnS_, BnS; 
    
    not (S_, S); 
    and (AnS_, A, S_); 
    and (BnS, B, S); 
    or (Out, AnS_, BnS); 
endmodule