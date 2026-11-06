// =============================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// -----------------------------------------------------------------------------
//   Copyright (c) 2017 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED
// -----------------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement.
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
// -----------------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
// -----------------------------------------------------------------------------
//
// =============================================================================
//                         FILE DETAILS
// Project               :
// File                  : tb_top.v
// Title                 : Test bench for dphy_rx
// Dependencies          : 1.
//                       : 2.
// Description           : Example simulation environment.
//                         Supports limited testing features as primary intent 
//                         is to give you a starting point on checking the 
//                         functionality of the IP. Official IP verification 
//                         is done through UVM.
// =============================================================================

`timescale 1 ps / 1 ps

`include "bus_driver.sv"
`include "clk_driver.sv"
`include "csi2_model.sv"
`include "dsi_model.sv"
`include "tb_lmmi_model.sv"

`ifndef tb_top
`define tb_top

//---Testbench Local Settings
// Selects which DUT to instantiate in the testbench.
// When USE_EVAL_TOP_DUT is defined, testbench instantiates eval_top
// as DUT. Otherwise, testbench instantiates the generated IP (IPX).
//`define USE_EVAL_TOP_DUT

// Define if intended to run Gate-level simulations. Leave commented out if 
// running RTL sim.
//`define GATE_SIM

module tb_top();
// -----------------------------------------------------------------------------
// Local Parameters
// -----------------------------------------------------------------------------
// Parameters from GUI
`include "dut_params.v"
// Internal parameters for TB
//DPHY line rate
localparam real    DPHY_RATE_R          = BYTECLK_MHZ_FLOAT*RX_GEAR;
localparam integer DPHY_RATE            = BYTECLK_MHZ_FLOAT*RX_GEAR;
//in ps, clock period of DPHY.
localparam integer DPHY_CLK             = 2000000/(BYTECLK_MHZ_FLOAT*RX_GEAR);
localparam         CLK_PER              = ((1000/(BYTECLK_MHZ_FLOAT*RX_GEAR)) * 1000);
/// CSI-2
localparam [31:0]  HEADERSP1            = 32'h1A000100;
localparam [31:0]  HEADERLP1            = 32'h250BB824;
localparam [31:0]  HEADERSP2            = 32'h1D000101;
/// DSI
localparam [31:0]  VSYNCSTART_COMM      = 32'h00000001; 
localparam [31:0]  HSYNCSTART_COMM      = 32'h00000021;

localparam [31:0]  RGB666_COMM          = 32'h250BB83E; // Packed Pixel Stream, 
                                                        // 24-bit RGB, 8-8-8 Format
// Parameters that can be modified by user
localparam         DATA_TYPE            = "RGB888";
localparam         num_frames           = 1;            // number of frames
localparam         num_lines            = 4;            //number of video lines
// For lower data rates, corresponding byte clock period might be larger than 
// the minimum tLPX by protocol.In such case, TB will adjust timing from minimum
// to value that will make the simulation pass.
localparam         lp_sample_clkp       = CIL_BYPASS == "CIL_ENABLED" ? 
                                            (1000000/SYNCCLK_MHZ) :
                                             RX_GEAR*(DPHY_CLK/2);
localparam         t_lpx                = lp_sample_clkp >= 50000 ? 
                                             lp_sample_clkp*1.5 : 50000;
localparam         t_clk_prepare        = 38000;        // in ps, set between 
                                                        // 38 to 95 ns
localparam         t_clk_zero           = 262000;       // in ps, (clk_prepare + 
                                                        // clk_zero minimum 
                                                        // should be 300ns)
localparam         t_clk_pre            = 12*(DPHY_CLK/2); 
localparam         t_clk_post           = (1200000 + (52*DPHY_CLK/2)); 
                                                       // in ps, minimum of 
                                                       // 60ns+52*UI
localparam         t_clk_trail          = 60000;       // in ps, minimum of 60ns

localparam         t_hs_prepare         = (85000 + (6*DPHY_CLK/2)); // in ps, 
                                                       // set between 40ns+4*UI 
                                                       //to max of 85ns+6*UI
localparam         t_hs_zero            = ((145000 + (10*DPHY_CLK/2)) - 
                                          t_hs_prepare); // in ps, hs_prepare 
                                                         // + hs_zero minimum 
                                                         // should be 145ns+10*UI
localparam         t_hs_trail           = ((60000 + (4*DPHY_CLK/2)) + 
                                           (105000 + (12*DPHY_CLK/2)))*2/3; 
                                                       // in ps, minimum should 
                                                       // be 60ns+4*UI, max 
                                                       // should be 105ns+12*UI
localparam         t_init               = 100000000;   //in ps
localparam         vact_payload         = (DYN_DEL_EN == "ON") ? 16'd641 : 
                                          16'd321;     //VACT 2-byte word count 
                                                       // (total number of bytes
                                                       // of active pixels in 1 
                                                       // line)
localparam         hsa_payload          = 16'h007A;    //HSA 2-byte word count 
                                                       // (number of bytes of 
                                                       // payload, see MIPI DSI 
                                                       // spec v1.1 figure 30), 
                                                       // used for Non-burst 
                                                       // sync pulse
localparam         bllp_payload         = 16'h193A;    //BLLP 2-byte word count 
                                                       // (number of bytes of 
                                                       // payload, see MIPI DSI 
                                                       // spec v1.1 figure 30),
                                                       //  used for HS_ONLY mode
localparam         hbp_payload          = 16'h01AE;    //HBP 2-byte word count 
                                                       // (number of bytes of 
                                                       // payload, see MIPI DSI 
                                                       // spec v1.1 figure 30), 
                                                       // used for HS_ONLY mode 
                                                       // and HS_LP Non-burst 
                                                       // sync pulse
localparam         hfp_payload          = 16'h0100;    //HFP 2-byte word count 
                                                       // (number of bytes of 
                                                       // payload, see MIPI 
                                                       // DSI spec v1.1 figure 
                                                       // 30), used for HS_ONLY
                                                       // mode and HS_LP 
                                                       // Non-burst sync pulse
localparam         lps_bllp_duration    = 2470000;     // in ps, used for HS_LP 
                                                       // mode, this pertains 
                                                       // to the LP-11 state 
                                                       // duration for blanking
localparam         lps_actduration_req  = (((vact_payload+100)/NUM_RX_LANE)*(1000000/BYTECLK_MHZ_FLOAT))/2; 
                                                       // Checks how long to 
                                                       // transfer valid packet 
                                                       // (with allowance)
localparam         lps_hbp_duration     = lps_actduration_req > 800000 ? 
                                          lps_actduration_req : 800000; 
                                                       // in ps, used for HS_LP 
                                                       // Non-burst sync events 
                                                       // and burst mode, this 
                                                       // pertains to the LP-11 
                                                       // state duration for 
                                                       // horizontal back porch
localparam         lps_hfp_duration     = lps_actduration_req > 500000 ? 
                                          lps_actduration_req : 500000; 
                                                       // in ps, used for HS_LP 
                                                       // Non-burst sync events 
                                                       // and burst mode, this 
                                                       // pertains to the LP-11 
                                                       // state duration for 
                                                       // horizontal front porch
localparam         virtual_channel      = 2'h0;        // virtual channel ID
localparam         vsa_lines            = 5;           // number of VSA lines, 
                                                       // see MIPI DSI spec v1.1
                                                       // figure 30
localparam         vbp_lines            = 36;          // number of VBP lines, 
                                                       // see MIPI DSI spec v1.1
                                                       // figure 30
localparam         vfp_lines            = 4;           // number of VFP lines, 
                                                       // see MIPI DSI spec v1.1 
                                                       // figure 30
localparam         eotp_enable          = 1;           // to enable/disable EOTP 
                                                       // packet
localparam         debug_on             = 0;           // for enabling/disabling 
                                                       // DPHY data debug messages
localparam         frame_gap            = 5000000;     // delay between frames (in ps)
localparam         CSI2_NUM_PIXELS      = 1001;
localparam         FRAME_LPM_DELAY      = 5000000;
localparam         INIT_DELAY           = 5000000;
// Per IPUG, there is a 3 offset down for the set DATA_SETTLE_CYC When
// using soft D-PHY. 
localparam         DATA_SETTLE_CYC_TB   = CIL_BYPASS == "CIL_ENABLED" ? 
                                            T_DATA_SETTLE_INT : 
                                            DPHY_RX_IP=="LATTICE" ? 
                                               DATA_SETTLE_CYC+3 : 
                                               DATA_SETTLE_CYC;
// Actual DATA_SETTLE expected by IP
localparam         DATA_SETTLE_REQ_TB   = DATA_SETTLE_CYC_TB*lp_sample_clkp;
// New requirement from IP for v2.1.0+
// When D-PHY RX IP == Soft D-PHY or CIL Bypass is checked, 
// follow these guidelines:
// - the minimum duration of the tHS-PREPARE + tHS-ZERO from the D-PHY source 
//   must satisfy the following condition:
//       t_(HS-PREPARE)+t_(HS-ZERO)≥145ns+10"UI"+max⁡(X,Y)
// Where:
//       X = 2 x TCLK_BYTE, if corresponding byte clock is ≤ 30 MHz, 
//       otherwise X=0
//           TCLK_BYTE is clk_byte_o for Soft D-PHY and 
//           clk_byte_fr_i for Hard D-PHY with CIL bypassed
//       Y = 8 x TCLK_SYNC, if D-PHY RX IP == Soft D-PHY, 
//       otherwise Y=0
//           TCLK_SYNC is sync_clk_i.
localparam         max_x                = (CIL_BYPASS == "CIL_BYPASSED" && DPHY_RATE <= 240) ? 
                                             (2*lp_sample_clkp) : 0;
localparam         max_y                = (DPHY_RX_IP=="LATTICE") ? 
                                             (8*(1000000/SYNCCLK_MHZ)) : 0;
//localparam         t_hs_zero_req        = (CIL_BYPASS == "CIL_BYPASSED" && DPHY_RATE <= 240) ? 
//                                          t_hs_zero + (2*lp_sample_clkp) : t_hs_zero;
localparam         t_hs_zero_req        = (max_x > max_y) ? 
                                          t_hs_zero + max_x : t_hs_zero + max_y;
localparam         t_hs_zero_temp       = DATA_SETTLE_REQ_TB >= t_hs_zero_req+t_hs_prepare ? 
                                          DATA_SETTLE_REQ_TB - t_hs_prepare + 10000 : 
                                          t_hs_zero_req + 10000;
localparam         t_hs_zero_new        = (DPHY_RX_IP=="LATTICE" && RX_FIFO_TYPE == "QUEUE" && 
                                          BYTECLK_MHZ_FLOAT <= 30) ? 
                                          (1*lp_sample_clkp) + t_hs_zero_temp : 
                                          t_hs_zero_temp;
localparam         ls_le_en             = 0;
localparam [15:0]  CIL_WORD_COUNT       = 16'h1770 * 4/NUM_RX_LANE - 1;
// Internal parameters for TB
localparam         DATA_COUNT           = 800; // count of received data
localparam integer refclk_period        = (RX_CLK_MODE == "HS_LP")? 
                                          2000000/(BYTECLK_MHZ_FLOAT*RX_GEAR) : 
                                          1000000/BYTECLK_MHZ_FLOAT;
localparam         DATA_R_WIDTH         = (PARSER == "ON") ? 
                                          ((RX_GEAR == 16 & NUM_RX_LANE == 4) ? 64 :
                                           32) : 0;
localparam         AXI_DATA_WIDTH       = NUM_RX_LANE*RX_GEAR + DATA_R_WIDTH;
localparam         DATA_WIDTH           = NUM_RX_LANE*RX_GEAR;
localparam         ESC_CLK_PER          = 500000/SYNCCLK_MHZ;
localparam         VIDEO_DATA_TYPE      = REF_DT;
localparam         CMOS_DWIDTH          = (RX_TYPE == "DSI")? (
                                          (DATA_TYPE == "RGB666_LOOSE")?     6 :
                                          (DATA_TYPE == "RGB666")?           6 :
                                        /*(DATA_TYPE == "RGB888")?*/         8
                                        ) :
                                        (
                                          (DATA_TYPE == "RAW8")?             8 :
                                          (DATA_TYPE == "RAW10")?           10 :
                                          (DATA_TYPE == "RAW12")?           12 :
                                          (DATA_TYPE == "YUV420_10")?       10 :
                                          (DATA_TYPE == "YUV420_8")?         8 :
                                          (DATA_TYPE == "YUV422_10")?       10 :
                                          (DATA_TYPE == "YUV422_8")?         8 :
                                          (DATA_TYPE == "LEGACY_YUV420_8")?  8 :
                                          (DATA_TYPE == "YUV420_10_CSPS")?  10 :
                                          (DATA_TYPE == "YUV420_8_CSPS")?    8 :
                                        /*(DATA_TYPE == "RGB888")?*/        24
                                        );
localparam         num_pixels           = (RX_TYPE == "DSI")? (
                                          32'd0
                                         ) :
                                         (
                                           (DATA_TYPE == "RAW8")?            CSI2_NUM_PIXELS        :
                                           (DATA_TYPE == "RAW10")?           CSI2_NUM_PIXELS * 5/4  :
                                           (DATA_TYPE == "RAW12")?           CSI2_NUM_PIXELS * 3/2  :
                                           (DATA_TYPE == "YUV420_10")?       CSI2_NUM_PIXELS * 5/4  : // odd line
                                           (DATA_TYPE == "YUV420_8")?        CSI2_NUM_PIXELS        : // odd line
                                           (DATA_TYPE == "YUV422_10")?       CSI2_NUM_PIXELS * 5/2  :
                                           (DATA_TYPE == "YUV422_8")?        CSI2_NUM_PIXELS * 2    :
                                           (DATA_TYPE == "LEGACY_YUV420_8")? CSI2_NUM_PIXELS * 3/2  :
                                           (DATA_TYPE == "YUV420_10_CSPS")?  CSI2_NUM_PIXELS * 5/4  : // odd line
                                           (DATA_TYPE == "YUV420_8_CSPS")?   CSI2_NUM_PIXELS        : // odd line
                                         /*(DATA_TYPE == "RGB888")?*/        CSI2_NUM_PIXELS * 3
                                         );
localparam         long_even_line_en    = (RX_TYPE == "DSI")? (
                                           32'd0
                                          ) :
                                          (
                                            (DATA_TYPE == "RAW8")?            0 :
                                            (DATA_TYPE == "RAW10")?           0 :
                                            (DATA_TYPE == "RAW12")?           0 :
                                            (DATA_TYPE == "YUV420_10")?       1 :
                                            (DATA_TYPE == "YUV420_8")?        1 :
                                            (DATA_TYPE == "YUV422_10")?       0 :
                                            (DATA_TYPE == "YUV422_8")?        0 :
                                            (DATA_TYPE == "LEGACY_YUV420_8")? 0 :
                                            (DATA_TYPE == "YUV420_10_CSPS")?  1 :
                                            (DATA_TYPE == "YUV420_8_CSPS")?   1 :
                                          /*(DATA_TYPE == "RGB888")?*/        0
                                          );
// Sets the Packet gaps between DPHY transactions
localparam         lps_gap          = (RX_TYPE == "DSI") ? 5000000 : 
                                       num_pixels*(1000000/BYTECLK_MHZ_FLOAT);

// Deskew Calibration
localparam [15:0] DESKEW_SYNC       = 16'hFFFF;     // Deskew SYNC
localparam [7:0]  DESKEW_PATT       = 8'b1010_1010; // Deskew Pattern
localparam        DESKEW_DUR        = 32768;        // Deskew Duration (min 2**15 UI)


// -----------------------------------------------------------------------------
// Generate Variables
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Testbench Integer and File Handles
real    dphy_clk;          // DPHY clock period (ps)
integer l = 0;             // General-purpose loop variable
integer true_result  = 0;  // Counter for correct data comparisons
integer false_result = 0;  // Counter for incorrect data comparisons
integer D_true_res;        // Number of true (matching) results in file compare
integer D_false_res;       // Number of mismatched results in file compare
integer D_file_1_value;    // Value read from first file during compare
integer D_file_2_value;    // Value read from second file during compare
integer D_file_1;          // File handle for expected data file
integer D_file_2;          // File handle for received data file
integer D_status_1;        // Status of fscanf for file 1
integer D_status_2;        // Status of fscanf for file 2

integer byte_num;          // Number of bytes to compare per frame/line
integer data_ctr;          // Data counter for compare loops
integer line_ctr;          // Line counter for compare loops
integer frame_ctr;         // Frame counter for compare loops

integer f;                    // File handle for writing received data
initial f = $fopen("received_data.txt","w");

// -----------------------------------------------------------------------------
// Sequential Registers
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// IP ports
reg        pd_dphy_i;
// -----------------------------------------------------------------------------
// LMMI
logic        lmmi_clk_r     = 1'd0;
logic        lmmi_resetn_r;
logic [ 7:0] lmmi_wdata_r;
logic        lmmi_wr_rdn_r;
logic [ 7:0] lmmi_offset_r;
logic        lmmi_request_r;
logic        lmmi_cmp_fail_r;

// APB
reg        pclk_r         = 1'd0;
reg [5:0]  apb_paddr_r    =  'd0;
reg [7:0]  apb_pwdata_r   =  'd0;
reg        apb_pwrite_r   = 1'd0;
reg        apb_psel_r     = 1'd0;
reg        apb_penable_r  = 1'd0;
reg        apb_pready_r   = 1'd0;

// Reset
reg        sync_rst_r = 1;
reg        reset_lp_w;
reg        reset_byte_fr_w;
reg        reset_byte_w;
reg        system_resetn_w;

reg        cont_clk;
reg        refclk_i;
reg        sync_clk_r        = 0;
reg        lp_ctrl_clk       = 0;
reg        clock_fr_r        = 0;

// Enable
reg        diff_clk_en;
reg        first_byte_data_r = 1'd0;
reg        pay_data_pass_r   = 1'd0;
reg        valid_data_r      = 1'd0;

// Counter
reg [15:0] byte_count_r      = 16'd0;

// GSR
reg        CLK_GSR  = 0;
reg        USER_GSR = 1;

// Data holder
reg [7:0]  act_data [$];
reg [7:0]  exp_data [$];

// ECC Checker
reg        ecc_err_flag_tb   = 0;
reg        ecc_berr_flag_tb  = 0;
reg        ecc_1berr_flag_tb = 0;
reg        ecc_2berr_flag_tb = 0;
reg        crc_err_flag_tb   = 0;

// -----------------------------------------------------------------------------
// Wire Declarations
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// IP Ports
// LMMI
wire                      lmmi_clk_i;
wire                      lmmi_resetn_i;
wire [7:0]                lmmi_wdata_i;
wire                      lmmi_wr_rdn_i;
wire [7:0]                lmmi_offset_i;
wire                      lmmi_request_i;
wire                      lmmi_ready_o;
wire [7:0]                lmmi_rdata_o;
wire                      lmmi_rdata_valid_o;
// Config Regs
wire                      rxcsr_vcx_on_i;
wire                      rxcsr_dropnull_i;
wire [1:0]                rxcsr_actvln_i;
wire                      rxcsr_datawidth_i;
wire [7:0]                rxcsr_datsettlecyc_i;
wire [15:0]               rxcsr_rxfifo_pktdly_i;
// AXI4-Stream
wire                      axis_tvalid_o;
wire [AXI_DATA_WIDTH-1:0] axis_tdata_o;
wire                      axis_tready_i;
// Reset and Controls
wire                      pll_lock_i;
wire                      sync_rst_i;
wire                      reset_n_i;
wire                      reset_lp_n_i;
wire                      reset_byte_n_i;
wire                      reset_byte_fr_n_i;
wire [5:0]                ref_dt_i;
wire                      tx_rdy_i;
wire                      sp_en_o;
wire                      lp_en_o;
wire                      lp_av_en_o;
wire                      sp2_en_o;
wire                      lp2_en_o;
wire                      lp2_av_en_o;
// Clock
wire                      sync_clk_i;
wire                      clk_byte_o;
wire                      clk_byte_hs_o;
wire                      clk_lp_ctrl_i;
wire                      clk_byte_fr_i;
// Data
wire [NUM_RX_LANE*8-1:0]  bd_o;
wire                      capture_en_o;
wire [RX_GEAR-1:0]        bd0_o ;
wire [RX_GEAR-1:0]        bd1_o ;
wire [RX_GEAR-1:0]        bd2_o ;
wire [RX_GEAR-1:0]        bd3_o ;
wire                      payload_en_o;
wire [DATA_WIDTH-1:0]     payload_o;
wire [7:0]                payload_bytevld_o;
wire [15:0]               payload_crc_o;
wire                      payload_crcvld_o;
// Header
wire [5:0]                dt_o;
wire [1:0]                vc_o;
wire [1:0]                vcx_o;
wire [15:0]               wc_o;
wire [5:0]                ecc_o;
wire [5:0]                dt2_o;
wire [1:0]                vc2_o;
wire [15:0]               wc2_o;
wire [5:0]                ecc2_o;
// Status
wire                      edgemon_done_o;
wire                      ready_o;
wire                      cd_clk_o;
wire                      cd_d0_o;
wire                      hs_d_en_o;
wire                      hs_sync_o;
wire [1:0]                lp_hs_state_clk_o;
wire [1:0]                lp_hs_state_d_o;
wire                      term_clk_en_o;
wire [NUM_RX_LANE-1:0]    term_d_en_o;
wire [1:0]                dphy_rxdatawidth_hs_o;
wire [1:0]                dphy_cfg_num_lanes_o;
wire [1:0]                rxdatsyncfr_state_o;
wire                      rxemptyfr0_o;
wire                      rxemptyfr1_o;
wire                      rxfullfr0_o;
wire                      rxfullfr1_o;
wire [1:0]                rxque_curstate_o;
wire                      rxque_empty_o;
wire                      rxque_full_o;
wire                      fifo_dly_err_o;
wire                      fifo_undflw_err_o;
wire                      fifo_ovflw_err_o;
wire                      skewcal_det_o;
wire                      skewcal_done_o;
// Error Stats
wire                      ecc_check_o;
wire                      ecc_byte_error_o;
wire                      ecc_1bit_error_o;
wire                      ecc_2bit_error_o;
wire                      crc_check_o;
wire                      crc_error_o;
// Dynamic delay
wire                      data_loadn_i;
wire                      data_move_i;
wire                      data_dir_i;
wire [1:0]                data_coarsedly_i;
wire                      data_cflag_o;
// Others
wire [NUM_RX_LANE-1:0]    lp_d_rx_p_o;
wire [NUM_RX_LANE-1:0]    lp_d_rx_n_o;
wire                      lp_d0_tx_en_i;   // not supported  
wire                      lp_d0_tx_p_i;    // not supported 
wire                      lp_d0_tx_n_i;    // not supported 
// DPHY High speed p/n
wire                      clk_p_io;
wire                      clk_n_io;
wire [NUM_RX_LANE-1:0]    d_p_io;
wire [NUM_RX_LANE-1:0]    d_n_io;

// -----------------------------------------------------------------------------
// Testbench Internal
// Used to connect clk_byte_fr_i to clk_byte_hs_o
wire                      clk_byte_fr;
wire [1:0]                vcx2_o;
    
// Datachecker
wire                      valid_w;          
wire                      pars_off_en_w;     
wire                      payload_en_w;      
wire                      data_en_w;         
wire                      lock_dtct_w;       
wire [DATA_WIDTH-1:0]     byte_data_temp_w; 
wire [15:0]               wc_w;             

    
wire                      clk_p_w;
wire                      clk_n_w;
wire [3:0]                d_p_io_w;
wire [3:0]                d_n_io_w;

wire                      tb_lockchk_w;

// -----------------------------------------------------------------------------
// Assign Statements
// -----------------------------------------------------------------------------
// LMMI
assign lmmi_clk_i        = lmmi_clk_r;
assign lmmi_resetn_i     = (LMMI == "ON") ? lmmi_resetn_r  : 'h0;
assign lmmi_wdata_i      = (LMMI == "ON") ? lmmi_wdata_r   : 'h0;
assign lmmi_wr_rdn_i     = (LMMI == "ON") ? lmmi_wr_rdn_r  : 'h0;
assign lmmi_offset_i     = (LMMI == "ON") ? lmmi_offset_r  : 'h0;
assign lmmi_request_i    = (LMMI == "ON") ? lmmi_request_r : 'h0;

// AXI
assign axis_tready_i    = (AXI4 == "ON")? 1'd1 : 1'd0;

// Clock
assign sync_clk_i        = sync_clk_r;
assign clk_byte_fr_i     = (RX_CLK_MODE == "HS_ONLY")? clk_byte_fr : clock_fr_r;
assign clk_lp_ctrl_i     = lp_ctrl_clk;
assign clk_byte_fr       = (RX_CLK_MODE == "HS_ONLY")? clk_byte_hs_o : 1'd0;

// Reset
assign sync_rst_i        = sync_rst_r;
assign reset_lp_n_i      = reset_lp_w;
assign reset_byte_fr_n_i = reset_byte_fr_w;
assign reset_byte_n_i    = reset_byte_w;
assign reset_n_i         = system_resetn_w;

// High speed p/n
assign clk_p_io          = clk_p_w;
assign clk_n_io          = clk_n_w;
assign d_p_io            = d_p_io_w[NUM_RX_LANE-1:0];
assign d_n_io            = d_n_io_w[NUM_RX_LANE-1:0];

// Header
assign ref_dt_i          = VIDEO_DATA_TYPE;
  
/// Data Chacker
assign byte_data_temp_w  = (AXI4 == "ON")   ? axis_tdata_o[DATA_WIDTH-1:0] : 
                           (PARSER == "ON") ? payload_o : 
                                             {bd3_o,bd2_o,bd1_o,bd0_o};
assign wc_w              = (RX_TYPE == "DSI")? vact_payload : num_pixels;
assign valid_w           = data_en_w;
assign payload_en_w      = (AXI4 == "ON") ? ((PARSER == "ON") ? axis_tvalid_o & 
                                                         ~(sp_en_o | lp_en_o) : 
                                                                valid_data_r) :
                                             (PARSER == "ON") ? payload_en_o  : 
                                                                valid_data_r;  
assign pars_off_en_w     = (AXI4 == "ON") ? axis_tvalid_o : capture_en_o; 

assign rxcsr_vcx_on_i        = (VCX_ON == "ON");
assign rxcsr_dropnull_i      = (DROP_NULL);
assign rxcsr_actvln_i        = (NUM_RX_LANE-1);
assign rxcsr_datawidth_i     = (RX_GEAR == 16) ;  // 0-gear8, 1-gear16
assign rxcsr_datsettlecyc_i  = DATA_SETTLE_CYC;
assign rxcsr_rxfifo_pktdly_i = RX_FIFO_PKT_DLY;

assign pll_lock_i        = 1'd1;
assign tx_rdy_i          = 1;    
assign lp_d0_tx_en_i     = 1'd0;//don't supported for now
assign lp_d0_tx_p_i      = 1'd0;//don't supported for now
assign lp_d0_tx_n_i      = 1'd0;//don't supported for now

// If IMONDELAY of IP is enabled, wait for lock before enabling CRC and 
// ECC checks
assign tb_lockchk_w      = (DYN_DEL_EN == "ON") ? lock_dtct_w : 1'b1;

// -----------------------------------------------------------------------------
// Blocks
// -----------------------------------------------------------------------------
// Select if wanted to instantiate the IPX generated file
//    dut_inst.v - IPX generated file
//    eval_top_inst.v - Evaluation top-level generated file
`ifndef GATE_SIM
  `ifdef DUT_INST_NAME
    `ifdef USE_EVAL_TOP_DUT
      `define DUT_HIER_PATH tb_top.u_eval_top.`DUT_INST_NAME.lscc_dphy_rx_inst
      `include "../eval/eval_top_inst.v"
    `else
      `define DUT_HIER_PATH tb_top.`DUT_INST_NAME.lscc_dphy_rx_inst
      `include "dut_inst.v"
    `endif
    // Manual overwrite of SIM_MODE parameter for RTL Sim
    defparam `DUT_HIER_PATH.SIM_MODE = 1;
    initial begin
      $display("----------------------------");
      $display("[DEBUG] Simulation Mode : %0d",`DUT_HIER_PATH.SIM_MODE);
      $display("----------------------------");
    end
  `endif
`else
  `ifdef USE_EVAL_TOP_DUT
    `include "../eval/eval_top_inst.v"
  `else
    `include "dut_inst.v"
  `endif
`endif

