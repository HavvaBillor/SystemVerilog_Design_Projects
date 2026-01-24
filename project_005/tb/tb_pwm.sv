`timescale 1ns / 1ps

module tb_pwm;

  // Parameters
  localparam int CLK_PERIOD = 20;  // 50 MHz = 20ns
  localparam int PWM_FREQ = 1000;
  localparam int PWM_PERIOD_NS = 1_000_000_000 / PWM_FREQ;  // PWM period in nanoseconds

  // Signals
  logic       clk;
  logic       rst_n;
  logic [7:0] duty_cycle;  // Duty cycle percentage (0-100)
  logic       pwm_out;

  // Instantiate the PWM module
  pwm_gen #(
      .CLK_FREQ(50_000_000),
      .PWM_FREQ(1000)
  ) dut (
      .*
  );

  // Clock generation
  initial begin
    clk = 0;
  end

  always #(CLK_PERIOD / 2) clk = ~clk;  // 50 MHz clock

  // Test sequence
  initial begin
    // Reset
    rst_n = 0;
    duty_cycle = 0;
    #(CLK_PERIOD * 5);
    rst_n = 1;


    $display("Testing 25%% duty cycle...");
    duty_cycle = 25;
    #(PWM_PERIOD_NS * 5);

    $display("Testing 50%% duty cycle...");
    duty_cycle = 50;
    #(PWM_PERIOD_NS * 5);

    $display("Testing 75%% duty cycle...");
    duty_cycle = 75;
    #(PWM_PERIOD_NS * 5);

    $display("Testing 100%% and above duty cycle...");
    $display("Testing 100%% duty cycle...");
    duty_cycle = 100;
    #(PWM_PERIOD_NS * 5);

    $display("Testing 110%% duty cycle...");
    duty_cycle = 110;
    #(PWM_PERIOD_NS * 5);



    $finish;
  end

endmodule
