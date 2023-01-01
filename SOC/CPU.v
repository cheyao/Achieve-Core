module CPU(
      input  wire        clk,
      input  wire        reset,
      output reg  [63:0] mem_addr,
      inout       [63:0] mem_data,
      output reg         rw
);
   reg  [63:0] pc    = 0;
   reg  [31:0] instr = 0;
   reg  [31:0] mdata = 0;
   wire [4:0]  rs1   = instr[19:15];
   wire [4:0]  rs2   = instr[24:20];
   wire [4:0]  rd    = instr[11: 7];
   assign mem_data = rw ? mdata : 'bz ;

   localparam READ = 0;
   localparam WRITE = 1;

   // ADD(x10,x0,x0);
   localparam FETCH_INSTR = 0;
   localparam WAIT_INSTR  = 1;
   localparam FETCH_REGS  = 2;
   localparam EXECUTE     = 3;
   localparam LOAD        = 4;
   localparam WAIT_DATA   = 5;
   reg [2:0] state = FETCH_INSTR;
   always @(posedge clk) begin
      case(state)
         FETCH_INSTR: begin
            mem_addr = 0;
            rw = READ;
         end
         WAIT_INSTR: begin

         end
         FETCH_REGS: begin
            
         end
         EXECUTE: begin

         end
         LOAD: begin

         end
         WAIT_DATA: begin

         end
      endcase
   end

   initial begin
      pc = 0;
   end

   RegisterFile regitserfile(
      .clk(clk),
      .rd(rd),
      .write_data(),
      .we(),
      .rs1(rs1),
      .data1(),
      .rs2(rs2),
      .data2()
   );
endmodule
