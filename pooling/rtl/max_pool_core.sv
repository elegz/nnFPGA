//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
//max pooling core module, signed N.(DATA_WIDTH-N) arithmetics

`timescale 1ns/1ps
`include "max_pool_core_defines.svh"

`ifdef DSP_FULL_ON
   `USE_DSP
`endif
module max_pool_core # (
   parameter DATA_WIDTH       = 8,
   parameter WIN_SIZE         = 3
) (
   input    wire                                                     clk,
   input    wire                                                     reset_n,
   input    wire                                                     din_vld,
   input    wire signed [WIN_SIZE-1:0][WIN_SIZE-1:0][DATA_WIDTH-1:0] din,
   output   wire                                                     dout_vld,
   output   wire signed                             [DATA_WIDTH-1:0] dout
);
   import functions_pkg::clog2;

   localparam STAGE_NUM = clog2(WIN_SIZE);
   localparam VAR_NUM   = WIN_SIZE * WIN_SIZE;

   wire  signed [DATA_WIDTH-1:0] max;
   reg          [ STAGE_NUM-1:0] dout_vld_z;

   //defining number of operations for each stage
   genvar g;
   generate
      for (g = 0; g < STAGE_NUM; g++) begin: stage
         //TO-DO: correct formula for even WIN_SIZE (?)
         localparam STAGE_VAR_NUM = (VAR_NUM >> g) + (VAR_NUM % (1 << g) ? 1 : 0);
         reg signed [STAGE_VAR_NUM-1:0][DATA_WIDTH-1:0] stage_var;
      end: stage
   endgenerate

   assign max           = stage[STAGE_NUM-1].stage_var;
   assign dout_vld      = dout_vld_z[STAGE_NUM-1];
   assign dout          = max;

   always_ff @(posedge clk or negedge reset_n) begin: max_pool_core_pipeline
      if (!reset_n) begin
         dout_vld_z <= '0;
         for (int i = 0; i < STAGE_NUM; i++) begin
            stage[i].stage_var <= '0; 
         end
      end else begin
         //stage # 0
         for (int j = 0, l = 0; j < stage[0].STAGE_VAR_NUM; j++, l += 2) begin
            automatic bit k = (j == (stage[0].STAGE_VAR_NUM - 1)) && (VAR_NUM % 2);
            stage[0].stage_var[j] <= k ? din[l] : ((din[l] > din[l+1]) ? din[l] : din[l+1]);
         end
         
         //stage # 1...STAGE_NUM
         for (int i = 1; i < STAGE_NUM; i++) begin
            for (int j = 0, l = 0; j < stage[i].STAGE_VAR_NUM; j++, l += 2) begin
               automatic bit k = (j == (stage[i].STAGE_VAR_NUM - 1)) && (stage[i-1].STAGE_VAR_NUM % 2);
               stage[i].stage_var[j] <= k ? stage[i-1].stage_var[l] : (
                  (stage[i-1].stage_var[l] > stage[i-1].stage_var[l+1]) ?
                     stage[i-1].stage_var[l] : stage[i-1].stage_var[l+1]);
            end
         end

         //dout_vld delay line
         dout_vld_z[STAGE_NUM-1:1]   <= dout_vld_z[STAGE_NUM-2:0];
         dout_vld_z[0]               <= win_vld;
      end
   end: max_pool_core_pipeline
endmodule: max_pool_core