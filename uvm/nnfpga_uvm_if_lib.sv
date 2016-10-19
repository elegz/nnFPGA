//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

interface tb_main_if;
   logic clk;
   logic reset;
endinterface: tb_main_if

interface frm_if # (DATA_WIDTH = 8) (input wire clk);
   logic [DATA_WIDTH-1:0]  data;
   logic                   valid;
   logic                   frame_start; 
endinterface: frm_if