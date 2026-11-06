//===========================================================================
// Filename: tb_lmmi_model.v
// Copyright(c) 2025 Lattice Semiconductor Corporation. All rights reserved. 
//===========================================================================
`ifndef TB_LMMI_MODEL
`define TB_LMMI_MODEL

`timescale 1ps / 1ps

module tb_lmmi_model #(
  parameter LMMI                     = "ON",
  parameter INIT_DELAY               = 0,
  parameter DPHY_IP                  = "LATTICE",
  parameter DPHY_RATE                = 0,
  parameter DPHY_GEAR                = 0,
  parameter NUM_LANE                 = 0,
  parameter CLK_MODE                 = "HS_LP",
  parameter PROT_TYPE                = "DSI",
  parameter CIL_BYPASS               = "CIL_ENABLED",
  parameter DESKEW_EN                = "DISABLED",
  parameter [5:0] UC_PRG_RXHS_SETTLE = 0,
  parameter [5:0] U_PRG_RXHS_SETTLE  = 0,
  parameter [7:0] DATA_SETTLE_CYC    = 0,
  parameter [15:0]RX_FIFO_PKT_DLY    = 0,
  parameter HARD_DPHY_REG            = 13,
  parameter GEN_DPHY_REG             = 27,
  parameter LMMI_OFFSET_WIDTH        = 8,
  parameter LMMI_DATA_WIDTH          = 32
)(
  input  logic                         lmmi_clk_i,
  input  logic                         lmmi_ready_i,
  input  logic                         lmmi_rdata_valid_i,
  input  logic [LMMI_DATA_WIDTH-1:0]   lmmi_rdata_i,
  output logic [LMMI_OFFSET_WIDTH-1:0] lmmi_offset_o,
  output logic [LMMI_DATA_WIDTH-1:0]   lmmi_wdata_o,
  output logic                         lmmi_wr_rdn_o,
  output logic                         lmmi_request_o,
  output logic                         lmmi_resetn_o,
  output logic                         lmmi_cmp_fail_o
);
// Parameters
// Hard DPHY default
localparam [0:0] HSEL              = DPHY_RATE > 1500 ? 1'b1 : 1'b0;
localparam [0:0] DSI_CSI           = PROT_TYPE == "DSI" ? 1'b1 : 1'b0;
localparam [1:0] RXCDRP            = 2'b01;
localparam [1:0] RSEL              = 2'b00;
localparam [0:0] EN_CIL            = CIL_BYPASS == "CIL_ENABLED" ? 1'b1 : 1'b0;
localparam [2:0] RXLPRP            = 3'b001;
localparam [0:0] DSKEW_EN          = DESKEW_EN == "ENABLED" ? 1'b1 : 1'b0;
localparam [1:0] LANE0_SEL         = 2'b00;
localparam [1:0] RXDATAWIDTHHS     = DPHY_GEAR == 8 ? 2'b00 : 2'b01;
localparam [1:0] CFG_NUM_LANE      = NUM_LANE-1;
localparam [0:0] CONT_CLK_MODE     = CLK_MODE == "HS_ONLY" ? 1'b1 : 1'b0;
localparam [3:0] HARD_0X1B         = DPHY_RATE > 1500 ? 4'b0000 : 4'b0010;
localparam [3:0] HARD_0X1D         = DPHY_RATE > 1500 ? 4'b0000 : 4'b1000;
localparam [5:0] D_PRG_RXHS_SETTLE = CIL_BYPASS == "CIL_ENABLED" ? 
                                               U_PRG_RXHS_SETTLE : 6'h00;
localparam [5:0] C_PRG_RXHS_SETTLE = CIL_BYPASS == "CIL_ENABLED" ? 
                                               UC_PRG_RXHS_SETTLE : 6'h00;

// General
localparam CSR_NUM = DPHY_IP == "LATTICE" ? GEN_DPHY_REG - 1 : 
                                            HARD_DPHY_REG + GEN_DPHY_REG -1;

// Internal signals

logic [LMMI_OFFSET_WIDTH-1:0] lmmi_offset_r;
logic [LMMI_DATA_WIDTH-1:0]   lmmi_wdata_r;
logic                         lmmi_wr_rdn_r;
logic                         lmmi_request_r;
logic                         lmmi_resetn_r;


// Declare logic for task output argument
logic [LMMI_DATA_WIDTH-1:0]   data;

// Array to store read data from addresses 0x1F to 0x39 (inclusive)
logic [LMMI_DATA_WIDTH-1:0] rd_data_array [0:CSR_NUM];

// Array to store expected read data for comparison
logic [LMMI_DATA_WIDTH-1:0] expected_rd_data_array [0:HARD_DPHY_REG+GEN_DPHY_REG-1];

logic lmmi_done;
logic lmmi_cmp_fail;

logic [LMMI_OFFSET_WIDTH-1:0] hardaddr_list [0:HARD_DPHY_REG-1];

// Read is done prior to transactions. Just expecting default values
initial begin
  // Expected data (8'h1F + idx - GEN_DPHY_REG)
  expected_rd_data_array[0]  = 'h00; // 0x1F
  expected_rd_data_array[1]  = 'h00; // 0x20
  expected_rd_data_array[2]  = 'h00; // 0x21
  expected_rd_data_array[3]  = 'h00; // 0x22
  expected_rd_data_array[4]  = 'h00; // 0x23
  expected_rd_data_array[5]  = 'h00; // 0x24
  expected_rd_data_array[6]  = 'h00; // 0x25
  expected_rd_data_array[7]  = 'h00; // 0x26
  expected_rd_data_array[8]  = 'h00; // 0x27
  expected_rd_data_array[9]  = 'h00; // 0x28
  expected_rd_data_array[10] = 'h0F; // 0x29
  expected_rd_data_array[11] = 'h00; // 0x2A
  expected_rd_data_array[12] = 'h00; // 0x2B
  expected_rd_data_array[13] = 'h00; // 0x2C
  expected_rd_data_array[14] = 'h00; // 0x2D
  expected_rd_data_array[15] = 'h00; // 0x2E
  expected_rd_data_array[16] = 'h00; // 0x2F
  expected_rd_data_array[17] = 'h00; // 0x30
  expected_rd_data_array[18] = 'h00; // 0x31
  expected_rd_data_array[19] = 'h00; // 0x32
  expected_rd_data_array[20] = 'h00; // 0x33
  expected_rd_data_array[21] = 'h00; // 0x34
  expected_rd_data_array[22] = 'h00; // 0x35
  expected_rd_data_array[23] = DATA_SETTLE_CYC[LMMI_DATA_WIDTH-1:0]; // 0x36
  expected_rd_data_array[24] = RX_FIFO_PKT_DLY[LMMI_DATA_WIDTH*1-1:LMMI_DATA_WIDTH*0]; // 0x37
  expected_rd_data_array[25] = RX_FIFO_PKT_DLY[LMMI_DATA_WIDTH*2-1:LMMI_DATA_WIDTH*1]; // 0x38
  expected_rd_data_array[26] = 'h00; // 0x39
  // Hard DPHY
  expected_rd_data_array[27] = {4'h0,HSEL,1'b0,1'b0,DSI_CSI         };  // 0x00
  expected_rd_data_array[28] = {4'h0,RXCDRP,RSEL                    };  // 0x01
  expected_rd_data_array[29] = {4'h0,EN_CIL,RXLPRP                  };  // 0x02
  expected_rd_data_array[30] = {4'h0,3'b010,DSKEW_EN                };  // 0x03
  expected_rd_data_array[31] = {4'h0,LANE0_SEL[0],RXDATAWIDTHHS,1'b0};  // 0x09
  expected_rd_data_array[32] = {4'h0,C_PRG_RXHS_SETTLE[0],
                                     CFG_NUM_LANE,LANE0_SEL[1]      };  // 0x0A
  expected_rd_data_array[33] = {4'h0,C_PRG_RXHS_SETTLE[4:1]        };  // 0x0B
  expected_rd_data_array[34] = {4'h0,3'b000,C_PRG_RXHS_SETTLE[5]   };  // 0x0C
  expected_rd_data_array[35] = {4'h0,D_PRG_RXHS_SETTLE[1:0], 2'b00  };  // 0x0F
  expected_rd_data_array[36] = {4'h0,D_PRG_RXHS_SETTLE[5:2]         };  // 0x10
  expected_rd_data_array[37] = {4'h0,HARD_0X1B                      };  // 0x1B
  expected_rd_data_array[38] = {4'h0,HARD_0X1D                      };  // 0x1D
  expected_rd_data_array[39] = {4'h0,3'b000,CONT_CLK_MODE           };  // 0x1E

  // hard DPHY registers
  hardaddr_list[ 0] = 'h00;
  hardaddr_list[ 1] = 'h01;
  hardaddr_list[ 2] = 'h02;
  hardaddr_list[ 3] = 'h03;
  hardaddr_list[ 4] = 'h09;
  hardaddr_list[ 5] = 'h0A;
  hardaddr_list[ 6] = 'h0B;
  hardaddr_list[ 7] = 'h0C;
  hardaddr_list[ 8] = 'h0F;
  hardaddr_list[ 9] = 'h10;
  hardaddr_list[10] = 'h1B;
  hardaddr_list[11] = 'h1D;
  hardaddr_list[12] = 'h1E;
end

initial begin
  lmmi_done     = 1'b0;
  lmmi_cmp_fail = 1'b0;
  #(INIT_DELAY); //wait initialization delay
  // Example: use hardaddr_list defined in the module
  lmmi_rd_wr_rd(hardaddr_list);
  lmmi_done = 1'b1;
  $display("%0t LMMI sequence done.", $realtime);
end

// task which gives initial values to LMMI ports and resets LMMI
task lmmi_reset();
  begin
    lmmi_resetn_r  = 1'd0;
    lmmi_wdata_r   = {LMMI_DATA_WIDTH{1'b0}};
    lmmi_wr_rdn_r  = 1'd0;
    lmmi_offset_r  = {LMMI_OFFSET_WIDTH{1'd0}};
    lmmi_request_r = 1'd0;
    #10;
    @(posedge lmmi_clk_i)
    #1;
    lmmi_resetn_r  = 1'd1;
  end
endtask

task lmmi_write(
  input [LMMI_OFFSET_WIDTH-1:0] offset,
  input [LMMI_DATA_WIDTH-1:0]   data
  );
  begin
    @(posedge lmmi_clk_i);
    lmmi_offset_r  = offset;
    lmmi_wdata_r   = data;
    lmmi_wr_rdn_r  = 1'd1;
    lmmi_request_r = 1'd1;
    @(posedge lmmi_clk_i);
    #1;
    $display("%0t", $realtime, " LMMI  : Write data 0x%1h", lmmi_wdata_r, " in register address 0x%h", lmmi_offset_r);
    lmmi_wr_rdn_r  = 1'd0;
    lmmi_request_r = 1'd0;
    @(posedge lmmi_clk_i);
    while (lmmi_ready_i != 1'h1) begin
      @(posedge lmmi_clk_i);
    end
    @(posedge lmmi_clk_i);
  end
endtask

task lmmi_read(
  input  [LMMI_OFFSET_WIDTH-1:0] offset,
  output [LMMI_DATA_WIDTH-1:0]   data
  );
  begin
    data              = {LMMI_DATA_WIDTH{1'h0}};
    @(posedge lmmi_clk_i);
    lmmi_offset_r     = offset;
    lmmi_wr_rdn_r     = 1'd0;
    lmmi_request_r    = 1'd1;
    @(posedge lmmi_clk_i);
    lmmi_wr_rdn_r     = 1'd0;
    lmmi_request_r    = 1'd0;
    @(posedge lmmi_clk_i);
    while (lmmi_ready_i != 1'h1 & lmmi_rdata_valid_i != 1'h1) begin
      @(posedge lmmi_clk_i);
    end
    data              = lmmi_rdata_i;
    $display("%0t",$realtime," LMMI  : Read  data 0x%1h", lmmi_rdata_i," in register address 0x%h", lmmi_offset_r);
    @(posedge lmmi_clk_i);
  end
endtask

// Pass an array of addresses for configurable reads
task lmmi_rd_wr_rd(
  input [LMMI_OFFSET_WIDTH-1:0] hard_addr_list [0:HARD_DPHY_REG-1]
);
  int idx;
  int compare_count; // Counter for number of data compared
  logic [LMMI_DATA_WIDTH-1:0] temp_data;
  begin
    compare_count = 0;
    // Access general registers (0x1F to 0x39)
    for (idx = 0; idx < GEN_DPHY_REG; idx = idx + 1) begin
      lmmi_read(8'h1F + idx, temp_data);
      rd_data_array[idx] = temp_data;
    end
    if (DPHY_IP != "LATTICE") begin
      // Access configurable addresses from the list
      for (idx = 0; idx < HARD_DPHY_REG; idx = idx + 1) begin
        lmmi_read(hard_addr_list[idx], temp_data);
        rd_data_array[GEN_DPHY_REG + idx] = temp_data;
      end
    end

    // Write back the previously read data to each register
    for (idx = 0; idx < GEN_DPHY_REG; idx = idx + 1) begin
      lmmi_write(8'h1F + idx, rd_data_array[idx]);
    end
    if (DPHY_IP != "LATTICE") begin
      for (idx = 0; idx < HARD_DPHY_REG; idx = idx + 1) begin
        lmmi_write(hard_addr_list[idx], rd_data_array[GEN_DPHY_REG + idx]);
      end
    end

    // Read again after write is done
    for (idx = 0; idx < GEN_DPHY_REG; idx = idx + 1) begin
      lmmi_read(8'h1F + idx, temp_data);
      $display("Post-Write Read: Addr=0x%h, Data=0x%h", 8'h1F + idx, temp_data);
    end
    if (DPHY_IP != "LATTICE") begin
      for (idx = 0; idx < HARD_DPHY_REG; idx = idx + 1) begin
        lmmi_read(hard_addr_list[idx], temp_data);
        $display("Post-Write Read: Addr=0x%h, Data=0x%h", hard_addr_list[idx], temp_data);
      end
    end

    // Compare logic between expected_rd_data_array and rd_data_array
    for (idx = 0; idx <= CSR_NUM; idx = idx + 1) begin
      compare_count = compare_count + 1;
      if (rd_data_array[idx] !== expected_rd_data_array[idx]) begin
        $display("ERROR: LMMI Read Mismatch at index %0d: read=0x%h, expected=0x%h", idx, rd_data_array[idx], expected_rd_data_array[idx]);
        lmmi_cmp_fail = 1'b1; // stick-high
      end 
      else begin
        $display("LMMI Matches at index %0d: value=0x%h", idx, rd_data_array[idx]);
      end
    end
    $display("Total LMMI CSRs compared data: %0d", compare_count);

  end
endtask

// Drive outputs from internal signals
assign lmmi_offset_o    = lmmi_offset_r;
assign lmmi_wdata_o     = lmmi_wdata_r;
assign lmmi_wr_rdn_o    = lmmi_wr_rdn_r;
assign lmmi_request_o   = lmmi_request_r;
assign lmmi_resetn_o    = lmmi_resetn_r;
assign lmmi_cmp_fail_o  = (LMMI == "ON") ? lmmi_cmp_fail : 1'b0;

endmodule
`endif

