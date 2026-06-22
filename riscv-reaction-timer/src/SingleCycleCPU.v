module SingleCycleCPU (
    input clk,
    input start,

    output [31:0] io_addr,
    output [31:0] io_wdata,
    output io_we,
    input  [31:0] io_rdata
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

// rst is active low
wire rst;
assign rst = start;

// =====================
// Wires
// =====================

wire [31:0] pc_now;
wire [31:0] pc_next;
wire [31:0] pc_plus_4;
wire [31:0] pc_branch;

wire [31:0] inst;

wire [6:0] opcode;
wire [4:0] rd;
wire [2:0] funct3;
wire [4:0] rs1;
wire [4:0] rs2;
wire funct7;

assign opcode = inst[6:0];
assign rd     = inst[11:7];
assign funct3 = inst[14:12];
assign rs1    = inst[19:15];
assign rs2    = inst[24:20];
assign funct7 = inst[30];

wire memRead;
wire [1:0] memtoReg;
wire [1:0] ALUOp;
wire memWrite;
wire ALUSrc;
wire regWrite;
wire [1:0] PCSel;

wire [31:0] readData1;
wire [31:0] readData2;
wire [31:0] writeData;

wire BrEq;
wire BrLT;

wire signed [31:0] imm;

wire [3:0] ALUCtl;
wire signed [31:0] alu_A;
wire signed [31:0] alu_B;
wire signed [31:0] ALUOut;
wire zero;

wire [31:0] memReadData;
wire [31:0] dataMemReadData;

// §C¦ì§}°£¿ùª©¡G
// address = 4 ¥Nªí BUTTON_REG
// address = 8 ¥Nªí LED_REG
wire is_io;
assign is_io = (ALUOut == 32'd4) || (ALUOut == 32'd8);

// §â CPU ªº°O¾ÐÅé¦s¨ú°T¸¹±µ¥X¥hµ¹ mmio.v
assign io_addr  = ALUOut;
assign io_wdata = readData2;
assign io_we    = memWrite && is_io;

// ¦pªG¬O I/O ¦ì§}¡A´NÅª io_rdata
// ¦pªG¬O¤@¯ë°O¾ÐÅé¡A´NÅª DataMemory
assign memReadData = is_io ? io_rdata : dataMemReadData;

// jalr target lowest bit should be 0
wire [31:0] jalr_target;
assign jalr_target = {ALUOut[31:1], 1'b0};

// auipc needs ALU input A = PC
assign alu_A = (opcode == 7'b0010111) ? pc_now : readData1;


// =====================
// PC
// =====================

PC m_PC(
    .clk(clk),
    .rst(rst),
    .pc_i(pc_next),
    .pc_o(pc_now)
);


// =====================
// PC + 4
// =====================

Adder m_Adder_1(
    .a(pc_now),
    .b(32'd4),
    .sum(pc_plus_4)
);


// =====================
// Instruction Memory
// =====================

InstructionMemory m_InstMem(
    .readAddr(pc_now),
    .inst(inst)
);


// =====================
// Control
// =====================

Control m_Control(
    .opcode(opcode),
    .funct3(funct3),
    .BrEq(BrEq),
    .BrLT(BrLT),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .PCSel(PCSel)
);


// =====================
// Register
// Do not change instance name!
// =====================

Register m_Register(
    .clk(clk),
    .rst(rst),
    .regWrite(regWrite),
    .readReg1(rs1),
    .readReg2(rs2),
    .writeReg(rd),
    .writeData(writeData),
    .readData1(readData1),
    .readData2(readData2)
);

// ======= for validation =======
// == Dont change this section ==
// assign r = m_Register.regs;
// ======= for validation =======


// =====================
// Branch Comparator
// =====================

BranchComp m_BranchComp(
    .A(readData1),
    .B(readData2),
    .BrEq(BrEq),
    .BrLT(BrLT)
);


// =====================
// Immediate Generator
// =====================

ImmGen m_ImmGen(
    .inst(inst),
    .imm(imm)
);


// =====================
// ShiftLeftOne
// ?™ä»½è¨­è?ˆæ?’æ?‰ä½¿?”¨å®ƒï?Œå? ç‚º ImmGen ??? B/J type å·²ç?“è?? 1'b0
// ä½†æ¨¡?¿??‰é?™å?‹æ¨¡çµ„ï?Œæ?ä»¥ä?ç?? instanceï¼Œé¿??ä? ä?‹å?Œæƒ³?”¹?ž¶æ§?
// =====================

wire [31:0] unused_shifted_imm;

ShiftLeftOne m_ShiftLeftOne(
    .i(imm),
    .o(unused_shifted_imm)
);


// =====================
// PC + imm for branch / jal
// æ³¨æ?ï?šé?™è£¡?›´?Ž¥?”¨ immï¼Œä?å?? shift left
// ?? ç‚º ImmGen å·²ç?“è?? 1'b0
// =====================

Adder m_Adder_2(
    .a(pc_now),
    .b(imm),
    .sum(pc_branch)
);


// =====================
// PC Mux
// PCSel:
// 00 -> PC + 4
// 01 -> PC + imm      branch / jal
// 10 -> rs1 + imm     jalr
// =====================

Mux3to1 #(.size(32)) m_Mux_PC(
    .sel(PCSel),
    .s0(pc_plus_4),
    .s1(pc_branch),
    .s2(jalr_target),
    .out(pc_next)
);


// =====================
// ALU input B Mux
// ALUSrc:
// 0 -> readData2
// 1 -> imm
// =====================

Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(ALUSrc),
    .s0(readData2),
    .s1(imm),
    .out(alu_B)
);


// =====================
// ALU Control
// =====================

ALUCtrl m_ALUCtrl(
    .ALUOp(ALUOp),
    .funct7(funct7),
    .funct3(funct3),
    .ALUCtl(ALUCtl)
);


// =====================
// ALU
// =====================

ALU m_ALU(
    .ALUctl(ALUCtl),
    .A(alu_A),
    .B(alu_B),
    .ALUOut(ALUOut),
    .zero(zero)
);


// =====================
// Data Memory
// =====================

DataMemory m_DataMemory(
    .rst(rst),
    .clk(clk),
    .memWrite(memWrite && !is_io),
    .memRead(memRead && !is_io),
    .address(ALUOut),
    .writeData(readData2),
    .readData(dataMemReadData)
);

// =====================
// Write Back Mux
// memtoReg:
// 00 -> ALUOut
// 01 -> DataMemory readData
// 10 -> PC + 4       jal / jalr
// =====================

Mux3to1 #(.size(32)) m_Mux_WriteData(
    .sel(memtoReg),
    .s0(ALUOut),
    .s1(memReadData),
    .s2(pc_plus_4),
    .out(writeData)
);

endmodule
