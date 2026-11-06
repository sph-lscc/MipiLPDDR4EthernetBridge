`timescale 1ns/1ps
module tb_xgmii_mst (
  input             clk,
  output reg [7:0]  control,
  output reg [63:0] xgmii_data,
  output reg [7:0]  xgmii_ctrl,
  output reg        trans_done,            //Transaction is done
  input             trans_start
);
// -----------------------------------------------------------------------------
// Initialize signals
// -----------------------------------------------------------------------------
initial begin
  xgmii_data = 64'h07070707_07070707;
  xgmii_ctrl = 8'hFF;
  control    = 8'h00;
  trans_done = 0;
  
  @(posedge clk);
  while (trans_start != 1) begin
    @(posedge clk);
    trans_done = 0;
  end
  
  repeat(100) @(posedge clk);
  // -----------------------------------------------------------------------------
  // Update desired sequence below
  // -----------------------------------------------------------------------------
  xgmii_idle      ();
  xgmii_start_dat ();
  xgmii_dat       ();
  xgmii_end_dat   ();
  xgmii_idle      ();
  // -----------------------------------------------------------------------------

  repeat (100) @(posedge clk);
  trans_done = 1;
  //$finish;
end

integer               n;

// -----------------------------------------------------------------------------
// XGMII drivers
// -----------------------------------------------------------------------------
task xgmii_idle ();
for (  n = 1; n < 100; n = n + 1) begin
    @(posedge clk) begin
      xgmii_data = 64'h07070707_07070707;
      xgmii_ctrl = 8'hFF;  	
	  control    = 8'h80; //{tx_fifo_wr, 6'b0, tx_frcpkt}
    end
  end
endtask

task xgmii_idle_err_char ();
for (  n = 1; n < 100; n = n + 1) begin 
    @(posedge clk) begin
      xgmii_data = 64'h07070707_07078807;
      xgmii_ctrl = 8'hFF;  	
    end
  end
endtask

task xgmii_idle_err_dat ();
for (  n = 1; n < 100; n = n + 1) begin
    @(posedge clk) begin
      xgmii_data = 64'h07070707_07078807;
      xgmii_ctrl = 8'hFD;
    end
  end
endtask

task xgmii_start_dat ();

for (  n = 1; n < 2; n = n + 1) begin
    @(posedge clk) begin
      xgmii_data = 64'hD5555555_555555FB;
      xgmii_ctrl = 8'h01;
	  control    = 'h80;
    end
  end
endtask

task xgmii_dat ();

for (  n = 1; n < 65; n = n + 1) begin
    @(posedge clk) begin
      xgmii_data[31:0]  = $random;//64'hDEADBEEF_BEEFDEAD;
	  xgmii_data[63:32] = $random;
      xgmii_ctrl = 8'h00;
	  control    = 'h80;
    end
  end
endtask

task xgmii_end_dat ();

for (  n = 1; n < 2; n = n + 1) begin
    @(posedge clk) begin
      xgmii_data = 64'h07070707_070707FD;
      xgmii_ctrl = 8'hE0;
	  control    = 'h80;
    end
  end
endtask

endmodule
