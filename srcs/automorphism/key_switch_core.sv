`timescale 1ns / 1ps
`include "params.vh"

module key_switch_core #(
    parameter N = `N,
    parameter K = `K
) (
    input logic             clk,
    input logic             reset,
    input logic             start,

    DPBRAMInterface         c0_bram_1,
    DPBRAMInterface         c1_bram_1,
    DPBRAMInterface         c1_bram_1_c,
    
    DPBRAMInterface1         evk0,
    DPBRAMInterface1        evk1,
    
    DPBRAMInterface         ks0_bram,
    DPBRAMInterface         ks1_bram,

    output logic            done
);

    logic start_mul, start_add;
    
    typedef enum logic [1 : 0] {
        KS_IDLE,
        KS_MULT,
        KS_ADD,
        KS_DONE
    } ks_state_t;
    
    ks_state_t current_state, next_state;

    always_ff @(posedge clk) begin
        if (reset) begin
            current_state <= KS_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            KS_IDLE: begin
                if (start) begin
                    next_state = KS_MULT;
                end
            end
            
            KS_MULT: begin
                if (mult_done) begin
                    next_state = KS_ADD;
                end
            end

            KS_ADD: begin
                if (add_done) begin
                    next_state = KS_DONE;
                end
            end

            KS_DONE: begin
                if (!start) begin
                    next_state = KS_DONE;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            start_mul <= 1'b0;
            start_add <= 1'b0;
            done <= 1'b0;
        end else begin
            case (current_state)
                KS_IDLE: begin
                    start_mul <= 1'b0;
                    start_add <= 1'b0;
                    done <= 1'b0;
                end
                KS_MULT: begin
                    if (!start_mul) begin
                        start_mul <= 1'b1;
                    end
                end
                KS_ADD: begin
                    start_mul <= 1'b0;
                    if (!start_add) begin
                        start_add <= 1'b1;
                    end
                end
                
                KS_DONE: begin
                    start_add <= 0;
                    done <= 1'b1;
                end
            endcase
        end
    end

    DPBRAMInterface internal_a();
    PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) internal_a_bram (
        .clk(clk),
        .reset(reset),
        .bram_if(internal_a)
    );
    
    DPBRAMInterface mult_0_output();
    DPBRAMInterface internal_a_add();
    
    logic mul_to_internal_a;
    
    always_comb begin
        mul_to_internal_a = (current_state == KS_MULT);
        
        for (int i = 0; i < 4; i++) begin
            if (mul_to_internal_a) begin
                internal_a.en[i] = mult_0_output.en[i];
                internal_a.we[i] = mult_0_output.we[i];
                internal_a.addr_a[i] = mult_0_output.addr_a[i];
                internal_a.addr_b[i] = mult_0_output.addr_b[i];
                internal_a.di_a[i] = mult_0_output.di_a[i];
                internal_a.di_b[i] = mult_0_output.di_b[i];
            end 
            else begin
                internal_a.en[i] = internal_a_add.en[i];
                internal_a.we[i] = internal_a_add.we[i];
                internal_a.addr_a[i] = internal_a_add.addr_a[i];
                internal_a.addr_b[i] = internal_a_add.addr_b[i];
                internal_a.di_a[i] = internal_a_add.di_a[i];
                internal_a.di_b[i] = internal_a_add.di_b[i];
            end
        end
    end
    
    // Connect internal_a outputs to adder inputs
    always_comb begin
        for (int i = 0; i < 4; i++) begin
            internal_a_add.do_a[i] = internal_a.do_a[i];
            internal_a_add.do_b[i] = internal_a.do_b[i];
        end
    end

    logic mult_done_0, mult_done_1;
    assign mult_done = mult_done_0 && mult_done_1;

    pointwise_mul1 #(
        .N(N),
        .K(K)
    ) mult_inst_0 (
        .clk(clk),
        .reset(reset),
        .start(start_mul),
        .input_bram_1(c1_bram_1),
        .input_bram_2(evk0),
        .output_brams(mult_0_output),
        .done(mult_done_0)
    );

    pointwise_mul1 #(
        .N(N),
        .K(K)
    ) mult_inst_1 (
        .clk(clk),
        .reset(reset),
        .start(start_mul),
        .input_bram_1(c1_bram_1_c),
        .input_bram_2(evk1),
        .output_brams(ks1_bram),
        .done(mult_done_1)
    );

    logic add_done;

    poly_add #(
        .N(N),
        .K(K)
    ) add_inst (
        .clk(clk),
        .reset(reset),
        .start(start_add),
        .input_bram_1(internal_a_add), // Connect to the muxed interface
        .input_bram_2(c0_bram_1),
        .output_brams(ks0_bram),
        .done(add_done)
    );
    
endmodule
