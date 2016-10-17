module fifo # (
   DATA_WIDTH = 8,
   DATA_SIZE  = 7
) (
   input    wire       clk,
   input    wire       reset,
   input    wire       wre,
   input    wire [7:0] data_in,
   input    wire       rde,
   output   wire [7:0] data_out
);
   //here sould be macro to generate fifo or FPGA vendor IP-core
endmodule: fifo