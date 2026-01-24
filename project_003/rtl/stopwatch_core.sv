// This module implements a stopwatch logic.
// When the start button is pressed, the stopwatch starts counting.
// Pressing the button again pauses the counting, and pressing it again resumes
// from the last value. The stopwatch can be reset using the reset signal.
//
// Additionally, a lap (round) feature is implemented using LEDs.
// Each time the stopwatch is paused, the lap counter increases and one LED turns on.
// Up to 4 LEDs are used on the board: after 1 pause, 1 LED is on; after 4 pauses, all LEDs are on.
// If the lap count exceeds 5, both the lap counter and the stopwatch are automatically reset.

module stopwatch_core #(
    parameter CLK_FREQ_HZ = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 10  // 10 ms debounce time
) (
    input logic clk,
    input logic rst_n,  // system reset active low
    input logic reset_in,  //stopwatch reset button
    input logic start_in,
    input logic stop_in,
    output logic [3:0] led_out,  // status LEDs for stopwatch laps
    output logic [23:0] bcd_data_out
);

  // -----------------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------
  // Integral signals and parameters for m_tick generation (1 ms tick)
  localparam int COUNT = 500000;
  logic [18:0] q_reg;
  logic        m_tick;
  // -----------------------------------------------------------------------------------
  // Internal signals for debounced buttons and edge detection
  logic        reset_db;
  logic        start_db;
  logic        stop_db;
  logic        reset_db_prev;
  logic        start_db_prev;
  logic        stop_db_prev;
  logic        reset_pressed;
  logic        start_pressed;
  logic        stop_pressed;
  // -----------------------------------------------------------------------------------
  // Internal signals for stopwatch FSM
  logic [ 3:0] ms_ones;
  logic [ 3:0] ms_tens;
  logic [ 3:0] sec_ones;
  logic [ 3:0] sec_tens;
  logic [ 3:0] min_ones;
  logic [ 3:0] min_tens;
  logic [ 2:0] stop_count;  // counts number of stops for LED indication

  // -----------------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------
  // Instantiate debounce modules for reset, start, and stop buttons
  // -----------------------------------------------------------------------------------
  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) start_button (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(start_in),
      .db_out(start_db)
  );

  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) reset_button (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(reset_in),
      .db_out(reset_db)
  );

  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) stop_button (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(stop_in),
      .db_out(stop_db)
  );
  // -----------------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------
  // Generate m_tick every 1 ms
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q_reg <= '0;
    end else if (q_reg >= COUNT - 1) begin
      q_reg <= q_reg + 1;
    end
  end

  assign m_tick = (q_reg == COUNT - 1) ? 1'b1 : 1'b0;

  // -----------------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------
  // Edge detection for buttons of reset, start, and stop
  // -----------------------------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_db_prev <= 1'b0;
      start_db_prev <= 1'b0;
      stop_db_prev  <= 1'b0;
    end else begin
      reset_db_prev <= reset_db;
      start_db_prev <= start_db;
      stop_db_prev  <= stop_db;
    end
  end

  assign reset_pressed = reset_db && !reset_db_prev;
  assign start_pressed = start_db && !start_db_prev;
  assign stop_pressed  = stop_db && !stop_db_prev;
  // -----------------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------
  // -----------------------------------------------------------------------------------
  // STOPWATCH FSM MODULEs
  typedef enum {
    IDLE,
    RUNNING,
    STOPPED
  } state_t;

  state_t current_state, next_state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  always_comb begin
    next_state = current_state;
    case (current_state)
      IDLE: begin
        if (start_pressed) begin
          next_state = RUNNING;
        end
      end
      RUNNING: begin
        if (stop_pressed) begin
          if (stop_count >= 3'd4) begin
            next_state = IDLE;
          end else begin
            next_state = STOPPED;
          end
        end else if (reset_pressed) begin
          next_state = IDLE;
        end
      end
      STOPPED: begin
        if (start_pressed) begin
          next_state = RUNNING;
        end else if (reset_pressed) begin
          next_state = IDLE;
        end
      end
    endcase
  end

  // -----------------------------------------------------------------------------------
  // stop_count and LED output logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stop_count <= 3'd0;
    end else begin
      if (current_state == IDLE) begin
        stop_count <= 3'd0;
      end else if (current_state == RUNNING && stop_pressed) begin
        stop_count <= stop_count + 3'd1;
      end
    end
  end

  always_comb begin
    led_out = 4'b0000;
    case (stop_count)
      3'd0:    led_out = 4'b0000;
      3'd1:    led_out = 4'b0001;
      3'd2:    led_out = 4'b0011;
      3'd3:    led_out = 4'b0111;
      3'd4:    led_out = 4'b1111;
      default: led_out = 4'b0000;
    endcase
  end
  // -----------------------------------------------------------------------------------
  // main stopwatch counting logic

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ms_ones  <= 4'd0;
      ms_tens  <= 4'd0;
      sec_ones <= 4'd0;
      sec_tens <= 4'd0;
      min_ones <= 4'd0;
      min_tens <= 4'd0;
    end else if (current_state == IDLE) begin
      ms_ones  <= 4'd0;
      ms_tens  <= 4'd0;
      sec_ones <= 4'd0;
      sec_tens <= 4'd0;
      min_ones <= 4'd0;
      min_tens <= 4'd0;
    end else if (current_state == RUNNING && m_tick) begin
      if (ms_ones == 4'd9) begin
        ms_ones <= 4'd0;
        if (ms_tens == 4'd9) begin
          ms_tens <= 4'd0;
          if (sec_ones == 4'd9) begin
            sec_ones <= 4'd0;
            if (sec_tens == 4'd5) begin
              sec_tens <= 4'd0;
              if (min_ones == 4'd9) begin
                min_ones <= 4'd0;
                if (min_tens == 4'd5) begin
                  min_tens <= 4'd0;
                end else begin
                  min_tens <= min_tens + 4'd1;
                end
              end else begin
                min_ones <= min_ones + 4'd1;
              end
            end else begin
              sec_tens <= sec_tens + 4'd1;
            end
          end else begin
            sec_ones <= sec_ones + 4'd1;
          end
        end else begin
          ms_tens <= ms_tens + 4'd1;
        end
      end else begin
        ms_ones <= ms_ones + 4'd1;
      end
    end
  end

  assign bcd_data_out = {min_tens, min_ones, sec_tens, sec_ones, ms_tens, ms_ones};


endmodule
