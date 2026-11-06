`include "defines.v"
//`timescale 1ns/100ps
`timescale 1ns/1ps

`include "tb_axis_mst.v"
`include "tb_axi4l_drv.v"
`include "tb_apb_mst.v"
`include "tb_mem.v"
`include "tb_data_checker.v"
`include "tb_gmii_mst.v"
//`include "tb_xgmii_mst.v"

module tb_top();

`include "dut_params.v"
//--------------------------------------------------------------------------
//--- Local Parameters/Defines ---
//--------------------------------------------------------------------------
localparam              CLKPERIOD         = 6.4;            //156.25 Mhz
localparam              CCLKPERIOD        = 6.4;            //156.25 MHz
localparam              WADDR_DEPTH       = 4096;           //512
localparam              RADDR_DEPTH       = 4096;           //512
localparam              REFCLK_MHZ        = (1/CCLKPERIOD)*1000;
localparam              SYSBUSCLK_MHZ     = (1/CLKPERIOD)*1000;
localparam              REG_WIDTH         = 32;
localparam              REG_DWIDTH        = 16;
localparam              PERIOD_400	      = 400;
localparam              PERIOD_156_25     = 6.4;
localparam              REFCLK_MHZ_156_25 = (1/PERIOD_156_25)*1000;
localparam              GMIICLK_MHZ       = (1/CCLKPERIOD)*1000;
localparam              DTYPE             = 5'b00011; // Hard Coded PCS Device Type

wire                    cpnx_xgmii_clk;
wire                    xg_rxval_o;
wire                    sys_ready_w;
//wire                    mac_clk;
wire                    epcs_tx_out_clk;
wire                    pad_refclkn_i  ;
wire                    pad_refclkp_i  ;
wire                    refclkp0_ext_i ;
wire                    refclkn0_ext_i ;
wire                    refclkp1_ext_i ;
wire                    refclkn1_ext_i ;
wire                    refclk_156 ; 
wire                    sd_pll_refclk_i;
wire                    use_refmux_i   ; 
wire                    diffioclksel_i ;
wire   [1:0]            clksel_i       ;
wire                    debug_link_timer_short;
wire                    force_isolate;
wire                    force_loopback;
wire                    force_unidir;
wire [15:0]             mr_adv_ability;
wire                    mr_an_enable;
wire                    mr_main_reset;
wire                    mr_restart_an;
wire                    mr_an_complete;
wire [15:0]             mr_lp_adv_ability;
wire                    mr_page_rx;
wire                    xmit_autoneg;
wire [15:0]             gmii_16_tx_d_i;
wire [1:0]              gmii_16_tx_en_i;
wire [1:0]              gmii_16_tx_err_i;
wire [15:0]             gmii_16_rx_d_o;
wire [1:0]              gmii_16_rx_dv_o;
wire [1:0]              gmii_16_rx_err_o;
wire                    phy_tx_clk_o;
wire                    phy_tx_clk_i;
wire                    phy_tx_rst_n_i;
wire                    phyrdy_o;
wire                    phy_link_sync_o;
//wire                    phy_rxidle_o;
wire                    phy_rx_clk_o;
wire                    phy_rx_clk_i;  
wire                    phy_rxval_o;
wire                    phy_rx_rst_n_i;
wire                    phy_pcs_clkin_i;
//wire                    phy_txval_i     ;
wire                    phy_txrdy_o    ;
//wire                    mac_rst;
wire                    mac_rst_n;
wire                    pad_rxn_i      ;
wire                    pad_rxp_i      ;
wire                    apb_pclk_i     ;
//reg                     phyrdy_o_d;
//wire                    phyrdy_o_det;
//wire                    obs_valid_det;
//reg                     obs_valid_reg;

// -----------------------------------------------------------------------------
// Register Declarations
// -----------------------------------------------------------------------------
reg                     obs_valid_Q;
reg                     axi4l_obs_valid_Q;
reg                     apb_obs_valid_Q;
reg                     reset_n_i;
reg                     sysbus_clk;
reg                     start_data_trans;
reg [63:0]              xgmii_rxd_r;
reg [7:0]               xgmii_rxc_r;
//reg                     mdc;
//reg [15:0]              mdio_rd_err;
//reg                     mdio_out;
//tri			          MDIO;
reg [15:0]              wr_data, rd_data;
reg                     core_clk;
reg [DATA_WIDTH-1:0]    obs_data_reg;
reg                     pcs_reset_n;

// -----------------------------------------------------------------------------
// Wire Declarations
// -----------------------------------------------------------------------------
wire                    exp_mstr;
wire                    exp_slv;
wire                    exp_valid;
wire [DATA_WIDTH-1:0]   exp_data;
wire                    obs_mstr;
wire                    obs_slv;
wire                    obs_valid;
wire [DATA_WIDTH-1:0]   obs_data;
wire                    axi4l_exp_mstr;
wire                    axi4l_exp_slv;
wire                    axi4l_exp_valid;
wire [REG_WIDTH-1:0]    axi4l_exp_data;
wire                    axi4l_obs_mstr;
wire                    axi4l_obs_slv;
wire                    axi4l_obs_valid;
wire [REG_WIDTH-1:0]    axi4l_obs_data;
wire                    apb_exp_mstr;
wire                    apb_exp_slv;
wire                    apb_exp_valid;
wire [REG_WIDTH-1:0]    apb_exp_data;
wire                    apb_obs_mstr;
wire                    apb_obs_slv;
wire                    apb_obs_valid;
wire [REG_WIDTH-1:0]    apb_obs_data;
wire [31:0]             apb_paddr_i;            
wire                    apb_penable_i;    
wire [31:0]             apb_prdata_o;     
wire                    apb_pready_o;       
wire                    apb_psel_i;       
wire                    apb_pslverr_o;    
wire [31:0]             apb_pwdata_i;     
wire                    apb_pwrite_i;     

wire [15:0]             apb_paddr;      
wire                    apb_pclk;       
wire                    apb_penable;    
wire [31:0]             apb_prdata;     
wire                    apb_pready;     
wire                    apb_preset_n;   
wire                    apb_psel;          
wire [31:0]             apb_pwdata;     
wire                    apb_pwrite; 

wire [63:0]             axis_tx_tdata_i;
wire                    axis_tx_tvalid_i;
wire                    axis_tx_tlast_i;
wire [7:0]              axis_tx_tkeep_i;
wire                    axis_tx_tuser_i;
wire                    axis_tx_tready_o;
wire [63:0]             axis_rx_tdata_o;
wire                    axis_rx_tvalid_o;
wire                    axis_rx_tlast_o;
wire [7:0]              axis_rx_tkeep_o;
wire                    axis_rx_tuser_o;
wire [27:0]             tx_statvec_o; 
wire                    tx_staten_o; 
wire [27:0]             rx_statvec_o; 
wire                    rx_staten_o; 
wire                    int_o;
wire                    tb_error_w;
wire                    tb_done_w;
wire                    gsr_out;                 
wire [63:0]             xgmii_rxd_i;       
wire [7:0]              xgmii_rxc_i;                      
wire [63:0]             xgmii_txd_o;       
wire [7:0]              xgmii_txc_o;
wire [15:0]             gmii_16_rx_d_i;   
wire [1:0]              gmii_16_rx_dv_i;
wire [1:0]              gmii_16_rx_err_i;  
wire [15:0]             gmii_16_tx_d_o;       
wire [1:0]              gmii_16_tx_en_o;
wire [1:0]              gmii_16_tx_err_o;  
wire [7:0]              gmii_rx_d_i;  
wire                    gmii_rx_dv_i;
wire                    gmii_rx_err_i;
wire [7:0]              gmii_tx_d_o;
wire                    gmii_tx_en_o;
wire                    gmii_tx_err_o;
wire [3:0]              mii_rx_d_i;  
wire                    mii_rx_dv_i;
wire                    mii_rx_err_i;
wire [3:0]              mii_tx_d_o;
wire                    mii_tx_en_o;
wire                    mii_tx_err_o;
wire [1:0]              speed_sel_i;
wire                    apb_done;
wire [31:0]		        axi4l_awaddr_i;		
wire 				    axi4l_awvalid_i;			
wire		            axi4l_awready_o;	
wire [2:0] 		        axi4l_awprot_i; 
wire [31:0]		        axi4l_wdata_i;
wire [3:0]		        axi4l_wstrb_i;	  
wire 				    axi4l_wvalid_i;			
wire		            axi4l_wready_o;			
wire [1:0]	            axi4l_bresp_o;			
wire		            axi4l_bvalid_o;		
wire 				    axi4l_bready_i;			
wire [31:0]		        axi4l_araddr_i;			
wire 				    axi4l_arvalid_i;			
wire		            axi4l_arready_o;	
wire [2:0] 		        axi4l_arprot_i;   
wire [31:0]	            axi4l_rdata_o;			
wire [1:0]	            axi4l_rresp_o;			
wire		            axi4l_rvalid_o;			
wire 				    axi4l_rready_i;
wire                    axi4l_done;
wire                    apb_en;
wire                    axi4l_en;
wire                    axi4l_tb_error_w;
wire                    apb_tb_error_w;
wire			        mdio_tb_error_w;
wire                    reg_tb_error_w;
wire                    reg_obs_valid;
wire                    xgmii_clk;
wire                    epcs_rxval;
wire [7:0]              xgmii_rxc;
wire [63:0]             xgmii_rxd;
wire [7:0]              control;

//MDIO Interface
wire                    mdio_in;
wire                    mdin, mdout, mdtri, mdc_neg;
wire                    mdc_i         ;
wire                    md_resetn_i   ;

wire                    xgmii_done;
wire                    txn;
wire                    txp;
wire                    pad_txn_o;
wire                    pad_txp_o;
wire [1:0]              phy_tx_gclk_o;
wire                    phy_rx_gclk_o;
wire                    xg_pcsrdy_o;
wire                    phy_init_done_o;
wire                    tb_error_xgmii_w;
wire                    phy_init_done;

wire   [7:0]            xg_txc_i       ;
wire   [63:0]           xg_txd_i       ;
wire                    pcsrdy_i       ;

//--------------------------------------------------------------------------
// Assign Statements
//--------------------------------------------------------------------------
generate
  if (IP_OPTION != "PHY only") begin
    //AXI4-stream for data checker
    assign exp_mstr         = axis_tx_tvalid_i && axis_tx_tready_o;
    assign exp_valid        = exp_mstr ;
    assign exp_data         = exp_mstr ? axis_tx_tdata_i[DATA_WIDTH-1:0] : 32'h0;
    assign obs_slv          = axis_rx_tvalid_o;
    assign obs_valid        = obs_slv;
    assign obs_data         = obs_slv ? axis_rx_tdata_o[DATA_WIDTH-1:0] : 32'h0;
    assign pcsrdy_i         = reset_n_i;
  end
  else begin
    assign exp_mstr         = (gmii_16_tx_en_i[1:0] != 'b00)? 1'b1 : 'b0;
    assign exp_valid        = exp_mstr ;
    assign exp_data         = exp_mstr ? gmii_16_tx_d_i[DATA_WIDTH-1:0] : 'h0;
    assign obs_slv          = (gmii_16_rx_dv_o[1:0] != 'b00)? 1'b1 : 'b0;
    assign obs_valid        = obs_slv;
    //assign obs_data         = obs_slv ? (obs_valid_det ? {gmii_16_rx_d_o[7:0],8'h55} : {gmii_16_rx_d_o[7:0],obs_data_reg[15:8]} ): 'h0;
    assign obs_data         = obs_slv ? gmii_16_rx_d_o[15:0] : 'h0;
  end
endgenerate

//AXI4-lite for register checker
assign axi4l_exp_mstr   = axi4l_wvalid_i & axi4l_wready_o; //default:axi4l_wvalid_i
assign axi4l_exp_valid  = axi4l_exp_mstr;
assign axi4l_exp_data   = axi4l_exp_mstr ? axi4l_wdata_i[REG_WIDTH-1:0] : 32'h0;
assign axi4l_obs_slv    = axi4l_rvalid_o & axi4l_rready_i; //default:axi4l_rvalid_o
assign axi4l_obs_valid  = axi4l_obs_slv;
assign axi4l_obs_data   = axi4l_obs_slv ? axi4l_rdata_o[REG_WIDTH-1:0] : 32'h0;
//APB for register checker
assign apb_exp_mstr     = apb_penable_i && apb_pwrite_i;
assign apb_exp_valid    = apb_exp_mstr;
assign apb_exp_data     = apb_exp_mstr ? apb_pwdata_i[DATA_WIDTH-1:0] : 32'h0;
assign apb_obs_slv      = apb_penable_i && !apb_pwrite_i && apb_pready_o;
assign apb_obs_valid    = apb_obs_slv;
assign apb_obs_data     = apb_obs_slv ? apb_prdata_o[DATA_WIDTH-1:0] : 32'h0;
//Clock assignments
assign sysbus_clk_i     = sysbus_clk;
assign rxmac_clk_i      = xgmii_clk;
assign txmac_clk_i      = xgmii_clk;

//Register enable
assign apb_en           = (PMI_FAMILY == "LFCPNX") ? 1'b1 : (HOST_IF=="APB") && (IP_OPTION != "PHY only") ? 1'b1 : 1'b0;
assign axi4l_en         = (PMI_FAMILY == "LFCPNX") ? 1'b0 : (HOST_IF=="AXI4-lite" || HOST_IF=="APB") && (IP_OPTION != "PHY only")  ? 1'b1 : 1'b0;
assign reg_obs_valid    = apb_en ? apb_obs_valid_Q : axi4l_obs_valid_Q;
assign reg_tb_error_w   = apb_en ? apb_tb_error_w : axi4l_tb_error_w;
//Loopback
generate
  if (DYN_SPEED_SEL) begin
    assign xgmii_rxd_i      = xgmii_txd_o; //XGMII loopback
    assign xgmii_rxc_i      = xgmii_txc_o; //XGMII loopback
    assign gmii_16_rx_d_i   = gmii_16_tx_d_o;     
    assign gmii_16_rx_dv_i  = gmii_16_tx_en_o;
    assign gmii_16_rx_err_i = gmii_16_tx_err_o;
    assign gmii_rx_d_i      = gmii_tx_d_o;
    assign gmii_rx_dv_i     = gmii_tx_en_o;
    assign gmii_rx_err_i    = gmii_tx_err_o;
    assign mii_rx_d_i       = mii_tx_d_o;
    assign mii_rx_dv_i      = mii_tx_en_o;
    assign mii_rx_err_i     = mii_tx_err_o;
    assign speed_sel_i      = (SPEED_SEL=="XGMII") ? 'd0 : (SPEED_SEL=="16-bit GMII") ? 'd2 : (SPEED_SEL=="8-bit GMII") ? 'd1 : 'd3;
  end
  else begin
    if (SPEED_SEL=="XGMII") begin
	  assign xgmii_rxd_i      = xgmii_txd_o; //XGMII loopback
      assign xgmii_rxc_i      = xgmii_txc_o; //XGMII loopback
	end
	else if (SPEED_SEL=="16-bit GMII") begin
	  assign gmii_16_rx_d_i   = gmii_16_tx_d_o;     
      assign gmii_16_rx_dv_i  = gmii_16_tx_en_o;
      assign gmii_16_rx_err_i = gmii_16_tx_err_o;
	end
	else if (SPEED_SEL=="8-bit GMII") begin
	  assign gmii_rx_d_i      = gmii_tx_d_o;
      assign gmii_rx_dv_i     = gmii_tx_en_o;
      assign gmii_rx_err_i    = gmii_tx_err_o;
	end
	else if (SPEED_SEL=="MII") begin
	  assign mii_rx_d_i       = mii_tx_d_o;
      assign mii_rx_dv_i      = mii_tx_en_o;
      assign mii_rx_err_i     = mii_tx_err_o;
	end
  end
endgenerate

always @(posedge phy_tx_clk_o or negedge reset_n_i) begin
	if (!reset_n_i) begin
		xgmii_rxd_r <= 'h0;
		xgmii_rxc_r <= 'h0;
	end
	else begin
                xgmii_rxd_r <= xgmii_rxd;
                xgmii_rxc_r <= xgmii_rxc;
	end
end

assign mac_rst_n       = reset_n_i; //(no pll needed)
assign cpnx_xgmii_clk  = phy_tx_clk_o;  //(no pll needed, 156.25MHz source clk from PHY MPCS)
   
assign phy_pcs_clkin_i = core_clk;
//assign phy_tx_clk_i = phy_tx_clk_o;
//assign phy_rx_clk_i = phy_rx_clk_o;

assign pad_rxn_i       = txn;
assign pad_rxp_i       = txp;

assign apb_pclk_i      = sysbus_clk;
assign apb_preset_n_i  = reset_n_i;

generate if ({PMI_FAMILY != "LFCPNX"}) begin : avant_pad_clk_gen
assign pad_refclkn_i   = core_clk;
assign pad_refclkp_i   = ~core_clk;
end
endgenerate

assign md_resetn_i    = reset_n_i;

assign txn             = pad_txn_o;
assign txp             = pad_txp_o;
assign xgmii_clk       = {(PMI_FAMILY == "LFCPNX") && ((IP_OPTION == "MAC + PHY")||(IP_OPTION == "PHY only"))}? cpnx_xgmii_clk : (IP_OPTION != "MAC only") ? phy_tx_gclk_o[0] : phy_pcs_clkin_i; //to MAC/PCS

assign xgmii_rxc       = gmii_16_rx_dv_o;
assign xgmii_rxd       = gmii_16_rx_d_o;
assign epcs_rxval      = {(PMI_FAMILY == "LFCPNX")&&((IP_OPTION == "MAC + PHY")||(IP_OPTION == "PHY only"))}? xg_rxval_o : (IP_OPTION != "MAC only") ? phyrdy_o : reset_n_i; //PCS is ready
assign phy_init_done   = {(PMI_FAMILY == "LFCPNX")&&((IP_OPTION == "MAC + PHY")||(IP_OPTION == "PHY only"))}? sys_ready_w : (IP_OPTION != "MAC only") ? phy_init_done_o : reset_n_i;                                            

//assign mdin_i           = mdin;     // MDIO Data In
//assign mdc_i            = mdc_neg;  // MDIO clock
//assign mdc_neg          = ~mdc;     // MDIO clock
//assign #1 mdio_io      = mdio_out;  // data from testbench
//assign    mdio_in      = mdio_io;   // going to read data of testbench

assign debug_link_timer_short = 'b0;
assign force_isolate   = 1'b0;
assign force_loopback  = 1'b0;
assign force_unidir    = 1'b0;
assign mr_adv_ability = 'h4001;
assign mr_an_enable = 'b0;
assign mr_main_reset = 'b0;
assign mr_restart_an = 'b0;

assign gmii_16_tx_err_i = 'b0;
//pullup(mdio_io);

//integer i, j;
integer error_count;

//--------------------------------------------------------------------------
// Initial statement; Reset sequence
//--------------------------------------------------------------------------
initial begin
  core_clk         = 1;
  sysbus_clk       = 1;
  //mdc		       = 1;
  reset_n_i        = 0;
  start_data_trans = 0;
  pcs_reset_n      = 0;
  `N_MSG(          ("************************************************"))
  `N_MSG(          ("Start of Simulation                             "))
  `N_MSG(          ("************************************************"))
  
  `TIME_DELAY(4,sysbus_clk)
   reset_n_i  = 1;

  `N_MSG(          ("+-----------------------------------------------"))
  `N_MSG(          ("Testbench Parameters                            "))
  `N_MSG(          ("+-----------------------------------------------"))
  `N_MSG(($sformatf("PHY Interface           :   %0s",SPEED_SEL      )))
  `N_MSG(($sformatf("Host Interface          :   %0s",HOST_IF        )))
   if ({IP_OPTION == "PHY only"}) begin
      `N_MSG(($sformatf("Client Interface        :   16-bit GMII"        )))
   end
   else begin
     `N_MSG(($sformatf("Client Interface        :   AXI4-Stream"        )))
   end
  `N_MSG(($sformatf("DATA WIDTH              :   %5f%0s",DATA_WIDTH   ,{{" "}})));
  `N_MSG(($sformatf("REFERENCE CLOCK (MHz)   :   %5f%0s",REFCLK_MHZ_156_25 ,{{" "}})));
  `N_MSG(($sformatf("XGMII CLOCK     (MHz)   :   %5f%0s",GMIICLK_MHZ ,{{" "}})));
  `N_MSG(          ("+-----------------------------------------------"))

  
  if (IP_OPTION != "MAC only") begin

    @(&phy_init_done)
    $display("+-----------------------------------------------");
    $display("PMA Ack assserted                               ");
    $display("+-----------------------------------------------"); 
    $display("+-----------------------------------------------");
    $display("Driving IDLE patterns at XGMII TX side          ");
    $display("while waiting for PCS RX PATH to be ready       ");
    $display("+-----------------------------------------------");
    if ((PMI_FAMILY == "LFCPNX") && ((IP_OPTION == "PHY only") || (IP_OPTION == "MAC + PHY"))) begin  
              $display("+-----------------------------------------------");
              $display("CPNX PCS RX is now ready");
              $display("+-----------------------------------------------");
    end
    else begin
        @(&epcs_rxval);
        $display("+-----------------------------------------------");
        $display("AVANT PCS RX is now ready");
        $display("+-----------------------------------------------");
    end
  end

