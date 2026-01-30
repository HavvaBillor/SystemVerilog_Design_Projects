`timescale 1ns / 1ps

module tb_traffic_controller;

  logic          clk;
  logic          rst_n;
  logic          button;
  logic    [3:0] led_0;
  logic    [7:0] seven_seg_out;
  logic    [5:0] an_out;

  realtime       start_time;
  realtime       elapsed;

  localparam CLK_FREQ_HZ = 100;
  localparam DEBOUNCE_TIME_MS = 1;

  top #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) dut (
      .*
  );

  initial begin
    clk = 0;
  end
  always #10ns clk = ~clk;



  task push_button();
    $info("INFO:  Button is pressed...");
    button = 1'b0;
    repeat (CLK_FREQ_HZ * 2) @(posedge clk);
    button = 1'b1;
    repeat (20) @(posedge clk);
  endtask

  task automatic check_status(input logic [4:0] exp_bcd, input logic [2:0] exp_leds, input string phase_name);
    // wait(dut.bcd_data == exp_bcd);
    @(dut.uut.current_state);
    if (dut.led_0[2:0] !== exp_leds) begin
      $error("ERROR!  ERROR: at %s phase wrong led! Expected: %b, Received: %b", phase_name, exp_leds, dut.led_0[2:0]);
    end else begin
      $info("INFO:  OK: at %s phase verificated. BCD: %0d", phase_name, dut.bcd_data);
    end
  endtask

  initial begin
    rst_n  = 0;
    button = 1;
    #100ns;
    rst_n = 1;
    #10ns;

    $info("INFO: Simulation is started!");
    if (dut.uut.current_state == dut.uut.IDLE) begin
      $info("INFO: Traffic light simulation is started with GREEN light!");
    end else begin
      $error("ERROR! RESET is not working! ");
    end


    check_status(5'd20, 3'b001, "GREEN_START");
    check_status(5'd5, 3'b010, "YELLOW");
    check_status(5'd10, 3'b100, "RED");
    check_status(5'd20, 3'b001, "GREEN_LOOP_BACK");

    $info("INFO: ---------------------- Pedestiran has come ----------------------");
    wait (dut.uut.current_state == dut.uut.GREEN && dut.bcd_data == 5'd20);
    wait (dut.bcd_data == 5'd15);
    push_button();

    wait (dut.bcd_data <= 10 || dut.uut.current_state == dut.uut.YELLOW);

    if (dut.bcd_data <= 10 || dut.uut.current_state == dut.uut.YELLOW) begin
      $info("INFO: [Scenario 1] Passed. BCD decreased to 10 and jumped to YELLOW. Current BCD: %0d", dut.bcd_data);
    end else begin
      $error("ERROR: [Scenario 1] Failed. BCD is still: %0d", dut.bcd_data);
    end

    wait (dut.uut.current_state == dut.uut.GREEN && dut.bcd_data == 5'd20);
    $info("INFO: New Green cycle started, waiting for BCD < 10...");

    wait (dut.bcd_data == 5'd8);
    push_button();
    repeat (2) @(posedge clk);

    if (dut.led_0[2:0] == 3'b010 || dut.uut.current_state == dut.uut.YELLOW) begin
      $info("INFO: [Scenario 2] Passed. System successfully jumped to YELLOW light. BCD: %0d", dut.bcd_data);
    end else begin
      $error("ERROR: [Scenario 2] Failed. System is still in state: %s with BCD: %0d", dut.uut.current_state.name(), dut.bcd_data);
    end


    $info("INFO: ---------------------- ALL TEST FINISHED ----------------------");
    $finish;

  end


endmodule
