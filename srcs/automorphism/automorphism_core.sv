`timescale 1ns / 1ps
`include "params.vh"

module automorphism_core_lut #(
    parameter N = `N,
    parameter K = `K
) (
    input logic                    clk,
    input logic                    reset,
    input logic                    start,

    DPBRAMInterface input_brams,
    DPBRAMInterface output_brams_1,
    DPBRAMInterface output_brams_2,
    DPBRAMInterface output_brams_3,

    output logic                   done
);

    localparam BATCH_SIZE = 4;
    localparam BATCH_COUNT = N / BATCH_SIZE;
    localparam EVEN_ODD_COUNT = N / 2;
    localparam ADDR_WIDTH = $clog2(EVEN_ODD_COUNT);
    localparam PIPELINE_DEPTH = 3;
    localparam COUNTER_WIDTH = $clog2(BATCH_COUNT + PIPELINE_DEPTH);

    typedef enum logic [2:0] {
        IDLE,
        PROCESSING,
        DONE
    } state_t;

    state_t current_state, next_state;

    logic [COUNTER_WIDTH-1:0] read_counter;
    logic [COUNTER_WIDTH-1:0] write_counter;
    logic processing_complete;

    // Input data from BRAMs
    logic [K-1:0] input_data [BATCH_SIZE];

    // Source indices for current batch
    logic [7:0] source_indices [BATCH_SIZE];

    // Target indices from LUT memory lookups
    logic [K-1:0] target_idx_1 [BATCH_SIZE];
    logic [K-1:0] target_idx_2 [BATCH_SIZE];
    logic [K-1:0] target_idx_3 [BATCH_SIZE];

    // Pipeline registers
    logic [K-1:0] pipeline_data [PIPELINE_DEPTH][BATCH_SIZE];
    logic [K-1:0] pipeline_target_1 [PIPELINE_DEPTH][BATCH_SIZE];
    logic [K-1:0] pipeline_target_2 [PIPELINE_DEPTH][BATCH_SIZE];
    logic [K-1:0] pipeline_target_3 [PIPELINE_DEPTH][BATCH_SIZE];
    logic [COUNTER_WIDTH-1:0] pipeline_write_addr [PIPELINE_DEPTH];
    logic pipeline_valid [PIPELINE_DEPTH];

    // LUT DPBRAM instances for neg1, neg16, neg17
    AutoInterface #(.DLEN(K), .HLEN(8)) lut_neg1_if();
    AutoInterface #(.DLEN(K), .HLEN(8)) lut_neg16_if();
    AutoInterface #(.DLEN(K), .HLEN(8)) lut_neg17_if();

    AutoDPBRAM #(
        .DLEN(K),
        .HLEN(8),
        .EVEN_FILE("neg1_even.mem"),
        .ODD_FILE("neg1_odd.mem")
    ) lut_neg1 (
        .clk(clk),
        .auto_if(lut_neg1_if)
    );

    AutoDPBRAM #(
        .DLEN(K),
        .HLEN(8),
        .EVEN_FILE("neg16_even.mem"),
        .ODD_FILE("neg16_odd.mem")
    ) lut_neg16 (
        .clk(clk),
        .auto_if(lut_neg16_if)
    );

    AutoDPBRAM #(
        .DLEN(K),
        .HLEN(8),
        .EVEN_FILE("neg17_even.mem"),
        .ODD_FILE("neg17_odd.mem")
    ) lut_neg17 (
        .clk(clk),
        .auto_if(lut_neg17_if)
    );

    function automatic logic get_target_parity(input logic [K-1:0] index);
        return index[0]; // 0 = even, 1 = odd
    endfunction

    function automatic logic [ADDR_WIDTH-1:0] get_target_addr(input logic [K-1:0] index);
        return index[7:1]; // Divide by 2
    endfunction

    // LUT address generation and lookups
    always_comb begin
        for (int i = 0; i < BATCH_SIZE; i++) begin
            source_indices[i] = read_counter * BATCH_SIZE + i;
        end

        lut_neg1_if.addr_a[0] = source_indices[0] >> 1;
        lut_neg1_if.addr_b[0] = source_indices[2] >> 1;
        lut_neg1_if.addr_a[1] = source_indices[1] >> 1;
        lut_neg1_if.addr_b[1] = source_indices[3] >> 1;

        lut_neg16_if.addr_a[0] = source_indices[0] >> 1;
        lut_neg16_if.addr_b[0] = source_indices[2] >> 1;
        lut_neg16_if.addr_a[1] = source_indices[1] >> 1;
        lut_neg16_if.addr_b[1] = source_indices[3] >> 1;

        lut_neg17_if.addr_a[0] = source_indices[0] >> 1;
        lut_neg17_if.addr_b[0] = source_indices[2] >> 1;
        lut_neg17_if.addr_a[1] = source_indices[1] >> 1;
        lut_neg17_if.addr_b[1] = source_indices[3] >> 1;
    end

    // Read target indices from LUT memories
    always_comb begin
        target_idx_1[0] = lut_neg1_if.do_a[0];
        target_idx_1[1] = lut_neg1_if.do_a[1];
        target_idx_1[2] = lut_neg1_if.do_b[0];
        target_idx_1[3] = lut_neg1_if.do_b[1];

        target_idx_2[0] = lut_neg16_if.do_a[0];
        target_idx_2[1] = lut_neg16_if.do_a[1];
        target_idx_2[2] = lut_neg16_if.do_b[0];
        target_idx_2[3] = lut_neg16_if.do_b[1];

        target_idx_3[0] = lut_neg17_if.do_a[0];
        target_idx_3[1] = lut_neg17_if.do_a[1];
        target_idx_3[2] = lut_neg17_if.do_b[0];
        target_idx_3[3] = lut_neg17_if.do_b[1];
    end

    // State machine and counters
    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= IDLE;
            read_counter <= 0;
            write_counter <= 0;
            for (int i = 0; i < PIPELINE_DEPTH; i++) begin
                pipeline_valid[i] <= 1'b0;
            end
        end else begin
            current_state <= next_state;

            if (current_state == PROCESSING) begin
                if (read_counter < BATCH_COUNT) begin
                    read_counter <= read_counter + 1;
                end

                // Shift pipeline
                for (int i = PIPELINE_DEPTH-1; i > 0; i--) begin
                    pipeline_valid[i] <= pipeline_valid[i-1];
                    pipeline_write_addr[i] <= pipeline_write_addr[i-1];
                end
                pipeline_valid[0] <= (read_counter < BATCH_COUNT);
                pipeline_write_addr[0] <= read_counter;

                if (pipeline_valid[PIPELINE_DEPTH-1]) begin
                    write_counter <= write_counter + 1;
                end
            end else if (current_state == IDLE) begin
                read_counter <= 0;
                write_counter <= 0;
                for (int i = 0; i < PIPELINE_DEPTH; i++) begin
                    pipeline_valid[i] <= 1'b0;
                end
            end
        end
    end

    always_comb begin
        next_state = current_state;
        processing_complete = (write_counter == BATCH_COUNT);
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = PROCESSING;
                end
            end
            PROCESSING: begin
                if (processing_complete) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end


    always_comb begin
        input_data[0] = input_brams.do_a[0];  // Even coefficient A
        input_data[1] = input_brams.do_a[1];  // Even coefficient B

        input_data[2] = input_brams.do_b[0];  // Odd coefficient A
        input_data[3] = input_brams.do_b[1];  // Odd coefficient B
    end

    always_comb begin
        logic [ADDR_WIDTH-1:0] target_addr_1 [BATCH_SIZE];
        logic target_parity_1 [BATCH_SIZE];
        logic [ADDR_WIDTH-1:0] target_addr_2 [BATCH_SIZE];
        logic target_parity_2 [BATCH_SIZE];
        logic [ADDR_WIDTH-1:0] target_addr_3 [BATCH_SIZE];
        logic target_parity_3 [BATCH_SIZE];

        for (int i = 0; i < BATCH_SIZE; i++) begin
            target_addr_1[i] = get_target_addr(pipeline_target_1[PIPELINE_DEPTH-1][i]);
            target_parity_1[i] = get_target_parity(pipeline_target_1[PIPELINE_DEPTH-1][i]);
            target_addr_2[i] = get_target_addr(pipeline_target_2[PIPELINE_DEPTH-1][i]);
            target_parity_2[i] = get_target_parity(pipeline_target_2[PIPELINE_DEPTH-1][i]);
            target_addr_3[i] = get_target_addr(pipeline_target_3[PIPELINE_DEPTH-1][i]);
            target_parity_3[i] = get_target_parity(pipeline_target_3[PIPELINE_DEPTH-1][i]);
        end

        for (int i = 0; i < 4; i++) begin
            output_brams_1.en[i] = 1'b0;
            output_brams_1.we[i] = 1'b0;
            output_brams_1.addr_a[i] = 0;
            output_brams_1.addr_b[i] = 0;
            output_brams_1.di_a[i] = 0;
            output_brams_1.di_b[i] = 0;

            output_brams_2.en[i] = 1'b0;
            output_brams_2.we[i] = 1'b0;
            output_brams_2.addr_a[i] = 0;
            output_brams_2.addr_b[i] = 0;
            output_brams_2.di_a[i] = 0;
            output_brams_2.di_b[i] = 0;

            output_brams_3.en[i] = 1'b0;
            output_brams_3.we[i] = 1'b0;
            output_brams_3.addr_a[i] = 0;
            output_brams_3.addr_b[i] = 0;
            output_brams_3.di_a[i] = 0;
            output_brams_3.di_b[i] = 0;
        end

        if (pipeline_valid[PIPELINE_DEPTH-1]) begin
                    for (int i = 0; i < 2; i++) begin
                    output_brams_1.en[i] = 1'b1;
                    output_brams_1.we[i] = 1'b1;

                    output_brams_2.en[i] = 1'b1;
                    output_brams_2.we[i] = 1'b1;

                    output_brams_3.en[i] = 1'b1;
                    output_brams_3.we[i] = 1'b1;
                end
                    output_brams_1.addr_a[0] = pipeline_target_1[PIPELINE_DEPTH - 1][0] >> 1;
                    output_brams_1.addr_a[1] = pipeline_target_1[PIPELINE_DEPTH - 1][1] >> 1;
                    output_brams_1.addr_b[0] = pipeline_target_1[PIPELINE_DEPTH - 1][2] >> 1;
                    output_brams_1.addr_b[1] = pipeline_target_1[PIPELINE_DEPTH - 1][3] >> 1;
                    output_brams_1.di_a[0] = pipeline_data[PIPELINE_DEPTH - 1][0];
                    output_brams_1.di_a[1] = pipeline_data[PIPELINE_DEPTH - 1][1];
                    output_brams_1.di_b[0] = pipeline_data[PIPELINE_DEPTH - 1][2];
                    output_brams_1.di_b[1] = pipeline_data[PIPELINE_DEPTH - 1][3];

                    output_brams_2.addr_a[0] = pipeline_target_2[PIPELINE_DEPTH - 1][0] >> 1;
                    output_brams_2.addr_a[1] = pipeline_target_2[PIPELINE_DEPTH - 1][1] >> 2;
                    output_brams_2.addr_b[0] = pipeline_target_2[PIPELINE_DEPTH - 1][2] >> 1;
                    output_brams_2.addr_b[1] = pipeline_target_2[PIPELINE_DEPTH - 1][3] >> 2;
                    output_brams_2.di_a[0] = pipeline_data[PIPELINE_DEPTH - 1][0];
                    output_brams_2.di_a[1] = pipeline_data[PIPELINE_DEPTH - 1][1];
                    output_brams_2.di_b[0] = pipeline_data[PIPELINE_DEPTH - 1][2];
                    output_brams_2.di_b[1] = pipeline_data[PIPELINE_DEPTH - 1][3];


                    output_brams_3.addr_a[0] = pipeline_target_3[PIPELINE_DEPTH - 1][0] >> 1;
                    output_brams_3.addr_a[1] = pipeline_target_3[PIPELINE_DEPTH - 1][1] >> 1;
                    output_brams_3.addr_b[0] = pipeline_target_3[PIPELINE_DEPTH - 1][2] >> 1;
                    output_brams_3.addr_b[1] = pipeline_target_3[PIPELINE_DEPTH - 1][3] >> 1;
                    output_brams_3.di_a[0] = pipeline_data[PIPELINE_DEPTH - 1][0];
                    output_brams_3.di_a[1] = pipeline_data[PIPELINE_DEPTH - 1][1];
                    output_brams_3.di_b[0] = pipeline_data[PIPELINE_DEPTH - 1][2];
                    output_brams_3.di_b[1] = pipeline_data[PIPELINE_DEPTH - 1][3];
            end
        end


    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < PIPELINE_DEPTH; i++) begin
                for (int j = 0; j < BATCH_SIZE; j++) begin
                    pipeline_data[i][j] <= 0;
                    pipeline_target_1[i][j] <= 0;
                    pipeline_target_2[i][j] <= 0;
                    pipeline_target_3[i][j] <= 0;
                end
            end
        end else if (current_state == PROCESSING) begin
            if (pipeline_valid[0]) begin
                for (int j = 0; j < BATCH_SIZE; j++) begin
                    pipeline_data[0][j] <= input_data[j];
                    pipeline_target_1[0][j] <= target_idx_1[j];
                    pipeline_target_2[0][j] <= target_idx_2[j];
                    pipeline_target_3[0][j] <= target_idx_3[j];
                end
            end

            for (int i = PIPELINE_DEPTH-1; i > 0; i--) begin
                if (pipeline_valid[i-1]) begin
                    for (int j = 0; j < BATCH_SIZE; j++) begin
                        pipeline_data[i][j] <= pipeline_data[i-1][j];
                        pipeline_target_1[i][j] <= pipeline_target_1[i-1][j];
                        pipeline_target_2[i][j] <= pipeline_target_2[i-1][j];
                        pipeline_target_3[i][j] <= pipeline_target_3[i-1][j];
                    end
                end
            end
        end
    end

    always_comb begin
        done = (current_state == DONE);
    end

endmodule