//if ((PMI_FAMILY == "LFCPNX") && (IP_OPTION == "PHY only") && (HOST_IF == "MDIO")) begin
//        $display("+-----------------------------------------------");
//        $display("Starting MDIO Register Access                   ");
//        $display("PORT ADDRESS      : %d", PRTAD                   );
//        $display("DEVICE ADDRESS    :        3                    ");
//        $display("+-----------------------------------------------");
//        error_count = 0;
//        repeat(20) @(posedge mdc); // wait for some time
//        @(posedge mdc);
//
//            //PMA WR -- invalid address test
//            //smi_write(16'hFE00, 16'h00AB);
//            smi_read(16'h0000, 16'h0000, "mpcs_regfe00");
//            //MPCS WR
//            //smi_write(16'h0192, 16'h00FF);
//            //smi_read(16'h0192, 16'h00FF, "mpcs_reg192");  
//            smi_read(16'h0100, 16'h0022, "mpcs_reg100");
//            smi_read(16'h0120, 16'h0024, "mpcs_reg120");
//            smi_read(16'h0191, 16'h0000, "mpcs_reg191");
//            smi_read(16'h01A4, 16'h0000, "mpcs_reg1A4");
//
//            //RWR to RO reg
//            smi_read(16'h0121, 16'h0000, "mpcs_reg121");
//            smi_write(16'h0121, 16'h00FF);
//            smi_read(16'h0121, 16'h0000, "mpcs_reg121");
//
//            smi_read(16'h013E, 16'h0000, "mpcs_reg13E");
//            smi_write(16'h013E, 16'h00FF);
//            smi_read(16'h013E, 16'h0000, "mpcs_reg13E");
//
//            //smi_read(16'h0186, 16'h001B, "mpcs_reg186");
//            //smi_write(16'h0186, 16'h00FF);
//            //smi_read(16'h0186, 16'h001B, "mpcs_reg186"); 
//
//            smi_read(16'h0190, 16'h0000, "mpcs_reg190");
//            smi_write(16'h0190, 16'h00FF);
//            smi_read(16'h013E, 16'h0000, "mpcs_reg13E");
//
//            //smi_read(16'h0186, 16'h001B, "mpcs_reg186");
//            //smi_write(16'h0186, 16'h00FF);
//            //smi_read(16'h0186, 16'h001B, "mpcs_reg186"); 
//
//            smi_read(16'h0190, 16'h0000, "mpcs_reg190");
//            smi_write(16'h0190, 16'h00FF);
//            smi_read(16'h0190, 16'h0000, "mpcs_reg190");
//
//            //MPCS WWR
//            smi_write(16'h0192, 16'h00AB);
//            smi_write(16'h0192, 16'h00CD);
//            smi_read(16'h0192, 16'h00CD, "mpcs_reg192");
//            //MMD RO
//            smi_read(16'h0002, 16'h0000, "mmd1_dv_id_0");//MMD1 Device Identifier [2]  -- 16'h0
//            smi_read(16'h0003, 16'h0003, "mmd1_dv_id_1");//MMD1 Device Identifier [3]  -- 16'h3
//            smi_read(16'h0005, 16'h000A, "mmd1_dv_pkg_0");//Devices in Package [5]      -- 16'hA
//            smi_read(16'h0006, 16'h0000, "mmd1_dv_pkg_1");//Devices in Package [6]      -- 16'h0
//            smi_read(16'h0008, 16'h8000, "mmd1_stat_reg");//MMD1 Status Register        -- 16'h8000
//            smi_read(16'h000E, 16'h0000, "mmd1_pkg_id_0");//MMD1 Package Identifier [E] -- 16'h0
//            smi_read(16'h000F, 16'h0003, "mmd1_pkg_id_1");//MMD1 Package Identifier [F] -- 16'h3
//            //Sample MPCS reg check
//            //smi_read(16'h0100, 16'h0022, "mpcs_reg100");
//            //smi_read(16'h0120, 16'h0024, "mpcs_reg120");
//
//        @(posedge mdc);
//        if (mdio_tb_error_w == 0 && error_count == 0) begin
//          $display("\n[%010t] [TEST]: SIMULATION PASSED \n", $time);
//        end
//        else begin
//          $error("\n[%010t] [TEST]: SIMULATION FAILED - No of Errors = %0d.\n", $time, error_count);
//          $display("+-----------------------------------------------");
//          $display("END of MDIO Register Access                           ");
//          $display("+-----------------------------------------------");
//        end
//end

 if (IP_OPTION != "PHY only") begin
       `N_MSG(          ("+-----------------------------------------------"))
       `N_MSG(          ("Driving %0s Register transactions      ",HOST_IF))
       `N_MSG(          ("+-----------------------------------------------"))

       @(&(axi4l_done||apb_done))
       `TIME_DELAY(100,sysbus_clk)

      if (IP_OPTION == "MAC + PHY" ) begin
        $display("+-----------------------------------------------");
        $display("Starting APB Register Access                    ");
        $display("+-----------------------------------------------");
        error_count = 0;
        repeat(20) @(posedge sysbus_clk); // wait for some time
        //register_check(); //No cover for PHY reg
        @(posedge sysbus_clk);
        if (apb_tb_error_w == 0 && error_count == 0) begin   //!!!TODO check apb_tb_error_w
          $display("\n[%010t] [TEST]: SIMULATION PASSED \n", $time);
        end
        else begin
          $display("\n[%010t] [TEST]: SIMULATION FAILED - No of Errors = %0d.\n", $time, error_count);
          $display("+-----------------------------------------------");
          $display("END of APB Register Access                      ");
          $display("+-----------------------------------------------");
        end
 
       `TIME_DELAY(100,sysbus_clk)
       `N_MSG(        ("+-----------------------------------------------"))
          if (axi4l_tb_error_w || apb_tb_error_w) begin
            `E_MSG(        ("******************** FAILED ********************"))
	        `E_MSG(        ("********* REGISTER MISMATCH ENCOUNTERED ********"))
          end
          else if (!reg_obs_valid) begin
            `E_MSG(        ("******************** FAILED ********************"))
            `E_MSG(        ("************* NO READ DATA RECEIVED ************"))
          end
          else begin
            `N_MSG(        ("************ REGISTER ACCESS PASSED ************"))
          end 
            `N_MSG(        ("+-----------------------------------------------"))
      end
  end
 
  if ((PMI_FAMILY == "LFCPNX") && IP_OPTION == "MAC + PHY") begin //delay xgmii data start due to rx link start late in CPNX.
   `TIME_DELAY(150,sysbus_clk)
    start_data_trans = 1;
  end
  else begin
    `TIME_DELAY(50,sysbus_clk)
    start_data_trans = 1;
  end

  @(&(tb_done_w || xgmii_done))
  if (IP_OPTION == "MAC only") begin
	  `TIME_DELAY(8000,sysbus_clk)
  end else begin
	  `TIME_DELAY(500,sysbus_clk)
  end

  start_data_trans = 0;
  `N_MSG(          ("+-----------------------------------------------"))
  `N_MSG(          ("Transaction Done                                "))
  `N_MSG(          ("+-----------------------------------------------"))

  if (IP_OPTION != "PHY only") begin
    while (!obs_valid & !tb_done_w)begin
      @(posedge sysbus_clk);
      while(obs_valid)begin
        @(negedge obs_valid);
      end
    end
  end

  if (tb_error_w || tb_error_xgmii_w) begin
    `E_MSG(        ("******************** FAILED ********************"))
	`E_MSG(        ("*********** DATA MISMATCH ENCOUNTERED **********"))
  end
  else if (!obs_valid_Q) begin
  `E_MSG(        ("******************** FAILED ********************"))
  `E_MSG(        ("*************** NO DATA RECEIVED ***************"))
  end
  else begin
    `N_MSG(      ("*********** DATA TRANSACTION PASSED ************"))
  end

  `N_MSG(          ("+-----------------------------------------------"))
  `N_MSG(          ("+-----------------------------------------------"))
  if (!tb_error_w && !reg_tb_error_w && obs_valid_Q) begin
    `N_MSG(        ("             SIMULATION PASSED                  "))
  end
  else begin
    `E_MSG(        ("             SIMULATION FAILED                  "))
  end
  `ENDSIM(50,sysbus_clk)
end

//--------------------------------------------------------------------------
// Clock source
//--------------------------------------------------------------------------
   always #((CLKPERIOD)/2.0000) 
      sysbus_clk = ~sysbus_clk;
  //Avant need 156.25 Mhz as the XCVR ref clk 
    always #(CCLKPERIOD/2.0000) 
      core_clk = ~core_clk;

//always #(PERIOD_400/2.0000)
//	mdc = ~mdc;

//--------------------------------------------------------------------------
// GSR
//--------------------------------------------------------------------------
GSR_CORE GSR_INST (
  .GSROUT            (gsr_out   ), 
  .GSR_N             (reset_n_i ), 
  .CLK               (sysbus_clk)
);

//--------------------------------------------------------------------------
// APB Driver
//--------------------------------------------------------------------------
tb_apb_mst u_tb_apb_mst (
  .apb_pclk          (sysbus_clk         ),
  //.apb_preset_n      ((PMI_FAMILY == "LFCPNX") ? (apb_en && epcs_rxval ) : (apb_en && phy_init_done && epcs_rxval )),
  .apb_preset_n      (apb_en && phy_init_done && epcs_rxval),
  .apb_prdata        (apb_prdata_o       ),
  .apb_pready        (apb_pready_o       ),
  .apb_pslverr       (apb_pslverr_o      ),
  .apb_paddr         (apb_paddr_i        ),
  .apb_penable       (apb_penable_i      ),
  .apb_psel          (apb_psel_i         ),
  .apb_pwdata        (apb_pwdata_i       ),
  .apb_pwrite        (apb_pwrite_i       ),
  .done              (apb_done           )
);

//--------------------------------------------------------------------------
// Data Checker - MDIO
//--------------------------------------------------------------------------
//tb_data_checker #(
//  .WADDR_DEPTH       (WADDR_DEPTH         ),
//  .WADDR_WIDTH       (clog2(WADDR_DEPTH)  ),
//  .WDATA_WIDTH       (DATA_WIDTH          ),
//  .RADDR_DEPTH       (RADDR_DEPTH         ),
//  .RADDR_WIDTH       (clog2(RADDR_DEPTH)  ),
//  .RDATA_WIDTH       (DATA_WIDTH          )
//) u_tb_data_checker_mdio (
//  // Outputs
//  .error_o           (mdio_tb_error_w            ),
//  // Inputs                             
//  .clk_i             (mdc          ),
//  .rst_n_i           (reset_n_i & sys_ready_w),
//  .direction_i       (1'b1                ),
//  .exp_valid_i       (exp_valid           ),
//  .exp_data_i        (exp_data            ),
//  .obs_valid_i       (obs_valid           ),
//  .obs_data_i        (obs_data            ),
//  .byte_en_i         (xgmii_rxc           ),
//  .eof_i             (1'b1                )
//);


//--------------------------------------------------------------------------
// Data Checker - APB
//--------------------------------------------------------------------------
tb_data_checker #(
  .WADDR_DEPTH       (WADDR_DEPTH       ),
  .WADDR_WIDTH       (clog2(WADDR_DEPTH)),
  .WDATA_WIDTH       (REG_WIDTH         ),
  .RADDR_DEPTH       (RADDR_DEPTH       ),
  .RADDR_WIDTH       (clog2(RADDR_DEPTH)),
  .RDATA_WIDTH       (REG_WIDTH         )
) u_tb_data_checker_apb (
  // Outputs
  .error_o           (apb_tb_error_w    ), 
  // Inputs                             
  .clk_i             (sysbus_clk        ),
  .rst_n_i           ((phy_init_done && apb_en)),
  .trans_done	     (apb_done),
  .direction_i       (1'b1              ),
  .exp_valid_i       (apb_exp_valid     ),
  .exp_data_i        (apb_exp_data      ),
  .obs_valid_i       (apb_obs_valid     ),
  .obs_data_i        (apb_obs_data      ),
  .byte_en_i         (8'hFF             ),
  .eof_i             (1'b0              )
);

//--------------------------------------------------------------------------
// AXI4-lite Driver
//--------------------------------------------------------------------------
tb_axi4l_drv u_tb_axi4l_drv (
  .i_clk              (sysbus_clk           ),
  .rst_n_i            (phy_init_done && axi4l_en && epcs_rxval),
  .axi_awvalid		  (axi4l_awvalid_i      ),
  .axi_awready		  (axi4l_awready_o      ),
  .axi_awaddr		  (axi4l_awaddr_i	    ),
  .axi_awprot		  (axi4l_awprot_i	    ),
  .axi_wvalid		  (axi4l_wvalid_i	    ),	
  .axi_wready		  (axi4l_wready_o	    ),
  .axi_wdata		  (axi4l_wdata_i	    ),
  .axi_wstrb		  (axi4l_wstrb_i	    ),
  .axi_bvalid	  	  (axi4l_bvalid_o	    ),
  .axi_bready	  	  (axi4l_bready_i	    ),
  .axi_bresp	  	  (axi4l_bresp_o	    ),
  .axi_arvalid		  (axi4l_arvalid_i      ),
  .axi_arready		  (axi4l_arready_o      ),
  .axi_araddr		  (axi4l_araddr_i	    ),
  .axi_arprot		  (axi4l_arprot_i	    ),
  .axi_rvalid		  (axi4l_rvalid_o	    ),
  .axi_rready		  (axi4l_rready_i	    ),
  .axi_rdata		  (axi4l_rdata_o	    ),
  .axi_rresp		  (axi4l_rresp_o	    ),
  .done               (axi4l_done           )  
);

//--------------------------------------------------------------------------
// Data Checker - AXI4-lite
//--------------------------------------------------------------------------
tb_data_checker #(
  .WADDR_DEPTH       (WADDR_DEPTH       ),
  .WADDR_WIDTH       (clog2(WADDR_DEPTH)),
  .WDATA_WIDTH       (REG_WIDTH         ),
  .RADDR_DEPTH       (RADDR_DEPTH       ),
  .RADDR_WIDTH       (clog2(RADDR_DEPTH)),
  .RDATA_WIDTH       (REG_WIDTH         )
) u_tb_data_checker_axi4l (
  // Outputs
  .error_o           (axi4l_tb_error_w  ),
  // Inputs                             
  .clk_i             (sysbus_clk        ),
  .rst_n_i           (phy_init_done && axi4l_en         ),
  .trans_done	     (axi4l_done),
  .direction_i       (1'b1              ),
  .exp_valid_i       (axi4l_exp_valid   ),
  .exp_data_i        (axi4l_exp_data    ),
  .obs_valid_i       (axi4l_obs_valid   ),
  .obs_data_i        (axi4l_obs_data    ),
  .byte_en_i         (8'hFF             ),
  .eof_i             (1'b0              )
);
//--------------------------------------------------------------------------
// AXI-4 Stream Driver
//--------------------------------------------------------------------------
tb_axis_mst u_tb_axis_mst ( 
  .axis_tvalid_o     (axis_tx_tvalid_i      ),
  .axis_tlast_o      (axis_tx_tlast_i       ),
  .axis_tid_o        (                      ),
  .axis_tdest_o      (                      ),
  .axis_tdata_o      (axis_tx_tdata_i       ),
  .axis_tstrb_o      (                      ),
  .axis_tkeep_o      (axis_tx_tkeep_i       ),
  .axis_tuser_o      (axis_tx_tuser_i       ),
  .axis_aclk_i       (xgmii_clk             ),
  .axis_arstn_i      (phy_init_done             ),
  .axis_tready_i     (axis_tx_tready_o      ),
  .sys_ready_i       (((apb_done || axi4l_done) && start_data_trans && (IP_OPTION!="PHY only"))),
  .done              (tb_done_w            )
);
//--------------------------------------------------------------------------
// Data Checker - AXI4-Stream
//--------------------------------------------------------------------------
tb_data_checker #(
  .WADDR_DEPTH       (WADDR_DEPTH       ),
  .WADDR_WIDTH       (clog2(WADDR_DEPTH)),
  .WDATA_WIDTH       (DATA_WIDTH        ),
  .RADDR_DEPTH       (RADDR_DEPTH       ),
  .RADDR_WIDTH       (clog2(RADDR_DEPTH)),
  .RDATA_WIDTH       (DATA_WIDTH        )
) u_tb_data_checker_axi4s (
  // Outputs
  .error_o           (tb_error_w        ),
  // Inputs                             
  .clk_i             (xgmii_clk      ),
  .rst_n_i           (phy_init_done && IP_OPTION!="PHY only"        ),
  .trans_done        (tb_done_w),  
  .direction_i       (1'b1              ),
  .exp_valid_i       (exp_valid         ),
  .exp_data_i        (exp_data          ),
  .obs_valid_i       (obs_valid         ),
  .obs_data_i        (obs_data          ),
  .byte_en_i         (axis_rx_tkeep_o   ),
  .eof_i             (axis_rx_tlast_o   )
);

//--------------------------------------------------------------------------
// 16-bits GMII driver
//--------------------------------------------------------------------------
tb_gmii_mst gmii_mst (
  .clk               (xgmii_clk        ),
  .control           (control    ),
  .gmii_data         (gmii_16_tx_d_i      ),
  .gmii_en           (gmii_16_tx_en_i     ),
  .trans_done        (xgmii_done          ),
  .trans_start       (IP_OPTION=="PHY only" ? (start_data_trans & phy_rxval_o)  : ((apb_done || axi4l_done) && start_data_trans))
);

//--------------------------------------------------------------------------
// Data Checker - 16-bits GMII
//--------------------------------------------------------------------------
tb_data_checker #(
  .WADDR_DEPTH       (WADDR_DEPTH         ),
  .WADDR_WIDTH       (clog2(WADDR_DEPTH)  ),
  .WDATA_WIDTH       (DATA_WIDTH          ),
  .RADDR_DEPTH       (RADDR_DEPTH         ),
  .RADDR_WIDTH       (clog2(RADDR_DEPTH)  ),
  .RDATA_WIDTH       (DATA_WIDTH          )
) u_tb_data_checker_16_gmii (
  // Outputs
  .error_o           (tb_error_xgmii_w    ),
  // Inputs                             
  .clk_i             (phy_rx_clk_o        ),
  .rst_n_i           ( phy_init_done && epcs_rxval && IP_OPTION=="PHY only"),
  .trans_done        (xgmii_done          ),
  .direction_i       (1'b1                ),
  .exp_valid_i       (exp_valid           ),
  .exp_data_i        (exp_data            ),
  .obs_valid_i       (obs_valid           ),
  .obs_data_i        (obs_data            ),
  .byte_en_i         (xgmii_rxc_r         ),
  .eof_i             (1'b1                )
);
//--------------------------------------------------------------------------
// DUT
//--------------------------------------------------------------------------
generate
if ((PMI_FAMILY == "LFCPNX") && (IP_OPTION == "MAC + PHY")) begin : MAC_PHY_SIM

   assign pad_refclkn_i   = {(PMA_REFCLK == "sdq0_refclk")||(PMA_REFCLK == "manual_select")} ? core_clk : 1'b1;
   assign pad_refclkp_i   = {(PMA_REFCLK == "sdq0_refclk")||(PMA_REFCLK == "manual_select")} ? ~core_clk : 1'b0;

   assign refclkp0_ext_i  = {(PMA_REFCLK == "refclkdiff0_ext")||(PMA_REFCLK == "sd_ext_0_refclk")} ? core_clk : 1'b0;
   assign refclkn0_ext_i  = {(PMA_REFCLK == "refclkdiff0_ext")||(PMA_REFCLK == "sd_ext_0_refclk")} ? ~core_clk : 1'b1;

   assign refclkp1_ext_i  = {(PMA_REFCLK == "refclkdiff1_ext")||(PMA_REFCLK == "sd_ext_1_refclk")}  ? core_clk : 1'b0;
   assign refclkn1_ext_i  = {(PMA_REFCLK == "refclkdiff1_ext")||(PMA_REFCLK == "sd_ext_1_refclk")}  ? ~core_clk : 1'b1;

   assign sd_pll_refclk_i = (PMA_REFCLK == "sd_pll_refclk") ? core_clk : 1'b0;
   assign refclk_156      = {(PMA_REFCLK == "pclk0")||(PMA_REFCLK == "pclk1")} ? core_clk : 1'b0;

   assign use_refmux_i   = {(PMA_REFCLK == "manual_select")||(PMA_REFCLK == "sdq0_refclk")} ? 1'b0 : 1'b1;  //Use dedicated refclks
   assign diffioclksel_i = {(PMA_REFCLK == "sd_ext_1_refclk")} ? 1'b1 : 1'b0;
   assign clksel_i       = {(PMA_REFCLK == "pclk1")} ? 2'b01 : (({PMA_REFCLK == "sd_ext_0_refclk"}||{PMA_REFCLK == "sd_ext_1_refclk"}||{PMA_REFCLK == "refclkdiff0_ext"}||{PMA_REFCLK == "refclkdiff1_ext"}) ? 2'b10 : (({PMA_REFCLK == "sd_pll_refclk"}) ? 2'b11 : 2'b00));

   //PHY reset
   assign phy_tx_rst_n_i   = reset_n_i;
   assign phy_rx_rst_n_i   = reset_n_i & epcs_rxval;
   assign epcs_tx_out_clk = phy_tx_clk_o; //to PLL
   assign xg_rxval_o      = phy_rxval_o;
   assign sys_ready_w     = phy_txrdy_o & epcs_rxval; //&  xg_rx_blk_lock_o; this signal not available in new mpcs

   assign pad_rxn_i       = txn;
   assign pad_rxp_i       = txp;
   assign phy_pcs_clkin_i = core_clk;
   assign phy_tx_clk_i = phy_tx_clk_o;
   assign phy_rx_clk_i = phy_rx_clk_o;

   assign apb_pclk_i      = sysbus_clk          ;
   assign apb_preset_n_i  = reset_n_i           ;
   assign apb_psel_i      = apb_psel            ;
   assign apb_penable_i   = apb_penable         ;
   assign apb_paddr_i     = apb_paddr           ;
   assign apb_pwdata_i    = apb_pwdata          ;
   assign apb_pwrite_i    = apb_pwrite          ;
   
   assign md_resetn_i     = reset_n_i            ;
  
   assign txn             = pad_txn_o           ;
   assign txp             = pad_txp_o           ;
   
   assign apb_prdata      = apb_prdata_o        ;
   assign apb_pready      = apb_pready_o        ;
   //assign mdin_i          = mdin;     // MDIO Data In
   //assign mdc_i           = mdc_neg;  // MDIO clock
   //assign mdc_neg         = ~mdc;     // MDIO clock
   //assign #1 mdio_io      = mdio_out;  // data from testbench
   //assign    mdio_in      = mdio_io;   // going to read data of testbench
   
end
else if ((PMI_FAMILY == "LFCPNX") && (IP_OPTION == "PHY only")) begin : CPNX_PHY_SIM
   
   assign pad_refclkn_i   = {(PMA_REFCLK == "sdq0_refclk")||(PMA_REFCLK == "manual_select")} ? core_clk : 1'b1;
   assign pad_refclkp_i   = {(PMA_REFCLK == "sdq0_refclk")||(PMA_REFCLK == "manual_select")} ? ~core_clk : 1'b0;

   assign refclkp0_ext_i  = {(PMA_REFCLK == "refclkdiff0_ext")||(PMA_REFCLK == "sd_ext_0_refclk")} ? core_clk : 1'b0;
   assign refclkn0_ext_i  = {(PMA_REFCLK == "refclkdiff0_ext")||(PMA_REFCLK == "sd_ext_0_refclk")} ? ~core_clk : 1'b1;

   assign refclkp1_ext_i  = {(PMA_REFCLK == "refclkdiff1_ext")||(PMA_REFCLK == "sd_ext_1_refclk")}  ? core_clk : 1'b0;
   assign refclkn1_ext_i  = {(PMA_REFCLK == "refclkdiff1_ext")||(PMA_REFCLK == "sd_ext_1_refclk")}  ? ~core_clk : 1'b1;

   assign sd_pll_refclk_i = (PMA_REFCLK == "sd_pll_refclk") ? core_clk : 1'b0;
   assign refclk_156      = {(PMA_REFCLK == "pclk0")||(PMA_REFCLK == "pclk1")} ? core_clk : 1'b0;

   assign use_refmux_i   = {(PMA_REFCLK == "manual_select")||(PMA_REFCLK == "sdq0_refclk")} ? 1'b0 : 1'b1;  //Use dedicated refclks
   assign diffioclksel_i = {(PMA_REFCLK == "sd_ext_1_refclk")} ? 1'b1 : 1'b0;
   assign clksel_i       = {(PMA_REFCLK == "pclk1")} ? 2'b01 : (({PMA_REFCLK == "sd_ext_0_refclk"}||{PMA_REFCLK == "sd_ext_1_refclk"}||{PMA_REFCLK == "refclkdiff0_ext"}||{PMA_REFCLK == "refclkdiff1_ext"}) ? 2'b10 : (({PMA_REFCLK == "sd_pll_refclk"}) ? 2'b11 : 2'b00));
   
   //PHY reset
   assign phy_tx_rst_n_i   = reset_n_i;
   assign phy_rx_rst_n_i   = reset_n_i & phy_txrdy_o & phyrdy_o;

   assign pad_rxn_i       = txn;
   assign pad_rxp_i       = txp;
   assign phy_pcs_clkin_i = core_clk;
   assign phy_tx_clk_i = phy_tx_clk_o;
   assign phy_rx_clk_i = phy_rx_clk_o;

   assign debug_link_timer_short = 'b0;
   assign force_isolate   = 1'b0;
   assign force_loopback  = 1'b0;
   assign force_unidir    = 1'b0;
   assign mr_adv_ability = 'h4001;
   assign mr_an_enable = 'b0;
   assign mr_main_reset = 'b0;
   assign mr_restart_an = 'b0;

   assign gmii_16_tx_err_i = 'b0;

   assign apb_pclk_i      = sysbus_clk          ;
   assign apb_preset_n_i  = reset_n_i             ;
   assign apb_psel_i      = apb_psel            ;
   assign apb_penable_i   = apb_penable         ;
   assign apb_paddr_i     = apb_paddr           ;
   assign apb_pwdata_i    = apb_pwdata          ;
   assign apb_pwrite_i    = apb_pwrite          ;
   
   assign md_resetn_i    = reset_n_i              ;
   
   assign txn             = pad_txn_o           ;
   assign txp             = pad_txp_o           ;
   assign epcs_tx_out_clk = phy_tx_clk_o         ; //to PLL
   
   assign xgmii_rxc       = gmii_16_rx_dv_o;          
   assign xgmii_rxd       = gmii_16_rx_d_o;         
   assign xg_rxval_o      = phy_rxval_o;
   assign epcs_rxval      = xg_rxval_o          ;
   
   assign apb_prdata      = apb_prdata_o        ;
   assign apb_pready      = apb_pready_o        ;
   //assign mdin_i           = mdin;     // MDIO Data In
   //assign mdc_i            = mdc_neg;  // MDIO clock
   //assign mdc_neg          = ~mdc;     // MDIO clock
   //assign #1 mdio_io      = mdio_out;  // data from testbench
   //assign    mdio_in      = mdio_io;   // going to read data of testbench
   
   assign sys_ready_w     = phy_txrdy_o & epcs_rxval;                                    
end
//else if ((PMI_FAMILY == "LAV-AT") && (IP_OPTION == "MAC + PHY")) begin : AVANT_MAC_PHY_SIM
//   assign rxmac_clk_i     = phy_rx_gclk_o;
//   assign txmac_clk_i     = phy_tx_gclk_o[0];
//   assign phy_tx_clk_i    = phy_tx_gclk_o[0];
//   assign phy_rx_clk_i    = phy_rx_gclk_o;
//end

else begin : NON_PTP_SIM //non-ptp sim
   //wire   phy_txrdy_o;
   assign phy_tx_rst_n_i   = reset_n_i;
   assign phy_rx_rst_n_i   = reset_n_i & epcs_rxval;
   assign epcs_tx_out_clk = phy_tx_clk_o; //to PLL
   assign xg_rxval_o      = phy_rxval_o;
   assign sys_ready_w     = phy_txrdy_o & epcs_rxval; //&  xg_rx_blk_lock_o; this signal not available in new mpcs

   assign pad_rxn_i       = txn;
   assign pad_rxp_i       = txp;
   assign phy_pcs_clkin_i = core_clk;
   assign phy_tx_clk_i = xgmii_clk;
   assign phy_rx_clk_i = xgmii_clk;

   assign apb_pclk_i      = sysbus_clk          ;
   assign apb_preset_n_i  = reset_n_i           ;
   assign apb_psel_i      = apb_psel            ;
   assign apb_penable_i   = apb_penable         ;
   assign apb_paddr_i     = apb_paddr           ;
   assign apb_pwdata_i    = apb_pwdata          ;
   assign apb_pwrite_i    = apb_pwrite          ;
   
   assign md_resetn_i     = reset_n_i            ;
  
   assign txn             = pad_txn_o           ;
   assign txp             = pad_txp_o           ;
   
   assign apb_prdata      = apb_prdata_o        ;
   assign apb_pready      = apb_pready_o        ;
   //assign mdin_i          = mdin;     // MDIO Data In
   //assign mdc_i           = mdc_neg;  // MDIO clock
   //assign mdc_neg         = ~mdc;     // MDIO clock
   //assign #1 mdio_io      = mdio_out;  // data from testbench
   //assign    mdio_in      = mdio_io;   // going to read data of testbench
end
endgenerate

generate if ({PMI_FAMILY != "LFCPNX"}) begin : avant_inst_gen
`include "dut_inst.v"
end else begin : cpnx_inst_gen
eval_top eval_top_inst(
    .reset_n_i(reset_n_i), 
    .sysbus_clk_i(sysbus_clk_i),

    .axis_tx_tvalid_i(axis_tx_tvalid_i), 
    .axis_tx_tlast_i(axis_tx_tlast_i), 
    .axis_tx_tkeep_i(axis_tx_tkeep_i), 
    .axis_tx_tdata_i(axis_tx_tdata_i), 
    .axis_tx_tuser_i(axis_tx_tuser_i), 
    .axis_tx_tready_o(axis_tx_tready_o), 
    .axis_rx_tvalid_o(axis_rx_tvalid_o), 
    .axis_rx_tlast_o(axis_rx_tlast_o), 
    .axis_rx_tkeep_o(axis_rx_tkeep_o), 
    .axis_rx_tdata_o(axis_rx_tdata_o), 
    .axis_rx_tuser_o(axis_rx_tuser_o), 

    .tx_statvec_o(tx_statvec_o), 
    .tx_staten_o(tx_staten_o), 
    .rx_statvec_o(rx_statvec_o), 
    .rx_staten_o(rx_staten_o), 

    .apb_psel_i(apb_psel_i), 
    .apb_paddr_i(apb_paddr_i), 
    .apb_pwdata_i(apb_pwdata_i), 
    .apb_pwrite_i(apb_pwrite_i), 
    .apb_penable_i(apb_penable_i), 
    .apb_pready_o(apb_pready_o), 
    .apb_prdata_o(apb_prdata_o), 
    .apb_pslverr_o(apb_pslverr_o), 

    .refclkp0_ext_i(refclkp0_ext_i), 
    .refclkn0_ext_i(refclkn0_ext_i), 
    .refclkp1_ext_i(refclkp1_ext_i), 
    .refclkn1_ext_i(refclkn1_ext_i), 
    .sd_pll_refclk_i(sd_pll_refclk_i), 
    .use_refmux_i(use_refmux_i), 
    .diffioclksel_i(diffioclksel_i), 
    .clksel_i(clksel_i),  
    .pad_refclkn_i(pad_refclkn_i), 
    .pad_refclkp_i(pad_refclkp_i), 
    .rxmac_clk_i(rxmac_clk_i),
    .txmac_clk_i(txmac_clk_i),
    .phy_tx_clk_i(phy_tx_clk_i),
    .phy_tx_rst_n_i(phy_tx_rst_n_i),
    .phy_rx_clk_i(phy_rx_clk_i),
    .phy_rx_rst_n_i(phy_rx_rst_n_i),

    .pad_rxn_i(pad_rxn_i), 
    .pad_rxp_i(pad_rxp_i), 
    .pad_txn_o(pad_txn_o), 
    .pad_txp_o(pad_txp_o), 
    .phy_pcs_clkin_i(phy_pcs_clkin_i), 
    .phy_tx_clk_o(phy_tx_clk_o), 
    .phy_rx_clk_o(phy_rx_clk_o), 
    .debug_link_timer_short(debug_link_timer_short), 
    .mr_adv_ability(mr_adv_ability), 
    .mr_an_enable(mr_an_enable), 
    .mr_main_reset(mr_main_reset), 
    .mr_restart_an(mr_restart_an), 
    .mr_an_complete(mr_an_complete), 
    .mr_lp_adv_ability(mr_lp_adv_ability), 
    .mr_page_rx(mr_page_rx), 
    .an_link_ok(an_link_ok), 
    .phy_rxval_o(phy_rxval_o), 
    .phy_txrdy_o(phy_txrdy_o), 
    .phyrdy_o(phyrdy_o), 
    .phy_link_sync_o(phy_link_sync_o), 
    .phy_rxidle_o(phy_rxidle_o), 

    .gmii_16_tx_d_i(gmii_16_tx_d_i), 
    .gmii_16_tx_en_i(gmii_16_tx_en_i), 
    .gmii_16_tx_err_i(gmii_16_tx_err_i), 
    .gmii_16_rx_d_o(gmii_16_rx_d_o), 
    .gmii_16_rx_dv_o(gmii_16_rx_dv_o), 
    .gmii_16_rx_err_o(gmii_16_rx_err_o), 

    .pcsrdy_i(pcsrdy_i),
    .gmii_16_rx_d_i(gmii_16_rx_d_i),
    .gmii_16_rx_dv_i(gmii_16_rx_dv_i),
    .gmii_16_rx_err_i(gmii_16_rx_err_i),
    .gmii_16_tx_d_o(gmii_16_tx_d_o),
    .gmii_16_tx_en_o(gmii_16_tx_en_o),
    .gmii_16_tx_err_o(gmii_16_tx_err_o),

    .refclk_156(refclk_156)
);
end
endgenerate

