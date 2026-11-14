# CS207 数字华容道 — Sprint 1 三人分工单

> **范围**：总览「优先级建议」第 1、2 项 —— 平台基础设施 + 显示驱动 + 初始化落地。
> **不在本期**：移动判定、步数统计、通关判定、可移动提示、撤回、演示模式、高级外设（只留端口占位）。
> **接口见 [`Project总览.md`](Project总览.md) 的「模块划分」一节**，本文只讲"谁做什么、做到什么程度算完"。
> **命名按课程站约定**（见总览「命名规范」）：`clk_div` / `btn_debounce` / `dynamic_display` / `tick` 做使能不做时钟 / 低有效只有 `rst_n` / 参数全大写。

---

## 0. 两层集成（整个分工的核心思想）

> **B 集成自己的四个模块 → C 集成自己的三个模块 → A 集成 B 和 C。**

```
              huarongdao_top.v   (A 独占)
              引脚 / clk_div×2 / btn_debounce×5 / 拨码同步 / 组间连线
                    │
        ┌───────────┴───────────┐
        ↓                       ↓
 display_top.v (B 独占)    core_top.v (C 独占)
 例化 dynamic_display      例化 board_reg
      display_ctrl                init_validate
      led_ctrl                    game_fsm
      view_toggle
        │                       │
        └──── board / cell_valid / zero_pos ────┘
              （C 生产，B 消费，只读不反向）
```

**三个人从不同时改同一个文件**，所以 git 零冲突。这是分层顶层的唯一目的，也是最重要的收益。

| 组 | 角色 | 交付文件数 | 最容易卡住的地方 |
|---|---|---|---|
| A | 平台 + 顶层集成 | 4 RTL + xdc + 2 tb | 第 1 天必须交空壳，否则 B/C 全停 |
| B | 显示域 | 5 RTL + 3 tb | 需要 `board`/`cell_valid` 的语义，C 第一天就要给准 |
| C | 核心域 | 4 RTL + 2 tb | `init_error` 必须单周期，否则 B 组 `E` 显示会连闪 |

---

## 1. 文件所有权（铁律）

| 文件 | 唯一作者 | 别人能不能碰 |
|---|---|---|
| `huarongdao_top.v`、`huarongdao_top.xdc` | **A** | 不能。要加线 → 群里提 → A 改 |
| `display_top.v`、`dynamic_display.v`、`display_ctrl.v`、`led_ctrl.v`、`view_toggle.v` | **B** | 不能 |
| `core_top.v`、`board_reg.v`、`init_validate.v`、`game_fsm.v` | **C** | 不能 |
| `clk_div.v`、`btn_debounce.v` | **A**（抄课程代码） | 不能 |
| `docs/` | 三人共写 | 可以，但要 review |
| `.gitignore`、`README.md` | A | 可以提意见 |

**违反这条的后果比你想的严重**：A 为了"让 top 跑起来"顺手改了 `display_ctrl`，B 组交实现时就会冲突，而且冲突在 D5 才发现 —— 那时候已经没时间了。

### 子顶层的端口归谁

**`display_top.v` / `core_top.v` 的整个文件（含端口声明）都归 B / C 写**，A 不代写。但有一条前置条件：

| 谁定 | 定什么 |
|---|---|
| **A**（D1 上午已完成） | 总览「组间接口」那张表：信号名、位宽、从谁到谁 |
| **B / C**（D1 结束前） | 按那张表，把自己子顶层的端口声明写出来推上 `main` |
| A（D2） | 拿到端口后，在 `huarongdao_top` 里例化两个子顶层 |

**为什么 B/C 必须先交端口**：A 的 top 里要写

```verilog
display_top u_display_top (
    .clk       (clk),
    .board     (board),
    .seg_left  (seg_left),
    ...
);
```

端口名字不存在，这行就是编译错误。A 的 top 不动工，A 的 `xdc` 也就无从下手（xdc 要完整端口列表）。

**所以硬性时间点是：D1 结束前，两个子顶层的端口必须出现在 `main` 上。** 那时实现可以是空的（`assign` 常量），只要端口在。

A 合并时的检查项就一条：**端口名/位宽是否和总览「组间接口」完全一致**。一致就合，不一致打回重看表。

---

## 2. A 组：平台 + 顶层集成

### 交付清单

