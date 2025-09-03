`timescale 1ns / 1ps
`include "params.vh"

module ct_ct_add #(
    parameter N = `N,
    parameter K = `K
) (
    input logic                     clk,
    input logic                     reset,
    input logic                     start,
    
    DPBRAMInterface c0_bram_1,
    DPBRAMInterface c1_bram_1,
    
    DPBRAMInterface c0_bram_2,
    DPBRAMInterface c1_bram_2,
    
    DPBRAMInterface c0_bram,
    DPBRAMInterface c1_bram,
    
    output logic                    done
);

    logic start_add_0, start_add_1;
    logic done_add_0, done_add_1;
    
    typedef enum logic [1:0] {
        CT_CT_IDLE,
        CT_CT_PROCESSING, 
        CT_CT_DONE
    } ct_ct_state_t;
    
    ct_ct_state_t current_state, next_state;
    
    // State machine
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= CT_CT_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state;
        case (current_state)
            CT_CT_IDLE: begin
                if (start) begin
                    next_state = CT_CT_PROCESSING;
                end
            end
            CT_CT_PROCESSING: begin
                if (done_add_0 && done_add_1) begin
                    next_state = CT_CT_DONE;
                end
            end
            CT_CT_DONE: begin
                if (!start) begin
                    next_state = CT_CT_IDLE;
                end
            end
        endcase
    end
    
    // Control logic
    always_ff @(posedge clk) begin
        if (reset) begin
            start_add_0 <= 1'b0;
            start_add_1 <= 1'b0;
            done <= 1'b0;
        end else begin
            case (current_state)
                CT_CT_IDLE: begin
                    start_add_0 <= 1'b0;
                    start_add_1 <= 1'b0;
                    done <= 1'b0;
                end
                CT_CT_PROCESSING: begin
                    if (!start_add_0 && !start_add_1) begin
                        start_add_0 <= 1'b1;
                        start_add_1 <= 1'b1;
                    end
                end
                CT_CT_DONE: begin
                    start_add_0 <= 1'b0;
                    start_add_1 <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end
    
    poly_add #(
        .N(N),
        .K(K)
    ) add_c0 (
        .clk(clk),
        .reset(reset),
        .start(start_add_0),
        .input_bram_1(c0_bram_1),
        .input_bram_2(c0_bram_2),
        .output_brams(c0_bram),
        .done(done_add_0)
    );
    
    poly_add #(
        .N(N),
        .K(K)
    ) add_c1 (
        .clk(clk),
        .reset(reset),
        .start(start_add_1),
        .input_bram_1(c1_bram_1),
        .input_bram_2(c1_bram_2),
        .output_brams(c1_bram),
        .done(done_add_1)
    );

endmodule


