`timescale 1ns / 1ps
`include "params.vh"

module conv_unit #(
    parameter N = `N,
    parameter K = `K
) (
    input logic                clk,
    input logic                reset,
    input logic                start,

    DPBRAMInterface            input_image_brams_0,    // c0
    DPBRAMInterface            input_image_brams_1,    // c1


    output logic               done
);

DPBRAMInterface #()input_auto_0();
DPBRAMInterface #() input_auto_1();

DPBRAMInterface #() a_00_auto();
DPBRAMInterface #() a_01_auto();
DPBRAMInterface #() a_10_auto();
DPBRAMInterface #() b_00_auto();
DPBRAMInterface #() b_01_auto();
DPBRAMInterface #() b_10_auto();

DPBRAMInterface #() ksa_00_auto();
DPBRAMInterface #() ksa_01_auto();
DPBRAMInterface #() ksa_10_auto();
DPBRAMInterface #() ksb_00_auto();
DPBRAMInterface #() ksb_01_auto();
DPBRAMInterface #() ksb_10_auto();

DPBRAMInterface #() k_00_if();
DPBRAMInterface #() k_01_if();

DPBRAMInterface #() k_10_if();
DPBRAMInterface #() k_11_if();

PolyCoffDPBRAM #() kernel_00 (
    .clk(clk), .reset(reset), .bram_if(k_00_if)
);

PolyCoffDPBRAM #() kernel_01 (
    .clk(clk), .reset(reset), .bram_if(k_01_if)
);

PolyCoffDPBRAM #() kernel_10 (
    .clk(clk), .reset(reset), .bram_if(k_10_if)
);

PolyCoffDPBRAM #() kernel_11 (
    .clk(clk), .reset(reset), .bram_if(k_11_if)
);

DPBRAMInterface #() k_00_if_1();
DPBRAMInterface #() k_01_if_1();

DPBRAMInterface #() k_10_if_1();
DPBRAMInterface #() k_11_if_1();

PolyCoffDPBRAM #() kernel_00_1 (
    .clk(clk), .reset(reset), .bram_if(k_00_if_1)
);

PolyCoffDPBRAM #() kernel_01_1 (
    .clk(clk), .reset(reset), .bram_if(k_01_if_1)
);

PolyCoffDPBRAM #() kernel_10_1 (
    .clk(clk), .reset(reset), .bram_if(k_10_if_1)
);

PolyCoffDPBRAM #() kernel_11_1 (
    .clk(clk), .reset(reset), .bram_if(k_11_if_1)
);


DPBRAMInterface #() a_00_if();
DPBRAMInterface #() a_01_if();
DPBRAMInterface #() a_10_if();
DPBRAMInterface #() b_00_if();
DPBRAMInterface #() b_01_if();
DPBRAMInterface #() b_10_if();



DPBRAMInterface1            evk0_1();
DPBRAMInterface1            evk1_1();

DPBRAMInterface1            evk0_2();
DPBRAMInterface1            evk1_2();

DPBRAMInterface1            evk0_3();
DPBRAMInterface1            evk1_3();

DPBRAMInterface            ks_neg1_brams_0();
DPBRAMInterface            ks_neg1_brams_1();
DPBRAMInterface            ks_neg16_brams_0();
DPBRAMInterface            ks_neg16_brams_1();
DPBRAMInterface            ks_neg17_brams_0();
DPBRAMInterface            ks_neg17_brams_1();

DPBRAMInterface            neg1_mul_brams_0();
DPBRAMInterface            neg1_mul_brams_1();
DPBRAMInterface            neg16_mul_brams_0();
DPBRAMInterface            neg16_mul_brams_1();
DPBRAMInterface            neg17_mul_brams_0();
DPBRAMInterface            neg17_mul_brams_1();

DPBRAMInterface             mul_input_c0_1();
DPBRAMInterface             mul_input_c1_1();
DPBRAMInterface             mul_input_c0_2();
DPBRAMInterface             mul_input_c1_2();
DPBRAMInterface             mul_input_c0_3();
DPBRAMInterface             mul_input_c1_3();
DPBRAMInterface             mul_input_c0_4();
DPBRAMInterface             mul_input_c1_4();

DPBRAMInterface             mul_out_c0_1();
DPBRAMInterface             mul_out_c1_1();
DPBRAMInterface             mul_out_c0_2();
DPBRAMInterface             mul_out_c1_2();
DPBRAMInterface             mul_out_c0_3();
DPBRAMInterface             mul_out_c1_3();
DPBRAMInterface             mul_out_c0_4();
DPBRAMInterface             mul_out_c1_4();

DPBRAMInterface             add_result_c0_1();
DPBRAMInterface             add_result_c1_1();
DPBRAMInterface             add_result_c0_2();
DPBRAMInterface             add_result_c1_2();

DPBRAMInterface             add_result_c0_1_stage1();
DPBRAMInterface             add_result_c1_1_stage1();
DPBRAMInterface             add_result_c0_2_stage1();
DPBRAMInterface             add_result_c1_2_stage1();

