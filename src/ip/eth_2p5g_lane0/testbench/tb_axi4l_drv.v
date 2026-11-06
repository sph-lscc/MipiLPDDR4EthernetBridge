`ifndef TB_AXI4L_DRIVER_V
`define TB_AXI4L_DRIVER_V
//0---------------------------------------------------------------------------------------------------
// File Name      : tse_mac_axi4l_master.v
// Project        : TSE_MAC
// Date Created   : 20-07-2022
// Description    : This is HDL file AXI4L master
// Generator      : Test bench Compiler Version 1.1
//0---------------------------------------------------------------------------------------------------

`timescale 1ns/1ps
`include "defines.v"

module tb_axi4l_drv
#(

  //1###################################################################################################
  // Parameter Declaration
  //1###################################################################################################

  parameter OFFSET_WIDTH   = 32,
  parameter DATA_WIDTH     = 32

  //1###################################################################################################
  // Local Parameter Declaration
  //1###################################################################################################
  )
// -----------------------------------------------------------------------------
// Input/Output Ports
// -----------------------------------------------------------------------------
(
input   wire       				i_clk,
input                           rst_n_i,
output  reg                     axi_awvalid,
input   wire                    axi_awready,
output  reg [OFFSET_WIDTH-1:0]  axi_awaddr,
output  reg [2:0]               axi_awprot,	//not used
	    
output  reg                     axi_wvalid,	
input   wire                    axi_wready,
output  reg [DATA_WIDTH-1:0]    axi_wdata,
output [3:0]                    axi_wstrb,	//not used 
		                          
		                          
input   wire                    axi_bvalid,	
output  reg                     axi_bready,
input   wire [1:0]              axi_bresp,	//bresp default 2'b00 (okay)
	    
	    
output  reg                     axi_arvalid,
input   wire                    axi_arready,
output  reg [OFFSET_WIDTH-1:0]  axi_araddr,
output  reg [2:0]               axi_arprot,	//not used
	    
input   wire                    axi_rvalid,
output  reg                     axi_rready,
input   wire [DATA_WIDTH-1:0]   axi_rdata,
input   wire [1:0]              axi_rresp,   //bresp default 2'b00 (okay)
output  reg                     done


);

// -----------------------------------------------------------------------------
// Registers
// -----------------------------------------------------------------------------
reg [1:0]  trans_idle_time;
reg [31:0] addr;
reg [31:0] data;
// -----------------------------------------------------------------------------
// Assign
// -----------------------------------------------------------------------------
assign axi_wstrb = 'h0; //not supported
 
// -----------------------------------------------------------------------------
// Initial statements
// ----------------------------------------------------------------------------- 
initial begin
  axi_awvalid	= 1'b0;
  axi_arvalid	= 1'b0; 
  axi_wvalid	= 1'b0; 
  axi_rready	= 1'b0;
  axi_awaddr	= 8'b00000000 ;
  axi_araddr	= 8'b00000000 ; 
  axi_wdata		= 8'b00000000 ;
  axi_awprot	= 3'b000;
  axi_bready	= 1'b0;
  axi_arprot	= 3'b000;
  done          = 1'b0;
end

