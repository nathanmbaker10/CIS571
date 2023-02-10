/* Matthew Pearl - pearlm, Nathan Baker - nater */

`timescale 1ns / 1ps
`default_nettype none

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);

      // determine the values to input to the cla16
      // later, if add_a, add_b, and cin are 0, we will not use the cla16
      reg [15:0] add_a, add_b;
      reg cin;

      // NOTE TO SELF: ASSIGN A AND B HERE -> CASE AFTER FOR ADD OR NOT
      always @(*) begin
            case (i_insn[15:12])
                  4'b0000 : begin // branch instructions
                        add_a <= i_pc;
                        add_b <= {{7{i_insn[8]}}, i_insn[8:0]};
                        cin <= 1'b1;
                  end
                  4'b0001 : begin // arithmetic instructions (ADD, SUB, ADDI)
                        add_a <= i_r1data;
                        cin <= 1'b0;
                        case (i_insn[5])
                              1'b1 : begin // ADDI
                                    add_b <= {{11{i_insn[4]}}, i_insn[4:0]};
                              end
                              default : begin
                                    case (i_insn[5:3])
                                          3'b000 : begin // ADD
                                                add_b <= i_r2data;
                                          end
                                          3'b010 : begin // SUB
                                                add_b <= ~i_r2data;
                                                cin <= 1'b1;
                                          end
                                          default : begin
                                                add_a <= 16'b0;
                                                add_b <= 16'b0;
                                                cin <= 1'b0;
                                          end
                                    endcase
                              end
                        endcase
                  end
                  default : begin
                        add_a <= 16'b1111111111111111;
                        add_b <= 16'b1111111111111111;
                        cin <= 1'b1;
                  end
            endcase
      end

      wire [15:0] sum;

      cla16 adder(.a(add_a), .b(add_b), .cin(cin), .sum(sum));

      assign o_result = sum;

endmodule
