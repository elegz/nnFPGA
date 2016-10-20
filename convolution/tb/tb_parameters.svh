//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com

parameter FRAME_H_MAX   = 224;
parameter FRAME_W_MAX   = 224;
parameter STRIDE_MAX    = 4;
parameter DIN_WIDTH     = 8;
parameter DOUT_WIDTH    = 8;
parameter KERN_WIDTH    = 16;
parameter WIN_SIZE      = 3;
parameter CHANNELS_IN   = 1;
parameter CHANNELS_OUT  = 1;
parameter KERNEL        = {}; //fill
parameter FRAME_H       = 13;
parameter FRAME_W       = 13;
parameter STRIDE        = 1;
parameter GCLK_T        = 4;
parameter RESET_T       = 100;
parameter DATA_WIDTH    = 8;
parameter RESET_CYCLES  = 100;
parameter TRANS_TIMEOUT = 100;

parameter string FRM_FILE  = ""; //fill
parameter string GM_FILE   = ""; //fill