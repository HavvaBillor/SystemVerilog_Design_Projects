module debounce #(
    parameter CLK_FREQ         = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 20           // 20 ms debounce time
) (
    input  logic clk,
    input  logic rst_n,
    input  logic signal_in,
    output logic signal_out
);

  localparam int DEBOUNCE_CYCLES = (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS;  // Number of clock cycles for debounce period
  logic [$clog2(DEBOUNCE_CYCLES)-1:0] counter;  // Counter to track debounce time

  logic                               sync_ff_0;
  logic                               sync_ff_1;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff_0 <= 1'b0;
      sync_ff_1 <= 1'b0;
    end else begin
      sync_ff_0 <= signal_in;
      sync_ff_1 <= sync_ff_0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      signal_out <= 1'b1;  // active low button
      counter    <= '0;
    end else begin
      if (sync_ff_1 != signal_out) begin
        if (counter >= DEBOUNCE_CYCLES - 1) begin
          signal_out <= sync_ff_1;
          counter <= '0;
        end else begin
          counter <= counter + 1;
        end
      end else begin
        counter <= '0;
      end
    end
  end




endmodule
