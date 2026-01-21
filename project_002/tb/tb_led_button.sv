`timescale 1ns / 1ps

module tb_led_button;

  // Testbench sinyalleri
  logic clk;
  logic rst_n;
  logic btn_i;
  logic led;

  led_button #(
      .CLK_FREQ        (50_000_000),
      .DEBOUNCE_TIME_MS(20)
  ) dut (
      .clk  (clk),
      .rst_n(rst_n),
      .btn_i(btn_i),
      .led  (led)
  );


  initial clk = 0;
  always #10ns clk = ~clk;

  // Test Senaryosu
  initial begin
    btn_i = 1;
    rst_n = 0;
    #10 rst_n = 1;


    btn_i = 1;
    #100ms;
    btn_i = 0;
    #100ms;
    btn_i = 1;
    #100ms;
    btn_i = 0;
    #100ms;
    btn_i = 1;
    #100ms;
    btn_i = 0;
    #100ms;


    #100ns;
    $finish;
  end


endmodule
