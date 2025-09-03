`timescale 1ns / 1ps
`include "params.vh"

module mod_addition #(
    parameter K = `K
)(
    input  logic clk,
    input  logic [K-1:0] a,
    input  logic [K-1:0] b,
    input  logic [K-1:0] mod,
    output logic [K-1:0] result
);

    logic [K:0] sum_1DP;
    logic [K:0] sum;
    logic [K:0] reduced;

    assign sum = a + b;

    always_ff @(posedge clk) begin
        sum_1DP <= sum;
    end

    assign reduced = sum_1DP - mod;

    always_ff @(posedge clk) begin
        result <= reduced[K] ? sum_1DP[K-1:0] : reduced[K-1:0];
    end

endmodule
