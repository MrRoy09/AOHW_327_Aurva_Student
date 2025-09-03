
  `timescale 1ns/1ps
  `include "params.vh"


 //latency = 7 cycles
 
  module INTT_Scale_Factor #(
      parameter K = 27,
      parameter [K-1:0] INV2 = 27'd66060289  // 1/2 mod Q = (Q+1)/2
  )(
      input  logic clk,
      input  logic [K-1:0] ina,
      output logic [K-1:0] out
  );

      logic [2*K-1:0] product;
      logic [2*K-1:0] product_reg;

      assign product = ina * INV2;

      always_ff @(posedge clk) begin
          product_reg <= product;
      end

      barrett_reduction_pipelined #(.K(K)) barrett_reduce (
          .clk(clk),
          .x(product_reg),
          .n(`Q),
          .mu(`barret_const),
          .r(out)
      );
endmodule
