`timescale 1ns / 1ps

// 输入计数、0~8范围检查、位图去重（seen[8:0]）
// 输出：init_we / init_idx / init_data / init_error
// init_error_idx / init_error_last / init_done

module init_validate (
    input  wire        clk,
    input  wire        rst_n,

    // 来自 game_fsm 的初始化控制
    input  wire        init_start,   // 复位后打一拍，清 seen/idx
    input  wire        init_en,      // state == INIT 时有效

    // 来自 top 的用户输入
    input  wire        confirm_pos,  // 消抖后的确认脉冲，高有效
    input  wire [3:0]  sw_num,       // 0~8

    // 给 board_reg 的写口
    output reg         init_we,      // 单周期
    output reg  [3:0]  init_idx,     // 当前待写格 0~8
    output reg  [3:0]  init_data,    // 合法输入值

    // 状态/错误
    output reg         init_error,      // 必须单周期
    output reg  [3:0]  init_error_idx,  // 出错格索引
    output reg         init_error_last, // 第 9 格非法
    output reg         init_done        // 第 9 格合法，单周期
);



endmodule