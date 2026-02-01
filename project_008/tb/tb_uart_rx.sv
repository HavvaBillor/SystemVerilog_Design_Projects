`timescale 1ns / 1ps

module tb_uart_rx #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115_200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter CLK_PERIOD = 20

);

  localparam BAUD_DIV = CLK_FREQ / BAUD_RATE;
  localparam BAUD_CLK_PERIOD = BAUD_DIV * CLK_PERIOD;

  logic                   clk_i;
  logic                   rst_ni;
  logic                   rx_en_i;
  logic                   rx_ren_i;
  logic                   rx_bit_i;
  logic [DATA_WIDTH -1:0] dout_o;
  logic                   empty_o;
  logic                   full_o;

  logic [ DATA_WIDTH-1:0] test_data_array  [] = {'h1, 'h9, 'h0, 'h7};
  logic [DATA_WIDTH -1:0] golden_model_fifo[$                        ];

  int                     tx_data_index;
  int                     rx_data_index;


  uart_rx #(
      .CLK_FREQ  (CLK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) uart_rx_dut (
      .*
  );

  initial begin
    clk_i = 0;
  end
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;


  task send_byte(input logic [DATA_WIDTH -1:0] data);
    $strobe("Sending data 'h'%0h = 'b%0b", data, data);
    rx_bit_i = 0;
    #BAUD_CLK_PERIOD;

    for (int i = 0; i < DATA_WIDTH; i++) begin
      rx_bit_i = data[i];
      #BAUD_CLK_PERIOD;
    end

    rx_bit_i = 1;
    #BAUD_CLK_PERIOD;
  endtask

  task read_and_verify();

    logic [DATA_WIDTH -1:0] expected_data;
    logic [DATA_WIDTH -1:0] received_data;

    rx_ren_i = 1;
    @(posedge clk_i);
    rx_ren_i = 0;
    @(posedge clk_i);

    received_data = dout_o;
    expected_data = golden_model_fifo.pop_front();

    if (received_data != expected_data) begin
      $error("ERROR! Data mismatched! Received data: %0h but expected data: %0h", received_data, expected_data);
      $finish;
    end else begin
      $display("INFO: Data received successfully: 'h%0h", received_data);
    end
  endtask

  initial begin

    rx_ren_i <= 0;
    rx_en_i  <= 0;
    rx_bit_i <= 1'b1;

    rst_ni   <= '0;
    @(posedge clk_i);
    rst_ni  <= '1;

    rx_en_i <= 1;
    $display("INFO: Sending test data via simulated TX...");

    for (tx_data_index = 0; tx_data_index < test_data_array.size(); ++tx_data_index) begin
      golden_model_fifo.push_back(test_data_array[tx_data_index]);  // added fifo
      send_byte(test_data_array[tx_data_index]);  // sending uart
    end

    $display("INFO: All data sent. Waiting for DUT to receive");

    wait (empty_o == 0);  // wait the time when all data sent to fifo


    while (golden_model_fifo.size() > 0) begin
      read_and_verify();
      @(posedge clk_i);
    end

    $display("INFO: All data received and verified. FIFO is empty");

    $display("INFO: Sending one more byte to test the end-to-end logic");
    send_byte('h25);
    golden_model_fifo.push_back('h25);

    wait (empty_o == 0);
    @(posedge clk_i);

    read_and_verify();

    #100ns;

    $display("INFO: Test finished succesfully");
    $finish;

  end


endmodule

/*

# run -all
# INFO: Sending test data via simulated TX...
# Sending data 'h'1 = 'b1
# Sending data 'h'9 = 'b1001
# Sending data 'h'0 = 'b0
# Sending data 'h'7 = 'b111
# INFO: All data sent. Waiting for DUT to receive
# INFO: Data received successfully: 'h1
# INFO: Data received successfully: 'h9
# INFO: Data received successfully: 'h0
# INFO: Data received successfully: 'h7
# INFO: All data received and verified. FIFO is empty
# INFO: Sending one more byte to test the end-to-end logic
# Sending data 'h'25 = 'b100101
# INFO: Data received successfully: 'h25
# INFO: Test finished succesfully
# ** Note: $finish    : tb/tb_uart_rx.sv(123)
#    Time: 434370 ns  Iteration: 0  Instance: /tb_uart_rx
# End time: 17:49:17 on Feb 01,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
[✓] Batch simulation completed

*/
