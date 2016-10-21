//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
`timescale 1ns/10ps

module dut (
   interface main_if,
   interface slave_frm_bus,
   interface master_frm_bus
);
   import nnfpga_uvm_pkg::*;

   conv3d # (
      .FRAME_H_MAX   (FRAME_H_MAX),
      .FRAME_W_MAX   (FRAME_W_MAX),
      .STRIDE_MAX    (STRIDE_MAX),
      .DIN_WIDTH     (DIN_WIDTH),
      .DOUT_WIDTH    (DOUT_WIDTH),
      .KERN_WIDTH    (KERN_WIDTH),
      .WIN_SIZE      (WIN_SIZE),
      .CHANNELS_IN   (CHANNELS_IN),
      .CHANNELS_OUT  (CHANNELS_OUT)
   ) conv3d_inst (
      .kernel        (KERNEL),
      .frame_h       (FRAME_H),
      .frame_w       (FRAME_W),
      .stride        (STRIDE),
      .indent        (INDENT),
      .clk           (main_if.clk),
      .reset_n       (~main_if.reset),
      .fin_start     (slave_frm_bus.frame_start),
      .din_vld       (slave_frm_bus.valid),
      .din           (slave_frm_bus.data),
      .fout_start    (master_frm_bus.frame_start),
      .dout_vld      (master_frm_bus.valid),
      .dout          (master_frm_bus.data)
   );
endmodule: dut