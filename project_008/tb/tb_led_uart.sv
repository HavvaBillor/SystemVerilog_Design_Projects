`timescale 1ns / 1ps
module tb_led_uart;

  localparam CLK_FREQ = 50_000_000;
  localparam BAUD_RATE = 115_200;
  localparam DATA_WIDTH = 8;
  localparam FIFO_DEPTH = 16;
  localparam CLK_PERIOD = 20;
  localparam BAUD_DIV = (CLK_FREQ / BAUD_RATE);
  localparam BAUD_PERIOD = BAUD_DIV * CLK_PERIOD;


  logic       clk;
  logic       rst_n;
  logic       uart_rx_i;
  logic       uart_tx_o;
  logic [3:0] led_o;


  led_ctrl_uart #(
      .CLK_FREQ  (CLK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) led_uart_dut (
      .*
  );

  initial clk = 0;
  always #(CLK_PERIOD / 2) clk = ~clk;

  task send_uart(input logic [7:0] data);
    $display("INFO: Sending byte %0h", data);
    @(negedge clk);
    uart_rx_i = 1'b0;
    #(BAUD_PERIOD);

    for (int i = 0; i < DATA_WIDTH; ++i) begin
      uart_rx_i = data[i];
      #(BAUD_PERIOD);
    end

    uart_rx_i = 1'b1;
    #(BAUD_PERIOD);
    #(BAUD_PERIOD);
  endtask

  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    rst_n = 1'b1;
  end


  initial begin
    @(posedge rst_n);
    repeat (5) @(posedge clk);

    $info("INFO: Test simulation is started!");

    send_uart(8'h41);
    wait (led_o == 4'h1);
    if (led_o == 4'h1) begin
      $display("INFO: Data 8'h41 received! Led: %b", led_o);
    end else begin
      $error("ERROR! Data 8'h41 expected but %b recevied", led_o);
    end

    send_uart(8'h49);
    wait (led_o == 4'h9);
    if (led_o == 4'h9) begin
      $display("INFO: Data 8'h49 received! Led: %b", led_o);
    end else begin
      $error("ERROR! Data 8'h49 expected but %b recevied", led_o);
    end

    #100;
    $info("INFO: Test simulation is finished successfully!");
    $finish;
  end


endmodule
/*
# run -all
# ** Info: INFO: Test simulation is started!
#    Time: 290 ns  Scope: tb_led_uart File: tb/tb_led_uart.sv Line: 59
# INFO: Sending byte 41
# INFO: Data 8'h41 received! Led: 0001
# INFO: Sending byte 49
# INFO: Data 8'h49 received! Led: 1001
# ** Info: INFO: Test simulation is finished successfully!
#    Time: 191360 ns  Scope: tb_led_uart File: tb/tb_led_uart.sv Line: 78
# ** Note: $finish    : tb/tb_led_uart.sv(79)
#    Time: 191360 ns  Iteration: 0  Instance: /tb_led_uart
# End time: 16:31:58 on Feb 02,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
[✓] Batch simulation completed
*/
