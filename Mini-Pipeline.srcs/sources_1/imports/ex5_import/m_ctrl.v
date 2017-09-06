`timescale 1ns / 1ps
module m_ctrl(
    input wire clk,
    input wire [5:0] OP,
    output reg [3:0] next_status = 4'b0,
    output reg PC_write_condition,
    output reg PC_write,
    output reg IorD,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg IR_write,
    output reg [1:0] PC_source,
    output reg [1:0] ALU_op,
    output reg ALU_src_A,
    output reg [1:0] ALU_src_B,
    output reg reg_write,
    output reg reg_dst
);

    wire LW = OP == 6'b100011; // OP[0]& OP[1]&~OP[2]&~OP[3]&~OP[4]& OP[5]
    wire SW = OP == 6'b101011; // OP[0]& OP[1]&~OP[2]& OP[3]&~OP[4]& OP[5]
    wire BEQ = OP == 6'b000100; // ~OP[0]&~OP[1]& OP[2]&~OP[3]&~OP[4]&~OP[5]
    wire R = OP == 6'b000000; // ~OP[0]&~OP[1]&~OP[2]&~OP[3]&~OP[4]&~OP[5]
    wire J = OP == 6'b000010;

always @ (posedge clk) begin
case (next_status)
    4'b0000:  begin
        // move to 1
        PC_write <= 1'b1;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        IR_write <= 1'b1;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b01;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;

        next_status <= 4'b0001;
    end
    4'b0001: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b11;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        if (J) begin
         // move to 9
         next_status <= 4'b1001;
        end else if (BEQ) begin
         // move to 8
         next_status <= 4'b1000;
        end else if (R) begin
         // move to 6
         next_status <= 4'b0110;
        end else if (LW || SW) begin
         // move to 2
         next_status <= 4'b0010;
        end
    end
    4'b0010: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b10;
        ALU_src_A <= 1'b1;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        if (SW) begin
            // move to 5
         next_status <= 4'b0101;
        end else if (LW) begin
            // move to 3
         next_status <= 4'b0011;
        end else begin
            // move to 0
         next_status <= 4'b0000;
     end
    end
    4'b0011: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b1;
        mem_read <= 1'b1;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        // move to 4
        next_status <= 4'b0100;
    end
    4'b0100: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b1;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b1;
        reg_dst <= 1'b0;
        // move to 0
        next_status <= 4'b0000;
    end
    4'b0101: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b1;
        mem_read <= 1'b0;
        mem_write <= 1'b1;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        // move to 0
        next_status <= 4'b0000;
    end
    4'b0110: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b10;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b1;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        // move to 7
        next_status <= 4'b0111;
    end
    4'b0111: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b00;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b1;
        reg_dst <= 1'b1;
        // move to 0
        next_status <= 4'b0000;
    end
    4'b1000: begin
        PC_write <= 1'b0;
        PC_write_condition <= 1'b1;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b01;
        ALU_op <= 2'b01;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b1;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        // move to 0
        next_status <= 4'b0000;
    end
    4'b1001: begin
        PC_write <= 1'b1;
        PC_write_condition <= 1'b0;
        IorD <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        IR_write <= 1'b0;
        mem_to_reg <= 1'b0;
        PC_source <= 2'b10;
        ALU_op <= 2'b00;
        ALU_src_B <= 2'b00;
        ALU_src_A <= 1'b0;
        reg_write <= 1'b0;
        reg_dst <= 1'b0;
        // move to 0
        next_status <= 4'b0000;
    end
    default: begin
        next_status <= 4'b0000;
    end
endcase
end

endmodule