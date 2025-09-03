// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module AurvaKernel_core #(
  parameter integer C_AXI_M_ADDR_WIDTH = 64 ,
  parameter integer C_AXI_M_DATA_WIDTH = 256
)
(
  // System Signals
  input  wire                            ap_clk       ,
  input  wire                            ap_rst_n     ,
  // AXI4 master interface axi_m
  output wire                            axi_m_awvalid,
  input  wire                            axi_m_awready,
  output wire [C_AXI_M_ADDR_WIDTH-1:0]   axi_m_awaddr ,
  output wire [8-1:0]                    axi_m_awlen  ,
  output wire                            axi_m_wvalid ,
  input  wire                            axi_m_wready ,
  output wire [C_AXI_M_DATA_WIDTH-1:0]   axi_m_wdata  ,
  output wire [C_AXI_M_DATA_WIDTH/8-1:0] axi_m_wstrb  ,
  output wire                            axi_m_wlast  ,
  input  wire                            axi_m_bvalid ,
  output wire                            axi_m_bready ,
  output wire                            axi_m_arvalid,
  input  wire                            axi_m_arready,
  output wire [C_AXI_M_ADDR_WIDTH-1:0]   axi_m_araddr ,
  output wire [8-1:0]                    axi_m_arlen  ,
  input  wire                            axi_m_rvalid ,
  output wire                            axi_m_rready ,
  input  wire [C_AXI_M_DATA_WIDTH-1:0]   axi_m_rdata  ,
  input  wire                            axi_m_rlast  ,
  // Control Signals
  input  wire                            ap_start     ,
  output wire                            ap_idle      ,
  output wire                            ap_done      ,
  output wire                            ap_ready     ,
  input  wire                            start        ,
  input  wire [64-1:0]                   axi_ptr0,
  
  // NTT Debug ports
  output wire [26:0] dbg_ntt_input_a,
  output wire [26:0] dbg_ntt_input_b,
  output wire [26:0] dbg_ntt_twiddle,
  output wire [26:0] dbg_ntt_mult_result,
  output wire [26:0] dbg_ntt_output_a,
  output wire [26:0] dbg_ntt_output_b,
  output wire dbg_ntt_is_intt     
);


timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 256*4*2;
localparam integer  LP_NUM_EXAMPLES    = 1;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                areset                         = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_i                     ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_r                      = {LP_NUM_EXAMPLES{1'b0}};
logic [32-1:0]                       ctrl_xfer_size_in_bytes        = LP_DEFAULT_LENGTH_IN_BYTES;
logic [32-1:0]                       ctrl_constant                  = 32'd1;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

// create pulse when ap_start transitions to 1
always @(posedge ap_clk) begin
  begin
    ap_start_r <= ap_start;
  end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (areset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 :
      ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge ap_clk) begin
  if (areset) begin
    ap_done_r <= '0;
  end
  else begin
    ap_done_r <= (ap_done) ? '0 : ap_done_r | ap_done_i;
  end
end

assign ap_done = &ap_done_r;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;

// Vadd example
AurvaKernel_Main #(
  .C_M_AXI_ADDR_WIDTH ( C_AXI_M_ADDR_WIDTH ),
  .C_M_AXI_DATA_WIDTH ( C_AXI_M_DATA_WIDTH ),
  .C_ADDER_BIT_WIDTH  ( 32                 ),
  .C_XFER_SIZE_WIDTH  ( 32                 )
)
Kernel_Main (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .kernel_clk              ( ap_clk                  ),
  .kernel_rst              ( areset                  ),
  .ctrl_addr_offset        ( axi_ptr0                ),
  .ctrl_xfer_size_in_bytes ( ctrl_xfer_size_in_bytes ),
  .ctrl_constant           ( ctrl_constant           ),
  .ap_start                ( ap_start_pulse          ),
  .ap_done                 ( ap_done_i[0]            ),
  .m_axi_awvalid           ( axi_m_awvalid           ),
  .m_axi_awready           ( axi_m_awready           ),
  .m_axi_awaddr            ( axi_m_awaddr            ),
  .m_axi_awlen             ( axi_m_awlen             ),
  .m_axi_wvalid            ( axi_m_wvalid            ),
  .m_axi_wready            ( axi_m_wready            ),
  .m_axi_wdata             ( axi_m_wdata             ),
  .m_axi_wstrb             ( axi_m_wstrb             ),
  .m_axi_wlast             ( axi_m_wlast             ),
  .m_axi_bvalid            ( axi_m_bvalid            ),
  .m_axi_bready            ( axi_m_bready            ),
  .m_axi_arvalid           ( axi_m_arvalid           ),
  .m_axi_arready           ( axi_m_arready           ),
  .m_axi_araddr            ( axi_m_araddr            ),
  .m_axi_arlen             ( axi_m_arlen             ),
  .m_axi_rvalid            ( axi_m_rvalid            ),
  .m_axi_rready            ( axi_m_rready            ),
  .m_axi_rdata             ( axi_m_rdata             ),
  .m_axi_rlast             ( axi_m_rlast             ),
  .dbg_ntt_input_a(dbg_ntt_input_a),
  .dbg_ntt_input_b(dbg_ntt_input_b),
  .dbg_ntt_twiddle(dbg_ntt_twiddle),
  .dbg_ntt_mult_result(dbg_ntt_mult_result),
  .dbg_ntt_output_a(dbg_ntt_output_a),
  .dbg_ntt_output_b(dbg_ntt_output_b),
  .dbg_ntt_is_intt(dbg_ntt_is_intt)
);


endmodule : AurvaKernel_core
`default_nettype wire
