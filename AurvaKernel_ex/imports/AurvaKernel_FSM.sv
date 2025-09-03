// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// Description: Pipelined adder.  This is an adder with pipelines before and
//   after the adder datapath.  The output is fed into a FIFO and prog_full is
//   used to signal ready.  This design allows for high Fmax.

// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1ps / 1ps
`include "params.vh"

(* dont_touch = "true" *) module AurvaKernel_FSM #(
  parameter integer C_AXIS_TDATA_WIDTH = 512, // Data width of both input and output data
  parameter integer C_ADDER_BIT_WIDTH  = 64,
  parameter integer C_NUM_CLOCKS       = 1,
  parameter integer C_AXIS_TID_WIDTH = 1,
  parameter integer C_AXIS_TDEST_WIDTH = 1,
  parameter integer C_AXIS_TUSER_WIDTH = 1
)
(

  input wire  [C_ADDER_BIT_WIDTH-1:0]   ctrl_constant,

  input wire                             s_axis_aclk,
  input wire                             s_axis_areset,
  input wire  [7:0]                      rotation_steps,
  input wire                             s_axis_tvalid,
  output wire                            s_axis_tready,
  input wire  [C_AXIS_TDATA_WIDTH-1:0]   s_axis_tdata,
  input wire  [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_tkeep,
  input wire  [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_tstrb,
  input wire                             s_axis_tlast,
  input wire [C_AXIS_TID_WIDTH-1:0]     s_axis_tid,
  input wire  [C_AXIS_TDEST_WIDTH-1:0]   s_axis_tdest,
  input wire  [C_AXIS_TUSER_WIDTH-1:0]   s_axis_tuser,

  input wire                             m_axis_aclk,
  output wire                            m_axis_tvalid,
  input  wire                            m_axis_tready,
  output wire [C_AXIS_TDATA_WIDTH-1:0]   m_axis_tdata,
  output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_tkeep,
  output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_tstrb,
  output wire                            m_axis_tlast,
  output wire  [C_AXIS_TID_WIDTH-1:0]     m_axis_tid,
  output wire  [C_AXIS_TDEST_WIDTH-1:0]   m_axis_tdest,
  output wire  [C_AXIS_TUSER_WIDTH-1:0]   m_axis_tuser,

  // NTT Debug ports
  output wire [26:0] dbg_ntt_input_a,
  output wire [26:0] dbg_ntt_input_b,
  output wire [26:0] dbg_ntt_twiddle,
  output wire [26:0] dbg_ntt_mult_result,
  output wire [26:0] dbg_ntt_output_a,
  output wire [26:0] dbg_ntt_output_b,
  output wire dbg_ntt_is_intt

);

localparam integer LP_NUM_LOOPS = C_AXIS_TDATA_WIDTH/C_ADDER_BIT_WIDTH;
localparam         LP_CLOCKING_MODE = C_NUM_CLOCKS == 1 ? "common_clock" : "independent_clock";
localparam K = 32;
localparam N = 256;
localparam TOTAL_BEATS = 64;
/////////////////////////////////////////////////////////////////////////////
// Variables
/////////////////////////////////////////////////////////////////////////////
reg                              d1_tvalid = 1'b0;
reg                              d1_tready = 1'b0;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d1_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tkeep;
reg                              d1_tlast;
reg   [C_ADDER_BIT_WIDTH-1:0]    d1_constant;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d1_tstrb = {C_AXIS_TDATA_WIDTH/8{1'b1}};
reg   [C_AXIS_TID_WIDTH-1:0]     d1_tid = {C_AXIS_TID_WIDTH{1'b0}};
reg   [C_AXIS_TDEST_WIDTH-1:0]   d1_tdest = {C_AXIS_TDEST_WIDTH{1'b0}};
reg   [C_AXIS_TUSER_WIDTH-1:0]   d1_tuser = {C_AXIS_TUSER_WIDTH{1'b0}};
integer i;

reg                              d2_tvalid = 1'b0;
reg   [C_AXIS_TDATA_WIDTH-1:0]   d2_tdata;
reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tkeep;
reg                              d2_tlast;


reg   [C_AXIS_TDATA_WIDTH/8-1:0] d2_tstrb;
reg   [C_AXIS_TID_WIDTH-1:0]     d2_tid;
reg   [C_AXIS_TDEST_WIDTH-1:0]   d2_tdest;
reg   [C_AXIS_TUSER_WIDTH-1:0]   d2_tuser;

wire                             prog_full_axis;
reg                              fifo_ready_r = 1'b0;

logic processing;
logic read_complete, read_end, read_end2;
logic write_complete;
logic [7:0] read_counter;
logic [7:0] write_counter;
logic [7:0] next_write_counter;

logic [1:0] pipe_valid;     // 2-stage valid pipeline
logic [1:0] pipe_last;      // 2-stage last pipeline
logic [7:0] pipe_addr [1:0];


logic automorph_start, automorph_done;
logic ntt_start, ntt_done1, ntt_done2;
logic ntt_reset, ntt_is_intt1, ntt_is_intt2;

DPBRAMInterface #() poly_a_brams();
DPBRAMInterface #() poly_b_brams();

DPBRAMInterface #() top_a_if();
DPBRAMInterface #() top_b_if();

DPBRAMInterface #() top_final_if_a();
DPBRAMInterface #() top_final_if_b();

DPBRAMInterface #() conv_a_brams();
DPBRAMInterface #() conv_b_brams();

logic use_top_interface;
logic use_conv_output;

DPBRAMInterface #() ntt_a_if();
DPBRAMInterface #() ntt_b_if();

TwiddleBRAMInterface tf_brams_1();
TwiddleBRAMInterface tf_brams_2();



TwiddleFactorBRAM tf_bram_1 (
    .clk(s_axis_aclk), .tf_if(tf_brams_1)
);

TwiddleFactorBRAM tf_bram_2 (
    .clk(s_axis_aclk), .tf_if(tf_brams_2)
);

NTT_Controller_Pipelined #() NTT_unit1 (
    .clk(s_axis_aclk), .reset(ntt_reset), .start(ntt_start), .is_intt(ntt_is_intt1),
    .done(ntt_done1), .poly_brams(ntt_a_if), .tf_brams(tf_brams_1)
);

NTT_Controller_Pipelined #() NTT_unit2 (
    .clk(s_axis_aclk), .reset(ntt_reset), .start(ntt_start), .is_intt(ntt_is_intt2),
    .done(ntt_done2), .poly_brams(ntt_b_if), .tf_brams(tf_brams_2)
);

PolyCoffDPBRAM #() poly_a_memory (
    .clk(s_axis_aclk), .reset(s_axis_areset), .bram_if(poly_a_brams)
);

PolyCoffDPBRAM #() poly_b_memory (
    .clk(s_axis_aclk), .reset(s_axis_areset), .bram_if(poly_b_brams)
);

DPBRAMInterface #() poly_a_final();
DPBRAMInterface #() poly_b_final();

PolyCoffDPBRAM #() poly_a_final_memory (
    .clk(s_axis_aclk), .reset(s_axis_areset), .bram_if(poly_a_final)
);

PolyCoffDPBRAM #() poly_b_final_memory (
    .clk(s_axis_aclk), .reset(s_axis_areset), .bram_if(poly_b_final)
);

typedef enum logic[2:0] {
  IDLE,
  READ,
  NTT,
  COMPUTE,
  WRITE,
  COMPLETE
} state_t;

state_t state, next_state;
logic[2:0] write_delay;


logic conv_start;
logic conv_done;

DPBRAMInterface #() conv_output_a_brams();
DPBRAMInterface #() conv_output_b_brams();

 conv_unit #(
     .N(N),
     .K(K)
 ) conv_unit (
     .clk(s_axis_aclk),
     .reset(s_axis_areset),
     .start(conv_start),
     .input_image_brams_0(conv_a_brams),
     .input_image_brams_1(conv_b_brams),
     .output_image_0(conv_output_a_brams),
     .output_image_1(conv_output_b_brams),
     .done(conv_done)
 );

/////////////////////////////////////////////////////////////////////////////
// RTL Logic

always_ff @(posedge s_axis_aclk or posedge s_axis_areset) begin
  if (s_axis_areset)
      state <= IDLE;
  else
      state <= next_state;
end

always_ff @(posedge s_axis_aclk or posedge s_axis_areset) begin

  if (s_axis_areset) begin
    processing <= 0;
    write_complete <= 0;
    
    // Counters
    read_counter <= 0;
    write_counter <= 0;
    next_write_counter <= 0;
    write_delay <= 0;
    conv_start <=0;
    read_complete <=0;
    ntt_start <=0;
  
  end else begin
    
      case (state)
        IDLE: begin
            read_counter <=0;
            write_counter <=0;
            next_write_counter <=0;
            write_complete <=0;
            d2_tlast <= 0;
            d2_tvalid <= 0;
            d2_tstrb <= 32'hFFFFFFFF;
            d2_tkeep <= s_axis_tkeep;
            d2_tid <=s_axis_tid;
            d2_tuser <=s_axis_tuser;
            d2_tdest <= s_axis_tdest;
            write_delay<=0;
            read_end <=0;
            read_end2<=0;
            conv_start <=0;
            ntt_start <=0;
        end

        READ: begin

          if(s_axis_tlast) begin 
            read_end <=1;
          end

          if(read_end) read_end2<=1;

          if(read_end2) begin
            read_complete <=1;
          end

          if(!read_complete && s_axis_tvalid && s_axis_tready) begin
            read_counter <= read_counter+1;
          end
        end

        NTT: begin
          ntt_start <= 1;
          if(ntt_done1 && ntt_done2) begin
            ntt_start <= 0;
          end
        end

        COMPUTE: begin
          conv_start<=1;
          if(conv_done) conv_start <=0;
        end

        WRITE: begin
          if(!write_complete && fifo_ready_r) begin    
            d2_tvalid<=1;     
            if(!write_delay) write_delay <=write_delay+1;
  
            write_counter <= write_counter + 1;         
            if(write_counter == TOTAL_BEATS+1) begin
              write_complete <= 1;
              d2_tlast <= 1;
            end
          end
          else begin
            d2_tvalid <= 0;
          end
        end

        COMPLETE: begin
          d2_tvalid <= 0;
          processing <= 0;
        end
      endcase

    end
end

always_comb begin

  next_state = state;  // Default to current state
  top_a_if.en = '{default:1'b1};
  top_a_if.addr_a = '{default:'0};
  top_a_if.addr_b = '{default:'0};
  top_a_if.di_a = '{default:'0};
  top_a_if.di_b = '{default:'0};

  top_b_if.en = '{default:1'b1};
  top_b_if.addr_a = '{default:'0};
  top_b_if.addr_b = '{default:'0};
  top_b_if.di_a = '{default:'0};
  top_b_if.di_b = '{default:'0};

  d2_tdata = '{default:'0};


  case (state)
      IDLE: begin 
        if (s_axis_tvalid) begin
          top_a_if.en   = '{default:1'b1};
          top_b_if.en   = '{default:1'b1};
          next_state = READ;
        end
        else begin
          next_state = IDLE;
        end
      end

      READ: begin
        if(read_complete) begin
          next_state = NTT;
        end
        if (!read_complete && s_axis_tvalid && s_axis_tready) begin
          top_a_if.addr_a[0] = read_counter * 2;
          top_a_if.addr_b[0] = read_counter * 2 + 1;
          top_a_if.addr_a[1] = read_counter * 2;
          top_a_if.addr_b[1] = read_counter * 2 + 1;    
          top_a_if.di_a[0] = s_axis_tdata[K-1:0];
          top_a_if.di_a[1] = s_axis_tdata[2*K-1:K];
          top_a_if.di_b[0] = s_axis_tdata[3*K-1:2*K];
          top_a_if.di_b[1] = s_axis_tdata[4*K-1:3*K];

          top_b_if.addr_a[0] = read_counter * 2;
          top_b_if.addr_b[0] = read_counter * 2 + 1;
          top_b_if.addr_a[1] = read_counter * 2;
          top_b_if.addr_b[1] = read_counter * 2 + 1;    
          top_b_if.di_a[0] = s_axis_tdata[5*K-1:4*K];
          top_b_if.di_a[1] = s_axis_tdata[6*K-1:5*K];
          top_b_if.di_b[0] = s_axis_tdata[7*K-1:6*K];
          top_b_if.di_b[1] = s_axis_tdata[8*K-1:7*K];

        end
      end

      NTT: begin
        if(ntt_done1 && ntt_done2) begin
          next_state = COMPUTE;
        end
        else next_state = NTT;
      end

      COMPUTE: begin
        if(conv_done) begin
          next_state = WRITE;
        end
        else next_state = COMPUTE;
      end

      WRITE: begin
        if(write_complete) begin
          next_state = COMPLETE;
        end
        else begin
          top_final_if_a.addr_a[0] = write_counter*2;
          top_final_if_a.addr_b[0] = write_counter*2+1;
          top_final_if_a.addr_a[1] = write_counter*2;
          top_final_if_a.addr_b[1] = write_counter*2+1;

          top_final_if_b.addr_a[0] = write_counter*2;
          top_final_if_b.addr_b[0] = write_counter*2+1;
          top_final_if_b.addr_a[1] = write_counter*2;
          top_final_if_b.addr_b[1] = write_counter*2+1;

          top_final_if_a.en = '{default:1'b1};
          top_final_if_b.en = '{default:1'b1};
          top_final_if_a.we = '{default:1'b0};
          top_final_if_b.we = '{default:1'b0};

          if(write_delay && fifo_ready_r) begin
            d2_tdata[K-1:0] = top_final_if_a.do_a[0];
            d2_tdata[2*K-1:K] = top_final_if_a.do_b[0];
            d2_tdata[3*K-1:2*K] = top_final_if_a.do_a[1];
            d2_tdata[4*K-1:3*K] = top_final_if_a.do_b[1];
            d2_tdata[5*K-1:4*K] = top_final_if_b.do_a[0];
            d2_tdata[6*K-1:5*K] = top_final_if_b.do_b[0];
            d2_tdata[7*K-1:6*K] = top_final_if_b.do_a[1];
            d2_tdata[8*K-1:7*K] = top_final_if_b.do_b[1];
          end
          next_state = WRITE;
        end
      end

      COMPLETE: begin
        next_state = COMPLETE;
          top_a_if.en = '{default:1'b0};
          top_b_if.en = '{default:1'b0};

      end
  endcase
end

// Mux control: use top interface during IDLE, READ, and WRITE stages
always_comb begin
  use_top_interface = (state == IDLE) || (state == READ) || (state == WRITE);
end

// NTT control signals
always_comb begin
  ntt_reset = s_axis_areset;
  ntt_is_intt1 = 1'b0; // Forward NTT for input polynomial a
  ntt_is_intt2 = 1'b0; // Forward NTT for input polynomial b
end

// BRAM interface muxing logic for poly_a_brams
always_comb begin
  if (use_top_interface) begin
    poly_a_brams.addr_a = top_a_if.addr_a;
    poly_a_brams.addr_b = top_a_if.addr_b;
    poly_a_brams.di_a = top_a_if.di_a;
    poly_a_brams.di_b = top_a_if.di_b;
    poly_a_brams.en = top_a_if.en;
    poly_a_brams.we = top_a_if.we;
    top_a_if.do_a = poly_a_brams.do_a;
    top_a_if.do_b = poly_a_brams.do_b;

  end else if (state == NTT) begin
    poly_a_brams.addr_a = ntt_a_if.addr_a;
    poly_a_brams.addr_b = ntt_a_if.addr_b;
    poly_a_brams.di_a = ntt_a_if.di_a;
    poly_a_brams.di_b = ntt_a_if.di_b;
    poly_a_brams.en = ntt_a_if.en;
    poly_a_brams.we = ntt_a_if.we;
    ntt_a_if.do_a = poly_a_brams.do_a;
    ntt_a_if.do_b = poly_a_brams.do_b;

  end else begin
    poly_a_brams.addr_a = conv_a_brams.addr_a;
    poly_a_brams.addr_b = conv_a_brams.addr_b;
    poly_a_brams.di_a = conv_a_brams.di_a;
    poly_a_brams.di_b = conv_a_brams.di_b;
    poly_a_brams.en = conv_a_brams.en;
    poly_a_brams.we = conv_a_brams.we;
    conv_a_brams.do_a = poly_a_brams.do_a;
    conv_a_brams.do_b = poly_a_brams.do_b;
  end

end

always_comb begin
  if (use_top_interface) begin
    poly_b_brams.addr_a = top_b_if.addr_a;
    poly_b_brams.addr_b = top_b_if.addr_b;
    poly_b_brams.di_a = top_b_if.di_a;
    poly_b_brams.di_b = top_b_if.di_b;
    poly_b_brams.en = top_b_if.en;
    poly_b_brams.we = top_b_if.we;
    top_b_if.do_a = poly_b_brams.do_a;
    top_b_if.do_b = poly_b_brams.do_b;
  end else if (state == NTT) begin
    // Mux poly_b_brams with NTT interface during NTT stage
    poly_b_brams.addr_a = ntt_b_if.addr_a;
    poly_b_brams.addr_b = ntt_b_if.addr_b;
    poly_b_brams.di_a = ntt_b_if.di_a;
    poly_b_brams.di_b = ntt_b_if.di_b;
    poly_b_brams.en = ntt_b_if.en;
    poly_b_brams.we = ntt_b_if.we;
    ntt_b_if.do_a = poly_b_brams.do_a;
    ntt_b_if.do_b = poly_b_brams.do_b;
  end else begin
    poly_b_brams.addr_a = conv_b_brams.addr_a;
    poly_b_brams.addr_b = conv_b_brams.addr_b;
    poly_b_brams.di_a = conv_b_brams.di_a;
    poly_b_brams.di_b = conv_b_brams.di_b;
    poly_b_brams.en = conv_b_brams.en;
    poly_b_brams.we = conv_b_brams.we;
    conv_b_brams.do_a = poly_b_brams.do_a;
    conv_b_brams.do_b = poly_b_brams.do_b;
  end
end

// BRAM interface muxing logic for poly_a_final and poly_b_final
always_comb begin
  case(state)
    COMPUTE: begin
      // In COMPUTE stage, mux conv outputs to poly_a_final and poly_b_final
      for (int i = 0; i < 4; i++) begin
        poly_a_final.en[i] = conv_output_a_brams.en[i];
        poly_a_final.we[i] = conv_output_a_brams.we[i];
        poly_a_final.addr_a[i] = conv_output_a_brams.addr_a[i];
        poly_a_final.addr_b[i] = conv_output_a_brams.addr_b[i];
        poly_a_final.di_a[i] = conv_output_a_brams.di_a[i];
        poly_a_final.di_b[i] = conv_output_a_brams.di_b[i];
        conv_output_a_brams.do_a[i] = poly_a_final.do_a[i];
        conv_output_a_brams.do_b[i] = poly_a_final.do_b[i];

        poly_b_final.en[i] = conv_output_b_brams.en[i];
        poly_b_final.we[i] = conv_output_b_brams.we[i];
        poly_b_final.addr_a[i] = conv_output_b_brams.addr_a[i];
        poly_b_final.addr_b[i] = conv_output_b_brams.addr_b[i];
        poly_b_final.di_a[i] = conv_output_b_brams.di_a[i];
        poly_b_final.di_b[i] = conv_output_b_brams.di_b[i];
        conv_output_b_brams.do_a[i] = poly_b_final.do_a[i];
        conv_output_b_brams.do_b[i] = poly_b_final.do_b[i];
      end
    end
    
    WRITE: begin
      // In WRITE stage, mux poly_a_final and poly_b_final to top_final interfaces
      for (int i = 0; i < 4; i++) begin
        poly_a_final.en[i] = top_final_if_a.en[i];
        poly_a_final.we[i] = top_final_if_a.we[i];
        poly_a_final.addr_a[i] = top_final_if_a.addr_a[i];
        poly_a_final.addr_b[i] = top_final_if_a.addr_b[i];
        poly_a_final.di_a[i] = top_final_if_a.di_a[i];
        poly_a_final.di_b[i] = top_final_if_a.di_b[i];
        top_final_if_a.do_a[i] = poly_a_final.do_a[i];
        top_final_if_a.do_b[i] = poly_a_final.do_b[i];

        poly_b_final.en[i] = top_final_if_b.en[i];
        poly_b_final.we[i] = top_final_if_b.we[i];
        poly_b_final.addr_a[i] = top_final_if_b.addr_a[i];
        poly_b_final.addr_b[i] = top_final_if_b.addr_b[i];
        poly_b_final.di_a[i] = top_final_if_b.di_a[i];
        poly_b_final.di_b[i] = top_final_if_b.di_b[i];
        top_final_if_b.do_a[i] = poly_b_final.do_a[i];
        top_final_if_b.do_b[i] = poly_b_final.do_b[i];
      end
    end
    
    default: begin
      // Default: disconnect interfaces
      for (int i = 0; i < 4; i++) begin
        conv_output_a_brams.do_a[i] = '0;
        conv_output_a_brams.do_b[i] = '0;
        conv_output_b_brams.do_a[i] = '0;
        conv_output_b_brams.do_b[i] = '0;
        top_final_if_a.do_a[i] = '0;
        top_final_if_a.do_b[i] = '0;
        top_final_if_b.do_a[i] = '0;
        top_final_if_b.do_b[i] = '0;
      end
    end
  endcase
end

/////////////////////////////////////////////////////////////////////////////

// Register s_axis_interface/inputs

// Tie-off unused inputs to FIFO.

wire we_enable = (s_axis_tvalid && s_axis_tready) || (read_counter == 6'd63);

assign top_a_if.we[0] = we_enable;
assign top_a_if.we[1] = we_enable;
assign top_b_if.we[0] = we_enable;
assign top_b_if.we[1] = we_enable;

always @(posedge s_axis_aclk) begin
  fifo_ready_r <= ~prog_full_axis;
end

assign s_axis_tready = (state==READ);



xpm_fifo_axis #(
   .CDC_SYNC_STAGES     ( 2                      ) , // DECIMAL
   .CLOCKING_MODE       ( LP_CLOCKING_MODE       ) , // String
   .ECC_MODE            ( "no_ecc"               ) , // String
   .FIFO_DEPTH          ( 32                     ) , // DECIMAL
   .FIFO_MEMORY_TYPE    ( "distributed"          ) , // String
   .PACKET_FIFO         ( "false"                ) , // String
   .PROG_EMPTY_THRESH   ( 5                      ) , // DECIMAL
   .PROG_FULL_THRESH    ( 32-5                   ) , // DECIMAL
   .RD_DATA_COUNT_WIDTH ( 6                      ) , // DECIMAL
   .RELATED_CLOCKS      ( 0                      ) , // DECIMAL
   .TDATA_WIDTH         ( C_AXIS_TDATA_WIDTH     ) , // DECIMAL
   .TDEST_WIDTH         ( C_AXIS_TDEST_WIDTH     ) , // DECIMAL
   .TID_WIDTH           ( C_AXIS_TID_WIDTH       ) , // DECIMAL
   .TUSER_WIDTH         ( C_AXIS_TUSER_WIDTH     ) , // DECIMAL
   .USE_ADV_FEATURES    ( "1002"                 ) , // String: Only use prog_full
   .WR_DATA_COUNT_WIDTH ( 6                      )   // DECIMAL
)
inst_xpm_fifo_axis (
   .s_aclk             ( s_axis_aclk    ) ,
   .s_aresetn          ( ~s_axis_areset ) ,
   .s_axis_tvalid      ( d2_tvalid      ) ,
   .s_axis_tready      (                ) ,
   .s_axis_tdata       ( d2_tdata       ) ,
   .s_axis_tstrb       ( d2_tstrb       ) ,
   .s_axis_tkeep       ( d2_tkeep       ) ,
   .s_axis_tlast       ( d2_tlast       ) ,
   .s_axis_tid         ( d2_tid         ) ,
   .s_axis_tdest       ( d2_tdest       ) ,
   .s_axis_tuser       ( d2_tuser       ) ,
   .almost_full_axis   (                ) ,
   .prog_full_axis     ( prog_full_axis ) ,
   .wr_data_count_axis (                ) ,
   .injectdbiterr_axis ( 1'b0           ) ,
   .injectsbiterr_axis ( 1'b0           ) ,

   .m_aclk             ( m_axis_aclk   ) ,
   .m_axis_tvalid      ( m_axis_tvalid ) ,
   .m_axis_tready      ( m_axis_tready ) ,
   .m_axis_tdata       ( m_axis_tdata  ) ,
   .m_axis_tstrb       ( m_axis_tstrb  ) ,
   .m_axis_tkeep       ( m_axis_tkeep  ) ,
   .m_axis_tlast       ( m_axis_tlast  ) ,
   .m_axis_tid         ( m_axis_tid    ) ,
   .m_axis_tdest       ( m_axis_tdest  ) ,
   .m_axis_tuser       ( m_axis_tuser  ) ,
   .almost_empty_axis  (               ) ,
   .prog_empty_axis    (               ) ,
   .rd_data_count_axis (               ) ,
   .sbiterr_axis       (               ) ,
   .dbiterr_axis       (               )
);

endmodule

`default_nettype wire