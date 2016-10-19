//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

package nnfpga_uvm_pkg;
   `include "tb_parameters.svh"

   typedef logic unsigned [7:0] data_t[$];

   function int str2hex (string str);
      int offset;

      str2hex = 0;

      if (str.len() > 8) begin
         $error("The string is too long!");
         return -1;
      end else begin
         for (int i = (str.len() - 1); i >= 0; i--) begin
            if ((str[i] > 47) && (str[i] < 58)) begin
               offset = 48;
            end else if ((str[i] > 96) && (str[i] < 103)) begin
               offset = 87;
            end else begin
               $error("A symbol is not valid for hex!");
               return -2;
            end

            str2hex += (str[i] - offset) * (16 ** ((str.len() - 1) - i));
         end
      end
   endfunction: str2hex
endpackage: nnfpga_uvm_pkg