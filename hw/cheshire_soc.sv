// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>
// Paul Scheffler <paulsc@iis.ee.ethz.ch>
// Thomas Benz <tbenz@iis.ee.ethz.ch>
// Alessandro Ottaviano <aottaviano@iis.ee.ethz.ch>
// Vincenzo Maisto <vincenzo.maisto2@unina.it>

module cheshire_soc import cheshire_pkg::*; #(
  // Cheshire config
  parameter cheshire_cfg_t Cfg = '0,
  // Debug info for external harts
  parameter dm::hartinfo_t [iomsb(Cfg.NumExtDbgHarts):0] ExtHartinfo = '0,
  // Interconnect types (must agree with Cheshire config)
  parameter type axi_ext_llc_req_t  = logic,
  parameter type axi_ext_llc_rsp_t  = logic,
  parameter type axi_ext_mst_req_t  = logic,
  parameter type axi_ext_mst_rsp_t  = logic,
  parameter type axi_ext_slv_req_t  = logic,
  parameter type axi_ext_slv_rsp_t  = logic,
  parameter type reg_ext_req_t      = logic,
  parameter type reg_ext_rsp_t      = logic
) (
  // DEBUG
  input  logic        xvio_en_ld_st_translation_i,
  input  logic        xvio_mmu_exception_i,
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        test_mode_i,
  input  logic [1:0]  boot_mode_i,
  input  logic        rtc_i,
  // External AXI LLC (DRAM) port
  output axi_ext_llc_req_t axi_llc_mst_req_o,
  input  axi_ext_llc_rsp_t axi_llc_mst_rsp_i,
  // External AXI crossbar ports
  input  axi_ext_mst_req_t [iomsb(Cfg.AxiExtNumMst):0] axi_ext_mst_req_i,
  output axi_ext_mst_rsp_t [iomsb(Cfg.AxiExtNumMst):0] axi_ext_mst_rsp_o,
  output axi_ext_slv_req_t [iomsb(Cfg.AxiExtNumSlv):0] axi_ext_slv_req_o,
  input  axi_ext_slv_rsp_t [iomsb(Cfg.AxiExtNumSlv):0] axi_ext_slv_rsp_i,
  // External reg demux slaves
  output reg_ext_req_t [iomsb(Cfg.RegExtNumSlv):0] reg_ext_slv_req_o,
  input  reg_ext_rsp_t [iomsb(Cfg.RegExtNumSlv):0] reg_ext_slv_rsp_i,
  // Interrupts from and to external targets
  input  logic [iomsb(Cfg.NumExtInIntrs):0]                                   intr_ext_i,
  output logic [iomsb(Cfg.NumExtOutIntrTgts):0][iomsb(Cfg.NumExtOutIntrs):0]  intr_ext_o,
  // Interrupt requests to external harts
  output logic [iomsb(NumIrqCtxts*Cfg.NumExtIrqHarts):0] xeip_ext_o,
  output logic [iomsb(Cfg.NumExtIrqHarts):0]             mtip_ext_o,
  output logic [iomsb(Cfg.NumExtIrqHarts):0]             msip_ext_o,
  // Debug interface to external harts
  output logic                                dbg_active_o,
  output logic [iomsb(Cfg.NumExtDbgHarts):0]  dbg_ext_req_o,
  input  logic [iomsb(Cfg.NumExtDbgHarts):0]  dbg_ext_unavail_i,
  // JTAG interface
  input  logic  jtag_tck_i,
  input  logic  jtag_trst_ni,
  input  logic  jtag_tms_i,
  input  logic  jtag_tdi_i,
  output logic  jtag_tdo_o,
  output logic  jtag_tdo_oe_o,
  // UART interface
  output logic  uart_tx_o,
  input  logic  uart_rx_i,
  // UART modem flow control
  output logic  uart_rts_no,
  output logic  uart_dtr_no,
  input  logic  uart_cts_ni,
  input  logic  uart_dsr_ni,
  input  logic  uart_dcd_ni,
  input  logic  uart_rin_ni,
  // I2C interface
  output logic  i2c_sda_o,
  input  logic  i2c_sda_i,
  output logic  i2c_sda_en_o,
  output logic  i2c_scl_o,
  input  logic  i2c_scl_i,
  output logic  i2c_scl_en_o,
  // SPI host interface
  output logic                  spih_sck_o,
  output logic                  spih_sck_en_o,
  output logic [SpihNumCs-1:0]  spih_csb_o,
  output logic [SpihNumCs-1:0]  spih_csb_en_o,
  output logic [ 3:0]           spih_sd_o,
  output logic [ 3:0]           spih_sd_en_o,
  input  logic [ 3:0]           spih_sd_i,
  // GPIO interface
  input  logic [31:0] gpio_i,
  output logic [31:0] gpio_o,
  output logic [31:0] gpio_en_o,
  // Serial link interface
  input  logic [SlinkNumChan-1:0]                     slink_rcv_clk_i,
  output logic [SlinkNumChan-1:0]                     slink_rcv_clk_o,
  input  logic [SlinkNumChan-1:0][SlinkNumLanes-1:0]  slink_i,
  output logic [SlinkNumChan-1:0][SlinkNumLanes-1:0]  slink_o,
  // VGA interface
  output logic                          vga_hsync_o,
  output logic                          vga_vsync_o,
  output logic [Cfg.VgaRedWidth  -1:0]  vga_red_o,
  output logic [Cfg.VgaGreenWidth-1:0]  vga_green_o,
  output logic [Cfg.VgaBlueWidth -1:0]  vga_blue_o
);

  `include "axi/typedef.svh"
  `include "common_cells/registers.svh"
  `include "common_cells/assertions.svh"
  `include "cheshire/typedef.svh"

  // Declare interface types internally
  `CHESHIRE_TYPEDEF_ALL(, Cfg)

  //////////////////
  //  Interrupts  //
  //////////////////

  localparam int unsigned NumIntHarts     = Cfg.NumCores;
  localparam int unsigned NumIrqHarts     = NumIntHarts + Cfg.NumExtIrqHarts;
  localparam int unsigned NumRtdIntrTgts  = 1 + NumIntHarts + Cfg.NumExtOutIntrTgts;
  localparam int unsigned NumClicSysIntrs = NumIntIntrs + Cfg.NumExtClicIntrs;
  localparam int unsigned NumClicIntrs    = NumCoreIrqs + NumClicSysIntrs;
  localparam int unsigned IntrRtdPlic     = 0;
  localparam int unsigned IntrRtdCoreBase = 1;
  localparam int unsigned IntrRtdExtBase  = IntrRtdCoreBase + NumIntHarts;

  // This routable type is as wide or wider than all targets.
  // It must be truncated before target connection.
  typedef struct packed {
    logic [iomsb(Cfg.NumExtInIntrs):0] ext;
    cheshire_int_intr_t                intn;
  } cheshire_intr_t;

  typedef struct packed {
    logic [NumClicSysIntrs-1:0] intr;
    cheshire_core_ip_t          core;
  } cheshire_intr_clic_t;

  // Interrupts from internal devices and external sources
  cheshire_intr_t intr;

  // Interrupts from router (or target fanout)
  cheshire_intr_t [NumRtdIntrTgts-1:0] intr_routed;

  // Interrupt requests to all interruptible harts
  cheshire_xeip_t [NumIrqHarts-1:0] xeip;
  logic           [NumIrqHarts-1:0] mtip, msip;

  // Interrupt 0 is hardwired to zero by convention.
  // Other internal interrupts are synchronous (for now) and need not be synced;
  // we wire them directly to internal synchronous devices.
  assign intr.intn.zero  = 0;

  // External interrupts must be synchronized to this domain
  for (genvar i = 0; i <= iomsb(Cfg.NumExtInIntrs); i++) begin : gen_ext_in_intr_syncs
    sync #(
      .STAGES     ( Cfg.NumExtIntrSyncs ),
      .ResetValue ( 1'b0 )
    ) i_ext_intr_sync (
      .clk_i,
      .rst_ni,
      .serial_i ( intr_ext_i[i] ),
      .serial_o ( intr.ext[i]   )
    );
  end

  // Connect routed outgoing interrupts to external targets (implicit truncation)
  if (Cfg.NumExtOutIntrTgts) begin : gen_ext_out_intrs
    for (genvar i = 0; i < Cfg.NumExtOutIntrTgts; ++i) begin : gen_ext_out_intr_conn
      assign intr_ext_o[i] = intr_routed[IntrRtdExtBase+i];
    end
  end else begin : gen_no_ext_out_intrs
    assign intr_ext_o[0] = '0;
  end

  // Forward IRQs to external interruptible harts if any
  if (Cfg.NumExtIrqHarts != 0) begin : gen_ext_irqs
    // We assume that machine and supervisor external interrupts are stacked
    assign xeip_ext_o = xeip[NumIrqHarts-1:NumIntHarts];
    assign mtip_ext_o = mtip[NumIrqHarts-1:NumIntHarts];
    assign msip_ext_o = msip[NumIrqHarts-1:NumIntHarts];
  end else begin : gen_no_ext_irqs
    assign xeip_ext_o = '0;
    assign mtip_ext_o = '0;
    assign msip_ext_o = '0;
  end

  ////////////////
  //  AXI Xbar  //
  ////////////////

  // Generate indices and get maps for all ports
  localparam axi_in_t   AxiIn   = gen_axi_in(Cfg);
  localparam axi_out_t  AxiOut  = gen_axi_out(Cfg);

  // Define needed parameters
  localparam int unsigned AxiStrbWidth  = Cfg.AxiDataWidth / 8;
  localparam int unsigned AxiSlvIdWidth = Cfg.AxiMstIdWidth + $clog2(AxiIn.num_in);

  // Type for address map entries
  typedef struct packed {
    logic [$bits(aw_bt)-1:0] idx;
    addr_t start_addr;
    addr_t end_addr;
  } addr_rule_t;

  // Generate address map
  function automatic addr_rule_t [AxiOut.num_rules-1:0] gen_axi_map();
    addr_rule_t [AxiOut.num_rules-1:0] ret;
    for (int i = 0; i < AxiOut.num_rules; ++i)
      ret[i] = '{idx: AxiOut.map[i].idx,
          start_addr: AxiOut.map[i].start, end_addr: AxiOut.map[i].pte};
    return ret;
  endfunction

  localparam addr_rule_t [AxiOut.num_rules-1:0] AxiMap = gen_axi_map();

  // Connectivity of Xbar
  axi_mst_req_t [AxiIn.num_in-1:0]    axi_in_req, axi_rt_in_req;
  axi_mst_rsp_t [AxiIn.num_in-1:0]    axi_in_rsp, axi_rt_in_rsp;
  axi_slv_req_t [AxiOut.num_out-1:0]  axi_out_req;
  axi_slv_rsp_t [AxiOut.num_out-1:0]  axi_out_rsp;

  // Configure AXI Xbar
  localparam axi_pkg::xbar_cfg_t AxiXbarCfg = '{
    NoSlvPorts:         AxiIn.num_in,
    NoMstPorts:         AxiOut.num_out,
    MaxMstTrans:        Cfg.AxiMaxMstTrans,
    MaxSlvTrans:        Cfg.AxiMaxSlvTrans,
    FallThrough:        0,
    LatencyMode:        axi_pkg::CUT_ALL_PORTS,
    PipelineStages:     0,
    AxiIdWidthSlvPorts: Cfg.AxiMstIdWidth,
    AxiIdUsedSlvPorts:  Cfg.AxiMstIdWidth,
    UniqueIds:          0,
    AxiAddrWidth:       Cfg.AddrWidth,
    AxiDataWidth:       Cfg.AxiDataWidth,
    NoAddrRules:        AxiOut.num_rules
  };

  axi_xbar #(
    .Cfg            ( AxiXbarCfg ),
    .ATOPs          ( 1  ),
    .Connectivity   ( '1 ),
    .slv_aw_chan_t  ( axi_mst_aw_chan_t ),
    .mst_aw_chan_t  ( axi_slv_aw_chan_t ),
    .w_chan_t       ( axi_mst_w_chan_t  ),
    .slv_b_chan_t   ( axi_mst_b_chan_t  ),
    .mst_b_chan_t   ( axi_slv_b_chan_t  ),
    .slv_ar_chan_t  ( axi_mst_ar_chan_t ),
    .mst_ar_chan_t  ( axi_slv_ar_chan_t ),
    .slv_r_chan_t   ( axi_mst_r_chan_t  ),
    .mst_r_chan_t   ( axi_slv_r_chan_t  ),
    .slv_req_t      ( axi_mst_req_t ),
    .slv_resp_t     ( axi_mst_rsp_t ),
    .mst_req_t      ( axi_slv_req_t ),
    .mst_resp_t     ( axi_slv_rsp_t ),
    .rule_t         ( addr_rule_t )
  ) i_axi_xbar (
    .clk_i,
    .rst_ni,
    .test_i                 ( test_mode_i ),
    .slv_ports_req_i        ( axi_rt_in_req ),
    .slv_ports_resp_o       ( axi_rt_in_rsp ),
    .mst_ports_req_o        ( axi_out_req ),
    .mst_ports_resp_i       ( axi_out_rsp ),
    .addr_map_i             ( AxiMap ),
    .en_default_mst_port_i  ( '0 ),
    .default_mst_port_i     ( '0 )
  );

  // Connect external masters
  if (Cfg.AxiExtNumMst > 0) begin : gen_ext_axi_mst
    assign axi_in_req[AxiIn.num_in-1:AxiIn.ext_base] = axi_ext_mst_req_i;
    assign axi_ext_mst_rsp_o = axi_in_rsp[AxiIn.num_in-1:AxiIn.ext_base];
  end else begin : gen_no_ext_axi_mst
    assign axi_ext_mst_rsp_o = '0;
  end

  // Connect external slaves
  if (Cfg.AxiExtNumSlv > 0) begin : gen_ext_axi_slv
    assign axi_ext_slv_req_o = axi_out_req[AxiOut.num_out-1:AxiOut.ext_base];
    assign axi_out_rsp[AxiOut.num_out-1:AxiOut.ext_base] = axi_ext_slv_rsp_i;
  end else begin : gen_no_ext_axi_slv
    assign axi_ext_slv_req_o = '0;
  end

  /////////////////
  //  Reg demux  //
  /////////////////

  // Define types needed
  `CHESHIRE_TYPEDEF_AXI_CT(axi_d32, addr_t, axi_slv_id_t, logic [31:0], logic [3:0], axi_user_t)

  // Generate indices and get maps for all ports
  localparam reg_out_t  RegOut = gen_reg_out(Cfg);

  // Generate Reg address map
  function automatic addr_rule_t [RegOut.num_rules-1:0] gen_reg_map();
    addr_rule_t [RegOut.num_rules-1:0] ret;
    for (int i = 0; i < RegOut.num_rules; ++i)
      ret[i] = '{idx: RegOut.map[i].idx,
          start_addr: RegOut.map[i].start, end_addr: RegOut.map[i].pte};
    return ret;
  endfunction

  localparam addr_rule_t [RegOut.num_rules-1:0] RegMap = gen_reg_map();

  logic [cf_math_pkg::idx_width(RegOut.num_out)-1:0] reg_select;

  axi_slv_req_t axi_reg_amo_req, axi_reg_cut_req;
  axi_slv_rsp_t axi_reg_amo_rsp, axi_reg_cut_rsp;


  reg_req_t reg_in_req;
  reg_rsp_t reg_in_rsp;

  logic[AxiSlvIdWidth-1:0] reg_id;

  reg_req_t [RegOut.num_out-1:0] reg_out_req;
  reg_rsp_t [RegOut.num_out-1:0] reg_out_rsp;

  // Shim atomics, which are not supported in reg
  // TODO: should we use a filter instead here?
  axi_riscv_atomics_structs #(
    .AxiAddrWidth     ( Cfg.AddrWidth    ),
    .AxiDataWidth     ( Cfg.AxiDataWidth ),
    .AxiIdWidth       ( AxiSlvIdWidth    ),
    .AxiUserWidth     ( Cfg.AxiUserWidth ),
    .AxiMaxReadTxns   ( Cfg.RegMaxReadTxns  ),
    .AxiMaxWriteTxns  ( Cfg.RegMaxWriteTxns ),
    .AxiUserAsId      ( 1 ),
    .AxiUserIdMsb     ( Cfg.AxiUserAmoMsb ),
    .AxiUserIdLsb     ( Cfg.AxiUserAmoLsb ),
    .RiscvWordWidth   ( 64 ),
    .NAxiCuts         ( Cfg.RegAmoNumCuts ),
    .axi_req_t        ( axi_slv_req_t ),
    .axi_rsp_t        ( axi_slv_rsp_t )
  ) i_reg_atomics (
    .clk_i,
    .rst_ni,
    .axi_slv_req_i ( axi_out_req[AxiOut.reg_demux] ),
    .axi_slv_rsp_o ( axi_out_rsp[AxiOut.reg_demux] ),
    .axi_mst_req_o ( axi_reg_amo_req ),
    .axi_mst_rsp_i ( axi_reg_amo_rsp )
  );

  axi_cut #(
    .Bypass     ( ~Cfg.RegAmoPostCut ),
    .aw_chan_t  ( axi_slv_aw_chan_t ),
    .w_chan_t   ( axi_slv_w_chan_t  ),
    .b_chan_t   ( axi_slv_b_chan_t  ),
    .ar_chan_t  ( axi_slv_ar_chan_t ),
    .r_chan_t   ( axi_slv_r_chan_t  ),
    .axi_req_t  ( axi_slv_req_t ),
    .axi_resp_t ( axi_slv_rsp_t )
  ) i_reg_atomics_cut (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( axi_reg_amo_req ),
    .slv_resp_o ( axi_reg_amo_rsp ),
    .mst_req_o  ( axi_reg_cut_req ),
    .mst_resp_i ( axi_reg_cut_rsp )
  );

  // Convert from AXI to reg protocol
  axi_to_reg_v2 #(
    .AxiAddrWidth ( Cfg.AddrWidth    ),
    .AxiDataWidth ( Cfg.AxiDataWidth ),
    .AxiIdWidth   ( AxiSlvIdWidth    ),
    .AxiUserWidth ( Cfg.AxiUserWidth ),
    .RegDataWidth ( 32'd32 ),
    .axi_req_t    ( axi_slv_req_t ),
    .axi_rsp_t    ( axi_slv_rsp_t ),
    .reg_req_t    ( reg_req_t ),
    .reg_rsp_t    ( reg_rsp_t )
  ) i_axi_to_reg_v2 (
    .clk_i,
    .rst_ni,
    .axi_req_i ( axi_reg_cut_req ),
    .axi_rsp_o ( axi_reg_cut_rsp ),
    .reg_req_o ( reg_in_req ),
    .reg_rsp_i ( reg_in_rsp ),
    .reg_id_o  ( reg_id     ),
    .busy_o    ( )
  );

  // Non-matching addresses are directed to an error slave
  addr_decode #(
    .NoIndices  ( RegOut.num_out   ),
    .NoRules    ( RegOut.num_rules ),
    .addr_t     ( addr_t      ),
    .rule_t     ( addr_rule_t )
  ) i_reg_demux_decode (
    .addr_i           ( reg_in_req.addr ),
    .addr_map_i       ( RegMap ),
    .idx_o            ( reg_select ),
    .dec_valid_o      ( ),
    .dec_error_o      ( ),
    .en_default_idx_i ( 1'b1 ),
    .default_idx_i    ( (cf_math_pkg::idx_width(RegOut.num_out))'(RegOut.err) )
  );

  reg_demux #(
    .NoPorts  ( RegOut.num_out ),
    .req_t    ( reg_req_t ),
    .rsp_t    ( reg_rsp_t )
  ) i_reg_demux (
    .clk_i,
    .rst_ni,
    .in_select_i  ( reg_select  ),
    .in_req_i     ( reg_in_req  ),
    .in_rsp_o     ( reg_in_rsp  ),
    .out_req_o    ( reg_out_req ),
    .out_rsp_i    ( reg_out_rsp )
  );

  reg_err_slv #(
    .DW       ( 32 ),
    .ERR_VAL  ( 32'hBADCAB1E ),
    .req_t    ( reg_req_t ),
    .rsp_t    ( reg_rsp_t )
  ) i_reg_err_slv (
    .req_i  ( reg_out_req[RegOut.err] ),
    .rsp_o  ( reg_out_rsp[RegOut.err] )
  );

  // Connect external slaves
  if (Cfg.RegExtNumSlv > 0) begin : gen_ext_reg_slv
    assign reg_ext_slv_req_o = reg_out_req[RegOut.num_out-1:RegOut.ext_base];
    assign reg_out_rsp[RegOut.num_out-1:RegOut.ext_base] = reg_ext_slv_rsp_i;
  end else begin : gen_no_ext_reg_slv
    assign reg_ext_slv_req_o = '0;
  end

  ///////////
  //  LLC  //
  ///////////

  axi_slv_req_t axi_llc_cut_req;
  axi_slv_rsp_t axi_llc_cut_rsp;

  if (Cfg.LlcOutConnect) begin : gen_llc_atomics

    axi_slv_req_t axi_llc_amo_req;
    axi_slv_rsp_t axi_llc_amo_rsp;

    // Shim atomics, which are not supported by LLC
    // TODO: This should be a filter, but how do we filter RISC-V atomics?
    axi_riscv_atomics_structs #(
      .AxiAddrWidth     ( Cfg.AddrWidth    ),
      .AxiDataWidth     ( Cfg.AxiDataWidth ),
      .AxiIdWidth       ( AxiSlvIdWidth    ),
      .AxiUserWidth     ( Cfg.AxiUserWidth ),
      .AxiMaxReadTxns   ( Cfg.LlcMaxReadTxns  ),
      .AxiMaxWriteTxns  ( Cfg.LlcMaxWriteTxns ),
      .AxiUserAsId      ( 1 ),
      .AxiUserIdMsb     ( Cfg.AxiUserAmoMsb ),
      .AxiUserIdLsb     ( Cfg.AxiUserAmoLsb ),
      .RiscvWordWidth   ( 64 ),
      .NAxiCuts         ( Cfg.LlcAmoNumCuts ),
      .axi_req_t        ( axi_slv_req_t ),
      .axi_rsp_t        ( axi_slv_rsp_t )
    ) i_llc_atomics (
      .clk_i,
      .rst_ni,
      .axi_slv_req_i ( axi_out_req[AxiOut.llc] ),
      .axi_slv_rsp_o ( axi_out_rsp[AxiOut.llc] ),
      .axi_mst_req_o ( axi_llc_amo_req ),
      .axi_mst_rsp_i ( axi_llc_amo_rsp )
    );

    axi_cut #(
      .Bypass     ( ~Cfg.LlcAmoPostCut ),
      .aw_chan_t  ( axi_slv_aw_chan_t ),
      .w_chan_t   ( axi_slv_w_chan_t  ),
      .b_chan_t   ( axi_slv_b_chan_t  ),
      .ar_chan_t  ( axi_slv_ar_chan_t ),
      .r_chan_t   ( axi_slv_r_chan_t  ),
      .axi_req_t  ( axi_slv_req_t ),
      .axi_resp_t ( axi_slv_rsp_t )
    ) i_llc_atomics_cut (
      .clk_i,
      .rst_ni,
      .slv_req_i  ( axi_llc_amo_req ),
      .slv_resp_o ( axi_llc_amo_rsp ),
      .mst_req_o  ( axi_llc_cut_req ),
      .mst_resp_i ( axi_llc_cut_rsp )
    );

  end

  if (Cfg.LlcOutConnect && Cfg.LlcNotBypass) begin : gen_llc

    axi_slv_req_t axi_llc_remap_req;
    axi_slv_rsp_t axi_llc_remap_rsp;

    // Remap both cached and uncached accesses to single base.
    // This is necessary for routing in the LLC-internal interconnect.
    always_comb begin
      axi_llc_remap_req = axi_llc_cut_req;
      if (axi_llc_cut_req.aw.addr & ~AmSpmRegionMask == AmSpmBaseUncached & ~AmSpmRegionMask)
        axi_llc_remap_req.aw.addr  = AmSpm | (AmSpmRegionMask & axi_llc_cut_req.aw.addr);
      if (axi_llc_cut_req.ar.addr & ~AmSpmRegionMask == AmSpmBaseUncached & ~AmSpmRegionMask)
        axi_llc_remap_req.ar.addr = AmSpm | (AmSpmRegionMask & axi_llc_cut_req.ar.addr);
      axi_llc_cut_rsp = axi_llc_remap_rsp;
    end

    axi_llc_reg_wrap #(
      .SetAssociativity ( Cfg.LlcSetAssoc  ),
      .NumLines         ( Cfg.LlcNumLines  ),
      .NumBlocks        ( Cfg.LlcNumBlocks ),
      .AxiIdWidth       ( AxiSlvIdWidth    ),
      .AxiAddrWidth     ( Cfg.AddrWidth    ),
      .AxiDataWidth     ( Cfg.AxiDataWidth ),
      .AxiUserWidth     ( Cfg.AxiUserWidth ),
      .slv_req_t        ( axi_slv_req_t ),
      .slv_resp_t       ( axi_slv_rsp_t ),
      .mst_req_t        ( axi_ext_llc_req_t ),
      .mst_resp_t       ( axi_ext_llc_rsp_t ),
      .reg_req_t        ( reg_req_t ),
      .reg_resp_t       ( reg_rsp_t ),
      .rule_full_t      ( addr_rule_t )
    ) i_llc (
      .clk_i,
      .rst_ni,
      .test_i              ( test_mode_i ),
      .slv_req_i           ( axi_llc_remap_req ),
      .slv_resp_o          ( axi_llc_remap_rsp ),
      .mst_req_o           ( axi_llc_mst_req_o ),
      .mst_resp_i          ( axi_llc_mst_rsp_i ),
      .conf_req_i          ( reg_out_req[RegOut.llc] ),
      .conf_resp_o         ( reg_out_rsp[RegOut.llc] ),
      .cached_start_addr_i ( addr_t'(Cfg.LlcOutRegionStart) ),
      .cached_end_addr_i   ( addr_t'(Cfg.LlcOutRegionEnd)   ),
      .spm_start_addr_i    ( addr_t'(AmSpm) ),
      .axi_llc_events_o    ( /* TODO: connect me to regs? */ )
    );

  end else if (Cfg.LlcOutConnect) begin : gen_llc_bypass

    assign axi_llc_mst_req_o  = axi_llc_cut_req;
    assign axi_llc_cut_rsp    = axi_llc_mst_rsp_i;

  end else begin : gen_llc_stubout

    assign axi_llc_mst_req_o  = '0;

  end

  /////////////
  //  Cores  //
  /////////////

  // TODO: Implement WIP coherent dual-core CVA6
  // TODO: Implement X interface support

  `CHESHIRE_TYPEDEF_AXI_CT(axi_cva6, addr_t, cva6_id_t, axi_data_t, axi_strb_t, axi_user_t)

  localparam ariane_pkg::ariane_cfg_t Cva6Cfg = gen_cva6_cfg(Cfg);

  // Boot from boot ROM only if available, otherwise from platform ROM
  localparam logic [63:0] BootAddr = 64'(Cfg.Bootrom ? AmBrom : Cfg.PlatformRom);

  // Debug interface for internal harts
  dm::hartinfo_t [NumIntHarts-1:0] dbg_int_info;
  logic          [NumIntHarts-1:0] dbg_int_unavail;
  logic          [NumIntHarts-1:0] dbg_int_req;

  // All internal harts are CVA6 and always available
  assign dbg_int_info     = {(NumIntHarts){ariane_pkg::DebugHartInfo}};
  assign dbg_int_unavail  = '0;

  for (genvar i = 0; i < NumIntHarts; i++) begin : gen_cva6_cores
    axi_cva6_req_t core_out_req, core_ur_req;
    axi_cva6_rsp_t core_out_rsp, core_ur_rsp;

    // CLIC interface
    logic clic_irq_valid, clic_irq_ready;
    logic clic_irq_kill_req, clic_irq_kill_ack;
    logic clic_irq_shv;
    logic [$clog2(NumClicIntrs)-1:0] clic_irq_id;
    logic [7:0]        clic_irq_level;
    riscv::priv_lvl_t  clic_irq_priv;

    // Accelerator ports
    acc_pkg::accelerator_req_t            acc_req;
    acc_pkg::accelerator_resp_t           acc_resp;

    // Invalidation filter ports
    logic                                 acc_cons_en;
    logic             [Cfg.AddrWidth-1:0] inval_addr;
    logic                                 inval_valid;
    logic                                 inval_ready;
    
    // CSR 
    logic                          en_ld_st_translation_cva6_acc;

    // MMU ports
    ariane_pkg::exception_t        mmu_misaligned_ex_acc_cva6;
    logic                          mmu_req_acc_cva6;
    logic [riscv::VLEN-1:0]        mmu_vaddr_acc_cva6;
    logic                          mmu_is_store_acc_cva6;
    logic                          mmu_dtlb_hit_cva6_acc;
    logic [riscv::PPNW-1:0]        mmu_dtlb_ppn_cva6_acc;
    logic                          mmu_valid_cva6_acc;
    logic [riscv::PLEN-1:0]        mmu_paddr_cva6_acc;
    ariane_pkg::exception_t        mmu_exception_cva6_acc;

    // Currently, we support only one core
    cva6 #(
      .ArianeCfg      ( Cva6Cfg ),
      .AxiAddrWidth   ( Cfg.AddrWidth ),
      .AxiDataWidth   ( Cfg.AxiDataWidth ),
      .AxiIdWidth     ( Cva6IdWidth ),
      .cvxif_req_t    ( acc_pkg::accelerator_req_t  ),
      .cvxif_resp_t   ( acc_pkg::accelerator_resp_t ),
      .axi_ar_chan_t  ( axi_cva6_ar_chan_t ),
      .axi_aw_chan_t  ( axi_cva6_aw_chan_t ),
      .axi_w_chan_t   ( axi_cva6_w_chan_t  ),
      .axi_req_t      ( axi_cva6_req_t ),
      .axi_rsp_t      ( axi_cva6_rsp_t )
    ) i_core_cva6 (
      .clk_i,
      .rst_ni,
      .boot_addr_i      ( BootAddr ),
      .hart_id_i        ( 64'(i) ),
      .irq_i            ( xeip[i] ),
      .ipi_i            ( msip[i] ),
      .time_irq_i       ( mtip[i] ),
      .debug_req_i      ( dbg_int_req[i] ),
      .rvfi_o           ( ),
      .l15_req_o        ( ),
      .l15_rtrn_i       ( '0 ),
      // Accelerator ports
      .cvxif_req_o      ( acc_req      ),
      .cvxif_resp_i     ( acc_resp     ),
  `ifdef ARIANE_ACCELERATOR_PORT
      // Invalidation requests
      .acc_cons_en_o    ( acc_cons_en  ),
      .inval_addr_i     ( inval_addr   ),
      .inval_valid_i    ( inval_valid  ),
      .inval_ready_o    ( inval_ready  ),
  // `ifdef ACC_MMU_INTERFACE
      // CSR output
      .en_ld_st_translation_o   ( en_ld_st_translation_cva6_acc ),
      // // MMU interface with accelerator
      .acc_mmu_misaligned_ex_i  ( '0 ),
      .acc_mmu_req_i            ( '0 ),
      .acc_mmu_vaddr_i          ( '0 ),
      .acc_mmu_is_store_i       ( '0 ),
      // .acc_mmu_misaligned_ex_i  ( mmu_misaligned_ex_acc_cva6 ),
      // .acc_mmu_req_i            ( mmu_req_acc_cva6           ),
      // .acc_mmu_vaddr_i          ( mmu_vaddr_acc_cva6         ),
      // .acc_mmu_is_store_i       ( mmu_is_store_acc_cva6      ),
      // .acc_mmu_dtlb_hit_o       ( mmu_dtlb_hit_cva6_acc      ),
      // .acc_mmu_dtlb_ppn_o       ( mmu_dtlb_ppn_cva6_acc      ),
      // .acc_mmu_valid_o          ( mmu_valid_cva6_acc         ),
      // .acc_mmu_paddr_o          ( mmu_paddr_cva6_acc         ),
      // .acc_mmu_exception_o      ( mmu_exception_cva6_acc     ),
  // `endif // ACC_MMU_INTERFACE
  `endif // ARIANE_ACCELERATOR_PORT
      // AXI interface
      .axi_req_o        ( core_out_req ),
      .axi_resp_i       ( core_out_rsp )
    );

`ifdef ARA
`ifdef ARA_INTEGRATION_V0_2  

    // v0.2: axi data with converter
    // NOTE: might reduce Ara's load/store throughput
    // NOTE: tune axi_dw_converter.AxiMaxReads w.r.t. ARA_NR_LANES
    //
    //        axi_ara_wide                  axi_ara_wide_req_inval                axi_ara_narrow __________
    //  ARA -(32*NrLanes)--> i_axi_inval_filter -(32*NrLanes)-> axi_dw_converter ----(64)------>|          |
    //                           |                                                              |          |
    //                           |                                                              | axi_xbar |
    //                           v                                                              |          |
    //                         CVA6 ---(64)---> i_axi_id_serialize ------------------(64)------>|__________|
    //                                

    // Configure Ara with the right AXI id width
    typedef logic [Cfg.AxiMstIdWidth-1:0] ara_id_t;
    // Default Ara AXI data width
    localparam int unsigned AraDataWideWidth = 32 * `ARA_NR_LANES;
    typedef logic [AraDataWideWidth   -1 : 0] axi_ara_wide_data_t;
    typedef logic [AraDataWideWidth/8 -1 : 0] axi_ara_wide_strb_t;
    `AXI_TYPEDEF_ALL(axi_ara_wide, addr_t, ara_id_t, axi_ara_wide_data_t, axi_ara_wide_strb_t, axi_user_t)
    axi_ara_wide_req_t     axi_ara_wide_req_inval, axi_ara_wide_req;
    axi_ara_wide_resp_t    axi_ara_wide_resp_inval, axi_ara_wide_resp;

    axi_mst_req_t     axi_ara_narrow_req;
    axi_mst_rsp_t     axi_ara_narrow_resp;

    ara #(
      .NrLanes      ( `ARA_NR_LANES          ),
      .AxiDataWidth ( AraDataWideWidth       ),
      .AxiAddrWidth ( Cfg.AddrWidth          ),
      .axi_ar_t     ( axi_ara_wide_ar_chan_t ),
      .axi_r_t      ( axi_ara_wide_r_chan_t  ),
      .axi_aw_t     ( axi_ara_wide_aw_chan_t ),
      .axi_w_t      ( axi_ara_wide_w_chan_t  ),
      .axi_b_t      ( axi_ara_wide_b_chan_t  ),
      .axi_req_t    ( axi_ara_wide_req_t     ),
      .axi_resp_t   ( axi_ara_wide_resp_t    )
    ) i_ara (
      .clk_i           ( clk_i             ),
      .rst_ni          ( rst_ni            ),
      .scan_enable_i   ( 1'b0              ),
      .scan_data_i     ( 1'b0              ),
      .scan_data_o     ( /* Unused */      ),
  // `ifdef ACC_MMU_INTERFACE
      // .en_ld_st_translation_i ( en_ld_st_translation_cva6_acc ),
      .en_ld_st_translation_i ( xvio_en_ld_st_translation_i ),
      .mmu_misaligned_ex_o ( mmu_misaligned_ex_acc_cva6 ),
      .mmu_req_o           ( mmu_req_acc_cva6           ),
      .mmu_vaddr_o         ( mmu_vaddr_acc_cva6         ),
      .mmu_is_store_o      ( mmu_is_store_acc_cva6      ),
      .mmu_dtlb_hit_i      ( mmu_dtlb_hit_cva6_acc      ),
      .mmu_dtlb_ppn_i      ( mmu_dtlb_ppn_cva6_acc      ),
      .mmu_valid_i         ( mmu_valid_cva6_acc         ),
      .mmu_paddr_i         ( mmu_paddr_cva6_acc         ),
      .mmu_exception_i     ( mmu_exception_cva6_acc     ),
  // `endif // ACC_MMU_INTERFACE
      .acc_req_i       ( acc_req           ),
      .acc_resp_o      ( acc_resp          ),
      .axi_req_o       ( axi_ara_wide_req  ),
      .axi_resp_i      ( axi_ara_wide_resp )
    );


    // DEBUG: MMU stub
`ifdef MMU_STUB
    mmu_stub i_mmu_stub (
      .clk_i                  ( clk_i                       ),
      .rst_ni                 ( rst_ni                      ),
      .en_ld_st_translation_i ( xvio_en_ld_st_translation_i ),  
      .trigger_exception_i    ( xvio_mmu_exception_i        ),     
      .misaligned_ex_i        ( mmu_misaligned_ex_acc_cva6  ),         
      .req_i                  ( mmu_req_acc_cva6            ),
      .vaddr_i                ( mmu_vaddr_acc_cva6          ),
      .is_store_i             ( mmu_is_store_acc_cva6       ),              
      .dtlb_hit_o             ( mmu_dtlb_hit_cva6_acc       ),
      .dtlb_ppn_o             ( mmu_dtlb_ppn_cva6_acc       ),              
      .valid_o                ( mmu_valid_cva6_acc          ),
      .paddr_o                ( mmu_paddr_cva6_acc          ),                 
      .exception_o            ( mmu_exception_cva6_acc      ) 
    );
`else // !MMU_STUB     
    // TODO: route these to CVA6
    assign mmu_dtlb_hit_cva6_acc  = '0;
    assign mmu_dtlb_ppn_cva6_acc  = '0;
    assign mmu_valid_cva6_acc     = '0;
    assign mmu_paddr_cva6_acc     = '0;
    assign mmu_exception_cva6_acc = '0;
`endif // MMU_STUB

    // Issue invalidations to CVA6 L1D$
    axi_inval_filter #(
      .MaxTxns    ( 4                               ),
      .AddrWidth  ( Cfg.AddrWidth                   ),
      .L1LineWidth( ariane_pkg::DCACHE_LINE_WIDTH/8 ),
      .aw_chan_t  ( axi_ara_wide_aw_chan_t          ),
      .req_t      ( axi_ara_wide_req_t              ),
      .resp_t     ( axi_ara_wide_resp_t             )
    ) i_ara_axi_inval_filter (
      .clk_i        ( clk_i                   ),
      .rst_ni       ( rst_ni                  ),
      .en_i         ( acc_cons_en             ),
      .slv_req_i    ( axi_ara_wide_req        ),
      .slv_resp_o   ( axi_ara_wide_resp       ),
      .mst_req_o    ( axi_ara_wide_req_inval  ),
      .mst_resp_i   ( axi_ara_wide_resp_inval ),
      .inval_addr_o ( inval_addr              ),
      .inval_valid_o( inval_valid             ),
      .inval_ready_i( inval_ready             )
    );

    // Convert from AraDataWideWidth (axi_ara_wide) to Cfg.AxiDataWidth (axi_ara_narrow)
    axi_dw_converter #(
      .AxiSlvPortDataWidth ( AraDataWideWidth       ),
      .AxiMstPortDataWidth ( Cfg.AxiDataWidth       ),
      .AxiMaxReads         ( 4                      ), // TODO: Tune this w.r.t. ARA_NR_LANES
      .AxiAddrWidth        ( Cfg.AddrWidth          ),
      .AxiIdWidth          ( Cfg.AxiMstIdWidth      ),
      .aw_chan_t           ( axi_ara_wide_aw_chan_t ), 
      .mst_w_chan_t        ( axi_mst_w_chan_t       ),
      .slv_w_chan_t        ( axi_ara_wide_w_chan_t  ),
      .b_chan_t            ( axi_ara_wide_b_chan_t  ),
      .ar_chan_t           ( axi_ara_wide_ar_chan_t ),
      .mst_r_chan_t        ( axi_mst_r_chan_t       ),
      .slv_r_chan_t        ( axi_ara_wide_r_chan_t  ),
      .axi_mst_req_t       ( axi_mst_req_t          ),
      .axi_mst_resp_t      ( axi_mst_rsp_t          ),
      .axi_slv_req_t       ( axi_ara_wide_req_t     ),
      .axi_slv_resp_t      ( axi_ara_wide_resp_t    ) 
    ) i_ara_axi_dw_converter (
      .clk_i      ( clk_i                   ),
      .rst_ni     ( rst_ni                  ),
      .slv_req_i  ( axi_ara_wide_req_inval  ),
      .slv_resp_o ( axi_ara_wide_resp_inval ),
      .mst_req_o  ( axi_ara_narrow_req      ),
      .mst_resp_i ( axi_ara_narrow_resp     )
    );

    // Assign to crossbar input/master
    assign axi_in_req[AxiIn.ara] = axi_ara_narrow_req;
    assign axi_ara_narrow_resp = axi_in_rsp[AxiIn.ara];

  `endif // ARA_INTEGRATION_V0_2  
  `else // ! ARA
    // Ingnore output acc_req
    // Tie outputs to zero
    assign acc_resp    = '0; 
    assign inval_valid = '0;
    assign inval_addr = '0;
    
    // MMU interface
    assign mmu_misaligned_ex_acc_cva6 = '0;
    assign mmu_req_acc_cva6           = '0;
    assign mmu_vaddr_acc_cva6         = '0;
    assign mmu_is_store_acc_cva6      = '0;

    // Crossbar
    // Ignore axi_in_rsp[AxiIn.ara] and axi_in_req[AxiIn.ara] since here they are not defined 

  `endif // ARA

    // Generate CLIC for core if enabled
    if (Cfg.Clic) begin : gen_clic

  `ifdef TARGET_CV64A6_IMAFDCV_SV39

      $fatal(1, "CLIC is not supported in CV64A6_IMAFDCV_SV39");

  `else // ! TARGET_CV64A6_IMAFDCV_SV39

      cheshire_intr_clic_t clic_intr;

      // Connect interrupts to CLIC
      assign clic_intr = '{
        intr: intr_routed[IntrRtdCoreBase+i][NumClicSysIntrs-1:0],
        core: '{
          meip: xeip[i].m,
          seip: xeip[i].s,
          mtip: mtip[i],
          msip: msip[i],
          default: '0
        }
      };

      clic #(
        .N_SOURCE   ( NumClicIntrs ),
        .INTCTLBITS ( Cfg.ClicIntCtlBits ),
        .reg_req_t  ( reg_req_t ),
        .reg_rsp_t  ( reg_rsp_t ),
        .SSCLIC     ( 1 ),
        .USCLIC     ( 0 )
      ) i_clic (
        .clk_i,
        .rst_ni,
        .reg_req_i      ( reg_out_req[RegOut.clic[i]] ),
        .reg_rsp_o      ( reg_out_rsp[RegOut.clic[i]] ),
        .intr_src_i     ( clic_intr ),
        .irq_valid_o    ( clic_irq_valid ),
        .irq_ready_i    ( clic_irq_ready ),
        .irq_id_o       ( clic_irq_id    ),
        .irq_level_o    ( clic_irq_level ),
        .irq_shv_o      ( clic_irq_shv   ),
        .irq_priv_o     ( clic_irq_priv  ),
        .irq_kill_req_o ( clic_irq_kill_req ),
        .irq_kill_ack_i ( clic_irq_kill_ack )
      );
  `endif // TARGET_CV64A6_IMAFDCV_SV39

    end else begin : gen_no_clic

      assign clic_irq_valid    = '0;
      assign clic_irq_id       = '0;
      assign clic_irq_level    = '0;
      assign clic_irq_shv      = '0;
      assign clic_irq_priv     = riscv::priv_lvl_t'(0);
      assign clic_irq_kill_req = '0;

    end

    // Map user to AMO domain as we are an atomics-capable master.
    // As we are core 0, the core 1 and serial link AMO bits should *not* be set.
    always_comb begin
      core_ur_req         = core_out_req;
      core_ur_req.aw.user = Cfg.AxiUserDefault;
      core_ur_req.ar.user = Cfg.AxiUserDefault;
      core_ur_req.w.user  = Cfg.AxiUserDefault;
      // TODO: for additional cores, assign user bits between LSB and MSB accordingly
      // TODO: for any other features, assign user bits accordingly
      core_out_rsp        = core_ur_rsp;
    end

    // CVA6's ID encoding is wasteful; remap it statically pack into available bits
    axi_id_serialize #(
      .AxiSlvPortIdWidth      ( Cva6IdWidth     ),
      .AxiSlvPortMaxTxns      ( Cfg.CoreMaxTxns ),
      .AxiMstPortIdWidth      ( Cfg.AxiMstIdWidth      ),
      .AxiMstPortMaxUniqIds   ( 2 ** Cfg.AxiMstIdWidth ),
      .AxiMstPortMaxTxnsPerId ( Cfg.CoreMaxTxnsPerId   ),
      .AxiAddrWidth           ( Cfg.AddrWidth    ),
      .AxiDataWidth           ( Cfg.AxiDataWidth ),
      .AxiUserWidth           ( Cfg.AxiUserWidth ),
      .AtopSupport            ( 1 ),
      .slv_req_t              ( axi_cva6_req_t ),
      .slv_resp_t             ( axi_cva6_rsp_t ),
      .mst_req_t              ( axi_mst_req_t  ),
      .mst_resp_t             ( axi_mst_rsp_t  ),
      .MstIdBaseOffset        ( '0 ),
      .IdMapNumEntries        ( Cva6IdsUsed ),
      .IdMap                  ( gen_cva6_id_map(Cfg) )
    ) i_axi_id_serialize (
      .clk_i,
      .rst_ni,
      .slv_req_i  ( core_ur_req ),
      .slv_resp_o ( core_ur_rsp ),
      .mst_req_o  ( axi_in_req[AxiIn.cores[i]] ),
      .mst_resp_i ( axi_in_rsp[AxiIn.cores[i]] )
    );
  end

  /////////////////////////
  //  JTAG Debug Module  //
  /////////////////////////

  localparam int unsigned NumDbgHarts = NumIntHarts + Cfg.NumExtDbgHarts;

  // Filter atomics and cut
  axi_slv_req_t dbg_slv_axi_amo_req, dbg_slv_axi_cut_req;
  axi_slv_rsp_t dbg_slv_axi_amo_rsp, dbg_slv_axi_cut_rsp;

  // Hart debug interface
  dm::hartinfo_t [NumDbgHarts-1:0] dbg_info;
  logic          [NumDbgHarts-1:0] dbg_unavail;
  logic          [NumDbgHarts-1:0] dbg_req;

  // Debug module slave interface
  logic       dbg_slv_req;
  addr_t      dbg_slv_addr;
  axi_data_t  dbg_slv_addr_long;
  logic       dbg_slv_we;
  axi_data_t  dbg_slv_wdata;
  axi_strb_t  dbg_slv_wstrb;
  axi_data_t  dbg_slv_rdata;
  logic       dbg_slv_rvalid;

  // Debug module system bus access interface
  logic       dbg_sba_req;
  addr_t      dbg_sba_addr;
  axi_data_t  dbg_sba_addr_long;
  logic       dbg_sba_we;
  axi_data_t  dbg_sba_wdata;
  axi_strb_t  dbg_sba_strb;
  logic       dbg_sba_gnt;
  axi_data_t  dbg_sba_rdata;
  logic       dbg_sba_rvalid;
  logic       dbg_sba_err;

  // JTAG DMI to debug module
  logic           dbg_dmi_rst_n;
  dm::dmi_req_t   dbg_dmi_req;
  logic           dbg_dmi_req_ready, dbg_dmi_req_valid;
  dm::dmi_resp_t  dbg_dmi_rsp;
  logic           dbg_dmi_rsp_ready, dbg_dmi_rsp_valid;

  // Truncate and pad addresses as necessary
  assign dbg_sba_addr       = dbg_sba_addr_long;
  assign dbg_slv_addr_long  = dbg_slv_addr;

  // Connect internal harts to debug interface
  assign dbg_info    [NumIntHarts-1:0] = dbg_int_info;
  assign dbg_unavail [NumIntHarts-1:0] = dbg_int_unavail;
  assign dbg_int_req = dbg_req[NumIntHarts-1:0];

  // Connect external harts to debug interface
  if (Cfg.NumExtDbgHarts != 0) begin : gen_dbg_ext
    assign dbg_info    [NumDbgHarts-1:NumIntHarts] = ExtHartinfo;
    assign dbg_unavail [NumDbgHarts-1:NumIntHarts] = dbg_ext_unavail_i;
    assign dbg_ext_req_o = dbg_req[NumDbgHarts-1:NumIntHarts];
  end else begin : gen_no_dbg_ext
    assign dbg_ext_req_o = '0;
  end

  // Filter atomic accesses
  axi_riscv_atomics_structs #(
    .AxiAddrWidth     ( Cfg.AddrWidth    ),
    .AxiDataWidth     ( Cfg.AxiDataWidth ),
    .AxiIdWidth       ( AxiSlvIdWidth    ),
    .AxiUserWidth     ( Cfg.AxiUserWidth ),
    .AxiMaxReadTxns   ( Cfg.DbgMaxReadTxns  ),
    .AxiMaxWriteTxns  ( Cfg.DbgMaxWriteTxns ),
    .AxiUserAsId      ( 1 ),
    .AxiUserIdMsb     ( Cfg.AxiUserAmoMsb ),
    .AxiUserIdLsb     ( Cfg.AxiUserAmoLsb ),
    .RiscvWordWidth   ( 64 ),
    .NAxiCuts         ( Cfg.DbgAmoNumCuts ),
    .axi_req_t        ( axi_slv_req_t ),
    .axi_rsp_t        ( axi_slv_rsp_t )
  ) i_dbg_slv_axi_atomics (
    .clk_i,
    .rst_ni,
    .axi_slv_req_i ( axi_out_req[AxiOut.dbg] ),
    .axi_slv_rsp_o ( axi_out_rsp[AxiOut.dbg] ),
    .axi_mst_req_o ( dbg_slv_axi_amo_req ),
    .axi_mst_rsp_i ( dbg_slv_axi_amo_rsp )
  );

  axi_cut #(
    .Bypass     ( ~Cfg.DbgAmoPostCut ),
    .aw_chan_t  ( axi_slv_aw_chan_t ),
    .w_chan_t   ( axi_slv_w_chan_t  ),
    .b_chan_t   ( axi_slv_b_chan_t  ),
    .ar_chan_t  ( axi_slv_ar_chan_t ),
    .r_chan_t   ( axi_slv_r_chan_t  ),
    .axi_req_t  ( axi_slv_req_t ),
    .axi_resp_t ( axi_slv_rsp_t )
  ) i_dbg_slv_axi_atomics_cut (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( dbg_slv_axi_amo_req ),
    .slv_resp_o ( dbg_slv_axi_amo_rsp ),
    .mst_req_o  ( dbg_slv_axi_cut_req ),
    .mst_resp_i ( dbg_slv_axi_cut_rsp )
  );

  // AXI access to debug module
  axi_to_mem_interleaved #(
    .axi_req_t  ( axi_slv_req_t ),
    .axi_resp_t ( axi_slv_rsp_t ),
    .AddrWidth  ( Cfg.AddrWidth    ),
    .DataWidth  ( Cfg.AxiDataWidth ),
    .IdWidth    ( AxiSlvIdWidth    ),
    .NumBanks   ( 1 ),
    .BufDepth   ( 4 )
  ) i_dbg_slv_axi_to_mem (
    .clk_i,
    .rst_ni,
    .test_i       ( test_mode_i ),
    .busy_o       ( ),
    .axi_req_i    ( dbg_slv_axi_cut_req ),
    .axi_resp_o   ( dbg_slv_axi_cut_rsp ),
    .mem_req_o    ( dbg_slv_req    ),
    .mem_gnt_i    ( dbg_slv_req    ),
    .mem_addr_o   ( dbg_slv_addr   ),
    .mem_wdata_o  ( dbg_slv_wdata  ),
    .mem_strb_o   ( dbg_slv_wstrb  ),
    .mem_atop_o   ( ),
    .mem_we_o     ( dbg_slv_we     ),
    .mem_rvalid_i ( dbg_slv_rvalid ),
    .mem_rdata_i  ( dbg_slv_rdata  )
  );

  // Read response is valid one cycle after request
  `FF(dbg_slv_rvalid, dbg_slv_req, 1'b0, clk_i, rst_ni)

  // Debug Module
  dm_top #(
    .NrHarts        ( NumDbgHarts ),
    .BusWidth       ( Cfg.AxiDataWidth ),
    .DmBaseAddress  ( AmDbg )
  ) i_dbg_dm_top (
    .clk_i,
    .rst_ni,
    .testmode_i           ( test_mode_i ),
    .ndmreset_o           ( ),
    .dmactive_o           ( dbg_active_o  ),
    .debug_req_o          ( dbg_req       ),
    .unavailable_i        ( dbg_unavail   ),
    .hartinfo_i           ( dbg_info      ),
    .slave_req_i          ( dbg_slv_req       ),
    .slave_we_i           ( dbg_slv_we        ),
    .slave_addr_i         ( dbg_slv_addr_long ),
    .slave_be_i           ( dbg_slv_wstrb     ),
    .slave_wdata_i        ( dbg_slv_wdata     ),
    .slave_rdata_o        ( dbg_slv_rdata     ),
    .master_req_o         ( dbg_sba_req       ),
    .master_add_o         ( dbg_sba_addr_long ),
    .master_we_o          ( dbg_sba_we        ),
    .master_wdata_o       ( dbg_sba_wdata     ),
    .master_be_o          ( dbg_sba_strb      ),
    .master_gnt_i         ( dbg_sba_gnt       ),
    .master_r_valid_i     ( dbg_sba_rvalid    ),
    .master_r_rdata_i     ( dbg_sba_rdata     ),
    .master_r_err_i       ( dbg_sba_err       ),
    .master_r_other_err_i ( 1'b0 ),
    .dmi_rst_ni           ( dbg_dmi_rst_n     ),
    .dmi_req_valid_i      ( dbg_dmi_req_valid ),
    .dmi_req_ready_o      ( dbg_dmi_req_ready ),
    .dmi_req_i            ( dbg_dmi_req       ),
    .dmi_resp_valid_o     ( dbg_dmi_rsp_valid ),
    .dmi_resp_ready_i     ( dbg_dmi_rsp_ready ),
    .dmi_resp_o           ( dbg_dmi_rsp       )
  );

  axi_mst_req_t axi_dbg_req;

  always_comb begin
    axi_in_req[AxiIn.dbg]         = axi_dbg_req;
    axi_in_req[AxiIn.dbg].aw.user = Cfg.AxiUserDefault;
    axi_in_req[AxiIn.dbg].w.user  = Cfg.AxiUserDefault;
    axi_in_req[AxiIn.dbg].ar.user = Cfg.AxiUserDefault;
  end

  // Debug module system bus access to AXI crossbar
  axi_from_mem #(
    .MemAddrWidth ( Cfg.AddrWidth    ),
    .AxiAddrWidth ( Cfg.AddrWidth    ),
    .DataWidth    ( Cfg.AxiDataWidth ),
    .MaxRequests  ( Cfg.DbgMaxReqs ),
    .AxiProt      ( '0 ),
    .axi_req_t    ( axi_mst_req_t ),
    .axi_rsp_t    ( axi_mst_rsp_t )
  ) i_dbg_sba_axi_from_mem (
    .clk_i,
    .rst_ni,
    .mem_req_i       ( dbg_sba_req    ),
    .mem_addr_i      ( dbg_sba_addr   ),
    .mem_we_i        ( dbg_sba_we     ),
    .mem_wdata_i     ( dbg_sba_wdata  ),
    .mem_be_i        ( dbg_sba_strb   ),
    .mem_gnt_o       ( dbg_sba_gnt    ),
    .mem_rsp_valid_o ( dbg_sba_rvalid ),
    .mem_rsp_rdata_o ( dbg_sba_rdata  ),
    .mem_rsp_error_o ( dbg_sba_err    ),
    .slv_aw_cache_i  ( axi_pkg::CACHE_MODIFIABLE ),
    .slv_ar_cache_i  ( axi_pkg::CACHE_MODIFIABLE ),
    .axi_req_o       ( axi_dbg_req           ),
    .axi_rsp_i       ( axi_in_rsp[AxiIn.dbg] )
  );

  // Debug Transfer Module and JTAG interface
  dmi_jtag #(
    .IdcodeValue  ( Cfg.DbgIdCode )
  ) i_dbg_dmi_jtag (
    .clk_i,
    .rst_ni,
    .testmode_i       ( test_mode_i ),
    .dmi_rst_no       ( dbg_dmi_rst_n     ),
    .dmi_req_o        ( dbg_dmi_req       ),
    .dmi_req_ready_i  ( dbg_dmi_req_ready ),
    .dmi_req_valid_o  ( dbg_dmi_req_valid ),
    .dmi_resp_i       ( dbg_dmi_rsp       ),
    .dmi_resp_ready_o ( dbg_dmi_rsp_ready ),
    .dmi_resp_valid_i ( dbg_dmi_rsp_valid ),
    .tck_i            ( jtag_tck_i     ),
    .tms_i            ( jtag_tms_i     ),
    .trst_ni          ( jtag_trst_ni   ),
    .td_i             ( jtag_tdi_i     ),
    .td_o             ( jtag_tdo_o     ),
    .tdo_oe_o         ( jtag_tdo_oe_o  )
  );

  /////////////////////
  //  Register File  //
  /////////////////////

  cheshire_reg_pkg::cheshire_hw2reg_t reg_hw2reg;

  assign reg_hw2reg = '{
    boot_mode     : boot_mode_i,
    rtc_freq      : Cfg.RtcFreq,
    platform_rom  : Cfg.PlatformRom,
    hw_features   : '{
      bootrom     : Cfg.Bootrom,
      llc         : Cfg.LlcNotBypass,
      uart        : Cfg.Uart,
      i2c         : Cfg.I2c,
      gpio        : Cfg.Gpio,
      spi_host    : Cfg.SpiHost,
      dma         : Cfg.Dma,
      serial_link : Cfg.SerialLink,
      vga         : Cfg.Vga,
      axirt       : Cfg.AxiRt,
      clic        : Cfg.Clic,
      irq_router  : Cfg.IrqRouter
    },
    llc_size      : get_llc_size(Cfg),
    vga_params    : '{
      red_width   : Cfg.VgaRedWidth,
      green_width : Cfg.VgaGreenWidth,
      blue_width  : Cfg.VgaBlueWidth
    },
    num_harts     : Cfg.NumCores
  };

  cheshire_reg_top #(
    .reg_req_t  ( reg_req_t ),
    .reg_rsp_t  ( reg_rsp_t )
  ) i_regs (
    .clk_i,
    .rst_ni,
    .reg_req_i  ( reg_out_req[RegOut.regs] ),
    .reg_rsp_o  ( reg_out_rsp[RegOut.regs] ),
    .hw2reg     ( reg_hw2reg ),
    .devmode_i  ( 1'b1 )
  );

  ////////////////////////
  //  Interrupt Router  //
  ////////////////////////

  if (Cfg.IrqRouter) begin : gen_irq_router

    irq_router #(
      .reg_req_t      ( reg_req_t ),
      .reg_rsp_t      ( reg_rsp_t ),
      .NumIntrSrc     ( $bits(cheshire_intr_t) ),
      .NumIntrTargets ( NumRtdIntrTgts )
    ) i_irq_router (
      .clk_i,
      .rst_ni,
      .reg_req_i          ( reg_out_req[RegOut.irq_router] ),
      .reg_rsp_o          ( reg_out_rsp[RegOut.irq_router] ),
      .irqs_i             ( intr ),
      .irqs_distributed_o ( intr_routed )
    );

  end else begin : gen_no_irq_router

    // We simply fan out the incoming interrupts to all targets
    for (genvar i = 0; i < NumRtdIntrTgts; i++) begin : gen_irq_fanout
      assign intr_routed[i] = intr;
    end

  end

  ////////////
  //  PLIC  //
  ////////////

  rv_plic #(
    .reg_req_t  ( reg_req_t ),
    .reg_rsp_t  ( reg_rsp_t )
  ) i_plic (
    .clk_i,
    .rst_ni,
    .reg_req_i  ( reg_out_req[RegOut.plic] ),
    .reg_rsp_o  ( reg_out_rsp[RegOut.plic] ),
    .intr_src_i ( intr_routed[IntrRtdPlic][rv_plic_reg_pkg::NumSrc-1:0] ),
    .irq_o      ( xeip ),
    .irq_id_o   ( ),
    .msip_o     ( )
  );

  /////////////
  //  CLINT  //
  /////////////

  clint #(
    .reg_req_t  ( reg_req_t ),
    .reg_rsp_t  ( reg_rsp_t )
  ) i_clint (
    .clk_i,
    .rst_ni,
    .testmode_i   ( test_mode_i ),
    .reg_req_i    ( reg_out_req[RegOut.clint] ),
    .reg_rsp_o    ( reg_out_rsp[RegOut.clint] ),
    .rtc_i,
    .timer_irq_o  ( mtip ),
    .ipi_o        ( msip )
  );

  //////////////
  //  AXI RT  //
  //////////////

  if (Cfg.AxiRt) begin : gen_axi_rt

    // Connect AXI RT units, one for each master
    axi_rt_reg_pkg::axi_rt_hw2reg_t axi_rt_hw2reg;
    axi_rt_reg_pkg::axi_rt_reg2hw_t axi_rt_reg2hw;

    // Rule type
    typedef struct packed {
      logic [0:0] idx;
      addr_t      start_addr;
      addr_t      end_addr;
    } rt_rule_t;

    localparam rt_rule_t [0:0] RtAddrmap = '{
      '{ idx: 8'h00, start_addr: '0, end_addr: '1 }
    };

    for (genvar i = 0; i < AxiIn.num_in; i++) begin : gen_axi_rt_units
      axi_rt_unit #(
        .AddrWidth      ( Cfg.AddrWidth     ),
        .DataWidth      ( Cfg.AxiDataWidth  ),
        .IdWidth        ( Cfg.AxiMstIdWidth ),
        .UserWidth      ( Cfg.AxiUserWidth  ),
        .NumPending     ( Cfg.AxiRtNumPending   ),
        .WBufferDepth   ( Cfg.AxiRtWBufferDepth ),
        .NumAddrRegions ( 1  ),
        .NumRules       ( 1  ),
        .PeriodWidth    ( 32 ),
        .BudgetWidth    ( 32 ),
        .rt_rule_t      ( rt_rule_t ),
        .addr_t         ( addr_t    ),
        .aw_chan_t      ( axi_mst_aw_chan_t ),
        .w_chan_t       ( axi_mst_w_chan_t  ),
        .axi_req_t      ( axi_mst_req_t ),
        .axi_resp_t     ( axi_mst_rsp_t )
      ) i_axi_rt_unit (
        .clk_i,
        .rst_ni,
        .slv_req_i        ( axi_in_req [i] ),
        .slv_resp_o       ( axi_in_rsp [i] ),
        .mst_req_o        ( axi_rt_in_req [i] ),
        .mst_resp_i       ( axi_rt_in_rsp [i] ),
        .rt_enable_i      ( axi_rt_reg2hw.rt_enable   [i] ),
        .rt_bypassed_o    ( axi_rt_hw2reg.rt_bypassed [i] ),
        .len_limit_i      ( axi_rt_reg2hw.len_limit   [i] ),
        .num_w_pending_o  ( ),
        .num_aw_pending_o ( ),
        .rt_rule_i        ( RtAddrmap ),
        .w_decode_error_o ( ),
        .r_decode_error_o ( ),
        .imtu_enable_i    ( axi_rt_reg2hw.imtu_enable [i] ),
        .imtu_abort_i     ( axi_rt_reg2hw.imtu_abort  [i] ),
        .w_budget_i       ( axi_rt_reg2hw.write_budget      [i] ),
        .w_budget_left_o  ( axi_rt_hw2reg.write_budget_left [i] ),
        .w_period_i       ( axi_rt_reg2hw.write_period      [i] ),
        .w_period_left_o  ( axi_rt_hw2reg.write_period_left [i] ),
        .r_budget_i       ( axi_rt_reg2hw.read_budget       [i] ),
        .r_budget_left_o  ( axi_rt_hw2reg.read_budget_left  [i] ),
        .r_period_i       ( axi_rt_reg2hw.read_period       [i] ),
        .r_period_left_o  ( axi_rt_hw2reg.read_period_left  [i] ),
        .isolate_o        ( axi_rt_hw2reg.isolate  [i] ),
        .isolated_o       ( axi_rt_hw2reg.isolated [i] )
      );
    end

    axi_rt_reg_top #(
      .reg_req_t  ( reg_req_t ),
      .reg_rsp_t  ( reg_rsp_t )
    ) i_axi_rt_regs (
      .clk_i,
      .rst_ni,
      .reg_req_i  ( reg_out_req[RegOut.axirt] ),
      .reg_rsp_o  ( reg_out_rsp[RegOut.axirt] ),
      .hw2reg     ( axi_rt_hw2reg ),
      .reg2hw     ( axi_rt_reg2hw ),
      .devmode_i  ( 1'b1 )
    );

  end else begin : gen_no_axi_rt

    assign axi_rt_in_req  = axi_in_req;
    assign axi_in_rsp     = axi_rt_in_rsp;

  end

  ////////////////
  //  Boot ROM  //
  ////////////////

  if (Cfg.Bootrom) begin : gen_bootrom

    logic [15:0]  bootrom_addr;
    logic [31:0]  bootrom_data, bootrom_data_q;
    logic         bootrom_req,  bootrom_req_q;
    logic         bootrom_we,   bootrom_we_q;

    // Delay response by one cycle to fulfill mem protocol
    `FF(bootrom_data_q, bootrom_data, '0, clk_i, rst_ni)
    `FF(bootrom_req_q,  bootrom_req,  '0, clk_i, rst_ni)
    `FF(bootrom_we_q,   bootrom_we,   '0, clk_i, rst_ni)

    reg_to_mem #(
      .AW     ( 16 ),
      .DW     ( 32 ),
      .req_t  ( reg_req_t ),
      .rsp_t  ( reg_rsp_t )
    ) i_reg_to_bootrom (
      .clk_i,
      .rst_ni,
      .reg_req_i  ( reg_out_req[RegOut.bootrom] ),
      .reg_rsp_o  ( reg_out_rsp[RegOut.bootrom] ),
      .req_o      ( bootrom_req  ),
      .gnt_i      ( bootrom_req  ),
      .we_o       ( bootrom_we   ),
      .addr_o     ( bootrom_addr ),
      .wdata_o    ( ),
      .wstrb_o    ( ),
      .rdata_i    ( bootrom_data_q ),
      .rvalid_i   ( bootrom_req_q  ),
      .rerror_i   ( bootrom_we_q   )
    );

    cheshire_bootrom #(
      .AddrWidth  ( 16 ),
      .DataWidth  ( 32 )
    ) i_bootrom (
      .clk_i,
      .rst_ni,
      .req_i    ( bootrom_req  ),
      .addr_i   ( bootrom_addr ),
      .data_o   ( bootrom_data )
    );

  end

  ////////////
  //  UART  //
  ////////////

  if (Cfg.Uart) begin : gen_uart

    reg_uart_wrap #(
      .AddrWidth  ( Cfg.AddrWidth ),
      .reg_req_t  ( reg_req_t ),
      .reg_rsp_t  ( reg_rsp_t )
    ) i_uart (
      .clk_i,
      .rst_ni,
      .reg_req_i  ( reg_out_req[RegOut.uart] ),
      .reg_rsp_o  ( reg_out_rsp[RegOut.uart] ),
      .intr_o     ( intr.intn.uart ),
      .out2_no    ( ),
      .out1_no    ( ),
      .rts_no     ( uart_rts_no ),
      .dtr_no     ( uart_dtr_no ),
      .cts_ni     ( uart_cts_ni ),
      .dsr_ni     ( uart_dsr_ni ),
      .dcd_ni     ( uart_dcd_ni ),
      .rin_ni     ( uart_rin_ni ),
      .sin_i      ( uart_rx_i   ),
      .sout_o     ( uart_tx_o   )
    );

  end else begin : gen_no_uart

    assign uart_rts_no  = 0;
    assign uart_dtr_no  = 0;
    assign uart_tx_o    = 0;

    assign intr.intn.uart  = 0;

  end

  ///////////
  //  I2C  //
  ///////////

  if (Cfg.I2c) begin : gen_i2c

    i2c #(
      .reg_req_t  ( reg_req_t ),
      .reg_rsp_t  ( reg_rsp_t )
    ) i_i2c (
      .clk_i,
      .rst_ni,
      .reg_req_i                ( reg_out_req[RegOut.i2c] ),
      .reg_rsp_o                ( reg_out_rsp[RegOut.i2c] ),
      .cio_scl_i                ( i2c_scl_i    ),
      .cio_scl_o                ( i2c_scl_o    ),
      .cio_scl_en_o             ( i2c_scl_en_o ),
      .cio_sda_i                ( i2c_sda_i    ),
      .cio_sda_o                ( i2c_sda_o    ),
      .cio_sda_en_o             ( i2c_sda_en_o ),
      .intr_fmt_threshold_o     ( intr.intn.i2c_fmt_threshold    ),
      .intr_rx_threshold_o      ( intr.intn.i2c_rx_threshold     ),
      .intr_fmt_overflow_o      ( intr.intn.i2c_fmt_overflow     ),
      .intr_rx_overflow_o       ( intr.intn.i2c_rx_overflow      ),
      .intr_nak_o               ( intr.intn.i2c_nak              ),
      .intr_scl_interference_o  ( intr.intn.i2c_scl_interference ),
      .intr_sda_interference_o  ( intr.intn.i2c_sda_interference ),
      .intr_stretch_timeout_o   ( intr.intn.i2c_stretch_timeout  ),
      .intr_sda_unstable_o      ( intr.intn.i2c_sda_unstable     ),
      .intr_cmd_complete_o      ( intr.intn.i2c_cmd_complete     ),
      .intr_tx_stretch_o        ( intr.intn.i2c_tx_stretch       ),
      .intr_tx_overflow_o       ( intr.intn.i2c_tx_overflow      ),
      .intr_acq_full_o          ( intr.intn.i2c_acq_full         ),
      .intr_unexp_stop_o        ( intr.intn.i2c_unexp_stop       ),
      .intr_host_timeout_o      ( intr.intn.i2c_host_timeout     )
    );

  end else begin : gen_no_i2c

    assign i2c_scl_o    = 0;
    assign i2c_scl_en_o = 0;
    assign i2c_sda_o    = 0;
    assign i2c_sda_en_o = 0;

    assign intr.intn.i2c_fmt_threshold     = 0;
    assign intr.intn.i2c_rx_threshold      = 0;
    assign intr.intn.i2c_fmt_overflow      = 0;
    assign intr.intn.i2c_rx_overflow       = 0;
    assign intr.intn.i2c_nak               = 0;
    assign intr.intn.i2c_scl_interference  = 0;
    assign intr.intn.i2c_sda_interference  = 0;
    assign intr.intn.i2c_stretch_timeout   = 0;
    assign intr.intn.i2c_sda_unstable      = 0;
    assign intr.intn.i2c_cmd_complete      = 0;
    assign intr.intn.i2c_tx_stretch        = 0;
    assign intr.intn.i2c_tx_overflow       = 0;
    assign intr.intn.i2c_acq_full          = 0;
    assign intr.intn.i2c_unexp_stop        = 0;
    assign intr.intn.i2c_host_timeout      = 0;

  end

  ////////////////
  //  SPI Host  //
  ////////////////

  if (Cfg.SpiHost) begin : gen_spi_host

    // Last CS is an internal dummy for devices that need it
    logic spih_csb_dummy, spih_csb_dummy_en;

    spi_host #(
      .reg_req_t  ( reg_req_t ),
      .reg_rsp_t  ( reg_rsp_t )
    ) i_spi_host (
      .clk_i,
      .rst_ni,
      .reg_req_i        ( reg_out_req[RegOut.spi_host] ),
      .reg_rsp_o        ( reg_out_rsp[RegOut.spi_host] ),
      .cio_sck_o        ( spih_sck_o    ),
      .cio_sck_en_o     ( spih_sck_en_o ),
      .cio_csb_o        ( {spih_csb_dummy,    spih_csb_o   } ),
      .cio_csb_en_o     ( {spih_csb_dummy_en, spih_csb_en_o} ),
      .cio_sd_o         ( spih_sd_o     ),
      .cio_sd_en_o      ( spih_sd_en_o  ),
      .cio_sd_i         ( spih_sd_i     ),
      .intr_error_o     ( intr.intn.spih_error     ),
      .intr_spi_event_o ( intr.intn.spih_spi_event )
    );

  end else begin : gen_no_spi_host

    assign spih_sck_o     = 0;
    assign spih_sck_en_o  = 0;
    assign spih_csb_o     = '1;
    assign spih_csb_en_o  = '0;
    assign spih_sd_o      = '0;
    assign spih_sd_en_o   = '0;

    assign intr.intn.spih_error      = 0;
    assign intr.intn.spih_spi_event  = 0;

  end

  ////////////
  //  GPIO  //
  ////////////

  if (Cfg.Gpio) begin : gen_gpio

    gpio #(
      .reg_req_t   ( reg_req_t ),
      .reg_rsp_t   ( reg_rsp_t ),
      .GpioAsyncOn ( Cfg.GpioInputSyncs )
    ) i_gpio (
      .clk_i,
      .rst_ni,
      .reg_req_i     ( reg_out_req[RegOut.gpio] ),
      .reg_rsp_o     ( reg_out_rsp[RegOut.gpio] ),
      .intr_gpio_o   ( intr.intn.gpio ),
      .cio_gpio_i    ( gpio_i    ),
      .cio_gpio_o    ( gpio_o    ),
      .cio_gpio_en_o ( gpio_en_o )
    );

  end else begin : gen_no_gpio

    assign gpio_o     = '0;
    assign gpio_en_o  = '0;

    assign intr.intn.gpio  = '0;

  end

  ///////////
  //  DMA  //
  ///////////

  if(Cfg.Dma) begin : gen_dma

    axi_slv_req_t dma_amo_req, dma_cut_req;
    axi_slv_rsp_t dma_amo_rsp, dma_cut_rsp;

    axi_riscv_atomics_structs #(
      .AxiAddrWidth     ( Cfg.AddrWidth    ),
      .AxiDataWidth     ( Cfg.AxiDataWidth ),
      .AxiIdWidth       ( AxiSlvIdWidth    ),
      .AxiUserWidth     ( Cfg.AxiUserWidth ),
      .AxiMaxReadTxns   ( Cfg.DmaConfMaxReadTxns  ),
      .AxiMaxWriteTxns  ( Cfg.DmaConfMaxWriteTxns ),
      .AxiUserAsId      ( 1 ),
      .AxiUserIdMsb     ( Cfg.AxiUserAmoMsb ),
      .AxiUserIdLsb     ( Cfg.AxiUserAmoLsb ),
      .RiscvWordWidth   ( 64 ),
      .NAxiCuts         ( Cfg.DmaConfAmoNumCuts ),
      .axi_req_t        ( axi_slv_req_t ),
      .axi_rsp_t        ( axi_slv_rsp_t )
    ) i_dma_conf_atomics (
      .clk_i,
      .rst_ni,
      .axi_slv_req_i ( axi_out_req[AxiOut.dma] ),
      .axi_slv_rsp_o ( axi_out_rsp[AxiOut.dma] ),
      .axi_mst_req_o ( dma_amo_req ),
      .axi_mst_rsp_i ( dma_amo_rsp )
    );

    axi_cut #(
      .Bypass     ( ~Cfg.DmaConfAmoPostCut ),
      .aw_chan_t  ( axi_slv_aw_chan_t ),
      .w_chan_t   ( axi_slv_w_chan_t  ),
      .b_chan_t   ( axi_slv_b_chan_t  ),
      .ar_chan_t  ( axi_slv_ar_chan_t ),
      .r_chan_t   ( axi_slv_r_chan_t  ),
      .axi_req_t  ( axi_slv_req_t ),
      .axi_resp_t ( axi_slv_rsp_t )
    ) i_dma_conf_atomics_cut (
      .clk_i,
      .rst_ni,
      .slv_req_i  ( dma_amo_req ),
      .slv_resp_o ( dma_amo_rsp ),
      .mst_req_o  ( dma_cut_req ),
      .mst_resp_i ( dma_cut_rsp )
    );

    axi_mst_req_t axi_dma_req;

    always_comb begin
      axi_in_req[AxiIn.dma]         = axi_dma_req;
      axi_in_req[AxiIn.dma].aw.user = Cfg.AxiUserDefault;
      axi_in_req[AxiIn.dma].w.user  = Cfg.AxiUserDefault;
      axi_in_req[AxiIn.dma].ar.user = Cfg.AxiUserDefault;
    end

    dma_core_wrap #(
      .AxiAddrWidth   ( Cfg.AddrWidth     ),
      .AxiDataWidth   ( Cfg.AxiDataWidth  ),
      .AxiIdWidth     ( Cfg.AxiMstIdWidth ),
      .AxiUserWidth   ( Cfg.AxiUserWidth  ),
      .AxiSlvIdWidth  ( AxiSlvIdWidth     ),
      .axi_mst_req_t  ( axi_mst_req_t ),
      .axi_mst_rsp_t  ( axi_mst_rsp_t ),
      .axi_slv_req_t  ( axi_slv_req_t ),
      .axi_slv_rsp_t  ( axi_slv_rsp_t )
    ) i_dma (
      .clk_i,
      .rst_ni,
      .testmode_i     ( test_mode_i ),
      .axi_mst_req_o  ( axi_dma_req           ),
      .axi_mst_rsp_i  ( axi_in_rsp[AxiIn.dma] ),
      .axi_slv_req_i  ( dma_cut_req ),
      .axi_slv_rsp_o  ( dma_cut_rsp )
    );

  end

  ///////////////////
  //  Serial Link  //
  ///////////////////

  // TODO: connect isolation IO properly

  if(Cfg.SerialLink) begin : gen_serial_link

    axi_slv_req_t slink_tx_uar_req;
    axi_slv_rsp_t slink_tx_uar_rsp;

    axi_mst_req_t slink_tx_idr_req;
    axi_mst_rsp_t slink_tx_idr_rsp;

    // TX outgoing channels: Remap address and set serial link user bit
    always_comb begin
      slink_tx_uar_req          = axi_out_req[AxiOut.slink];
      slink_tx_uar_req.aw.addr  = (Cfg.SlinkTxAddrDomain    & ~Cfg.SlinkTxAddrMask) |
                                  (slink_tx_uar_req.aw.addr &  Cfg.SlinkTxAddrMask);
      slink_tx_uar_req.ar.addr  = (Cfg.SlinkTxAddrDomain    & ~Cfg.SlinkTxAddrMask) |
                                  (slink_tx_uar_req.ar.addr &  Cfg.SlinkTxAddrMask);
      slink_tx_uar_req.aw.user |= (addr_t'(1) << Cfg.SlinkUserAmoBit);
      slink_tx_uar_req.ar.user |= (addr_t'(1) << Cfg.SlinkUserAmoBit);
      slink_tx_uar_req.w.user  |= (addr_t'(1) << Cfg.SlinkUserAmoBit);
    end

    // TX incoming channels: unset serial link user bit
    always_comb begin
      axi_out_rsp[AxiOut.slink]         = slink_tx_uar_rsp;
      axi_out_rsp[AxiOut.slink].r.user &= ~(addr_t'(1) << Cfg.SlinkUserAmoBit);
      axi_out_rsp[AxiOut.slink].b.user &= ~(addr_t'(1) << Cfg.SlinkUserAmoBit);
    end

    // TX: Remap wider slave ID to narrower master ID
    axi_id_remap #(
      .AxiSlvPortIdWidth    ( AxiSlvIdWidth         ),
      .AxiSlvPortMaxUniqIds ( Cfg.SlinkMaxUniqIds   ),
      .AxiMaxTxnsPerId      ( Cfg.SlinkMaxTxnsPerId ),
      .AxiMstPortIdWidth    ( Cfg.AxiMstIdWidth     ),
      .slv_req_t            ( axi_slv_req_t ),
      .slv_resp_t           ( axi_slv_rsp_t ),
      .mst_req_t            ( axi_mst_req_t ),
      .mst_resp_t           ( axi_mst_rsp_t )
    ) i_serial_link_tx_id_remap (
      .clk_i,
      .rst_ni,
      .slv_req_i  ( slink_tx_uar_req ),
      .slv_resp_o ( slink_tx_uar_rsp ),
      .mst_req_o  ( slink_tx_idr_req ),
      .mst_resp_i ( slink_tx_idr_rsp )
    );

    serial_link #(
      .axi_req_t    ( axi_mst_req_t ),
      .axi_rsp_t    ( axi_mst_rsp_t ),
      .cfg_req_t    ( reg_req_t ),
      .cfg_rsp_t    ( reg_rsp_t ),
      .aw_chan_t    ( axi_mst_aw_chan_t ),
      .ar_chan_t    ( axi_mst_ar_chan_t ),
      .r_chan_t     ( axi_mst_r_chan_t  ),
      .w_chan_t     ( axi_mst_w_chan_t  ),
      .b_chan_t     ( axi_mst_b_chan_t  ),
      .hw2reg_t     ( serial_link_single_channel_reg_pkg::serial_link_single_channel_hw2reg_t ),
      .reg2hw_t     ( serial_link_single_channel_reg_pkg::serial_link_single_channel_reg2hw_t ),
      .NumChannels  ( SlinkNumChan   ),
      .NumLanes     ( SlinkNumLanes  ),
      .MaxClkDiv    ( SlinkMaxClkDiv )
    ) i_serial_link (
      .clk_i,
      .rst_ni,
      .clk_sl_i       ( clk_i  ),
      .rst_sl_ni      ( rst_ni ),
      .clk_reg_i      ( clk_i  ),
      .rst_reg_ni     ( rst_ni ),
      .testmode_i     ( test_mode_i ),
      .axi_in_req_i   ( slink_tx_idr_req ),
      .axi_in_rsp_o   ( slink_tx_idr_rsp ),
      .axi_out_req_o  ( axi_in_req[AxiIn.slink]   ),
      .axi_out_rsp_i  ( axi_in_rsp[AxiIn.slink]   ),
      .cfg_req_i      ( reg_out_req[RegOut.slink] ),
      .cfg_rsp_o      ( reg_out_rsp[RegOut.slink] ),
      .ddr_rcv_clk_i  ( slink_rcv_clk_i ),
      .ddr_rcv_clk_o  ( slink_rcv_clk_o ),
      .ddr_i          ( slink_i ),
      .ddr_o          ( slink_o ),
      .isolated_i     ( '0 ),
      .isolate_o      ( ),
      .clk_ena_o      ( ),
      .reset_no       ( )
    );

  end else begin : gen_no_serial_link

    assign slink_rcv_clk_o  = 0;
    assign slink_o          = '0;

  end

  ///////////
  //  VGA  //
  ///////////

  if (Cfg.Vga) begin : gen_vga

    axi_mst_req_t axi_vga_req;

    always_comb begin
      axi_in_req[AxiIn.vga]         = axi_vga_req;
      axi_in_req[AxiIn.vga].aw.user = Cfg.AxiUserDefault;
      axi_in_req[AxiIn.vga].w.user  = Cfg.AxiUserDefault;
      axi_in_req[AxiIn.vga].ar.user = Cfg.AxiUserDefault;
    end

    axi_vga #(
      .RedWidth     ( Cfg.VgaRedWidth    ),
      .GreenWidth   ( Cfg.VgaGreenWidth  ),
      .BlueWidth    ( Cfg.VgaBlueWidth   ),
      .HCountWidth  ( Cfg.VgaHCountWidth ),
      .VCountWidth  ( Cfg.VgaVCountWidth ),
      .AXIAddrWidth ( Cfg.AddrWidth    ),
      .AXIDataWidth ( Cfg.AxiDataWidth ),
      .AXIStrbWidth ( AxiStrbWidth     ),
      .axi_req_t    ( axi_mst_req_t ),
      .axi_resp_t   ( axi_mst_rsp_t ),
      .reg_req_t    ( reg_req_t ),
      .reg_resp_t   ( reg_rsp_t )
    ) i_axi_vga (
      .clk_i,
      .rst_ni,
      .test_mode_en_i ( test_mode_i ),
      .reg_req_i      ( reg_out_req[RegOut.vga] ),
      .reg_rsp_o      ( reg_out_rsp[RegOut.vga] ),
      .axi_req_o      ( axi_vga_req           ),
      .axi_resp_i     ( axi_in_rsp[AxiIn.vga] ),
      .hsync_o        ( vga_hsync_o ),
      .vsync_o        ( vga_vsync_o ),
      .red_o          ( vga_red_o   ),
      .green_o        ( vga_green_o ),
      .blue_o         ( vga_blue_o  )
    );

  end else begin : gen_no_vga

    assign vga_hsync_o  = 0;
    assign vga_vsync_o  = 0;
    assign vga_red_o    = '0;
    assign vga_green_o  = '0;
    assign vga_blue_o   = '0;

  end

  //////////////////
  //  Assertions  //
  //////////////////

  // TODO: check that CVA6 and Cheshire config agree
  // TODO: check that all interconnect params agree
  // TODO: check that params with min/max values are within legal range
  // TODO: check that CLINT and PLIC target counts are both `NumIntHarts + Cfg.NumExtHarts`
  // TODO: check that (for now) `NumIntHarts == 1`
  // TODO: check that available user bits suffice to identify all masters
  // TODO: check that atomics user domain is nonzero
  // TODO: check that `ext` (IO) and internal types agree
  // TODO: many other things I most likely forgot
  // TODO: check that LLC only exists if its output is connected (the reverse is allowed)

endmodule
