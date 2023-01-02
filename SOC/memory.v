module Memory(
   input        clk,
   input [63:0] addr,
   inout [63:0] data,
   input        rw
);
   reg [63:0] MEM [0:255];
   reg [63:0] d;

   `include "SOC/riscv_assembly.v"
   initial begin
      MEM[0] = {32'h02000113, 32'h000000b3};
      MEM[1] = {32'hfe209ee3, 32'h00108093};
      MEM[2] = {32'h00000000, 32'h00100073};
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