| 文件 | 内容 | 截止 |
|---|---|---|
| `rtl/clk_div.v` | 复用 Lab 5 代码，`#(parameter MAX_COUNT)`，出 `tick` | D1 空壳，D1 实现 |
| `rtl/btn_debounce.v` | 复用 Lab 7 方法一代码，`#(parameter CNT_MAX = 21'd2_000_000)` | D1 空壳，D2 实现 |
| `rtl/huarongdao_top.v` | 引脚 + `clk_div`×2 + `btn_debounce`×5 + 拨码直读（方案 A，1 行）+ 组间连线 + 两个子顶层例化 | **D2**（依赖 B/C 的端口声明） |
| `xdc/huarongdao_top.xdc` | 全部引脚（16 拨码 + 5 按键 + 两组数码管 + 16 LED + P17 + P15） | D4 |
| `tb/tb_clk_div.v`、`tb/tb_btn_debounce.v` | 见第 5 节 | D3 |

> **`sw_sync.v` 已删除** —— 采用方案 A：`huarongdao_top` 里直接 `wire [3:0] sw_num = sw[3:0];`。理由与代价见总览「设计决策记录」第 8 条（答辩要能解释：采样时刻是人拨好再按确认键，远离信号跳变）。

### D1 上午必须做的三件事（顺序不能换）

**① 建仓库骨架（30 分钟）**

```
huarongdao/
├── rtl/      xdc/      tb/      docs/
├── .gitignore
└── README.md
```

`.gitignore`：
```
*.jou
*.log
*.dcp
*.Xil/
.Xil/
*.str
*.wdb
```

**② 建全部 12 个空壳文件，推到 `main`（1 小时）**

按接口表逐个建，**端口一字不差**，模块体只写 `assign` 常量 + `// TODO` 注释。输出必须显式赋值，不能留空 module——悬空输出在仿真里是 `X`，B/C 会以为是自己写错。

**③ 群里通知 B/C clone + 建分支**

### 你的 module 清单（写成代码前对一遍）

| 实例名 | 模块 | 参数 | 输出 |
|---|---|---|---|
| `u_div_1khz` | `clk_div` | `MAX_COUNT(100_000)` | `tick_1khz` |
| `u_div_2hz` | `clk_div` | `MAX_COUNT(50_000_000)` | `tick_2hz` |
| `u_deb_confirm` | `btn_debounce` | `CNT_MAX(2_000_000)` | `confirm_pos` |
| `u_deb_view` | `btn_debounce` | 同上 | `view_pos` |
| `u_deb_mode` | `btn_debounce` | 同上 | `mode_pos` |
| `u_deb_demo` | `btn_debounce` | 同上 | `demo_pos` |
| `u_deb_undo` | `btn_debounce` | 同上 | `undo_pos` |
| `u_display_top` | `display_top` | — | `seg_left/an_left/seg_right/an_right/led_low/led_cell9/led_status` |
| `u_core_top` | `core_top` | — | `board/cell_valid/zero_pos/...` |

### 验收标准（D6 上板）

- [ ] 按 P15 复位，所有 LED 全灭、数码管全灭，松开后系统正常启动
- [ ] 临时挂调试计数器（验收后删），按任意功能键**每次只加 1**，按住不连续加
- [ ] `tick_1khz` 用 ILA 或计数器验证周期确实是 100_000 个 `clk`
- [ ] `xdc` 全部端口有约束，综合 **0 critical warning**

### 常见坑

- **按键高电平有效**（Lab 7）。写成 `_n` 低有效，全部按键逻辑反，且仿真"看起来有反应"，极难发现。
- **复位键 P15 低有效**，与功能键极性相反；直接当 `rst_n`，**不进 `btn_debounce`**。
- **数码管段码位序 `seg = {a,b,c,d,e,f,g,dp}`，a 在 bit7**。
- **`an` 低有效**，one-hot。
- **8 位数码管分左右两组、各自共用段选**，xdc 里是两套。
- **LED 映射两份课程材料不一致**（Lab 1 `led[7]=F6`，Lab 6 跑马灯反）。按 spec"最左为最高位"取 Lab 1，并对照 `Ego1_UserManual_v2.2.pdf` 复核。
- 仿真时把 `MAX_COUNT`/`CNT_MAX` 改小，**上板前改回**。

---

## 3. B 组：显示域

### 交付清单

