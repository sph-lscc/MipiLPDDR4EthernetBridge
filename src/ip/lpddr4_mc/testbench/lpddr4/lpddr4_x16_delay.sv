module lpddr4_x16_delay #(
  parameter  DQS_DEL_VALUE     = 0,
  parameter  DQ_DMI_OFFSET_MAX = 0,
  parameter  DQS_SKEW          = 0,
  parameter  READ_LATENCY      = 0,
  parameter  WRITE_LATENCY     = 0,
  parameter  RAND_OFFSET       = 0
) (
  input        mc_reset_n ,
  input        mc_ck_t    ,
  input        mc_cke     ,
  input        mc_cs      ,
  input [5:0]  mc_ca      , 

  inout [1:0]  mc_dqs_t   ,
  inout [1:0]  mc_dqs_c   ,
  inout [15:0] mc_dq      ,
  inout [1:0]  mc_dmi     ,
  inout [1:0]  mem_dqs_t  ,
  inout [1:0]  mem_dqs_c  ,
  inout [15:0] mem_dq     ,
  inout [1:0]  mem_dmi
);

localparam CNT_WRITE_START = WRITE_LATENCY - 4;
localparam CNT_WRITE_END   = CNT_WRITE_START + 13;

localparam CNT_READ_START = READ_LATENCY - 4;
localparam BL16_LEN       = 13;  // 8 data, 2 preamble, 1 postamble, 2 extra
localparam CNT_READ_END   = READ_LATENCY + BL16_LEN;

//  decode commands and assert these signals

logic in_cbt   ;   // assert when MR13.CBT is written 1, de-assert when MR13.CBT is written 0
logic in_wrlvl ;   // assert when MR2.WR_LEV is written 1, de-assert when MR2.WR_LEV is written 0
logic rd_access;   // Pulse for 1 DDR clock when the command is: Write -1, Mask Write -1, MPC.WR FIFO:
logic wr_access;   // Pulse for 1 DDR clock when the command is: Read -1, MPC.RD DQ Calibration, MPC.RD FIFO

logic wr_ongoing; // will assert based on wr_access and wr_latency for a period of 13 cycles
logic rd_ongoing; // // will assert based on rd_access and rd_latency for a period of 13 cycles


// use the above signals to drive these enables, based on latency 
// start driving 2 DDR clocks earlier than latency and at least 1 ddr clock cycles later
logic [1:0] mc_dqs_enb ; // If 1: MC is driving DQS
logic [1:0] mc_dq_enb  ; // If 1: MC is driving DQ/DM
logic [1:0] mem_dqs_enb; // If 1: Mem is driving DQS
logic [1:0] mem_dq_enb ; // If 1: Mem is driving DQ/DM

// If in_cbt, refer to 4.28.1 Step 2: After time tMRD, CKE may be set LOW...
// If in_wrlvl, refer to 4.30.1 Write Leveling Procedure
// If rd_access, drive mem_dqs_enb and mem_dq_enb to 1 before and after actual read
// If wr_access, drive mc_dqs_enb and mc_dq_enb to 1 before and after actual read


logic       in_cbt_ast  ;
logic       in_cbt_deast;
//logic int_clk;
logic       in_wrlvl_ast  ;
logic       in_wrlvl_deast;
logic       sig_wr_access;
logic       sig_rd_access;
logic [5:0] wr_count;
logic [5:0] rd_count;
logic [5:0] mc_ca_r;
logic       mc_cs_r;
logic       mrw_op_7_r;
logic       mrw_op_6_r;
logic [5:0] mrw_ma_r;


typedef enum logic[3:0] {IDLE,MRW_1,MRW_MA,MRW_2,MRW_OP,WR_1,MWR_1,RD_1,MPC_1,MPC_2,CAS_1,CAS_2H,CAS_2L} state;
state ns_mrw, cs_mrw, cs_wr, ns_wr, cs_rd, ns_rd;

