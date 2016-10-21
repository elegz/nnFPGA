//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
//window with padding

`timescale 1ns/1ps

module win_pad import functions_pkg::clog2; # (
   parameter FRAME_H_MAX = 224,
   parameter FRAME_W_MAX = 224,
   parameter STRIDE_MAX  = 4,
   parameter DIN_WIDTH   = 8,
   parameter WIN_SIZE    = 3,
   parameter CH_NUM      = 3
) (
   input    wire                                                                    clk,
   input    wire                                                                    reset_n,
   input    wire                                          [clog2(FRAME_H_MAX-1):0]  frame_h,
   input    wire                                          [clog2(FRAME_W_MAX-1):0]  frame_w,
   input    wire                                          [ clog2(STRIDE_MAX-1):0]  stride,
   input    wire                                                                    indent,
   input    wire                                                                    fin_start,
   input    wire                                                                    din_vld,
   input    wire                [WIN_SIZE-1:0][CH_NUM-1:0][         DIN_WIDTH-1:0]  din,
   output   wire                                                                    fout_start,
   output   reg                                                                     win_vld,
   output   reg   [WIN_SIZE-1:0][WIN_SIZE-1:0][CH_NUM-1:0][         DIN_WIDTH-1:0]  window
);
   localparam WIN_R   = WIN_SIZE / 2;
   localparam WIN_DLY = WIN_R + 1;

   reg                                                       frame_valid;
   reg                             [clog2(FRAME_H_MAX-1):0]  row_pointer;
   reg                             [clog2(FRAME_W_MAX-1):0]  column_pointer;
   reg                             [clog2(FRAME_H_MAX-1):0]  str_row_ptr;
   reg                             [clog2(FRAME_W_MAX-1):0]  str_col_ptr;
   reg                             [           WIN_DLY-1:0]  fin_start_z;
   reg                             [           WIN_DLY-1:0]  din_vld_z;
   reg   [WIN_SIZE-1:0][ WIN_R-1:0][         DIN_WIDTH-1:0]  win_buf;
   reg                 [   WIN_R:1][        clog2(WIN_R):0]  top_pad_timer;
   reg                 [   WIN_R:1][        clog2(WIN_R):0]  bot_pad_timer;

   assign fout_start = fin_start_z[WIN_DLY-1];

   //delay lines for some input signals
   always_ff @(posedge clk or negedge reset_n) begin: input_sig_delay
      if (~reset_n) begin
         {din_vld_z, frame_start_z} <= '0;
      end else begin
         din_vld_z[WIN_DLY-1:1]   <= din_vld_z[WIN_DLY-2:0];
         din_vld_z[0]             <= din_vld;

         fin_start_z[WIN_DLY-1:1] <= fin_start_z[WIN_DLY-2:0];
         fin_start_z[0]           <= fin_start;
      end
   end: input_sig_delay

   always_ff @(posedge clk or negedge reset_n) begin: window_logic
      if (~reset_n) begin
         {window, win_buf, frame_valid, win_vld}                  <= '0;
         {row_pointer, column_pointer, str_row_ptr, str_col_ptr}  <= '0;
         {top_pad_timer, bot_pad_timer}                           <= '0;
      end else if (frame_start) begin
         {row_pointer, top_pad_timer, bot_pad_timer}     <= '0;
         str_row_ptr                                     <= indent;
         frame_valid                                     <= '1;
      end else begin
         //buffer to support continuous streaming
         if (din_vld) begin
            win_buf[WIN_R][0] <= din[WIN_R];
            for (int i = 0; i < WIN_R; i++) begin
               win_buf[i][0]         <= (bot_pad_timer[i+1] == 0) ? din[i] : 1'b0;
               win_buf[i+WIN_R+1][0] <= (top_pad_timer[i+1] == (i + 1)) ? din[i]: 1'b0;
            end
         end

         if (din_vld_z[WIN_DLY-2] && frame_valid) begin
            //output column & row + stride logic
            if (column_pointer == (frame_w - 1)) begin
               column_pointer <= '0;
               row_pointer++;
               str_col_ptr    <= indent;
               if (row_pointer == str_row_ptr) begin
                  str_row_ptr += stride;
               end
            end else begin 
               if ((row_pointer == str_row_ptr) && (column_pointer == str_col_ptr)) begin
                  win_vld     <= (column_pointer < (frame_w - indent)) && (row_pointer < (frame_h - indent));
                  str_col_ptr += stride;
               end else begin
                  win_vld <= 1'b0;
               end
               column_pointer++;
            end

            //top/bottom borders padding with timers
            if (column_pointer == (frame_w - WIN_R - 1)) begin
               for (int i = 1; i <= WIN_R; i++) begin
                  if (top_mux_addr[i] != i) begin
                     top_pad_timer[i]++;
                  end
                  if (row_pointer >= (frame_h - WIN_R + i - 1)) begin
                     bot_pad_timer[i]++;
                  end
               end
            end

            if (!column_pointer) begin
               //load window from internal buffer regs
               for (int i = 0; i < WIN_SIZE; i++) begin
                  for (int j = 1; j <= WIN_R; j++) begin
                     window[i][j] <= win_buf[i][j-1];
                  end
               end
               //left border padding
               for (int i = 0; i < WIN_SIZE; i++) begin
                  for (int j = WIN_R + 1; j < WIN_SIZE; j++) begin
                     window[i][j] <= 1'b0;
                  end
               end
            end else begin
               //shifting rows through window
               //performing padding, if window[i][0] is reseted
               //by column_pointer >= frame_w - WIN_R (1...n stages) 
               for (int i = 0; i < WIN_SIZE; i++) begin
                  window[i][WIN_SIZE-1:1] <= window[i][WIN_SIZE-2:0];
               end
            end

            //shifting rows through window
            //performing padding, if window[i][0] is reseted
            //by column_pointer >= frame_w - WIN_R (0 stage)
            if (column_pointer < (frame_w - WIN_R)) begin
               window[WIN_R][0] <= din[WIN_R];
               for (int i = 0; i < WIN_R; i++) begin
                  window[i][0]          <= (bot_pad_timer[i+1] == 0) ? din[i] : 1'b0;
                  window[i+WIN_R+1][0]  <= (top_pad_timer[i+1] == (i + 1)) ? din[i]: 1'b0;
               end
            end else begin
               for (int i = 0; i < WIN_SIZE; i++) begin
                  window[i][0] <= 1'b0;
               end
            end
         end

         if (row_pointer == frame_h) begin
            frame_valid <= '0;
         end
      end
   end: window_logic
endmodule: win_pad