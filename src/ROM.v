// 0xFFFFFFFFFFFFF0000 - 0xFFFFFFFFFFFFFFFF 
module ROM(
   input        clk,
   input [15:3] addr,
   inout [63:0] data,
   input        enable
);
   reg [63:0] ROM [0:8191];
   reg [63:0] d;

   initial begin
      $readmemh("Achieve-BIOS/AchieveBIOS.hex", ROM);
   end

   always @(posedge clk) begin
      d <= ROM[addr[15:3]];
   end

   assign data = !enable ? 64'bz : d;
endmodule
