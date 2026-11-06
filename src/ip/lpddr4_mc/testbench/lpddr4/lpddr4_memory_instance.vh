// This instance is only for single rank

localparam INST_NUM      = DDR_WIDTH/16;
  // RANK0 is the terminating rank, it has longer delay
  localparam int RANK0_DLY      = (SIM_VAL[1]==1'b0) ? 0 : 400 ;
  localparam int RANK0_CS_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 400 ;
  localparam int RANK0_CA_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 300 ;
  localparam int RANK0_DQ_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 0   ;
  localparam int RANK0_DM_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 0   ;
  localparam int RANK0_DQS_DLY  = (SIM_VAL[1]==1'b0) ? 0 : 200 ;
  localparam int RANK0_DQ_OFST  = (SIM_VAL[1]==1'b0) ? 0 : 100 ;
  localparam int RANK0_DQS_SKEW = (SIM_VAL[1]==1'b0) ? 0 : 20  ;
  localparam int RANK1_DLY      = (SIM_VAL[1]==1'b0) ? 0 : 200 ;  // 150ps
  localparam int RANK1_CS_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 200 ;
  localparam int RANK1_CA_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 200 ;
  localparam int RANK1_DQ_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 0   ;
  localparam int RANK1_DM_DLY   = (SIM_VAL[1]==1'b0) ? 0 : 0   ;
  localparam int RANK1_DQS_DLY  = (SIM_VAL[1]==1'b0) ? 0 : 100 ;
  localparam int RANK1_DQ_OFST  = (SIM_VAL[1]==1'b0) ? 0 : 100 ;
  localparam int RANK1_DQS_SKEW = (SIM_VAL[1]==1'b0) ? 0 : 25  ;


localparam int DQS_DELAY[2]  = {RANK1_DQS_DLY, RANK0_DQS_DLY};
localparam int DQ_OFFSET[2]  = {RANK1_DQ_OFST, RANK0_DQ_OFST};
localparam int DQS_SKEW[2]   = {RANK1_DQS_SKEW, RANK0_DQS_SKEW};


genvar cs_i, inst_i;

logic [1:0]                dly_ck_t ;
logic [1:0]                dly_ck_c ;
logic [1:0]                dly_cke  ;
logic [1:0]                dly_cs   ;
logic [1:0][CA_WIDTH-1:0]  dly_ca   ;
wire  [1:0][DQS_WIDTH-1:0] dly_dqs_io;
wire  [1:0][DQS_WIDTH-1:0] dly_dqs_c ;
wire  [1:0][BUS_WIDTH-1:0] dly_dq_io ;
wire  [1:0][DQS_WIDTH-1:0] dly_dmi_io;

//logic [1:0][DQS_WIDTH-1:0] dqs_out_enb ;
//logic [1:0][BUS_WIDTH-1:0] dq_out_enb  ; 
//logic [1:0][DQS_WIDTH-1:0] dm_out_enb  ;


//assign ddr_odt_o[0] = 1;  // Terminating rank

generate 
  // LPDDR4 Memory Instances
  if (DDR_TYPE == 1) begin : LP4MEM
    // Move here for cleaner hierarchy
    delay_1dir #(.DELAY_VAL(RANK0_DLY),    .BIT_WIDTH(1)) d_ckt0 (.ddr_i(ddr_ck_o[0]), .ddr_o(dly_ck_t[0]));
    delay_1dir #(.DELAY_VAL(RANK0_DLY),    .BIT_WIDTH(1)) d_ckc0 (.ddr_i(~ddr_ck_o[0]), .ddr_o(dly_ck_c[0]));
    delay_1dir #(.DELAY_VAL(RANK0_DLY),    .BIT_WIDTH(1)) d_cke0 (.ddr_i(ddr_cke_o[0]), .ddr_o(dly_cke[0]));
    delay_1dir #(.DELAY_VAL(RANK0_CS_DLY), .BIT_WIDTH(1)) d_cs0 (.ddr_i(ddr_cs_o[0]), .ddr_o(dly_cs[0]));
    delay_1dir #(.DELAY_VAL(RANK0_CA_DLY), .BIT_WIDTH(6)) d_ca0 (.ddr_i(ddr_ca_o), .ddr_o(dly_ca[0]));
  
    if (CK_WIDTH == 1) begin : CK1
      delay_1dir #(.DELAY_VAL(RANK1_DLY), .BIT_WIDTH(1)) d_ckt1 (.ddr_i(ddr_ck_o[0]), .ddr_o(dly_ck_t[1]));
      delay_1dir #(.DELAY_VAL(RANK1_DLY), .BIT_WIDTH(1)) d_ckc1 (.ddr_i(~ddr_ck_o[0]), .ddr_o(dly_ck_c[1]));
    end
    else begin : CK2
      delay_1dir #(.DELAY_VAL(RANK1_DLY), .BIT_WIDTH(1)) d_ckt1 (.ddr_i(ddr_ck_o[1]), .ddr_o(dly_ck_t[1]));
      delay_1dir #(.DELAY_VAL(RANK1_DLY), .BIT_WIDTH(1)) d_ckc1 (.ddr_i(~ddr_ck_o[1]), .ddr_o(dly_ck_c[1]));
    end
    if (CS_WIDTH == 2) begin : RANK1
      delay_1dir #(.DELAY_VAL(RANK1_DLY),    .BIT_WIDTH(1)) d_cke1 (.ddr_i(ddr_cke_o[1]), .ddr_o(dly_cke[1]));
      delay_1dir #(.DELAY_VAL(RANK1_CS_DLY), .BIT_WIDTH(1)) d_cs1 (.ddr_i(ddr_cs_o[1]), .ddr_o(dly_cs[1]));
      delay_1dir #(.DELAY_VAL(RANK1_CA_DLY), .BIT_WIDTH(6)) d_ca1 (.ddr_i(ddr_ca_o), .ddr_o(dly_ca[1]));
      assign ddr_odt_o[1] = 0; // Non-terminating rank
    end
    for(cs_i=0; cs_i<CS_WIDTH; cs_i++) begin : RANK
      for(inst_i=0; inst_i<INST_NUM; inst_i++) begin : INST
        // FIXME: Instantiate lpddr4_x16_delay here
        lpddr4_x16_delay #(
          .DQS_DEL_VALUE    (DQS_DELAY[cs_i]),
          .DQ_DMI_OFFSET_MAX(DQ_OFFSET[cs_i]),
          .DQS_SKEW         (DQS_SKEW[cs_i] ),
          .READ_LATENCY     (READ_LATENCY   ),
          .WRITE_LATENCY    (WRITE_LATENCY  ),
          .RAND_OFFSET      ((cs_i*INST_NUM) + (inst_i*16))) 
        u_x16_delay (  // lpddr_x16_delay_dut
          .mc_reset_n(ddr_reset_n_o ),
          .mc_ck_t   (dly_ck_t[cs_i]),
          .mc_cke    (dly_cke[cs_i] ),
          .mc_cs     (dly_cs[cs_i]  ),
          .mc_ca     (dly_ca[cs_i]  ),
          .mc_dqs_t  (ddr_dqs_io[inst_i*2+:2] ),
          .mc_dqs_c  (ddr_dqs_c[inst_i*2+:2]  ),
          .mc_dq     (ddr_dq_io[inst_i*16+:16]),
          .mc_dmi    (ddr_dmi_io[inst_i*2+:2] ),
          .mem_dqs_t (dly_dqs_io[cs_i][inst_i*2+:2] ),
          .mem_dqs_c (dly_dqs_c[cs_i][inst_i*2+:2]  ),
          .mem_dq    (dly_dq_io[cs_i][inst_i*16+:16]),
          .mem_dmi   (dly_dmi_io[cs_i][inst_i*2+:2] )
        );

        lpddr4_16 mem_x16 (
          .CK_t   (dly_ck_t[cs_i]  ),
          .CK_c   (dly_ck_c[cs_i]  ),
          .CKE    (dly_cke[cs_i]   ),
          .CS     (dly_cs[cs_i]    ),
          .CA     (dly_ca[cs_i]    ),
          .ODT_CA (ddr_odt_o[cs_i] ),
          // FIXME: Need to add DQS/DQ/DM Rank delay
          .DQ     (dly_dq_io[cs_i][inst_i*16+:16]),
          .DQS_t  (dly_dqs_io[cs_i][inst_i*2+:2] ),
          .DQS_c  (dly_dqs_c[cs_i][inst_i*2+:2]  ),
          .DMI    (dly_dmi_io[cs_i][inst_i*2+:2] ),
          .RESET_n(ddr_reset_n_o   ),
          .ZQ     (                ) // not connected
        );
//        assign dqs_out_enb[cs_i][inst_i*2+:2]  = mem_x16.ins_1ch.dqs_out_enb;
//        assign dq_out_enb[cs_i][inst_i*16+:16] = mem_x16.ins_1ch.dq_out_enb;
//        assign dm_out_enb[cs_i][inst_i*2+:2]   = mem_x16.ins_1ch.dm_out_enb;
      end // INST
    end // RANK
  end  // LP4MEM
  
endgenerate
