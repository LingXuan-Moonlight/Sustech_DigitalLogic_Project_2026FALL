`timescale 1ns/1ps

module tb_board_reg();
    reg  clk;
    reg  rst_n;
    wire ...;

    xxx uut (
        .clk   (clk),
        .rst_n (rst_n),
        ...
    );

    initial clk = 0;
    always #5 clk = ~clk;      // 100MHz

    initial begin
        rst_n = 0;
        #25;
        rst_n = 1;
        // 测试序列
        #1000;
        $finish;
    end
endmodule