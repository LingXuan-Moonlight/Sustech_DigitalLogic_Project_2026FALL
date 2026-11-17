`timescale 1ns / 1ps 

module core_top (
    input  wire        clk,
    input  wire        rst_n,

    // 来自 huarongdao_top
    input  wire [3:0]  sw_num,
    input  wire        confirm_pos,

    // 给 display_top / huarongdao_top
    output wire [35:0] board,
    output wire [8:0]  cell_valid,
    output wire [3:0]  zero_pos,
    output wire [2:0]  state,
    output wire        win,
    output wire        error_pulse
);



endmodule
