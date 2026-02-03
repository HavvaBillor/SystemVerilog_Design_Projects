`timescale 1ns / 1ps

module tb_bin_to_bcd ();

  logic [15:0] binary_in;
  logic [15:0] bcd_o;

  bin_to_bcd dut (
      .binary_in(binary_in),
      .bcd_o    (bcd_o)
  );

  initial begin
    $display("--- BCD Testi Basliyor ---");

    binary_in = 16'd256;
    #10;
    $display("Input: %d | BCD: %h (Beklenen: 0256)", binary_in, bcd_o);

    binary_in = 16'd1234;
    #10;
    $display("Input: %d | BCD: %h (Beklenen: 1234)", binary_in, bcd_o);

    binary_in = 16'd4995;
    #10;
    $display("Input: %d | BCD: %h (Beklenen: 4995)", binary_in, bcd_o);

    #10;
    $finish;
  end

endmodule

/*
# run -all
# --- BCD Testi Basliyor ---
# Input:   256 | BCD: 0256 (Beklenen: 0256)
# Input:  1234 | BCD: 1234 (Beklenen: 1234)
# Input:  4995 | BCD: 4995 (Beklenen: 4995)
# ** Note: $finish    : tb/tb_bin_to_bcd.sv(30)
#    Time: 40 ns  Iteration: 0  Instance: /tb_bin_to_bcd
# End time: 15:43:47 on Feb 03,2026, Elapsed time: 0:00:01
# Errors: 0, Warnings: 0
[✓] Batch simulation completed
*/
