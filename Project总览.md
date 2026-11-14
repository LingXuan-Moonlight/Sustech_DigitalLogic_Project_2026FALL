# 功能总览与分值:

| 功能                    | 分值  |
| --------------------- | --- |
| 复位、棋盘初始化              | 10  |
| 棋子移动、合法性判定、步数统计及二进制展示 | 25  |
| 辅助提示                  | 10  |
| 游戏通关判定、数码管十进制展示步数统计   | 10  |
| 撤回                    | 5   |
| 演示模式                  | 10  |
| ---                   | 共70 |
项目个人得分 = （项目功能 70 + 视频文档 10）× 小组人数 × 个人贡献比 + 个人能力 20，其中前者折算不超过 90 分。
	个人能力 20 = 基本开发能力 15 + project相关简答 5

---

# 命名规范（对齐课程站 cs207digitallogic.github.io）

> 这一节是从 Lab 1 / 5 / 6 / 7 / 8 / 9 里提炼的课程约定。**全项目按这里写，不要各写各的。**

## 文件与模块

| 约定 | 示例 |
|---|---|
| 设计文件 `<模块名>.v`，模块名与文件名一致 | `btn_debounce.v` → `module btn_debounce` |
| 仿真文件 `tb_<模块名>.v`，模块 `tb_<模块名>` | `tb_btn_debounce.v` → `module tb_btn_debounce` |
| 约束文件 `<顶层名>.xdc` | `huarongdao_top.xdc` |
| 顶层模块名 `<功能>_top` | `huarongdao_top`（课程里是 `hex_counter_top`） |
| 模块名小写下划线 | `dynamic_display`、`counter_mod`、`edge_detect` |
| 例化名 `u_<缩写>` | `u_deb`、`u_edge`、`u_disp` |
| tb 里被测模块例化名 `uut` | `btn_debounce uut (...)` |

## 信号与端口

| 约定 | 说明 |
|---|---|
| `clk` | 100 MHz，引脚 **P17** |
| `rst_n` | **低电平有效复位**，引脚 **P15**。接口里直接叫 `rst_n`，不要再包一层 `rst_btn_n` |
| `*_in` / `*_out` | 模块输入/输出端口 |
| `*_n` 后缀 | 低有效（只有 `rst_n` 用） |
| 延迟一拍寄存器加 `_d` | `sig_d`、`btn_level_d` |
| 单周期脉冲用 `_pos` / `_neg` / `_pulse` / `tick` | `btn_pos`、`neg_edge`、`tick_1khz` |
| 计数器统一叫 `cnt` / `count`，分频计数器叫 `div_cnt` | `cnt`、`div_cnt` |
| 参数全大写下划线 | `CNT_MAX`、`MAX_COUNT`、`PERIOD`、`MOD` |
| 状态机用 `state` / `next_state`，状态常量大写 | `localparam IDLE = 3'd0;` |

## ★ 硬件极性（先看这条，写反了全部逻辑都要返工）

| 外设 | 极性与位序 | 出处 |
|---|---|---|
| **右侧 5 个通用按键** | **默认低电平，按下为高电平（高有效）** | Lab 7 开头说明 |
| **复位键 / P15** | **低电平有效**，按下 = 0 | Lab 5 §2.2 |
| **数码管** | **共阴极，高电平点亮**；段码 `seg = {a,b,c,d,e,f,g,dp}`，**a 是 bit7，dp 是 bit0** | Lab 6 §2.7 |
| **数码管片选 `an`** | **低电平有效**，one-hot，`an[0]=0` 选中该组最右位 | Lab 9 §4 步骤 4 |
| **8 位数码管结构** | 左右两组**各自共用一套段选信号**，即需要 **两套 `seg` + 两套 `an`** | Lab 6 §2.1 |
| **LED** | 高电平点亮 | Lab 1 约束 |
| **拨码开关** | 拨上为高 | Lab 1 约束 |

