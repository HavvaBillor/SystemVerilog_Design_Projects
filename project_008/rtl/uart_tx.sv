/*
BAUD RATE = PRESCALER * 16 * system_clock_frequncy
16 : oversampling rate

PRESCALER(DIVISOR) = 50_000_000 /(16* 115_200) = 27.12 ~ 27 

*/

module uart_tx #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 115_200,
    parameter DATA_WIDTH = 8,  // in my design, it should be 2^n
    parameter FIFO_DEPTH = 16
) (
    input logic clk_i,
    input logic rst_ni,
    input logic tx_en_i,  // communication enable
    input logic tx_wen_i,  // write enable
    input logic [DATA_WIDTH -1:0] din_i,  // data_width bit data input
    output logic empty_o,
    output logic full_o,
    output logic tx_bit_o

);

  localparam BAUD_DIV = (CLK_FREQ / BAUD_RATE);  // tx sends the data with 16 sampling rate
  localparam int N = $clog2(BAUD_DIV);
  localparam int M = $clog2(DATA_WIDTH);

  logic [          N-1:0] baud_counter;
  logic [          M-1:0] bit_counter;
  logic [DATA_WIDTH -1:0] data_reg;
  logic                   rd_en;
  logic [            7:0] r_data;

  // fifo inst
  wrap_around_fifo #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) fifo_dut (
      .clk   (clk_i),
      .rst_n (rst_ni),
      .rd_en (rd_en),
      .wr_en (tx_wen_i),
      .w_data(din_i),     // write data
      .r_data(r_data),
      .full  (full_o),
      .empty (empty_o)
  );

  typedef enum logic [1:0] {
    IDLE,
    SEND_START,
    SEND_DATA,
    SEND_STOP
  } state_t;

  state_t next_state, current_state;

  always_comb begin
    next_state = current_state;
    rd_en = 1'b0;

    case (current_state)
      IDLE: begin
        // if communication is started and fifo is not empty
        if (tx_en_i && !empty_o) begin
          next_state = SEND_START;
          rd_en = 1'b1;  // reading data via fifo
        end
      end
      SEND_START: begin
        // send start bit 
        if (baud_counter == BAUD_DIV - 1) begin  // (baud_counter == BAUD_DIV - 1) means one uart bit time
          next_state = SEND_DATA;
        end
      end
      SEND_DATA: begin
        // send data and if you sent 8bit jump to send_stop
        if ((baud_counter == BAUD_DIV - 1) && (bit_counter == 7)) begin
          next_state = SEND_STOP;
        end
      end
      SEND_STOP: begin
        // if it is sent stop bit to uart, you have to jump idle state or if there is a new data restart
        if (baud_counter == BAUD_DIV - 1) begin
          if (tx_en_i && !empty_o) begin
            next_state = SEND_START;
            rd_en = 1'b1;
          end else begin
            next_state = IDLE;
            rd_en = 1'b0;
          end
        end
      end
    endcase

    case (current_state)
      IDLE:       tx_bit_o = 1'b1;
      SEND_START: tx_bit_o = 1'b0;
      SEND_DATA:  tx_bit_o = data_reg[bit_counter];
      SEND_STOP:  tx_bit_o = 1'b1;
    endcase

  end


  // bit counter nad baud counter fsm

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      current_state <= IDLE;
      bit_counter <= '0;
      baud_counter <= '0;
      data_reg <= '0;
    end else begin
      current_state <= next_state;

      if (current_state != IDLE) begin
        if (baud_counter == BAUD_DIV - 1) begin
          baud_counter <= '0;
        end else begin
          baud_counter <= baud_counter + 1;
        end
      end

      if (baud_counter == BAUD_DIV - 1) begin

        case (current_state)
          IDLE: begin
            bit_counter <= '0;
          end
          SEND_START: begin
            bit_counter <= '0;
            data_reg <= r_data;  // observe the fifo module 
          end
          SEND_DATA: begin
            if (bit_counter == 7) begin
              bit_counter <= '0;
            end else begin
              bit_counter <= bit_counter + 1;
            end
          end
          SEND_STOP: begin
            bit_counter <= '0;
          end
        endcase
      end
    end
  end

endmodule