| 文件 | 内容 | 截止 |
|---|---|---|
| `rtl/view_toggle.v` | `view_pos` 的 1 bit 翻转（复位后 = 游戏提示） | D1 |
| `rtl/dynamic_display.v` | 复用 Lab 6 扩到 8 位：动态扫描 + 4bit→段码 | D2 |
| `rtl/display_ctrl.v` | `digit0~digit7` + `cell9_data/cell9_error/cell9_blank` | D3 |
| `rtl/led_ctrl.v` | `led_low` + `led_cell9` + `led_status`，含 K3 三态 | D4 |
| `rtl/display_top.v` | **端口由 B 自己声明**（按总览「组间接口」）；例化上面四个模块 + 接线 | **D1 端口 / D5 实现** |
| `tb/tb_dynamic_display.v`、`tb/tb_display_ctrl.v`、`tb/tb_led_ctrl.v` | 见第 5 节 | 跟随模块 |

> ⚠️ **`display_top.v` 的端口必须 D1 结束前推上 `main`。** A 要在自己的 `huarongdao_top` 里例化它，没有端口名字 A 写不下去。端口写完可以立刻推一个只有 `assign` 常量的版本，实现留到 D5。

### 你要接的线（`display_top` 里）

输入（来自 top 和 core_top）：
```
clk, rst_n, tick_1khz, tick_2hz, view_pos,
board[35:0], cell_valid[8:0], hint_mask[7:0],
valid_cnt[7:0], invalid_cnt[7:0],
win, state[2:0], error_pulse, error_flag   // 后四个本期可先忽略
```
输出（到 top 的引脚）：
```
seg_left[7:0], an_left[3:0], seg_right[7:0], an_right[3:0],
led_low[7:0], led_cell9[3:0], led_status[3:0]
```

### 必须自己覆盖的 5 个显示场景

`display_ctrl` 的分数全在这 5 个场景里：

| # | 场景 | 期望 |
|---|---|---|
| 1 | 复位后什么都没输入 | `digit*` 全 `4'd15`（空白） |
| 2 | 只输 3 格（`1 2 3`） | 只亮前 3 位，第 4~8 位空白 |
| 3 | 某格是 0 号棋 | 该位空白（不是显示 `0`） |
| 4 | 第 6 格输错 | 第 6 位 `4'd14`（E），其余保持 |
| 5 | 第 9 格非法 | 4 颗 LED 全亮（不是数码管），`cell9_error = 1` |

### 验收标准（D6 上板）

- [ ] 8 位数码管显示 `0 1 2 3 4 5 6 7`，**无重影、无明显闪烁**
- [ ] 单个数码管亮度均匀
- [ ] 按展示切换键，左下 8 灯在提示/统计之间翻转，**复位后是提示**
- [ ] `valid_cnt = 20` 时左下高 4 位全亮（饱和 15 → `4'hF`），不是 `4'h4`
- [ ] 非法输入后 K3 闪约 3 秒自动灭

### 常见坑

- **`display_ctrl` 只出 4bit 字符码，不碰引脚**。段码译码在 `dynamic_display`。写成直接驱动端口说明职责错了。
- 扫描用 `tick_1khz` 做**使能**，`always @(posedge clk)`。**不要生成 `scan_clk` 再当时钟**（Lab 5 禁止，Lab 6 那段是反例）。
- `hint_mask` 是**物理顺序**（bit7 = 1 号棋），不是 bit1 = 1 号棋。错了提示灯全反。
- K3 不是 1 bit，而是**三态**：`win ? 1 : err_flash ? k3_blink : 0`。
  ⚠️ **不能直接写 `tick_2hz`** —— tick 是 10 ns 的单周期脉冲，肉眼看就是"永远不亮"。必须用 `if (tick_2hz) k3_blink <= ~k3_blink;` 翻转，得到亮 0.5 s / 灭 0.5 s。
- `an` **低有效**，别写成一热拉高。

---

## 4. C 组：核心域

### 交付清单

| 文件 | 内容 | 截止 |
|---|---|---|
| `rtl/board_reg.v` | `board[35:0]` + `cell_valid[8:0]` + `zero_pos[3:0]` | D1 |
| `rtl/init_validate.v` | 合法性 + 位图去重 + 非法不递增 + `init_done` | D3 |
| `rtl/game_fsm.v` | 三段式骨架 `IDLE ⇄ INIT → PLAY` | D4 |
| `rtl/core_top.v` | **端口由 C 自己声明**（按总览「组间接口」）；例化上面三个模块 + 接线 | **D1 端口 / D5 实现** |
| `tb/tb_board_reg.v`、`tb/tb_init_validate.v` | 见第 5 节 | 跟随模块 |

> ⚠️ 同样：**`core_top.v` 的端口必须 D1 结束前推上 `main`**，否则 A 没法在自己的 top 里例化它。

### 你要接的线（`core_top` 里）

输入（来自 top）：
```
clk, rst_n, sw_num[3:0], confirm_pos
```
输出（给 display_top 和 top）：
```
board[35:0], cell_valid[8:0], zero_pos[3:0],
state[2:0], win, error_pulse
```