> ⚠️ 课程材料自相矛盾的一处：Lab 6 §2.4/2.5 把 `scan_clk` 当真时钟用（`always @(posedge scan_clk)`），但 Lab 5 §4.3 末尾明确写"**不要用分频产生的信号当作其他模块的时钟**，用 `tick` 脉冲作为使能"。
> **本项目按 Lab 5 执行**：全系统只有 `clk` 一个时钟，分频器只出 `tick`。
>
> ⚠️ LED 引脚映射两份材料不一致：Lab 1 是 `led[7]=F6 … led[0]=K2`，Lab 6 跑马灯是反的（`led[7]=K2 … led[0]=F6`）。
> 按 spec"最左为最高位"，**以 Lab 1 为准**：`led_low[7]=F6`（F6 在最左）。写 xdc 前对照 `Ego1_UserManual_v2.2.pdf` 再核一遍。

## 复位与赋值规范

- 时序逻辑 `always @(posedge clk or negedge rst_n)` 内一律用 `<=`；组合逻辑 `always @(*)` 内一律用 `=`，不要混用。
- 组合逻辑 `case` 前先给**默认赋值**，否则综合出锁存器。
- 状态机用**三段式**（状态寄存器 / 次态逻辑 / 输出逻辑），Moore 型。
- Xilinx 支持 `initial` 初始化寄存器，简单初值可以直接写 `reg [31:0] cnt = 0;`。

---

# 规则：
- 3×3 棋盘，棋子编号为 0~8，0 号棋子表示空位；
- 只有与 0 号空位上下左右相邻的棋子可以与 0 交换；
- 通关条件：从左到右、从上到下依次为123456780。

# 外设要求
- 使用多个拨码开关或 LED 表示多bit二进制时，最左侧对应最高位，最右侧对应最低位
- 棋盘展示方式：
	- 基础：按键 + 拨码开关输入，数码管 + LED 输出（一维）
		8 个数码管从左到右显示二维棋盘前 8 个棋格；
		第 9 个棋格使用四位相邻 LED ( K1-H6-H5-J5 ) 显示棋子编号的二进制编码；
		0 号棋子：数码管时不显示，LED 时全灭。
	
	- 高级：键盘/UART/手机app输入，VGA/UART/手机app输出（二维）；
	
	无论哪种方案，**辅助提示**和**统计信息**必须用**基础**外设输出。
		使用开发板左下角的 8 个相邻 LED ( F6-G4-G3-J4-H4-J3-J2-K2 )，通过"展示切换"键切换：
			奇数次按键：游戏提示
				8 个 LED 从左到右依次对应 1~8 号棋子；
				亮灭表示该棋子的可移动状态。
			偶数次按键：统计信息
				左侧 4 个 LED 显示有效步数二进制 ( F6-G4-G3-J4 )；
				右侧 4 个 LED 显示无效步数二进制 ( H4-J3-J2-K2 )；
	
	模式与状态 LED ( K6-L1-M1-K3 )：
		K6：
			亮：高级外设；
			灭：基础外设。
		L1、M1：
			L1：游戏模式；
			M1：演示模式。
		K3：
			闪烁：初始化或移动时出现非法输入；
			常亮：通关；
			熄灭：其他状态

> ★ 修正：spec 的"奇数次/偶数次"是在数**第几次显示**，不是数按键次数。spec 演示流程第 1 步写明"按展示切换键 → 统计区全灭"，说明**复位后默认显示游戏提示，第 1 次按下变统计**。所以 `view_toggle` 的正确语义是：**每次 `view_pulse` 翻转一次，复位后 `view_mode = 0`（游戏提示）**。

# 复位要求：
游戏全程均可通过按下复位键S6(P15)回到初始态：
- 全部统计信息清零
- 一维棋盘不显示信息，等待重新初始化

# 初始化要求：
用户按照二维棋盘从左到右、从上到下的顺序，依次输入每个棋格中的棋子编号，每输入一个按一次确认键；
- 合法性要求：
	- 只能输入 0~8
	- 每个数字只能输入一次
	- 共输入 9 次
- 非法输入处理：
	- 状态指示灯闪烁
	- 对应位置数码管显示字母 E
		若第九个输入非法，则 4 个 LED 全亮
	- 本次输入无效，重新输入合法编号以继续

> ★ 补充：数码管是**渐进显示**的 —— 每确认一个合法编号，对应位置的数码管立刻显示该编号，并**保持到该棋子被移动**。填了 3 格时，第 4~8 位必须空白。这需要 `board_reg` 多输出一根 `cell_valid[8:0]`（每格是否已写入），否则 `display_ctrl` 无法实现。

