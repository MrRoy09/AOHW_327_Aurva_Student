`timescale 1ns/1ps

interface DPBRAMInterface #(
    parameter int DLEN = 32,
    parameter int HLEN = 8
);
    logic en   [4];
    logic we   [4];
    logic [HLEN-1:0] addr_a [4];
    logic [HLEN-1:0] addr_b [4];
    logic [DLEN-1:0] di_a   [4];
    logic [DLEN-1:0] di_b   [4];
    logic [DLEN-1:0] do_a   [4];
    logic [DLEN-1:0] do_b   [4];
    logic reset;
endinterface

module PolyCoffDPBRAM #(
    parameter int DLEN = 32,
    parameter int HLEN = 7
)(
    input  logic clk,
    input  logic reset,
    DPBRAMInterface bram_if
);
    localparam int DEPTH = (1<<HLEN);

    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram0 [0:DEPTH-1];
    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram1 [0:DEPTH-1];
    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram2 [0:DEPTH-1];
    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram3 [0:DEPTH-1];

     initial begin
         $readmemh("polycoff_even.mem", blockram0);
         $readmemh("polycoff_odd.mem", blockram1);
     end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_a[0] <= '0;
        end else if (bram_if.en[0]) begin
            if (bram_if.we[0]) begin
                blockram0[ bram_if.addr_a[0] ] <= bram_if.di_a[0];
            end
            bram_if.do_a[0] <= blockram0[ bram_if.addr_a[0] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_b[0] <= '0;
        end else if (bram_if.en[0]) begin
            if (bram_if.we[0]) begin
                blockram0[ bram_if.addr_b[0] ] <= bram_if.di_b[0];
            end
            bram_if.do_b[0] <= blockram0[ bram_if.addr_b[0] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_a[1] <= '0;
        end else if (bram_if.en[1]) begin
            if (bram_if.we[1]) begin
                blockram1[ bram_if.addr_a[1] ] <= bram_if.di_a[1];
            end
            bram_if.do_a[1] <= blockram1[ bram_if.addr_a[1] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_b[1] <= '0;
        end else if (bram_if.en[1]) begin
            if (bram_if.we[1]) begin
                blockram1[ bram_if.addr_b[1] ] <= bram_if.di_b[1];
            end
            bram_if.do_b[1] <= blockram1[ bram_if.addr_b[1] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_a[2] <= '0;
        end else if (bram_if.en[2]) begin
            if (bram_if.we[2]) begin
                blockram2[ bram_if.addr_a[2] ] <= bram_if.di_a[2];
            end
            bram_if.do_a[2] <= blockram2[ bram_if.addr_a[2] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_b[2] <= '0;
        end else if (bram_if.en[2]) begin
            if (bram_if.we[2]) begin
                blockram2[ bram_if.addr_b[2] ] <= bram_if.di_b[2];
            end
            bram_if.do_b[2] <= blockram2[ bram_if.addr_b[2] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_a[3] <= '0;
        end else if (bram_if.en[3]) begin
            if (bram_if.we[3]) begin
                blockram3[ bram_if.addr_a[3] ] <= bram_if.di_a[3];
            end
            bram_if.do_a[3] <= blockram3[ bram_if.addr_a[3] ];
        end
    end

    always_ff @(posedge clk) begin
        if (reset || bram_if.reset) begin
            bram_if.do_b[3] <= '0;
        end else if (bram_if.en[3]) begin
            if (bram_if.we[3]) begin
                blockram3[ bram_if.addr_b[3] ] <= bram_if.di_b[3];
            end
            bram_if.do_b[3] <= blockram3[ bram_if.addr_b[3] ];
        end
    end

endmodule
