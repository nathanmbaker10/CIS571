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

                  4'b0100 : begin // JSRR and JSR
                        add_b <= 16'b0;
                        cin <= 1'b0;
                        case (i_insn[11])
                              1'b0 : begin // JSRR
                                    add_a <= i_r1data;
                              end
                              1'b1 : begin // JSR <Label>
                                    add_a <= (i_pc & 16'b1000000000000000) | (i_insn[10:0] << 4);
                              end
                              default : begin
                                    add_a <= 16'b0;
                              end
                        endcase
                  end

                  4'b0110 : begin // LDR
                        add_a <= i_r1data;
                        add_b <= {{10{i_insn[5]}}, i_insn[5:0]};
                        cin <= 0;
                  end

                  4'b0111 : begin // STR
                        add_a <= i_r1data;
                        add_b <= {{10{i_insn[5]}}, i_insn[5:0]};
                        cin <= 0;
                  end

                  4'b1000 : begin // RTI
                        add_a <= i_r1data;
                        add_b <= 16'b0;
                        cin <= 1'b0;
                  end

                  4'b1001 : begin // CONST
                        add_a <= {{7{i_insn[8]}}, i_insn[8:0]};
                        add_b <= 16'b0;
                        cin <= 1'b0;
                  end

                  4'b1100 : begin // JMPR and JMP
                        case (i_insn[11])
                              1'b0 : begin // JMPR
                                    add_a <= i_r1data;
                                    add_b <= 16'b0;
                                    cin <= 1'b0;
                              end
                              1'b1 : begin // JMP <Label>
                                    add_a <= i_pc;
                                    add_b <= {{5{i_insn[10]}}, i_insn[10:0]};
                                    cin <= 1'b1;
                              end
                              default : begin
                                    add_a <= 16'b0;
                                    add_b <= 16'b0;
                                    cin <= 1'b0;
                              end
                        endcase
                  end

                  4'b1101 : begin // HICONST
                        add_a <= (i_r1data & 16'b0000000011111111) | (i_insn[7:0] << 8);
                        add_b <= 16'b0;
                        cin <= 1'b0;
                  end

                  4'b1111 : begin // TRAP
                        add_a <= 16'b1000000000000000 | i_insn[7:0];
                        add_b <= 16'b0;
                        cin <= 1'b0;
                  end

                  default : begin
                        add_a <= 16'b0;
                        add_b <= 16'b0;
                        cin <= 1'b0;
                  end
            endcase
      end

      wire [33:0] cla16_inputs = {add_a, add_b, cin};
      wire [15:0] sum;
      wire [15:0] remainder, quotient;

      wire [2:0] cmp_nzp = {$signed(i_r1data) < $signed(i_r2data), $signed(i_r1data) == $signed(i_r2data), $signed(i_r1data) > $signed(i_r2data)};
      wire [2:0] cmpu_nzp = {i_r1data < i_r2data, i_r1data == i_r2data, i_r1data > i_r2data};
      wire [2:0] cmpi_nzp = {$signed(i_r1data) < $signed(i_insn[6:0]), $signed(i_r1data) == $signed(i_insn[6:0]), $signed(i_r1data) > $signed(i_insn[6:0])};
      wire [2:0] cmpiu_nzp = {i_r1data < i_insn[6:0], i_r1data == i_insn[6:0], i_r1data > i_insn[6:0]};

      lc4_divider divider(.i_dividend(i_r1data), .i_divisor(i_r2data), .o_remainder(remainder), .o_quotient(quotient));
      cla16 adder(.a(add_a), .b(add_b), .cin(cin), .sum(sum));
      
      reg [15:0] out;

      // check whether we should add or not
      always @(*) begin
            case (cla16_inputs)
                  33'b0 : begin
                        case (i_insn[15:12])
                              4'b0001 : begin // arithmetic instructions (MUL, DIV)
                                    case (i_insn[5:3])
                                          3'b001 : begin // MUL
                                                out <= i_r1data * i_r2data;
                                          end
                                          3'b011 : begin // DIV
                                                out <= quotient;
                                          end
                                          default : begin
                                                out <= 16'b0;
                                          end
                                    endcase 
                              end
                              4'b0101 : begin // logic instructions (AND, NOT, OR, XOR, ANDI)
                                    case (i_insn[5])
                                          1'b1 : begin // ANDI
                                                out <= i_r1data & {{11{i_insn[4]}}, i_insn[4:0]};
                                          end
                                          default : begin
                                                case (i_insn[5:3])
                                                      3'b000 : begin // AND
                                                            out <= i_r1data & i_r2data;
                                                      end
                                                      3'b001 : begin // NOT
                                                            out <= ~i_r1data;
                                                      end
                                                      3'b010 : begin // OR
                                                            out <= i_r1data | i_r2data;
                                                      end
                                                      3'b011 : begin // XOR
                                                            out <= i_r1data ^ i_r2data;
                                                      end
                                                      default : begin
                                                            out <= 16'b0;
                                                      end
                                                endcase
                                          end
                                    endcase
                              end
                              4'b1010 : begin // shift and mod instructions (SLL, SRA, SRL, MOD)
                                    case (i_insn[5:4])
                                          2'b00 : begin // SLL
                                                out <= i_r1data << i_insn[3:0];
                                          end
                                          2'b01 : begin // SRA
                                                out <= $signed(i_r1data) >>> i_insn[3:0];
                                          end
                                          2'b10 : begin // SRL
                                                out <= i_r1data >> i_insn[3:0];
                                          end
                                          2'b11 : begin // MOD
                                                out <= remainder;
                                          end
                                          default : begin
                                                out <= 16'b0;
                                          end
                                    endcase
                              end
                              4'b0010 : begin // comparison instructions (CMP, CMPU, CMPI, CMPIU)
                                    case (i_insn[8:7])
                                          2'b00 : begin // CMP
                                                case (cmp_nzp)
                                                      3'b100 : begin
                                                            out <= 16'b1111111111111111;
                                                      end
                                                      3'b010 : begin
                                                            out <= 16'b0000000000000000;
                                                      end
                                                      3'b001 : begin
                                                            out <= 16'b0000000000000001;
                                                      end
                                                      default : begin
                                                            out <= 16'b0;
                                                      end
                                                endcase
                                          end
                                          2'b01 : begin // CMPU
                                                case (cmpu_nzp)
                                                      3'b100 : begin
                                                            out <= 16'b1111111111111111;
                                                      end
                                                      3'b010 : begin
                                                            out <= 16'b0000000000000000;
                                                      end
                                                      3'b001 : begin
                                                            out <= 16'b0000000000000001;
                                                      end
                                                      default : begin
                                                            out <= 16'b0;
                                                      end
                                                endcase
                                          end
                                          2'b10 : begin // CMPI
                                                case (cmpi_nzp)
                                                      3'b100 : begin
                                                            out <= 16'b1111111111111111;
                                                      end
                                                      3'b010 : begin
                                                            out <= 16'b0000000000000000;
                                                      end
                                                      3'b001 : begin
                                                            out <= 16'b0000000000000001;
                                                      end
                                                      default : begin
                                                            out <= 16'b0;
                                                      end
                                                endcase
                                          end
                                          2'b11 : begin // CMPIU
                                                case (cmpiu_nzp)
                                                      3'b100 : begin
                                                            out <= 16'b1111111111111111;
                                                      end
                                                      3'b010 : begin
                                                            out <= 16'b0000000000000000;
                                                      end
                                                      3'b001 : begin
                                                            out <= 16'b0000000000000001;
                                                      end
                                                      default : begin
                                                            out <= 16'b0;
                                                      end
                                                endcase
                                          end
                                          default : begin
                                                out <= 16'b0;
                                          end
                                    endcase
                              end
                              default : begin
                                    out <= 16'b0;
                              end
                        endcase
                  end
                  default : begin
                        out <= sum;
                  end
            endcase
      end

      assign o_result = out;

endmodule