# 游戏过程与统计：
用户输入要移动的棋子编号并按确认键：
- 若该棋子与 0 号空位上下左右相邻：
	有效移动，交换棋子与 0，更新棋盘，有效步数 + 1
- 不相邻：
	无效移动，不更新棋盘，无效步数 + 1

> ★ 溢出处理：spec 有一条硬要求"数码管上显示的数值应与 led 上的二进制表示的数值一致"。左下统计区只有 4 bit（0~15），所以**统一饱和到 15**：`step_counter` 内部用 8 bit 存真实值，显示层取 `min(cnt, 15)`；通关后数码管也显示 `min(cnt, 15)`。这样任何时刻都一致，答辩不会被问倒。

# 通关判定与通关后展示：
通关条件见上
- 通关时：一维棋盘显示保持不变，点亮通关状态 LED
- 通关后按确认键：
	- 数码管展示统计信息
		- 左侧 2 个数码管显示有效步数的十进制，至少 2 位
		- 右侧 2 个数码管显示无效步数的十进制，至少 2 位

> ★ 钉死位置：8 个数码管里 **`digit7:digit6` = 有效步数**，**`digit1:digit0` = 无效步数**，中间 `digit5..digit2` 空白。

# 其他功能：
- 撤回：
	通过按键或拨码开关实现撤回，可以撤回到上一步。棋盘及统计信息同步撤回状态。
- 演示模式：
	通过"模式切换"开关或按键 选择游戏/演示模式；
	对初级用户进行游戏引导；
	要求：
	- 初始化棋盘和每步移动可硬编码
	- 通过"演示切换键"模拟下棋操作，触发各模块更新

# 其他：
- deadline：week16（Wed: 12月23日）为答辩周；
- 使用 git 做版本控制；
- 使用课程 Github Classroom 远程仓库管理项目；
- 项目视频文档（待后续发布）

---

# 模块划分：

> 命名已按课程站约定调整：`clk_reset`→`clk_div`、`key_debounce`→`btn_debounce`、`seg_driver`→`dynamic_display`、`top`→`huarongdao_top`。

- `huarongdao_top` 顶层（**A 独占，别人不改这个文件**）
	例化所有子模块，连接 EGO1 引脚；汇总拨码开关、按键、LED、数码管；*选择基础/高级显示路径*。

	**★ 分层顶层结构（三人并行、零文件冲突的关键）**：
	```
	huarongdao_top.v   (A 独占)  引脚 + clk_div×2 + btn_debounce×5 + 拨码同步 + 组间连线
	├── display_top.v  (B 独占)  例化 dynamic_display / display_ctrl / led_ctrl / view_toggle
	└── core_top.v     (C 独占)  例化 board_reg / init_validate / game_fsm
	```
	- A **不代写** B/C 的例化，只定义**组间信号**（约 20 根，见下）。
	- B/C 各自负责"自己的模块怎么连进系统"，写在各自的子顶层里。
	- 三个人从不同时修改同一个文件 → git 零冲突；也避免"合并时解错一根线、编译照样过"这种隐形 bug。

	**组间接口（A 定义，B/C 共用）**：
	| 信号 | 位宽 | 产生 | 消费 |
	|---|---|---|
	`tick_1khz` / `tick_2hz` | 1 / 1 | top | 两个子顶层 |
	`confirm_pos` / `view_pos` / `mode_pos` / `demo_pos` / `undo_pos` | 1 | top | core_top / display_top |
	`sw_num` | 4 | top | core_top |
	`board` | 36 | core_top | display_top |
	`cell_valid` | 9 | core_top | display_top |
	`zero_pos` | 4 | core_top | display_top（及 Sprint 3 的 move_check） |
	`init_*`（we/idx/data/error/error_idx/error_last/done） | — | core_top | core_top 内部 |
	`hint_mask` | 8 | (Sprint 4 的 hint_gen) | display_top |
	`valid_cnt` / `invalid_cnt` | 8 | (Sprint 3 的 step_counter) | display_top |
	`state` / `win` / `error_pulse` | 3 / 1 / 1 | core_top | display_top |
	`view_mode` | 1 | display_top | display_top 内部 |
	`cell9_data` / `cell9_error` / `cell9_blank` | 4 / 1 / 1 | display_top 内部 | display_top 内部 |

	注：若选择高级外设，需注意：
	- 基础主棋盘显示始终可工作；
	- K6仅切换主显示路径；
	- 左下 8 LED 的辅助提示/统计、K6/L1/M1/K3 状态灯始终走基础外设，不被高级模式替代；
	- 高级 UART/VGA/APP 的显示与 `board_reg/step_counter/game_fsm` 共享只读数据，不直接抢写；输入经命令接口送入`game_fsm/init_validate`，由主状态机决定是否写入`board_reg`。

