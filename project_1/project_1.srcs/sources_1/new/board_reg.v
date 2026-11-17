`timescale 1ns / 1ps

// 1.存储棋盘board[35:0]，其中board[4*k +: 4]；
// 2.输出cell_valid[8:0]（每格是否已写入）；
// 3.输出zero_pos：0号空位所在格索引；

module board_reg (
    input  wire        clk,
    input  wire        rst_n,

    // 初始化写入（来自 init_validate）
    input  wire        init_we,
    input  wire [3:0]  init_idx,     // 0~8
    input  wire [3:0]  init_data,    // 0~8

    // input wire         swap_en,
    // input wire  [3:0]  piece_pos;

    // 棋盘只读输出（给 display_top / core_top 内部）
    output wire [35:0] board,        // board[4*k +: 4] = 第 k 格
    output wire [8:0]  cell_valid,   // 每格是否已写入
    output wire [3:0]  zero_pos      // 0 号空位所在格索引
);



endmodule