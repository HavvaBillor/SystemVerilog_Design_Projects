module display_controller #(
    parameter CLK_FREQ_HZ = 50_000_000,
    parameter DEBOUNCE_TIME_MS = 10
) (
    input logic clk,
    input logic rst_n,
    input logic pwm_en,
    input logic [4:0] bcd_data_in,
    output logic push_led,
    output logic [7:0] seg_out,
    output logic [5:0] an_out
);
  localparam int PWM_STEP_COUNT = (CLK_FREQ_HZ / 100);

  logic [19:0] refresh_counter;
  logic [31:0] pwm_step_timer;
  logic [ 7:0] auto_duty;
  logic direction, pwm_out;
  logic [3:0] current_digit;

  // --- Breathing LED Logic ---
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pwm_step_timer <= '0;
      auto_duty <= '0;
      direction <= 1'b0;
    end else if (pwm_en) begin
      if (pwm_step_timer >= PWM_STEP_COUNT) begin
        pwm_step_timer <= '0;
        if (!direction) begin
          if (auto_duty >= 100) direction <= 1'b1;
          else auto_duty <= auto_duty + 1;
        end else begin
          if (auto_duty == 0) direction <= 1'b0;
          else auto_duty <= auto_duty - 1;
        end
      end else begin
        pwm_step_timer <= pwm_step_timer + 1;
      end
    end else begin
      pwm_step_timer <= '0;
      auto_duty <= '0;
      direction <= 1'b0;
    end
  end

  pwm_gen pwm_inst (
      .clk       (clk),
      .rst_n     (rst_n),
      .duty_cycle(auto_duty),
      .pwm_out   (pwm_out)
  );
  assign push_led = pwm_out;

  // --- 7-Segment Multiplexing ---
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) refresh_counter <= '0;
    else refresh_counter <= refresh_counter + 1;
  end

  always_comb begin
    case (refresh_counter[18:17])
      2'd0: begin
        an_out = 6'b111110;
        current_digit = bcd_data_in % 10;
      end
      2'd1: begin
        an_out = 6'b111101;
        current_digit = bcd_data_in / 10;
      end
      default: begin
        an_out = 6'b111111;
        current_digit = 4'hF;
      end
    endcase
  end

  bcd_to_sevenseg bcd_inst (
      .bcd_in (current_digit),
      .dp_in  (1'b1),
      .seg_out(seg_out)
  );
endmodule
