module bin_to_bcd (
    input  logic [15:0] binary_in,
    output logic [15:0] bcd_o
);

  logic [31:0] shift_reg;


  always_comb begin
    shift_reg = 32'd0;
    shift_reg[18:3] = binary_in;
    for (int i = 0; i <= 12; ++i) begin
      if (shift_reg[19:16] > 4) shift_reg[19:16] = shift_reg[19:16] + 3;
      if (shift_reg[23:20] > 4) shift_reg[23:20] = shift_reg[23:20] + 3;
      if (shift_reg[27:24] > 4) shift_reg[27:24] = shift_reg[27:24] + 3;
      if (shift_reg[31:28] > 4) shift_reg[31:28] = shift_reg[31:28] + 3;
      shift_reg[31:1] = shift_reg[30:0];
    end
    bcd_o = shift_reg[31:16];

  end


endmodule
