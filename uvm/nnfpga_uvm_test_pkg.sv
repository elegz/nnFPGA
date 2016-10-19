//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_test_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_env_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;
   import nnfpga_uvm_sequence_pkg::*;
   import nnfpga_uvm_sequencer_pkg::*;
   //import nnfpga_uvm_if_lib::*;
   import nnfpga_uvm_pkg::*;

   class nnfpga_uvm_test extends uvm_test;
      `uvm_component_utils(nnfpga_uvm_test)

      nnfpga_uvm_env    nnfpga_env;
      uvm_table_printer printer;
      int               sim_status  = 0;

      protected virtual tb_main_if vif;

      function new(string name, uvm_component parent);
         super.new(name, parent);
      endfunction: new

      virtual function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         // Enable transaction recording for everything
         uvm_config_db#(int)::set(this, "*", "recording_detail", UVM_FULL);
         void'(uvm_resource_db #(virtual tb_main_if)::read_by_name(.scope("ifs"), .name("main_vif"), .val(vif)));
         void'(uvm_resource_db #(int)::read_by_name(.scope("flags"), .name("sim_status"), .val(sim_status)));

         nnfpga_env = nnfpga_uvm_env::type_id::create(.name("nnfpga_env"), .parent(this));

         // Create a specific depth printer for printing the created topology
         printer = new();
         printer.knobs.depth = 3;
      endfunction: build_phase

      virtual function void end_of_elaboration_phase(uvm_phase phase);
         // Set verbosity for the monitors
         // if (env.agent != null) begin
         //    env.agent.set_report_verbosity_level(UVM_FULL);
         // end
         uvm_top.set_report_verbosity_level_hier(UVM_FULL);
         //uvm_top.enable_print_topology = 1;
         //uvm_top.print_topology(printer);
         `uvm_info(get_type_name(), $sformatf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
      endfunction: end_of_elaboration_phase

      virtual task reset_phase(uvm_phase phase);
         //reg_block.REG_BLOCK.reset("HARD");
         phase.raise_objection(this);
            @(posedge vif.clk);
            vif.reset_n = '0;
            #(RESET_T/2);
            if(nnfpga_env.nnfpga_sb) begin
               ->nnfpga_env.nnfpga_sb.reset_scoreboard;
            end
            #(RESET_T/2);
            vif.reset_n = '1;
         phase.drop_objection(this);
      endtask: reset_phase

      virtual task main_phase(uvm_phase phase);
         file_sequence # (.REQ(frame_trans), .FILE_NAME(FRM_FILE)) frm_seq;
         file_sequence # (.REQ(frame_trans), .FILE_NAME(GM_FILE))  gm_seq;
         
         bit frm_seq_end;
         bit gm_seq_end;

         phase.raise_objection(.obj(this));
            frm_seq = file_sequence # (.REQ(frame_trans), .FILE_NAME(FRM_FILE))::type_id::create(.name("frm_seq")), .contxt(get_full_name()));
            gm_seq  = file_sequence # (.REQ(simple_eth_trans), .FILE_NAME(MDP_FILE))::type_id::create(.name("gm_seq")), .contxt(get_full_name()));

            frm_seq.seq_id = 0;
            gm_seq.seq_id  = 1;

            frm_seq_end = '0;
            gm_seq_end  = '0;

            fork
               begin
                  frm_seq.start(nnfpga_env.frm_agnt.sequencer);
                  frm_seq_end = '1;
               end
               begin
                  gm_seq.start(nnfpga_env.frm_agnt.sequencer);
                  gm_seq_end = '1;
               end
            join_none

            //@(frm_seq_end or gm_seq_end);
            wait(&{frm_seq_end, gm_seq_end});
            #10000;
         phase.drop_objection(.obj(this));
      endtask: main_phase

      virtual function void extract_phase(uvm_phase phase);
         if (nnfpga_env.nnfpga_sb.sb_error) begin
            sim_status = 1;
         end
      endfunction: extract_phase

      virtual function void report_phase(uvm_phase phase);
         if(sim_status) begin
            `uvm_error(get_type_name(), "** NNFPGA TEST FAIL **")
         end else begin
            `uvm_info(get_type_name(), "** NNFPGA TEST PASSED **", UVM_NONE)
         end
         //$stop;
      endfunction: report_phase
   endclass: nnfpga_uvm_test

   class nnfpga_uvm_onfly_reset_test extends nnfpga_uvm_test;
      `uvm_component_utils(nnfpga_uvm_onfly_reset_test)
      int unsigned   reset_delay;

      int unsigned   i = 0;

      function new(string name, uvm_component parent);
         super.new(name, parent);
      endfunction: new

      virtual function void build_phase(uvm_phase phase);
         super.build_phase(phase);
      endfunction: build_phase

      virtual function void end_of_elaboration_phase(uvm_phase phase);
         super.end_of_elaboration_phase(phase);
      endfunction: end_of_elaboration_phase

      virtual task reset_phase(uvm_phase phase);
         super.reset_phase(phase);
      endtask: reset_phase

      virtual task main_phase(uvm_phase phase);
         fork
            super.main_phase(phase);
         join_none

         if (i < RESET_CYCLES) begin
            phase.raise_objection(this);
               std::randomize(reset_delay) with { reset_delay inside {[1000:4000]}; };
               #(reset_delay);
            phase.drop_objection(this);
            phase.get_objection().set_report_severity_id_override(UVM_WARNING, "OBJTN_CLEAR", UVM_INFO);
            phase.jump(uvm_pre_reset_phase::get());
            i++;
         end else begin
            phase.get_objection().set_report_severity_id_override(UVM_WARNING, "OBJTN_CLEAR", UVM_INFO);
            phase.jump(uvm_extract_phase::get());
         end
      endtask: main_phase

      virtual function void extract_phase(uvm_phase phase);
         super.extract_phase(phase);
      endfunction: extract_phase

      virtual function void report_phase(uvm_phase phase);
         super.report_phase(phase);
      endfunction: report_phase
   endclass: nnfpga_uvm_onfly_reset_test
endpackage: nnfpga_uvm_test_pkg