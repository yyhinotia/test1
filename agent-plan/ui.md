# UI 主题计划

> 最后修改：2026-09-25T13:54:22+08:00  
> 主题：ui  
> 规则来源：`../AGENTS.md`

## INC-UI-001：实现 Pawn 验证场景 HUD

- 状态：accepted
- 创建时间：2026-09-25T13:21:58+08:00
- 最后修改：2026-09-25T13:43:51+08:00
- 主题：ui
- 目标：让 Pawn MVP 的关键状态可被玩家直接观察和验收。
- 验收标准：
  - 左键点击玩家 Pawn 后出现清晰的选中标识。
  - 每个 Pawn 显示生命条，并在护盾或生命变化时刷新。
  - HUD 显示操作提示、当前暂停状态和选中单位信息。
  - 暂停时显示明确的暂停覆盖层，恢复后消失。
  - 重要状态不只依赖颜色，使用文字或形状辅助表达。
- 范围：`game/ui/**`、`game/main/main.tscn` 中的 HUD 节点、`game/pawns/health_bar.gd` 与相关场景节点。
- 非范围：正式主题、菜单、设置页面、像素素材替换、完整战斗界面、技能栏和多选操作面板。
- 依赖：`INC-PAWNS-001`、`INC-COMBAT-001` 的生命与状态信号。
- 风险：如果 HUD 直接轮询所有 Pawn，会造成耦合和性能浪费；本 Increment 使用场景信号和当前选中对象。
- 实现说明：
  - 使用 `Control`、`PanelContainer`、`VBoxContainer` 和 `Label` 搭出最小 HUD。
  - `PawnHealthBar` 自绘护盾与生命两层数值，受击后由 Pawn 主动刷新。
  - 选择框使用 `Line2D`；选中和死亡状态通过 `Pawn.set_selected()` 更新。
  - 玩家 Pawn 的 `health_changed`、`shield_changed`、`state_changed` 和 `died` 信号在场景中连接到 HUD。
  - 暂停覆盖层使用 `Control` 和 `ColorRect`，暂停状态额外使用文字和覆盖层，不只依赖颜色。
- 变更文件：
  - `game/ui/pawn_health_bar.gd`
  - `game/ui/arena_backdrop.gd`
  - `game/main/main.gd`
  - `game/main/main.tscn`
  - `game/pawns/pawn.tscn`
  - `game/pawns/player_pawn.tscn`
  - `game/pawns/enemy_pawn.tscn`
- 测试证据：
  - 左键选择玩家后，`SelectionIndicator.visible = true`；HUD 显示 `测试修士`、`player`、HP 和护盾。
  - 攻击过程中 HUD 文本实时更新，例如 `HP：120 / 120 护盾：40 / 40` 变为 `HP：104 / 120 护盾：0 / 40`。
  - 暂停后 `PauseOverlay` 出现，`PauseStateLabel` 变为 `游戏已暂停`；恢复后覆盖层消失并回到 `实时运行中`。
  - 在 1152x648、1152x720、800x720 三种窗口尺寸下读取 UI 元素，HUD、血条、选中信息和暂停标签均在逻辑视口内；800x720 时逻辑视口为 1152x1036。
  - 截图证据：`.mcp/godot-runtime/screenshots/screenshot_1790314251_89.png`（移动/战斗）、`screenshot_1790314283_184.png`（16:10）、`screenshot_1790314287_913.png`（800x720）、`screenshot_1790314402_601.png`（敌人死亡）、`screenshot_1790314406_356.png`（暂停覆盖层）。
  - 复验（选中）：左键点击玩家 Pawn 后 SelectionIndicator.visible 由 false 变为 true，SelectedLabel 显示 测试修士 / 阵营：player / HP：120 / 120 护盾：40 / 40 / 状态：待命。
  - 复验（暂停覆盖层）：Space 后 PauseOverlay 出现、PauseStateLabel 变为 游戏已暂停；再次 Space 后覆盖层消失并回到 实时运行中。
  - 复验（布局）：运行态读取 HUD 面板 rect 为 1120x162 @ (16, 16)，两个 Pawn 血条为 72x16，暂停覆盖层覆盖完整逻辑视口 1152x690。
  - 复验截图：.mcp/godot-runtime/screenshots/screenshot_1790314698_188.png（敌人死亡）、screenshot_1790314702_467.png（暂停覆盖层）。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:43:51+08:00
- 已知问题：HUD 文案仍为 MVP 硬编码中文，尚未接入 `tr()`/翻译键；未做正式视觉设计和屏幕阅读器检查。
- 用户验收：已验收
- 验收时间：2026-09-25T13:43:51+08:00
- Git：分支 main，commit d7c2e1e（feat(pawns): add pawn MVP with movement, combat, HUD and pause [INC-CROSS-001]）
- 备注：此 Increment 是 `INC-CROSS-001` 的子 Increment。

