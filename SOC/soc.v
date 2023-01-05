/**
 * Achieve Core 
 * Created by Cyao on 31 Decenber 2022
 */

`default_nettype none

`include "SOC/Memory.v" 
`include "SOC/CPU.v"

module SOC (
   input             clk,
   input             reset,
   output reg [15:0] data, // Max word
   output reg [15:0] port,
   output wire       IOenable,
   output wire       rw
);
   /* verilator lint_off UNUSEDSIGNAL */
   wire [63:0] mem_addr; // TODO: Fix dis
   /* verilator lint_on UNUSEDSIGNAL */
   wire [63:0] mem_data;
   wire [ 7:0] mem_mask; 
   wire isIO  = mem_addr[63];
   wire isRAM = !isIO;

   assign data = rw ? mem_data[15:0] : 16'bz;
   assign port = mem_addr[15:0];
   assign IOenable = isIO;

   CPU cpu(
      .clk(clk),
      .reset(reset),
      .mem_addr(mem_addr),
      .mem_data(mem_data),
      .mem_mask(mem_mask),
      .rw(rw)
   ); 

   Memory memory( // (Should be) Extern memory
      .clk(clk),
      .addr(mem_addr[23:3]),
      .data(mem_data),
      .mask(mem_mask),
      .rw(isRAM & rw) // Don't write on IO
   );
endmodule