### D1 下班前必须做的一件事

**在群里公告 `board` / `cell_valid` / `zero_pos` 三个信号的最终定义**（位序、含义、什么时候变）。B 组照这个写 `display_ctrl`，你不发，B 组就是在猜。

### `init_validate` 必须满足的 4 条时序

| 事件 | 期望 |
|---|---|
| 合法输入 | `init_we` 出 **1 个**周期；`init_idx` 递增 |
| 非法（超范围/重复） | `init_error` 出 **1 个**周期；`init_idx` **不递增**；`init_we` **不出** |
| 第 9 格非法 | 额外 `init_error_last = 1` |
| 第 9 格合法 | `init_done` 出 **1 个**周期，之后不再出 |

> ⚠️ `init_error` **必须单周期**。写成电平保持，B 组的 `E` 会一直闪 —— 本期最高频 bug。

### 验收标准（D6 上板）

- [ ] 输入 `1 2 3 4 5 6 7 8 0` → `board == 36'h0_87654321`、`zero_pos == 8`、`cell_valid == 9'h1FF`
- [ ] 第 6 格输 `10` → `init_error` 1 次、`init_error_idx == 5`、`init_idx` 仍是 5
- [ ] 第 6 格输重复 → 同上
- [ ] 第 9 格输重复 → `init_error_last == 1`
- [ ] 出错后重输正确值，`init_idx` 从卡住那格继续，`cell_valid` 正常累积
- [ ] 中途按 P15 → `init_idx`/`cell_valid`/`board` 全归 0

### 常见坑

- **去重用位图 `seen[8:0]`**，不要 9 次循环比较。
- 复位后 `game_fsm` 进 `INIT`，`init_start` 打一拍——**别和 `init_validate` 复位同拍**。
- `game_fsm` 里**不要**直接改棋盘，只发 `init_we`。
- 三段式里 `case` 前先写默认赋值，否则综合出锁存器。

---

## 5. testbench（7 个，一个都不能省）

统一格式（Lab 5 §5.4）：

```verilog
`timescale 1ns/1ps

module tb_xxx();
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
```

| testbench | 负责 | 用例 | 通过标准 |
|---|---|---|---|
| `tb_clk_div` | A | `MAX_COUNT(10)` | `tick` 每 10 周期出 1 个单周期脉冲 |
| `tb_btn_debounce` | A | 抖动 20 次后稳定按下 | `btn_pos` 恰好 1 周期、只出现 1 次 |
| `tb_board_reg` | C | 写 9 格 + 中途复位 | `cell_valid` 单调累积；`zero_pos` 跟随 0 号棋 |
| `tb_init_validate` | C | ①`1..8,0` ②中途 `10` ③中途重复 ④第 9 格非法 | ①`init_done` 1 次 ②③`init_error` 1 次且 `init_idx` 不变 ④`init_error_last=1` |
| `tb_dynamic_display` | B | 灌 `0~7` 走 8 位轮扫 | `an` 每周期只低一位；`seg` 位序对 |
| `tb_display_ctrl` | B | 5 个显示场景 | 未填格 `4'hF`；0 号棋 `4'hF`；E `4'hE` |
| `tb_led_ctrl` | B | `valid_cnt=3/20`、`view_mode` 翻转、`error_pulse` 后数窗口 | 3→`4'h3`；20→`4'hF`；K3 随 `tick_2hz` 翻转 |

**规矩：模块没 tb 不算完成。**

---

## 6. 集成节奏

| 时间 | 动作 | 责任人 |
|---|---|---|
| **D1 上午** | 建仓库骨架 → 推 A 自己的 3 个文件（`clk_div` / `btn_debounce` / `huarongdao_top` 骨架）+ 建 B/C 的 7 个模块空壳 → 通知 B/C | A |
| **D1 上午** | 三方逐条过「组间接口」表，有异议当场改 | 全员 |
| **D1 下午** | B/C `clone` + 建分支，确认能编译 | B/C |
| **D1 下班前** | **B 推 `display_top` 端口、C 推 `core_top` 端口**（实现可为 `assign` 常量） | B / C |
| **D1 下班前** | 群里公告 `board`/`cell_valid`/`zero_pos` 定义 | C |
| **D2** | A 拿到两个子顶层端口 → 补完 `huarongdao_top` 的例化与组间连线 → 跑综合 | A |
| **D2-D4** | 各自实现 + tb，每天 push；晚上 `rebase main` | 全员 |
| **D3-D4** | A 写 `xdc`（先查手册补 16 拨码 + 两组数码管引脚） | A |
| **D5** | B 集成 `display_top`、C 集成 `core_top`、A 复核 `huarongdao_top` 连线 | 各自 |
| **D6** | **B 主导上板冒烟**（显示是最终可见输出），C 配合查内部信号，A 只看综合与时序 | B 主导 |