DPBRAMInterface             add_result_c0_1_stage2();
DPBRAMInterface             add_result_c1_1_stage2();
DPBRAMInterface             add_result_c0_2_stage2();
DPBRAMInterface             add_result_c1_2_stage2();


DPBRAMInterface             final_output_c0();
DPBRAMInterface             final_output_c1();





PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) ks_neg1_bram_0 (
    .clk(clk), .reset(reset), .bram_if(ks_neg1_brams_0));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) ks_neg1_bram_1 (
    .clk(clk), .reset(reset), .bram_if(ks_neg1_brams_1));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) ks_neg16_bram_0 (
    .clk(clk), .reset(reset), .bram_if(ks_neg16_brams_0));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) ks_neg16_bram_1 (
    .clk(clk), .reset(reset), .bram_if(ks_neg16_brams_1));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) ks_neg17_bram_0 (
    .clk(clk), .reset(reset), .bram_if(ks_neg17_brams_0));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) ks_neg17_bram_1 (
    .clk(clk), .reset(reset), .bram_if(ks_neg17_brams_1));

PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_0_1 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c0_1));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_1_1 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c1_1));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_0_2 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c0_2));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_1_2 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c1_2));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_0_3 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c0_3));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_1_3 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c1_3));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_0_4 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c0_4));
PolyCoffDPBRAM #(.DLEN(32), .HLEN(8)) mul_out_1_4 (
    .clk(clk), .reset(reset), .bram_if(mul_out_c1_4));



PolyCoffDPBRAM #() auto_result_00 (
    .clk(clk), .reset(reset), .bram_if(a_00_if)
);
PolyCoffDPBRAM #() auto_result_01 (
    .clk(clk), .reset(reset), .bram_if(a_01_if)
);
PolyCoffDPBRAM #() auto_result_02 (
    .clk(clk), .reset(reset), .bram_if(a_10_if)
);
PolyCoffDPBRAM #() auto_result_10 (
    .clk(clk), .reset(reset), .bram_if(b_00_if)
);
PolyCoffDPBRAM #() auto_result_11 (
    .clk(clk), .reset(reset), .bram_if(b_01_if)
);
PolyCoffDPBRAM #() auto_result_12 (
    .clk(clk), .reset(reset), .bram_if(b_10_if)
);

PolyCoffDPBRAM #() add_1 (
    .clk(clk), .reset(reset), .bram_if(add_result_c0_1)
);
PolyCoffDPBRAM #() add_2 (
    .clk(clk), .reset(reset), .bram_if(add_result_c1_1)
);
PolyCoffDPBRAM #() add_3 (
    .clk(clk), .reset(reset), .bram_if(add_result_c0_2)
);
PolyCoffDPBRAM #() add_4 (
    .clk(clk), .reset(reset), .bram_if(add_result_c1_2)
);

PolyCoffDPBRAM #() add_5 (
    .clk(clk), .reset(reset), .bram_if(final_output_c0)
);
PolyCoffDPBRAM #() add_6 (
    .clk(clk), .reset(reset), .bram_if(final_output_c1)
);


PolyCoffDPBRAM1  #(.DLEN(32), .HLEN(8))ev0_inst (
    .clk(clk), .reset(reset), .bram_if(evk0_1));
PolyCoffDPBRAM1 #(.DLEN(32), .HLEN(8)) ev1_inst (
    .clk(clk), .reset(reset), .bram_if(evk1_1));
PolyCoffDPBRAM1  #(.DLEN(32), .HLEN(8))ev3_inst (
    .clk(clk), .reset(reset), .bram_if(evk0_2));
PolyCoffDPBRAM1 #(.DLEN(32), .HLEN(8)) ev4_inst (
    .clk(clk), .reset(reset), .bram_if(evk1_2));
PolyCoffDPBRAM1  #(.DLEN(32), .HLEN(8))ev5_inst (
    .clk(clk), .reset(reset), .bram_if(evk0_3));
PolyCoffDPBRAM1 #(.DLEN(32), .HLEN(8)) ev6_inst (
    .clk(clk), .reset(reset), .bram_if(evk1_3));

 typedef enum logic [3:0] {
        IDLE,
        ROTATE,
        KEY_SWITCH,
        KERNEL_MUL,
        ADD_01,
        ADD_FINAL,
        COMPLETE
} state_t;

state_t state, next_state;

logic auto_start;
logic auto0_done, auto1_done;
logic [7:0] address_counter_auto;

logic ks_start;
logic ks1_done, ks2_done, ks3_done;

logic mul_start;
logic mul1_done, mul2_done, mul3_done, mul4_done;

logic add_start_1, add_start_2, add_final_start;
logic add_done_1, add_done_2, add_final_done;



automorphism_core_lut #(.N(N), .K(K)) automorphism_0 (
        .clk(clk),
        .reset(reset),
        .start(auto_start),
        .input_brams(input_auto_0),
        .output_brams_1(a_00_auto),
        .output_brams_2(a_01_auto),
        .output_brams_3(a_10_auto),
        .done(auto0_done)
);

