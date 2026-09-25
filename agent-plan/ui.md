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

- 状态：in_progress
- 创建时间：2026-09-25T13:54:22+08:00
- 最后修改：2026-09-25T13:54:22+08:00
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
- 范围：`game/ui/pawn_health_bar.gd`、`game/ui/pawn_health_bar.tscn`（新增）、`game/pawns/pawn.tscn` 中的 `HealthBarAnchor/HealthBar` 结构、`test/headless/health_bar_visibility_test.gd`（新增，自建 headless 验证）。
- 非范围：渐隐/闪烁动画（需求文档列为第二阶段）、治疗与护盾技能、HUD 信息面板改造、正式血条美术、HealthComponent 抽取（见 `INC-PAWNS-003`）。
- 依赖：`INC-UI-001`（常驻血条现状）、`INC-PAWNS-001`、`INC-PAWNS-002`（生命状态变化统一入口）。
- 风险：可见性由常驻改为事件驱动，若未来有代码绕过统一入口直接修改 `current_health`，血条不会出现；通过 `Pawn.notify_health_state_changed()` 单一入口降低风险，并写入已知问题。
- 实现说明：待实现完成后填写。
- 变更文件：待填写。
- 测试证据：待填写。
- 验证状态：未验证
- 验证时间：
- 已知问题：“同一帧显示”依赖伤害帧内的同步信号链，需要运行态证据确认；需求文档的“① HealthComponent”未在本 Increment 实现，已登记 `INC-PAWNS-003`。
- 用户验收：未验收
- 验收时间：
- Git：
- 备注：父 Increment 为 `INC-CROSS-002`；本 Increment 取代 `INC-UI-001` 中“每个 Pawn 常驻显示生命条”的表现约定，数值刷新与选中 HUD 行为保持不变。