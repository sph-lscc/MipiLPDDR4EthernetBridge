module debug_c_code #(
parameter    DDR_TYPE    = 0,
parameter    ASSERT_ADDR = 0,
parameter    GOOD_CODE   = 0
) (
input        clk_i        ,
input        reset_n_i    ,
input [31:0] cpu_haddr    ,
input [1:0]  cpu_htrans   ,
input [31:0] cpu_hwdata   ,
input        cpu_hreadyout
);

logic        hwdata_check_en_r;
logic [31:0] cpu_hwdata_masked;
logic [15:0] debug_value;

assign cpu_hwdata_masked = cpu_hwdata & 32'hF0000FFF;
assign debug_value       = cpu_hwdata[27:12];

always_ff @(posedge clk_i or negedge reset_n_i) begin
    if (!reset_n_i)
        hwdata_check_en_r <= 1'b0;
    else if ((cpu_haddr == ASSERT_ADDR) && (cpu_htrans == 2'h2) && cpu_hreadyout)
        hwdata_check_en_r <= 1'b1;
    else if (cpu_hreadyout)
        hwdata_check_en_r <= 1'b0;
end

always @(negedge clk_i) begin
    if (hwdata_check_en_r && cpu_hreadyout) begin
        case(cpu_hwdata_masked)
          // LPDDR4 debugs
          32'h80000001 : $display("%0d C-Code Debug: memc_init_fields()", $time);
          32'h80000002 : $display("%0d C-Code Debug: wait_phy_ready() done", $time);
          32'h80000003 : $display("%0d C-Code Debug: clock_freq_change()", $time);
          32'h80000004 : $display("%0d C-Code Debug: memc_cmd_bus_trn()", $time);
          32'h80000005 : $display("%0d C-Code Debug: memc_cmd_bus_trn_skip()", $time);
          32'h80000006 : $display("%0d C-Code Debug: memc_write_leveling()", $time);
          32'h80000007 : $display("%0d C-Code Debug: memc_write_leveling_skip()", $time);
          32'h80000008 : $display("%0d C-Code Debug: memc_read_dqs_training()", $time);
          32'h80000009 : $display("%0d C-Code Debug: memc_read_dqs_training_skip()", $time);
          32'h8000000A : $display("%0d C-Code Debug: memc_read_read_data_eye_training()", $time);
          32'h8000000B : $display("%0d C-Code Debug: memc_write_training()", $time);
          32'h8000000C : $display("%0d C-Code Debug: memc_write_training_skip()", $time);
          32'h8000000D : $display("%0d C-Code Debug: memc_initialize()", $time);
          32'h8000000E : $display("%0d C-Code Debug: cbt_check_dq_feedback(): %s", $time, ((debug_value == 0) ? "Pass" : "Fail"));
//          32'h8010000E : $display("%0d C-Code Debug: cbt_check_dq_feedback(): Fail", $time);
          32'h8000000F : $display("%0d C-Code Debug: memc_cbt_scan()", $time);
          32'h80000010 : $display("%0d C-Code Debug: wrlvl_check_dq_feedback(): %s", $time, ((debug_value == 0) ? "Pass" : "Fail"));
//          32'h80100010 : $display("%0d C-Code Debug: wrlvl_check_dq_feedback(): Fail", $time);
          32'h80000011 : $display("%0d C-Code Debug: memc_wrlvl_scan()", $time);
          32'h80000012 : $display("%0d C-Code Debug: memc_wrlvl_scan() negative path", $time);
          32'h80000013 : $display("%0d C-Code Debug: memc_cmd_bus_trn() CS training", $time);
          32'h80000014 : $display("%0d C-Code Debug: memc_delay_move(), cnt=%0d", $time, debug_value);
          32'h80000015 : $display("%0d C-Code Debug: memc_read_dqs_scan()", $time);
          32'h80000016 : $display("%0d C-Code Debug: memc_read_dqs_scan_fine()", $time);
          32'h80000017 : $display("%0d C-Code Debug: memc_read_tdqsq_training()", $time);
          32'h80000018 : $display("%0d C-Code Debug: memc_mc_dq_vref_training()", $time);
          32'h80000019 : $display("%0d C-Code Debug: memc_read_tdqsq_scan()", $time);
          32'h80000020 : $display("%0d C-Code Debug: memc_mem_dq_vref_training()", $time);
          32'h80000021 : $display("%0d C-Code Debug: memc_write_dqs2dq_scan()", $time);
           
          // DDR3 debugs
          32'hC0000001 : $display("%0d C-Code Debug: memc_ddr3_initialize()", $time);
          32'hC0000002 : $display("%0d C-Code Debug: memc_ddr3_write_leveling()", $time);
          32'hC0000003 : $display("%0d C-Code Debug: memc_ddr3_write_leveling_skip()", $time);
          32'hC0000004 : $display("%0d C-Code Debug: memc_ddr3_read_dqs_training()", $time);
          32'hC0000005 : $display("%0d C-Code Debug: memc_ddr3_read_dqs_training_skip()", $time);
          32'hC0000006 : $display("%0d C-Code Debug: memc_ddr3_wrlvl_scan()", $time);
          32'hC0000007 : $display("%0d C-Code Debug: memc_ddr3_read_dqs_scan()", $time);
          32'hC0000008 : $display("%0d C-Code Debug: memc_ddr3_read_tdqsck_scan()", $time);
          32'hC0000009 : $display("%0d C-Code Debug: memc_ddr3_read_tdqsck_training() done", $time);
          32'hC000000A : $display("%0d C-Code Debug: memc_ddr3_write_dqs2dq_scan()", $time);
          32'hC000000B : $display("%0d C-Code Debug: memc_ddr3_write_training()", $time);
          GOOD_CODE    : begin
                         $display("GOOD_CODE: C-Code terminates the test");
                         $finish;
          end
          default      : begin
                         $display("C-Code Error: C Error Code=0x%08x", cpu_hwdata);
                         $finish;
          end
        endcase
    end
end

endmodule
