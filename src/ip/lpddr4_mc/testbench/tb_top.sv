// =============================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// -----------------------------------------------------------------------------
//   Copyright (c) 2019 by Lattice Semiconductor Corporation
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
// Title                 :
// Dependencies          :
// Description           : Simple test for MC_Avant
// =============================================================================
//                        REVISION HISTORY
// Version               : 1.0.0.
// Author(s)             :
// Mod. Date             : 11.07.2019
// Changes Made          : Initial release.
// =============================================================================
`define LPDDR4

// Uncomment this define to speed-up simulation in RTL (not Post-Synthesis/P&R)
//`define RTL_SIM
//`define C_DEBUG_EN
//`define DELAY_MODEL
`ifdef LPDDR4
  `include "lpddr4/z19m_2gx16_4266_20210604_ms.svp"
`endif

`timescale 1 ps / 1 ps
`ifdef C_DEBUG_EN
`include "debug_c_code.sv"
`endif
`include "delay_1dir.sv"
`include "dqs_grp_delay.sv"
`include "lpddr4/lpddr4_x16_delay.sv"


module tb_top ();
`include "dut_params.v"

localparam PLL_REFCLK_PERIOD      = 1000000/CLKI_FREQ;
localparam PLL_REFCLK_HALFPERIOD  = PLL_REFCLK_PERIOD/2;
localparam ACLK_PERIOD            = 1000000/150;
localparam ACLK_HALFPERIOD        = ACLK_PERIOD/2;
localparam TB_TIMEOUT             = 300000 * 6;

localparam BL256 = (MAX_BURST_LEN < 256) ? 1'b0 : 1'b1;
localparam BL128 = (MAX_BURST_LEN < 128) ? 1'b0 : 1'b1;

//logic                  clk_i       ;
logic                  rstn_i      ;
logic                  pll_refclk_i;
logic                  uart_rxd_i  ;
logic                  uart_txd_o  ;
wire  [11:0]           LED         ;
logic                  irq_out     ;
logic                  sim_o       ;
logic                  init_done_o ;
// LPDDR4 Interface
//logic [CK_WIDTH-1:0]         ddr_ck_t_o   ;
//logic [CK_WIDTH-1:0]         ddr_ck_c_o   ;
logic [CK_WIDTH-1:0]         ddr_ck_o     ;
logic [CS_WIDTH-1:0]         ddr_cke_o    ;
logic [CS_WIDTH-1:0]         ddr_cs_o     ;
logic [CA_WIDTH-1:0]         ddr_ca_o     ;
//logic [BA_WIDTH-1:0]         ddr_ba_o     ;
//logic [BG_WIDTH-1:0]         ddr_bg_o     ;
logic                        ddr_ras_n_o  ;
logic                        ddr_cas_n_o  ;
logic                        ddr_we_n_o   ;
logic                        ddr_act_n_o  ;
logic [ODT_WIDTH-1:0]        ddr_odt_o    ;
logic                        ddr_reset_n_o;
wire  [BUS_WIDTH-1:0]        ddr_dq_io    ;
wire  [DQS_WIDTH-1:0]        ddr_dqs_io   ;
wire  [DQS_WIDTH-1:0]        ddr_dqs_c    ;
wire  [DQS_WIDTH-1:0]        ddr_dmi_io   ;

initial begin
    pll_refclk_i   = 1;
    forever pll_refclk_i = #(PLL_REFCLK_HALFPERIOD) ~pll_refclk_i;
end

//initial begin
//    clk_i   = 1;
//    forever clk_i = #(ACLK_HALFPERIOD) ~clk_i;
//end


initial begin
  rstn_i    = 1;
  #(PLL_REFCLK_HALFPERIOD*2);
  rstn_i    = 0;
  #(PLL_REFCLK_HALFPERIOD*40);
  rstn_i     = 1;

  @(posedge init_done_o);
  $display("INIT_DONE asserted!");
end

assign uart_rxd_i = 1'b1;

assign ddr_dqs_c  = ~ddr_dqs_io;


reg [100*8-1:0] gpio_msg;
reg [100 : 0]   gpio_array [1:0];
int x ;
//reg [6:0]       idx_msg;

initial begin
//  idx_msg  = 0;
x = 0;
  gpio_msg = {(100*8){1'b0}};
end

always @(LED[8]) begin : print_messages
  #1;  // add some delay before capturing signals
  if (LED[9]) begin // GPIO sends string message
//    gpio_msg[idx_msg*8+:8] = LED[7:0];
//    idx_msg = idx_msg + 1;
    gpio_msg = {gpio_msg[99*8-1:0], LED[7:0]};  // Push the message to match the order in C-Code
    if (LED[7:0] == 0) begin                    // NULL character is received
      if (gpio_msg[15:8] != 8'h00)  begin           // gpio_msg has content
        //$display("%0d [TB_TOP]: %0s", $time, gpio_msg);
        gpio_array[x] = gpio_msg;
        if(x == 0)
          $display("%0d [TB_TOP] Bus efficiency : %0s", $time, gpio_array[x]);
        else if(x == 1)
          $display("%0d [TB_TOP] Mbps: %0s", $time, gpio_array[x]);
        x++;
      end

      #1;
//      idx_msg  = 0;
      gpio_msg = {(100*8){1'b0}};
    end
  end
end

`ifdef RTL_SIM
eval_top #(
  .SIM(1)
)
u_eval_top(
`else
eval_top u_eval_top(
`endif
//  .clk_i         (clk_i        ),
  .rstn_i        (rstn_i       ),
  .pll_refclk_i  (pll_refclk_i ),
  .uart_rxd_i    (uart_rxd_i   ),
  .uart_txd_o    (uart_txd_o   ),
  .LED           (LED          ),
 // .irq_out       (irq_out      ),
  .sim_o         (sim_o        ),
  .init_done_o   (init_done_o  ),
//  .ddr_ck_t_o    (ddr_ck_t_o   ),
//  .ddr_ck_c_o    (ddr_ck_c_o   ),
  .ddr_ck_o      (ddr_ck_o     ),
  .ddr_cke_o     (ddr_cke_o    ),
  .ddr_cs_o      (ddr_cs_o     ),
  .ddr_ca_o      (ddr_ca_o     ),
  //.ddr_odt_ca_o  (ddr_odt_ca_o ),
  .ddr_reset_n_o (ddr_reset_n_o),
  .ddr_dq_io     (ddr_dq_io    ),
  .ddr_dqs_io    (ddr_dqs_io   ),
  .ddr_dmi_io    (ddr_dmi_io   )
);
/////////////////////////////////////////////////////////////////////
logic done_rd,done_pulse,done_wr,done_wr_pulse;
logic led_r,led_r1,led_rd,led_rd_1;
logic flag_test_done,flag_test_done_r;
logic stream_valid_r, stream_valid_r1,stream_valid_r2;
int i = 1;
logic pwr_pulse;
logic t_done;
logic t_done_r;
logic t_done_r1;
logic done_pulse_r;
logic [31:0] duration_cnt;
logic [31:0] num_wr_rd ;
logic [31:0] led_bytes_concat;
logic [31:0] num_pass,num_fail;
int j,wc;
assign done_wr = LED[3] & LED[2] & !LED[9]; //&& !LED[7];
assign done_rd = LED[3] & !LED[2] & !LED[9];
assign flag_test_done = LED[6] && !LED[9]  ;

