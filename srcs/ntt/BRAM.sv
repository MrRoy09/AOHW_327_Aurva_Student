interface TwiddleBRAMInterface #(
    parameter int DLEN = 32,
    parameter int HLEN = 10
);
    logic [HLEN-1:0] raddra;
    logic [DLEN-1:0] douta;
    logic [HLEN-1:0] raddrb;
    logic [DLEN-1:0] doutb;
endinterface

module TwiddleFactorBRAM #(
    parameter int DLEN = 32,
    parameter int HLEN = 10 
)(
    input logic clk,
    TwiddleBRAMInterface tf_if
);

    (* ram_style = "block" *)
    logic [DLEN-1:0] blockram [0:(1 << HLEN)-1];

    initial begin
        $readmemh("NTT_tables.mem", blockram);
    end

    always_ff @(posedge clk) begin
        tf_if.douta <= blockram[tf_if.raddra];
    end

    always_ff @(posedge clk) begin
        tf_if.doutb <= blockram[tf_if.raddrb];
    end

endmodule
