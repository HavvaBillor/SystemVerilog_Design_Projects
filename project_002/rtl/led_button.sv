module led_button #(
    parameter CLK_FREQ = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 20  // 20 ms debounce time
) (
    input  logic clk,
    input  logic rst_n,
    input  logic btn_i,
    output logic led
);

  // Internal signals
  logic btn_clean;
  logic btn_clean_prev;
  logic btn_edge;


  // debounce instance
  debounce #(
      .CLK_FREQ        (CLK_FREQ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) debounce_inst (
      .clk       (clk),
      .rst_n     (rst_n),
      .signal_in (btn_i),
      .signal_out(btn_clean)
  );

  // Edge detection
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      btn_clean_prev <= 1'b1;  // active low button
    end else begin
      btn_clean_prev <= btn_clean;
    end
  end

  assign btn_edge = btn_clean_prev & ~btn_clean;  // detect falling edge (button press)

  // LED control logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      led <= 1'b0;
    end else begin
      if (btn_edge) begin
        led <= ~led;  // toggle LED on button press
      end
    end
  end


endmodule
