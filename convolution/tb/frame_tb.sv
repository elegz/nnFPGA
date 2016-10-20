//(c) Aleksandr Kotelnikov, al.kotelnikov@gmail.com
`timescale 1ns/10ps
`include "nnfpga_uvm_if_lib.sv"

module main;
   import uvm_pkg::*;
   import nnfpga_uvm_pkg::*;
   import nnfpga_uvm_test_pkg::*;

   int sim_status = 0;

   tb_main_if                           main_vif ();
   frm_if # (DATA_WIDTH(DATA_WIDTH))    master_frm_bus (.clk(main_vif.clk));
   frm_if # (DATA_WIDTH(DATA_WIDTH))    slave_frm_bus (.clk(main_vif.clk));

   initial begin: variables_ini
      main_vif.clk       = '0;
      main_vif.reset      = '1;
      //#(RESET_T);
      //main_vif.reset      = '0;
   end: variables_ini

   always begin: clk_generating
      #(GCLK_T/2);
      main_vif.clk = ~main_vif.clk;
   end: clk_generating

   //Connects the Interfaces to the DUT
   dut dut_inst (
      .main_if          (main_vif),
      .slave_frm_bus    (master_frm_bus),
      .master_frm_bus   (slave_frm_bus)
   );

   initial begin: test_instance
      //registers the Interfaces in the configuration block so that other blocks can use it
      uvm_resource_db # (virtual tb_main_if)::set(.scope("ifs"), .name("main_vif"), .val(main_vif));
      uvm_resource_db # (int)::set(.scope("flags"), .name("sim_status"), .val(sim_status));
      uvm_config_db # (virtual xgmii_if)::set(null, "*driver","frm_if", master_frm_bus);
      uvm_config_db # (virtual xgmii_if)::set(null, "*frm_mon","frm_if", slave_frm_bus);
      //executes the test
      run_test(); //requires test name option in the sumulator run command
   end: test_instance
endmodule: main