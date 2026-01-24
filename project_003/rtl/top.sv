module top #(
    parameter CLK_FREQ_HZ = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 10  // 10 ms debounce time
) (
    input logic clk,
    input logic rst_n,
    input logic reset_in,
    input logic start_in,
    input logic stop_in,
    output logic [3:0] led_out,
    output logic [7:0] seven_seg_out,
    output logic [5:0] an_out
);

  logic [23:0] bcd_data;
  logic        dp_in;

  // instantiate modules

  display_controller d_c_dut (
      .clk        (clk),
      .rst_n      (rst_n),
      .bcd_data_in(bcd_data),
      .dp_in      (dp_in),
      .sseg_out   (seven_seg_out),
      .an_out     (an_out)
  );

  stopwatch_core #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) clk_dut (
      .clk         (clk),
      .rst_n       (rst_n),
      .reset_in    (reset_in),
      .start_in    (start_in),
      .stop_in     (stop_in),
      .led_out     (led_out),
      .bcd_data_out(bcd_data)
  );


endmodule
