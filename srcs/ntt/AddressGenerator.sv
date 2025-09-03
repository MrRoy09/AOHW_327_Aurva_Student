`timescale 1ns/1ps
`include "params.vh"

// Pipelined Address Generator with valid signal
module AddressControlUnit_Pipelined #(
    parameter N = 256,
    parameter N_bits = 8
)(
    input logic clk,
    input logic reset,
    input logic enable,                     // Enable address generation
    input logic is_intt,
    input logic [N_bits:0] i,
    input logic [N_bits:0] j, 
    input logic [N_bits:0] m,
    input logic [N_bits:0] counter,
    input logic [N_bits:0] current_pair,
    output logic [N_bits-1:0] index1,index2,index3,index4,
    output logic [N_bits-1:0] tf_index1,tf_index2,
    output logic valid                      // Address generation complete
);

// 2-stage pipelined address generator internal signals
// Stage 1: Control signal decode and basic calculations
logic [N_bits:0] k_for_twiddle_s1;
logic [N_bits:0] counter_s1, current_pair_s1, i_s1;
logic [N_bits:0] m_shift_s1;  // m>>2 pre-calculated
logic [N_bits:0] tf_shift_s1; // (7-i) pre-calculated
logic is_intt_s1;
logic stage0_1_s1;  // i==0 || i==1
logic valid_s1;

// Stage 2: Final address calculations
logic [N_bits-1:0] index1_s2, index2_s2, index3_s2, index4_s2;
logic [N_bits-1:0] tf_index1_s2, tf_index2_s2;
logic valid_s2;

// Twiddle factor base calculations (combinational)
logic [N_bits:0] tf_base1, tf_base2;

// Pipeline Stage 1: Control decode and preparation
always_ff @(posedge clk) begin
    if (reset) begin
        counter_s1 <= 0;
        current_pair_s1 <= 0;
        i_s1 <= 0;
        m_shift_s1 <= 0;
        tf_shift_s1 <= 0;
        is_intt_s1 <= 0;
        stage0_1_s1 <= 0;
        k_for_twiddle_s1 <= 0;
        valid_s1 <= 0;
    end else if (enable) begin
        // Register inputs
        counter_s1 <= counter;
        current_pair_s1 <= current_pair;
        i_s1 <= i;
        is_intt_s1 <= is_intt;
        k_for_twiddle_s1 <= current_pair;
        
        // Pre-calculate shift amounts (critical path reduction)
        m_shift_s1 <= (m >> 2);
        tf_shift_s1 <= (7 - i);
        
        // Decode stage type
        stage0_1_s1 <= (i == 0) || (i == 1);
        
        valid_s1 <= 1;
    end else begin
        valid_s1 <= 0;
    end
end

// Pipeline Stage 2: Final address calculation
always_ff @(posedge clk) begin
    if (reset) begin
        index1_s2 <= 0;
        index2_s2 <= 0;
        index3_s2 <= 0;
        index4_s2 <= 0;
        tf_index1_s2 <= 0;
        tf_index2_s2 <= 0;
        valid_s2 <= 0;
    end else if (valid_s1) begin
        // Address calculations using pre-computed values
        if (stage0_1_s1) begin
            // Sequential pairs: (0,1), (2,3), (4,5)...
            index1_s2 <= counter_s1;
            index2_s2 <= counter_s1;
            index3_s2 <= counter_s1 + 1;
            index4_s2 <= counter_s1 + 1;
        end else begin
            // Butterfly pairs with pre-calculated spacing
            index1_s2 <= counter_s1;
            index2_s2 <= counter_s1;
            index3_s2 <= counter_s1 + m_shift_s1;
            index4_s2 <= counter_s1 + m_shift_s1;
        end
        
        // Twiddle factor generation with pre-calculated shifts
        if (i_s1 == 0) begin
            tf_index1_s2 <= 0;
            tf_index2_s2 <= 0;
        end else begin
            tf_index1_s2 <= is_intt_s1 ? (N - tf_base1) : tf_base1;
            tf_index2_s2 <= is_intt_s1 ? (N - tf_base2) : tf_base2;
        end
        
        valid_s2 <= 1;
    end else begin
        valid_s2 <= 0;
    end
end

// Combinational twiddle factor base calculations
assign tf_base1 = current_pair_s1 << tf_shift_s1;
assign tf_base2 = (current_pair_s1 + 1) << tf_shift_s1;

// Output assignments
assign index1 = index1_s2;
assign index2 = index2_s2;
assign index3 = index3_s2;
assign index4 = index4_s2;
assign tf_index1 = tf_index1_s2;
assign tf_index2 = tf_index2_s2;
assign valid = valid_s2;

endmodule