## INC-UI-002：血条改为生命状态变化时显示并延迟自动隐藏

- 状态：accepted
- 创建时间：2026-09-25T13:54:22+08:00
- 最后修改：2026-09-25T14:10:35+08:00
- 主题：ui
- 目标：按 `docs/血条ui需求.txt` 的方案，把 Pawn 头顶血条由“常驻显示”改成“生命状态变化时立即显示、最后一次变化后 2 秒无变化再隐藏”，减少战场 UI 噪音（当前 2 个单位，目标战斗规模为 4v4 / 4-8 单位）。
- 验收标准：
  - 场景启动后，所有 Pawn 的头顶血条初始隐藏（`visible == false`）。
  - 生命值或护盾发生变化时，对应 Pawn 的血条在同一帧变为可见，并显示最新数值。
  - 最后一次生命状态变化后 2.0 秒（`auto_hide_delay`，可配置）无新变化，血条自动隐藏，且不做渐隐（需求文档规则 4：MVP 先直接隐藏）。
  - 连续变化会重置隐藏计时：t=0/1/2 秒连续变化时，直到 t=4 秒才隐藏。
  - 护盾变化（不只是掉血）同样触发显示；死亡也触发显示，之后按同一规则隐藏。
  - 血条仍固定在 Pawn 头顶锚点（`Pawn/HealthBarAnchor/HealthBar`），Pawn 移动时跟随。
  - 暂停期间血条不因暂停消失（隐藏计时随 `SceneTree.paused` 冻结）。
  - 不引入 GDScript 解析错误、场景加载错误和信号断链。
- 范围：`game/ui/pawn_health_bar.gd`、`game/ui/pawn_health_bar.tscn`（新增）、`game/pawns/pawn.tscn` 中的 `HealthBarAnchor/HealthBar` 结构、`test/headless/health_bar_visibility_test.gd`（新增，自建 headless 验证）、`test/tools/capture_health_bar_evidence.gd`（新增，截图证据脚本）。
- 非范围：渐隐/闪烁动画（需求文档列为第二阶段）、治疗与护盾技能、HUD 信息面板改造、正式血条美术、HealthComponent 抽取（见 `INC-PAWNS-003`）。
- 依赖：`INC-UI-001`（常驻血条现状）、`INC-PAWNS-001`、`INC-PAWNS-002`（生命状态变化统一入口）。
- 风险：可见性由常驻改为事件驱动，若未来有代码绕过统一入口直接修改 `current_health`，血条不会出现；通过 `Pawn.notify_health_state_changed()` 单一入口降低风险，并写入已知问题。
- 实现说明：
  - `PawnHealthBar` 改为事件驱动：`notify_health_state_changed()` 刷新数值并立即 `reveal()`，`tick()`/`_process()` 做倒计时，归零后 `hide_now()`；隐藏时 `set_process(false)`，避免每帧空转。
  - `set_values()` 只同步数值、不改变可见性，用于初始化与无事件同步；`auto_hide_delay <= 0` 保留为“常驻显示”的逃生开关（默认 2.0 秒）。
  - 血条独立为 `game/ui/pawn_health_bar.tscn`（根 `Control` 默认 `visible = false`），Pawn 通过 `HealthBarAnchor` 节点挂载其实例，保持头顶位置。
  - 未做渐隐/闪烁动画，按需求文档规则 4 保持 MVP 的“直接隐藏”。
- 变更文件：
  - `game/ui/pawn_health_bar.gd`（改为状态变化驱动显示 + 自动隐藏）
  - `game/ui/pawn_health_bar.tscn`（新增，独立血条场景，根节点默认隐藏）
  - `game/pawns/pawn.tscn`（`HealthBarAnchor` + `pawn_health_bar.tscn` 实例，移除内联血条节点）
  - `game/pawns/pawn.gd`（新增 `notify_health_state_changed()`，伤害/死亡通过统一入口刷新）
  - `test/headless/health_bar_visibility_test.gd`（新增，自建 headless 断言）
  - `test/tools/capture_health_bar_evidence.gd`（新增，截图证据脚本）
