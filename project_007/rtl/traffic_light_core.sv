module traffic_light_core #(
    parameter CLK_FREQ_HZ = 50_000_000,
    parameter DEBOUNCE_TIME_MS = 10
) (
    input logic clk,
    input logic rst_n,
    input logic button,
    output logic [4:0] bcd_out,  // goes to display controller
    output logic pwm_enable,  // for pedestrian wait led
    output logic [2:0] traffic_lights  // rgb lights
);


  logic [4:0] start_val;
  logic       timer_done_tick;
  logic       timer_en;
  logic [4:0] current_time;
  logic       button_deb;
  logic       ped_request;

  typedef enum {
    IDLE,
    GREEN,
    YELLOW,
    RED
  } state_t;
  state_t next_state, current_state;

  //----------------------------------------------------------------------------------------
  // Instantiate modules
  timer_controller #(
      .CLK_FREQ_HZ(CLK_FREQ_HZ)
  ) timer_dut (
      .clk         (clk),
      .rst_n       (rst_n),
      .enable      (timer_en),
      .start_time  (start_val),
      .current_time(current_time),
      .timer_done  (timer_done_tick)
  );


  debounce #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) debounce_dut (
      .clk   (clk),
      .rst_n (rst_n),
      .btn_in(button),
      .db_out(button_deb)
  );
  //----------------------------------------------------------------------------------------


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ped_request <= 1'b0;
    end else begin
      if (button_deb) begin
        ped_request <= 1'b1;
      end else if (current_state == YELLOW) begin
        ped_request <= 1'b0;
      end
    end
  end

  always_comb begin
    next_state = current_state;
    start_val  = 5'd0;
    timer_en   = 1'b0;  // at the beginning we're starting the green light

    case (current_state)
      IDLE: begin
        next_state = GREEN;
        start_val  = 5'd20;
        timer_en   = 1'b1;
      end

      GREEN: begin

        if (timer_done_tick || (ped_request && current_time <= 10)) begin
          next_state = YELLOW;
          timer_en   = 1'b1;
          start_val  = 5'd5;
        end
      end

      YELLOW: begin

        if (timer_done_tick) begin
          next_state = RED;
          timer_en   = 1'b1;
          start_val  = 5'd15;
        end
      end

      RED: begin

        if (timer_done_tick) begin
          next_state = GREEN;
          timer_en   = 1'b1;
          start_val  = 5'd20;
        end
      end
      default: next_state = IDLE;

    endcase

  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      traffic_lights <= 3'b100;
      pwm_enable <= 1'b0;
    end else begin

      case (next_state)
        IDLE:   traffic_lights <= 3'b001;
        GREEN:  traffic_lights <= 3'b001;
        YELLOW: traffic_lights <= 3'b010;
        RED:    traffic_lights <= 3'b100;
      endcase

      if (ped_request || button_deb) begin
        pwm_enable <= 1'b1;
      end else if (current_state == RED && timer_done_tick) begin
        pwm_enable <= 1'b0;
      end

    end
  end

  assign bcd_out = current_time;




endmodule
