`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/13 16:45:04
// Design Name: 
// Module Name: btn_debounce
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


module btn_debounce#
(parameter CNT_MAX=21'd2_000_000
)(
    input clk,
    input rst_n,
    input btn_in,
    output reg btn_level,
    output btn_pos,
    output btn_neg   
    );
    reg[20:0] cnt=0;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
             cnt<=21'd0;
             btn_level <=1'b0;
        end
        else if(btn_in==btn_level)begin
            cnt <=0; 
        end
        else if(cnt==CNT_MAX-1)begin
            cnt<=0;
            btn_level<=btn_in;
        end
        else begin
            cnt<=cnt+1;
        end
    end
    reg btn_level_d;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            btn_level_d<=1'b0;
        else begin
            btn_level_d<=btn_level; 
        end
    end
    
    assign btn_pos = btn_level&~btn_level_d;
    assign btn_neg = ~btn_level&btn_level_d;
endmodule