always_ff @(posedge pll_refclk_i or negedge rstn_i) begin
  if(!rstn_i) begin
    led_r                 <= 0;
    led_rd                <= 0;
    led_r1                <= 0;
    led_rd_1              <= 0;
    flag_test_done_r      <= 0;
    t_done_r              <= 0;
    t_done_r1             <= 0;
    num_pass              <= 0;
    num_fail              <= 0;

  end
  else begin
    led_r1               <= led_r;
    led_r                <= done_wr;
    led_rd_1             <= led_rd;
    led_rd               <= done_rd;
    flag_test_done_r     <= flag_test_done;
    t_done_r             <= t_done;
    t_done_r1            <= t_done_r;
    num_pass             <= (LED[9] == 0 & done_pulse & LED[4] == 0 & LED[2] == 0 & init_done_o ) ? num_pass + 1 : num_pass ;
    num_fail             <= (LED[9] == 0 & done_pulse & LED[4] == 1 & LED[2] == 0 & init_done_o ) ? num_fail + 1 : num_fail ;
  end
end

assign done_pulse = (led_r & ~led_r1 | led_rd & ~led_rd_1) ;
assign done_wr_pulse = (led_r & ~led_r1);
assign t_done     = flag_test_done & ~flag_test_done_r;
initial begin // {
 `ifdef DELAY_MODEL
    //force `DUT_HIER_PATH.lscc_lpddr4_mc_inst.u_ctrl_wrap.u_controller.u_trn_eng.i_csr.trn_operation_reg = 'h1E;
  `endif
`ifdef RTL_SIM
  // Uncomment this if you want to test the training in RTL simulation
  force `DUT_HIER_PATH.lscc_lpddr4_mc_inst.u_ctrl_wrap.u_controller.u_trn_eng.i_csr.trn_operation_reg = 'h1E;
`endif
  @(posedge pll_refclk_i);
  if (sim_o == 1'b0) begin
    $error("\n\n%0d [TB_TOP] Simulation with eval_top.SIM=0 is not supported due to extremely long simulation time.", $time);
    $display("[TB_TOP] RTL simulation, please uncomment this line in tb_top: `define RTL_SIM");
    $display("[TB_TOP] For post-Synthesis and post-P&R simulations, please set eval_top.SIM=1");
    $display("SIMULATION FAILED");
    $finish;
  end

  @(posedge init_done_o);
  $display("%0d [TB_TOP] Initialization and Training Done",$time);

  repeat (100) @(posedge pll_refclk_i);
//  num_pass = 0;
//  num_fail = 0;
  j = 0;
  wc = 0;
  $display("Waiting for the posedge of the ddr_dqs_t");
  @(posedge ddr_dqs_io[0]);
  $display("Found the dqs toggle");
  while(i > 0) begin  // {
    @(posedge pll_refclk_i);
    if(LED[9] == 0) begin // {
      if(t_done_r1) begin // {
         i = 0;
         $display("END_OF_SIMULATION");
         break;
      end // }
      else begin // {
        if(done_pulse) begin // {
             if((LED[2] & !LED[9] ) == 1) begin // {
               $display("%0d [TB_TOP] Run : %0d ",$time,j);
               burst_type(done_wr_pulse,j);
               j = j + 1;
               $display("%0d [TB_TOP] Write Done",$time);
             end // }
             else  begin // {
               if((LED[4] & !LED[9]) == 0) begin  // {
                 $display("%0d [TB_TOP] Read Done : Data Compare Pass",$time);
                 //num_pass = num_pass + 1;
                 continue;
               end // }
               else begin // {
                 $error("%0d [TB_TOP] Read Done : Data Compare Fail", $time);
                 //num_fail = num_fail + 1;
                 $display(" %0d [TB_TOP] Test number :  %0d" , $time,num_fail);
                 continue;
               end  // }
             end // }
        end // }
      end // }
      i = 1;
    end // }
  end  // }
   @(posedge pll_refclk_i);
   @(posedge pll_refclk_i);
   $display("Out side the loop");
   $display("//////////////////////////SUMMARY/////////////////////");
   if(num_fail!=0) begin
     $display("FAILED_RUNS : %d",num_fail);
     $error("SIMULATION FAILED");
   end
   else begin
     $display("PASSED_RUNS : %d",num_pass);
     $display("SIMULATION PASSED");
   end
   $display("//////////////////////////////////////////////////////");
   $finish;
end // }

task burst_type(input int done_wr_pulse, input int wc);
  if(done_wr_pulse) begin
    if (BL256) begin
     if(wc == 0)  $display("%0d [TB_TOP] Single INCR2", $time);
     else if(wc == 1)  $display("%0d [TB_TOP] INCR2 " , $time);
     else if(wc == 2)  $display("%0d [TB_TOP] INCR4 " , $time);
     else if(wc == 3)  $display("%0d [TB_TOP] INCR8 " , $time);
     else if(wc == 4)  $display("%0d [TB_TOP] INCR8 with Delay" , $time);
     else if(wc == 5)  $display("%0d [TB_TOP] INCR64",$time);
      else if(wc == 6)  $display("%0d [TB_TOP] INCR128",$time);
      else if(wc == 7)  $display("%0d [TB_TOP] INCR256",$time);
      else if(wc == 8)  $display("%0d [TB_TOP] RAND2",$time);
      else if(wc == 9)  $display("%0d [TB_TOP] PERFORMANCE TEST WITH INCR64",$time);
    end
    else begin
      if (BL128) begin
        if(wc == 0)  $display("%0d [TB_TOP] Single INCR2", $time);
        else if(wc == 1)  $display("%0d [TB_TOP] INCR2 " , $time);
        else if(wc == 2)  $display("%0d [TB_TOP] INCR4 " , $time);
        else if(wc == 3)  $display("%0d [TB_TOP] INCR8 " , $time);
        else if(wc == 4)  $display("%0d [TB_TOP] INCR8 with Delay" , $time);
        else if(wc == 5)  $display("%0d [TB_TOP] INCR64",$time);
        else if(wc == 6)  $display("%0d [TB_TOP] INCR128",$time);
        else if(wc == 7)  $display("%0d [TB_TOP] RAND2",$time);
        else if(wc == 8)  $display("%0d [TB_TOP] PERFORMANCE TEST WITH INCR64",$time);
      end
      else begin
        if(wc == 0)  $display("%0d [TB_TOP] Single INCR2", $time);
        else if(wc == 1)  $display("%0d [TB_TOP] INCR2 " , $time);
        else if(wc == 2)  $display("%0d [TB_TOP] INCR4 " , $time);
        else if(wc == 3)  $display("%0d [TB_TOP] INCR8 " , $time);
        else if(wc == 4)  $display("%0d [TB_TOP] INCR8 with Delay" , $time);
        else if(wc == 5)  $display("%0d [TB_TOP] INCR64",$time);
        else if(wc == 6)  $display("%0d [TB_TOP] RAND2",$time);
        else if(wc == 7)  $display("%0d [TB_TOP] PERFORMANCE TEST WITH INCR64",$time);
      end
    end
  end
endtask

// This instance is only for single rank
`ifdef LPDDR4
  `include "lpddr4/lpddr4_memory_instance.vh"
//  `include "lpddr4/lpddr4_memory_instance_rk1.vh"
`endif

///////////////////// GSR /////////////////////
reg gsr_clk;
initial begin
  gsr_clk = 0;
  forever gsr_clk = #2500 ~gsr_clk; // 200MHz
end

GSR GSR_INST (.GSR_N(1'b1), .CLK(gsr_clk));
///////////////////// END OF GSR ////////////


initial begin
   repeat (TB_TIMEOUT) @(posedge pll_refclk_i);
   $display ("============TestBench INFO: SIMULATION TIMEOUT=============");
   $stop;
end
`ifdef RTL_SIM
  // For C-Code debugging
  `ifdef C_DEBUG_EN
  // FIXME: For C-Code debugging only
  // Will be removed prior to release
  localparam   ASSERT_ADDR = 32'h8800;
  localparam   GOOD_CODE   = 32'h600DF00D;

  logic [31:0] cpu_ahbl_m1_haddr    ;
  logic [1:0]  cpu_ahbl_m1_htrans   ;
  logic [31:0] cpu_ahbl_m1_hwdata   ;
  logic        cpu_ahbl_m1_hreadyout;
  logic        PCLK   ;
  logic        PRESETn;

  generate
    if (CPU_GRP_EN == 1) begin : CPU_EN
      assign cpu_ahbl_m1_haddr     = `DUT_HIER_PATH.lscc_lpddr4_mc_inst.u_controller.u_trn_eng.CPU_EN.i_cpu_grp.i_cpu_AHBL_M1_DATA_interconnect_HADDR_interconnect;
      assign cpu_ahbl_m1_htrans    = `DUT_HIER_PATH.lscc_lpddr4_mc_inst.u_controller.u_trn_eng.CPU_EN.i_cpu_grp.i_cpu_AHBL_M1_DATA_interconnect_HTRANS_interconnect;
      assign cpu_ahbl_m1_hwdata    = `DUT_HIER_PATH.lscc_lpddr4_mc_inst.u_controller.u_trn_eng.CPU_EN.i_cpu_grp.i_cpu_AHBL_M1_DATA_interconnect_HWDATA_interconnect;
      assign cpu_ahbl_m1_hreadyout = `DUT_HIER_PATH.lscc_lpddr4_mc_inst.u_controller.u_trn_eng.CPU_EN.i_cpu_grp.i_cpu_AHBL_M1_DATA_interconnect_HREADYOUT_interconnect;
      assign PCLK                  = u_eval_top.pclk_i;
      assign PRESETn               = u_eval_top.prst_n ;

  debug_c_code #(
    .DDR_TYPE     (DDR_TYPE   ),
    .ASSERT_ADDR  (ASSERT_ADDR),
    .GOOD_CODE    (GOOD_CODE  )
  )
  i_dbg_c(
    .clk_i        (PCLK                 ),
    .reset_n_i    (PRESETn              ),
    .cpu_haddr    (cpu_ahbl_m1_haddr    ),
    .cpu_htrans   (cpu_ahbl_m1_htrans   ),
    .cpu_hwdata   (cpu_ahbl_m1_hwdata   ),
    .cpu_hreadyout(cpu_ahbl_m1_hreadyout)
  );

    end else begin : CPU_DIS
      // Not yet set for this mode
    end

  endgenerate

  `endif
`endif
/*
typedef enum logic[2:0] {IDLE,P1,P2,P3,P4} state;
state cs,ns;

int count = 0;
logic end_of_c_code;
int timer = 0;
int TIME_COUNT = 15000;
logic cbt_pass=1'b1,cpu_hang = 1'b0;
parameter CBT_ERR = 'h10;
//parameter INV_CBT_ERR;


initial begin
    //INV_CBT_ERR = ~CBT_ERR;
    $display("INV_CBT_ERR = %0h",~CBT_ERR);
    repeat (100) @(posedge pll_refclk_i)
    wait(ddr_reset_n_o); // DDR reset de-assert
    $display("Waiting for RST to deassert");
    wait(ddr_cke_o);      // CKE assert
    $display("Waiting for CKE to assert");
    if (FORCE_TRN_ERR[1] == 1) begin    // Force error in CBT
      // Wait for the target CBT Rank
      cke_count = 1 + FORCE_TRN_ERR[5];
      repeat(cke_count) begin
        @(negedge ddr_cke_o);
      end
      // Force CBT Error
      force ddr_dq_io = 0;
      $display("DQ is forced to 0 in Rank %d", FORCE_TRN_ERR[5]);
      $display("LED[7:0] before = %0h",LED[7:0]);
      // Detect CBT Error
      @(posedge pll_refclk_i);
      while(!trn_err_o) begin
        @(posedge pll_refclk_i); // clk edge
        timer= timer + 1;
        if(LED[4] == 0) begin
          cbt_pass = LED[4] ;
          break;
        end
        else if(timer == TIME_COUNT) begin
          cpu_hang = 1;
          break;
        end
      end
      // Messages
      if (trn_err_o) begin
        if (!cbt_pass)
          $display("CBT error detected in Rank %d", FORCE_TRN_ERR[5]);
        else
          $error("Unexpected Error detected!");
      end
      else if(cpu_hang == 1) begin
        if(cbt_pass !=0)
          $fatal(0,"CPU Hangs when Error is inserted in Rank %d", FORCE_TRN_ERR[5]);
      end
      else begin
        $error("Error : CBT error should be asserted but it isn't asserted as yet - Rank 0");
        $finish;
      end
      repeat (10) @(posedge pll_refclk_i); // wait for some time after error
      release ddr_dq_io;
      $display("DQ is released back in RANK %d", FORCE_TRN_ERR[5]);
    end // FORCE_TRN_ERR[1] CBT error
    if (FORCE_TRN_ERR[2] == 1) begin    // Force error inWRLVL
      // use in_wrlvl in LPDDR4
      /tb_top/LP4MEM/RANK[0]/INST[0]/u_x16_delay/in_wrlvl
      /tb_top/LP4MEM/RANK[1]/INST[0]/u_x16_delay/in_wrlvl
      // Force on 1st assertion
    end
    if (FORCE_TRN_ERR[3] == 1) begin    // Force error in Read Training
      // wait for read
      /tb_top/LP4MEM/RANK[0]/INST[0]/u_x16_delay/rd_access
      /tb_top/LP4MEM/RANK[1]/INST[0]/u_x16_delay/rd_access
      // Force on 1st assertion
    end
    if (FORCE_TRN_ERR[4] == 1) begin    // Force error in Write Training
      // wait for rd_access
      /tb_top/LP4MEM/RANK[0]/INST[0]/u_x16_delay/wr_access
      /tb_top/LP4MEM/RANK[1]/INST[0]/u_x16_delay/wr_access
      // Force on 1st assertion
    end
    wait(end_of_c_code=='d1);
    #100ns;
    $finish;
end
*/


    /*else if(FORCE_TRN_ERR[5] == 1) begin
        //repeat(2) begin
        @(negedge ddr_cke_o);
           count = count+1;        //count the number CKE -- it tells which CBT is for what rank
        //end
           if(count==2) begin
             force ddr_dq_io=0;       // to trigger CBT error
             $display("DQ is forced to 0 in Rank 1");
             $display("LED[7:0] before = %0h",LED[7:0]);
             //wait(LED[7:0] == 'hEF) begin
             // $display("LED[7:0] after = %0h",LED[7:0]);
             @(posedge pll_refclk_i);
                while(1) begin
                  $display("Inside while loop");
                  @(posedge pll_refclk_i); // clk edge
                    timer= timer+1;
                    if(LED[4] == 0) begin
                      cbt_pass = LED[4] ;
                      break;
                    end
                    else if(timer == TIME_COUNT) begin
                      cpu_hang = 1;
                      break;
                    end
                end
           end
           if(cpu_hang == 1) begin
             if(cbt_pass !=0)
                error("CPU_HANG interrupt isn't detected" ); //$error
           end
           if(cpu_hang==0) begin
            if(cbt_pass == 0)
                $display("CBT error detected in Rank 1");
            else begin
                $error("Error : CBT error should be asserted but it isn't asserted as yet");
                $finish;
            end
           end
           #200ns;
           release ddr_dq_io;          // when CBT error is detected + few cycles
           $display("DQ is released back in Rank 1");
       end
    end
      wait(end_of_c_code=='d1);
      #100ns;
      $finish;
end */
    /*if (FORCE_TRN_ERR[1] == 1) begin   // CBT
      if(FORCE_TRN_ERR[5] == 0) begin // RANK0
       @(negedge ddr_cke_o);
          count = count+1; //count the number CKE -- it tells which CBT is for what rank
          if(count==1) begin
            force ddr_dq_io=0;        // to trigger CBT error
            $display("DQ is forced to 0 in RANK0");
            while((LED[7:0] & ~CBT_ERR != ~CBT_ERR)) begin
              @(posedge pll_refclk_i); // clk edge
                timer= timer+1;
                if(timer == TIME_COUNT) begin
                  cpu_hang = 1;
                  break;
                end
            end
            cbt_err = LED[4] ;
            if(cpu_hang == 1) begin
              if(cbt_err !=0)
                $display("CPU_HANG interrupt isn't detected" ); //$error
              else if(cbt_err == 0)
                $display("Interrupt detected");
              else
                $display("Error : Interrupt should be asserted but it isn't asserted as yet");
                $finish;
            end
            release ddr_dq_io;          // when CBT error is detected + few cycles
            $display("DQ is released back in RANK0");
          end
      end
    end
    /*else if (FORCE_TRN_ERR[1] == 1 && FORCE_TRN_ERR[5] == 1) begin                // RANK1
       @(negedge ddr_cke_o);
          count = count+1; //count the number CKE -- it tells which CBT is for what rank
          if(count==2) begin
            force ddr_dq_io=0;        // to trigger CBT error
            $display("DQ is forced to 0 in RANK1");
            while((LED[7:4] & ~CBT_ERR != ~CBT_ERR)) begin
              @(posedge pll_refclk_i); // clk edge
                timer= timer+1;
                if(timer == TIME_COUNT) begin
                  cpu_hang = 1;
                  break;
                end
            end
            cbt_err = LED[4] ;
            if(cpu_hang == 1) begin
              if(cbt_err !=0)
                $display("CPU_HANG interrupt isn't detected"); //$error
              else if(cbt_err == 0)
                $display("Interrupt detected");
              else
                $display("Error : Interrupt should be asserted but it isn't asserted as yet");
                $finish;
            end
            release ddr_dq_io;          // when CBT error is detected + few cycles
            $display("DQ is released back in RANK0");
          end
      //end
    end
    wait(end_of_c_code=='d1);
       #100ns;
       $finish;
end*/
/**
always_ff @(posedge pll_refclk_i) begin
    if(!ddr_reset_n_o)
      cs <= IDLE;
    else
      cs <= ns;
end

always @(LED[7:0]) begin : detect_end
   ns=IDLE;
   end_of_c_code=0;
   case(cs)
      IDLE : ns = (LED[7:0] == 8'hFF) ? P1 : IDLE;
      P1   : ns = (LED[7:0] == 8'h00) ? P2 : IDLE;
      P2   : ns = (LED[7:0] == 8'hAA) ? P3 : IDLE;
      P3   : begin if(LED[7:0] == 8'h55)  begin
              end_of_c_code = 'd1;
              ns = IDLE;
             end
             else
              ns = IDLE;
             end

    endcase
end
**/

endmodule

    /*if (FORCE_TRN_ERR[2] == 1)  begin // WrLvl
       @(negedge ddr_cke_o);
          count = count+1;
       if(count==1) begin
          force ddr_dq_io=0;          // to trigger Wrlvl error
          $display("DQ is forced to 0");
          wait(LED[7:0]=='hEF) begin
            #700ns;
            release ddr_dq_io;          // when Wrlvl error is detected + few cycles
            $display("DQ is released back");
          end
       end
    end

    if (FORCE_TRN_ERR[3] == 1)  begin // Read Training
       @(negedge ddr_cke_o);
          count = count+1;
          force ddr_dq_io=0;          // to trigger Read Training error
          $display("DQ is forced to 0");
          wait(LED[7:0]=='hEF) begin
            #700ns;
            release ddr_dq_io;          // when Read Training error is detected + few cycles
            $display("DQ is released back");
          end
       end
    end

    if (FORCE_TRN_ERR[4] == 1) begin   // Write Training
       @(negedge ddr_cke_o);
          count = count+1;
       if(count==1) begin
          force ddr_dq_io=0;          // to trigger Write training error
          $display("DQ is forced to 0");
          wait(LED[7:0]=='hEF) begin
            #700ns;
            release ddr_dq_io;          // when Write Training error is detected + few cycles
            $display("DQ is released back");
          end
       end
    end


/*always @(LED[7:0]) begin : detect_end
   end_of_c_code=0
   case
      8'hFF:
      8'h00:
      8'hAA:
      8'h55: begin
         end_of_c_code=1
      end
   endcase
end*/







