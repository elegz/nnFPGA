//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_driver_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;

   class frm_bus_driver # (type TRANS_TYPE = frame_transaction, parameter DATA_WIDTH) extends uvm_driver # (TRANS_TYPE);
      `uvm_component_param_utils(frm_bus_driver # (TRANS_TYPE, DATA_WIDTH))

      localparam WORD_SIZE = (DATA_WIDTH + 7) / 8;

      event reset_driver;
      int   int_gap_min;
      int   int_gap_max;

      protected virtual frm_if # (.DATA_WIDTH(DATA_WIDTH)) vif;

      function new (string name, uvm_component parent);
         super.new(name, parent);
         int_gap_min = 3;
         int_gap_max = 5;         
      endfunction: new

      function void build_phase (uvm_phase phase);
         super.build_phase(phase);
         uvm_config_db #(virtual frm_if # (.DATA_WIDTH(DATA_WIDTH)))::get(this,"","frm_if",vif);
      endfunction: build_phase

      virtual task run_reset_phase (uvm_phase phase);
         phase.raise_objection(this);
            vif.data          = '0;
            vif.valid         = '0;
            vif.frame_start   = '0;
         phase.drop_objection(this);
      endtask: run_reset_phase

      virtual task run_phase (uvm_phase phase);
         forever begin
            fork
               forever begin
                  seq_item_port.get_next_item(req);
                  drive_item(req);
                  seq_item_port.item_done();
               end
            join_none

            @(reset_driver);
            disable fork;
            cleanup();
         end
      endtask: run_phase

      virtual protected task drive_item (TRANS_TYPE item);
         send_frame_start();
         transfer_pause($urandom_range(int_gap_max, int_gap_min));
         send_data(item);
         transfer_pause(item.gap);
      endtask: drive_item

      virtual protected task send_frame_start ();
         @(posedge vif.clk);
         vif.valid         = '0;
         vif.frame_start   = '1;
         @(posedge vif.clk);
         vif.frame_start   = '0;
      endtask: send_frame_start

      virtual protected task send_data (TRANS_TYPE item);
         for (int i = 0; i < item.frame.height; i++) begin
            for (int j = 0; j < item.frame.width; j++) begin
               @(posedge vif.clk);
               vif.data    = item.frame.data[(i*item.frame.width*WORD_SIZE+j*WORD_SIZE)+:WORD_SIZE];
               vif.valid   = '1;
            end
            transfer_pause($urandom_range(int_gap_max, int_gap_min));
         end
      endtask: send_data

      virtual protected task transfer_pause (int duration);
         for (int i = 0; i < duration; i++) begin
            @(posedge vif.clk);
            vif.valid = '0;
         end
      endtask: transfer_pause

      virtual protected function void cleanup ();
         vif.data          = '0;
         vif.valid         = '0;
         vif.frame_start   = '0;
      endfunction: cleanup
   endclass: frm_bus_driver
endpackage: nnfpga_uvm_driver_pkg