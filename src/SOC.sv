/**
 * Achieve Core 
 * Created by Cyao on 31 Decenber 2022
 */
`default_nettype none

`include "src/Memory.sv"
`include "src/ROM.sv"
`include "src/CPU.sv"

module SOC (
    input             clk,
    input             reset,
    output reg [63:0] data, // Max word
    output reg [31:0] port,
    output wire       isIO,
    output wire [3:0] size,
    output wire       rw
);
   wire [63:0] mem_addr;
   wire   isBIOS = mem_addr[63:16] == 48'hFFFFFFFFFFFF;
   assign isIO   = mem_addr[63:32] == 32'hFFFFFFFF & !isBIOS;
   wire   isRAM  = !isIO;

   assign port = mem_addr[31:0];

   CPU cpu(
      .clk(clk),
      .reset(reset),
      .mem_addr(mem_addr),
      .mem_data(data),
      .size(size),
      .rw(rw)
   );

   Memory memory( // (Should be) Extern memory
      .clk(clk),
      .addr(mem_addr[23:0]),
      .data(data),
      .size(size),
      .rw(rw),
      .enable(isRAM) // Don't write on IO
   );

   ROM BIOS(
      .clk(clk),
      .addr(mem_addr[15:3]),
      .data(data),
      .enable(isBIOS) // Don't write on IO
   );
endmodule
