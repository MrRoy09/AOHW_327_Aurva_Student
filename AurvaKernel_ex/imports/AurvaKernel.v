// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module AurvaKernel #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32 ,
  parameter integer C_AXI_M_ADDR_WIDTH         = 64 ,
  parameter integer C_AXI_M_DATA_WIDTH         = 256
)
(
  // System Signals
  input  wire                                    ap_clk               ,
  input  wire                                    ap_rst_n             ,
  //  Note: A minimum subset of AXI4 memory mapped signals are declared.  AXI
  // signals omitted from these interfaces are automatically inferred with the
  // optimal values for Xilinx accleration platforms.  This allows Xilinx AXI4 Interconnects
  // within the system to be optimized by removing logic for AXI4 protocol
  // features that are not necessary. When adapting AXI4 masters within the RTL
  // kernel that have signals not declared below, it is suitable to add the
  // signals to the declarations below to connect them to the AXI4 Master.
  // 
  // List of ommited signals - effect
  // -------------------------------
  // ID - Transaction ID are used for multithreading and out of order
  // transactions.  This increases complexity. This saves logic and increases Fmax
  // in the system when ommited.
  // SIZE - Default value is log2(data width in bytes). Needed for subsize bursts.
  // This saves logic and increases Fmax in the system when ommited.
  // BURST - Default value (0b01) is incremental.  Wrap and fixed bursts are not
  // recommended. This saves logic and increases Fmax in the system when ommited.
  // LOCK - Not supported in AXI4
  // CACHE - Default value (0b0011) allows modifiable transactions. No benefit to
  // changing this.
  // PROT - Has no effect in current acceleration platforms.
  // QOS - Has no effect in current acceleration platforms.
  // REGION - Has no effect in current acceleration platforms.
  // USER - Has no effect in current acceleration platforms.
  // RESP - Not useful in most acceleration platforms.
  // 
  // AXI4 master interface axi_m
  output wire                                    axi_m_awvalid        ,
  input  wire                                    axi_m_awready        ,
  output wire [C_AXI_M_ADDR_WIDTH-1:0]           axi_m_awaddr         ,
  output wire [8-1:0]                            axi_m_awlen          ,
  output wire                                    axi_m_wvalid         ,
  input  wire                                    axi_m_wready         ,
  output wire [C_AXI_M_DATA_WIDTH-1:0]           axi_m_wdata          ,
  output wire [C_AXI_M_DATA_WIDTH/8-1:0]         axi_m_wstrb          ,
  output wire                                    axi_m_wlast          ,
  input  wire                                    axi_m_bvalid         ,
  output wire                                    axi_m_bready         ,
  output wire                                    axi_m_arvalid        ,
  input  wire                                    axi_m_arready        ,
  output wire [C_AXI_M_ADDR_WIDTH-1:0]           axi_m_araddr         ,
  output wire [8-1:0]                            axi_m_arlen          ,
  input  wire                                    axi_m_rvalid         ,
  output wire                                    axi_m_rready         ,
  input  wire [C_AXI_M_DATA_WIDTH-1:0]           axi_m_rdata          ,
  input  wire                                    axi_m_rlast          ,
  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid,
  output wire                                    s_axi_control_awready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
  input  wire                                    s_axi_control_wvalid ,
  output wire                                    s_axi_control_wready ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
  input  wire                                    s_axi_control_arvalid,
  output wire                                    s_axi_control_arready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
  output wire                                    s_axi_control_rvalid ,
  input  wire                                    s_axi_control_rready ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
  output wire [2-1:0]                            s_axi_control_rresp  ,
  output wire                                    s_axi_control_bvalid ,
  input  wire                                    s_axi_control_bready ,
  output wire [2-1:0]                            s_axi_control_bresp  ,
  output wire                                    interrupt,
  
  // NTT Debug ports
  output wire [26:0] dbg_ntt_input_a,
  output wire [26:0] dbg_ntt_input_b,
  output wire [26:0] dbg_ntt_twiddle,
  output wire [26:0] dbg_ntt_mult_result,
  output wire [26:0] dbg_ntt_output_a,
  output wire [26:0] dbg_ntt_output_b,
  output wire dbg_ntt_is_intt            
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* DONT_TOUCH = "yes" *)
reg                                 areset                         = 1'b0;
wire                                ap_start                      ;
wire                                ap_idle                       ;
wire                                ap_done                       ;
wire                                ap_ready                      ;
wire [1-1:0]                        start                         ;
wire [64-1:0]                       axi_ptr0                    ;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

