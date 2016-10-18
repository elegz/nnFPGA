//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
//convolver, signed N.(KERN_WIDTH-N) arithmetics

`timescale 1ns/1ps
`include "conv_kernel_defines.svh"

`ifdef DSP_FULL_ON
   `USE_DSP
`endif
module conv_kernel # (
   parameter KERN_WIDTH       = 16,
   parameter DIN_WIDTH        = 8,
   parameter DOUT_WIDTH       = 8,
   parameter KERN_SIZE        = 3
) (
   input    wire                                            clk,
   input    wire                                            reset_n,
   input    wire signed [KERN_SIZE-1:0][KERN_WIDTH-1:0]     kernel,
   input    wire                                            din_vld,
   input    wire signed [KERN_SIZE-1:0][ DIN_WIDTH-1:0]     din,
   output   wire                                            dout_vld,
   output   wire signed                [DOUT_WIDTH-1:0]     dout
);
   import functions_pkg::clog2;

   localparam SUM_STAGE_NUM   = clog2(KERN_SIZE);
   localparam DIFF_SIZE       = KERN_WIDTH - DIN_WIDTH;

   logic signed [KERN_SIZE-1:0][  DIN_WIDTH-1:0] din_format;
   wire  signed [KERN_SIZE-1:0][ KERN_WIDTH-1:0] dot_pro;
   wire  signed                [ KERN_WIDTH-1:0] dot_pro_sum;
   reg                         [SUM_STAGE_NUM:0] dout_vld_z;

   `ifdef DSP_MULT_ON
      `USE_DSP
   `endif
   reg signed [KERN_SIZE-1:0][KERN_WIDTH-1:0] dot_pro_mat;

   //defining number of operations for each stage
   genvar g;
   generate
      for (g = 1; g <= SUM_STAGE_NUM; g++) begin: sum_stage
         //TO-DO: correct formula for even KERN_SIZE (?)
         localparam DOT_PRO_SUMS_NUM = (KERN_SIZE >> g) + (KERN_SIZE % (1 << g) ? 1 : 0);
         reg signed [DOT_PRO_SUMS_NUM-1:0][KERN_WIDTH-1:0] dot_pro_sums;
      end: sum_stage
   endgenerate

   assign dot_pro       = dot_pro_mat;
   assign dot_pro_sum   = sum_stage[SUM_STAGE_NUM].dot_pro_sums;
   assign dout_vld      = dout_vld_z[SUM_STAGE_NUM];
   assign dout          = dot_pro_sum[KERN_WIDTH-1:KERN_WIDTH-DOUT_WIDTH];

   //reformat din to signed N.(KERN_WIDTH-N) arithmetics
   always_comb begin: din_reformatting
      for (int i = 0; i < KERN_SIZE; i++) begin
         din_format[i] = DIFF_SIZE ? {din[i],{DIFF_SIZE{1'b0}}} : din[i];
      end
   end: din_reformatting

   always_ff @(posedge clk or negedge reset_n) begin: kernel_pipeline
      if (!reset_n) begin
         {dot_pro_mat, dout_vld_z} <= '0;
         for (int i = 1; i <= SUM_STAGE_NUM; i++) begin
            sum_stage[i].dot_pro_sums <= '0; 
         end
      end else begin
         //kernel stage # 0: dot_pro calculation
         for (int i = 0; i < KERN_SIZE; i++) begin
            dot_pro_mat[i] <= din_format[i] * kernel[i];
         end

         //kernel stage # 1...SUM_STAGE_NUM: dot_pro_sum calculation
         for (int j = 0, l = 0; j < sum_stage[1].DOT_PRO_SUMS_NUM; j++, l += 2) begin //kernel stage # 1
            automatic bit k = (j == (sum_stage[1].DOT_PRO_SUMS_NUM - 1)) && (KERN_SIZE % 2);
            sum_stage[1].dot_pro_sums[j] <= k ? dot_pro[l] : dot_pro[l] + dot_pro[l+1];
         end
         
         for (int i = 2; i <= SUM_STAGE_NUM; i++) begin //kernel stage # 2...SUM_STAGE_NUM
            for (int j = 0, l = 0; j < sum_stage[i].DOT_PRO_SUMS_NUM; j++, l += 2) begin
               automatic bit k = (j == (sum_stage[i].DOT_PRO_SUMS_NUM - 1)) && (sum_stage[i-1].DOT_PRO_SUMS_NUM % 2);
               sum_stage[i].dot_pro_sums[j] <=
                  k ? sum_stage[i-1].dot_pro_sums[l] : sum_stage[i-1].dot_pro_sums[l] + sum_stage[i-1].dot_pro_sums[l+1];
            end
         end

         //dout_vld delay line
         dout_vld_z[SUM_STAGE_NUM:1]   <= dout_vld_z[SUM_STAGE_NUM-1:0];
         dout_vld_z[0]                 <= win_vld;
      end
   end: kernel_pipeline
endmodule: conv_kernel