always @(posedge xgmii_clk or negedge phy_init_done) begin
  if (!phy_init_done) begin
    obs_valid_Q     <= 0;
  end
  else begin
    if (obs_valid) begin
       obs_valid_Q     <= 1'b1;
	end
  end
end

always @(posedge xgmii_clk or negedge phy_init_done) begin
  if (!phy_init_done) begin
    axi4l_obs_valid_Q     <= 0;
  end
  else begin
    if (axi4l_obs_valid) begin
       axi4l_obs_valid_Q     <= 1'b1;
	end
  end
end

always @(posedge xgmii_clk or negedge phy_init_done) begin
  if (!phy_init_done) begin
    apb_obs_valid_Q     <= 0;
  end
  else begin
    if (apb_obs_valid) begin
       apb_obs_valid_Q     <= 1'b1;
	end
  end
end

//------------------------------------------------------------------------------
// Function Definition
//------------------------------------------------------------------------------
// synopsys translate_off
function [31:0] clog2;
  input [31:0] value;
  reg   [31:0] num;
  begin
    num = value - 1;
    for (clog2 = 0; num > 0; clog2 = clog2 + 1) num = num >> 1;
  end
endfunction
// synopsys translate_on

generate
if (IP_OPTION == "MAC + PHY + 1588") begin

