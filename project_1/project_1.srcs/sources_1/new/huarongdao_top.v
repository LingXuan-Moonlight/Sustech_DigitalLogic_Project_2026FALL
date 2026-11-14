`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/13 16:45:04
// Design Name: 
// Module Name: huarongdao_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////


module huarongdao_top(
input clk,
input rst_n,
input btn_in_confirm,
input btn_in_view,
input btn_in_mode,
input btn_in_demo,
input btn_in_undo,
input[15:0] sw,        //16¸ö²¦Âë
output wire [7:0]  seg_left,
output wire [3:0]  an_left,
output wire [7:0]  seg_right,
output wire [3:0]  an_right,
output wire [7:0]  led_low,
output wire [3:0]  led_cell9,
output wire [3:0]  led_status
    );
    wire[3:0] sw_num = sw[3:0];
    wire confirm_pos;
    wire view_pos;
    wire mode_pos;
    wire demo_pos;
    wire undo_pos;
    wire tick_1khz;
    wire tick_2hz;
    
    clk_div#(.MAX_COUNT(100_000)) u_div_1khz(
    .clk(clk),
    .rst_n(rst_n),
    .tick(tick_1khz)
    );
    clk_div#(.MAX_COUNT(50_000_000)) u_div_2hz(
    .clk(clk),
    .rst_n(rst_n),
    .tick(tick_2hz)
    );
    btn_debounce u_deb_confirm(
    .clk(clk),
    .rst_n(rst_n),
    .btn_in(btn_in_confirm),
    .btn_pos(confirm_pos)
    );
        btn_debounce u_deb_view(
    .clk(clk),
    .rst_n(rst_n),
    .btn_in(btn_in_view),
    .btn_pos(view_pos)
    );
        btn_debounce u_deb_mode(
    .clk(clk),
    .rst_n(rst_n),
    .btn_in(btn_in_mode),
    .btn_pos(mode_pos)
    );
        btn_debounce u_deb_demo(
    .clk(clk),
    .rst_n(rst_n),
    .btn_in(btn_in_demo),
    .btn_pos(demo_pos)
    );
        btn_debounce u_deb_undo(
    .clk(clk),
    .rst_n(rst_n),
    .btn_in(btn_in_undo),
    .btn_pos(undo_pos)
    );
    
endmodule