**每天 5 分钟同步**（只回答三句）：① 昨天完成什么 ② 今天做什么 ③ 有没有被谁卡住。

---

## 7. Git 流程（直接影响个人贡献比）

```
main
├── feat/platform   (A)
├── feat/display    (B)
└── feat/core       (C)
```

| 规则 | 说明 |
|---|---|
| 分支 | 每人一条 `feat/*`；`main` 只接受 PR 合入 |
| PR | 谁写完谁提 PR，**由 A review 后合**（唯一例外：A 的 PR 由 B 或 C review） |
| commit 粒度 | **一个模块一个 commit**，不要攒到最后一天一次性提交 |
| commit message | `feat(clk_div): 实现 1kHz 分频` / `fix(init_validate): init_error 改单周期` |
| push 前 | 先 `git rebase main` |
| **Sprint tag** | 每个 Sprint 收工时打 `git tag sprint1-done`，**现在就约定，答辩前补不回来** |
| 不提交 | `*.jou` `*.log` `*.dcp` `*.Xil/` |

> 个人贡献比按小组自评 + 实际工作量。**commit 分布 + tag + PR review 记录**就是最硬的证据。

---

## 8. A 的 Review 清单（每次合并 PR 照这 6 条过）

```
□ 1. 端口名/位宽/方向 和总览接口表一字不差
□ 2. 极性对不对       按键高有效、an 低有效、rst_n 低有效
□ 3. 位序对不对       seg={a..dp}、hint_mask[7]=1号棋、board[4k+:4]
□ 4. 有没有用 tick 当时钟   always @(posedge tick_xxx) → 一律打回
□ 5. 有没有碰别人的文件     diff 里出现不该他改的文件 → 打回
□ 6. 组合 case 有没有默认赋值    否则综合出锁存器
```

前 5 条看 diff 就能发现，第 6 条看代码。**这 6 条过了，D5 集成基本不会出问题。**

---

## 9. 本期交付物检查表

```
rtl/     clk_div.v  btn_debounce.v  huarongdao_top.v
         display_top.v  display_ctrl.v  dynamic_display.v  led_ctrl.v  view_toggle.v
         core_top.v  board_reg.v  init_validate.v  game_fsm.v
xdc/     huarongdao_top.xdc
tb/      tb_clk_div.v  tb_btn_debounce.v  tb_board_reg.v  tb_init_validate.v
         tb_dynamic_display.v  tb_display_ctrl.v  tb_led_ctrl.v
docs/    Project总览.md  CS207_Sprint1_评审.md  CS207_Sprint1_三人分工.md  README.md
```

12 个 RTL + 1 个 xdc + 7 个 tb + 4 个文档。

---

## 10. Sprint 1 验收流程（D6 由 B 照着跑）

```
① 上电 → 数码管全灭、16 个 LED 全灭
② 按 P15 复位 → 仍全灭，K3 灭
③ 拨码 1，按确认 → 第 1 个数码管显示 1
④ 拨码 2，按确认 → 第 2 个显示 2          ← 渐进显示，第 3~8 位仍空白
⑤ 拨码 5（重复），按确认 → 第 3 位显示 E，K3 开始闪
⑥ 拨码 3，按确认 → 第 3 位变 3，K3 停止闪  ← 非法后可恢复
⑦ 依次输 4 5 6 7 8 → 数码管显示 1 2 3 4 5 6 7 8
⑧ 拨码 0，按确认 → 最右位数码管空白，4 颗 LED 全灭
⑨ 按展示切换 → 左下 8 灯全灭（有效 0、无效 0）
⑩ 再按一次 → 回到提示模式
⑪ 按 P15 → 回到 ① 的全灭状态，可以重新来过
```

第 ⑤ 步第一次跑大概率失败——`E` 一直闪不停，原因是 `init_error` 写成了电平保持。先查它。

---

## 附：三个人的"一句话定义"

- **A**：让别人今天下午就能编译，并保证两根线接的是同一根线。
- **B**：让棋盘在板子上**看得见**，且 5 个显示场景一个不漏。
- **C**：让 `board` / `cell_valid` / `zero_pos` 这三根线的语义**不再被质疑**。