automorphism_core_lut #(.N(N), .K(K)) automorphism_1 (
    .clk(clk),
    .reset(reset),
    .start(auto_start),
    .input_brams(input_auto_1),
    .output_brams_1(b_00_auto),
    .output_brams_2(b_01_auto),
    .output_brams_3(b_10_auto),
    .done(auto1_done)
);

key_switch_core #(.N(N), .K(K)) ks_1(
    .clk(clk),
    .reset(reset),
    .start(ks_start),
    .c0_bram_1(ksa_00_auto),
    .c1_bram_1(ksb_00_auto),
    .c1_bram_1_c(ksb_00_auto),
    .evk0(evk0_1),
    .evk1(evk1_1),
    .ks0_bram(ks_neg1_brams_0),
    .ks1_bram(ks_neg1_brams_1),
    .done(ks1_done)
);

key_switch_core #(.N(N), .K(K)) ks_2(
    .clk(clk),
    .reset(reset),
    .start(ks_start),
    .c0_bram_1(ksa_01_auto),
    .c1_bram_1(ksb_01_auto),
    .c1_bram_1_c(ksb_01_auto),
    .evk0(evk0_2),
    .evk1(evk1_2),
    .ks0_bram(ks_neg16_brams_0),
    .ks1_bram(ks_neg16_brams_1),
    .done(ks2_done)
);

key_switch_core #(.N(N), .K(K)) ks_3(
    .clk(clk),
    .reset(reset),
    .start(ks_start),
    .c0_bram_1(ksa_10_auto),
    .c1_bram_1(ksb_10_auto),
    .c1_bram_1_c(ksb_10_auto),
    .evk0(evk0_3),
    .evk1(evk1_3),
    .ks0_bram(ks_neg17_brams_0),
    .ks1_bram(ks_neg17_brams_1),
    .done(ks3_done)
);

ct_pt_mul #(.N(N), .K(K)) pt_ct_mul1 ( // zero rotation
    .clk(clk),
    .reset(reset),
    .start(mul_start),
    .c0_bram(mul_input_c0_1),
    .c1_bram(mul_input_c1_1),
    .pt_bram_1(k_00_if),
    .pt_bram_2(k_00_if_1),
    .c0_pt_bram(mul_out_c0_1),
    .c1_pt_bram(mul_out_c1_1),
    .done(mul1_done)
);

ct_pt_mul #(.N(N), .K(K)) pt_ct_mul2 ( // -1 rotation
    .clk(clk),
    .reset(reset),
    .start(mul_start),
    .c0_bram(mul_input_c0_2),
    .c1_bram(mul_input_c1_2),
    .pt_bram_1(k_01_if),
    .pt_bram_2(k_01_if_1),
    .c0_pt_bram(mul_out_c0_2),
    .c1_pt_bram(mul_out_c1_2),
    .done(mul2_done)
);

ct_pt_mul #(.N(N), .K(K)) pt_ct_mul3 ( // -16 rotation
    .clk(clk),
    .reset(reset),
    .start(mul_start),
    .c0_bram(mul_input_c0_3),
    .c1_bram(mul_input_c1_3),
    .pt_bram_1(k_10_if),
    .pt_bram_2(k_10_if_1),
    .c0_pt_bram(mul_out_c0_3),
    .c1_pt_bram(mul_out_c1_3),
    .done(mul3_done)
);

ct_pt_mul #(.N(N), .K(K)) pt_ct_mul4 ( // -17 rotation
    .clk(clk),
    .reset(reset),
    .start(mul_start),
    .c0_bram(mul_input_c0_4),
    .c1_bram(mul_input_c1_4),
    .pt_bram_1(k_11_if),
    .pt_bram_2(k_11_if_1),
    .c0_pt_bram(mul_out_c0_4),
    .c1_pt_bram(mul_out_c1_4),
    .done(mul4_done)
);

ct_ct_add #(.N(N), .K(K)) add_12 (
    .clk(clk),
    .reset(reset),
    .start(add_start_1),
    .c0_bram_1(mul_out_c0_1),
    .c1_bram_1(mul_out_c1_1),
    .c0_bram_2(mul_out_c0_2),
    .c1_bram_2(mul_out_c1_2),
    .c0_bram(add_result_c0_1_stage1),
    .c1_bram(add_result_c1_1_stage1),
    .done(add_done_1)
);

ct_ct_add #(.N(N), .K(K)) add_34 (
    .clk(clk),
    .reset(reset),
    .start(add_start_2),
    .c0_bram_1(mul_out_c0_3),
    .c1_bram_1(mul_out_c1_3),
    .c0_bram_2(mul_out_c0_4),
    .c1_bram_2(mul_out_c1_4),
    .c0_bram(add_result_c0_2_stage1),
    .c1_bram(add_result_c1_2_stage1),
    .done(add_done_2)
);

