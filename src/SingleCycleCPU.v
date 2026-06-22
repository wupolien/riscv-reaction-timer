module SingleCycleCPU(
    input clk,
    input start,

    output [31:0] io_addr,
    output [31:0] io_wdata,
    output io_we,
    input  [31:0] io_rdata
);

    reg [31:0] pc = 32'd0;
    reg [31:0] regs [0:31];

    integer i;

    wire [31:0] inst;

    InstructionMemory u_inst_mem(
        .readAddr(pc),
        .inst(inst)
    );

    wire [6:0] opcode;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [6:0] funct7;

    assign opcode = inst[6:0];
    assign rd     = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1    = inst[19:15];
    assign rs2    = inst[24:20];
    assign funct7 = inst[31:25];

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    assign rs1_data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    wire signed [31:0] imm_i;
    wire signed [31:0] imm_s;
    wire signed [31:0] imm_b;
    wire signed [31:0] imm_j;

    assign imm_i = {{20{inst[31]}}, inst[31:20]};
    assign imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign imm_b = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign imm_j = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    localparam OPCODE_OPIMM  = 7'b0010011; // addi, andi
    localparam OPCODE_LOAD   = 7'b0000011; // lw
    localparam OPCODE_STORE  = 7'b0100011; // sw
    localparam OPCODE_BRANCH = 7'b1100011; // beq
    localparam OPCODE_JAL    = 7'b1101111; // jal
    localparam OPCODE_OP     = 7'b0110011; // add

    wire [31:0] load_addr;
    wire [31:0] store_addr;

    assign load_addr  = rs1_data + imm_i;
    assign store_addr = rs1_data + imm_s;

    assign io_addr  = (opcode == OPCODE_STORE) ? store_addr :
                      (opcode == OPCODE_LOAD)  ? load_addr  :
                      32'd0;

    assign io_wdata = rs2_data;
    assign io_we = start && (opcode == OPCODE_STORE);

    always @(posedge clk) begin
        if (!start) begin
            pc <= 32'd0;

            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end
        else begin
            case (opcode)

                OPCODE_OPIMM: begin
                    if (rd != 5'd0) begin
                        case (funct3)
                            3'b000: regs[rd] <= rs1_data + imm_i; // addi
                            3'b111: regs[rd] <= rs1_data & imm_i; // andi
                            default: regs[rd] <= regs[rd];
                        endcase
                    end

                    pc <= pc + 32'd4;
                end

                OPCODE_OP: begin
                    if (rd != 5'd0) begin
                        if (funct3 == 3'b000 && funct7 == 7'b0000000) begin
                            regs[rd] <= rs1_data + rs2_data; // add
                        end
                    end

                    pc <= pc + 32'd4;
                end

                OPCODE_LOAD: begin
                    if (funct3 == 3'b010) begin
                        if (rd != 5'd0) begin
                            regs[rd] <= io_rdata;
                        end
                    end

                    pc <= pc + 32'd4;
                end

                OPCODE_STORE: begin
                    pc <= pc + 32'd4;
                end

                OPCODE_BRANCH: begin
                    if (funct3 == 3'b000 && rs1_data == rs2_data) begin
                        pc <= pc + imm_b;
                    end
                    else begin
                        pc <= pc + 32'd4;
                    end
                end

                OPCODE_JAL: begin
                    if (rd != 5'd0) begin
                        regs[rd] <= pc + 32'd4;
                    end

                    pc <= pc + imm_j;
                end

                default: begin
                    pc <= pc + 32'd4;
                end

            endcase

            regs[0] <= 32'd0;
        end
    end

endmodule