- `clk_div` 分频器（课程标准模块，直接复用 Lab 5 代码）
	`clk_div #(parameter MAX_COUNT)`，输入 `clk/rst_n`，输出 `tick`（单周期脉冲）。
	实例化两次：
	- `clk_div #(.MAX_COUNT(100_000)) u_div_1khz` → `tick_1khz`（数码管扫描、消抖采样、K3 闪烁窗口计时）
	- `clk_div #(.MAX_COUNT(50_000_000)) u_div_2hz` → `tick_2hz`（K3 闪烁）
	注：
	- **不再有 `clk_reset` 模块**：复位直接用 `rst_n`（P15，低有效），各模块自己写 `negedge rst_n`。课程不要求做复位同步器。
	- **不要用 tick 当时钟**（Lab 5 明确禁止），tick 只做使能。
	
	注：复位清单：
	- `step_counter` 清零；
	- `board_reg` 清空/无效；
	- `init_validate` 计数和 `seen` 清零；
	- `view_toggle` 回默认；
	- `undo_ctrl` 快照清空；
	- K3 灭、L1/M1 回游戏模式、K6 按基础/高级选择；
	- 数码管空白、第 9 格 LED 灭、左下 8 LED 按默认提示或灭。

- `btn_debounce` 按键消抖（课程标准模块，直接复用 Lab 7 方法一代码）
	`btn_debounce #(parameter CNT_MAX = 21'd2_000_000)`，端口 `clk / rst_n / btn_in / btn_level / btn_pos / btn_neg`。
	**5 个按键例化 5 次**，不要写成一个 5 路的大模块：
	- `u_deb_confirm` → `confirm_pos`
	- `u_deb_view` → `view_pos`
	- `u_deb_mode` → `mode_pos`
	- `u_deb_demo` → `demo_pos`
	- `u_deb_undo` → `undo_pos`
	注：
	- **按键高电平有效**（Lab 7），`btn_pos` 就是"按下"那一下。不要写成 `_n`。
	- 复位键 P15 **不经过消抖**，直接当 `rst_n` 用；也不要用普通按键的方式处理。
	- 若要"按下就响应"，用 `btn_pos`；若要"按住持续"，用 `btn_level`。
	- 仿真时把 `CNT_MAX` 改小（如 `10`），上板前记得改回 `2_000_000`。

- 拨码同步（**本项目决定：不做同步，直接读**；两级触发器方案留作备选）
	**采用方案**：在 `huarongdao_top` 里直接
	```verilog
	wire [3:0] sw_num = sw[3:0];   // 数值输入 0~8，不打拍
	```
	理由：拨码是"人拨好 → 再按确认键"才读取，采样时早已稳定几百毫秒，亚稳态实际风险极低；课程 Lab 1 也是直接 `assign led = sw`。**代价已知**：理论上仍有亚稳态可能，答辩若被问"异步输入怎么处理"，要能答出"我们判断本场景采样时刻远离信号跳变，风险可接受；若要严格处理，加两级触发器即可"。

	备选方案（若决定改严格）：两级触发器内联在 top 里
	```verilog
	reg [15:0] sw_d1, sw_d2;
	always @(posedge clk or negedge rst_n) begin
	    if (!rst_n) begin
	        sw_d1 <= 16'd0;
	        sw_d2 <= 16'd0;
	    end else begin
	        sw_d1 <= sw;       // 第一级：可能进亚稳态
	        sw_d2 <= sw_d1;    // 第二级：输出已稳定
	    end
	end
	wire [3:0] sw_num = sw_d2[3:0];   // 数值输入 0~8
	```
	注：
	- **必须是两级，一级不算同步器。** 只打一拍（`sw_d <= sw`）时，那个触发器本身就可能处于亚稳态，等于没同步。
	- `_d` = delay，课程里同样用 `sig_d` / `btn_level_d` 表示"延迟一拍的寄存器"。
	- 只有 8 行，不值得单独建文件；多一个模块就多一个要对齐的接口。
	- **不要输出 `sw_cfg` 这类占位信号**。`sw[15:4]` 本期完全不用；将来真要用拨码做模式切换时再往端口上加，名字也别叫 `cfg`（要给具体名，如 `sw_mode`）。
	- 位宽待定：16 个拨码就 `[15:0]`，只有 8 个就 `[7:0]`，`sw_num` 始终取低 4 位。

