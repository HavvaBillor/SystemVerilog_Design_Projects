`timescale 1ns / 1ps

module tb_stopwatch;

  // Parameters
  localparam CLK_FREQ_HZ = 100_000;
  localparam DEBOUNCE_TIME_MS = 1;

  // Signals
  logic clk, rst_n, reset_in, start_in, stop_in;
  logic [ 3:0] led_out;
  logic [23:0] bcd_data_out;

  // DUT Instantiation
  stopwatch_core #(
      .CLK_FREQ_HZ     (CLK_FREQ_HZ),
      .DEBOUNCE_TIME_MS(DEBOUNCE_TIME_MS)
  ) dut (
      .*
  );

  // Clock Generation
  initial clk = 0;
  always #10ns clk = ~clk;

  // Task: Push Button
  task automatic push_button(ref logic btn, input string name);
    $info("INFO: %s button is pressed...", name);
    btn = 1'b1;
    #(DEBOUNCE_TIME_MS * 1ms + 100us);
    btn = 1'b0;
    #(2ms);
  endtask

  // Test Sequence
  initial begin
    $info("INFO: --- Simulation Started ---");

    // 1. Scenario: Hardware Reset Test
    rst_n    = 1'b0;
    reset_in = 1'b1;  // Active-low 
    start_in = 1'b1;  // Active-low 
    stop_in  = 1'b1;  // Active-low 

    #200ns;  // wait for some time
    rst_n = 1'b1;  // Release reset
    #100us;  // wait for stabilization

    // confirm reset
    #1ms;

    if (bcd_data_out !== 24'b0) $error("ERROR: BCD data is not zero after hardware reset! Data: %h", bcd_data_out);
    else $info("INFO: Hardware reset is successful.");

    // 2. Scenario: Manual Reset Test
    $info("INFO: TEST 1 - Checking Manual Reset");
    push_button(start_in, "START");
    #5ms;
    push_button(reset_in, "RESET");

    #100us;
    if (led_out == 4'b0000 && bcd_data_out == 24'b0) $info("INFO: [PASS] Manual reset cleared the system successfully.");
    else $error("ERROR: [FAIL] Manual reset failed! LEDs: %b, Data: %h", led_out, bcd_data_out);

    // 3. Scenario: Automatic Reset with 5th Stop
    $info("INFO: TEST 2 - Checking Automatic Reset after 5th stop");
    push_button(start_in, "START");

    for (int i = 1; i <= 4; i++) begin
      push_button(stop_in, $sformatf("STOP %0d", i));
      if (led_out === 4'b0) $warning("WARNING: No LEDs turned on after stop %0d!", i);
      if (i < 4) push_button(start_in, "START");
    end

    // Check 4 LEDs
    assert (led_out == 4'b1111) $info("INFO: [PASS] All 4 LEDs are ON after 4 laps.");
    else $error("ERROR: [FAIL] LED count is incorrect! LEDs: %b", led_out);

    // Final Action (Reset expected)
    $info("INFO: Final Step - System should go to IDLE on 5th button press.");
    push_button(start_in, "START");
    push_button(stop_in, "STOP 5 (RESET)");

    #1ms;
    if (bcd_data_out == 24'b0 && led_out == 4'b0) $info("INFO: [SUCCESS] System reset successfully on 5th stop.");
    else $error("ERROR: [CRITICAL] System did not reset on 5th stop! Check logic.");

    $info("INFO: --- All Tests Completed ---");
    $finish;
  end

endmodule
