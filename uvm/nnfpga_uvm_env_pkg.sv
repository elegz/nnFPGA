//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_env_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;
   import nnfpga_uvm_agent_pkg::*;
   import nnfpga_uvm_scoreboard_pkg::*;
   import nnfpga_uvm_pkg::*;

   class frame_env extends uvm_env;
      `uvm_component_utils(frame_env)

      frame_agent             frm_agnt;
      nnfpga_uvm_scoreboard   sb;

      function new(string name, uvm_component parent);
         super.new(name, parent);
      endfunction: new

      function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         frm_agnt = frame_agent::type_id::create(.name("frm_agnt"), .parent(this));
         sb       = nnfpga_uvm_scoreboard::type_id::create(.name("sb"), .parent(this));
      endfunction: build_phase

      function void connect_phase(uvm_phase phase);
         super.connect_phase(phase);
         frm_agnt.frm_mon_port.connect(sb.frm_mon_export);
         frm_agnt.gm_mon_port.connect(sb.gm_mon_export);
      endfunction: connect_phase
   endclass: frame_env
endpackage: nnfpga_uvm_env_pkg