- `init_validate` 初始化/输入解析
	输入计数；0~8 检查；重复性检查；
	输出`init_we/init_idx/init_data/init_error/init_error_idx/init_error_last/init_done`
	注：
	- `init_error` **必须是单周期脉冲**。写成电平保持的话，`display_ctrl` 每个扫描周期都会重判，`E` 会一直闪。
	- 非法时 `init_idx` **不递增**，本次输入作废，等用户重输。
	- 去重用位图 `seen[8:0]`，不要写 9 次循环比较。
	- 第 9 格输入非法时，输出 `init_error_idx`/`init_error_last` 交给 `led_ctrl` 和 `display_ctrl` 处理（LED 全亮或显示 E）

- `board_reg` 棋盘寄存器
	存储 3×3 棋盘，共 9 个 4-bit 寄存器；记录 0 号空位位置；支持初始化写入、有效移动交换、撤回恢复。
	输出 `board[35:0]`（`board[4*k +: 4]` = 第 k 格）、`cell_valid[8:0]`、`zero_pos[3:0]`。
	注：`cell_valid` 是渐进显示必需的（见上）；`board[0..8]` 在 Verilog 里打包成 `board[35:0]`。

- `move_check` 移动合法性检测
	根据输入棋子编号找到其位置；判断是否与 0 号空位上下左右相邻；
	输入`move_piece[3:0]/board[35:0]/zero_pos[3:0]`；
	输出 `valid_move/invalid_move/piece_pos[3:0]`。
	注：`board_reg`用`swap_en + piece_pos`交换棋子，这样就不需要`board_reg`自己找棋子位置；此外尝试移动 0 时，建议按无效移动处理，即无效步数+1，K3闪烁。

- `step_counter` 步数统计
	有效步数、无效步数计数器；支持清零、+1、撤回恢复；输出二进制数给 LED 和数码管（将二-十进制转换放到`display_ctrl`）。
	输出 `valid_cnt[7:0]`、`invalid_cnt[7:0]`（**8 bit 真实值**，别用 4 bit 存）。
	注：左下 4 个 LED 只能显示 4 bit，显示层统一 `min(cnt,15)` 饱和；数码管也显示 `min(cnt,15)`，保证 spec 要求的"数码管与 LED 一致"。

- `win_check` 通关判定
	比较 9 个棋格是否依次为 `1 2 3 4 5 6 7 8 0`；输出 `win` 状态。

- `hint_gen` 可移动提示
	根据空位位置计算可移动棋子编号；映射到 8 个 LED，分别对应 1~8 号棋子；游戏启动后和每次有效移动后更新。
	输出 `hint_mask[7:0]`，位序定死：**`hint_mask[7]` = 1 号棋 … `hint_mask[0]` = 8 号棋**（直接就是 LED 物理顺序，`led_ctrl` 原样透传，不做反转）。

- `display_ctrl` 显示控制
	管理数码管和 LED 的显示内容：输出 8 个数码管的字符码 `digit0~digit7`（各 4 bit）及第 9 格的 `cell9_data[3:0]`；通关统计显示选择。
	字符码约定：`4'd0`~`4'd9` 数字 / `4'd14` 字母 E / `4'd15` 空白。
	初始化时渐进显示或 `E`；第 9 格用 4 个 LED 显示二进制；通关后显示十进制步数；处理 0 号棋不显示。
	注：
	- 仅管理数据，不管理物理输出。
	- 0 号棋 → 该位字符码给 `4'd15`（空白），不是显示 `0`。
	- 第 9 格的两个异常由 `display_ctrl` 转成两根线传给 `led_ctrl`：`cell9_error`（非法 → 全亮）、`cell9_blank`（为 0 → 全灭）。

