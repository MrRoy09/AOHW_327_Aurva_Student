`timescale 1ns / 1ps
`include "params.vh"

module ct_pt_mul #(
    parameter N = `N,
    parameter K = `K
) (
    input logic                     clk,
    input logic                     reset,
    input logic                     start,
    
    // Ciphertext inputs: c0 and c1 polynomials
    DPBRAMInterface c0_bram,
    DPBRAMInterface c1_bram,
    
    // Plaintext input: pt polynomial  
    DPBRAMInterface pt_bram_1,
    DPBRAMInterface pt_bram_2,			// for parallelization, same values as pt_bram_1
    
    // Outputs: c0*pt and c1*pt
    DPBRAMInterface c0_pt_bram,
    DPBRAMInterface c1_pt_bram,
    
    output logic                    done
);

    // Internal control signals for pointwise multipliers
    logic start_mult_0, start_mult_1;
    logic done_mult_0, done_mult_1;
    logic core_bram_control_enable_0, core_bram_control_enable_1;
    
    // State machine for coordinating parallel multiplications
    typedef enum logic [1:0] {
        CT_PT_IDLE,
        CT_PT_PROCESSING, 
        CT_PT_DONE
    } ct_pt_state_t;
    
    ct_pt_state_t current_state, next_state;
    
    // State machine
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= CT_PT_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state;
        case (current_state)
            CT_PT_IDLE: begin
                if (start) begin
                    next_state = CT_PT_PROCESSING;
                end
            end
            CT_PT_PROCESSING: begin
                if (done_mult_0 && done_mult_1) begin
                    next_state = CT_PT_DONE;
                end
            end
            CT_PT_DONE: begin
                if (!start) begin
                    next_state = CT_PT_IDLE;
                end
            end
        endcase
    end
    
    // Control logic
    always_ff @(posedge clk) begin
        if (reset) begin
            start_mult_0 <= 1'b0;
            start_mult_1 <= 1'b0;
            core_bram_control_enable_0 <= 1'b0;
            core_bram_control_enable_1 <= 1'b0;
            done <= 1'b0;
        end else begin
            case (current_state)
                CT_PT_IDLE: begin
                    start_mult_0 <= 1'b0;
                    start_mult_1 <= 1'b0;
                    done <= 1'b0;
                end
                CT_PT_PROCESSING: begin
                    if (!start_mult_0 && !start_mult_1) begin
                        start_mult_0 <= 1'b1;
                        start_mult_1 <= 1'b1;
                    end
                end
                CT_PT_DONE: begin
                    start_mult_0 <= 1'b0;
                    start_mult_1 <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end
    
    // First pointwise multiplier: c0 * pt -> c0_pt
    pointwise_mul #(
        .N(N),
        .K(K)
    ) mult_c0_pt (
        .clk(clk),
        .reset(reset),
        .start(start_mult_0),
        .input_bram_1(c0_bram),
        .input_bram_2(pt_bram_1),
        .output_brams(c0_pt_bram),
        .done(done_mult_0)
    );
    
    // Second pointwise multiplier: c1 * pt -> c1_pt  
    pointwise_mul #(
        .N(N),
        .K(K)
    ) mult_c1_pt (
        .clk(clk),
        .reset(reset),
        .start(start_mult_1),
        .input_bram_1(c1_bram),
        .input_bram_2(pt_bram_2),
        .output_brams(c1_pt_bram),
        .done(done_mult_1)
    );

endmodule