// -----------------------------------------------------------------------------
// Test sequences
// -----------------------------------------------------------------------------
initial begin

  addr = 'h0;
  data = 'h0;

  wait (rst_n_i);
  
  // AXI4-lite write access
  repeat (1) begin
    addr = 'h0;
    data = 'h3;
    `N_MSG(("************************************************"))
    `N_MSG(("AXI4-lite write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    axi4l_write (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end
  
  repeat (1) begin
    addr = 'h4;
    data = 'h0;
    `N_MSG(("************************************************"))
    `N_MSG(("AXI4-lite write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    axi4l_write (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end  
  
  repeat (1) begin
    addr = 'h8;
    data = 'h1;
    `N_MSG(("************************************************"))
    `N_MSG(("AXI4-lite write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    axi4l_write (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end 
  
  repeat (1) begin
    addr = 'h10;
    data = 'h16;
    `N_MSG(("************************************************"))
    `N_MSG(("AXI4-lite write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    axi4l_write (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end

  repeat (1) begin
    addr = 'h1c;
    data = 'h013;
    `N_MSG(("************************************************"))
    `N_MSG(("AXI4-lite write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    axi4l_write (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end

  // AXI4-lite read access
  // Note: sequence of write and read transaction should be the same 
  //       in order for the register checker to work
  repeat (1) begin
    addr = 'h0;
    trans_idle_time = $random;
    axi4l_read (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end 

  repeat (1) begin
    addr = 'h4;
    trans_idle_time = $random;
    axi4l_read (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end 

  repeat (1) begin
    addr = 'h8;
    trans_idle_time = $random;
    axi4l_read (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end   
  
  repeat (1) begin
    addr = 'h10;
    trans_idle_time = $random;
    axi4l_read (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end

  repeat (1) begin
    addr = 'h1c;
    trans_idle_time = $random;
    axi4l_read_vbr (addr, data);
    repeat(trans_idle_time) @(posedge i_clk);
  end

  done = 1;
  //$finish;
end
  //1-------------------------------------------------------------------------------------------------
  // axi4l_write :This method is used to perform write transfer 
  //1-------------------------------------------------------------------------------------------------
  //           p_paddr_32b :AXI4L register address 
  //           p_pwdata_32b :AXI4L write data 
  //1-------------------------------------------------------------------------------------------------
task axi4l_write;
    input    [OFFSET_WIDTH-1:0]       p_paddr_bv ;
    input    [DATA_WIDTH-1:0]         p_pwdata_bv;
	
	reg done;
    begin
      @(posedge i_clk);
	   
		axi_awaddr		<= p_paddr_bv ;
		axi_wdata		<= p_pwdata_bv ;
		axi_bready		<= 1'b0;
		axi_awvalid		<= 1'b1;
		axi_wvalid		<= 1'b1;
		done = 0;
	
	  while (!done) /*(axi_wready == 0)*/ begin
        @ (posedge i_clk);
		done = axi_wready;
      end     
		axi_awvalid		<= 1'b0;
		axi_wvalid		<= 1'b0; 
		axi_bready		<= 1'b1;
	while (!axi_bvalid) begin
	   @ (posedge i_clk);	
	end
	   axi_bready		<= 0;
	  repeat(2) @(posedge i_clk);
    end
  endtask


  //1-------------------------------------------------------------------------------------------------
  // axi4l_read :This method is used to perform read transfer 
  //1-------------------------------------------------------------------------------------------------
  //           p_paddr_32b :AXI4L register address 
  //1-------------------------------------------------------------------------------------------------
  task axi4l_read;
    input [DATA_WIDTH-1:0] p_paddr_bv;
    output [DATA_WIDTH-1:0]          p_prdata_bv;
    begin
     @ (posedge i_clk);

		axi_araddr		<= p_paddr_bv ; 
		axi_arvalid		<= 1'b1; 
		axi_rready		<= 1'b1;
		 p_prdata_bv     <= axi_rdata;
	 while (axi_rvalid == 0) begin
        @ (posedge i_clk);
      end
		axi_arvalid		<= 0; 
		axi_rready		<= 0; 
		 p_prdata_bv     <= axi_rdata;
    end
  endtask

  //1-------------------------------------------------------------------------------------------------
  // axi4l_read :This method is used to perform read transfer - VALID before READY handshake
  //1-------------------------------------------------------------------------------------------------
  //           p_paddr_32b :AXI4L register address 
  //1-------------------------------------------------------------------------------------------------
  task axi4l_read_vbr;
    input [DATA_WIDTH-1:0] p_paddr_bv;
    output [DATA_WIDTH-1:0] p_prdata_bv;
    begin
     @ (posedge i_clk);

		axi_araddr		<= p_paddr_bv ; 
		axi_arvalid		<= 1'b1; 
		axi_rready		<= 1'b0;
		p_prdata_bv             <= axi_rdata;
	 while (axi_rvalid == 0) begin
            @ (posedge i_clk);
         end
		axi_rready		<= 1; 
		axi_arvalid		<= 0;
        repeat(1) @(posedge i_clk);
		axi_rready		<= 0; 
		p_prdata_bv             <= axi_rdata;
    end
  endtask

endmodule
`endif


