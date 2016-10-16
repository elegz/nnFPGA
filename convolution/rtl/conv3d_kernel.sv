//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
//3D-convolution, wrapper for conv_kernel (1D-convolution)

`timescale 1ns/1ps

module conv3d_kernel # (
   parameter KERN_WIDTH       = 16,
   parameter DIN_WIDTH        = 8,
   parameter DOUT_WIDTH       = 8,
   parameter KERN_H           = 3,
   parameter KERN_W           = 3,
   parameter KERN_L           = 3
) (
   input    wire                                                                 clk,
   input    wire                                                                 reset_n,
   input    wire signed [KERN_L-1:0][KERN_H-1:0][KERN_W-1:0][KERN_WIDTH-1:0]     kernel,
   input    wire                                                                 din_vld,
   input    wire signed [KERN_L-1:0][KERN_H-1:0][KERN_W-1:0][ DIN_WIDTH-1:0]     din,
   output   wire                                                                 dout_vld,
   output   wire signed                                     [DOUT_WIDTH-1:0]     dout
);
   //unrolling 3D-array
   conv_kernel # (
      .KERN_WIDTH (KERN_WIDTH),
      .DIN_WIDTH  (DIN_WIDTH),
      .DOUT_WIDTH (DOUT_WIDTH),
      .KERN_SIZE  (KERN_L * KERN_H * KERN_W)
   ) conv_kernel_inst (
      .clk,
      .reset_n,
      .kernel     (kernel),
      .din_vld,
      .din        (din),
      .dout_vld,
      .dout
   );   
endmodule: conv3d_kernel