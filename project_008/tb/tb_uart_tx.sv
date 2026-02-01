`timescale 1ns / 1ps

module tb_uart_tx #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115_200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter CLK_PERIOD = 10
);

  localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
  localparam BAUD_CLK_PERIOD = BAUD_DIV * CLK_PERIOD;


  logic                  clk_i;
  logic                  rst_ni;
  logic                  tx_en_i;
  logic                  tx_wen_i;
  logic [DATA_WIDTH-1:0] din_i;
  logic                  empty_o;
  logic                  full_o;
  logic                  tx_bit_o;


  uart_tx #(
      .CLK_FREQ  (CLK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) tx_dut (
      .*
  );

  logic [DATA_WIDTH-1:0] test_data_array[] = {'h1, 'h9, 'h0, 'h7};
  logic [           3:0] bit_counter;
  logic [           9:0] expected_frame;

  initial clk_i = '0;
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  task write_fifo(input logic [7:0] data);
    $strobe("Writing data %0h to FIFO", data);
    tx_wen_i = 1;  // tx write enable 1
    din_i = data;  // send data to uart tx data input
    @(posedge clk_i);
    tx_wen_i = 0;
    @(posedge clk_i);
  endtask

  task verifying_tx_bit(input logic expected_bit, input int bit_index);
    @(negedge clk_i);
    if (expected_bit !== tx_bit_o) begin
      $error("ERROR! TX bit verification failed! At bit %0d, expected bit %0b but got: %0b", bit_index, expected_bit, tx_bit_o);
    end else begin
      $info("INFO: TX bit verification successful. Bit %0d is %0b", bit_index, tx_bit_o);
    end
  endtask

  initial begin
    tx_en_i  <= 0;
    tx_wen_i <= 0;
    din_i    <= 0;
    rst_ni   <= 0;
    repeat (2) @(posedge clk_i);
    rst_ni <= 1;

    $display("INFO: Writing data to FIFO ");
    for (int i = 0; i < test_data_array.size(); ++i) begin
      write_fifo(test_data_array[i]);
    end

    $display("INFO: TX enabling and starting transmission ");
    tx_en_i <= 1;

    for (int i = 0; i < test_data_array.size(); ++i) begin
      @(posedge clk_i);
      expected_frame = {1'b1, test_data_array[i], 1'b0};  // stop_bit,test_data,start_bit

      $display("INFO: Testing start bit");
      verifying_tx_bit(expected_frame[0], 0);

      for (bit_counter = 1; bit_counter < 9; bit_counter++) begin
        #BAUD_CLK_PERIOD;
        verifying_tx_bit(expected_frame[bit_counter], bit_counter);
      end

      #BAUD_CLK_PERIOD;
      $display("INFO: Testing stop bit");
      verifying_tx_bit(expected_frame[9], 9);
      #BAUD_CLK_PERIOD;

    end

    wait (empty_o && bit_counter == 9);
    #100ns;
    $display("INFO: All data transmitted! Verification is completed successfully!");
    $finish;

  end



endmodule

/*
# INFO: Writing data to FIFO 
# Writing data 1 to FIFO
# Writing data 9 to FIFO
# Writing data 0 to FIFO
# Writing data 7 to FIFO
# INFO: TX enabling and starting transmission 
# INFO: Testing start bit
# ** Info: INFO: TX bit verification successful. Bit 0 is 0
#    Time: 110 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 1 is 1
#    Time: 4450 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 2 is 0
#    Time: 8790 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 3 is 0
#    Time: 13130 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 4 is 0
#    Time: 17470 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 5 is 0
#    Time: 21810 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 6 is 0
#    Time: 26150 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 7 is 0
#    Time: 30490 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 8 is 0
#    Time: 34830 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing stop bit
# ** Info: INFO: TX bit verification successful. Bit 9 is 1
#    Time: 39170 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing start bit
# ** Info: INFO: TX bit verification successful. Bit 0 is 0
#    Time: 43520 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 1 is 1
#    Time: 47860 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 2 is 0
#    Time: 52200 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 3 is 0
#    Time: 56540 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 4 is 1
#    Time: 60880 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 5 is 0
#    Time: 65220 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 6 is 0
#    Time: 69560 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 7 is 0
#    Time: 73900 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 8 is 0
#    Time: 78240 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing stop bit
# ** Info: INFO: TX bit verification successful. Bit 9 is 1
#    Time: 82580 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing start bit
# ** Info: INFO: TX bit verification successful. Bit 0 is 0
#    Time: 86930 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 1 is 0
#    Time: 91270 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 2 is 0
#    Time: 95610 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 3 is 0
#    Time: 99950 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 4 is 0
#    Time: 104290 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 5 is 0
#    Time: 108630 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 6 is 0
#    Time: 112970 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 7 is 0
#    Time: 117310 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 8 is 0
#    Time: 121650 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing stop bit
# ** Info: INFO: TX bit verification successful. Bit 9 is 1
#    Time: 125990 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing start bit
# ** Info: INFO: TX bit verification successful. Bit 0 is 0
#    Time: 130340 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 1 is 1
#    Time: 134680 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 2 is 1
#    Time: 139020 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 3 is 1
#    Time: 143360 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 4 is 0
#    Time: 147700 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 5 is 0
#    Time: 152040 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 6 is 0
#    Time: 156380 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 7 is 0
#    Time: 160720 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# ** Info: INFO: TX bit verification successful. Bit 8 is 0
#    Time: 165060 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: Testing stop bit
# ** Info: INFO: TX bit verification successful. Bit 9 is 1
#    Time: 169400 ns  Scope: tb_uart_tx.verifying_tx_bit File: tb/tb_uart_tx.sv Line: 55
# INFO: All data transmitted! Verification is completed successfully!
# ** Note: $finish    : tb/tb_uart_tx.sv(97)
#    Time: 173840 ns  Iteration: 0  Instance: /tb_uart_tx
# End time: 13:16:00 on Feb 01,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
[✓] Batch simulation completed

*/
