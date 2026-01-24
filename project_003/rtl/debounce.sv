
module debounce #(
    parameter CLK_FREQ_HZ = 50_000_000,  // 50 MHz
    parameter DEBOUNCE_TIME_MS = 10  // 10 ms debounce time
) (
    input  logic clk,
    input  logic rst_n,
    input  logic btn_in,
    output logic db_out
);

  localparam int COUNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_TIME_MS;
  localparam int N = $clog2(COUNT);

  logic [N-1:0] q_reg;
  logic [N-1:0] q_next;
  logic         m_tick;
  logic         btn;
  logic sync_ff_0, sync_ff_1;

  typedef enum {
    ZERO,
    WAIT_ONE_1,
    WAIT_ONE_2,
    WAIT_ONE_3,
    ONE,
    WAIT_ZERO_1,
    WAIT_ZERO_2,
    WAIT_ZERO_3
  } state_type;

  state_type state_reg, state_next;

  // ACTIVE LOW BUTTON  METASTABILITE----------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_ff_0 <= 1'b1;
      sync_ff_1 <= 1'b1;
    end else begin
      sync_ff_0 <= btn_in;
      sync_ff_1 <= sync_ff_0;
    end

  end

  assign btn = ~sync_ff_1;  // Invert button input for active low

  // -----------------------------------------------------------------

  // counter to generate m_tick every DEBOUNCE_TIME_MS
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      q_reg <= '0;
    end else begin
      q_reg <= q_next;
    end
  end

  assign q_next = q_reg + 1;
  assign m_tick = (q_reg == 0) ? 1'b1 : 1'b0;

  // FSM for debouncing 

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_reg <= ZERO;
    end else begin
      state_reg <= state_next;
    end
  end

  always_comb begin
    state_next = state_reg;
    db_out = 1'b0;

    case (state_reg)
      ZERO: begin
        if (btn) begin
          state_next = WAIT_ONE_1;
        end
      end
      WAIT_ONE_1: begin
        if (~btn) begin
          state_next = ZERO;
        end else if (m_tick) begin
          state_next = WAIT_ONE_2;
        end
      end
      WAIT_ONE_2: begin
        if (~btn) begin
          state_next = ZERO;
        end else if (m_tick) begin
          state_next = WAIT_ONE_3;
        end
      end
      WAIT_ONE_3: begin
        if (~btn) begin
          state_next = ZERO;
        end else if (m_tick) begin
          state_next = ONE;
        end
      end
      ONE: begin
        db_out = 1'b1;
        if (~btn) begin
          state_next = WAIT_ZERO_1;
        end
      end
      WAIT_ZERO_1: begin
        db_out = 1'b1;
        if (btn) begin
          state_next = ONE;
        end else if (m_tick) begin
          state_next = WAIT_ZERO_2;
        end
      end
      WAIT_ZERO_2: begin
        db_out = 1'b1;
        if (btn) begin
          state_next = ONE;
        end else if (m_tick) begin
          state_next = WAIT_ZERO_3;
        end
      end
      WAIT_ZERO_3: begin
        db_out = 1'b1;
        if (btn) begin
          state_next = ONE;
        end else if (m_tick) begin
          state_next = ZERO;
        end
      end
      default: state_next = ZERO;

    endcase

  end

endmodule
