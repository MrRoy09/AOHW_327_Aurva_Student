`timescale 1ns/1ps
`include "./params.vh"
`include "./NTT_Controller_Pipelined.sv"
`include "./BRAM.sv"
`include "./DPBRAM.sv"

module tb_NTT_Controller_Pipelined;

    parameter K = 32;
    parameter N = 256;
    parameter N_bits = 8;
    parameter CLK_PERIOD = 20;

    // Clock and reset
    logic clk;
    logic reset;
    logic start;
    logic is_intt;
    logic done;

    // BRAM interfaces
    DPBRAMInterface poly_brams();
    TwiddleBRAMInterface tf_brams();
    
    // Instantiate actual BRAMs for testing
    PolyCoffDPBRAM poly_bram (
        .clk(clk),
        .bram_if(poly_brams)
    );
    
    TwiddleFactorBRAM tf_bram (
        .clk(clk),
        .tf_if(tf_brams)
    );

    // Computation unit debug signals
    logic [N_bits:0] dbg_comp_i, dbg_comp_j, dbg_comp_current_pair, dbg_comp_m, dbg_comp_counter;
    logic [K-1:0] dbg_comp_index1, dbg_comp_index2, dbg_comp_index3, dbg_comp_index4;
    logic [K-1:0] dbg_comp_tf_index1, dbg_comp_tf_index2;
    logic [K-1:0] dbg_comp_poly1, dbg_comp_poly2, dbg_comp_poly3, dbg_comp_poly4;
    logic [K-1:0] dbg_comp_tf1, dbg_comp_tf2;
    logic dbg_comp_valid;

    // Instantiate the NTT Controller
    NTT_Controller_Pipelined #(
        .K(K),
        .N(N),
        .N_bits(N_bits)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .is_intt(is_intt),
        .done(done),
        .poly_brams(poly_brams),
        .tf_brams(tf_brams),
        
        // Computation unit debug outputs
        .dbg_comp_i(dbg_comp_i),
        .dbg_comp_j(dbg_comp_j),
        .dbg_comp_current_pair(dbg_comp_current_pair),
        .dbg_comp_m(dbg_comp_m),
        .dbg_comp_counter(dbg_comp_counter),
        .dbg_comp_index1(dbg_comp_index1),
        .dbg_comp_index2(dbg_comp_index2),
        .dbg_comp_index3(dbg_comp_index3),
        .dbg_comp_index4(dbg_comp_index4),
        .dbg_comp_tf_index1(dbg_comp_tf_index1),
        .dbg_comp_tf_index2(dbg_comp_tf_index2),
        .dbg_comp_poly1(dbg_comp_poly1),
        .dbg_comp_poly2(dbg_comp_poly2),
        .dbg_comp_poly3(dbg_comp_poly3),
        .dbg_comp_poly4(dbg_comp_poly4),
        .dbg_comp_tf1(dbg_comp_tf1),
        .dbg_comp_tf2(dbg_comp_tf2),
        .dbg_comp_valid(dbg_comp_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        reset = 1;
        start = 0;
        is_intt = 0;
        
        // Initialize BRAM interface signals (will be controlled by NTT controller)
        poly_brams.di_a[0] = 0;
        poly_brams.di_a[1] = 0;
        poly_brams.di_b[0] = 0;
        poly_brams.di_b[1] = 0;

        // Reset for a few cycles
        repeat(5) @(posedge clk);
        reset = 0;
        start = 1;

        @(posedge done);
        start = 0;
        is_intt = 1;
        reset = 1;

        repeat(5) @(posedge clk);
        reset = 0;
        start = 1;
        @(posedge done);
        $finish;

        // Start NTT operation
        
    end

    // Optional: Dump waveforms
    initial begin
        $dumpfile("tb_ntt_controller_pipelined.vcd");
        $dumpvars(0, tb_NTT_Controller_Pipelined);
    end

endmodule