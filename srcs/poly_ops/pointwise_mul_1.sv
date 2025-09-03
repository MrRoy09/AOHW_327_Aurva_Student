`timescale 1ns / 1ps
`include "params.vh"

module pointwise_mul1 #(
	parameter N = `N,
	parameter K = `K
) (
	input logic				clk,
	input logic				reset,
	input logic				start,
	DPBRAMInterface				input_bram_1,
	DPBRAMInterface1				input_bram_2,

	DPBRAMInterface				output_brams,

	output logic				done
);


	localparam BATCH_SIZE = 4;
	localparam BATCH_COUNT = N / BATCH_SIZE;
	localparam EVEN_ODD_COUNT = N / 2;
	localparam ADDR_WIDTH = $clog2(EVEN_ODD_COUNT);
	localparam PIPELINE_DEPTH = 11;
	localparam COUNTER_WIDTH = $clog2(BATCH_COUNT + PIPELINE_DEPTH);

	typedef enum logic [2 : 0] {
		IDLE,
		PROCESSING,
		DONE
	} state_t;

	state_t current_state, next_state;

	logic [COUNTER_WIDTH-1:0] read_counter;
	logic [COUNTER_WIDTH-1:0] write_counter;
	logic processing_complete;
	//logic pipeline_active;

	logic [K-1:0] mult_a [BATCH_SIZE];
	logic [K-1:0] mult_b [BATCH_SIZE];
	logic [K-1:0] mult_result [BATCH_SIZE];

	logic [K-1:0] pipeline_reg_a [PIPELINE_DEPTH][BATCH_SIZE];
	logic [K-1:0] pipeline_reg_b [PIPELINE_DEPTH][BATCH_SIZE];
	logic [COUNTER_WIDTH-1:0] pipeline_write_addr [PIPELINE_DEPTH];
	logic pipeline_valid [PIPELINE_DEPTH];

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
		logic [ADDR_WIDTH-1:0] even_addr, odd_addr, out_even_addr, out_odd_addr;

		even_addr = read_counter*2;
		odd_addr = read_counter*2;
		out_even_addr = (pipeline_write_addr[PIPELINE_DEPTH-1])*2;
		out_odd_addr = (pipeline_write_addr[PIPELINE_DEPTH-1])*2;

		input_bram_1.en[0] = (current_state == PROCESSING && read_counter < BATCH_COUNT);
		input_bram_1.we[0] = 1'b0;
		input_bram_1.addr_a[0] = even_addr;
		input_bram_1.addr_b[0] = even_addr + 1;

		input_bram_1.en[1] = (current_state == PROCESSING && read_counter < BATCH_COUNT);
		input_bram_1.we[1] = 1'b0;
		input_bram_1.addr_a[1] = odd_addr;
		input_bram_1.addr_b[1] = odd_addr + 1;

		input_bram_1.en[2] = 1'b0;
		input_bram_1.we[2] = 1'b0;
		input_bram_1.addr_a[2] = 0;
		input_bram_1.addr_b[2] = 0;

		input_bram_1.en[3] = 1'b0;
		input_bram_1.we[3] = 1'b0;
		input_bram_1.addr_a[3] = 0;
		input_bram_1.addr_b[3] = 0;

		input_bram_2.en[0] = (current_state == PROCESSING && read_counter < BATCH_COUNT);
		input_bram_2.we[0] = 1'b0;
		input_bram_2.addr_a[0] = even_addr;
		input_bram_2.addr_b[0] = even_addr + 1;

		input_bram_2.en[1] = (current_state == PROCESSING && read_counter < BATCH_COUNT);
		input_bram_2.we[1] = 1'b0;
		input_bram_2.addr_a[1] = odd_addr;
		input_bram_2.addr_b[1] = odd_addr + 1;

		input_bram_2.en[2] = 1'b0;
		input_bram_2.we[2] = 1'b0;
		input_bram_2.addr_a[2] = 0;
		input_bram_2.addr_b[2] = 0;

		input_bram_2.en[3] = 1'b0;
		input_bram_2.we[3] = 1'b0;
		input_bram_2.addr_a[3] = 0;
		input_bram_2.addr_b[3] = 0;

		output_brams.en[0] = pipeline_valid[PIPELINE_DEPTH-1];
		output_brams.we[0] = pipeline_valid[PIPELINE_DEPTH-1];
		output_brams.addr_a[0] = out_even_addr;
		output_brams.addr_b[0] = out_even_addr + 1;
		output_brams.di_a[0] = mult_result[0];
		output_brams.di_b[0] = mult_result[2];

		output_brams.en[1] = pipeline_valid[PIPELINE_DEPTH-1];
		output_brams.we[1] = pipeline_valid[PIPELINE_DEPTH-1];
		output_brams.addr_a[1] = out_odd_addr;
		output_brams.addr_b[1] = out_odd_addr + 1;
		output_brams.di_a[1] = mult_result[1];
		output_brams.di_b[1] = mult_result[3];

		output_brams.en[2] = 1'b0;
		output_brams.we[2] = 1'b0;
		output_brams.addr_a[2] = 0;
		output_brams.addr_b[2] = 0;
		output_brams.di_a[2] = 0;
		output_brams.di_b[2] = 0;

		output_brams.en[3] = 1'b0;
		output_brams.we[3] = 1'b0;
		output_brams.addr_a[3] = 0;
		output_brams.addr_b[3] = 0;
		output_brams.di_a[3] = 0;
		output_brams.di_b[3] = 0;
	end

	always_comb begin
		mult_a[0] = input_bram_1.do_a[0];
		mult_a[1] = input_bram_1.do_a[1];
		mult_a[2] = input_bram_1.do_b[0];
		mult_a[3] = input_bram_1.do_b[1];

		mult_b[0] = input_bram_2.do_a[0];
		mult_b[1] = input_bram_2.do_a[1];
		mult_b[2] = input_bram_2.do_b[0];
		mult_b[3] = input_bram_2.do_b[1];
	end

	genvar j;
	generate
		for (j = 0; j < BATCH_SIZE; j++) begin : mult_instances
			mod_multiplication #(
				.K(K)
			) mult_inst (
				.clk(clk),
				.a(mult_a[j]),
				.b(mult_b[j]),
				.result(mult_result[j])
			);
		end
	endgenerate

	always_comb begin
		done = (current_state == DONE);
	end
endmodule


