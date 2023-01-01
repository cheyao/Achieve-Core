module Memory(
   input        clk,
   input [63:0] addr,
   inout [63:0] data,
   input        rw
);
   reg [31:0] MEM [0:255];
   reg [31:0] d;

`include "SOC/riscv_assembly.v"
   integer L0_   = 4;
   integer wait_ = 24;
   integer L1_   = 32;
   
   initial begin
      ADDI(x10,x0,5);
      
      EBREAK();
   end

   always @(negedge clk) begin
      if (rw) begin // Write
         MEM[addr[63:3]] <= data;
      end else begin // Read
         d <= MEM[addr[63:3]];
      end
   end

   assign data = rw ? 'bz : d;
endmodule
