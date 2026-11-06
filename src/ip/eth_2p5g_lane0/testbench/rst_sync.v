`timescale 1ns / 1ps

module rst_sync (
   input                               clk,              // clock to be synced to
   input                               reset_in,         // Reset to be 'synced'
   output                              reset_out,        // synced active high reset
   output                              resetn_out        // synced active low reset
);

   reg                                 reset_async0 = 1'b1;
   reg                                 reset_async1 = 1'b1;
   reg                                 reset_async2 = 1'b1;
   reg                                 reset_async3 = 1'b1;
   reg                                 reset_async4 = 1'b1;
   reg                                 reset_sync0 = 1'b1;
   reg                                 reset_sync1 = 1'b1;

   // Synchroniser process.
   // first five flops are asynchronously reset
   always @(posedge clk or posedge reset_in)
   begin
      if (reset_in) begin
         reset_async0                  <= 1'b1;
         reset_async1                  <= 1'b1;
         reset_async2                  <= 1'b1;
         reset_async3                  <= 1'b1;
         reset_async4                  <= 1'b1;      
      end
      else begin
         reset_async0                  <= 1'b0;
         reset_async1                  <= reset_async0;
         reset_async2                  <= reset_async1;
         reset_async3                  <= reset_async2;
         reset_async4                  <= reset_async3;      
      end
   end

   // second two flops are synchronously reset - this is used for all later flops
   // and should ensure the reset is fully synchronous
   always @(posedge clk)
   begin
      if (reset_async4) begin
         reset_sync0                   <= 1'b1;
         reset_sync1                   <= 1'b1;
      end
      else begin
         reset_sync0                   <= 1'b0;
         reset_sync1                   <= reset_sync0;
      end
   end

   assign reset_out                    = reset_sync1;
   assign resetn_out                   = !reset_sync1;
  
endmodule
