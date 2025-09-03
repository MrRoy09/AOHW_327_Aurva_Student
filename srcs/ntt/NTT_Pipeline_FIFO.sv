`timescale 1ns/1ps
`include "params.vh"

// NTT Pipeline Data Structure
typedef struct packed {
    // Control signals
    logic is_intt;
    logic [7:0] i;
    logic [7:0] j;
    logic [7:0] current_pair;
    logic [7:0] m;
    logic [7:0] counter;
    
    // Memory addresses
    logic [31:0] index1;
    logic [31:0] index2;
    logic [31:0] index3;
    logic [31:0] index4;
    logic [31:0] tf_index1;
    logic [31:0] tf_index2;
    
    // Polynomial coefficients
    logic [31:0] poly1;
    logic [31:0] poly2;
    logic [31:0] poly3;
    logic [31:0] poly4;
    
    // Twiddle factors
    logic [31:0] tf1;
    logic [31:0] tf2;
    
    // Butterfly outputs
    logic [31:0] btfu1_output1;
    logic [31:0] btfu1_output2;
    logic [31:0] btfu2_output1;
    logic [31:0] btfu2_output2;
    
    // Pipeline stage control
    logic [1:0] stage;
    logic valid;
    logic butterfly_started;
    logic butterfly_complete;
    
    // Modular arithmetic parameter
    logic [31:0] mod_q;
} ntt_pipeline_data_t;

// NTT Pipeline FIFO Interface
interface NTTPipelineFIFOInterface(input logic clk);
    // Data signals
    ntt_pipeline_data_t write_data;
    ntt_pipeline_data_t read_data;
    
    // Control signals
    logic write_en;
    logic read_en;
    logic enable;
    logic clear;
    
    // Status signals
    logic full;
    logic empty;
    logic [3:0] count;
    
endinterface

// NTT Pipeline FIFO Module
module NTTPipelineFIFO #(
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input logic clk,
    input logic reset,
    NTTPipelineFIFOInterface fifo_if
);

    // Internal FIFO storage
    ntt_pipeline_data_t fifo_mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] rd_ptr, wr_ptr;
    logic [ADDR_WIDTH:0] fifo_count;
    
    // Status flags
    assign fifo_if.full = (fifo_count == DEPTH);
    assign fifo_if.empty = (fifo_count == 0);
    assign fifo_if.count = fifo_count;
    
    always_ff @(posedge clk) begin
        if (reset || fifo_if.clear) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            fifo_count <= 0;
            fifo_if.read_data <= '0;
        end else if (fifo_if.enable) begin
            // Write operation
            if (fifo_if.write_en && !fifo_if.full) begin
                fifo_mem[wr_ptr] <= fifo_if.write_data;
                wr_ptr <= (wr_ptr + 1) % DEPTH;
            end
            
            // Read operation
            if (fifo_if.read_en && !fifo_if.empty) begin
                fifo_if.read_data <= fifo_mem[rd_ptr];
                rd_ptr <= (rd_ptr + 1) % DEPTH;
            end
            
            // Update count
            case ({fifo_if.write_en && !fifo_if.full, fifo_if.read_en && !fifo_if.empty})
                2'b10: fifo_count <= fifo_count + 1;    // Write only
                2'b01: fifo_count <= fifo_count - 1;    // Read only
                2'b11: fifo_count <= fifo_count;        // Both (no change)
                2'b00: fifo_count <= fifo_count;        // Neither
            endcase
        end
    end

endmodule
