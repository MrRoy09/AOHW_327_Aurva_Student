

`timescale 1ns/1ps
`include "params.vh"

module NTT_Controller_Pipelined #(
    parameter K = 32,
    parameter N = 256,
    parameter N_bits = 8
)(
    input clk,
    input reset,
    input start,
    input is_intt,
    output logic done,
    DPBRAMInterface poly_brams,
    TwiddleBRAMInterface tf_brams
);

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

// Pipeline shift register for index data
localparam ADDR_LATENCY = 2;
localparam PIPE_DEPTH = ADDR_LATENCY; // With ADDR_LATENCY=1, gives 3 stages total

ntt_pipeline_data_t pipeline_shift_reg [PIPE_DEPTH-1:0];
logic pipeline_valid [PIPE_DEPTH-1:0];

// Combined data for address generator stage
ntt_pipeline_data_t combined_data;
logic combined_valid;

// Computation unit data (final stage with BRAM data)
ntt_pipeline_data_t computation_unit;
logic computation_unit_valid;
ntt_pipeline_data_t combined_data_delayed;

// Butterfly unit pipeline (20-cycle latency for INTT, 13-cycle for NTT)
localparam BUTTERFLY_LATENCY_NTT = 13;
localparam BUTTERFLY_LATENCY_INTT = 21;
localparam MAX_BUTTERFLY_LATENCY = 21; // Use max for array sizing
logic butterfly_valid_shift_reg [MAX_BUTTERFLY_LATENCY-1:0];
ntt_pipeline_data_t butterfly_data_shift_reg [MAX_BUTTERFLY_LATENCY-1:0];

// Write-back unit data (butterfly outputs ready for memory write)
ntt_pipeline_data_t write_back_unit;
ntt_pipeline_data_t write_back_unit_delayed;
logic write_back_unit_valid;
logic write_back_delayed;
logic memory_write_back;
logic any_butterfly_valid;


logic [N_bits:0] i, j, m, counter;
logic [N_bits:0] current_pair;      
logic [N_bits:0] pairs_per_group;
logic [K-1:0] mod_q;

// Pipelined address generator signals
logic addr_gen_enable, addr_gen_valid;
logic [K-1:0] addr_index1, addr_index2, addr_index3, addr_index4;
logic [K-1:0] addr_tf_index1, addr_tf_index2;

// Loop control combinational signals
logic advance_pair, advance_j, advance_i, ntt_complete;
logic [N_bits:0] next_i, next_j, next_current_pair, next_counter;
logic [N_bits:0] next_m, next_pairs_per_group;

// Butterfly unit control signals
logic [K-1:0] btfu1_output1, btfu1_output2, btfu2_output1, btfu2_output2;
logic start_btf_unit1, start_btf_unit2, complete_btf_unit1, complete_btf_unit2;
logic reset_butterfly1, reset_butterfly2;
logic [4:0] current_butterfly_latency;

// Pipeline control
logic stage0_enable;
logic pipeline_stall;
logic stall_reason; // 0: advance_i, 1: ntt_complete

AddressControlUnit_Pipelined #(
    .N(N),
    .N_bits(N_bits)
) addr_gen_pipe (
    .clk(clk),
    .reset(reset),
    .enable(addr_gen_enable),
    .is_intt(is_intt),
    .i(i),
    .j(j),
    .m(m),
    .counter(counter),
    .current_pair(current_pair),
    .index1(addr_index1),
    .index2(addr_index2),
    .index3(addr_index3),
    .index4(addr_index4),
    .tf_index1(addr_tf_index1),
    .tf_index2(addr_tf_index2),
    .valid(addr_gen_valid)
);

CTNTTButterfly_Pipeline #(.K(27)) uut (
    .clk(clk),
    .start(start_btf_unit1),
    .reset(reset_butterfly1 || reset),
    .ina(computation_unit.poly1),
    .inb(computation_unit.poly2),
    .q_m(mod_q),
    .twiddle_factor(computation_unit.tf1),
    .is_intt(is_intt),
    .outa(btfu1_output1),
    .outb(btfu1_output2),
    .complete(complete_btf_unit1),
    .dbg_input_a(dbg_btf1_input_a),
    .dbg_input_b(dbg_btf1_input_b),
    .dbg_twiddle(dbg_btf1_twiddle),
    .dbg_mult_result(dbg_btf1_mult_result),
    .dbg_output_a(dbg_btf1_output_a),
    .dbg_output_b(dbg_btf1_output_b),
    .dbg_is_intt(dbg_btf1_is_intt)
);