// GSR Clock
initial begin
  forever begin
    #5;
    CLK_GSR = ~CLK_GSR;
  end
end

// Power-down sequence for DPHY
initial begin
  pd_dphy_i = 1;
  #700000;
  pd_dphy_i = 0;
end


generate
  // Sync reset
  if (DPHY_RX_IP != "LATTICE") begin
    initial begin
      #200000;
      sync_rst_r = 1'd0;
    end
  end


  if (PARSER == "ON") begin
    // ECC Checker
    initial begin : ecc_error_checker
      forever begin
        @(posedge clk_byte_fr_i);
        if (tb_lockchk_w && ecc_check_o && 
           (ecc_byte_error_o || ecc_1bit_error_o || ecc_2bit_error_o)) begin
          ecc_err_flag_tb = 1'b1;
          if (ecc_byte_error_o) begin
            ecc_berr_flag_tb = 1'b1;
          end
          if (ecc_1bit_error_o) begin
            ecc_1berr_flag_tb = 1'b1;
          end
          if (ecc_2bit_error_o) begin
            ecc_2berr_flag_tb = 1'b1;
          end
        end
      end
    end
    // CRC Checker
    initial begin : crc_error_checker
      forever begin
        @(posedge clk_byte_fr_i);
        if (tb_lockchk_w && crc_check_o && crc_error_o) begin
          crc_err_flag_tb = 1'b1;
        end
      end
    end
  end
