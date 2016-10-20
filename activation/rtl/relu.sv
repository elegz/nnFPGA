//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
//ReLU module, signed N.(DATA_WIDTH-N) arithmetics

`timescale 1ns/1ps

module relu # (
   parameter DATA_WIDTH = 8,
   parameter CH_NUM     = 128
) (
   input    wire                                      clk,
   input    wire                                      reset_n,
   input    wire                                      fin_start,
   input    wire                                      din_vld,
   input    wire signed [CH_NUM-1:0][DATA_WIDTH-1:0]  din,
   output   reg                                       fout_start,
   output   reg                                       dout_vld,
   output   reg  signed [CH_NUM-1:0][DATA_WIDTH-1:0]  dout
);
   always_ff @(posedge clk or negedge reset_n) begin: relu_proc
      if(~reset_n) begin
         {dout_vld, fout_start, out_st dout} <= '0;
      end else begin
         dout_vld    <= din_vld;
         fout_start  <= fin_start;
         for (int i = 0; i < CH_NUM; i++) begin
            dout[i] <= din[i][DATA_WIDTH-1] ? 0 : din[i];
         end
      end
   end: relu_proc
endmodule: relu