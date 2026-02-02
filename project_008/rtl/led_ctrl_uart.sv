module led_ctrl_uart #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115_200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
) (
    input logic clk,
    input logic rst_n,
    input logic uart_rx_i,
    output logic uart_tx_o,
    output logic [3:0] led_o
);

  logic                     rx_empty_o;
  logic                     tx_empty_o;
  logic                     rx_full_o;
  logic                     tx_full_o;
  logic                     tx_wen;  // tx write enable
  logic                     rx_ren;  // rx read enable
  logic [DATA_WIDTH -1 : 0] dout_o;  // rx fifo out

  uart_tx #(
      .CLK_FREQ  (CLK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) tx_dut (
      .clk_i   (clk),
      .rst_ni  (rst_n),
      .tx_en_i (1'b1),        // communication enable
      .tx_wen_i(tx_wen),      // write enable
      .din_i   (dout_o),      // data_width bit data input
      .empty_o (tx_empty_o),
      .full_o  (tx_full_o),
      .tx_bit_o(uart_tx_o)

  );

  uart_rx #(
      .CLK_FREQ  (CLK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .DATA_WIDTH(DATA_WIDTH),
      .FIFO_DEPTH(FIFO_DEPTH)
  ) rx_dut (
      .clk_i   (clk),
      .rst_ni  (rst_n),
      .rx_en_i (1'b1),        // communication enable
      .rx_ren_i(rx_ren),      // read enable
      .rx_bit_i(uart_rx_i),
      .dout_o  (dout_o),      // data_width bit data output
      .empty_o (rx_empty_o),
      .full_o  (rx_full_o)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      led_o  <= 4'b0000;
      rx_ren <= '0;
      tx_wen <= '0;
    end else begin
      if (!rx_empty_o && !rx_ren) begin
        rx_ren <= 1'b1;
      end else begin
        rx_ren <= 1'b0;
      end

      tx_wen <= rx_ren;

      if (tx_wen) begin
        led_o <= dout_o[3:0];
      end
    end
  end


endmodule
