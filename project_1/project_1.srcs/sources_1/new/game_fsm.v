`timescale 1ns / 1ps

module game_fsm (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        init_done,    // 来自 init_validate

    output reg  [2:0]  state,        // IDLE / INIT / PLAY ...
    output wire        init_en,      // state == INIT
    output reg         init_start,   // 复位后打一拍给 init_validate
    output wire        win           // 本期可 assign 0；后续接 win_check
);



endmodule