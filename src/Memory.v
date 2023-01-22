module Memory(
   input        clk,
   input [23:3] addr,
   inout [63:0] data,
   input [ 7:0] mask,
   input [ 2:0] shift,
   input        rw,
   input        enable
);
   reg [63:0] MEM [0:1048576]; // 1Mib of ram
   reg [63:0] d;
   wire [63:0] write_data = data << shift;

   always @(posedge clk) begin
      if (rw & enable) begin // Write
         if(mask[0]) MEM[addr[23:3]][ 7: 0] <= write_data[ 7: 0];
         if(mask[1]) MEM[addr[23:3]][15: 8] <= write_data[15: 8];
         if(mask[2]) MEM[addr[23:3]][23:16] <= write_data[23:16];
         if(mask[3]) MEM[addr[23:3]][31:24] <= write_data[31:24]; 
         if(mask[4]) MEM[addr[23:3]][39:32] <= write_data[39:32];
         if(mask[5]) MEM[addr[23:3]][47:40] <= write_data[47:40];
         if(mask[6]) MEM[addr[23:3]][55:48] <= write_data[55:48];
         if(mask[7]) MEM[addr[23:3]][63:56] <= write_data[63:56]; 
      end else begin // Read
         d <= MEM[addr[23:3]];
      end
   end

   assign data = rw | !enable ? 64'bz : d;
endmodule
