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
   integer wait_ = 20;
   integer L1_   = 28;
   
   initial begin
      ADD(x10,x0,x0);
   Label(L0_); 
      ADDI(x10,x10,1);
      JAL(x1,LabelRef(wait_)); // call(wait_)
      JAL(zero,LabelRef(L0_)); // jump(l0_)
      
      EBREAK(); // I keep it systematically
                // here in case I change the program.

   Label(wait_);
      ADDI(x11,x0,1);
      SLLI(x11,x11,slow_bit);
   Label(L1_);
      ADDI(x11,x11,-1);
      BNE(x11,x0,LabelRef(L1_));
      JALR(x0,x1,0);   
     
      endASM();
   end

   always @(posedge clk) begin
      if (rw) begin // Write
         MEM[addr] <= data;
      end else begin // Read
         d <= MEM[addr];
      end
   end

   assign data = rw ? 'bz : d;
endmodule
