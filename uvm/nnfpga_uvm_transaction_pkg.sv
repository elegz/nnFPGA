//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvmnnfpga_uvm_transaction_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_pkg::*;

   typedef struct {
      int                       width,
      int                       height,
      rand logic unsigned [7:0] data[$];
   } frm_stream;

   //one channel / serial transaction
   class frame_transaction # (
      type      FTYPE            = frm_stream,
      parameter GAP_TIME_MIN     = 3,
      parameter GAP_TIME_MAX     = 10
   ) extends uvm_sequence_item;
      `uvm_object_param_utils(frame_transaction # (
         FTYPE,
         GAP_TIME_MIN,
         GAP_TIME_MAX
      ))

      FTYPE              frame;
      int unsigned       length;
      rand int unsigned  gap;
      int                seq_id = 0;

      constraint c_igp {
         gap inside {[GAP_TIME_MIN:GAP_TIME_MAX]};
      }

      virtual function void create_from_string (
         input string str
      );
         data_t data;
         for (int i = 0; i < (str.len() - 1); i += 2) begin
            data.push_back(byte'(str2hex(str[i+:2])));
         end
         create_from_stream(data);
      endfunction: create_from_string

      virtual function void create_from_stream (input data_t stream);
         frame.data  = {};
         frame       = FTYPE'(stream);
         length      = frame.data.size();
      endfunction: create_from_stream

      virtual function void print_hex ();
         string str = "";
         for (int i = 0; i < frame.data.size(); i++) begin
            str = {str, $sformatf("%h ", frame.data[i])};
         end
         $display(str);
      endfunction: print_hex

      function new (string name = "frame_transaction");
         super.new(name);
         gap      = GAP_TIME_MIN;
         seq_id   = 0;
      endfunction: new
   endclass: frame_transaction
endpackage: nnfpga_uvm_transaction_pkg