ct_ct_add #(.N(N), .K(K)) add_final (
    .clk(clk),
    .reset(reset),
    .start(add_final_start),
    .c0_bram_1(add_result_c0_1_stage2),
    .c1_bram_1(add_result_c1_1_stage2),
    .c0_bram_2(add_result_c0_2_stage2),
    .c1_bram_2(add_result_c1_2_stage2),
    .c0_bram(final_output_c0),
    .c1_bram(final_output_c1),
    .done(add_final_done)
);



always_ff@(posedge clk or posedge reset) begin
    if(reset) state <=IDLE;
    else state<=next_state;
end

always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        auto_start<=0;
        address_counter_auto <=0;
        ks_start<=0;
        mul_start<=0;
        add_start_1<=0;
        add_start_2<=0;
        add_final_start<=0;
    end

    else begin
        case (state)
        IDLE: begin
            auto_start<=0;
            address_counter_auto<=0;
            ks_start<=0;
            mul_start<=0;
            add_start_1<=0;
            add_start_2<=0;
            add_final_start<=0;
        end

        ROTATE: begin
            auto_start <=1;
            if(!auto0_done && !auto1_done) address_counter_auto <=address_counter_auto+1;
            if(auto0_done&&auto1_done) auto_start <=0;
        end

        KEY_SWITCH: begin
            ks_start <=1;
            if(ks1_done && ks2_done && ks3_done) ks_start <=0;
        end

        KERNEL_MUL: begin
            mul_start <= 1;
            if (mul1_done && mul2_done && mul3_done && mul4_done) mul_start <= 0;
        end

        ADD_01: begin
            add_start_1 <= 1;
            add_start_2 <= 1;
            if (add_done_1 && add_done_2) begin
                add_start_1 <= 0;
                add_start_2 <= 0;
            end
        end

        ADD_FINAL: begin
            add_final_start <= 1;
            if (add_final_done) add_final_start <= 0;
        end

        COMPLETE: begin
            done <= 1;
        end

        endcase
    end
end

always_comb begin
    next_state = state;

    case(state)
    IDLE: begin
        if(start) next_state = ROTATE;
        else next_state = IDLE;
    end

    ROTATE: begin
        if(auto0_done && auto1_done) next_state = KEY_SWITCH;
        else begin
            input_auto_0.addr_a[0] = address_counter_auto*2;
            input_auto_0.addr_a[1] = address_counter_auto*2;
            input_auto_0.addr_b[0] = address_counter_auto*2+1;
            input_auto_0.addr_b[1] = address_counter_auto*2+1;

            input_auto_1.addr_a[0] = address_counter_auto*2;
            input_auto_1.addr_a[1] = address_counter_auto*2;
            input_auto_1.addr_b[0] = address_counter_auto*2+1;
            input_auto_1.addr_b[1] = address_counter_auto*2+1;
        end
    end

    KEY_SWITCH: begin
        if(ks1_done && ks2_done && ks3_done) next_state = KERNEL_MUL;
    end

    KERNEL_MUL: begin
        if (mul1_done && mul2_done && mul3_done && mul4_done) next_state = ADD_01;
    end

    ADD_01: begin
        if (add_done_1 && add_done_2) next_state = ADD_FINAL;
    end

    ADD_FINAL: begin
        if (add_final_done) next_state = COMPLETE;
    end

    COMPLETE: begin
        if(!start) next_state = COMPLETE;
        else next_state = COMPLETE;
    end
    endcase
end

