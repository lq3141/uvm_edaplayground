`include "uvm_macros.svh"
import uvm_pkg::*;

`include "ral.sv"
`include "env.sv"
`include "test.sv"

module tb;
	bit pclk;
   always #10 pclk = ~pclk;

   bus_if   _if (pclk);

   traffic  DUT ( .pclk    (_if.pclk),
                  .presetn (_if.presetn),
                  .paddr   (_if.paddr),
                  .pwdata  (_if.pwdata),
                  .prdata  (_if.prdata),
                  .psel    (_if.psel),
                  .pwrite  (_if.pwrite),
                  .penable (_if.penable));

   initial begin 
      uvm_config_db #(virtual bus_if)::set (null, "uvm_test_top.*", "bus_if", _if);
     run_test ("reg_backdoor_test");
   end
  
  initial begin
    $dumpvars;
    $dumpfile("dump.vcd");
  end

endmodule
