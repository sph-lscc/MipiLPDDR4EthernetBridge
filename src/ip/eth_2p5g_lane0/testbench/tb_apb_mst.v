//==========================================================================
// Module : tb_apb_mst - APB Master
//==========================================================================
`include "defines.v"
module tb_apb_mst #(

    parameter PMI_FAMILY = "LFCPNX"
)
( //--begin_ports--
//--------------------------------------------------------------------------
// Inputs
//--------------------------------------------------------------------------
  input       [31:0]            apb_prdata,
  input                         apb_pready,
  input                         apb_pslverr,
//--------------------------------------------------------------------------
// Outputs
//--------------------------------------------------------------------------
  input                         apb_pclk,
  input                         apb_preset_n,
  output reg  [31:0]            apb_paddr,
  output reg                    apb_penable,
  output reg                    apb_psel,
  output reg  [31:0]            apb_pwdata,
  output reg                    apb_pwrite,
  output reg                    done
); //--end_ports--
//--------------------------------------------------------------------------
//--- Combinational Wire/Reg ---
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
//--- Registers ---
//--------------------------------------------------------------------------
reg [1:0]  trans_idle_time;
reg        trans_type;
reg [31:0] addr;
reg [31:0] data;
  
initial begin
  apb_paddr   = 0;
  apb_penable = 0;
  apb_psel    = 0;
  apb_pwdata  = 0;
  apb_pwrite  = 0;
  
  addr        = 'h100;
  data        = 0;
end

initial begin
    /*if (PMI_FAMILY == "LFCPNX") begin
    repeat(30) @(posedge apb_pclk);

    repeat(1) begin
    addr = 'h00; //TX IPG
    trans_idle_time = $random;
    trans_type      = 0;
    m_write_16(addr, 'd00);
    repeat(trans_idle_time) @(posedge apb_pclk);

  end
  
  repeat(50) @(posedge apb_pclk);
  done = 1;
    end
  else begin
  */

  done = 0;
  wait (apb_preset_n);
  
  repeat(5) @(posedge apb_pclk);
  
  repeat(1) begin
    addr = 'h00;
	data = 'h3;
    `N_MSG(("************************************************"))
    `N_MSG(("APB write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    trans_type      = 0;
    m_write(addr, data); // enable RX and TX MAC
    repeat(trans_idle_time) @(posedge apb_pclk);
  end
  
  repeat(2) @(posedge apb_pclk);

  repeat(1) begin
    addr = 'h04; // TX control
    data = 'h00;
    `N_MSG(("************************************************"))
    `N_MSG(("APB write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    trans_type      = 0;
    m_write(addr, data); 
    repeat(trans_idle_time) @(posedge apb_pclk);
  end  

  repeat(1) begin
    addr = 'h08; //RX control
    data = 'h1;
    `N_MSG(("************************************************"))
    `N_MSG(("APB write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    trans_type      = 0;
    m_write(addr, data); //prms=1
    repeat(trans_idle_time) @(posedge apb_pclk);
  end

  repeat(1) begin
    addr = 'h10; //TX IPG
    data = 'h16;
    `N_MSG(("************************************************"))
    `N_MSG(("APB write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    trans_type      = 0;
    m_write(addr, data); //extend IPG
    repeat(trans_idle_time) @(posedge apb_pclk);
  end

 /* repeat(1) begin
    addr = 'h4000; //TSU debug write
    data = 'hA;
    `N_MSG(("************************************************"))
    `N_MSG(("TSU APB write access: address = %0h, data = %0h",addr,data))
    `N_MSG(("************************************************"))
    trans_idle_time = $random;
    trans_type      = 0;
    m_write(addr, data); 
    repeat(trans_idle_time) @(posedge apb_pclk);
  end
*/
  
  //READ
  
  repeat(1) begin
    addr = 'h00;
    trans_idle_time = $random;
    trans_type      = 0;
    m_read(addr); // enable RX and TX MAC
    repeat(trans_idle_time) @(posedge apb_pclk);
  end
  
  repeat(2) @(posedge apb_pclk);

  repeat(1) begin
    addr = 'h04; // TX control
    trans_idle_time = $random;
    trans_type      = 0;
    m_read(addr); 
    repeat(trans_idle_time) @(posedge apb_pclk);
  end  

  repeat(1) begin
    addr = 'h08; //RX control
    trans_idle_time = $random;
    trans_type      = 0;
    m_read(addr); //prms=1
    repeat(trans_idle_time) @(posedge apb_pclk);
  end

  repeat(1) begin
    addr = 'h10; //TX IPG
    trans_idle_time = $random;
    trans_type      = 0;
    m_read(addr); //extend IPG
    repeat(trans_idle_time) @(posedge apb_pclk);
  end 

 /*repeat(1) begin
    addr = 'h4000; //TSU DEBUG
    trans_idle_time = $random;
    trans_type      = 0;
    m_read(addr); 
    repeat(trans_idle_time) @(posedge apb_pclk);
  end
*/
  repeat(5) @(posedge apb_pclk);
  done = 1;
 //$finish;
end
//end

task m_write
(
  input  [31:0] addr,
  input  [31:0] data
);
  reg           done;
  begin
      apb_psel    <= 1'b1;
      apb_pwrite  <= 1'b1;
      apb_pwdata  <= data;
      apb_paddr   <= addr;
    @(posedge apb_pclk);
      apb_penable <= 1'b1;

    done = 0;
    while(!done) begin
      @(posedge apb_pclk);
        done = apb_pready;
    end
    apb_psel    <= 1'b0;
    apb_penable <= 1'b0;
    apb_pwrite  <= 1'b0;
  end
endtask // m_write

task m_write_16
(
  input  [15:0] addr,
  input  [15:0] data
);
  reg           done;
  begin
      apb_psel    <= 1'b1;
      apb_pwrite  <= 1'b1;
      apb_pwdata  <= {16'h00, data};
      apb_paddr   <= {16'h00, addr};
    @(posedge apb_pclk);
      apb_penable <= 1'b1;

    done = 0;
    while(!done) begin
      @(posedge apb_pclk);
        done = apb_pready;
    end
    apb_psel    <= 1'b0;
    apb_penable <= 1'b0;
    apb_pwrite  <= 1'b0;
  end
endtask // m_write



task m_read
(
  input  [31:0] addr/*,
  output [31:0] data*/
);
  reg           done;
  reg [31:0]    data;
  begin
      apb_psel    <= 1'b1;
      apb_pwrite  <= 1'b0;
      apb_paddr   <= addr;
    @(posedge apb_pclk);
      apb_penable <= 1'b1;

    done = 0;
    data = {32{1'bx}};
    while(!done) begin
      @(posedge apb_pclk);
        done = apb_pready;
    end
    data = apb_prdata;
    apb_psel    <= 1'b0;
    apb_penable <= 1'b0;
  end
endtask // m_read


task m_read_16
(
  input  [15:0] addr,
  output [15:0] data
);
  reg           done;
  begin
    //@(posedge apb_pclk);
      apb_psel    <= 1'b1;
      apb_pwrite  <= 1'b0;
      apb_paddr   <= addr;
    @(posedge apb_pclk);
      apb_penable <= 1'b1;

    done = 0;
    data = {16{1'bx}};
    while(!done) begin
      @(posedge apb_pclk);
        done = apb_pready;
    end
    data = apb_prdata[15:0];
    apb_psel    <= 1'b0;
    apb_penable <= 1'b0;
  end
endtask // m_read


endmodule //--tb_apb_mst--

