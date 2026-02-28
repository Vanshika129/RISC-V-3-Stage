`timescale 1ns / 1ps
module data_memory(
    input clk,rst,[4:0] wr_addr,[31:0] wr_data,sw,[4:0] rd_addr,
    output [31:0] data_out
    );
    
    reg [31:0] data_mem [31:0];
    integer i;
    
    always@(posedge clk)
        begin
            if(rst)
                begin
                    for(i = 0;i < 32;i = i+ 1)
                        data_mem[i] <= 32'b0;
                 end
                 
             else
                if(sw)
                    begin
                        data_mem[wr_addr] <= wr_data;
                    end
                    
       end
       
       assign data_out = data_mem[rd_addr];
                   
endmodule
