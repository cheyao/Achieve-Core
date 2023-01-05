module Memory(
   input        clk,
   input [23:3] addr,
   inout [63:0] data,
   input [ 7:0] mask,
   input        rw
);
   reg [63:0] MEM [0:1048576]; // 1Mib of ram
   reg [63:0] d;

   initial begin
      $readmemh("Achieve-BIOS/AchieveBIOS.hex", MEM);
   end

   always @(negedge clk) begin
      if (rw) begin // Write
         if(mask[0]) MEM[addr[23:3]][ 7: 0] <= data[ 7: 0];
         if(mask[1]) MEM[addr[23:3]][15: 8] <= data[15: 8];
         
         if(mask[2]) MEM[addr[23:3]][23:16] <= data[23:16];
         if(mask[3]) MEM[addr[23:3]][31:24] <= data[31:24]; 

         if(mask[4]) MEM[addr[23:3]][39:32] <= data[39:32];
         if(mask[5]) MEM[addr[23:3]][47:40] <= data[47:40];

         if(mask[6]) MEM[addr[23:3]][55:48] <= data[55:48];
         if(mask[7]) MEM[addr[23:3]][63:56] <= data[63:56]; 
      end else begin // Read
         d <= MEM[addr[23:3]];
      end
   end

   assign data = rw ? 64'bz : d;
endmodule
