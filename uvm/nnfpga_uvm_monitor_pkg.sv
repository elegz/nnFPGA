//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_monitor_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;
   import nnfpga_uvm_pkg::*;
   //import nnfpga_uvm_if_lib::*;

   class frm_bus_monitor # (type TRANS_TYPE = frame_transaction, DATA_WIDTH) extends uvm_monitor;
      `uvm_component_param_utils(frm_bus_monitor # (TRANS_TYPE, DATA_WIDTH))

      localparam WORD_SIZE = (DATA_WIDTH + 7) / 8;

      event reset_monitor;
      int   frame_width;
      int   frame_height;

      uvm_analysis_port # (TRANS_TYPE) frm_bus_mon;

      protected virtual tb_main_if              tb_vif;
      protected virtual frm_if # (DATA_WIDTH)   vif;
      protected         TRANS_TYPE              trans_collected;

      function new(string name, uvm_component parent);
         super.new(name, parent);
      endfunction: new

      function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         void'(uvm_resource_db #(virtual tb_main_if)::read_by_name(.scope("ifs"), .name("main_vif"), .val(tb_vif)));
         uvm_config_db #(virtual frm_if # (DATA_WIDTH))::get(this,"","frm_if",vif);
         frm_bus_mon = new(.name("frm_bus_mon"), .parent(this));
      endfunction: build_phase

      virtual task run_phase(uvm_phase phase);
         forever begin
            fork
               begin
                  data_t word_queue;
                  int loop_key;

                  @(negedge tb_vif.reset);
                  forever begin
                     word_queue  = {};

                     @(posedge vif.frame_start);
                     while (word_queue.size() != (frame_width * frame_height * WORD_SIZE)) begin
                        @(posedge vif.clk);
                        if (vif.valid) begin
                           word_queue = {word_queue, data_t'(vif.data)};
                        end
                     end
                     trans_collected = TRANS_TYPE::type_id::create(.name("trans_collected"), .contxt(get_full_name()));
                     trans_collected.create_from_stream(word_queue);
                     frm_bus_mon.write(trans_collected);
                     // $display("FRM trans_collected");
                     // trans_collected.print_hex();
                  end
               end
            join_none

            @(reset_monitor);
            disable fork;
            cleanup();
         end
      endtask: run_phase

      virtual task cleanup();
         $display("FRM BUS cleanup");
         trans_collected = {};
      endtask: cleanup
   endclass: frm_bus_monitor

   class gm_monitor # (type TRANS_TYPE = frame_transaction, parameter string FILE_NAME) extends uvm_monitor;
      `uvm_component_param_utils(gm_monitor #(TRANS_TYPE, FILE_NAME))

      uvm_analysis_port # (TRANS_TYPE) gm_mon;

      event reset_monitor;

      protected virtual tb_main_if  vif;
      protected         TRANS_TYPE  trans_generated;
      protected         int         width;
      protected         int         height;
      protected         int         file_id;
      protected         int         rd_code;
      protected         string      trans;
      protected         int         trans_count;

      function new(string name, uvm_component parent);
         super.new(name, parent);
      endfunction: new

      function void build_phase(uvm_phase phase);
         super.build_phase(phase);
         void'(uvm_resource_db #(virtual tb_main_if)::read_by_name(.scope("ifs"), .name("main_vif"), .val(vif)));
         gm_mon = new(.name("gm_mon"), .parent(this));
      endfunction: build_phase

      virtual task run_phase(uvm_phase phase);
         forever begin
            @(negedge vif.reset);
            trans_count = 0;
            file_id     = $fopen(FILE_NAME, "r");
            if (!file_id) `uvm_error("UVM_ERR", "Can not open file");
            rd_code     = $fgets(width, file_id);
            rd_code     = $fgets(height, file_id);

            while (1) begin
               rd_code = $fgets(trans, file_id);
               trans_count++;
               if ((trans == "")) begin
                  `uvm_info("Sequence", $sformatf("The number of the GM transactions sent: %0d.", trans_count), UVM_LOW);
                  break;
               end else begin
                  trans_generated = TRANS_TYPE::type_id::create(.name("trans_generated"), .contxt(get_full_name()));
                  trans_generated.create_from_string(trans);
                  trans_generated.frame.width   = width;
                  trans_generated.frame.height  = height;
                  gm_mon.write(trans_generated);
                  // $display("GM");
                  // $display(trans_generated);
               end
            end

            $fclose(file_id);
         end
      endtask: run_phase

      virtual task cleanup();
         $display("GM cleanup");
         trans_generated = TRANS_TYPE::type_id::create(.name("trans_generated"), .contxt(get_full_name()));
      endtask: cleanup
   endclass: gm_monitor
endpackage: nnfpga_uvm_monitor_pkg