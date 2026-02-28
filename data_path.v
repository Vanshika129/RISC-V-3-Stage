module data_path(
    input clk, rst,

    input [4:0] read_reg_num1,
    input [4:0] read_reg_num2,
    input [4:0] write_reg_num1,

    input [31:0] input_pc,         

    input reg_write,
    input [5:0] alu_control,
    input alu_src,
    input jump,
    input stall,
    input branch_flush,

    input beq_control, bne_control,
    input bgeq_control, blt_control,

    input [31:0] imm_val,
    input [3:0] sh_amt,

    input lb, sw,
    input lui_control,
    input [31:0] imm_val_lui,

    output EX_MEM_regwrite,
    output [4:0] EX_MEM_rd,
    output EX_MEM_lb,
    output [31:0] EX_MEM_pc,        

    output [4:0] read_data_addr_dm,
    output beq, bneq, bge, blt
);

// ================= STAGE 2 =================

wire [31:0] read_data1, read_data2;
wire [31:0] alu_result;
wire [31:0] alu_input_2;

assign alu_input_2 = (alu_src) ? imm_val : read_data2;

wire [31:0] final_write_back_data;

register_file rfu (
    .clk(clk),
    .reset(rst),
    .read_reg_num1(read_reg_num1),
    .read_reg_num2(read_reg_num2),
    .write_reg_num1(EX_MEM_rd),
    .write_data_dm(final_write_back_data),
    .lb(EX_MEM_lb),
    .lui_control(lui_control),
    .lui_imm_val(imm_val_lui),
    .jump(jump),
    .read_data1(read_data1),
    .read_data2(read_data2),
    .sw(sw)
);

alu alu_unit(
    .src1(read_data1),
    .src2(alu_input_2),
    .alu_control(alu_control),
    .imm_val_r(imm_val),
    .sh_amt(sh_amt),
    .result(alu_result)
);

// ================= EX/MEM REGISTER =================

reg [31:0] EX_MEM_alu_result_reg;
reg [31:0] EX_MEM_read_data2_reg;
reg [4:0]  EX_MEM_rd_reg;
reg EX_MEM_lb_reg;
reg EX_MEM_sw_reg;
reg EX_MEM_regwrite_reg;
reg [31:0] EX_MEM_pc_reg;         

reg EX_MEM_beq_control;
reg EX_MEM_bne_control;
reg EX_MEM_bgeq_control;
reg EX_MEM_blt_control;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        EX_MEM_alu_result_reg <= 0;
        EX_MEM_read_data2_reg <= 0;
        EX_MEM_rd_reg <= 0;
        EX_MEM_lb_reg <= 0;
        EX_MEM_sw_reg <= 0;
        EX_MEM_regwrite_reg <= 0;
        EX_MEM_pc_reg <= 0;
        EX_MEM_beq_control <= 0;
        EX_MEM_bne_control <= 0;
        EX_MEM_bgeq_control <= 0;
        EX_MEM_blt_control <= 0;
    end
    else if (branch_flush) begin   
        EX_MEM_regwrite_reg <= 0;
        EX_MEM_rd_reg <= 0;
        EX_MEM_lb_reg <= 0;
        EX_MEM_sw_reg <= 0;
        EX_MEM_beq_control <= 0;
        EX_MEM_bne_control <= 0;
        EX_MEM_bgeq_control <= 0;
        EX_MEM_blt_control <= 0;
    end
    else if (stall) begin          
        EX_MEM_regwrite_reg <= 0;
        EX_MEM_rd_reg <= 0;
        EX_MEM_lb_reg <= 0;
        EX_MEM_sw_reg <= 0;
        EX_MEM_beq_control <= 0;
        EX_MEM_bne_control <= 0;
        EX_MEM_bgeq_control <= 0;
        EX_MEM_blt_control <= 0;
    end
    else begin
        EX_MEM_alu_result_reg <= alu_result;
        EX_MEM_read_data2_reg <= read_data2;
        EX_MEM_rd_reg <= write_reg_num1;
        EX_MEM_lb_reg <= lb;
        EX_MEM_sw_reg <= sw;
        EX_MEM_regwrite_reg <= reg_write;
        EX_MEM_pc_reg <= input_pc;        
        EX_MEM_beq_control <= beq_control;
        EX_MEM_bne_control <= bne_control;
        EX_MEM_bgeq_control <= bgeq_control;
        EX_MEM_blt_control <= blt_control;
    end
end

assign EX_MEM_rd = EX_MEM_rd_reg;
assign EX_MEM_lb = EX_MEM_lb_reg;
assign EX_MEM_regwrite = EX_MEM_regwrite_reg;
assign EX_MEM_pc = EX_MEM_pc_reg;

// ================= STAGE 3 =================

wire [31:0] data_out_mem;

data_memory dmu(
    .clk(clk),
    .rst(rst),
    .wr_addr(EX_MEM_alu_result_reg[6:2]),
    .wr_data(EX_MEM_read_data2_reg),
    .sw(EX_MEM_sw_reg),
    .rd_addr(EX_MEM_alu_result_reg[6:2]),
    .data_out(data_out_mem)
);

assign final_write_back_data =
    (EX_MEM_lb_reg) ? data_out_mem :
                      EX_MEM_alu_result_reg;

assign read_data_addr_dm = EX_MEM_alu_result_reg[6:2];

assign beq  = (EX_MEM_alu_result_reg == 0 && EX_MEM_beq_control);
assign bneq = (EX_MEM_alu_result_reg != 0 && EX_MEM_bne_control);
assign bge  = (EX_MEM_alu_result_reg == 1 && EX_MEM_bgeq_control);
assign blt  = (EX_MEM_alu_result_reg == 1 && EX_MEM_blt_control);

endmodule
