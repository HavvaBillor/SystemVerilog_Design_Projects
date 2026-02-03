module bcd_to_sevenseg (
    input logic [3:0] bcd_in,
    input logic dp_in,
    output logic [7:0] seg_out
);

  logic [6:0] sseg_temp;

  always_comb begin
    case (bcd_in)
      4'h0:    sseg_temp = 7'b1000000;
      4'h1:    sseg_temp = 7'b1111001;
      4'h2:    sseg_temp = 7'b0100100;
      4'h3:    sseg_temp = 7'b0110000;
      4'h4:    sseg_temp = 7'b0011001;
      4'h5:    sseg_temp = 7'b0010010;
      4'h6:    sseg_temp = 7'b0000010;
      4'h7:    sseg_temp = 7'b1111000;
      4'h8:    sseg_temp = 7'b0000000;
      4'h9:    sseg_temp = 7'b0010000;
      4'hA:    sseg_temp = 7'b0001000;
      4'hB:    sseg_temp = 7'b0000011;
      4'hC:    sseg_temp = 7'b1000110;
      4'hD:    sseg_temp = 7'b0100001;
      4'hE:    sseg_temp = 7'b0000110;
      4'hF:    sseg_temp = 7'b0001110;
      default: sseg_temp = 7'b1111111;
    endcase
  end

  assign seg_out = {dp_in, sseg_temp};

endmodule