- `dynamic_display` 数码管驱动（课程标准模块，复用 Lab 6 代码）
	8 位七段数码管动态扫描；段码/位选译码。
	端口 `clk / rst_n / tick_1khz / digit0..digit7 / seg / an`；参数 `PERIOD`（或直接吃 `tick_1khz`）。
	注：
	- **`seg = {a,b,c,d,e,f,g,dp}`，a 是 bit7**（Lab 6 §2.7），不要写成 `{dp,g,f,e,d,c,b,a}`。
	- 数码管**共阴极，高电平点亮**。
	- **`an` 低有效**，one-hot，同一时刻只拉低一位。
	- **EGO1 的 8 位数码管分左右两组，各自共用一套段选**，所以顶层需要两套 `seg`/`an` 端口；具体引脚名见 `Ego1_UserManual_v2.2.pdf`。
	- 用 `tick_1khz` 做使能，**不要生成 `scan_clk` 再当时钟**。

- `led_ctrl` LED显示
	控制所有 LED 的物理输出：
	- 第 9 格二进制 LED（`led_cell9[3:0]`）；
	- 左下 8 个 LED 在"游戏提示"和"统计信息"之间切换（`led_low[7:0]`）；
	- K6/L1/M1/K3 模式与状态灯（`led_status[3:0]` = `{K6,L1,M1,K3}`）。
	注：关于K3：初始化非法输入、非法移动时闪烁；通关常亮>闪烁；其他情况灭。
	`led_ctrl`接收`error_pulse/error_flag`和`win`，内部用 `tick_2hz` 和带优先级MUX：

	⚠️ **`tick` 是单周期脉冲，不能直接当 K3 的电平用。** 写成 `K3 = err_flash ? tick_2hz : 0` 的话，K3 每 0.5 秒只亮 1 个 `clk` 周期（10 ns）—— 肉眼完全看不见，只有用示波器才测得到。正确做法是**用一个寄存器翻转**：

	```verilog
	reg k3_blink;
	always @(posedge clk or negedge rst_n) begin
	    if (!rst_n)          k3_blink <= 1'b0;
	    else if (tick_2hz)   k3_blink <= ~k3_blink;   // 每 0.5s 翻一次
	end

	assign K3 = win        ? 1'b1
	          : err_flash  ? k3_blink
	          :              1'b0;
	```
	翻转效果：亮 0.5 s、灭 0.5 s，**视觉闪烁 1 Hz** —— 这是指示灯的标准闪烁频率，而且和"常亮（通关）"区分得非常清楚。

	`err_flash` 由 `error_pulse` 置位，用 `tick_1khz` 展宽约 3 秒（数 3000 个 tick）。

- `view_toggle` 视图切换 (->`led_ctrl`)
	每次 `view_pos` 翻转 `view_mode`；`view_mode = 0` 游戏提示（复位默认），`1` 统计信息。

- `game_fsm` 游戏主控状态机
	统筹游戏阶段：复位/空闲、初始化、游戏进行、通关、通关后统计展示、演示模式；向各模块发使能信号。
	端口用课程约定：`state` / `next_state`，三段式，Moore 型；状态常量 `localparam`：
	```
	localparam IDLE     = 3'd0;
	localparam INIT     = 3'd1;
	localparam PLAY     = 3'd2;
	localparam WIN      = 3'd3;
	localparam WIN_STAT = 3'd4;
	localparam DEMO     = 3'd5;
	```

- `undo_ctrl` 撤回
	保存上一步棋盘和步数快照，*或使用历史栈（可选）*；撤回时恢复棋盘、空位位置、有效/无效步数，并刷新提示。
	注：
	- 通过写回端口恢复`board_reg`和`step_counter`，不直接改内部寄存器；
	- 确认移动后保存快照包含`board/zero_pos/valid_cnt/invalid_cnt`，撤回时恢复这四项；
	- `PLAY/WIN`状态可撤回，`WIN_STAT`先退出统计或直接回`PLAY`，`DEMO`不可撤回；
	- 建议无效移动可撤回（恢复无效步数）。

- `demo_ctrl` 演示模块
	根据"模式切换"进入演示；硬编码初始化棋盘和移动序列；用"演示切换键"推进：触发初始化、有效/无效移动、通关、统计展示、复位等流程。
	注：
	- 输出`demo_piece[3:0]`和`demo_confirm`传给`game_fsm`，走正常的移动判定，不绕过校验路径；
	- 硬编码初始化数据通过`init_validate`注入；
	- 模式切换建议在`IDLE/INIT`或复位后生效，运行中切换则直接复位进入对应模式；
	- L1/M1互斥（模式切换按键）；
	- 注意演示推进时的推进粒度（一步步走/一步到位）。

