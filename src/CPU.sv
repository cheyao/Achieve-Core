// `define DEBUG
// `define NON_SYNTH

module CPU (
      input  wire        clk,
      input  wire        reset,
      output reg  [63:0] mem_addr,
      inout  wire [63:0] mem_data,
      output reg  [ 3:0] size,
      output reg         rw
);
   reg  [63:0] registers [1:31];

   wire isIO = mem_addr[63:32] == 32'hFFFFFFFF && mem_addr[31:16] != 16'hFFFF;

   reg  [63:0] pc     = 64'hFFFFFFFFFFFF0000;
   reg  [63:0] mdata  = 0;
   reg  [31:0] instr  = 0;
   wire [4:0]  rs1    = instr[19:15];
   wire [4:0]  rs2    = instr[24:20];
   wire [4:0]  rd     = instr[11: 7];
   wire [63:0] rs1_data = rs1 == 0 ? 64'b0 : registers[rs1];
   wire [63:0] rs2_data = rs2 == 0 ? 64'b0 : registers[rs2];
   assign      mem_data = rw ? mdata : 64'bz;
   wire [63:0] pcnext = pc + 4;

   wire isALUreg   = (instr[6:0] == 7'b0110011); // rd <- rs1 OP rs2   
   wire isALUreg32 = (instr[6:0] == 7'b0111011);
   wire isALUimm   = (instr[6:0] == 7'b0010011); // rd <- rs1 OP Iimm
   wire isALUimm32 = (instr[6:0] == 7'b0011011);
   wire isBranch   = (instr[6:0] == 7'b1100011); // if(rs1 OP rs2) PC<-PC+Bimm
   wire isJALR     = (instr[6:0] == 7'b1100111); // rd <- PC+4; PC<-rs1+Iimm
   wire isJAL      = (instr[6:0] == 7'b1101111); // rd <- PC+4; PC<-PC+Jimm
   wire isAUIPC    = (instr[6:0] == 7'b0010111); // rd <- PC + Uimm
   wire isLUI      = (instr[6:0] == 7'b0110111); // rd <- Uimm   
   wire isLoad     = (instr[6:0] == 7'b0000011); // rd <- mem[rs1+Iimm]
   wire isStore    = (instr[6:0] == 7'b0100011); // mem[rs1+Simm] <- rs2
   wire isSYSTEM   = (instr[6:0] == 7'b1110011); // special

   wire [2:0] funct3 = instr[14:12];
   /* verilator lint_off UNUSEDSIGNAL */
   wire [6:0] funct7 = instr[31:25];
   /* verilator lint_on UNUSEDSIGNAL */

   wire [63:0] Uimm = {{33{instr[31]}},   instr[30:12], {12{1'b0}}};
   wire [63:0] Iimm = {{53{instr[31]}}, instr[30:20]};
   wire [63:0] Simm = {{53{instr[31]}}, instr[30:25],instr[11:7]};

   localparam READ  = 0;
   localparam WRITE = 1;
   reg takeBranch;

   wire [63:0] aluIn2   = isALUreg | isALUreg32 | isBranch ? rs2_data : Iimm;
   wire [64:0] aluMinus = {1'b1, ~aluIn2} + {1'b0,rs1_data} + 65'b1;
   wire        EQ  = (aluMinus[63:0] == 0);
   wire        LTU = aluMinus[64]; 
   wire        LT  = (rs1_data[63] ^ aluIn2[63]) ? rs1_data[63] : aluMinus[64];
   wire [63:0] aluPlus = rs1_data + aluIn2;
   wire [5:0] shamt = (isALUimm | isALUimm32) ? instr[25:20] : {1'b0, rs2_data[4:0]}; // isALUreg32  ? : ; // shift amount
   
   wire [63:0] LDaddr = {rs1_data + (isStore ? Simm : Iimm)};
   wire [31:0] LOAD_word =
          LDaddr[2] ? mem_data[63:32] : mem_data[31:0];
   wire [15:0] LOAD_halfword =
          LDaddr[1] ? LOAD_word[31:16] : LOAD_word[15:0];
   wire  [7:0] LOAD_byte =
          LDaddr[0] ? LOAD_halfword[15:8] : LOAD_halfword[7:0];

   // ADD(x10,x0,x0);
   localparam FETCH_INSTR = 0;
   localparam WAIT_INSTR  = 1;
   localparam FETCH_REGS  = 2;
   localparam WAIT_REGS   = 3;
   localparam WAIT_REGS2  = 4;
   localparam EXECUTE     = 5;
   reg [2:0] state = FETCH_INSTR;
   always @(posedge clk) begin
      if (reset) begin
         state <= FETCH_INSTR;
         pc    <= 64'hFFFFFFFFFFFF0000;
      end else

      case(state)
         FETCH_INSTR: begin
            mem_addr <= pc;
            rw       <= READ;
            state    <= WAIT_INSTR;
         end
         WAIT_INSTR: begin 
            state    <= FETCH_REGS;
         end
         FETCH_REGS: begin
            instr <= pc[2] ? mem_data[63:32] : mem_data[31:0];
            state <= WAIT_REGS;
         end
         WAIT_REGS: begin
            if (isLoad) begin
               case(funct3[1:0]) 
                  2'b00: size <= 1;
                  2'b01: size <= 3;
                  2'b10: size <= 7;
                  2'b11: size <= 15;
               endcase

               mem_addr <= LDaddr;
            end 
            state    <= WAIT_REGS2;
         end
         WAIT_REGS2: begin
            state    <= EXECUTE;
         end
         EXECUTE: begin
            if (isALUreg || isALUimm || isALUreg32 || isALUimm32) begin
               case(funct3)
                  3'b000: registers[rd] <= (funct7[5] & instr[5]) ? aluMinus[63:0] : aluPlus;
                  3'b001: registers[rd] <= rs1_data << shamt;
                  3'b010: registers[rd] <= {63'b0, LT};
                  3'b011: registers[rd] <= {63'b0, LTU};
                  3'b100: registers[rd] <= (rs1_data ^ aluIn2);
                  3'b101: registers[rd] <= funct7[5]? ($signed(rs1_data) >>> shamt) : 
                        ($signed(rs1_data) >> shamt); 
                  3'b110: registers[rd] <= (rs1_data | aluIn2);
                  3'b111: registers[rd] <= (rs1_data & aluIn2); 
               endcase

               pc <= pcnext;
            end else if (isJAL) begin
               registers[rd] <= pcnext;
               pc <= pc + {{44{instr[31]}}, instr[19:12],instr[20],instr[30:21],1'b0}; // Jmm
            end else if (isJALR) begin
               registers[rd] <= pcnext;
               pc <= rs1_data + Iimm;
            end else if (isLUI) begin
               registers[rd] <= Uimm;
               pc <= pcnext;
            end else if (isAUIPC) begin
               registers[rd] <= Uimm + pc;
               pc <= pcnext;
            end else if (isBranch) begin
               if (takeBranch)
                  pc <= pc + {{52{instr[31]}}, instr[7],instr[30:25],instr[11:8],1'b0};
               else 
                  pc <= pcnext;
            end else if (isStore) begin
               case(funct3[1:0]) 
                  2'b00: size <= 1;
                  2'b01: size <= 3;
                  2'b10: size <= 7;
                  2'b11: size <= 15;
               endcase

               mem_addr <= LDaddr;
               mdata <= rs2_data;
               rw <= WRITE;
               pc <= pcnext;
            end else if (isLoad) begin
               if (isIO) begin
                  case(funct3[1:0]) 
                     2'b00: registers[rd] <= rd == 0 ? 64'b0 : {funct3[2] ? 0 : {56{mem_data[7]}}, mem_data[7:0]};
                     2'b01: registers[rd] <= rd == 0 ? 64'b0 : {funct3[2] ? 0 : {48{mem_data[15]}}, mem_data[15:0]};
                     2'b10: registers[rd] <= rd == 0 ? 64'b0 : {funct3[2] ? 0 : {32{mem_data[31]}}, mem_data[31:0]};
                     2'b11: registers[rd] <= rd == 0 ? 64'b0 : mem_data;
                  endcase
               end else begin
                  case(funct3[1:0]) 
                     2'b00: registers[rd] <= rd == 0 ? 64'b0 : {funct3[2] ? 0 : {56{LOAD_byte[7]}}, LOAD_byte};
                     2'b01: registers[rd] <= rd == 0 ? 64'b0 : {funct3[2] ? 0 : {48{LOAD_halfword[15]}}, LOAD_halfword};
                     2'b10: registers[rd] <= rd == 0 ? 64'b0 : {funct3[2] ? 0 : {32{LOAD_word[31]}}, LOAD_word};
                     2'b11: registers[rd] <= rd == 0 ? 64'b0 : mem_data;
                  endcase
               end
               pc <= pcnext;
            end
`ifdef NON_SYNTH
            else if(isSYSTEM) begin
               $display("Finished correctly");
               $finish;
            end else begin
               $display("Unknown command: %h", instr);
               $finish;
            end
`endif

            state <= FETCH_INSTR;
         end
      endcase
   end

   always @(*) begin
      case(funct3)
         3'b000: takeBranch = EQ;
         3'b001: takeBranch = !EQ;
         3'b100: takeBranch = LT;
         3'b101: takeBranch = !LT;
         3'b110: takeBranch = LTU;
         3'b111: takeBranch = !LTU;
         default: takeBranch = 1'b0;
      endcase
   end
endmodule
