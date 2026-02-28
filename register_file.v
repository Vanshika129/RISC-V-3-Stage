`timescale 1ns / 1ps

module register_file(
    input clk,
    input reset,
    input [4:0] read_reg_num1,     // rs1
    input [4:0] read_reg_num2,     // rs2
    input [4:0] write_reg_num1,    // rd
    input [31:0] write_data_dm,    // Data from ALU or Memory
    input lb,                      // Load Byte signal
    input lui_control,             // LUI signal
    input [31:0] lui_imm_val,      // Immediate for LUI
    input jump,                    // Jump signal
    input sw,                      // Store Word signal
    output [31:0] read_data1,
    output [31:0] read_data2,
    output [4:0] read_data_addr_dm,
    output reg [31:0] data_out_2_dm
);

    reg [31:0] reg_mem [31:0];
    integer i;

    // Output assignments (Combinational)
    assign read_data1 = (read_reg_num1 == 5'b0) ? 32'b0 : reg_mem[read_reg_num1];
    assign read_data2 = (read_reg_num2 == 5'b0) ? 32'b0 : reg_mem[read_reg_num2];
    assign read_data_addr_dm = write_reg_num1;

    // Synchronous Write Logic
    always @(posedge clk) begin
        if (reset) begin
            // Initialize registers: X0 is 0, others initialized to index for debugging
            for (i = 0; i < 32; i = i + 1) begin
                reg_mem[i] <= i; 
            end
            data_out_2_dm <= 32'b0;
        end 
        else begin
            // 1. Handle writing to destination register (rd)
            // Register X0 is hardwired to 0 in RISC-V, so we never write to it
            if (write_reg_num1 != 5'b0) begin
                if (lb) begin
                    // Writing data loaded from memory
                    reg_mem[write_reg_num1] <= write_data_dm;
                end 
                else if (lui_control) begin
                    // Writing upper immediate
                    reg_mem[write_reg_num1] <= lui_imm_val;
                end 
                else if (!sw && !jump) begin
                    // ADDITION: This handles ADD, ADDI, SUB, AND, etc.
                    // If we aren't storing to memory or jumping, we write ALU result to rd
                    reg_mem[write_reg_num1] <= write_data_dm;
                end
            end

            // 2. Handle Data out for Store instructions
            if (sw) begin
                // When sw is high, we send the value of rs1 (or rs2 depending on your ALU) to memory
                data_out_2_dm <= reg_mem[read_reg_num1];
            end
        end
    end

endmodule
