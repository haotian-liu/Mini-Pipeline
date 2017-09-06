`timescale 1ns / 1ps
module Multi_CPU(
    input wire clk,
    input wire rst,
    output reg [31:0] pc = 32'b0,
    output wire [31:0] pc_next,
    input wire [15:0] display,
    output wire pc_change,
    output wire [3:0] next_state,
    output reg [31:0] ALUout,
    output reg [31:0] instruction
);
    reg [31:0] m_reg;
    wire zero;
    wire [31:0] result;
    wire [31:0] mem_data;

    wire [31:0] ALU_input_B;

    wire [31:0] input_A;
    wire [31:0] input_B;
    reg [31:0] A;
    reg [31:0] B;

    wire PC_write_condition, PC_write, IorD, mem_read, mem_write, mem_to_reg, IR_write;
    wire [1:0] PC_source, ALU_op;
    wire ALU_src_A;
    wire [1:0] ALU_src_B;
    wire reg_write, reg_dst;

    wire [4:0] WriteAddress = reg_dst ? instruction[15:11] : instruction[20:16];
    wire [31:0] sign_ext = {{16{instruction[15]}}, instruction[15:0]};
    wire [31:0] ALU_input_A = ALU_src_A ? A : pc;
    wire [31:0] jump_pc = {pc[31:28], instruction[25:0], 2'b00};
    wire [31:0] w_data = mem_to_reg ? m_reg : ALUout;
    wire [31:0] mem_input = IorD ? ALUout : pc;

    assign pc_change = (zero && PC_write_condition) || PC_write;

    wire [2:0] ALUoper;

    mux4_1 alubmux(.I0(B), .I1(32'h4), .I2(sign_ext), .I3({sign_ext[29:0], 2'b0}), .Ctrl(ALU_src_B), .S(ALU_input_B));
    mux4_1 pcmux(.I0(result), .I1(ALUout), .I2(jump_pc), .I3(32'b0), .Ctrl(PC_source), .S(pc_next));

    m_ctrl m_ctrl(.OP(instruction[31:26]), .clk(clk), .PC_write_condition(PC_write_condition), .PC_write(PC_write), .IorD(IorD), .mem_read(mem_read), . mem_write(mem_write), .mem_to_reg(mem_to_reg), .IR_write(IR_write), .PC_source(PC_source[1:0]), .ALU_op(ALU_op), .ALU_src_A(ALU_src_A), .ALU_src_B(ALU_src_B[1:0]), .reg_write( reg_write), .reg_dst(reg_dst), .next_status(next_state));

    ALU_ctrl ALU_ctrl(.clk(clk), .ALUop(ALU_op), .func(instruction[5:0]), .ALUoper(ALUoper));
    regs rf(.clk(clk), .display(display[4:0]), .rst(rst), .reg_R_addr_A(instruction[25:21]), .reg_R_addr_B(instruction[20:16]), .reg_W_addr(WriteAddress), .wdata(w_data), .reg_we(reg_write), .rdata_A(input_A), .rdata_B(input_B));

    ALU ALU(.A(ALU_input_A), .B(ALU_input_B), .zero(zero), .ALU_OP(ALUoper), .res(result));

    RAM mem(.clka(~clk), .wea({4{mem_write}}), .addra(mem_input), .dina(B), .douta(mem_data));

    always @ (posedge clk) begin
        if (pc_change) begin
            pc <= pc_next;
        end
        if (IR_write == 1'b1) begin
            instruction <= mem_data;
        end
        m_reg <= mem_data;
        ALUout <= result;
        A <= input_A;
        B <= input_B;
    end
endmodule