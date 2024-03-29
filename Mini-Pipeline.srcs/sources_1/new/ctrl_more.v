`timescale 1ns / 1ps
module ctrl(
    input clk,
    input reset,
    input [31:0] Inst_in,
    input [31:0] PC_Current, PC_Next,
    input zero,
    input overflow,
    input INT,
    input MIO_ready,
    input PC_CE,
    output reg MemRead,
    output reg MemWrite,
    output reg [2:0] ALU_operation,
    output reg [31:0] eret_addr,
    output [31:0] debug,
    output [4:0] state_out,

    output reg CPU_MIO,
    output reg IorD,
    output reg IRWrite,
    output reg [1:0] RegDst,
    output reg RegWrite,
    output reg [1:0] MemtoReg,
    output reg ALUSrcA,
    output reg [1:0] ALUSrcB,
    output wire [1:0] PCSource,
    output reg PCWrite,
    output reg PCWriteCond,
    output reg Branch
);

    parameter IF = 3'b000, ID = 3'b001, EXE = 3'b010, MEM = 3'b011, WB = 3'b100, SINT = 3'b101, SERET = 3'b110;

    wire [5:0] OP = Inst_in[31:26];
    wire [5:0] Fun = Inst_in[5:0];

    reg [31:0] EPC;

    wire RType = ~|OP;
    wire ERET = Inst_in == 32'h42000018;
    wire IType = OP[5:3] == 3'b001;
    wire LUI = IType & (OP[2:0] == 3'b111);
    wire JR = RType & (Fun == 6'b001000);
    wire Jalr = RType & (Fun == 6'b001001);
    wire IBEQ = (OP == 6'b000100);
    wire IBNE = (OP == 6'b000101);
    wire Jump = (OP == 6'b000010);
    wire Jal = (OP == 6'b000011);
    wire LW = (OP == 6'b100011);
    wire SW = (OP == 6'b101011);
    wire LS = LW | SW;

    reg [2:0] state, next_state;
    reg [2:0] ALUop;
    assign state_out = {next_state, 1'b0};

    reg [1:0] PCSource_wire;

    assign PCSource = PCSource_wire;

    always @ (*) begin
        {PCWrite, PCWriteCond, IorD, MemRead, MemWrite, IRWrite, MemtoReg, PCSource_wire, ALUSrcA, ALUSrcB, RegWrite, RegDst, Branch, ALUop, CPU_MIO} = 20'h0;

        case (state)
            IF: begin
                MemRead = 1;
                IRWrite = 1;
                ALUSrcB = 2'b01;
                PCWrite = 1;

                next_state = ID;
            end
            ID: begin
                ALUSrcB = 2'b11;
                if (ERET) next_state = SERET;
                else if (Jump | Jal | JR | Jalr) begin
                    PCWrite = 1;
                    case ({Jump, Jal, JR, Jalr})
                        4'b1000: PCSource_wire = 2'b10;
                        4'b0100: begin
                            PCSource_wire = 2'b10;
                            MemtoReg = 2'b11;
                            RegDst = 2'b10;
                            RegWrite = 1;
                        end
                        4'b0010: ALUSrcA = 1;
                        4'b0001: begin
                            ALUSrcA = 1;
                            MemtoReg = 2'b11;
                            RegDst = 2'b10;
                            RegWrite = 1;
                        end
                        default: begin
                            PCSource_wire = 2'b11;
                        end
                    endcase
                    next_state = IF;
                end
                else next_state = EXE;
            end
            EXE: begin
                casex({LS, RType | IType, IBEQ | IBNE, Jump | Jal | JR | Jalr})
                    4'b1xxx: begin
                        ALUSrcA = 1;
                        ALUSrcB = 2'b10;
                    end
                    4'bx1xx: begin
                        ALUSrcA = 1;
                        if (IType) begin
                            ALUSrcB = 2'b10;
                            ALUop = 2'b11;
                        end
                        else ALUop = 2'b10;
                    end
                    4'bxx1x: begin
                        ALUSrcA = 1;
                        ALUop = 2'b01;
                        PCWriteCond = IBEQ;
                        PCSource_wire = 2'b01;
                        Branch = 1;
                    end
                    4'bxxx1: begin
                    end
                endcase

                next_state = MEM;
            end
            MEM: begin
                IorD = 1;
                if (RType) begin
                    RegDst = 1;
                    RegWrite = 1;
                end
                else if (LUI) begin
                    MemtoReg = 2'b10;
                    RegWrite = 1;
                end
                else if (IType) begin
                    ALUSrcB = 2'b10;
                    ALUSrcA = 1;
                    RegWrite = 1;
                end
                else if (LW) MemRead = 1;
                else if (SW) MemWrite = 1;

                if (LW) next_state = WB;
                else next_state = IF;
            end
            WB: begin
                RegWrite = 1;
                MemtoReg = 2'b01;
                next_state = IF;
            end
            SINT: begin
                PCWrite = 1;
                PCSource_wire = 2'b11;
                next_state = IF;
            end
            SERET: begin
                PCWrite = 1;
                PCSource_wire = 2'b11;
                next_state = IF;
            end
            default: next_state = IF;
        endcase
    end

    reg ie = 1; // interrupt enable

    assign debug = {4'b0, {1'b0, {next_state}}, {4{INT}}, {4{ie}}, {16{ERET}}};

    wire INTON = next_state == IF && INT && ie;

    always @ (posedge clk or posedge reset) begin
        if (reset) begin
            ie <= 1'b1;
            state <= IF;
        end
        else if (ERET) begin
            eret_addr <= EPC;
            state <= next_state;
            if (next_state == IF) ie <= 1'b1;
        end
        else if (next_state == IF && INT && ie) begin
            eret_addr <= 32'h00000008;
            ie <= 1'b0;
            state <= SINT;
        end
        else if (state == SINT) begin
            // EPC <= PC_CE ? PC_Next : PC_Next + 3'h4;
            EPC <= PC_Current;
            state <= next_state;
        end
        else begin
            state <= next_state;
        end
    end

    always @ (*) begin
        case (ALUop)
            2'b00: ALU_operation = 3'b010; //lw add
            2'b01: ALU_operation = 3'b110; //sw sub
            2'b10:
                case (Fun)
                    6'b100000: ALU_operation = 3'b010; // add
                    6'b100010: ALU_operation = 3'b110; // sub
                    6'b100100: ALU_operation = 3'b000; // and
                    6'b100101: ALU_operation = 3'b001; // or
                    6'b101010: ALU_operation = 3'b111; // slt
                    6'b100111: ALU_operation = 3'b100; // nor
                    6'b000010: ALU_operation = 3'b101; // srl
                    6'b100110: ALU_operation = 3'b011; // xor
                    default: ALU_operation = 3'b000; // default and
                endcase
            2'b11:
                case (OP[2:0])
                    3'b000: ALU_operation = 3'b010; // addi
                    3'b010: ALU_operation = 3'b111; // slti
                    3'b100: ALU_operation = 3'b000; // andi
                    3'b101: ALU_operation = 3'b001; // ori
                    3'b110: ALU_operation = 3'b011; // xori
                    default: ALU_operation = 3'b000; // default and
                endcase
        endcase
    end
endmodule