endgenerate

// -----------------------------------------------------------------------------
// Clock generation 
//generate clk for clk_lp_ctrl_i  = 50MHz
always #(10000) lp_ctrl_clk = ~lp_ctrl_clk;

always #(500000/(BYTECLK_MHZ_FLOAT)) clock_fr_r  <= ~clock_fr_r;

generate
  if (RX_CLK_MODE == "HS_LP") begin
    always #(refclk_period/2)   refclk_i = ~refclk_i;
  end
  else if (RX_TYPE == "CSI2") begin
    always #(DPHY_CLK/2) cont_clk = ~cont_clk;
  end
  if (LMMI == "ON") begin
    always begin
      #(refclk_period/2) lmmi_clk_r <= ~lmmi_clk_r;
    end
  end
  if (CIL_BYPASS == "CIL_ENABLED") begin
    always #(ESC_CLK_PER) sync_clk_r <= ~ sync_clk_r;
  end
  else begin
    always #(500000/SYNCCLK_MHZ) sync_clk_r <= ~ sync_clk_r;
  end
endgenerate


generate 
  if (PARSER == "OFF") begin
    always @(posedge valid_w) begin
      @(posedge pars_off_en_w);
      if (CIL_BYPASS == "CIL_ENABLED") begin
        @(negedge clk_byte_fr_i);
      end
      else begin
        while (byte_data_temp_w[DATA_WIDTH-1:DATA_WIDTH-8] != 8'hb8) begin
          @(negedge clk_byte_fr_i);
        end
      end
      repeat(1 + 4*8/(NUM_RX_LANE*RX_GEAR)) begin
        @(posedge clk_byte_fr_i);
      end    
      valid_data_r = 1'd1;
      @(negedge pars_off_en_w);
        valid_data_r = 1'd0;
    end
  end
endgenerate

// Invoking datachacker
always begin
  @(posedge payload_en_w)
  if (DYN_DEL_EN == "ON") begin
    if (lock_dtct_w) begin
      datachack(wc_w);  
    end  
  end
  else begin
    datachack(wc_w);  
  end
end


// -----------------------------------------------------------------------------
// Module Instance
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// GSR instance required for primitive models
`ifdef LAV_AT
  GSRA GSR_INST (
      .GSR_N(USER_GSR)
  );
`else
  GSR GSR_INST (
      .GSR_N(USER_GSR),
      .CLK(CLK_GSR)
  );
`endif


tb_lmmi_model #(
  .LMMI               (LMMI              ),
  .INIT_DELAY         (INIT_DELAY        ),
  .DPHY_IP            (DPHY_RX_IP        ),
  .DPHY_RATE          (DPHY_RATE         ),
  .DPHY_GEAR          (RX_GEAR           ),
  .NUM_LANE           (NUM_RX_LANE       ),
  .CLK_MODE           (RX_CLK_MODE       ),
  .PROT_TYPE          (RX_TYPE           ),
  .CIL_BYPASS         (CIL_BYPASS        ),
  .DESKEW_EN          (DESKEW_EN         ),
  .UC_PRG_RXHS_SETTLE (T_CLK_SETTLE_INT  ),
  .U_PRG_RXHS_SETTLE  (T_DATA_SETTLE_INT ),
  .DATA_SETTLE_CYC    (DATA_SETTLE_CYC   ),
  .RX_FIFO_PKT_DLY    (RX_FIFO_PKT_DLY   ),
  .HARD_DPHY_REG      (13                ),
  .GEN_DPHY_REG       (27                ), // 0x39-0x1F+1
  .LMMI_OFFSET_WIDTH  (8                 ),
  .LMMI_DATA_WIDTH    (8                 )
) lmmi_model_inst     (
  .lmmi_clk_i         (lmmi_clk_r        ),
  .lmmi_ready_i       ((LMMI == "ON") ? lmmi_ready_o       : 'h0),
  .lmmi_rdata_valid_i ((LMMI == "ON") ? lmmi_rdata_valid_o : 'h0),
  .lmmi_rdata_i       ((LMMI == "ON") ? lmmi_rdata_o       : 'h0),
  .lmmi_offset_o      (lmmi_offset_r     ),
  .lmmi_wdata_o       (lmmi_wdata_r      ),
  .lmmi_wr_rdn_o      (lmmi_wr_rdn_r     ),
  .lmmi_request_o     (lmmi_request_r    ),
  .lmmi_resetn_o      (lmmi_resetn_r     ),
  .lmmi_cmp_fail_o    (lmmi_cmp_fail_r   )
);


generate
  if (RX_TYPE == "DSI") begin : dsi
    dsi_model #(
      .dphy_num_lane     (NUM_RX_LANE      ),
      .dphy_clk_period   (DPHY_CLK         ),
      .CLK_MODE          (RX_CLK_MODE      ),
      .DYN_DEL_EN        (DYN_DEL_EN       ),
      .DESKEW_SYNC       (DESKEW_SYNC      ),
      .DESKEW_PATT       (DESKEW_PATT      ),
      .DESKEW_DUR        (DESKEW_DUR       ),
      .DPHY_RATE         (DPHY_RATE_R      ),
      .num_frames        (num_frames       ),
      .num_lines         (num_lines        ),
      .t_lpx             (t_lpx            ),
      .t_clk_prepare     (t_clk_prepare    ),
      .t_clk_zero        (t_clk_zero       ),
      .t_clk_pre         (t_clk_pre        ),
      .t_clk_post        (t_clk_post       ),
      .t_clk_trail       (t_clk_trail      ),
      .t_hs_prepare      (t_hs_prepare     ),
      .t_hs_zero         (t_hs_zero_new    ),
      .t_hs_trail        (t_hs_trail       ),
      .t_init            (t_init           ),
      .hsa_payload       (hsa_payload      ),
      .bllp_payload      (bllp_payload     ),
      .hbp_payload       (hbp_payload      ),
      .hfp_payload       (hfp_payload      ),
      .lps_bllp_duration (lps_bllp_duration),
      .lps_hfp_duration  (lps_hfp_duration ),
      .lps_hbp_duration  (lps_hbp_duration ),
      .vact_payload      (vact_payload     ),
      .virtual_channel   (virtual_channel  ),
      .video_data_type   (VIDEO_DATA_TYPE  ),
      .vsa_lines         (vsa_lines        ),
      .vbp_lines         (vbp_lines        ),
      .vfp_lines         (vfp_lines        ),
      .eotp_enable       (eotp_enable      ),
      .frame_gap         (frame_gap        ),
      .debug_on          (debug_on         )
    )
    dsi_ch0 (
      .resetn        (system_resetn_w), //resetn
      .edgemon_done  (edgemon_done_o),
      .clk_p_i       (clk_p_w),
      .clk_n_i       (clk_n_w),
      .d_p_i         (d_p_io_w),
      .d_n_i         (d_n_io_w),
      .lock_dtct_o   (lock_dtct_w),
      .dsi_valid_o   (data_en_w)
    );

    initial begin
      $timeformat(-12,0,"",10);
      refclk_i = 0;
      cont_clk = 0;
      fork
        begin
          reset_byte;
        end
        begin
          drive_reset;
          if(DPHY_CLK%2 > 0) begin
              dphy_clk = DPHY_CLK - 1;
          end
          else begin
              dphy_clk = DPHY_CLK;
          end

          $display("%0t TEST START\n",$realtime);
          #(DPHY_CLK*12*3);

          #(INIT_DELAY); //wait initialization delay
          dsi_ch0.dphy_active = 1;
          $display("%t Activating DSI model\n", $time);
          @(negedge dsi_ch0.dphy_active);
          #10;
          $fclose(f);
          #100000;
          text_comp_t;
          #10
          if (pay_data_pass_r == 1 && ecc_err_flag_tb == 0 && crc_err_flag_tb == 0 && lmmi_cmp_fail_r == 0) begin  
            $display("**SIMULATION PASSED**");
            if (lp_sample_clkp >= 50000 || t_hs_zero_req != t_hs_zero) begin
              $display("WARNING: Please make sure that transmitter's tLPX and tHS-ZERO settings are at least %0d ps and %0d ps respectively.", t_lpx,t_hs_zero_new);  
            end
          end 
          else begin
            if (ecc_err_flag_tb) begin
              $display("***ECC ERROR DETECTED: ecc_byte_error_o=%b, ecc_1bit_error_o=%b, ecc_2bit_error_o=%b", ecc_berr_flag_tb, ecc_1berr_flag_tb, ecc_2berr_flag_tb);
            end
            if (crc_err_flag_tb) begin
              $display("***CRC ERROR DETECTED***");
            end
            if (lmmi_cmp_fail_r) begin
              $display("***LMMI DEFAULT VALUE COMPARE ERROR DETECTED***");
            end
            $display("**SIMULATION FAILED**");
          end               
        end
      join
      test_end;
      $finish;
    end
  end

  else begin : csi2
      csi2_model #(
        .active_dphy_lanes (NUM_RX_LANE),
        .RX_CLK_MODE       (RX_CLK_MODE),
        .DATA_COUNT        (DATA_COUNT),
        .DYN_DEL_EN        (DYN_DEL_EN),
        .DESKEW_SYNC       (DESKEW_SYNC),
        .DESKEW_PATT       (DESKEW_PATT),
        .DESKEW_DUR        (DESKEW_DUR),
        .DPHY_RATE         (DPHY_RATE_R),
        .num_frames        (num_frames),
        .num_lines         (num_lines),
        .num_pixels        (num_pixels),
        .data_type         (VIDEO_DATA_TYPE),
        .dphy_clk_period   (DPHY_CLK),
        .t_lpx             (t_lpx),
        .t_clk_prepare     (t_clk_prepare),
        .t_clk_zero        (t_clk_zero),
        .t_clk_pre         (t_clk_pre),
        .t_clk_post        (t_clk_post),
        .t_clk_trail       (t_clk_trail),
        .t_hs_prepare      (t_hs_prepare),
        .t_hs_zero         (t_hs_zero_new),
        .t_hs_trail        (t_hs_trail),
        .lps_gap           (lps_gap),
        .frame_gap         (frame_gap),
        .t_init            (t_init ),
        .dphy_ch           (0),
        .dphy_vc           (virtual_channel),
        .long_even_line_en (long_even_line_en),
        .ls_le_en          (ls_le_en),
        .debug             (debug_on)
      )
      u_csi2_model (
        .resetn            (system_resetn_w), //resetn
        .refclk_i          ((RX_CLK_MODE == "HS_ONLY")? cont_clk : refclk_i),
        .pll_lock          (1'd1),
        .edgemon_done      (edgemon_done_o),
        .clk_p_i           (clk_p_w),
        .clk_n_i           (clk_n_w),
        .do_p_i            (d_p_io_w),
        .do_n_i            (d_n_io_w),
        .lock_dtct_o       (lock_dtct_w),
        .csi_valid_o       (data_en_w)
      );


    initial begin
        $timeformat(-12,0,"",10);
        refclk_i = 0;
        cont_clk = 0;
        fork
          begin
            reset_byte;
          end
          begin
            drive_reset;
            if(DPHY_CLK%2 > 0) begin
                dphy_clk = DPHY_CLK - 1;
            end
            else begin
                dphy_clk = DPHY_CLK;
            end
            $display("%0t TEST START\n",$realtime);
            #(DPHY_CLK*12*3);
            #(INIT_DELAY); //wait initialization delay
            u_csi2_model.dphy_active = 1;
            $display("%t Activating CSI2 model\n", $time);
            @(negedge u_csi2_model.dphy_active);
            #10;
            $fclose(f);
            #100000;
            text_comp_t;
            #10
            if (pay_data_pass_r == 1 && ecc_err_flag_tb == 0 && crc_err_flag_tb == 0 && lmmi_cmp_fail_r == 0) begin
              $display("**SIMULATION PASSED**");
              if (lp_sample_clkp >= 50000 || t_hs_zero_req != t_hs_zero) begin
                $display("WARNING: Please make sure that transmitter's tLPX and tHS-ZERO settings are at least %0d ps and %0d ps respectively.", t_lpx,t_hs_zero_new);  
              end
            end 
            else begin
              if (ecc_err_flag_tb) begin
                $display("***ECC ERROR DETECTED: ecc_byte_error_o=%b, ecc_1bit_error_o=%b, ecc_2bit_error_o=%b", ecc_berr_flag_tb, ecc_1berr_flag_tb, ecc_2berr_flag_tb);
              end
              if (crc_err_flag_tb) begin
                $display("***CRC ERROR DETECTED***");
              end
              if (lmmi_cmp_fail_r) begin
                $display("***LMMI DEFAULT VALUE COMPARE ERROR DETECTED***");
              end
              $display("**SIMULATION FAILED**");
            end 
          end
        join
        test_end;
        $finish;
    end
  end 
endgenerate

// -----------------------------------------------------------------------------
// Task Declarations
// -----------------------------------------------------------------------------

// Global task which includes all reset tasks
task drive_reset();
  begin
     reset_lp_w       = 1;
     reset_byte_fr_w  = 0;
     // reset_byte_w     = 0;
     system_resetn_w   = 1;
     if (DPHY_RX_IP == "LATTICE") begin
      gddr_reset;
      @(posedge ready_o);
    end
    fork
      begin reset_lp;      end
      begin reset_byte_fr; end
      begin system_reset;  end
      begin if (LMMI == "ON") lmmi_model_inst.lmmi_reset;    end
    join
  end
endtask

task reset_lp();
  begin
    reset_lp_w = 0;
    @(posedge lp_ctrl_clk);
    #1;
    reset_lp_w = 1;
  end
endtask

task reset_byte_fr();
  begin
    reset_byte_fr_w = 0;
    #10;
    @(posedge clk_byte_fr_i);
    #1;
    reset_byte_fr_w = 1;
  end
endtask

// Byte clock's reset
task reset_byte();
  begin
  reset_byte_w = 0;
    #10;
    if (RX_CLK_MODE == "HS_ONLY") begin
      @(posedge clk_byte_hs_o);
    end
    else begin
      @(posedge clk_byte_fr_i);
    end
    #1;
    reset_byte_w = 1;
  end
endtask

// system reset
task system_reset();
  begin
    system_resetn_w = 0;
    #(2*refclk_period);
    system_resetn_w = 1;
  end
endtask

// task which reset lscc_gddr_sync in SOFT_RX which reset other modules
task gddr_reset();
  begin
    repeat (10) begin
      @(posedge sync_clk_r);
    end
    #1;
    sync_rst_r     = 1'd0;
  end
endtask

task apb_write (
   input [5:0] addr,
   input [7:0] data
   );
   begin
     @(posedge pclk_r);
     apb_paddr_r   <= addr;
     apb_pwrite_r  <= 1'b1;
     apb_psel_r    <= 1'b1;
     apb_penable_r <= 1'b1;
     apb_pwdata_r  <= data;
     @(posedge pclk_r);
     while (apb_pready_r == 1'b0) begin
       @(posedge pclk_r);
     end
     apb_paddr_r   <= 0; 
     apb_pwrite_r  <= 0; 
     apb_psel_r    <= 0; 
     apb_penable_r <= 0; 
     apb_pwdata_r  <= 0; 
   end
endtask

// Task which writing incoming data in text document
task datachack( 
  input            [15: 0] num_bytes
  );begin    
    first_byte_data_r  = 1;
    byte_count_r       = 0;
    while(byte_count_r < num_bytes) begin
      @(negedge clk_byte_fr_i);      
      if (num_bytes - byte_count_r < (RX_GEAR*NUM_RX_LANE)/8) begin
        case(num_bytes - byte_count_r)
          16'd1 : begin
            $fwrite(f,"%0x\n",byte_data_temp_w[ 7: 0]);
        act_data.push_front(byte_data_temp_w[7:0]);
        data_compare();
          end
          16'd2 : begin
            if (PARSER == "ON" || RX_GEAR == 8) begin
              $fwrite(f,"%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[15: 8]);              
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[15:8]);
          data_compare();
            end
            else begin
              $fwrite(f,"%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16]);              
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          data_compare();
            end
          end
          16'd3 : begin
            if (PARSER == "ON" || RX_GEAR == 8) begin
              $fwrite(f,"%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[15:8],byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[15:8]);
          act_data.push_front(byte_data_temp_w[23:16]);
          data_compare();
            end
            else begin
              if (NUM_RX_LANE == 2) begin
                $fwrite(f,"%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[15: 8]);                
            act_data.push_front(byte_data_temp_w[7:0]);
            act_data.push_front(byte_data_temp_w[23:16]);
            act_data.push_front(byte_data_temp_w[15:8]);
            data_compare();
              end
              else begin
                $fwrite(f,"%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32]);
            act_data.push_front(byte_data_temp_w[7:0]);
            act_data.push_front(byte_data_temp_w[23:16]);
            act_data.push_front(byte_data_temp_w[39:32]);
          data_compare();
              end
            end
          end
          16'd4 : begin
            if (PARSER == "ON") begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[15: 8],byte_data_temp_w[23:16],byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[15:8]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[31:24]);
          data_compare();
            end
            else begin
              if (NUM_RX_LANE == 3 ) begin
                $fwrite(f,"%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32],byte_data_temp_w[15: 8]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[15:8]);
          data_compare();
              end
              else begin
                $fwrite(f,"%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32],byte_data_temp_w[55:48]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[55:48]);
          data_compare();
              end
            end
          end
          16'd5 : begin
            if (PARSER == "ON") begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[15: 8],byte_data_temp_w[23:16],byte_data_temp_w[31:24],byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[15:8]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[39:32]);
          data_compare();
            end
            else begin
              if (NUM_RX_LANE == 3) begin
                $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32],byte_data_temp_w[15:8],byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[15:8]);
          act_data.push_front(byte_data_temp_w[31:24]);
          data_compare();
              end
              else begin
                $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32],byte_data_temp_w[55:48],byte_data_temp_w[15: 8]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[55:48]);
          act_data.push_front(byte_data_temp_w[15:8]);
          data_compare();
              end
            end
          end
          16'd6 : begin
            if (PARSER == "ON") begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[15: 8],byte_data_temp_w[23:16],byte_data_temp_w[31:24],byte_data_temp_w[39:32],byte_data_temp_w[47:40]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[15:8]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[47:40]);
          data_compare();
            end
            else begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32],byte_data_temp_w[55:48],byte_data_temp_w[15: 8],byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[55:48]);
          act_data.push_front(byte_data_temp_w[15: 8]);
          act_data.push_front(byte_data_temp_w[31:24]);
          data_compare();
            end
          end
          16'd7 : begin
            if (PARSER == "ON") begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[15: 8],byte_data_temp_w[23:16],byte_data_temp_w[31:24],byte_data_temp_w[39:32],byte_data_temp_w[47:40],byte_data_temp_w[55:48]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[15: 8]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[47:40]);
          act_data.push_front(byte_data_temp_w[55:48]);
          data_compare();
            end
            else begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[ 7: 0],byte_data_temp_w[23:16],byte_data_temp_w[39:32],byte_data_temp_w[55:48],byte_data_temp_w[15: 8],byte_data_temp_w[31:24],byte_data_temp_w[47:40]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[55:48]);
          act_data.push_front(byte_data_temp_w[15: 8]);
          act_data.push_front(byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[47:40]);
          data_compare();
            end
          end
        endcase
      end
      else begin
        if (DATA_WIDTH ==  8) begin
          $fwrite(f,"%0x\n",byte_data_temp_w[7:0]);
      act_data.push_front(byte_data_temp_w[7:0]);
      data_compare();
        end 
        else if (DATA_WIDTH == 16) begin
          $fwrite(f,"%0x\n%0x\n",byte_data_temp_w[7:0],byte_data_temp_w[15:8]);
      act_data.push_front(byte_data_temp_w[7:0]);
      act_data.push_front(byte_data_temp_w[15:8]);
      data_compare();
        end
        else if (DATA_WIDTH == 24) begin
          if (first_byte_data_r) begin
            $fwrite(f,"%0x\n%0x\n",byte_data_temp_w[15:8],byte_data_temp_w[23:16]);
      act_data.push_front(byte_data_temp_w[15:8]);
      act_data.push_front(byte_data_temp_w[23:16]);
      data_compare();
          end
          else begin
            $fwrite(f,"%0x\n%0x\n%0x\n",byte_data_temp_w[7:0],byte_data_temp_w[15:8],byte_data_temp_w[23:16]);
      act_data.push_front(byte_data_temp_w[7:0]);
      act_data.push_front(byte_data_temp_w[15:8]);
      act_data.push_front(byte_data_temp_w[23:16]);
      data_compare();
          end
        end 
        else if (DATA_WIDTH == 32) begin
          if (PARSER == "ON" || RX_GEAR == 8) begin
            $fwrite(f,"%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[7:0],byte_data_temp_w[15:8],byte_data_temp_w[23:16],byte_data_temp_w[31:24]);
      act_data.push_front(byte_data_temp_w[7:0]);
      act_data.push_front(byte_data_temp_w[15:8]);
      act_data.push_front(byte_data_temp_w[23:16]);
      act_data.push_front(byte_data_temp_w[31:24]);
      data_compare();
          end
          else begin
            $fwrite(f,"%0x\n%0x\n%0x\n%0x\n",byte_data_temp_w[7:0],byte_data_temp_w[23:16],byte_data_temp_w[15:8],byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[7:0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[15:8]);
          act_data.push_front(byte_data_temp_w[31:24]);
          data_compare();
          end
        end
        else if (DATA_WIDTH == 48) begin
            if (first_byte_data_r) begin
              $fwrite(f,"%0x\n%0x\n",                               byte_data_temp_w[31:24],
                                                                    byte_data_temp_w[47:40]);
          act_data.push_front(byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[47:40]);
          data_compare();
            end
            else begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n",           byte_data_temp_w[ 7: 0],
                                                                    byte_data_temp_w[23:16],
                                                                    byte_data_temp_w[39:32],
                                                                    byte_data_temp_w[15: 8],
                                                                    byte_data_temp_w[31:24],
                                                                    byte_data_temp_w[47:40]);

          act_data.push_front(byte_data_temp_w[ 7: 0]);
          act_data.push_front(byte_data_temp_w[23:16]);
          act_data.push_front(byte_data_temp_w[39:32]);
          act_data.push_front(byte_data_temp_w[15: 8]);
          act_data.push_front(byte_data_temp_w[31:24]);
          act_data.push_front(byte_data_temp_w[47:40]);
          data_compare();
            end
        end 
        else if (DATA_WIDTH == 64) begin
          if (PARSER == "ON") begin            
            $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n", byte_data_temp_w[ 7: 0],
                                                                  byte_data_temp_w[15: 8],
                                                                  byte_data_temp_w[23:16],
                                                                  byte_data_temp_w[31:24],
                                                                  byte_data_temp_w[39:32],
                                                                  byte_data_temp_w[47:40],
                                                                  byte_data_temp_w[55:48],
                                                                  byte_data_temp_w[63:56]);

            act_data.push_front(byte_data_temp_w[ 7: 0]);
            act_data.push_front(byte_data_temp_w[15: 8]);
            act_data.push_front(byte_data_temp_w[23:16]);
            act_data.push_front(byte_data_temp_w[31:24]);
            act_data.push_front(byte_data_temp_w[39:32]);
            act_data.push_front(byte_data_temp_w[47:40]);
            act_data.push_front(byte_data_temp_w[55:48]);
            act_data.push_front(byte_data_temp_w[63:56]);
        data_compare();
          end
          else begin
            if (first_byte_data_r) begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n",                     byte_data_temp_w[15: 8],
                                                                    byte_data_temp_w[31:24],
                                                                    byte_data_temp_w[47:40],
                                                                    byte_data_temp_w[63:56]);
              act_data.push_front(byte_data_temp_w[15: 8]);
              act_data.push_front(byte_data_temp_w[31:24]);
              act_data.push_front(byte_data_temp_w[47:40]);
              act_data.push_front(byte_data_temp_w[63:56]);
          data_compare();
            end
            else begin
              $fwrite(f,"%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n%0x\n", byte_data_temp_w[ 7: 0],
                                                                    byte_data_temp_w[23:16],
                                                                    byte_data_temp_w[39:32],
                                                                    byte_data_temp_w[55:48],
                                                                    byte_data_temp_w[15: 8],
                                                                    byte_data_temp_w[31:24],
                                                                    byte_data_temp_w[47:40],
                                                                    byte_data_temp_w[63:56]);
              act_data.push_front(byte_data_temp_w[ 7: 0]);
              act_data.push_front(byte_data_temp_w[23:16]);
              act_data.push_front(byte_data_temp_w[39:32]);
              act_data.push_front(byte_data_temp_w[55:48]);
              act_data.push_front(byte_data_temp_w[15: 8]);
              act_data.push_front(byte_data_temp_w[31:24]);
              act_data.push_front(byte_data_temp_w[47:40]);
              act_data.push_front(byte_data_temp_w[63:56]);
          data_compare();
            end            
          end
        end
      end
      if ((first_byte_data_r && DATA_WIDTH == 64 && PARSER == "OFF") || ((NUM_RX_LANE == 3) && first_byte_data_r)) begin
        byte_count_r       = byte_count_r + NUM_RX_LANE - (NUM_RX_LANE == 3);
        first_byte_data_r = 0;
      end
      else begin
        byte_count_r       = byte_count_r + (RX_GEAR*NUM_RX_LANE)/8;
      end      
    end
    $display("%0t Receiving video data DONE!",$realtime);
  end
endtask


// Task which compare two text files
task text_comp_t;
  begin  
   byte_num = (RX_TYPE == "DSI")? vact_payload : num_pixels;
   data_ctr = 0;
   line_ctr = 0;
   frame_ctr = 0;
    D_status_1       = 0;
    D_status_2       = 0;
    D_true_res       = 32'd0;
    D_false_res      = 32'd0;
    D_file_1_value   = 32'd0;
    D_file_2_value   = 32'd0;
    D_file_1         = $fopen("DRIVEN_DATA.txt","r");
    D_file_2         = $fopen("received_data.txt","r");
    pay_data_pass_r  = 1'd0;
    #1;
    $display("Start of data comparing");
    while (!$feof(D_file_1) | !$feof(D_file_2)) begin
      #1;
      D_status_1 = $fscanf(D_file_1,"%h\n",D_file_1_value);
      D_status_2 = $fscanf(D_file_2,"%h\n",D_file_2_value);
      #1;
      if (D_file_1_value == D_file_2_value) begin
//        $display("Data Valid : Frame = %0d, Line num = %0d, byte num = %0d", frame_ctr, line_ctr, data_ctr);
//        $display("Data compare : Expected = %0x vs Actual = %0x",D_file_1_value,D_file_2_value);
        D_true_res   = D_true_res + 1;
      end
      else begin
        D_false_res  = D_false_res + 1;
//        $display("Data Error : Frame = %0d, Line num = %0d, byte num = %0d", frame_ctr, line_ctr, data_ctr);
//        $display("Data compare : Expected = %0x vs Actual = %0x",D_file_1_value,D_file_2_value);
      end
      if (data_ctr < byte_num - 1) begin
         data_ctr = data_ctr + 1;
      end else
      begin
         data_ctr = 0;
     if (line_ctr < num_lines - 1) begin
            line_ctr = line_ctr + 1;
         end else
     begin
            line_ctr = 0;
        frame_ctr = frame_ctr + 1;
     end
      end
    end
    $fclose(D_file_1);
    $fclose(D_file_2);
    $display("End of data comparing");
    ///////////////////////////////////////////////////
    /// Payload Data Check
    ///////////////////////////////////////////////////
    if (D_false_res == 0 && D_true_res != 0) begin
      if (D_status_1 == 1) begin
        $display("***PAYLOAD DATA COMPARE PASS***");
        pay_data_pass_r = 1'd1;
      end
      else begin
         $display("***CURRENT CONFIGURATION NOT SUPPORTED***");
         pay_data_pass_r = 1'd0;
      end      
    end
    else begin
      $display("***PAYLOAD DATA COMPARE FAIL***");
      $display("Errors` ",D_false_res,"/",D_false_res + D_true_res);
      pay_data_pass_r = 1'd0;
    end
  end
endtask


task data_compare();
  if (RX_TYPE == "DSI") begin
     dc.data_compare();
  end else
  begin
     dc.data_compare();
  end
endtask


generate
  if (RX_TYPE == "DSI") begin : dc
    task data_compare();
       reg [7:0] exp, act;
       while (act_data.size > 0) begin
        exp = dsi.dsi_ch0.data_h.pop_back();
        act = act_data.pop_back();
        if (exp != act) begin
            $display("%t : Data Error : Exp Data = %2h | Act Data = %2h\n", $realtime, exp, act);
        end else
        begin
    if (debug_on) begin
            $display("%t : Data Match : Exp Data = %2h | Act Data = %2h\n", $realtime, exp, act);
        end
        end
       end
    endtask
  end else
  if (RX_TYPE == "CSI2") begin : dc
    task data_compare();
       reg [7:0] exp, act;
     
       while (act_data.size > 0) begin
           exp = csi2.u_csi2_model.data_h.pop_back();
         act = act_data.pop_back();
         if (exp != act) begin
            $display("%t : Data Error : Exp Data = %2h | Act Data = %2h\n", $realtime, exp, act);
         end else
    begin
    if (debug_on) begin
            $display("%t : Data Match : Exp Data = %2h | Act Data = %2h\n", $realtime, exp, act);
    end
    end
       end
    endtask
  end
endgenerate

generate
  if (RX_TYPE == "DSI")
  begin : tx_cnt
    task check_tx_data_cnt();
      if (dsi.dsi_ch0.data_h.size() > 0) begin
        $display("Error : DUT failed to transmit %0d bytes of data", dsi.dsi_ch0.data_h.size());
      end else
      begin
        $display("All data received and transmitted");
      end
    endtask
  end else
  begin : tx_cnt
    task check_tx_data_cnt();
      if (csi2.u_csi2_model.data_h.size() > 0) begin
        $display("Error : DUT failed to transmit %0d bytes of data", csi2.u_csi2_model.data_h.size());
      end else
      begin
        $display("All data received and transmitted");
      end
    endtask
  end
endgenerate

task test_end;
  begin
    if (DYN_DEL_EN == "OFF") begin
      tx_cnt.check_tx_data_cnt();
    end
    $display("Test end");
    $stop;
  end
endtask

endmodule
//==============================================================================
// tb_top.v
//==============================================================================
`endif
