`timescale 1ns / 1ps
`include "params.vh"

module mod_subtraction #(
    parameter K = `K
  )
  (
    input clk,
    input [K-1:0] a,
    input [K-1:0] b,
    input [K-1:0] mod,
    output [K-1:0] result
  );

  logic [K:0] integer_subtraction, integer_subtraction_1DP;
  assign integer_subtraction = a - b;
  always_ff @(posedge clk) begin
    integer_subtraction_1DP <= integer_subtraction;
  end

  logic [K-1:0] corrected, result_2DP;
  assign corrected = integer_subtraction_1DP + mod;
  always_ff @(posedge clk) begin
    result_2DP <= integer_subtraction_1DP[K] ? corrected : integer_subtraction_1DP[K-1:0];
  end
  assign result = result_2DP;
endmodule
