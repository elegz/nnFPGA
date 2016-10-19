//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

`timescale 1ns / 10ps
`include "uvm_macros.svh"
//`include "nnfpga_uvm_defines.svh"

package nnfpga_uvm_sequence_pkg;
   import uvm_pkg::*;
   import nnfpga_uvm_transaction_pkg::*;

   parameter END_TIME = 1000000;

   class file_sequence # (type REQ, parameter string FILE_NAME) extends uvm_sequence # (REQ);
      `uvm_object_param_utils(file_sequence #(REQ, FILE_NAME))

      int seq_id = 0;

      protected int width;
      protected int height;

      function new (string name = "file_sequence");
         super.new(name);
         seq_id = 0;
      endfunction: new

      virtual task body();
         int      file_id;
         int      rd_code;
         string   trans;
         int      trans_count = 0;
         int      start_time  = $time;

         file_id = $fopen(FILE_NAME, "r");
         if (!file_id) `uvm_error("UVM_ERR", "Can not open file");

         rd_code = $fgets(width, file_id);
         rd_code = $fgets(height, file_id);

         while (1) begin
            rd_code = $fgets(trans, file_id);
            if ((trans == "") || (($time - start_time) >= END_TIME)) begin
               `uvm_info("Sequence", $sformatf("The number of the transactions sent: %0d.", trans_count), UVM_LOW);
               break;
            end
            trans_count++;
            req = REQ::type_id::create(.name("req"), .contxt(get_full_name()));
            start_item(req);
               req.randomize();
               req.create_from_string(trans);
               req.frame.width   = width;
               req.frame.height  = height;
               req.seq_id        = seq_id;
            finish_item(req);
         end

         $fclose(file_id);
      endtask: body
   endclass: file_sequence
endpackage: nnfpga_uvm_sequence_pkg