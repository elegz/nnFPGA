//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_scoreboard_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;
   //import nnfpga_uvm_if_lib::*;

   class nnfpga_uvm_scoreboard extends uvm_scoreboard;
      `uvm_component_utils(nnfpga_uvm_scoreboard)

      event reset_scoreboard;

      uvm_analysis_export # (frame_trans)    sb_frm_mon_export;
      uvm_analysis_export # (frame_trans)    sb_gm_mon_export;

      uvm_tlm_analysis_fifo # (frame_trans)  sb_frm_mon_fifo;
      uvm_tlm_analysis_fifo # (frame_trans)  sb_gm_mon_fifo;

      frame_trans frm_trans;
      frame_trans gm_trans;

      int sb_error = 0;

      function new(string name, uvm_component parent);
         super.new(name, parent);
         frm_trans = new("frame_trans");
         gm_trans  = new("frame_trans");
      endfunction: new

      function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         sb_frm_mon_export    = new("sb_frm_mon_export", this);
         sb_gm_mon_export     = new("sb_gm_mon_export", this);

         sb_frm_mon_fifo      = new("sb_frm_mon_fifo", this);
         sb_gm_mon_fifo       = new("sb_gm_mon_fifo", this);
      endfunction: build_phase

      function void connect_phase(uvm_phase phase);
         super.connect_phase(phase);
         sb_frm_mon_export.connect(sb_frm_mon_fifo.analysis_export);
         sb_gm_mon_export.connect(sb_gm_mon_fifo.analysis_export);
      endfunction: connect_phase

      virtual task run_phase(uvm_phase phase);
         forever begin
            fork
               begin
                  //init full cycle vars here
                  fork
                     forever begin: frm_checks
                        bit got_frm  = '0;
                        fork
                           timeout_check("Frame timeout", TRANS_TIMEOUT, 100, got_frm);
                           begin
                              // $display("BEFORE SB FIFOs");
                              // $display(frm_trans);
                              // $display(gm_trans);
                              // $display(sb_frm_mon_fifo.size());
                              // $display(sb_gm_mon_fifo.size());
                              frm_trans = frame_transaction # ()::type_id::create(.name("frm_trans"), .contxt(get_full_name()));
                              sb_frm_mon_fifo.get(frm_trans);
                              gm_trans = frame_transaction # ()::type_id::create(.name("gm_trans"), .contxt(get_full_name()));
                              sb_gm_mon_fifo.get(gm_trans);
                              frm_compare();
                              // $display("GM FIFO");
                              // $display(frm_trans);
                              // $display(gm_trans);
                              // $display(sb_frm_mon_fifo.size());
                              // $display(sb_gm_mon_fifo.size());
                              got_frm = '1;    
                           end   
                        join
                     end: frm_checks
                  join
               end
            join_none

            @(reset_scoreboard);
            disable fork;
            cleanup();
         end
      endtask: run_phase

      virtual function void frm_compare();
         int      size0    = frm_trans.frame.size();
         int      size1    = gm_trans.frame.size();
         data_t   frm0     = frm_trans.frame;
         data_t   frm1     = gm_trans.frame;
         if (size0 == size1) begin
            if (frm != frm) begin
               `uvm_error("Frame compare: data", "ERR: rdata of the received frame does not match to the expected data!");
               sb_error = 1;
               $display($sformatf("Frame size: %0d", size0));
               $display("Expected frame:");
               gm_trans.print_hex();
               $display("Received frame:");
               frm_trans.print_hex();
               // $display(sb_frm_mon_fifo.size());
               // $display(sb_gm_mon_fifo.size());
               //$stop;
            end
         end else begin
            `uvm_error("Frame compare: size", $sformatf("ERR: size (%0d) of the received frame does not match to the expected size (%0d)!", size0, size1));
            sb_error = 1;
            $display($sformatf("Frame size: %0d", size0));
            $display("Expected frame:");
            $display(size1);
            gm_trans.print_hex();
            $display("Received frame:");
            $display(size0);
            frm_trans.print_hex();
            // $display(sb_frm_mon_fifo.size());
            // $display(sb_gm_mon_fifo.size());
            //$stop;
         end
      endfunction: frm_compare
      
      virtual task timeout_check(string mark, int timeout, int step, ref bit stop);
         int cur_time = $stime;
         while (!stop) begin
            if (($stime - cur_time) < timeout) begin
               #(step);
            end else begin
               `uvm_error(mark, "ERR: transaction timeout!");
                //$stop;
               sb_error = 1;
               break;
            end
         end
      endtask: timeout_check

      virtual task cleanup();
         $display("SB cleanup");
         sb_frm_mon_fifo.flush();
         sb_gm_mon_fifo.flush();
      endtask: cleanup
   endclass: nnfpga_uvm_scoreboard
endpackage: nnfpga_uvm_scoreboard_pkg