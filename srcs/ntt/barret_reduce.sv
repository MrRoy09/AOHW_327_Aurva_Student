`timescale 1ns / 1ps
`include "params.vh"

// Latency = 6 clock cycles

module barrett_reduction_pipelined #(
    parameter K = `K
)(
    input  logic             clk,
    input  logic [2*K-1:0]   x,   
    input  logic [K-1:0]     n,   
    input  logic [2*K:0]     mu,  
    output logic [K-1:0]     r     
);

logic [2*K-1:0] x_reg1;
logic [K:0]     q1;
logic [2*K-1:0] x_reg2;
logic [3*K:0]   q2;
logic [2*K-1:0] x_reg3;
logic [K-1:0]   q3;
logic [K-1:0]   n_reg3;
logic [2*K-1:0] x_reg4;
logic [2*K-1:0] q3_mul_n_reg4;
logic [K-1:0]   n_reg4;
logic [2*K-1:0] r_temp_reg5;
logic [K-1:0]   n_reg5;

  always_ff @(posedge clk) begin
    x_reg1 <= x;
    q1     <= x >> (K-1);
  end

  always_ff @(posedge clk) begin
    x_reg2 <= x_reg1;
    q2     <= q1 * mu;     
  end

  always_ff @(posedge clk) begin
    x_reg3 <= x_reg2;
    q3     <= q2 >> (K+1);
    n_reg3 <= n;
  end

  always_ff @(posedge clk) begin
    x_reg4 <= x_reg3;
    q3_mul_n_reg4 <= q3 * n_reg3;
    n_reg4 <= n_reg3;
  end

  always_ff @(posedge clk) begin
    r_temp_reg5 <= x_reg4 - q3_mul_n_reg4;
    n_reg5 <= n_reg4;
  end

  always_ff @(posedge clk) begin
    if (r_temp_reg5 >= n_reg5)
      r = r_temp_reg5[K-1:0] - n_reg5;
    else
      r = r_temp_reg5[K-1:0];
  end

endmodule