always_ff @(posedge mc_ck_t or negedge mc_reset_n) begin
  if(!mc_reset_n) begin
    mc_ca_r   <= 6'h00;
    mc_cs_r   <= 1'b0;
  end
  else if (mc_cke) begin
    mc_ca_r   <= mc_ca;
    mc_cs_r   <= mc_cs;
  end
 end // always_ff

logic is_mrw_1;
logic is_mrw_2;

// MRW: Next state logic
always_comb begin

  ns_mrw       = IDLE;
  is_mrw_1     = (mc_cs_r==1) && (mc_ca_r[4:0] == 'b00110);
  is_mrw_2     = (mc_cs_r==1) && (mc_ca_r[4:0] == 'b10110);
  case(cs_mrw)
    IDLE  : ns_mrw = is_mrw_1 ? MRW_1  : IDLE;
    MRW_1 : ns_mrw = !mc_cs_r ? MRW_MA : IDLE;
    MRW_MA: ns_mrw = is_mrw_2 ? MRW_2  : IDLE;
    MRW_2 : ns_mrw = MRW_OP;
    MRW_OP: ns_mrw = IDLE;
  endcase
end

// MRW: State Register and outputs
always_ff @(posedge mc_ck_t or negedge mc_reset_n) begin
  if(!mc_reset_n) begin
    cs_mrw         <= IDLE;
    mrw_ma_r       <= 0;
    mrw_op_7_r     <= 0;
    mrw_op_6_r     <= 0;
    in_cbt_ast     <= 0;
    in_cbt_deast   <= 0;
    in_cbt         <= 0;
    in_wrlvl_ast   <= 0;
    in_wrlvl_deast <= 0;
    in_wrlvl       <= 0;
  end
  else begin
    cs_mrw         <= ns_mrw;  // State register
    if (ns_mrw == MRW_MA)
      mrw_ma_r   <= mc_ca_r;
    else if (cs_mrw == IDLE)
      mrw_ma_r   <= 6'h00;

    if (ns_mrw == MRW_1)
      mrw_op_7_r <= mc_ca_r[5];
    if (ns_mrw == MRW_2)
      mrw_op_6_r <= mc_ca_r[5];

    in_cbt_ast     <= 0;
    in_cbt_deast   <= 0;
    in_wrlvl_ast   <= 0;
    in_wrlvl_deast <= 0;
    if (ns_mrw == MRW_OP) begin
      if (mrw_ma_r == 6'hD) begin // MR13
        if (mc_ca_r[0])
          in_cbt_ast   <= 1;
        else
          in_cbt_deast <= 1;
      end
      if (mrw_ma_r == 6'h2) begin // MR2
        if (mrw_op_7_r)
          in_wrlvl_ast   <= 1;
        else
          in_wrlvl_deast <= 1;
      end
    end

    // CBT
    if (in_cbt_ast)        // assert condition
      in_cbt   <= 1;
    else if (in_cbt_deast) // de-assert condition
      in_cbt   <= 0;

    // Write Leveling
    if (in_wrlvl_ast)        // assert condition
      in_wrlvl <= 1;
    else if (in_wrlvl_deast) // de-assert condition
      in_wrlvl <= 0;

  end
end // always_ff

logic is_mpc_wr_fifo;
logic is_cas2_wr;
// WR: Next state logic
always_comb begin
  is_mpc_wr_fifo = (mc_cs_r==0) && (mc_ca_r[5:0]=='h7);
  is_cas2_wr     = (mc_cs_r==1) && (mc_ca_r[4:0]=='h12);
  ns_wr          = IDLE;
  case(cs_wr)
    IDLE : begin
      case({mc_cs_r,mc_ca_r[5:0]})
        'b1000100 : ns_wr = WR_1;
        'b1001100 : ns_wr = MWR_1;
        'b1100000 : ns_wr = MPC_1;
        default   : ns_wr = IDLE;
      endcase
    end
    WR_1   : ns_wr = CAS_1;
    MWR_1  : ns_wr = CAS_1;
    MPC_1  : ns_wr = is_mpc_wr_fifo ? CAS_1 : IDLE;
    CAS_1  : ns_wr = is_cas2_wr ? CAS_2H : IDLE;
    CAS_2H : ns_wr = CAS_2L;
    CAS_2L : ns_wr = IDLE;
  endcase
  sig_wr_access  = (cs_wr==CAS_2H);

end
logic [WRITE_LATENCY:0] wr_dly;
localparam WR_SEL = WRITE_LATENCY-6;

// WR: State Register and outputs
always_ff @(posedge mc_ck_t or negedge mc_reset_n) begin
  if(!mc_reset_n) begin
    cs_wr      <= IDLE;
    wr_access  <= 0;
    wr_count   <= 6'h3F;
    wr_dly     <= {(WRITE_LATENCY+1){1'b0}};
  end
  else begin
    cs_wr      <= ns_wr;  // State register
    // WR_Access
    wr_access  <= sig_wr_access;
    if (wr_access)
      wr_count    <=0;
    else if (wr_count <= CNT_WRITE_END)
      wr_count   <= wr_count + 1;

    if (wr_count < BL16_LEN)
      wr_dly <= {wr_dly[WRITE_LATENCY-1:0], 1'b1};
    else
      wr_dly <= {wr_dly[WRITE_LATENCY-1:0], 1'b0};
  end
end // always_ff

assign wr_ongoing = wr_dly[WR_SEL];

logic is_mpc_rd_fifo;
logic is_mpc_rd_dq;
logic is_cas2_rd;
always_comb begin
 
  ns_rd = IDLE;
  is_mpc_rd_fifo = (mc_cs_r==0) && (mc_ca_r[5:0]=='h1);
  is_mpc_rd_dq   = (mc_cs_r==0) && (mc_ca_r[5:0]=='h3);
  is_cas2_rd     = (mc_cs_r==1) && (mc_ca_r[4:0]=='h12);
  case(cs_rd)
    IDLE : begin
      case({mc_cs_r,mc_ca_r[5:0]})
        'b1100000 : ns_rd = MPC_1;
        'b1000010 : ns_rd = RD_1;
        default   : ns_rd = IDLE;
      endcase
    end
    RD_1   : ns_rd = CAS_1;
    MPC_1  : begin 
               if(is_mpc_rd_fifo)
                 ns_rd = CAS_1;
               else if(is_mpc_rd_dq)
                 ns_rd = CAS_1;
               else
                 ns_rd = IDLE;
             end         
    CAS_1  : ns_rd = is_cas2_rd ? CAS_2H : IDLE;
    CAS_2H : ns_rd = CAS_2L;
    CAS_2L : ns_rd = IDLE;
  endcase
  sig_rd_access  = (cs_rd==CAS_2H);
 end 


logic [READ_LATENCY:0] rd_dly;
localparam RD_SEL = READ_LATENCY-5;

// State Outputs
always_ff @(posedge mc_ck_t or negedge mc_reset_n) begin
  if(!mc_reset_n) begin
    cs_rd        <= IDLE;
    rd_access    <= 0;
    rd_count     <= 6'h3F;
    rd_dly       <= {(READ_LATENCY+1){1'b0}};
  end
  else begin
    cs_rd        <= ns_rd;  // State Register

    // Read access
    rd_access    <= sig_rd_access;
    if (rd_access)
      rd_count   <= 0;
    else if (rd_count <= CNT_READ_END)
      rd_count   <= rd_count + 1;

    if (rd_count < BL16_LEN)
      rd_dly <= {rd_dly[READ_LATENCY-1:0], 1'b1};
    else
      rd_dly <= {rd_dly[READ_LATENCY-1:0], 1'b0};
  end

end //always_ff

assign rd_ongoing = rd_dly[RD_SEL];

always_ff @(posedge mc_ck_t or negedge mc_reset_n) begin
  if(!mc_reset_n) begin //reset
    mc_dqs_enb    <= 0;
    mc_dq_enb     <= 0;
    mem_dqs_enb   <= 0;
    mem_dq_enb    <= 0;
  end
  else begin //logic
    if (in_cbt) begin
      mc_dqs_enb  <= 2'b01; // MC drives VREF on lower byte
      mc_dq_enb   <= 2'b01;
      mem_dqs_enb <= 2'b10; // MEM drives CA feedback on upper byte
      mem_dq_enb  <= 2'b10;
    end
    else if(in_wrlvl) begin
      mc_dqs_enb  <= 3; // MC drives DQS
      mc_dq_enb   <= 0;
      mem_dqs_enb <= 0;
      mem_dq_enb  <= 3; // MEM drives DQ with WrLvl feedback
    end
    else if(wr_ongoing) begin
      mc_dqs_enb  <= 3; // MC drives during write
      mc_dq_enb   <= 3;
      mem_dqs_enb <= 0;
      mem_dq_enb  <= 0;
    end
    else if(rd_ongoing) begin
      mc_dqs_enb  <= 0;
      mc_dq_enb   <= 0;
      mem_dqs_enb <= 3; // MEM drives during read
      mem_dq_enb  <= 3;
    end
    else begin
      mc_dqs_enb  <= 3; // WDQS control mode 1
      mc_dq_enb   <= 0;
      mem_dqs_enb <= 0;
      mem_dq_enb  <= 0;
    end
  end
end // always_ff


// Instantiate 2x for lower byte and upper byte

dqs_grp_delay #(
  .DQS_DEL_VALUE    (DQS_DEL_VALUE    ), // in between DQ_DMI_DEL_MIN and DQ_DMI_DEL_MAX
  .DQ_DMI_OFFSET_MAX(DQ_DMI_OFFSET_MAX),
  .RAND_OFFSET      (RAND_OFFSET      )
) 
u_lbyte (
  .mc_dqs_enb (mc_dqs_enb[0] ),
  .mc_dqs_t   (mc_dqs_t[0]   ),
  .mc_dqs_c   (mc_dqs_c[0]   ),
  .mc_dq_enb  (mc_dq_enb[0]  ), // controls both DQ and DMI
  .mc_dq      (mc_dq[7:0]    ),
  .mc_dmi     (mc_dmi[0]     ),
  .mem_dqs_enb(mem_dqs_enb[0]),
  .mem_dqs_t  (mem_dqs_t[0]  ),
  .mem_dqs_c  (mem_dqs_c[0]  ),
  .mem_dq_enb (mem_dq_enb[0] ), // controls both DQ and DMI
  .mem_dq     (mem_dq[7:0]   ),
  .mem_dmi    (mem_dmi[0]    )
);

dqs_grp_delay #(
  .DQS_DEL_VALUE    (DQS_DEL_VALUE+DQS_SKEW),  // in between DQ_DMI_DEL_MIN and DQ_DMI_DEL_MAX
  .DQ_DMI_OFFSET_MAX(DQ_DMI_OFFSET_MAX     ),
  .RAND_OFFSET      (RAND_OFFSET+8         )
) 
u_hbyte (
  .mc_dqs_enb (mc_dqs_enb[1] ),
  .mc_dqs_t   (mc_dqs_t[1]   ),
  .mc_dqs_c   (mc_dqs_c[1]   ),
  .mc_dq_enb  (mc_dq_enb[1]  ), // controls both DQ and DMI
  .mc_dq      (mc_dq[15:8]   ),
  .mc_dmi     (mc_dmi[1]     ),
  .mem_dqs_enb(mem_dqs_enb[1]),
  .mem_dqs_t  (mem_dqs_t[1]  ),
  .mem_dqs_c  (mem_dqs_c[1]  ),
  .mem_dq_enb (mem_dq_enb[1] ), // controls both DQ and DMI
  .mem_dq     (mem_dq[15:8]  ),
  .mem_dmi    (mem_dmi[1]    )
);

endmodule