- （可选）高级外设接口
	可选实现二维棋盘展示和高级输入；与棋盘寄存器、步数、状态共享数据；不替代基础外设的辅助提示和统计输出。

## 模块图：
```
[拨码开关] ──→ (方案A: 直读, 不打拍) ──→ sw_num[3:0] ──┐
                                                      │
[确认/展示/模式/演示/撤回键] ──→ [btn_debounce ×5] ──┐  │
                                       │          │
[P15 复位] ───────────────────────────────────────┤
                                       ↓          ↓
                              [init_validate] ← [demo_ctrl]
                                       │          ↑
                                       │          │ demo_piece/demo_confirm
                                       ↓          │
                                [game_fsm] ───────┘
                                    │  │  │
          ┌────────────────────────┘  │  └────────────────────────┐
          ↓                           ↓                           ↓
   [board_reg]                [step_counter]                [undo_ctrl]
   board[35:0]                valid_cnt[7:0]               快照/恢复
   cell_valid[8:0]            invalid_cnt[7:0]             写回 board_reg
   zero_pos                   │                            写回 step_counter
          │                   │
          ├──────────→ [move_check] ──┘
          │              ↑ move_piece[3:0]
          │              │ board/zero_pos
          │              └─ valid_move/invalid_move/piece_pos[3:0]
          │                         │
          │                         └─ swap_en + piece_pos → board_reg
          │
          ├──────────→ [win_check] ──→ win
          │
          ├──────────→ [hint_gen] ──→ hint_mask[7:0]
          │
          └──────────→ [display_ctrl] ←── step_counter
                         │  ↑  ↑  ↑
                         │  │  │  └── init_error_idx / init_error_last
                         │  │  └───── win / state
                         │  └──────── valid_cnt/invalid_cnt
                         │
                         ├──→ [dynamic_display] ──→ seg ×2 / an ×2
                         │      ↑ tick_1khz
                         │
                         └──→ cell9_data[3:0] ──┐
                                 cell9_error     │
                                 cell9_blank     │
                                                 │
[view_toggle] ──→ view_mode ───────────────┐    │
                                           ↓    ↓
                                      [led_ctrl] ←── hint_mask[7:0]
                                           │    ←── valid_cnt/invalid_cnt 低4位
                                           │    ←── cell9_data/cell9_error/cell9_blank
                                           │    ←── win / state / error_pulse
                                           │    ←── tick_1khz / tick_2hz
                                           │
                                           ├──→ 第9格4个LED (K1-H6-H5-J5)
                                           ├──→ 左下8个LED (提示/统计切换)
                                           └──→ K6/L1/M1/K3 状态灯

[clk_div #(100_000)]   → tick_1khz  （扫描 / 消抖采样 / 闪烁窗口）
[clk_div #(50_000_000)] → tick_2hz   （K3 闪烁）

[可选高级显示 UART/VGA/APP] ·····只读共享····· board_reg / step_counter / game_fsm
[可选高级输入 键盘/UART/APP] ──命令接口──→ game_fsm / init_validate
                                      （不直接写 board_reg / step_counter）
```

## 关于棋盘寄存器 `board_reg`：
保存如下信息：
- `board[35:0]`：9 个 4-bit 棋子编号（`board[4*k +: 4]` = 第 k 格）；
- `cell_valid[8:0]`：每格是否已写入（渐进显示必需）；
- `zero_pos[3:0]`：0 号空位所在格索引，0~8；
以下信息交给对应模块：
- `valid_cnt`：有效步数 ->`step_counter`
- `invalid_cnt`：无效步数 ->`step_counter`
- `state`：初始化/游戏/通关/统计展示/演示等 ->`game_fsm`
- `view_mode`：提示/统计展示切换 ->`view_toggle`
- `game_mode`：游戏/演示 ->`game_fsm`
- `error_flag`：非法输入 ->`init_validate/game_fsm`
- 撤回快照：上一步的棋盘、空位、步数 ->`undo_ctrl`