task register_check();
  reg [REG_DWIDTH-1:0]  wr_data;
  reg [REG_DWIDTH-1:0]  rd_data;
  begin
    $display("\n[%010t] [TEST]: Register access test start!", $time);
      rd_check_all_regs(); 
    $display("[%010t] [TEST]: Register access check end.", $time);
    $display("[%010t] [TEST]:Register test end!\n", $time);
  end
endtask


task rd_check_all_regs();
  reg [REG_DWIDTH-1:0]  rd_data;
  begin
    u_tb_apb_mst.m_read_16(30724, rd_data); //MMD1 Device Identifier [2]  
    data_compare_reg(rd_data[15:0], 16'h0, "mmd1_dv_id_0", 30724);     //-- 16'h0
    
    u_tb_apb_mst.m_read_16(30725, rd_data); //MMD1 Device Identifier [3]  
    data_compare_reg(rd_data[15:0], 16'h3, "mmd1_dv_id_1", 30725);    //-- 16'h3
    
    u_tb_apb_mst.m_read_16(30730, rd_data); //Devices in Package [5]      
    data_compare_reg(rd_data[15:0], 16'hA, "mmd1_dv_pkg_0", 30730);    //-- 16'hA
    
    u_tb_apb_mst.m_read_16(30731, rd_data); //Devices in Package [6]      
    data_compare_reg(rd_data[15:0], 16'h0, "mmd1_dv_pkg_1", 30731);    //-- 16'h0
    
    u_tb_apb_mst.m_read_16(30736, rd_data); //MMD1 Status Register        
    data_compare_reg(rd_data[15:0], 16'h8000, "mmd1_stat_reg", 30736);  //-- 16'h8000
    
    u_tb_apb_mst.m_read_16(30748, rd_data); //MMD1 Package Identifier [E] 
    data_compare_reg(rd_data[15:0], 16'h0, "mmd1_pkg_id_0", 30748);    //-- 16'h0
    
    u_tb_apb_mst.m_read_16(30749, rd_data); //MMD1 Package Identifier [F] 
    data_compare_reg(rd_data[15:0], 16'h3, "mmd1_pkg_id_1", 30749);    //-- 16'h3
	
	//Sample MPCS reg check
	u_tb_apb_mst.m_read_16(31488, rd_data);
    data_compare_reg(rd_data[15:0], 16'h22, "mpcs_reg100", 31488);    
	
	u_tb_apb_mst.m_read_16(31520, rd_data);
    data_compare_reg(rd_data[15:0], 16'h24, "mpcs_reg120", 31520);    
    
  end
endtask

task data_compare_reg(
  input     [7:0]         act,
  input     [7:0]         exp,
  input reg [8*23:1]      reg_name,
  input     [3:0]         addr
);
  begin
    if (exp == act) begin
      $display("[%010t] [APB_reg_test]: PHY Data compare MATCHED on %0s register (APB Addr=0x%02x). Actual (0x%02x) == Expected (0x%02x).", $time, reg_name, addr, act, exp);
    end
    else begin // (exp != act) begin
      error_count = error_count + 1;
      $error("[%010t] [APB_reg_test]: PHY Data compare ERROR on %0s register (APB Addr=0x%02x). Actual (0x%02x) != Expected (0x%02x)!", $time, reg_name, addr, act, exp);
    end
  end
endtask
end


//--------------------------------------------------------------------------
// MDIO Tasks
//--------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Task : serial Management Interface read
//------------------------------------------------------------------------------
//task smi_read;
//   input [15:0]   address;
//   input [15:0]   data;     //Expected data
//   input [8*23:1] reg_name;
//   begin
//     smi_address(address);
//     smi_rddata(data, reg_name);
//   end
//endtask
//
////------------------------------------------------------------------------------
//// Task : serial Management Interface write
////------------------------------------------------------------------------------
//task smi_write;
//   input [15:0]  address;
//   input [15:0]  data;
//   begin
//     smi_address(address);
//     smi_wrdata(data);
//   end
//endtask
//
////------------------------------------------------------------------------------
//// Task : serial Management Interface Address
////------------------------------------------------------------------------------
//task smi_address;
//   input [15:0]  address;
//   reg   [1:0]   op;
//   reg   [1:0]   ta;
//   reg   [4:0]   phyaddr;
//   reg   [4:0]   devtype;
//
//   begin
//     op      = 2'b00;
//     ta      = 2'b10;
//     phyaddr = PRTAD;
//     devtype = DTYPE;
//     // Generate a high preamble
//     for (i = 31; i >= 0; i = i- 1) begin 
//        @(posedge mdc) 
//           mdio_out = 1;
//     end
//     // Generate ST = 00 
//     for (i = 1; i >= 0; i = i- 1) begin 
//        @(posedge mdc) 
//           mdio_out = 0;
//     end
//     // Generate OP
//     for (i = 1; i >= 0; i = i- 1) begin 
//        @(posedge mdc) begin
//           mdio_out = op[1];
//           op       = op << 1;
//        end
//     end
//     // Generate PRTAD 
//     for (i = 4; i >= 0; i = i- 1) begin 
//        @(posedge mdc) 
//            mdio_out = phyaddr[i];
//     end
//     // Generate DTYPE 
//     for (i = 4; i >= 0; i = i- 1) begin 
//        @(posedge mdc) 
//           mdio_out = devtype[i];
//     end
//     // Generate TA = 10
//     for (i = 1; i >= 0; i = i- 1) begin 
//        @(posedge mdc) begin
//           mdio_out = ta[1];
//           ta       = ta << 1;
//        end
//     end
//     // Generate Address 
//     for (i = 15; i >= 0; i = i- 1) begin
//        @(posedge mdc) 
//           mdio_out = address[i];
//     end
//   end
//endtask
//
////------------------------------------------------------------------------------
//// Task : serial Management Interface read Data
////------------------------------------------------------------------------------
//task smi_rddata;
//   input [15:0]       data;
//   input reg [8*23:1] reg_name;
//
//   reg   [1:0]   op;
//   reg   [1:0]   ta;
//   reg   [15:0]  rddata;
//   reg   [4:0]   phyaddr;
//   reg   [4:0]   devtype;
//
//   begin
//      op      = 2'b11;
//      ta      = 2'bZ0;
//      phyaddr = PRTAD;
//      devtype = DTYPE;
//      rddata  = 16'h0000;
//     // Generate a high preamble
//     for (i = 31; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = 1;
//     end
//     // Generate ST = 00
//     for (i = 1; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = 0;
//     end
//     // Generate OP
//     for (i = 1; i >= 0; i = i- 1) begin
//        @(posedge mdc) begin
//           mdio_out = op[1];
//           op       = op << 1;
//        end
//     end
//     // Generate PRTAD
//     for (i = 4; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//            mdio_out = phyaddr[i];
//     end
//     // Generate DTYPE
//     for (i = 4; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = devtype[i];
//     end
//     // Generate TA = Z0
//     for (i = 1; i >= 0; i = i- 1) begin 
//        @(posedge mdc) begin
//           mdio_out = ta[1];
//           ta       = ta << 1;
//        end
//     end
//      // Read Data 
////      for (i = 16; i >=0 ; i = i- 1) begin    // For NCVERILOG!!
//      for (i = 15; i >=0 ; i = i- 1) begin  // For MTI!!
//         mdio_out  = 1'bz;
//         @(posedge mdc) begin
//            rddata[i] = mdio_in;
//         end
//      end
//   
//      if(rddata === data) begin 
//        $display("[%010t] [MDIO_reg_test]: Data compare MATCHED on %0s register. Actual (0x%02x) == Expected (0x%02x).", $time, reg_name, rddata, data);
//    //    $display("[%010t] [reg_test]: Register data compare MATCHED. Actual (%h) == Expected (%h).", $time, rddata, data);
//      end
//      else begin //(rddata !== data) begin 
//        error_count = error_count + 1;
//        $error("[%010t] [MDIO_reg_test]: Data compare ERROR on %0s register. Actual (0x%02x) != Expected (0x%02x).", $time, reg_name, rddata, data);
//     //   $error("[%010t] [reg_test]: Register data compare ERROR. Actual (%h) != Expected (%h).", $time, rddata, data);
//      end
//   end
//endtask
//
////------------------------------------------------------------------------------
//// Task : serial Management Interface Write Data
////------------------------------------------------------------------------------
//task smi_wrdata;
//   input [15:0]  data;
//
//   reg   [1:0]   op;
//   reg   [1:0]   ta;
//   reg   [4:0]   phyaddr;
//   reg   [4:0]   devtype;
//
//   begin
//     op      = 2'b01;
//     ta      = 2'b10;
//     phyaddr = PRTAD;
//     devtype = DTYPE;
//     // Generate a high preamble
//     for (i = 31; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = 1;
//     end
//     // Generate ST = 00
//     for (i = 1; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = 0;
//     end
//     // Generate OP
//     for (i = 1; i >= 0; i = i- 1) begin
//        @(posedge mdc) begin
//           mdio_out = op[1];
//           op       = op << 1;
//        end
//     end
//     // Generate PRTAD
//     for (i = 4; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//            mdio_out = phyaddr[i];
//     end
//     // Generate DTYPE
//     for (i = 4; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = devtype[i];
//     end
//     // Generate TA = 10
//     for (i = 1; i >= 0; i = i- 1) begin 
//        @(posedge mdc) begin
//           mdio_out = ta[1];
//           ta       = ta << 1;
//        end
//     end
//     // Send Data 
//     for (i = 15; i >= 0; i = i- 1) begin
//        @(posedge mdc)
//           mdio_out = data[i];
//     end
//   end
//endtask

endgenerate

endmodule
