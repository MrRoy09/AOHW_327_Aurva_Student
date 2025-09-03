`include "params.vh"

module mod_multiplication #(
    parameter K = `K
)(
    input  logic clk,
    input  logic [K-1:0] a,
    input  logic [K-1:0] b,
    output logic [K-1:0] result
);

    logic [2*K-1:0] product;
    (* dont_touch = "true" *) logic [2*K-1:0] product_1DP;
    (* dont_touch = "true" *) logic [2*K-1:0] product_2DP;
    (* dont_touch = "true" *) logic [2*K-1:0] product_3DP;
    (* dont_touch = "true" *) logic [2*K-1:0] product_4DP;

    assign product = a * b;

    always_ff @(posedge clk) begin
        product_1DP <= product;
        product_2DP <= product_1DP;
        product_3DP <= product_2DP;
        product_4DP <= product_3DP;
    end

    barrett_reduction_pipelined #(
        .K(K)
    ) barrett_reduce (
        .clk(clk),
        .x(product_4DP),
        .n(`Q),
        .mu(`barret_const),
        .r(result)
    );

endmodule