## 关于游戏主控状态机 `game_fsm`：
`game_fsm` 可以设计成以下状态：
1. **IDLE / RESET**：复位后统计清零，棋盘不显示，等待初始化。
2. **INIT**：依次输入 9 个棋子编号；合法则写入棋盘，非法则显示 `E` 并闪烁状态灯。
3. **PLAY**：等待输入要移动的棋子编号；按确认后判定有效/无效并更新。
4. **WIN**：通关状态，点亮 K3 常亮；一维棋盘保持。
5. **WIN_STAT**：通关后按确认键，数码管显示有效/无效步数十进制。
6. **DEMO**：演示模式，按演示切换键推进硬编码步骤。
`view_toggle` 可独立于主状态机，只控制左下 8 个 LED 当前显示提示还是统计。

## 优先级建议：
按照分值和工作量，建议的顺序：
1. 时钟分频、按键消抖、拨码同步、数码管驱动、LED 控制。
2. 初始化 + 棋盘存储 + 非法输入处理
3. 移动合法性 + 有效/无效步数 + 二进制展示
4. 可移动提示 + 展示切换
5. 通关判定 + 通关后十进制统计
6. 撤回
7. 演示模式
8. 高级外设（可选）
核心：`board_reg + game_fsm + move_check + step_counter + display_ctrl`

---

# 设计决策记录（答辩素材 + 贡献留痕）

> 这张表的用处：① 答辩"project 相关简答"5 分的直接素材（评委爱问"你为什么这么设计"）；② 说明谁在思考，比代码行数更有说服力；③ 三个月后你自己会忘记当初为什么这么选。
> **新增决策就往后面加一行**，不要删旧的（改主意也要保留，写清"改过一次，因为…"）。

| # | 决策点 | 备选方案 | 选定 | 为什么 | 代价/已知不足 |
|---|---|---|---|---|---|
| 1 | 步数溢出（左下只有 4 bit） | 回绕 / 各自饱和 / 统一饱和 15 | **统一饱和 15** | spec 硬要求"数码管数值应与 LED 二进制一致"；回绕会在 15→0 突然全灭，像"清零" | >15 步看不到真实值（可用 8 bit 内部计数保留真值） |
| 2 | 显示模块粒度 | 一个模块全包 / 拆两个 | **`display_ctrl` + `dynamic_display`** | 内容与电气分离，`display_ctrl` 能脱离引脚单独仿真 | 多一根 32 bit 的字符码总线 |
| 3 | 时钟方案 | 分频出 `scan_clk` 当真时钟 / 单 `clk` + `tick` 使能 | **单 `clk` + `tick`** | Lab 5 §4.3 明确禁止分频信号当钟；避免跨时钟域 | 每个模块都要接一根 tick |
| 4 | 错误线数量 | 初始化错误 / 移动错误 各一根 / 汇总一根 | **汇总成 `error_pulse`** | `led_ctrl` 只需一根，K3 逻辑集中在一处 | 多一级传播延迟（可忽略） |
| 5 | K3 三态优先级 | 闪烁优先 / 常亮优先 | **常亮 > 闪烁 > 灭** | 通关是终局状态，闪烁表示"正在出错"，两者同时发生时应该显示成功 | spec 未规定，属于自定 |
| 6 | `cell_valid` 由谁输出 | `game_fsm` / `board_reg` | **`board_reg`** | 它是棋盘本身的属性（哪些格写过），`display_ctrl` 直接消费 | `board_reg` 多一根输出 |
| 7 | 顶层结构 | 单一 top / 分层三个子顶层 | **分层**（top + display_top + core_top） | 三人并行、git 零文件冲突、组内连线责任下放 | 多一层层次，答辩需解释 |
| 8 | 拨码同步 | 不打拍 / 一级 / 两级 | **不打拍，直接读 `sw[3:0]`** | 采样时刻是"人拨好再按确认键"，远离信号跳变；与课程 Lab 1 一致 | 理论上仍有亚稳态可能；答辩需能解释这个判断。若要严格，改两级触发器（8 行） |
| 9 | 逐步显示 vs 一次性显示 | 全部输入完再显示 / 输一格亮一格 | **输一格亮一格**（spec 要求） | 用户能看见进度 | 需要 `cell_valid` |
| 10 | 键盘/拨码的界面约定 | — | **`sw[3:0]` 输数值，按键全部走消抖脉冲** | 与 spec"最左为最高位"一致；按键高有效（Lab 7） | — |
