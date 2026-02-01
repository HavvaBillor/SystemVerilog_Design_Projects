/*
BAUD RATE = PRESCALER * 16 * system_clock_frequncy
16 : oversampling rate

PRESCALER(DIVISOR) = 50_000_000 /(16* 115_200) = 27.12 ~ 27 

*/

module uart_rx #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115_200,
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
) (
    input logic clk_i,
    input logic rst_ni,
    input logic rx_en_i,  // communication enable
    input logic rx_ren_i,  // read enable
    input logic rx_bit_i,
    output logic [DATA_WIDTH -1:0] dout_o,  // data_width bit data input
    output logic empty_o,
    output logic full_o
);
  localparam BAUD_DIV = (CLK_FREQ / BAUD_RATE);  // 16x sample data
  localparam int BAUD_COUNT = $clog2(BAUD_DIV);
  localparam int DATA_COUNT = $clog2(DATA_WIDTH + 1);

  logic [BAUD_COUNT-1:0] baud_counter;
  logic [DATA_COUNT-1:0] bit_counter;
  logic [DATA_WIDTH-1:0] rx_data_reg;
  logic                  rx_wr_en;

  logic                  sync_ff_0;
  logic                  sync_rx_bit;

  logic                  mid_tick;  // 8x sample, sampling point used to capture the data bit at its stable center.
  logic                  end_tick;  // 16x sample, Marks the end of a bit period

  assign mid_tick = (baud_counter == (BAUD_DIV >> 1) - 1);  // shift right 1 = data/2
  assign end_tick = (baud_counter == BAUD_DIV - 1);


  // fifo inst
  wrap_around_fifo #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) fifo_dut (
      .clk   (clk_i),
      .rst_n (rst_ni),
      .rd_en (rx_ren_i),
      .wr_en (rx_wr_en),
      .w_data(rx_data_reg),
      .r_data(dout_o),
      .full  (full_o),
      .empty (empty_o)
  );

  typedef enum logic [2:0] {
    IDLE,
    SEND_START,
    SEND_DATA,
    SEND_STOP
  } state_t;
  state_t next_state, current_state;

  assign rx_wr_en = (current_state == SEND_STOP) && mid_tick && sync_rx_bit;  // wait the stop state and stop signal at mid_tick to write enable FIFO

  // prevent metasbility
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_ff_0   <= 1'b1;
      sync_rx_bit <= 1'b1;
    end else begin
      sync_ff_0   <= rx_bit_i;
      sync_rx_bit <= sync_ff_0;
    end
  end


  always_comb begin

    next_state = current_state;

    case (current_state)
      IDLE: begin
        if (rx_en_i && !sync_rx_bit && !full_o) begin  // when the start bit comes which means that sync_rx_bit(rx_bit_i) is low
          next_state = SEND_START;
        end
      end
      SEND_START: begin
        if (mid_tick) begin
          if (!sync_rx_bit) begin
            next_state = SEND_DATA;
          end else begin
            next_state = IDLE;
          end
        end
      end
      SEND_DATA: begin
        if (mid_tick && (bit_counter == DATA_WIDTH - 1)) begin
          next_state = SEND_STOP;
        end
      end
      SEND_STOP: begin
        if (mid_tick) begin
          if (sync_rx_bit) begin  // stop bit is 1
            next_state = IDLE;
          end
        end
      end
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin
      current_state <= IDLE;
      bit_counter   <= '0;
      rx_data_reg   <= '0;
      baud_counter  <= '0;
    end else begin
      current_state <= next_state;
      if (current_state == IDLE || end_tick) begin
        baud_counter <= '0;
      end else begin
        baud_counter <= baud_counter + 1;
      end
    end

    if (mid_tick) begin
      if (current_state == SEND_DATA) begin
        rx_data_reg[bit_counter] <= sync_rx_bit;
        if (bit_counter < DATA_WIDTH - 1) begin
          bit_counter <= bit_counter + 1;
        end
      end else if (current_state == SEND_START) begin
        bit_counter <= '0;
      end
    end

  end

endmodule
