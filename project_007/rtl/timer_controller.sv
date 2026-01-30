module timer_controller #(
    parameter CLK_FREQ_HZ = 50_000_000
) (
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic [4:0] start_time,
    output logic [4:0] current_time,
    output logic timer_done
);

  logic [25:0] s_counter;
  logic        sec_tick;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_counter <= '0;
      sec_tick  <= 1'b0;
    end else begin
      if (s_counter == CLK_FREQ_HZ - 1) begin
        s_counter <= '0;
        sec_tick  <= 1'b1;
      end else begin
        s_counter <= s_counter + 1;
        sec_tick  <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_time <= '0;
      timer_done   <= 1'b0;
    end else if (enable) begin
      current_time <= start_time;
      timer_done   <= 1'b0;
    end else if (sec_tick && current_time > 0) begin
      current_time <= current_time - 1;
      if (current_time == 1) begin
        timer_done <= 1'b1;
      end
    end
  end

endmodule