CTNTTButterfly_Pipeline #(.K(27)) uut2 (
    .clk(clk),
    .start(start_btf_unit2),
    .reset(reset_butterfly2 || reset),
    .ina(computation_unit.poly3),
    .inb(computation_unit.poly4),
    .q_m(mod_q),
    .twiddle_factor(computation_unit.tf2),
    .is_intt(is_intt),
    .outa(btfu2_output1),
    .outb(btfu2_output2),
    .complete(complete_btf_unit2),
    .dbg_input_a(),
    .dbg_input_b(), 
    .dbg_twiddle(),
    .dbg_mult_result(),
    .dbg_output_a(),
    .dbg_output_b(),
    .dbg_is_intt()
);

// Pipeline control logic
always_ff @(posedge clk) begin
        if ((advance_i || ntt_complete) && !pipeline_stall) begin
        pipeline_stall <= 1'b1;
        stall_reason <= ntt_complete; // Capture reason for stall
        // Update loop variables only for advance_i
        // if (advance_i) begin
        //     i <= is_intt ? i - 1 : i + 1;
        //     j <= 0;
        //     current_pair <= 0;
        //     counter <= 0;
        // end
        end else if (pipeline_stall && !any_butterfly_valid && !write_back_unit_valid && !memory_write_back) begin
        pipeline_stall <= 1'b0;
        // Handle completion cleanup when stall was due to ntt_complete
        if (stall_reason) begin
            done <= 1'b1;
            // Cleanup signals
            reset_butterfly1 <= 1;
            reset_butterfly2 <= 1;
            start_btf_unit1 <= 0;
            start_btf_unit2 <= 0;
            poly_brams.we[0] <= 1'b0;
            poly_brams.we[1] <= 1'b0;
            poly_brams.we[2] <= 1'b0;
            poly_brams.we[3] <= 1'b0;
            addr_gen_enable <= 0;
            memory_write_back <= 0;
        end
    end
    if (reset) begin
        // Pipeline control
        pipeline_stall <= 1'b0;
        stall_reason <= 0;
        
        // Loop control variables
        i <= is_intt ? N_bits-1 : 0;
        j <= 0;
        current_pair <= 0;
        counter <= 0;
        m <= is_intt ? N : 2;
        pairs_per_group <= is_intt ? N/2 : 1;
        done <= 0;
        
        // Butterfly control signals
        start_btf_unit1 <= 0;
        start_btf_unit2 <= 0;
        reset_butterfly1 <= 1;
        reset_butterfly2 <= 1;
        
        // Address generator control
        addr_gen_enable <= 0;
        stage0_enable <= 0;
        mod_q <= `Q;
        
        // BRAM interface controls
        poly_brams.en[0] <= 1'b0;
        poly_brams.en[1] <= 1'b0;
        poly_brams.en[2] <= 1'b0;
        poly_brams.en[3] <= 1'b0;
        poly_brams.we[0] <= 1'b0;
        poly_brams.we[1] <= 1'b0;
        poly_brams.we[2] <= 1'b0;
        poly_brams.we[3] <= 1'b0;
        poly_brams.reset <= 1;
        
        // Reset BRAM address and data signals
        for (int k = 0; k < 4; k++) begin
            poly_brams.addr_a[k] <= 0;
            poly_brams.addr_b[k] <= 0;
            poly_brams.di_a[k] <= 0;
            poly_brams.di_b[k] <= 0;
        end
        
        // Reset twiddle factor interface
        tf_brams.raddra <= 0;
        tf_brams.raddrb <= 0;
        
        // Reset pipeline shift registers
        for (int k = 0; k < PIPE_DEPTH; k++) begin
            pipeline_shift_reg[k] <= '0;
            pipeline_valid[k] <= 0;
        end
        
        // Reset stage data
        combined_data <= '0;
        combined_valid <= 0;
        computation_unit <= '0;
        computation_unit_valid <= 0;
        combined_data_delayed <= '0;
        
        // Reset butterfly pipeline
        for (int k = 0; k < MAX_BUTTERFLY_LATENCY; k++) begin
            butterfly_valid_shift_reg[k] <= 0;
            butterfly_data_shift_reg[k] <= '0;
        end
        current_butterfly_latency <= is_intt ? BUTTERFLY_LATENCY_INTT : BUTTERFLY_LATENCY_NTT;
        
        // Reset write-back stage
        write_back_unit <= '0;
        write_back_unit_valid <= 0;
        write_back_unit_delayed <= '0;
        write_back_delayed <= 0;
        memory_write_back <= 0;
    end
    else if(start) begin
        poly_brams.en[0] <= 1'b1;
        poly_brams.en[1] <= 1'b1;
        poly_brams.en[2] <=1'b1;
        poly_brams.en[3] <=1'b1;
        poly_brams.reset<=0;
        if(!pipeline_stall) begin
            addr_gen_enable <= 1'b1;
            stage0_enable<=1;
        end
        else begin
            addr_gen_enable<=0;
            stage0_enable<=0;
        end


        for (int k = PIPE_DEPTH-1; k > 0; k--) begin
            pipeline_shift_reg[k] <= pipeline_shift_reg[k-1];
            pipeline_valid[k] <= pipeline_valid[k-1];
        end

        if (stage0_enable) begin
            pipeline_shift_reg[0].is_intt <= is_intt;
            pipeline_shift_reg[0].i <= i;
            pipeline_shift_reg[0].j <= j;
            pipeline_shift_reg[0].current_pair <= current_pair;
            pipeline_shift_reg[0].m <= m;
            pipeline_shift_reg[0].counter <= counter;
            pipeline_shift_reg[0].stage <= 0;
            pipeline_shift_reg[0].mod_q <= mod_q;
            pipeline_valid[0] <= 1;
            
            i <= next_i;
            j <= next_j;
            current_pair <= next_current_pair;
            counter <= next_counter;
            m <= next_m;
            pairs_per_group <= next_pairs_per_group;
        end else begin
            pipeline_valid[0] <= 0;
        end

        if (pipeline_valid[PIPE_DEPTH-1] && addr_gen_valid) begin
            combined_data <= pipeline_shift_reg[PIPE_DEPTH-1];
            
            combined_data.index1 <= addr_index1;
            combined_data.index2 <= addr_index2;
            combined_data.index3 <= addr_index3;
            combined_data.index4 <= addr_index4;
            combined_data.tf_index1 <= addr_tf_index1;
            combined_data.tf_index2 <= addr_tf_index2;
            combined_data.stage <= 1;
            combined_valid <= 1;

            // For INTT, reverse the BRAM pair selection
            poly_brams.addr_a[0+(is_intt ? !pipeline_shift_reg[PIPE_DEPTH-1].i[0] : pipeline_shift_reg[PIPE_DEPTH-1].i[0])*2] <= addr_index1;
            poly_brams.addr_a[1+(is_intt ? !pipeline_shift_reg[PIPE_DEPTH-1].i[0] : pipeline_shift_reg[PIPE_DEPTH-1].i[0])*2] <= addr_index2;
            poly_brams.addr_b[0+(is_intt ? !pipeline_shift_reg[PIPE_DEPTH-1].i[0] : pipeline_shift_reg[PIPE_DEPTH-1].i[0])*2] <= addr_index3;
            poly_brams.addr_b[1+(is_intt ? !pipeline_shift_reg[PIPE_DEPTH-1].i[0] : pipeline_shift_reg[PIPE_DEPTH-1].i[0])*2] <= addr_index4;
            
            tf_brams.raddra <= addr_tf_index1;
            tf_brams.raddrb <= addr_tf_index2;
        end else begin
            combined_valid <= 0;
        end

        if (combined_valid) begin
            combined_data_delayed <= combined_data;
        end
        computation_unit_valid <= combined_valid;
        
        if (computation_unit_valid) begin
            computation_unit <= combined_data_delayed;
            
            // Capture BRAM data (now valid due to 1-cycle delay)
            // For INTT, reverse the BRAM pair selection
            if (combined_data_delayed.i == 0) begin
                computation_unit.poly1 <= poly_brams.do_a[0+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
                computation_unit.poly2 <= poly_brams.do_a[1+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
                computation_unit.poly3 <= poly_brams.do_b[0+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
                computation_unit.poly4 <= poly_brams.do_b[1+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
            end else begin
                computation_unit.poly1 <= poly_brams.do_a[0+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
                computation_unit.poly2 <= poly_brams.do_b[0+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
                computation_unit.poly3 <= poly_brams.do_a[1+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
                computation_unit.poly4 <= poly_brams.do_b[1+(is_intt ? !combined_data_delayed.i[0] : combined_data_delayed.i[0])*2];
            end
            
            computation_unit.tf1 <= tf_brams.douta;
            computation_unit.tf2 <= tf_brams.doutb;
            computation_unit.stage <= 2;
        end
        
        for (int k = MAX_BUTTERFLY_LATENCY-1; k > 0; k--) begin
            butterfly_valid_shift_reg[k] <= butterfly_valid_shift_reg[k-1];
            butterfly_data_shift_reg[k] <= butterfly_data_shift_reg[k-1];
        end
        
        start_btf_unit1 <= computation_unit_valid;
        start_btf_unit2 <= computation_unit_valid;
        reset_butterfly1 <= 0;  // Keep butterflies always active
        reset_butterfly2 <= 0;
        
        if (computation_unit_valid) begin
            butterfly_valid_shift_reg[0] <= 1;
            butterfly_data_shift_reg[0] <= computation_unit;
        end else begin
            butterfly_valid_shift_reg[0] <= 0;
        end
        
        if (butterfly_valid_shift_reg[current_butterfly_latency-1]) begin
            write_back_unit_delayed <= butterfly_data_shift_reg[current_butterfly_latency-1];
            write_back_delayed<=1;
            write_back_unit_valid<=1;
        end

        else begin
            write_back_delayed<=0;
            write_back_unit_valid<=0;
        end
        
        if(write_back_delayed) begin
            write_back_unit <= write_back_unit_delayed;
            write_back_unit.btfu1_output1 <= btfu1_output1;
            write_back_unit.btfu1_output2 <= btfu1_output2;
            write_back_unit.btfu2_output1 <= btfu2_output1;
            write_back_unit.btfu2_output2 <= btfu2_output2;
            write_back_unit.stage <= 3; 
            memory_write_back <=1;
        end else begin
            memory_write_back <=0;
        end

        if (memory_write_back) begin
            // For INTT, reverse the BRAM pair selection for writes
            poly_brams.we[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= 1'b1;
            poly_brams.we[1+ 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= 1'b1;
            if (write_back_unit.i == 0) begin
                poly_brams.addr_a[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index1;
                poly_brams.addr_a[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index2;
                poly_brams.addr_b[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index3;
                poly_brams.addr_b[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index4;

                poly_brams.di_a[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu1_output1;
                poly_brams.di_a[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu1_output2;
                poly_brams.di_b[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu2_output1;
                poly_brams.di_b[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu2_output2;
            end else begin  
                poly_brams.addr_a[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index1;
                poly_brams.addr_b[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index3;
                poly_brams.addr_a[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index2;
                poly_brams.addr_b[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.index4;

                poly_brams.di_a[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu1_output1;
                poly_brams.di_b[0 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu1_output2;
                poly_brams.di_a[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu2_output1;
                poly_brams.di_b[1 + 2*(write_back_unit.is_intt ? write_back_unit.i[0] : !write_back_unit.i[0])] <= write_back_unit.btfu2_output2;
            end
        end else begin
            poly_brams.we[0] <= 1'b0;
            poly_brams.we[1] <= 1'b0;
            poly_brams.we[2] <= 1'b0;
            poly_brams.we[3] <= 1'b0;
        end
    end
end


always_comb begin
    any_butterfly_valid = 1'b0;
    for (int k = 0; k < MAX_BUTTERFLY_LATENCY; k++) begin
        any_butterfly_valid |= butterfly_valid_shift_reg[k];
    end
end

//always_ff @(posedge clk) begin
//    if (reset) begin
//        pipeline_stall <= 1'b0;
//        stall_reason <= 0;
//    end else if ((advance_i || ntt_complete) && !pipeline_stall) begin
//        pipeline_stall <= 1'b1;
//        stall_reason <= ntt_complete; // Capture reason for stall
//        // Update loop variables only for advance_i
//        // if (advance_i) begin
//        //     i <= is_intt ? i - 1 : i + 1;
//        //     j <= 0;
//        //     current_pair <= 0;
//        //     counter <= 0;
//        // end
//    end else if (pipeline_stall && !any_butterfly_valid && !write_back_unit_valid && !memory_write_back) begin
//        pipeline_stall <= 1'b0;
//        // Handle completion cleanup when stall was due to ntt_complete
//        if (stall_reason) begin
//            done <= 1'b1;
//            // Cleanup signals
//            reset_butterfly1 <= 1;
//            reset_butterfly2 <= 1;
//            start_btf_unit1 <= 0;
//            start_btf_unit2 <= 0;
//            poly_brams.we[0] <= 1'b0;
//            poly_brams.we[1] <= 1'b0;
//            poly_brams.we[2] <= 1'b0;
//            poly_brams.we[3] <= 1'b0;
//            addr_gen_enable <= 0;
//            memory_write_back <= 0;
//        end
//    end
//end

always_comb begin
    advance_pair = (current_pair + 2 < pairs_per_group) && !pipeline_stall;
    advance_j = !advance_pair && (j + m < N) && !pipeline_stall;
    advance_i = !advance_pair && !advance_j && ((is_intt && i > 0) || (!is_intt && i < N_bits-1)) && !pipeline_stall;
    
    if (advance_pair) begin
        next_current_pair = current_pair + 2;
        next_counter = (i == 0 || i == 1) ? counter + 2 : counter + 1;
        next_i = i;
        next_j = j;
        next_m = m;
        next_pairs_per_group = pairs_per_group;
    end
    else if (advance_j) begin
        next_j = j + m;
        next_current_pair = 0;
        next_counter = counter + ((i == 0 || i == 1) ? 2 : (m>>2) + 1);
        next_i = i;
        next_m = m;
        next_pairs_per_group = pairs_per_group;
    end
    else if (advance_i) begin
        next_i = is_intt ? i-1 : i+1;
        next_j = 0;
        next_current_pair = 0;
        next_counter = 0;
        next_m = is_intt ? (N>>(7-(i-1))) : 1<<(i+2);
        next_pairs_per_group = is_intt ? (1<<(i-1)) : 1<<(i+1);

    end else begin
        // Default case - no advancement
        next_i = i;
        next_j = j;
        next_current_pair = current_pair;
        next_counter = counter;
        next_m = m;
        next_pairs_per_group = pairs_per_group;
    end
    
    // NTT completion logic
    ntt_complete = !advance_pair && !advance_j && !advance_i && !pipeline_stall;
end

// assign dbg_comp_i = computation_unit.i;
// assign dbg_comp_j = computation_unit.j;
// assign dbg_comp_current_pair = computation_unit.current_pair;
// assign dbg_comp_m = computation_unit.m;
// assign dbg_comp_counter = computation_unit.counter;
// assign dbg_comp_index1 = computation_unit.index1;
// assign dbg_comp_index2 = computation_unit.index2;
// assign dbg_comp_index3 = computation_unit.index3;
// assign dbg_comp_index4 = computation_unit.index4;
// assign dbg_comp_tf_index1 = computation_unit.tf_index1;
// assign dbg_comp_tf_index2 = computation_unit.tf_index2;
 assign dbg_comp_poly1 = computation_unit.poly1;
 assign dbg_comp_poly2 = computation_unit.poly2;
 assign dbg_comp_poly3 = computation_unit.poly3;
 assign dbg_comp_poly4 = computation_unit.poly4;
// assign dbg_comp_tf1 = computation_unit.tf1;
// assign dbg_comp_tf2 = computation_unit.tf2;
// assign dbg_comp_valid = computation_unit_valid;

endmodule
