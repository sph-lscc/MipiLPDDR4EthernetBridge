module delay_1dir #(
  parameter DELAY_VAL = 0,
  parameter BIT_WIDTH = 1
) (
  input  [BIT_WIDTH-1:0] ddr_i,
  output [BIT_WIDTH-1:0] ddr_o
);

localparam DIVNUM    = 4;
localparam DELAY_DIV = DELAY_VAL/DIVNUM;
logic [DIVNUM:0][BIT_WIDTH-1:0] ddr_r;

assign ddr_r[0] = ddr_i;

genvar i;

generate 
  if (DELAY_VAL <= DIVNUM) begin : DLY0
    assign #(DELAY_VAL) ddr_o = ddr_i;
  end
  else begin : DLAY
    for(i=1; i<=DIVNUM; i=i+1) begin : DLYDIV
      assign #(DELAY_DIV) ddr_r[i] = ddr_r[i-1];
    end
    assign ddr_o = ddr_r[DIVNUM];
  end

endgenerate
endmodule