//muxing logic
always_comb begin
    case(state)
    ROTATE: begin
        for (int i = 0; i < 4; i++) begin
            a_00_if.en[i] = a_00_auto.en[i];
            a_00_if.we[i] = a_00_auto.we[i];
            a_00_if.addr_a[i] = a_00_auto.addr_a[i];
            a_00_if.addr_b[i] = a_00_auto.addr_b[i];
            a_00_if.di_a[i] = a_00_auto.di_a[i];
            a_00_if.di_b[i] = a_00_auto.di_b[i];
            a_00_auto.do_a[i] = a_00_if.do_a[i];
            a_00_auto.do_b[i] = a_00_if.do_b[i];

            a_01_if.en[i] = a_01_auto.en[i];
            a_01_if.we[i] = a_01_auto.we[i];
            a_01_if.addr_a[i] = a_01_auto.addr_a[i];
            a_01_if.addr_b[i] = a_01_auto.addr_b[i];
            a_01_if.di_a[i] = a_01_auto.di_a[i];
            a_01_if.di_b[i] = a_01_auto.di_b[i];
            a_01_auto.do_a[i] = a_01_if.do_a[i];
            a_01_auto.do_b[i] = a_01_if.do_b[i];

            a_10_if.en[i] = a_10_auto.en[i];
            a_10_if.we[i] = a_10_auto.we[i];
            a_10_if.addr_a[i] = a_10_auto.addr_a[i];
            a_10_if.addr_b[i] = a_10_auto.addr_b[i];
            a_10_if.di_a[i] = a_10_auto.di_a[i];
            a_10_if.di_b[i] = a_10_auto.di_b[i];
            a_10_auto.do_a[i] = a_10_if.do_a[i];
            a_10_auto.do_b[i] = a_10_if.do_b[i];

            b_00_if.en[i] = b_00_auto.en[i];
            b_00_if.we[i] = b_00_auto.we[i];
            b_00_if.addr_a[i] = b_00_auto.addr_a[i];
            b_00_if.addr_b[i] = b_00_auto.addr_b[i];
            b_00_if.di_a[i] = b_00_auto.di_a[i];
            b_00_if.di_b[i] = b_00_auto.di_b[i];
            b_00_auto.do_a[i] = b_00_if.do_a[i];
            b_00_auto.do_b[i] = b_00_if.do_b[i];

            // Connect b_01_auto to b_01_if
            b_01_if.en[i] = b_01_auto.en[i];
            b_01_if.we[i] = b_01_auto.we[i];
            b_01_if.addr_a[i] = b_01_auto.addr_a[i];
            b_01_if.addr_b[i] = b_01_auto.addr_b[i];
            b_01_if.di_a[i] = b_01_auto.di_a[i];
            b_01_if.di_b[i] = b_01_auto.di_b[i];
            b_01_auto.do_a[i] = b_01_if.do_a[i];
            b_01_auto.do_b[i] = b_01_if.do_b[i];

            // Connect b_10_auto to b_10_if
            b_10_if.en[i] = b_10_auto.en[i];
            b_10_if.we[i] = b_10_auto.we[i];
            b_10_if.addr_a[i] = b_10_auto.addr_a[i];
            b_10_if.addr_b[i] = b_10_auto.addr_b[i];
            b_10_if.di_a[i] = b_10_auto.di_a[i];
            b_10_if.di_b[i] = b_10_auto.di_b[i];
            b_10_auto.do_a[i] = b_10_if.do_a[i];
            b_10_auto.do_b[i] = b_10_if.do_b[i];
        end

        input_auto_0.en = '{default:1'b1};
        input_auto_1.en = '{default:1'b1};
        input_auto_0.we = '{default:1'b0};
        input_auto_1.we = '{default:1'b0};

        input_image_brams_0.en = input_auto_0.en;
        input_image_brams_1.en = input_auto_1.en;
        input_image_brams_0.we = input_auto_0.we;
        input_image_brams_1.we = input_auto_1.we;

        input_image_brams_0.addr_a = input_auto_0.addr_a;
        input_image_brams_0.addr_b = input_auto_0.addr_b;
        input_image_brams_1.addr_a = input_auto_1.addr_a;
        input_image_brams_1.addr_b = input_auto_1.addr_b;

        input_auto_0.do_a = input_image_brams_0.do_a;
        input_auto_0.do_b = input_image_brams_0.do_b;
        input_auto_1.do_a = input_image_brams_1.do_a;
        input_auto_1.do_b = input_image_brams_1.do_b;
    end

    KEY_SWITCH: begin
        for (int i = 0; i < 4; i++) begin
            a_00_if.en[i] = ksa_00_auto.en[i];
            a_00_if.we[i] = ksa_00_auto.we[i];
            a_00_if.addr_a[i] = ksa_00_auto.addr_a[i];
            a_00_if.addr_b[i] = ksa_00_auto.addr_b[i];
            a_00_if.di_a[i] = ksa_00_auto.di_a[i];
            a_00_if.di_b[i] = ksa_00_auto.di_b[i];
            ksa_00_auto.do_a[i] = a_00_if.do_a[i];
            ksa_00_auto.do_b[i] = a_00_if.do_b[i];

            a_01_if.en[i] = ksa_01_auto.en[i];
            a_01_if.we[i] = ksa_01_auto.we[i];
            a_01_if.addr_a[i] = ksa_01_auto.addr_a[i];
            a_01_if.addr_b[i] = ksa_01_auto.addr_b[i];
            a_01_if.di_a[i] = ksa_01_auto.di_a[i];
            a_01_if.di_b[i] = ksa_01_auto.di_b[i];
            ksa_01_auto.do_a[i] = a_01_if.do_a[i];
            ksa_01_auto.do_b[i] = a_01_if.do_b[i];

            a_10_if.en[i] = ksa_10_auto.en[i];
            a_10_if.we[i] = ksa_10_auto.we[i];
            a_10_if.addr_a[i] = ksa_10_auto.addr_a[i];
            a_10_if.addr_b[i] = ksa_10_auto.addr_b[i];
            a_10_if.di_a[i] = ksa_10_auto.di_a[i];
            a_10_if.di_b[i] = ksa_10_auto.di_b[i];
            ksa_10_auto.do_a[i] = a_10_if.do_a[i];
            ksa_10_auto.do_b[i] = a_10_if.do_b[i];

            b_00_if.en[i] = ksb_00_auto.en[i];
            b_00_if.we[i] = ksb_00_auto.we[i];
            b_00_if.addr_a[i] = ksb_00_auto.addr_a[i];
            b_00_if.addr_b[i] = ksb_00_auto.addr_b[i];
            b_00_if.di_a[i] = ksb_00_auto.di_a[i];
            b_00_if.di_b[i] = ksb_00_auto.di_b[i];
            ksb_00_auto.do_a[i] = b_00_if.do_a[i];
            ksb_00_auto.do_b[i] = b_00_if.do_b[i];

            b_01_if.en[i] = ksb_01_auto.en[i];
            b_01_if.we[i] = ksb_01_auto.we[i];
            b_01_if.addr_a[i] = ksb_01_auto.addr_a[i];
            b_01_if.addr_b[i] = ksb_01_auto.addr_b[i];
            b_01_if.di_a[i] = ksb_01_auto.di_a[i];
            b_01_if.di_b[i] = ksb_01_auto.di_b[i];
            ksb_01_auto.do_a[i] = b_01_if.do_a[i];
            ksb_01_auto.do_b[i] = b_01_if.do_b[i];

            b_10_if.en[i] = ksb_10_auto.en[i];
            b_10_if.we[i] = ksb_10_auto.we[i];
            b_10_if.addr_a[i] = ksb_10_auto.addr_a[i];
            b_10_if.addr_b[i] = ksb_10_auto.addr_b[i];
            b_10_if.di_a[i] = ksb_10_auto.di_a[i];
            b_10_if.di_b[i] = ksb_10_auto.di_b[i];
            ksb_10_auto.do_a[i] = b_10_if.do_a[i];
            ksb_10_auto.do_b[i] = b_10_if.do_b[i];
        end

    end

    KERNEL_MUL: begin
        for (int i = 0; i < 4; i++) begin
            input_image_brams_0.en[i] = mul_input_c0_1.en[i];
            input_image_brams_0.we[i] = mul_input_c0_1.we[i];
            input_image_brams_0.addr_a[i] = mul_input_c0_1.addr_a[i];
            input_image_brams_0.addr_b[i] = mul_input_c0_1.addr_b[i];
            input_image_brams_0.di_a[i] = mul_input_c0_1.di_a[i];
            input_image_brams_0.di_b[i] = mul_input_c0_1.di_b[i];
            mul_input_c0_1.do_a[i] = input_image_brams_0.do_a[i];
            mul_input_c0_1.do_b[i] = input_image_brams_0.do_b[i];

            input_image_brams_1.en[i] = mul_input_c1_1.en[i];
            input_image_brams_1.we[i] = mul_input_c1_1.we[i];
            input_image_brams_1.addr_a[i] = mul_input_c1_1.addr_a[i];
            input_image_brams_1.addr_b[i] = mul_input_c1_1.addr_b[i];
            input_image_brams_1.di_a[i] = mul_input_c1_1.di_a[i];
            input_image_brams_1.di_b[i] = mul_input_c1_1.di_b[i];
            mul_input_c1_1.do_a[i] = input_image_brams_1.do_a[i];
            mul_input_c1_1.do_b[i] = input_image_brams_1.do_b[i];

            ks_neg1_brams_0.en[i] = mul_input_c0_2.en[i];
            ks_neg1_brams_0.we[i] = mul_input_c0_2.we[i];
            ks_neg1_brams_0.addr_a[i] = mul_input_c0_2.addr_a[i];
            ks_neg1_brams_0.addr_b[i] = mul_input_c0_2.addr_b[i];
            ks_neg1_brams_0.di_a[i] = mul_input_c0_2.di_a[i];
            ks_neg1_brams_0.di_b[i] = mul_input_c0_2.di_b[i];
            mul_input_c0_2.do_a[i] = ks_neg1_brams_0.do_a[i];
            mul_input_c0_2.do_b[i] = ks_neg1_brams_0.do_b[i];

            ks_neg1_brams_1.en[i] = mul_input_c1_2.en[i];
            ks_neg1_brams_1.we[i] = mul_input_c1_2.we[i];
            ks_neg1_brams_1.addr_a[i] = mul_input_c1_2.addr_a[i];
            ks_neg1_brams_1.addr_b[i] = mul_input_c1_2.addr_b[i];
            ks_neg1_brams_1.di_a[i] = mul_input_c1_2.di_a[i];
            ks_neg1_brams_1.di_b[i] = mul_input_c1_2.di_b[i];
            mul_input_c1_2.do_a[i] = ks_neg1_brams_1.do_a[i];
            mul_input_c1_2.do_b[i] = ks_neg1_brams_1.do_b[i];

            ks_neg16_brams_0.en[i] = mul_input_c0_3.en[i];
            ks_neg16_brams_0.we[i] = mul_input_c0_3.we[i];
            ks_neg16_brams_0.addr_a[i] = mul_input_c0_3.addr_a[i];
            ks_neg16_brams_0.addr_b[i] = mul_input_c0_3.addr_b[i];
            ks_neg16_brams_0.di_a[i] = mul_input_c0_3.di_a[i];
            ks_neg16_brams_0.di_b[i] = mul_input_c0_3.di_b[i];
            mul_input_c0_3.do_a[i] = ks_neg16_brams_0.do_a[i];
            mul_input_c0_3.do_b[i] = ks_neg16_brams_0.do_b[i];

            ks_neg16_brams_1.en[i] = mul_input_c1_3.en[i];
            ks_neg16_brams_1.we[i] = mul_input_c1_3.we[i];
            ks_neg16_brams_1.addr_a[i] = mul_input_c1_3.addr_a[i];
            ks_neg16_brams_1.addr_b[i] = mul_input_c1_3.addr_b[i];
            ks_neg16_brams_1.di_a[i] = mul_input_c1_3.di_a[i];
            ks_neg16_brams_1.di_b[i] = mul_input_c1_3.di_b[i];
            mul_input_c1_3.do_a[i] = ks_neg16_brams_1.do_a[i];
            mul_input_c1_3.do_b[i] = ks_neg16_brams_1.do_b[i];

            ks_neg17_brams_0.en[i] = mul_input_c0_4.en[i];
            ks_neg17_brams_0.we[i] = mul_input_c0_4.we[i];
            ks_neg17_brams_0.addr_a[i] = mul_input_c0_4.addr_a[i];
            ks_neg17_brams_0.addr_b[i] = mul_input_c0_4.addr_b[i];
            ks_neg17_brams_0.di_a[i] = mul_input_c0_4.di_a[i];
            ks_neg17_brams_0.di_b[i] = mul_input_c0_4.di_b[i];
            mul_input_c0_4.do_a[i] = ks_neg17_brams_0.do_a[i];
            mul_input_c0_4.do_b[i] = ks_neg17_brams_0.do_b[i];

            ks_neg17_brams_1.en[i] = mul_input_c1_4.en[i];
            ks_neg17_brams_1.we[i] = mul_input_c1_4.we[i];
            ks_neg17_brams_1.addr_a[i] = mul_input_c1_4.addr_a[i];
            ks_neg17_brams_1.addr_b[i] = mul_input_c1_4.addr_b[i];
            ks_neg17_brams_1.di_a[i] = mul_input_c1_4.di_a[i];
            ks_neg17_brams_1.di_b[i] = mul_input_c1_4.di_b[i];
            mul_input_c1_4.do_a[i] = ks_neg17_brams_1.do_a[i];
            mul_input_c1_4.do_b[i] = ks_neg17_brams_1.do_b[i];

        end

    end

    ADD_01: begin
        add_result_c0_1.en[i] = add_result_c0_1_stage1.en[i];
        add_result_c0_1.we[i] = add_result_c0_1_stage1.we[i];
        add_result_c0_1.addr_a[i] = add_result_c0_1_stage1.addr_a[i];
        add_result_c0_1.addr_b[i] = add_result_c0_1_stage1.addr_b[i];
        add_result_c0_1.di_a[i] = add_result_c0_1_stage1.di_a[i];
        add_result_c0_1.di_b[i] = add_result_c0_1_stage1.di_b[i];
        add_result_c0_1_stage1.do_a[i] = add_result_c0_1.do_a[i];
        add_result_c0_1_stage1.do_b[i] = add_result_c0_1.do_b[i];

        add_result_c0_2.en[i] = add_result_c0_1_stage1s.en[i];
        add_result_c0_2.we[i] = add_result_c0_1_stage1.we[i];
        add_result_c0_2.addr_a[i] = add_result_c0_1_stage1.addr_a[i];
        add_result_c0_2.addr_b[i] = add_result_c0_1_stage1.addr_b[i];
        add_result_c0_2.di_a[i] = add_result_c0_1_stage2.di_a[i];
        add_result_c0_2.di_b[i] = add_result_c0_1_stage2.di_b[i];
        add_result_c0_2_stage1.do_a[i] = add_result_c0_2.do_a[i];
        add_result_c0_2_stage1.do_b[i] = add_result_c0_2.do_b[i];

        add_result_c1_1.en[i] = add_result_c1_1_stage1.en[i];
        add_result_c1_1.we[i] = add_result_c1_1_stage1.we[i];
        add_result_c1_1.addr_a[i] = add_result_c1_1_stage1.addr_a[i];
        add_result_c1_1.addr_b[i] = add_result_c1_1_stage1.addr_b[i];
        add_result_c1_1.di_a[i] = add_result_c1_1_stage1.di_a[i];
        add_result_c1_1.di_b[i] = add_result_c1_1_stage1.di_b[i];
        add_result_c1_1_stage1.do_a[i] = add_result_c1_1.do_a[i];
        add_result_c1_1_stage1.do_b[i] = add_result_c1_1.do_b[i];

        add_result_c1_2.en[i] = add_result_c1_1_stage1.en[i];
        add_result_c1_2.we[i] = add_result_c1_1_stage1.we[i];
        add_result_c1_2.addr_a[i] = add_result_c1_1_stage1.addr_a[i];
        add_result_c1_2.addr_b[i] = add_result_c1_1_stage1.addr_b[i];
        add_result_c1_2.di_a[i] = add_result_c1_1_stage1.di_a[i];
        add_result_c1_2.di_b[i] = add_result_c1_1_stage1.di_b[i];
        add_result_c1_2_stage1.do_a[i] = add_result_c1_2.do_a[i];
        add_result_c1_2_stage1.do_b[i] = add_result_c1_2.do_b[i];

    end

    ADD_FINAL: begin

        add_result_c0_1.en[i] = add_result_c0_1_stage2.en[i];
        add_result_c0_1.we[i] = add_result_c0_1_stage2.we[i];
        add_result_c0_1.addr_a[i] = add_result_c0_1_stage2.addr_a[i];
        add_result_c0_1.addr_b[i] = add_result_c0_1_stage2.addr_b[i];
        add_result_c0_1.di_a[i] = add_result_c0_1_stage2.di_a[i];
        add_result_c0_1.di_b[i] = add_result_c0_1_stage2.di_b[i];
        add_result_c0_1_stage2.do_a[i] = add_result_c0_1.do_a[i];
        add_result_c0_1_stage2.do_b[i] = add_result_c0_1.do_b[i];

        add_result_c0_2.en[i] = add_result_c0_1_stage2.en[i];
        add_result_c0_2.we[i] = add_result_c0_1_stage2.we[i];
        add_result_c0_2.addr_a[i] = add_result_c0_1_stage2.addr_a[i];
        add_result_c0_2.addr_b[i] = add_result_c0_1_stage2.addr_b[i];
        add_result_c0_2.di_a[i] = add_result_c0_1_stage2.di_a[i];
        add_result_c0_2.di_b[i] = add_result_c0_1_stage2.di_b[i];
        add_result_c0_2_stage2.do_a[i] = add_result_c0_2.do_a[i];
        add_result_c0_2_stage2.do_b[i] = add_result_c0_2.do_b[i];

        add_result_c1_1.en[i] = add_result_c1_1_stage2.en[i];
        add_result_c1_1.we[i] = add_result_c1_1_stage2.we[i];
        add_result_c1_1.addr_a[i] = add_result_c1_1_stage2.addr_a[i];
        add_result_c1_1.addr_b[i] = add_result_c1_1_stage2.addr_b[i];
        add_result_c1_1.di_a[i] = add_result_c1_1_stage2.di_a[i];
        add_result_c1_1.di_b[i] = add_result_c1_1_stage2.di_b[i];
        add_result_c1_1_stage2.do_a[i] = add_result_c1_1.do_a[i];
        add_result_c1_1_stage2.do_b[i] = add_result_c1_1.do_b[i];

        add_result_c1_2.en[i] = add_result_c1_1_stage2.en[i];
        add_result_c1_2.we[i] = add_result_c1_1_stage2.we[i];
        add_result_c1_2.addr_a[i] = add_result_c1_1_stage2.addr_a[i];
        add_result_c1_2.addr_b[i] = add_result_c1_1_stage2.addr_b[i];
        add_result_c1_2.di_a[i] = add_result_c1_1_stage2.di_a[i];
        add_result_c1_2.di_b[i] = add_result_c1_1_stage2.di_b[i];
        add_result_c1_2_stage2.do_a[i] = add_result_c1_2.do_a[i];
        add_result_c1_2_stage2.do_b[i] = add_result_c1_2.do_b[i];
    end

    default: begin
        for (int i = 0; i < 4; i++) begin
            a_00_auto.do_a[i] = '0;
            a_00_auto.do_b[i] = '0;
            a_01_auto.do_a[i] = '0;
            a_01_auto.do_b[i] = '0;
            a_10_auto.do_a[i] = '0;
            a_10_auto.do_b[i] = '0;
            b_00_auto.do_a[i] = '0;
            b_00_auto.do_b[i] = '0;
            b_01_auto.do_a[i] = '0;
            b_01_auto.do_b[i] = '0;
            b_10_auto.do_a[i] = '0;
            b_10_auto.do_b[i] = '0;

            // Disconnect key-switch intermediate interfaces
            ksa_00_auto.do_a[i] = '0;
            ksa_00_auto.do_b[i] = '0;
            ksa_01_auto.do_a[i] = '0;
            ksa_01_auto.do_b[i] = '0;
            ksa_10_auto.do_a[i] = '0;
            ksa_10_auto.do_b[i] = '0;
            ksb_00_auto.do_a[i] = '0;
            ksb_00_auto.do_b[i] = '0;
            ksb_01_auto.do_a[i] = '0;
            ksb_01_auto.do_b[i] = '0;
            ksb_10_auto.do_a[i] = '0;
            ksb_10_auto.do_b[i] = '0;
        end
    end
    endcase
end

endmodule