///////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL.  Modifying not recommended.
///////////////////////////////////////////////////////////////////////////////


// AXI4-Lite slave interface
AurvaKernel_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .ACLK       ( ap_clk                ),
  .ARESET     ( areset                ),
  .ACLK_EN    ( 1'b1                  ),
  .AWVALID    ( s_axi_control_awvalid ),
  .AWREADY    ( s_axi_control_awready ),
  .AWADDR     ( s_axi_control_awaddr  ),
  .WVALID     ( s_axi_control_wvalid  ),
  .WREADY     ( s_axi_control_wready  ),
  .WDATA      ( s_axi_control_wdata   ),
  .WSTRB      ( s_axi_control_wstrb   ),
  .ARVALID    ( s_axi_control_arvalid ),
  .ARREADY    ( s_axi_control_arready ),
  .ARADDR     ( s_axi_control_araddr  ),
  .RVALID     ( s_axi_control_rvalid  ),
  .RREADY     ( s_axi_control_rready  ),
  .RDATA      ( s_axi_control_rdata   ),
  .RRESP      ( s_axi_control_rresp   ),
  .BVALID     ( s_axi_control_bvalid  ),
  .BREADY     ( s_axi_control_bready  ),
  .BRESP      ( s_axi_control_bresp   ),
  .interrupt  ( interrupt             ),
  .ap_start   ( ap_start              ),
  .ap_done    ( ap_done               ),
  .ap_ready   ( ap_ready              ),
  .ap_idle    ( ap_idle               ),
  .start_r      ( start                 ),
  .axi_ptr0 ( axi_ptr0            )
);

///////////////////////////////////////////////////////////////////////////////
// Add kernel logic here.  Modify/remove example code as necessary.
///////////////////////////////////////////////////////////////////////////////

AurvaKernel_core #(
  .C_AXI_M_ADDR_WIDTH ( C_AXI_M_ADDR_WIDTH ),
  .C_AXI_M_DATA_WIDTH ( C_AXI_M_DATA_WIDTH )
)
Kernel_Core_AXI (
  .ap_clk        ( ap_clk        ),
  .ap_rst_n      ( ap_rst_n      ),
  .axi_m_awvalid ( axi_m_awvalid ),
  .axi_m_awready ( axi_m_awready ),
  .axi_m_awaddr  ( axi_m_awaddr  ),
  .axi_m_awlen   ( axi_m_awlen   ),
  .axi_m_wvalid  ( axi_m_wvalid  ),
  .axi_m_wready  ( axi_m_wready  ),
  .axi_m_wdata   ( axi_m_wdata   ),
  .axi_m_wstrb   ( axi_m_wstrb   ),
  .axi_m_wlast   ( axi_m_wlast   ),
  .axi_m_bvalid  ( axi_m_bvalid  ),
  .axi_m_bready  ( axi_m_bready  ),
  .axi_m_arvalid ( axi_m_arvalid ),
  .axi_m_arready ( axi_m_arready ),
  .axi_m_araddr  ( axi_m_araddr  ),
  .axi_m_arlen   ( axi_m_arlen   ),
  .axi_m_rvalid  ( axi_m_rvalid  ),
  .axi_m_rready  ( axi_m_rready  ),
  .axi_m_rdata   ( axi_m_rdata   ),
  .axi_m_rlast   ( axi_m_rlast   ),
  .ap_start      ( ap_start      ),
  .ap_done       ( ap_done       ),
  .ap_idle       ( ap_idle       ),
  .ap_ready      ( ap_ready      ),
  .start         ( start         ),
  .axi_ptr0    ( axi_ptr0    ),
  .dbg_ntt_input_a(dbg_ntt_input_a),
  .dbg_ntt_input_b(dbg_ntt_input_b),
  .dbg_ntt_twiddle(dbg_ntt_twiddle),
  .dbg_ntt_mult_result(dbg_ntt_mult_result),
  .dbg_ntt_output_a(dbg_ntt_output_a),
  .dbg_ntt_output_b(dbg_ntt_output_b),
  .dbg_ntt_is_intt(dbg_ntt_is_intt)
);



endmodule
`default_nettype wire
