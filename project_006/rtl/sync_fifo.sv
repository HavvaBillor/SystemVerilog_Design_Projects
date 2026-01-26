// COUNTER_BASED FIFO
// LINEAR(SHIFT) FIFO
// WRAP AROUND FIFO

module counter_based_fifo #(
    parameter FIFO_DEPTH = 4,
    parameter DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  rd_en,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic                  full,
    output logic                  empty
);


  localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

  logic [ DATA_WIDTH-1:0] fifo_mem   [FIFO_DEPTH];
  logic [ADDR_WIDTH -1:0] wr_ptr;
  logic [ADDR_WIDTH -1:0] rd_ptr;
  logic [   ADDR_WIDTH:0] fifo_count;

  assign full  = (fifo_count == FIFO_DEPTH);
  assign empty = (fifo_count == 0);

  logic actual_write;
  logic actual_read;

  assign actual_write = wr_en && !full;
  assign actual_read  = rd_en && !empty;


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr     <= '0;
      rd_ptr     <= '0;
      fifo_count <= '0;
      r_data     <= '0;
    end else begin

      case ({
        actual_write, actual_read
      })
        2'b10: fifo_count <= fifo_count + 1;
        2'b01: fifo_count <= fifo_count - 1;
      endcase
      if (actual_write) begin
        fifo_mem[wr_ptr] <= w_data;
        wr_ptr <= (wr_ptr == FIFO_DEPTH - 1) ? '0 : wr_ptr + 1;
      end
      if (actual_read) begin
        r_data <= fifo_mem[rd_ptr];
        rd_ptr <= (rd_ptr == FIFO_DEPTH - 1) ? '0 : rd_ptr + 1;
      end
    end
  end

endmodule


module shift_fifo #(
    parameter FIFO_DEPTH = 4,
    parameter DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  rd_en,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic                  full,
    output logic                  empty
);

  localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
  logic [DATA_WIDTH-1:0] fifo_mem[FIFO_DEPTH];
  logic [  ADDR_WIDTH:0] wr_ptr;

  assign full  = (wr_ptr == FIFO_DEPTH);
  assign empty = (wr_ptr == 0);

  logic actual_write;
  logic actual_read;

  assign actual_write = wr_en && !full;
  assign actual_read  = rd_en && !empty;


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      r_data <= '0;
    end else begin

      if (actual_write && !actual_read) begin
        fifo_mem[wr_ptr] <= w_data;
        wr_ptr <= wr_ptr + 1;
      end else if (actual_read && !actual_write) begin
        r_data <= fifo_mem[0];
        for (int i = 0; i < FIFO_DEPTH - 1; ++i) begin
          fifo_mem[i] <= fifo_mem[i+1];
        end
        wr_ptr <= wr_ptr - 1;
      end else if (actual_read && actual_write) begin
        r_data <= fifo_mem[0];
        for (int i = 0; i < FIFO_DEPTH - 1; ++i) begin
          fifo_mem[i] <= fifo_mem[i+1];
        end
        fifo_mem[wr_ptr-1] <= w_data;
      end
    end

  end

endmodule

// WRAP AROUND 2^n fifo depth !!!

module wrap_around_fifo #(
    parameter FIFO_DEPTH = 4,
    parameter DATA_WIDTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  rd_en,
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] w_data,
    output logic [DATA_WIDTH-1:0] r_data,
    output logic                  full,
    output logic                  empty
);


  localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);
  logic [DATA_WIDTH - 1:0] fifo_mem[FIFO_DEPTH];
  logic [  ADDR_WIDTH : 0] wr_ptr;
  logic [  ADDR_WIDTH : 0] rd_ptr;

  assign empty = (wr_ptr == rd_ptr);
  assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

  logic actual_write;
  logic actual_read;

  assign actual_write = wr_en && !full;
  assign actual_read  = rd_en && !empty;


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      r_data <= '0;
    end else begin

      if (actual_write) begin
        fifo_mem[wr_ptr[ADDR_WIDTH-1:0]] <= w_data;
        wr_ptr <= wr_ptr + 1;
      end
      if (actual_read) begin
        r_data <= fifo_mem[rd_ptr[ADDR_WIDTH-1:0]];
        rd_ptr <= rd_ptr + 1;
      end

    end
  end

endmodule
