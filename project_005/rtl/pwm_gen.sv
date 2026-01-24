
module pwm_gen #(
    parameter CLK_FREQ = 50_000_000,
    parameter PWM_FREQ = 1_000
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] duty_cycle,
    output logic       pwm_out
);

  localparam integer PERIOD = CLK_FREQ / PWM_FREQ;  // Number of clock cycles per PWM period
  localparam int WIDTH = $clog2(PERIOD);  // Width of the counter
  logic [WIDTH -1:0] counter;  // Counter for PWM period
  logic [WIDTH -1:0] threshold;  // Threshold for duty cycle

  assign threshold = (duty_cycle * PERIOD) / 100;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 32'd0;
    end else begin
      // timer counter
      if (counter >= PERIOD - 1) begin
        counter <= 32'd0;
      end else begin
        counter <= counter + 1;
      end

      // PWM output logic
      if (counter < threshold) begin
        pwm_out <= 1'b1;
      end else begin
        pwm_out <= 1'b0;
      end
    end
  end


endmodule


