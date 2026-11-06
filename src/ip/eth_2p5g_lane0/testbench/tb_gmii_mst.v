`timescale 1ns/1ps
module tb_gmii_mst (
  input             clk,
  output reg [7:0]  control,
  output reg [15:0] gmii_data,
  output reg [1:0]  gmii_en,
  output reg        trans_done,            //Transaction is done
  input             trans_start
);
// -----------------------------------------------------------------------------
// Initialize signals
// -----------------------------------------------------------------------------
initial begin
  gmii_data = 16'h0000;
  gmii_en = 2'b00;
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
  gmii_idle      ();
  gmii_start1_dat ();
  gmii_start2_dat ();
  gmii_dat       ();
  gmii_idle      ();
  // -----------------------------------------------------------------------------

  repeat (100) @(posedge clk);
  trans_done = 1;
end

integer               n;

// -----------------------------------------------------------------------------
// gmii drivers
// -----------------------------------------------------------------------------
task gmii_idle ();
for (  n = 1; n < 100; n = n + 1) begin
    @(posedge clk) begin
      gmii_data = 16'h0000;
      gmii_en = 2'b00;  	
	  control    = 8'h80; //{tx_fifo_wr, 6'b0, tx_frcpkt}
    end
  end
endtask

task gmii_idle_err_char ();
for (  n = 1; n < 100; n = n + 1) begin 
    @(posedge clk) begin
      gmii_data = 16'h8807;
      gmii_en = 2'b00;  	
    end
  end
endtask

task gmii_idle_err_dat ();
for (  n = 1; n < 100; n = n + 1) begin
    @(posedge clk) begin
      gmii_data = 16'h8807;
      gmii_en = 2'b00;
    end
  end
endtask

task gmii_start1_dat ();

for (  n = 1; n < 4; n = n + 1) begin
    @(posedge clk) begin
      gmii_data = 16'h5555;
      gmii_en = 2'b11;
	  control    = 8'h80;
    end
  end
endtask

task gmii_start2_dat ();

for (  n = 1; n < 2; n = n + 1) begin
    @(posedge clk) begin
      gmii_data = 16'hD555;
      gmii_en = 2'b11;
	  control    = 8'h80;
    end
  end
endtask

task gmii_dat ();

for (  n = 1; n < 64; n = n + 1) begin
    @(posedge clk) begin
      gmii_data[7:0]  = $random;//64'hDEADBEEF_BEEFDEAD;
	  gmii_data[15:8] = $random;
      gmii_en = 2'b11;
	  control    = 8'h80;
    end
  end
endtask

endmodule
