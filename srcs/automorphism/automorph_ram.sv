`timescale 1ns/1ps

interface AutoInterface #(
    parameter int DLEN = 32,
    parameter int HLEN = 8
);
    logic [HLEN-1:0] addr_a [2];
    logic [HLEN-1:0] addr_b [2];
    logic [DLEN-1:0] do_a   [2];
    logic [DLEN-1:0] do_b   [2];
endinterface

module AutoDPBRAM #(
    parameter int DLEN = 32,
    parameter int HLEN = 7,
    parameter EVEN_FILE = "neg1_even.mem",
    parameter ODD_FILE = "neg1_odd.mem"
)(
    input  logic clk,
    AutoInterface auto_if
);
    localparam int DEPTH = (1<<HLEN);

    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram0 [0:DEPTH-1];
    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram1 [0:DEPTH-1];

    initial begin
        $readmemh(EVEN_FILE, blockram0);
        $readmemh(ODD_FILE, blockram1);
    end

    always_ff @(posedge clk) begin
            auto_if.do_a[0] <= blockram0[ auto_if.addr_a[0] ];
    end

    always_ff @(posedge clk) begin
            auto_if.do_b[0] <= blockram0[ auto_if.addr_b[0] ];
    end

    always_ff @(posedge clk) begin
            auto_if.do_a[1] <= blockram1[ auto_if.addr_a[1] ];
    end

    always_ff @(posedge clk) begin
            auto_if.do_b[1] <= blockram1[ auto_if.addr_b[1] ];
    end

endmodule
