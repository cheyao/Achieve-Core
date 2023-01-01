module RegisterFile(
   input  wire        clk,
   input  wire [4:0]  rd,
   output reg  [63:0] write_data,
   input  wire        we,
   input  wire [4:0]  rs1,
   output reg  [63:0] data1,
   input  wire [4:0]  rs2,
   output reg  [63:0] data2
);
   reg [63:0] registers [0:4];

   initial begin
      for (i = 0; i < 32; i = i + 1)
         registers[i] = 0;
   end

   always @(posedge clk) begin
      if (we)
         registers[rd] <= write_data; 

      data1 <= registers[rs1];
      data2 <= registers[rs2];
   end
endmodule
