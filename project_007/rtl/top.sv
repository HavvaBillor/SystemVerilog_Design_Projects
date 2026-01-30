module top #(
    parameter CLK_FREQ_HZ = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 10  // 10 ms debounce time
) (
    input logic clk,
    input logic rst_n,
    input logic button,
    output logic [3:0] led_0,
    output logic [7:0] seven_seg_out,
    output logic [5:0] an_out
);

  logic [2:0] traffic_lights;
  logic       pwm_en;
  logic [4:0] bcd_data;
  logic       push_led;

  traffic_light_core #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) uut (
      .clk           (clk),
      .rst_n         (rst_n),
      .button        (button),
      .bcd_out       (bcd_data),
      .pwm_enable    (pwm_en),
      .traffic_lights(traffic_lights)
  );
  display_controller #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) dut (
      .clk        (clk),
      .rst_n      (rst_n),
      .pwm_en     (pwm_en),
      .bcd_data_in(bcd_data),
      .push_led   (push_led),
      .seg_out    (seven_seg_out),
      .an_out     (an_out)
  );

  assign led_0[2:0] = traffic_lights;
  assign led_0[3]   = push_led;

endmodule
