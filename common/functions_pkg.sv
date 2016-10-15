//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
package functions_pkg;
   function integer clog2(input integer value);
      value -= 1;
      for (clog2 = 0; value > 0; clog2++) begin
         value = value >> 1;
      end
   endfunction: clog2
endpackage: functions_pkg