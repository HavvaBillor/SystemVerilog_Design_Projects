module led_controller #(
    parameter CLK_FREQ_HZ = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 10,  // 10 ms debounce time
    parameter PWM_FREQ = 1_000
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       btn_mode_in,
    input  logic       btn_up_in,
    input  logic       btn_down_in,
    output logic [1:0] led_out
);

  localparam int COUNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_TIME_MS;
  localparam int N = $clog2(COUNT);

  logic [N-1:0] counter;
  logic         direction;  // 0:down 1:up

  logic         btn_mode_db;
  logic         btn_up_db;
  logic         btn_down_db;
  logic         btn_mode_prev;
  logic         btn_up_prev;
  logic         btn_down_prev;
  logic         btn_mode_pressed;
  logic         btn_up_pressed;
  logic         btn_down_pressed;

  logic [  7:0] selected_duty_cycle;
  logic [  7:0] auto_duty;
  logic [  7:0] manual_duty;
  logic         pwm_out;
  logic         current_mode;  // 0: manual, 1: auto

  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  // instantiate debounce modules for each button
  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) debounce_btn_mode (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(btn_mode_in),
      .db_out(btn_mode_db)
  );

  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) debounce_btn_up (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(btn_up_in),
      .db_out(btn_up_db)
  );

  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) debounce_btn_down (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(btn_down_in),
      .db_out(btn_down_db)
  );
  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  // Instantiate PWM module for LED brightness control
  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  pwm_gen #(
      .CLK_FREQ(CLK_FREQ_HZ),
      .PWM_FREQ(PWM_FREQ)
  ) pwm_manel (
      .clk       (clk),
      .rst_n     (rst_n),
      .duty_cycle(selected_duty_cycle),
      .pwm_out   (pwm_out)
  );


  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  // EDGE DETECTION FOR BUTTONS
  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      btn_mode_prev <= 1'b0;
      btn_up_prev   <= 1'b0;
      btn_down_prev <= 1'b0;
    end else begin
      btn_mode_prev <= btn_mode_db;
      btn_up_prev   <= btn_up_db;
      btn_down_prev <= btn_down_db;
    end
  end

  assign btn_mode_pressed = btn_mode_db && !btn_mode_prev;
  assign btn_up_pressed   = btn_up_db && !btn_up_prev;
  assign btn_down_pressed = btn_down_db && !btn_down_prev;
  // -----------------------------------------------------------------
  // -----------------------------------------------------------------
  // LED MODE AND BRIGHTNESS CONTROL
  // -----------------------------------------------------------------
  // -----------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_mode <= 1'b0;  // manuel start
    end else begin
      if (btn_mode_pressed) begin
        current_mode <= ~current_mode;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      manual_duty <= '0;
    end else if (current_mode == 1'b0) begin
      if (btn_up_pressed && manual_duty < 100) begin
        manual_duty <= manual_duty + 20;
      end else if (btn_down_pressed && manual_duty > 0) begin
        manual_duty <= manual_duty - 20;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter   <= '0;
      auto_duty <= '0;
      direction <= 1'b0;
    end else if (current_mode == 1'b1) begin
      if (counter >= CLK_FREQ_HZ / 100) begin
        counter <= '0;
        if (direction == 1'b0) begin
          if (auto_duty >= 100) direction <= 1'b1;
          else auto_duty <= auto_duty + 1;
        end else begin
          if (auto_duty <= 0) direction <= 1'b0;
          else auto_duty <= auto_duty - 1;
        end
      end else begin
        counter <= counter + 1;
      end
    end
  end


  assign selected_duty_cycle = (current_mode == 1'b0) ? manual_duty : auto_duty;
  assign led_out[0] = pwm_out;
  assign led_out[1] = current_mode;




endmodule
