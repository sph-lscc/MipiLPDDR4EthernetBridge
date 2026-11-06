//==========================================================================
// Module : tb_axis_mst - AXI4-Stream Master
//==========================================================================
`include "defines.v"
module tb_axis_mst #
// -----------------------------------------------------------------------------
// Module Parameters
// -----------------------------------------------------------------------------
(
parameter                         IN_DATA_WIDTH    = 64,  // 8/16/32/64/128/256/512/1024
parameter                         OUT_DATA_WIDTH   = 64,  // 8/16/32/64/128/256/512/1024
parameter                         ID_WIDTH         = 8,   // recommened max is 8 (TID)
parameter                         DEST_WIDTH       = 4,   // recommended max is 4 (TDEST)
parameter                         CNT_WIDTH        = 12,
parameter                         ADDR_WIDTH       = DEST_WIDTH + ID_WIDTH, // {TDEST, TID}
parameter                         USER_WIDTH       = 4    // integer multiple of data width
)
// -----------------------------------------------------------------------------
// Input/Output Ports
// -----------------------------------------------------------------------------
(
input                             axis_aclk_i,
input                             axis_arstn_i,

input                             axis_tready_i,

output reg                        axis_tvalid_o,
output reg                        axis_tlast_o,
output reg [ID_WIDTH-1:0]         axis_tid_o,
output reg [ADDR_WIDTH-1:0]       axis_tdest_o,
output reg [IN_DATA_WIDTH-1:0]    axis_tdata_o,
output reg [IN_DATA_WIDTH/8-1:0]  axis_tstrb_o,
output reg [IN_DATA_WIDTH/8-1:0]  axis_tkeep_o,
output reg                        axis_tuser_o,
input                             sys_ready_i,    //Subsystem is ready for transaction
output reg                        done            //Transaction is done
);

// -----------------------------------------------------------------------------
// Local Parameters
// -----------------------------------------------------------------------------
localparam                        BYTES_PER_BURST = (IN_DATA_WIDTH / 8);

// -----------------------------------------------------------------------------
// Register Declarations
// -----------------------------------------------------------------------------
reg [3:0] 		                  idle_cyc;
reg [11:0] 		                  trans_idx;
reg [CNT_WIDTH-1:0] 	          run_cnt;
reg [3:0] 		                  num_trans;
// -----------------------------------------------------------------------------
// Initial Block
// -----------------------------------------------------------------------------
initial begin

  done          = 0;
  run_cnt       = 0; 
  axis_tvalid_o = 0;
  axis_tlast_o  = 0; 
  axis_tid_o    = 0;
  axis_tdest_o  = 0;
  axis_tdata_o  = 64'hdeadbeef_aaaaffff;
  axis_tstrb_o  = 0;
  axis_tkeep_o  = 8'hff;
  axis_tuser_o  = 0;

  trans_idx = 0;
  idle_cyc  = 0;
  //num_trans = $random;
    num_trans = 2;
  wait(sys_ready_i); //Wait for sys_ready_i
  `N_MSG(          ("+-----------------------------------------------"))
  `N_MSG(          ("Driving %d AXI4-Stream TX random transactions   ",num_trans))
  `N_MSG(          ("+-----------------------------------------------"))   
  repeat(10) @(posedge axis_aclk_i);
 
  repeat(num_trans) begin
    idle_cyc  = $random;
    trans_idx = trans_idx + 1;
    axis_trans(1);
    repeat(idle_cyc) @(posedge axis_aclk_i);
  end
  
  //repeat(1) begin
  //  idle_cyc  = $random;
  //  trans_idx = trans_idx + 1;
  //  axis_trans(1);
  //  repeat(idle_cyc) @(posedge axis_aclk_i);
  //end
  
  repeat(1) @(posedge axis_aclk_i);
  done = 1;
  //$finish;
end

// -----------------------------------------------------------------------------
// Task Definitions
// -----------------------------------------------------------------------------
task axis_trans 
(
  input                rd0_wr1
);
  reg [CNT_WIDTH-1:0]  tmp;
  reg [CNT_WIDTH-1:0]  cnt;
  
  begin
    tmp = $urandom + 64;//$random; //100
    cnt = ((tmp % 8) == 0) ? tmp : tmp - (tmp % 8);
    `N_MSG(          ("+-----------------------------------------------"))
    `N_MSG(          ("Driving %d bytes in AXI4-stream TX interface",cnt))
    `N_MSG(          ("+-----------------------------------------------"))   
    task_write(cnt);
	
  end

endtask

// -----------
// LMMI Write
// -----------
task task_write
(
  input [CNT_WIDTH-1:0]  cnt
);

  reg [ADDR_WIDTH-1:0] 	 addr;
  reg [3:0] 		     idle_cyc;
  
  begin
    addr     = $random;  
    idle_cyc = 0;	
    run_cnt  = cnt;
	
    @(posedge axis_aclk_i);      
      if (axis_tready_i) begin
        axis_tvalid_o       <= 1;
        axis_tlast_o        <= 0; 
        axis_tid_o          <= addr[ID_WIDTH-1:0];
        axis_tdest_o        <= 0;
        axis_tdata_o[31:0]  <= $random;
	    axis_tdata_o[63:32] <= $random;
        axis_tstrb_o        <= 0;
        axis_tkeep_o        <= 8'b11111111;
        axis_tuser_o        <= 0;

        @(posedge axis_aclk_i);
      end 
	  
      axis_tlast_o  <= 1'b0;
	  
      while (run_cnt != 0) begin
        axis_tvalid_o       <= 1'b1;
	    
        if (axis_tready_i) begin
          axis_tvalid_o <= 1'b1;
        end
	    
        if (axis_tready_i && axis_tvalid_o) begin	
          run_cnt             <= run_cnt - BYTES_PER_BURST;
          axis_tdata_o[31:0]  <= $random;
	      axis_tdata_o[63:32] <= $random;
	    axis_tkeep_o        <= 8'b11111111;
  
        end
	    
      @(posedge axis_aclk_i);
        axis_tvalid_o <= 1'b1;   
      end // while (run_cnt != 0)
	  
	  @(posedge axis_aclk_i);
      axis_tvalid_o <= 1'b1;  
      axis_tlast_o  <= 1'b1;
      axis_tkeep_o  <= 8'b00001111;	
	  axis_tdata_o[31:0]  <= $random;
	  axis_tdata_o[63:32] <='h0;  
	  @(posedge axis_aclk_i);
      axis_tlast_o  <= 1'b0;
	  axis_tvalid_o <= 1'b0;
  end
  
endtask

endmodule

