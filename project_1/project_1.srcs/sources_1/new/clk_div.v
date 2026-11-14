`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/13 16:45:04
// Design Name: 
// Module Name: clk_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clk_div #(parameter MAX_COUNT=100_000_000)(
    input clk,
    input rst_n,
    output reg tick
    );
    reg [31:0] cnt;
    always@(posedge clk , negedge rst_n)begin
        if(!rst_n)begin
            cnt<=0;
            tick<=1'b0;
        end
        else if(cnt==MAX_COUNT-1)begin
            cnt<=0;
            tick<=1'b1;
        end
        else begin
        cnt<=cnt+1;
        tick <=1'b0;
        end
    end   
    
endmodule
