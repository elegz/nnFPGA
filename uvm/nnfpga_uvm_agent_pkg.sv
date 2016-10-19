//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_agent_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;
   import nnfpga_uvm_driver_pkg::*;
   import nnfpga_uvm_monitor_pkg::*;
   //import nnfpga_uvm_if_lib::*;
   import nnfpga_uvm_pkg::*;

   class frame_agent extends uvm_agent;
      uvm_analysis_port # (frame_transaction) agnt_frm_mon_port;
      uvm_analysis_port # (frame_transaction) agnt_gm_mon_port;

      uvm_sequencer # (.REQ(frame_transaction))                                     sequencer;
      frm_bus_driver  # (.TRANS_TYPE(frame_transaction), .DATA_WIDTH(DATA_WIDTH))   driver;
      frm_bus_monitor # (.TRANS_TYPE(frame_transaction), .DATA_WIDTH(DATA_WIDTH))   frm_mon;
      gm_monitor # (.FILE_NAME(GM_FILE))                                            gm_mon;

      `uvm_component_utils(frame_agent)

      function new (string name, uvm_component parent);
         super.new(name, parent);
      endfunction: new

      function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         agnt_frm_mon_port   = new(.name("agnt_frm_mon_port"), .parent(this));
         agnt_gm_mon_port    = new(.name("agnt_gm_mon_port"), .parent(this));

         frm_mon              = frm_bus_monitor # (.TRANS_TYPE(frame_transaction), .DATA_WIDTH(DATA_WIDTH))::type_id::create("frm_mon", this);
         frm_mon.frame_width  = FRAME_WIDTH;
         frm_mon.frame_height = FRAME_HEIGHT;
         gm_mon               = gm_monitor # (.FILE_NAME(GM_FILE))::type_id::create("gm_mon", this);

         if(get_is_active() == UVM_ACTIVE) begin
            sequencer = uvm_sequencer # (.REQ(frame_transaction))::type_id::create("sequencer", this);
            driver    = frm_bus_driver  # (.TRANS_TYPE(frame_transaction), .DATA_WIDTH(DATA_WIDTH))::type_id::create("driver", this);
         end
      endfunction: build_phase

      function void connect_phase(uvm_phase phase);
         super.connect_phase(phase);
         frm_mon.out_port.connect(agnt_frm_mon_port);
         gm_mon.out_port.connect(agnt_gm_mon_port);

         if(get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
         end
      endfunction: connect_phase

      virtual task pre_reset_phase(uvm_phase phase);
         $display("Agent prereset");
         if (sequencer && driver) begin
            sequencer.stop_sequences();
            ->driver.reset_driver;
         end
         if (frm_mon) begin
            ->frm_mon.reset_monitor;
         end
         if (gm_mon) begin
            ->gm_mon.reset_monitor;
         end
      endtask: pre_reset_phase
   endclass: frame_agent
endpackage: nnfpga_uvm_agent_pkg