- 测试证据：
  - 替代原因：2026-09-25 本会话 Godot MCP 工具调用返回 `unsupported call`，按 `AGENTS.md` §6 改用 Godot 4.7.2 CLI headless 与自建脚本做等价验证。
  - headless 断言：`godot --headless --path . --script res://test/headless/health_bar_visibility_test.gd` → 退出码 0，输出 `CHECKS=38 FAILURES=0` / `HEALTH_BAR_TEST_OK`。覆盖：初始隐藏、变化同帧显示、2 秒自动隐藏、连续变化重置计时、护盾变化触发、死亡触发、`Pawn/HealthBarAnchor/HealthBar` 路径与头顶坐标 (364,246)（Pawn 在 (400,300) 时）、暂停冻结计时、恢复后隐藏。
  - 运行态真实计时（同一脚本）：伤害后血条同帧显示，`HIDE_ELAPSED_MS=1972` 后自动隐藏；暂停 30 帧后 `PAUSED_BAR_VISIBLE=true`；恢复运行后 `RESUME_HIDE_ELAPSED_MS=2030` 隐藏。
  - 主场景冒烟：`godot --headless --path . --quit-after 600` → 退出码 0，无脚本解析错误、节点缺失或信号断链（仅有沙箱环境导致的 `user://logs/godot.log` 写入警告，与本改动无关）。
  - 截图证据（1152x648 真实渲染，脚本 `test/tools/capture_health_bar_evidence.gd`）：`.mcp/godot-runtime/screenshots/health_bar_01_idle.png`（无血条）、`health_bar_02_player_hit.png`（玩家血条出现）、`health_bar_03_both_hit.png`（双方血条）、`health_bar_04_hidden_after_delay.png`（延迟后隐藏）、`health_bar_05_paused_still_visible.png`（暂停中仍显示）、`health_bar_06_hidden_after_resume.png`（恢复后隐藏）。
  - 截图像素核验：idle 帧玩家血条区域绿色像素 0；玩家受击帧 621 px，bbox `(834,362)-(902,370)`，与 Pawn(870,410) 头顶 -46px 锚点 + 72x16 血条预期一致；双方受击帧 1188 px；暂停帧玩家区域仍有 513 个绿色主导像素（被暂停遮罩压暗）；隐藏帧恢复为 0。
  - 多分辨率复验（AGENTS.md §5.4，真实窗口渲染，脚本同上）：`health_bar_res_1152x648.png`（16:9，窗口 1152x648，逻辑视口 1152x648）、`health_bar_res_1152x720.png`（16:10，窗口 1152x720，逻辑视口 1152x720）、`health_bar_res_800x720.png`（窄屏，窗口 800x720 → 逻辑视口 1152x1036）三档全部满足 `BAR_RECT=(834,356,72,16)`、`BAR_CENTER.x = PAWN.x = 870`、`ABOVE_HEAD=true`、`INSIDE_VIEWPORT=true`；窗口 DPI 缩放 1.00、`RESIZE_OK=true`。
  - 多分辨率渲染核验（按图宽等比缩放后统计血条区域绿色像素）：1152 宽两张均为 504 px，bbox `(834,362)-(889,370)`；800 宽为 222 px，bbox `(580,252)-(616,257)`，面积与位移随缩放等比变化，确认血条在三档分辨率下都真实渲染在 Pawn 头顶。
  - 证据报告文件：`.mcp/godot-runtime/screenshots/health_bar_evidence_report.txt`（Windows GUI 子系统进程的 stdout 无法回传到 PowerShell，脚本改为 `print()` 与写文件双写，可重复执行）。
  - 复跑（验收前最终一轮）：headless 断言 `CHECKS=38 FAILURES=0`（退出码 0）、主场景冒烟 `--quit-after 600` 退出码 0、运行态 `HIDE_ELAPSED_MS=1964` / `PAUSED_BAR_VISIBLE=true` / `RESUME_HIDE_ELAPSED_MS=2035`。
  - 方法学说明：`--headless` 的 dummy 窗口固定为 64x64（逻辑视口退化为 1152x1152），无法模拟分辨率；多分辨率验证只能在真实窗口渲染下执行，且 GUI 子系统进程必须用 `Start-Process -Wait` 才能取得退出码。
- 验证状态：验证通过
- 验证时间：2026-09-25T14:09:39+08:00
- 已知问题：渐隐动画未实现（非范围）；`auto_hide_delay <= 0` 的常驻模式未编写用例；MCP 不可用期间的截图由自建脚本产出，不是 MCP 截图；“① HealthComponent”未在本 Increment 实现，已登记 `INC-PAWNS-003`。
- 用户验收：已验收
- 验收时间：2026-09-25T14:09:39+08:00
- Git：分支 main，commit `e233120`（feat(ui): show pawn health bar on health change and auto-hide [INC-CROSS-002]）
- 备注：父 Increment 为 `INC-CROSS-002`；本 Increment 取代 `INC-UI-001` 中“每个 Pawn 常驻显示生命条”的表现约定，数值刷新与选中 HUD 行为保持不变。
