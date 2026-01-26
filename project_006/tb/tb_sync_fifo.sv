`timescale 1ns / 1ps

module tb_sync_fifo;

  localparam FIFO_DEPTH = 8;  // for counter_based and shift fifo, it is used 6
  localparam DATA_WIDTH = 8;

  logic                  clk;
  logic                  rst_n;
  logic                  rd_en;
  logic                  wr_en;
  logic [DATA_WIDTH-1:0] w_data;
  logic [DATA_WIDTH-1:0] r_data;
  logic                  full;
  logic                  empty;


  wrap_around_fifo #(
      .FIFO_DEPTH(FIFO_DEPTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) fifo_dut (
      .*
  );


  // data yazma ve full flag yakalama
  // fifo doluyken data yazma

  // data okuma ve empty flag yakalama
  // fifo boşkan data okuma

  // aynı anda yazıp okuma yani yazdığını okuma

  initial begin
    clk = 0;
  end
  always #10ns clk = ~clk;

  logic [7:0] test_data_array[] = {'h10, 'h11, 'h12, 'h13, 'h14, 'h15, 'h16, 'h17};
  logic [7:0] my_que         [$                                                    ];

  task write_fifo(input logic [7:0] data);
    @(negedge clk);
    w_data <= data;
    wr_en  <= 1'b1;
    @(posedge clk);
    if (full) begin
      $warning("WARNING!: You attempted to write data when FIFO was FULL");
    end else begin
      my_que.push_back(data);
      $info("INFO: [WRITE] Data: %h is written", data);
    end
    wr_en <= 1'b0;
  endtask

  task read_fifo();
    logic [7:0] expected_data;
    @(negedge clk);
    rd_en <= 1'b1;
    @(posedge clk);
    rd_en <= 1'b0;
    @(posedge clk);
    #1;

    if (my_que.size() == 0) begin
      if (!empty) begin
        $error("ERROR! QUE is empty but FIFO is NOT!");
      end else begin
        $warning("WARNING! You attempted to read data when FIFO and QUE were empty");
      end
    end else begin
      expected_data = my_que.pop_front();
      if (r_data !== expected_data) begin
        $error("ERROR! Expected data: %h Received data: %h", expected_data, r_data);
      end else begin
        $info("INFO: Successful reading: %h", r_data);
      end
    end

  endtask

  initial begin

    rst_n  <= 1'b0;
    rd_en  <= 1'b0;
    wr_en  <= 1'b0;
    w_data <= '0;
    #100ns;
    rst_n <= 1'b1;
    #20ns;

    $info("--- TEST SCENARIO IS STARTED ---\n");
    $info("-------------------------------------------------------------------------\n");
    $info("TEST 1: Reading data when FIFO is empty----------------------------------\n");
    read_fifo();
    #20;

    $info("----------------------------------------------------------------------- \n");
    $info("TEST 2: Writing data and testing overflow-------------------------------\n");
    for (int i = 0; i < test_data_array.size(); ++i) begin
      write_fifo(test_data_array[i]);
    end
    #20;

    $info("--------------------------------------------------------------------------- \n");
    $info("TEST 3: Reading data------------------------------------------------------- \n");
    for (int i = 0; i < test_data_array.size(); ++i) begin
      read_fifo();
    end

    $info("------------------------------------------------------------------------------ \n");
    $info("TEST 4: Simultaneous Read & Write--------------------------------------------- \n");

    write_fifo(8'hA1);
    write_fifo(8'hA2);
    #20ns;

    fork
      write_fifo(8'hA3);
      read_fifo();
    join
    #20ns;

    while (my_que.size() > 0) begin
      read_fifo();
    end

    $info("\n -------------------- TESTS FINISHED SUCCESSFULLY -----------------------");
    #100;
    $finish;

  end


endmodule

// counter based and  shift fifo 
/*
# ** Info: --- TEST SCENARIO IS STARTED ---
#    Time: 120 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 92
# ** Info: -------------------------------------------------------------------------
#    Time: 120 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 93
# ** Info: TEST 1: Reading data when FIFO is empty----------------------------------
#    Time: 120 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 94
# ** Warning: WARNING! You attempted to read data when FIFO and QUE were empty
#    Time: 151 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 69
# ** Info: -----------------------------------------------------------------------
#    Time: 171 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 98
# ** Info: TEST 2: Writing data and testing overflow-------------------------------
#    Time: 171 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 99
# ** Info: INFO: [WRITE] Data: 10 is written
#    Time: 190 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: 11 is written
#    Time: 210 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: 12 is written
#    Time: 230 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: 13 is written
#    Time: 250 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: 14 is written
#    Time: 270 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: 15 is written
#    Time: 290 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Warning: WARNING!: You attempted to write data when FIFO was FULL
#    Time: 310 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 48
# ** Warning: WARNING!: You attempted to write data when FIFO was FULL
#    Time: 330 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 48
# ** Info: ---------------------------------------------------------------------------
#    Time: 350 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 105
# ** Info: TEST 3: Reading data-------------------------------------------------------
#    Time: 350 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 106
# ** Info: INFO: Successful reading: 10
#    Time: 391 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: 11
#    Time: 431 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: 12
#    Time: 471 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: 13
#    Time: 511 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: 14
#    Time: 551 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: 15
#    Time: 591 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Warning: WARNING! You attempted to read data when FIFO and QUE were empty
#    Time: 631 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 69
# ** Warning: WARNING! You attempted to read data when FIFO and QUE were empty
#    Time: 671 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 69
# ** Info: ------------------------------------------------------------------------------
#    Time: 671 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 111
# ** Info: TEST 4: Simultaneous Read & Write---------------------------------------------
#    Time: 671 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 112
# ** Info: INFO: [WRITE] Data: a1 is written
#    Time: 690 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: a2 is written
#    Time: 710 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: [WRITE] Data: a3 is written
#    Time: 750 ns  Scope: tb_counter_based_fifo.write_fifo File: tb/tb_counter_based_fifo.sv Line: 51
# ** Info: INFO: Successful reading: a1
#    Time: 771 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: a2
#    Time: 831 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: INFO: Successful reading: a3
#    Time: 871 ns  Scope: tb_counter_based_fifo.read_fifo File: tb/tb_counter_based_fifo.sv Line: 76
# ** Info: 
#  -------------------- TESTS FINISHED SUCCESSFULLY -----------------------
#    Time: 871 ns  Scope: tb_counter_based_fifo File: tb/tb_counter_based_fifo.sv Line: 128
# ** Note: $finish    : tb/tb_counter_based_fifo.sv(130)
#    Time: 971 ns  Iteration: 0  Instance: /tb_counter_based_fifo
# End time: 17:56:56 on Jan 26,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 5
*/
