`timescale 1ns / 1ps

module tb_led_controller;

  logic       clk;
  logic       rst_n;
  logic       btn_mode_in;
  logic       btn_up_in;
  logic       btn_down_in;
  logic [1:0] led_out;

  localparam CLK_FREQ_HZ = 100_000;
  localparam DEBOUNCE_TIME_MS = 10;
  localparam PWM_FREQ = 1_000;

  led_controller #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS),
      .PWM_FREQ        (PWM_FREQ)
  ) dut (
      .*
  );

  initial begin
    clk = 0;
  end
  always #10ns clk = ~clk;

  task automatic push_button(ref logic btn, input string name);
    $info("INFO: %s button is pressed...", name);
    btn = 1'b0;
    #(DEBOUNCE_TIME_MS * 1ms + 100us);
    btn = 1'b1;
    #(2ms);
  endtask

  initial begin

    $info("INFO: --- Simulation Started ---");

    // 1. Scenario: Hardware Reset Test
    rst_n    = 1'b0;
    btn_mode_in = 1'b1;  // Active-low 
    btn_up_in = 1'b1;  // Active-low 
    btn_down_in = 1'b1;  // Active-low 

    #200ns;  // wait for some time
    rst_n = 1'b1;  // Release reset
    #100us;  // wait for stabilization

    if (led_out[0] == 1'b1) $error("ERROR! After hardware reset, auto mode is on!");
    else $info("INFO: Manuel mode is started after hardware reset!");

    for (int i = 0; i < 5; ++i) begin
      push_button(btn_up_in, "UP");
      #100us;
      $info("INFO: %0d UP Time:%0t Manuel Duty: %0d", i, $time, dut.manual_duty);
    end

    push_button(btn_up_in, "UP");
    #100us;
    $info("INFO: 5.UP Time:%0t Manuel Duty: %0d", $time, dut.manual_duty);

    for (int i = 0; i < 5; ++i) begin
      push_button(btn_down_in, "DOWN");
      #100us;
      $info("INFO: %0d.DOWN Time:%0t Manuel Duty: %0d", i, $time, dut.manual_duty);
    end

    push_button(btn_down_in, "DOWN");
    #100us;
    $info("INFO: 5.DOWN Time:%0t Manuel Duty: %0d", $time, dut.manual_duty);

    push_button(btn_mode_in, "MODE");
    #100us;

    if (led_out[1] == 1'b1) $info("INFO: AUTO Mode is on");
    else $error("ERROR! AUTO MODE IS OFF!");

    $info("INFO: Waiting the breathing effect!");
    #20ms;

    $info("INFO: --- Simulation Finished ---");
    $finish;

  end


endmodule
