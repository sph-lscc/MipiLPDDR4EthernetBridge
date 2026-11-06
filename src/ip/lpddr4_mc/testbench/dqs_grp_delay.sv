
module delay_2dir #( 
  parameter int unsigned MAX_DELAY = 0,
  parameter int unsigned MIN_DELAY = 0,
  parameter [6:0]        RAND_NUM  = 0
)
(
  input mc_enb ,
  inout mc_io  ,
  input mem_enb,
  inout mem_io
);
  localparam DIVNUM      = 4;
//  localparam DELAY_DIV   = DEL_VALUE/DIVNUM;
//  localparam RD_TS_DELAY = DEL_VALUE << 1; // 2 * DEL_VALUE
  logic            mc_enb_dly;
  logic            mem_enb_dly;
  logic [DIVNUM:0] mc2mem;
  logic [DIVNUM:0] mem2mc;
  int delay_val;
  int delay_div;
  
  initial begin
    if (MAX_DELAY == MIN_DELAY)
      delay_val = MAX_DELAY;
    else begin
	  for(int j=0; j<= RAND_NUM ; j++)
       delay_val = $urandom_range(MAX_DELAY, MIN_DELAY);
	  end
	#10;  
	delay_div = delay_val/DIVNUM;
  end 

  genvar i;
  
  always @(mc_enb)
    mc_enb_dly  = #(delay_val) mc_enb;

  always @(mem_enb)
    mem_enb_dly = #(delay_val) mem_enb;
    
  always @(*) begin
    mc2mem[0] = mc_io;
    mem2mc[0] = mem_io;
  end
  
  generate   
    for(i=1; i<=DIVNUM; i=i+1) begin : DLY
      always @(mc2mem[i-1])
        mc2mem[i] = #(delay_div) mc2mem[i-1];
            
      always @(mem2mc[i-1])
        mem2mc[i] = #(delay_div) mem2mc[i-1];
    end
  endgenerate
  
  assign mem_io = mc_enb_dly  ? mc2mem[DIVNUM] : 1'bz;
  assign mc_io  = mem_enb_dly ? mem2mc[DIVNUM] : 1'bz;
 
endmodule

module dqs_grp_delay #(
  parameter  DQS_DEL_VALUE     = 0,  // in between DQ_DMI_DEL_MIN and DQ_DMI_DEL_MAX
  parameter  DQ_DMI_OFFSET_MAX = 0,
  parameter  RAND_OFFSET       = 0
)
(
  input        mc_dqs_enb ,
  inout        mc_dqs_t   ,
  inout        mc_dqs_c   ,
  input        mc_dq_enb  , // controls both DQ and DMI
  inout [7:0]  mc_dq      ,
  inout        mc_dmi     ,
  input        mem_dqs_enb,
  inout        mem_dqs_t  ,
  inout        mem_dqs_c  ,
  input        mem_dq_enb , // controls both DQ and DMI
  inout [7:0]  mem_dq     ,
  inout        mem_dmi
);
  
localparam MAX_DELAY = DQS_DEL_VALUE + DQ_DMI_OFFSET_MAX;
localparam MIN_DELAY = DQS_DEL_VALUE > DQ_DMI_OFFSET_MAX ? (DQS_DEL_VALUE - DQ_DMI_OFFSET_MAX) : 0;

  delay_2dir #( 
    .MAX_DELAY(DQS_DEL_VALUE),
    .MIN_DELAY(DQS_DEL_VALUE)
  ) u_dqst_del (
    .mc_enb (mc_dqs_enb ),
    .mc_io  (mc_dqs_t   ),
    .mem_enb(mem_dqs_enb),
    .mem_io (mem_dqs_t  )
  );
  
  delay_2dir #( 
    .MAX_DELAY(DQS_DEL_VALUE),
    .MIN_DELAY(DQS_DEL_VALUE)
  ) u_dqsc_del (
    .mc_enb (mc_dqs_enb ),
    .mc_io  (mc_dqs_c   ),
    .mem_enb(mem_dqs_enb),
    .mem_io (mem_dqs_c  )
  );

  genvar i;
  generate
    for (i=0; i<8;i=i+1) begin : DQ_DEL
      delay_2dir #( 
        .MAX_DELAY(MAX_DELAY    ),
        .MIN_DELAY(MIN_DELAY    ),
        .RAND_NUM (RAND_OFFSET+i)
      ) 
      u_dq_del (
        .mc_enb (mc_dq_enb ),
        .mc_io  (mc_dq[i]  ),
        .mem_enb(mem_dq_enb),
        .mem_io (mem_dq[i] )
      );
    end
  endgenerate


  delay_2dir #( 
    .MAX_DELAY(MAX_DELAY    ),
    .MIN_DELAY(MIN_DELAY    ),
    .RAND_NUM (RAND_OFFSET+8)
  ) u_dmi_del (
    .mc_enb (mc_dq_enb ),
    .mc_io  (mc_dmi    ),
    .mem_enb(mem_dq_enb),
    .mem_io (mem_dmi   )
  );

endmodule