`timescale 1ns / 1ps

module top_tb;

reg clk;
reg reset;

top uut (
    .clk(clk),
    .reset(reset)
);
initial begin
    $monitor("Time=%0t | PC=%h | x1=%d | x2=%d | x3=%d",
        $time,
        uut.pc,
        uut.dpu.rfu.reg_mem[1],
        uut.dpu.rfu.reg_mem[2],
        uut.dpu.rfu.reg_mem[3]
    );
end
// Clock generation
always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;

    #20;
    reset = 0;

    // Run long enough for pipeline
    #200;

    $finish;
end

endmodule
