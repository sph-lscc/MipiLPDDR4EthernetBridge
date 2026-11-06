//------------------------------------------------------------------------------------------------------------
// Title       : tod_counter.v
// Project     : PTP1588v2
//------------------------------------------------------------------------------------------------------------
// Description :
//------------------------------------------------------------------------------------------------------------
// 1. This design file implements PTP Hardware Clock(PHC) / Time of the Day (ToD)
// 2. counter is 80 bit -- 48 bits for seconds & 32 bits for nanoseconds
// 3. nanoseconds can be tuned through clock servo DSPLL clock
// 4. seconds can be loaded by the CPU when set_time = '1'.
// 5. Time valued is pushed out when it receives get_time. 
//------------------------------------------------------------------------------------------------------------
// Parameters :
//------------------------------------------------------------------------------------------------------------
// ToD_CLK_PERIOD_ns            -->  8       -- ptp clock = 125 MHz
//                                   4       -- ptp clock = 250 MHz
//------------------------------------------------------------------------------------------------------------

module tod_counter 
#(
  parameter ToD_CLK_PERIOD_ns = 4)
( 
  // clock and reset
  input             clk,
  input             rst,
  // set_time interface for seconds
  input             set_time,
  input [79:0]      set_seconds_ns,
  // get_time interface
  input             get_time_port_0,
  output reg [79:0] get_seconds_ns_port_0,
  input             get_time_port_1,
  output reg [79:0] get_seconds_ns_port_1,
  input             get_time_port_2,
  output reg [79:0] get_seconds_ns_port_2,
  input             get_time_port_3,
  output reg [79:0] get_seconds_ns_port_3,
  input             get_time_port_4,
  output reg [79:0] get_seconds_ns_port_4,
  input             get_time_gnss_pps,
  output reg [79:0] get_seconds_ns_gnss_pps,
  // 1 PPS
  output     [79:0] pps_seconds_ns,
  output reg        pps_out,
  output            pps_out_slow_clock
);

reg  [31:0] timestamp_ns;
reg  [47:0] timestamp_s;
reg  set_time_d;
reg  get_time_port_0_d;
reg  get_time_port_1_d;
reg  get_time_port_2_d;
reg  get_time_port_3_d;
reg  get_time_port_4_d;
reg  get_time_gnss_pps_d;
reg  [47:0] pps_seconds;
reg  [31:0] pps_nanosec/* synthesis syn_preserve=1 nomerge=""*/;

// Logic for loading and updating seconds
always @ (posedge clk or posedge rst) begin
  if (rst) begin 
   timestamp_s              <= 0;
   set_time_d               <= 0;
   get_time_port_0_d        <= 0;
   get_time_port_1_d        <= 0;
   get_time_port_2_d        <= 0;
   get_time_port_3_d        <= 0;
   get_time_port_4_d        <= 0;
   get_time_gnss_pps_d        <= 0;
   pps_seconds              <= 0;
  end else begin
    set_time_d              <= set_time;
    get_time_port_0_d       <= get_time_port_0;
    get_time_port_1_d       <= get_time_port_1;
    get_time_port_2_d       <= get_time_port_2;
    get_time_port_3_d       <= get_time_port_3;
    get_time_port_4_d       <= get_time_port_4;
    get_time_gnss_pps_d     <= get_time_gnss_pps;
    if (set_time & (!set_time_d)) begin
      timestamp_s           <= set_seconds_ns[79:32];
    end else if (timestamp_ns == (32'd1000000000 - ToD_CLK_PERIOD_ns)) begin
      timestamp_s           <= timestamp_s + 1;
      pps_seconds           <= timestamp_s;
    end
  end
end

// Logic for nano seconds
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    timestamp_ns            <= 0;
    pps_nanosec             <= 0;
  end else begin
    if (set_time & (!set_time_d)) begin
      timestamp_ns          <= set_seconds_ns[31:0];
    end else if(timestamp_ns  == (32'd1000000000 - ToD_CLK_PERIOD_ns)) begin
      timestamp_ns          <= 0;
      pps_nanosec           <= timestamp_ns;
    end else begin
      timestamp_ns          <= timestamp_ns + ToD_CLK_PERIOD_ns;
    end
  end
end 
 
// logic for extracting the timestamp  
always @ (posedge clk or posedge rst) begin
  if (rst) begin
   get_seconds_ns_port_0       <= 0;
  end 
  //else if (get_time_port_0 & (!get_time_port_0_d)) begin
   else begin //free running counter
   get_seconds_ns_port_0       <= {timestamp_s[47:0], timestamp_ns[31:0]};
  end
end 

always @ (posedge clk or posedge rst) begin
  if (rst) begin
   get_seconds_ns_port_1       <= 0;
  end 
  //else if (get_time_port_1 & (!get_time_port_1_d)) begin
  else begin //free running counter
   get_seconds_ns_port_1       <= {timestamp_s[47:0], timestamp_ns[31:0]};
  end
end 

always @ (posedge clk or posedge rst) begin
  if (rst) begin
   get_seconds_ns_port_2       <= 0;
  end 
  else if (get_time_port_2 & (!get_time_port_2_d)) begin
   get_seconds_ns_port_2       <= {timestamp_s[47:0], timestamp_ns[31:0]};
  end
end 

always @ (posedge clk or posedge rst) begin
  if (rst) begin
   get_seconds_ns_port_3       <= 0;
  end 
  else if (get_time_port_3 & (!get_time_port_3_d)) begin
   get_seconds_ns_port_3       <= {timestamp_s[47:0], timestamp_ns[31:0]};
  end
end 

always @ (posedge clk or posedge rst) begin
  if (rst) begin
   get_seconds_ns_port_4       <= 0;
  end 
  else if (get_time_port_4 & (!get_time_port_4_d)) begin
   get_seconds_ns_port_4       <= {timestamp_s[47:0], timestamp_ns[31:0]};
  end
end
always @ (posedge clk or posedge rst) begin
  if (rst) begin
   get_seconds_ns_gnss_pps       <= 0;
  end 
  else if (get_time_gnss_pps & (!get_time_gnss_pps_d)) begin
   get_seconds_ns_gnss_pps       <= {timestamp_s[47:0], timestamp_ns[31:0]};
  end
end
// Assigning Time value for every 1 PPS
assign pps_seconds_ns   = {pps_seconds, pps_nanosec};

// Logic for generating 1 PPS
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    pps_out                 <= 0;
  end else begin
    if(timestamp_ns  < (32'd500000000 - ToD_CLK_PERIOD_ns)) begin
      pps_out               <= 1;
    end else begin
      pps_out               <= 0;
    end
  end
end 

assign pps_out_slow_clock = timestamp_ns[8];

endmodule  
