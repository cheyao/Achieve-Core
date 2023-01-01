`define BENCH

`include "SOC/soc.v"

module bench();
   reg clk;
   wire reset = 0; 
   wire [63:0] addr;
   wire [63:0] data;

   initial begin
      clk = 0;
      #500 $finish;
   end

   always begin
	   #1 clk = ~clk;
   end

   SOC soc(
      .clk(clk),
      .reset(reset)
   );
endmodule  
