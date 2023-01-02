`include "SOC/registerfile.v"

module CPU(
      input  wire        clk,
      input  wire        reset,
      output reg  [63:0] mem_addr,
      inout       [63:0] mem_data,
      output wire [63:0]  LED,
      output reg         rw
);
   reg  [63:0] pc     = 0;
   reg  [31:0] instr  = 0;
   reg  [31:0] mdata  = 0;
   wire [4:0]  rs1    = instr[19:15];
   wire [4:0]  rs2    = instr[24:20];
   wire [4:0]  rd     = instr[11: 7];
   wire [63:0] rs1_data;
   wire [63:0] rs2_data;
   reg  [63:0] rd_data  = 0;
   reg         write_rd = 0;
   assign      mem_data = rw ? mdata : 'bz;

   RegisterFile regitserfile(
      .clk(clk),
      .rd(rd),
      .write_data(rd_data),
      .we(write_rd),
      .rs1(rs1),
      .data1(rs1_data),
      .rs2(rs2),
      .data2(rs2_data)
   );

   //       1111111000100000100111101_1100011

   wire isALUreg =  (instr[6:0] == 7'b0110011); // rd <- rs1 OP rs2   
   wire isALUimm =  (instr[6:0] == 7'b0010011); // rd <- rs1 OP Iimm
   wire isBranch =  (instr[6:0] == 7'b1100011); // if(rs1 OP rs2) PC<-PC+Bimm
   wire isJALR   =  (instr[6:0] == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm
   wire isJAL    =  (instr[6:0] == 7'b1101111); // rd <- PC+4; PC<-PC+Jimm
   wire isAUIPC  =  (instr[6:0] == 7'b0010111); // rd <- PC + Uimm
   wire isLUI    =  (instr[6:0] == 7'b0110111); // rd <- Uimm   
   wire isLoad   =  (instr[6:0] == 7'b0000011); // rd <- mem[rs1+Iimm]
   wire isStore  =  (instr[6:0] == 7'b0100011); // mem[rs1+Simm] <- rs2
   wire isSYSTEM =  (instr[6:0] == 7'b1110011); // special

   wire [2:0] funct3 = instr[14:12];
   wire [6:0] funct7 = instr[31:25];

   wire [31:0] Uimm = {    instr[31],   instr[30:12], {12{1'b0}}};
   wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]};
   wire [31:0] Simm = {{21{instr[31]}}, instr[30:25],instr[11:7]};

   localparam READ  = 0;
   localparam WRITE = 1;
   reg takeBranch;

   wire [31:0] aluIn2 = isALUreg ? rs2_data : Iimm;
   wire [4:0] shamt = isALUreg ? rs2[4:0] : instr[24:20]; // shift amount

   // ADD(x10,x0,x0);
   localparam FETCH_INSTR = 0;
   localparam WAIT_INSTR  = 1;
   localparam WAIT_DATA   = 2;
   localparam EXECUTE     = 3;
   reg [2:0] state = FETCH_INSTR;
   always @(posedge clk) begin
      case(state)
         FETCH_INSTR: begin
            write_rd <= 0;
            mem_addr <= pc;
            rw       <= READ;
            state    <= WAIT_INSTR;
         end
         WAIT_INSTR: begin
            instr <= pc[2] ? mem_data[63:32] : mem_data[31:0];
            state <= WAIT_DATA;
         end
         WAIT_DATA: begin
            state <= EXECUTE;
         end
         EXECUTE: begin
            if (isALUreg || isALUimm) begin
               case(funct3)
                  3'b000: rd_data <= (funct7[5] & instr[5]) ? 
                     (rs1_data - aluIn2) : (rs1_data + aluIn2);
                  3'b001: rd_data <= rs1_data << shamt;
                  3'b010: rd_data <= ($signed(rs1_data) < $signed(aluIn2));
                  3'b011: rd_data <= (rs1_data < aluIn2);
                  3'b100: rd_data <= (rs1_data ^ aluIn2);
                  3'b101: rd_data <= funct7[5]? ($signed(rs1_data) >>> shamt) : 
                     ($signed(rs1_data) >> shamt); 
                  3'b110: rd_data <= (rs1_data | aluIn2);
                  3'b111: rd_data <= (rs1_data & aluIn2); 
               endcase

               write_rd <= 1;
               pc <= pc + 4;
            end else if (isJAL) begin
               rd_data <= pc;
               write_rd <= 1;
               pc <= pc + {{44{instr[31]}}, instr[19:12],instr[20],instr[30:21],1'b0}; // Jmm
            end else if (isJALR) begin
               rd_data <= pc;
               write_rd <= 1;
               pc <= pc + rs1 + Iimm;
            end else if (isLUI) begin
               rd_data <= Uimm;
               write_rd <= 1;
               pc <= pc + 4;
            end else if (isAUIPC) begin
               rd_data <= Uimm;
               write_rd <= 1;
               pc <= pc + Uimm;
            end else if (isBranch) begin
               if (takeBranch)
                  pc = pc + {{52{instr[31]}}, instr[7],instr[30:25],instr[11:8],1'b0};
               else 
                  pc = pc + 4;
            end
`ifdef BENCH
            else if(isSYSTEM) begin
               $display("Finished correctly");
               $finish;
            end
`endif
            else begin
               pc <= pc + 4;
            end

            state <= FETCH_INSTR;
         end
      endcase
   end

   always @(*) begin
      case(funct3)
         3'b000: takeBranch = (rs1_data == rs2_data);
         3'b001: takeBranch = (rs1_data != rs2_data);
         3'b100: takeBranch = ($signed(rs1_data) < $signed(rs2_data));
         3'b101: takeBranch = ($signed(rs1_data) >= $signed(rs2_data));
         3'b110: takeBranch = (rs1_data < rs2_data);
         3'b111: takeBranch = (rs1_data >= rs2_data);
         default: takeBranch = 1'b0;
      endcase
   end

   assign LED = pc;
endmodule
