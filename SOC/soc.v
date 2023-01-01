/**
 * Achieve Core 
 * Created by Cyao on 31 Decenber 2022
 */

`default_nettype none

`include "SOC/memory.v"
`include "SOC/registerfile.v"
`include "SOC/CPU.v"

module SOC (
   input  clk,
   input  reset
);
   wire [63:0] mem_addr;
   wire [63:0] mem_data;
   wire        rw;

   CPU cpu(
      .clk(clk),
      .reset(reset),
      .mem_addr(mem_addr),
      .mem_data(mem_data),
      .rw(rw)
   );

   Memory memory(
      .clk(clk),
      .addr(mem_addr),
      .data(mem_data),
      .rw(rw)
   );
endmodule
