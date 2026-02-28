`timescale 1ns / 1ps
`include "defines.vh"

module top(
    input clk,
    input reset
);

wire [31:0] pc;
wire [31:0] current_pc;
wire [31:0] instruction_out;

wire stall;
wire branch_taken;

wire [31:0] imm_val_r;
wire [31:0] ex_mem_pc;   // 🔥 NEW

wire reg_write;
wire ex_mem_regwrite;
wire [4:0] ex_mem_rd;
wire ex_mem_lb;

wire beq, bneq, bge, blt;

assign branch_taken = beq | bneq | bge | blt;

// ================= IF =================

instruction_fetch_unit ifu (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .beq(beq),
    .bneq(bneq),
    .bge(bge),
    .blt(blt),
    .jump(1'b0),
    .imm_address(imm_val_r),
    .imm_address_jump(imm_val_r),
    .branch_base_pc(ex_mem_pc),   
    .pc(pc),
    .current_pc(current_pc)
);

instruction_memory imu (
    .pc(pc),
    .instruction_code(instruction_out)
);

// ================= IF/ID =================

reg [31:0] IF_ID_instruction;

always @(posedge clk or posedge reset) begin
    if (reset)
        IF_ID_instruction <= 0;
    else if (branch_taken)
        IF_ID_instruction <= 0;
    else if (!stall)
        IF_ID_instruction <= instruction_out;
end

// ================= ID =================

imm_gen ig (
    .instr_memory(IF_ID_instruction),
    .imm_val_r(imm_val_r)
);

wire [5:0] alu_control;
wire lb, sw, lui_control;
wire alu_src;
wire bneq_control, beq_control, bgeq_control, blt_control;

control_unit cu (
    .reset(reset),
    .funct7(IF_ID_instruction[31:25]),
    .funct3(IF_ID_instruction[14:12]),
    .opcode(IF_ID_instruction[6:0]),
    .alu_control(alu_control),
    .lb(lb),
    .bneq_control(bneq_control),
    .beq_control(beq_control),
    .bgeq_control(bgeq_control),
    .blt_control(blt_control),
    .jump(),
    .sw(sw),
    .lui_control(lui_control),
    .alu_src(alu_src),
    .reg_write(reg_write)
);

wire [4:0] rs1 = IF_ID_instruction[19:15];
wire [4:0] rs2 = IF_ID_instruction[24:20];

assign stall =
    (ex_mem_regwrite) &&
    (ex_mem_rd != 0) &&
    ((ex_mem_rd == rs1) || (ex_mem_rd == rs2));

// ================= DATAPATH =================

data_path dpu (
    .clk(clk),
    .rst(reset),
    .read_reg_num1(rs1),
    .read_reg_num2(rs2),
    .write_reg_num1(IF_ID_instruction[11:7]),
    .input_pc(current_pc),
    .reg_write(reg_write),
    .alu_control(alu_control),
    .alu_src(alu_src),
    .jump(1'b0),
    .stall(stall),
    .branch_flush(branch_taken),
    .beq_control(beq_control),
    .bne_control(bneq_control),
    .bgeq_control(bgeq_control),
    .blt_control(blt_control),
    .imm_val(imm_val_r),
    .sh_amt(IF_ID_instruction[24:21]),
    .lb(lb),
    .sw(sw),
    .lui_control(lui_control),
    .imm_val_lui(imm_val_r),
    .EX_MEM_regwrite(ex_mem_regwrite),
    .EX_MEM_rd(ex_mem_rd),
    .EX_MEM_lb(ex_mem_lb),
    .EX_MEM_pc(ex_mem_pc),
    .read_data_addr_dm(),
    .beq(beq),
    .bneq(bneq),
    .bge(bge),
    .blt(blt)
);

endmodule
