`timescale 1ns / 1ps
`include "params.vh"


module CTNTTButterfly_Pipeline #(
    parameter K = `K 
) (
    input clk,
    input start,
    input reset,
    input [K-1:0] ina,
    input [K-1:0] inb,
    input [K-1:0] q_m,
    input [K-1:0] twiddle_factor,
    input is_intt,
    output [K-1:0] outa,
    output [K-1:0] outb,
    output complete,
    // Debug ports - synthesis will preserve these
    output [K-1:0] dbg_input_a,
    output [K-1:0] dbg_input_b,
    output [K-1:0] dbg_twiddle,
    output [K-1:0] dbg_mult_result,
    output [K-1:0] dbg_add_result,
    output [K-1:0] dbg_sub_result,
    output [K-1:0] dbg_output_a,
    output [K-1:0] dbg_output_b,
    output dbg_is_intt
);

typedef struct packed {
    logic [K-1:0] ina;
    logic [K-1:0] inb;
    logic [K-1:0] twiddle_factor;
    logic is_intt;
    logic [K-1:0] result;
} mult_stage_t;

typedef struct packed {
    logic [K-1:0] ina;
    logic [K-1:0] inb;
    logic [K-1:0] twiddle_factor;
    logic is_intt;
    logic [K-1:0] result;
} intt_mult_stage_t;

typedef struct packed {
    logic [K-1:0] ina;
    logic [K-1:0] inb;
    logic is_intt;
    logic [K-1:0] result;
} add_stage_t;

typedef struct packed {
    logic [K-1:0] ina;
    logic [K-1:0] inb;
    logic is_intt;
    logic [K-1:0] result;
} sub_stage_t;

localparam MULT_LATENCY = 10;
(* dont_touch = "true" *) mult_stage_t mult_pipeline [MULT_LATENCY-1:0];
(* dont_touch = "true" *) logic [MULT_LATENCY-1:0] mult_valid;

localparam ADD_LATENCY = 2;
(* dont_touch = "true" *) add_stage_t add_pipeline [ADD_LATENCY -1:0];
(* dont_touch = "true" *) logic [ADD_LATENCY-1:0] add_valid;

localparam SUB_LATENCY = 2;
(* dont_touch = "true" *) sub_stage_t sub_pipeline [SUB_LATENCY -1:0];
(* dont_touch = "true" *) logic [SUB_LATENCY-1:0] sub_valid;

localparam SCALE_LATENCY = 7;
(* dont_touch = "true" *) logic [SCALE_LATENCY-1:0] intt_scale_valid;

(* dont_touch = "true" *) intt_mult_stage_t intt_mult_a_pipeline [MULT_LATENCY-1:0];
(* dont_touch = "true" *) logic [MULT_LATENCY-1:0] intt_mult_a_valid;
(* dont_touch = "true" *) intt_mult_stage_t intt_mult_b_pipeline [MULT_LATENCY-1:0];
(* dont_touch = "true" *) logic [MULT_LATENCY-1:0] intt_mult_b_valid;
logic [MULT_LATENCY + ADD_LATENCY - 1:0] valid_shift;

logic [K-1:0] mult_result;
logic [K-1:0] intt_mult_a_result;
logic [K-1:0] intt_mult_b_result;
logic [K-1:0] intt_scaled_a_result;
logic [K-1:0] intt_scaled_b_result;
logic [K-1:0] result;
logic [K-1:0] sub_result;
logic [K-1:0] sum;
logic [K-1:0] diff;
logic [K-1:0] ntt_sum;
logic [K-1:0] ntt_diff;

// INTT input pipeline to handle consecutive inputs properly
logic [K-1:0] intt_ina_pipeline [1:0];
logic [K-1:0] intt_inb_pipeline [1:0];
logic [K-1:0] twiddle_delayed [3:0];  // Extended to account for add/sub latency
 logic [3:0] intt_pipeline_valid;       // Extended pipeline
logic [K-1:0] pipelined_sum, pipelined_diff;

mod_multiplication #(.K(K)) multiplier (
    .clk(clk),
    .a(mult_pipeline[0].inb),
    .b(mult_pipeline[0].twiddle_factor),
    .result(mult_result)
);

mod_addition #(.K(K)) add (
    .clk(clk),
    .a(add_pipeline[0].ina),
    .b(add_pipeline[0].inb),
    .mod(q_m),
    .result(sum)
);

mod_subtraction #(.K(K)) sub (
    .clk(clk),
    .a(sub_pipeline[0].ina),
    .b(sub_pipeline[0].inb),
    .mod(q_m),
    .result(diff)
);

mod_addition #(.K(K)) ntt_add (
    .clk(clk),
    .a(ina),
    .b(inb),
    .mod(q_m),
    .result(ntt_sum)
);

mod_subtraction #(.K(K)) ntt_sub (
    .clk(clk),
    .a(ina),
    .b(inb),
    .mod(q_m),
    .result(ntt_diff)
);

// Dedicated pipelined add/sub modules for INTT
mod_addition #(.K(K)) pipelined_add (
    .clk(clk),
    .a(intt_ina_pipeline[1]),
    .b(intt_inb_pipeline[1]),
    .mod(q_m),
    .result(pipelined_sum)
);

mod_subtraction #(.K(K)) pipelined_sub (
    .clk(clk),
    .a(intt_ina_pipeline[1]),
    .b(intt_inb_pipeline[1]),
    .mod(q_m),
    .result(pipelined_diff)
);

mod_multiplication #(.K(K)) intt_mult_a (
    .clk(clk),
    .a(intt_mult_a_pipeline[0].ina),
    .b(intt_mult_a_pipeline[0].twiddle_factor),
    .result(intt_mult_a_result)
);

mod_multiplication #(.K(K)) intt_mult_b (
    .clk(clk),
    .a(intt_mult_b_pipeline[0].inb),
    .b(intt_mult_b_pipeline[0].twiddle_factor),
    .result(intt_mult_b_result)
);

INTT_Scale_Factor #(.K(K)) intt_scale_a (
    .clk(clk),
    .ina(intt_mult_a_result),
    .out(intt_scaled_a_result)
);

INTT_Scale_Factor #(.K(K)) intt_scale_b (
    .clk(clk),
    .ina(intt_mult_b_result),
    .out(intt_scaled_b_result)
);

always_ff @(posedge clk) begin

    if (reset) begin
         for (int i = 0; i < MULT_LATENCY; i++) begin
             mult_pipeline[i] <= '0;
         end
         mult_valid <= '0;

         for (int i = 0; i < ADD_LATENCY; i++) begin
             add_pipeline[i] <= '0;
         end
        add_valid <= '0;

         for (int i = 0; i < SUB_LATENCY; i++) begin
             sub_pipeline[i] <= '0;
         end
        sub_valid <= '0;

         for (int i = 0; i < MULT_LATENCY; i++) begin
             intt_mult_a_pipeline[i] <= '0;
             intt_mult_b_pipeline[i] <= '0;
         end
        intt_mult_a_valid <= '0;
        intt_mult_b_valid <= '0;
        
        intt_scale_valid <= '0;
        valid_shift <= '0;
        
        // Reset INTT input pipelines
        intt_ina_pipeline[0] <= '0;
        intt_ina_pipeline[1] <= '0;
        intt_inb_pipeline[0] <= '0;
        intt_inb_pipeline[1] <= '0;
        for (int i = 0; i < 4; i++) begin
            twiddle_delayed[i] <= '0;
        end
        intt_pipeline_valid <= '0;
    end

    if(start) begin
        if(!is_intt) begin
            mult_pipeline[0].ina <= ina;
            mult_pipeline[0].inb <= inb;
            mult_pipeline[0].twiddle_factor <= twiddle_factor;
            mult_pipeline[0].is_intt<=is_intt;
            mult_valid[0]<=1'b1;
        end else begin
            // INTT will be handled by separate pipeline logic
            mult_valid[0] <= 1'b0;
        end
    end else begin
        mult_valid[0] <= 1'b0;
        intt_mult_a_valid[0] <= 1'b0;
        intt_mult_b_valid[0] <= 1'b0;
    end

    // Pipeline inputs and twiddle factor for INTT
    if(start && is_intt) begin
        // Shift input pipeline 
        intt_ina_pipeline[1] <= intt_ina_pipeline[0];
        intt_inb_pipeline[1] <= intt_inb_pipeline[0];
        
        // Shift extended twiddle pipeline
        for (int i = 3; i > 0; i--) begin
            twiddle_delayed[i] <= twiddle_delayed[i-1];
            intt_pipeline_valid[i] <= intt_pipeline_valid[i-1];
        end
        
        // Load new input
        intt_ina_pipeline[0] <= ina;
        intt_inb_pipeline[0] <= inb;
        twiddle_delayed[0] <= twiddle_factor;
        intt_pipeline_valid[0] <= 1'b1;
    end else if(is_intt) begin
        // Shift pipeline even when not starting new input
        intt_ina_pipeline[1] <= intt_ina_pipeline[0];
        intt_inb_pipeline[1] <= intt_inb_pipeline[0];
        
        for (int i = 3; i > 0; i--) begin
            twiddle_delayed[i] <= twiddle_delayed[i-1];
            intt_pipeline_valid[i] <= intt_pipeline_valid[i-1];
        end
        intt_pipeline_valid[0] <= 1'b0;
    end
    
    // Process INTT when pipelined add/sub results are ready (after additional 2 cycles)
    if(intt_pipeline_valid[3]) begin  // 2 cycles for input + 2 cycles for add/sub = 4 total
        // Start INTT multiplication with properly aligned data
        intt_mult_a_pipeline[0].ina <= pipelined_sum;
        intt_mult_a_pipeline[0].twiddle_factor <= 27'd1;  // No twiddle factor for first output
        intt_mult_a_pipeline[0].is_intt <= 1'b1;
        intt_mult_a_valid[0] <= 1'b1;
        
        intt_mult_b_pipeline[0].inb <= pipelined_diff;
        intt_mult_b_pipeline[0].twiddle_factor <= twiddle_delayed[3];  // Use aligned twiddle factor
        intt_mult_b_pipeline[0].is_intt <= 1'b1;
        intt_mult_b_valid[0] <= 1'b1;
    end else if(is_intt) begin
        intt_mult_a_valid[0] <= 1'b0;
        intt_mult_b_valid[0] <= 1'b0;
    end

    for (int i = MULT_LATENCY-1; i > 0; i--) begin
        mult_pipeline[i] <= mult_pipeline[i-1];
        mult_valid[i] <= mult_valid[i-1];
        
        intt_mult_a_pipeline[i] <= intt_mult_a_pipeline[i-1];
        intt_mult_a_valid[i] <= intt_mult_a_valid[i-1];
        
        intt_mult_b_pipeline[i] <= intt_mult_b_pipeline[i-1];
        intt_mult_b_valid[i] <= intt_mult_b_valid[i-1];
    end

    if(mult_valid[MULT_LATENCY-1]) begin
        add_pipeline[0].ina <= mult_pipeline[MULT_LATENCY-1].ina;
        add_pipeline[0].inb <= mult_result;
        add_pipeline[0].is_intt <= mult_pipeline[MULT_LATENCY-1].is_intt;
        add_valid[0]<=1'b1;
        
        sub_pipeline[0].ina <= mult_pipeline[MULT_LATENCY-1].ina;
        sub_pipeline[0].inb <= mult_result;
        sub_pipeline[0].is_intt <= mult_pipeline[MULT_LATENCY-1].is_intt;
        sub_valid[0]<=1'b1;
    end else begin
        add_valid[0] <= 1'b0;
        sub_valid[0] <= 1'b0;
    end

    for (int i = ADD_LATENCY-1; i > 0; i--) begin
        add_pipeline[i] <= add_pipeline[i-1];
        add_valid[i] <= add_valid[i-1];
    end

    for (int i = SUB_LATENCY-1; i > 0; i--) begin
        sub_pipeline[i] <= sub_pipeline[i-1];
        sub_valid[i] <= sub_valid[i-1];
    end

    if(add_valid[ADD_LATENCY-1]) begin
        result <= sum;
    end
    
    if(sub_valid[SUB_LATENCY-1]) begin
        sub_result <= diff;
    end
    
    // INTT scaling valid pipeline
    for (int i = SCALE_LATENCY-1; i > 0; i--) begin
        intt_scale_valid[i] <= intt_scale_valid[i-1];
    end
    
    // Start scaling when multiplication completes
    intt_scale_valid[0] <= (intt_mult_a_valid[MULT_LATENCY-1] && intt_mult_b_valid[MULT_LATENCY-1]);
end

assign outa = is_intt ? intt_scaled_a_result : result;
assign outb = is_intt ? intt_scaled_b_result : sub_result;
assign complete = is_intt ? intt_scale_valid[SCALE_LATENCY-1] : (add_valid[ADD_LATENCY-1] && sub_valid[SUB_LATENCY-1]);

// Debug signal assignments - these will be preserved by synthesis
assign dbg_input_a = ina;
assign dbg_input_b = inb;
assign dbg_twiddle = twiddle_factor;
assign dbg_mult_result = mult_result;
assign dbg_add_result = result;
assign dbg_sub_result = sub_result;
assign dbg_output_a = outa;
assign dbg_output_b = outb;
assign dbg_is_intt = is_intt;

endmodule




