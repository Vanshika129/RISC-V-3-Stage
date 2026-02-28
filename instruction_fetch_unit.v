module instruction_fetch_unit(
        input clk, 
    input reset, 
    input stall,
    input beq, bneq, bge, blt, jump,
    input [31:0] imm_address,
    input [31:0] imm_address_jump,
    input [31:0] branch_base_pc,
    output reg [31:0] pc,         // Added [31:0]
    output reg [31:0] current_pc  // Added [31:0]
);

    // PC Update Logic
    always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 32'b0;
    end 
    else if (!stall) begin   // FREEZE PC WHEN STALL
        if (jump) begin
            pc <= pc + imm_address_jump;
        end 
        else if (beq || bneq || bge || blt) begin
            pc <= branch_base_pc + imm_address;
        end 
        else begin
            pc <= pc + 4;
        end
    end
end

    
    always @(posedge clk) begin
        if (reset)
            current_pc <= 32'b0;
        else
            current_pc <= pc; 
    end

endmodule
