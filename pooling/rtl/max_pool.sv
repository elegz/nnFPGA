//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
`timescale 1ns/1ps

module max_pool import functions_pkg::clog2; # (
   parameter FRAME_H_MAX   = 224,
   parameter FRAME_W_MAX   = 224,
   parameter STRIDE_MAX    = 4,
   parameter DATA_WIDTH    = 8,
   parameter WIN_SIZE      = 3,
   parameter CH_NUM        = 128
) (
   //external buffer
   input    wire [clog2(FRAME_H_MAX):0] frame_h,
   input    wire [clog2(FRAME_W_MAX):0] frame_w,
   input    wire [ clog2(STRIDE_MAX):0] stride,

   input    wire                                clk,
   input    wire                                reset_n,
   input    wire                                frame_start,
   input    wire                                din_vld,
   input    wire [CH_NUM-1:0][DATA_WIDTH-1:0]   din,
   output   wire                                dout_vld,
   output   wire [CH_NUM-1:0][DATA_WIDTH-1:0]   dout
);
   wire                                                                 frame_start_buf;
   wire                                                                 din_vld_buf;
   wire                   [WIN_SIZE-1:0][  CH_NUM-1:0][DATA_WIDTH-1:0]  din_buf;
   wire                                                                 win_vld;
   wire  [   WIN_SIZE-1:0][WIN_SIZE-1:0][  CH_NUM-1:0][DATA_WIDTH-1:0]  window;
   wire                                                                 pool_dout_vld[CH_NUM];

   logic                  [WIN_SIZE-1:0][WIN_SIZE-1:0][DATA_WIDTH-1:0]  pool_din[CH_NUM];

   assign dout_vld = pool_dout_vld[0];

   always_comb begin: pool_din_forming
      for (int i = 0; i < WIN_SIZE; i++) begin
         for (int j = 0; j < WIN_SIZE; j++) begin
            for (int k = 0; k < CH_NUM; k++) begin
               pool_din[k][i][j] = window[i][j][k];          
            end
         end
      end
   end: pool_din_forming

   row_buffer # (
      .FRAME_H_MAX      (FRAME_H_MAX),
      .FRAME_W_MAX      (FRAME_W_MAX),
      .DIN_WIDTH        (DATA_WIDTH),
      .WIN_SIZE         (WIN_SIZE),
      .CH_NUM           (CH_NUM)
   ) row_buffer_inst (
      .clk,
      .reset_n,
      .frame_h,
      .frame_w,
      .frame_start,
      .din_vld,
      .din,
      .din_vld_buf,
      .din_buf,
      .frame_start_buf
   );

   win_pad # (
      .FRAME_H_MAX   (FRAME_H_MAX),
      .FRAME_W_MAX   (FRAME_W_MAX),
      .STRIDE_MAX    (STRIDE_MAX),
      .DIN_WIDTH     (DATA_WIDTH),
      .WIN_SIZE      (WIN_SIZE),
      .CH_NUM        (CH_NUM)
   ) win_pad_inst (
      .clk,
      .reset_n,
      .frame_h,
      .frame_w,
      .stride,
      .frame_start   (frame_start_buf),
      .din_vld       (din_vld_buf),
      .din           (din_buf),
      .win_vld,
      .window
   );

   genvar g;
   generate
      for (g = 0; g < CH_NUM; g++) begin: pool_ch
         max_pool_core # (
            .DATA_WIDTH (DATA_WIDTH),
            .WIN_SIZE   (WIN_SIZE)
         ) max_pool_core_inst (
            .clk,
            .reset_n,
            .din_vld    (win_vld),
            .din        (pool_din[g]),
            .dout_vld   (pool_dout_vld[g]),
            .dout       (dout[g])
         );
      end: pool_ch
   endgenerate
endmodule: max_pool