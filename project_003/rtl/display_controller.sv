module display_controller (
    input logic clk,
    input logic rst_n,
    input logic [23:0] bcd_data_in,
    input logic dp_in,
    output logic [7:0] sseg_out,
    output logic [5:0] an_out
);


  logic        current_dp;
  logic [ 3:0] digit_0;
  logic [ 3:0] digit_1;
  logic [ 3:0] digit_2;
  logic [ 3:0] digit_3;
  logic [ 3:0] digit_4;
  logic [ 3:0] digit_5;
  logic [ 3:0] current_data;
  logic [19:0] refresh_counter;  // 20 bits for 1 ms at 50 MHz
  logic [ 2:0] counter;  // 3 bits to count 0 to 5 for 6 digits


  // instantiate modules
  bcd_to_sevenseg dut (
      .bcd_in (current_data),
      .dp_in  (current_dp),
      .seg_out(sseg_out)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      refresh_counter <= 20'd0;
    end else begin
      refresh_counter <= refresh_counter + 1'b1;
    end
  end

  assign counter = refresh_counter[19:17];  // use the top 3 bits for 6 digits

  always_comb begin
    digit_0 = bcd_data_in[3:0];  // ms_ones
    digit_1 = bcd_data_in[7:4];  // ms_tens
    digit_2 = bcd_data_in[11:8];  // sec_ones
    digit_3 = bcd_data_in[15:12];  // sec_tens
    digit_4 = bcd_data_in[19:16];  // min_ones
    digit_5 = bcd_data_in[23:20];  // min_tens
  end

  always_comb begin
    case (counter)
      3'd0: begin
        an_out = 6'b111110;
        current_data = digit_0;
        current_dp = 1'b0;  // decimal point off
      end
      3'd1: begin
        an_out = 6'b111101;
        current_data = digit_1;
        current_dp = 1'b1;  // decimal point on
      end
      3'd2: begin
        an_out = 6'b111011;
        current_data = digit_2;
        current_dp = 1'b0;  // decimal point off
      end
      3'd3: begin
        an_out = 6'b110111;
        current_data = digit_3;
        current_dp = 1'b1;  // decimal point on
      end
      3'd4: begin
        an_out = 6'b101111;
        current_data = digit_4;
        current_dp = 1'b0;  // decimal point off
      end
      3'd5: begin
        an_out = 6'b011111;
        current_data = digit_5;
        current_dp = 1'b0;  // decimal point off
      end
      default: begin
        an_out = 6'b111111;
        current_data = 4'd0;
        current_dp = 1'b1;
      end
    endcase
  end

endmodule
