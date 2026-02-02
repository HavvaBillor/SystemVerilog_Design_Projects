`timescale 1ns / 1ps
module tb_uart #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115_200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter CLK_PERIOD = 20
);
  localparam BAUD_DIV = (CLK_FREQ / BAUD_RATE);



  logic        clk_i;
  logic        rst_ni;
  logic        stb_i;
  logic [ 1:0] adr_i;
  logic [ 3:0] byte_sel_i;
  logic        we_i;
  logic [31:0] data_i;
  logic [31:0] data_o;
  logic        uart_rx_i;
  logic        uart_tx_o;

  logic        uart_tx;
  byte         TxQueue    [$];

  assign uart_rx_i = uart_tx_o;  // TX'i RX'e geri bağla (Loopback)

  uart #(
      .CLK_FREQ  (CLK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) uart_dut (
      .*
  );

  initial clk_i = 0;
  always #(CLK_PERIOD / 2) clk_i = ~clk_i;

  initial begin
    rst_ni = 1'b0;
    repeat (10) @(posedge clk_i);
    rst_ni = 1'b1;
  end

  task automatic write_reg(input logic [1:0] w_addr, input logic [31:0] w_data, input logic [3:0] w_byte_sel);
    stb_i      = 1'b1;
    we_i       = 1'b1;
    adr_i      = w_addr;
    data_i     = w_data;
    byte_sel_i = w_byte_sel;
    @(posedge clk_i);
    stb_i = 1'b0;
    we_i  = 1'b0;
  endtask

  task automatic read_reg(input logic [1:0] r_addr, output logic [31:0] r_data);
    stb_i = 1'b1;
    we_i  = 1'b0;
    adr_i = r_addr;
    @(posedge clk_i);
    stb_i = 1'b0;
    we_i  = 1'b0;
    @(posedge clk_i);
    r_data = data_o;
  endtask

  initial begin

    @(posedge rst_ni);

    // define register addresses
    `define UART_BAUD_ADDR 2'b00
    `define UART_CTRL_ADDR 2'b01
    `define UART_STATUS_ADDR 2'b10
    `define UART_TX_DATA_ADDR 2'b11
    `define UART_RX_DATA_ADDR 2'b11

    // configure UART baud rate
    $info("INFO: Setting UART baud rate. Divisor: %0d", BAUD_DIV);
    write_reg(.w_addr(`UART_BAUD_ADDR), .w_data(BAUD_DIV), .w_byte_sel(4'b0011));

    // Enable TX and RX
    $info("INFO: Enabling UART TX and RX.");
    write_reg(.w_addr(`UART_CTRL_ADDR), .w_data({32'b0, 1'b1, 1'b1}), .w_byte_sel(4'b0001));

    // Send random data
    $info("INFO: Starting random data transmission test.");

    for (int i = 0; i < FIFO_DEPTH; ++i) begin
      logic [DATA_WIDTH-1:0] random_data;
      random_data = $urandom();


      // Wait if TX is full
      do begin
        logic [31:0] status;
        read_reg(.r_addr(`UART_STATUS_ADDR), .r_data(status));
        if (!status[0]) begin  // tx_full_o = bit 0
          break;
        end
        @(posedge clk_i);
      end while (1);

      // write data to TX FIFO
      write_reg(.w_addr(`UART_TX_DATA_ADDR), .w_data({26'b0, random_data}), .w_byte_sel(4'b001));

      TxQueue.push_back(random_data);
      $info("INFO: Data written to TX FIFO: 0x%0h. TX queue size: %0d", random_data, TxQueue.size());

      @(posedge clk_i);
    end

    $info("INFO: TX FIFO is full. Waiting for data to be received.");


    repeat (100_000) @(posedge clk_i);

    // RX FIFO daki veriyi oku ve doğrula

    while (TxQueue.size() > 0) begin
      logic [DATA_WIDTH -1:0] expected_data;
      logic [           31:0] received_data;

      expected_data = TxQueue.pop_front();

      // RX FIFO'nun boş olmamasını bekleyin
      // Bu testin en öenmli parçasıdır

      do begin
        logic [31:0] status;
        read_reg(.r_addr(`UART_STATUS_ADDR), .r_data(status));
        if (!status[3]) begin
          break;
        end
        @(posedge clk_i);
      end while (1);


      //RX FIFO dan veriyi okuma
      read_reg(.r_addr(`UART_RX_DATA_ADDR), .r_data(received_data));

      // Alınan veriyi doğrulayın
      if (received_data[DATA_WIDTH-1:0] == expected_data) begin
        $info("INFO: Data verified. Received: 0x%0h, Expected: 0x%0h", received_data[DATA_WIDTH-1:0], expected_data);
      end else begin
        $error("ERROR: Data verified. Received: 0x%0h, Expected: 0x%0h", received_data[DATA_WIDTH-1:0], expected_data);
      end
    end

    $info("INFO: All data transmitted, received, and verified successfully.");
    $info("INFO: Test PASSED!");
    $finish;

  end


endmodule
