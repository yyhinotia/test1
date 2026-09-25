# Combat 主题计划

> 最后修改：2026-09-25T16:50:57+08:00
> 主题：combat  
> 规则来源：`../AGENTS.md`

## INC-COMBAT-001：实现基础普通攻击闭环

- 状态：accepted
- 创建时间：2026-09-25T13:21:58+08:00
- 最后修改：2026-09-25T13:43:51+08:00
- 主题：combat
- 目标：验证 `Target -> Move To Range -> Attack -> Damage -> Death` 的最小战斗闭环。
- 验收标准：
  - 右键敌方 Pawn 后，玩家 Pawn 自动接近到攻击距离并停止。
  - Pawn 按攻击间隔持续发动普通攻击，不出现每帧伤害。
  - 伤害名称使用 `max(1, attack - defense)`，先扣护盾再扣生命。
  - 受击后生命/护盾数据与 UI 同步更新。
  - 生命归零后进入 `DEAD` 状态，停止移动并停止攻击。
  - 敌方 AI Pawn 会主动接近并攻击玩家 Pawn。
- 范围：`game/combat/**`、`game/pawns/pawn.gd`、`game/pawns/data/*.tres` 中的战斗属性。
- 非范围：技能、功法、五行、伤害类型、暴击、范围伤害、仇恨表、状态异常和复杂目标选择。
- 依赖：`INC-PAWNS-001`；基础 Pawn 移动和生命接口。
- 风险：攻速、伤害和攻击距离如果未数据化，后续平衡会返工；本 Increment 将攻击间隔和数据放入 `PawnData`。
- 实现说明：
  - `Pawn.try_attack()` 通过攻击冷却生成普通攻击；`Pawn.take_damage()` 负责防御减免、护盾吸收和生命扣除。
  - 敌人 AI 延迟 3 秒启动，随后主动接近玩家并进入普通攻击循环。
  - `PlayerController` 保存移动/攻击指令，自动接近目标；`AIController` 使用同一 Pawn 攻击接口。
- 变更文件：
  - `game/pawns/pawn.gd`
  - `game/pawns/data/player_pawn.tres`
  - `game/pawns/data/enemy_pawn.tres`
  - `game/pawns/controllers/player_controller.gd`
  - `game/pawns/controllers/ai_controller.gd`
- 测试证据：
  - 右击敌人后 HUD 指令变为 `指令：攻击 试炼傀儡`，玩家随后与敌人互相攻击。
  - 运行态读取：敌人 `current_health` 从 80 降到 0、`current_shield` 从 20 降到 0，最终 `state = DEAD`（枚举值 3）。
  - 运行态读取：玩家在敌人普通攻击下 `current_shield` 从 40 降到 0，`current_health` 从 120 降到 104，证明敌人伤害通过同一 `take_damage()` 流程。
  - 敌人死亡后玩家生命在后续等待中保持不变，未出现死亡目标继续攻击。
  - `get_debug_output()` 最终 `errors` 为空。
  - 复验（攻击指令）：右键敌人后 HUD 指令由 待命 变为 指令：攻击 试炼傀儡，玩家在 64.9 像素距离内立即进入攻击循环。
  - 复验（伤害闭环）：敌人护盾 20 到 0、生命 80 到 50 到 0，最终 state = 3（DEAD）；同期玩家在敌人普攻下生命 120 到 90 到 62 到 55 到 48，双方共用同一 take_damage() 流程。
  - 复验（死亡后行为）：敌人死亡后玩家生命保持 48 不变，敌人不再发起攻击，攻击指令自动清回 待命。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:43:51+08:00
- 已知问题：暂无攻击动画、命中特效、伤害数字、攻击前摇和复杂命中判定。
- 用户验收：已验收
- 验收时间：2026-09-25T13:43:51+08:00
- Git：分支 main，commit d7c2e1e（feat(pawns): add pawn MVP with movement, combat, HUD and pause [INC-CROSS-001]）
- 备注：此 Increment 是 `INC-CROSS-001` 的子 Increment。

## INC-COMBAT-002：增加灵力资源池与原子消耗能力

- 状态：accepted
- 创建时间：2026-09-25T14:31:51+08:00
- 最后修改：2026-09-25T15:06:34+08:00
- 主题：combat
- 目标：新增灵力（技能蓝条）作为第二个实际资源消费者，验证 ResourcePoolComponent 与 ResourceBar 能覆盖“不能透支、可恢复、非死亡资源”的场景，但暂不实现技能链。
- 验收标准：
  - PawnData 能静态配置灵力上限与初始值；默认 `max_spirit = 0` 的 Pawn 不显示灵力条，配置为正数的 Pawn 创建 `Spirit` 资源池。
  - Pawn 暴露只读 `current_spirit` / `max_spirit` 与 `spirit_changed(current, max)`；资源变化驱动 PawnStatusBars 的 SpiritBar 显示和延迟追赶。
  - 提供 `try_spend_spirit(amount)` 原子接口：余额不足返回 false 且数值完全不变；余额足够时一次性扣除并返回 true。
  - 提供 `restore_spirit(amount)` 或等价接口，按上限截断；自动再生是否启用由资源定义或战斗规则决定，基础池不得强制再生。
  - 灵力归零只触发资源池的 depleted 语义，不得直接令 Pawn 死亡；技能、消耗、回复技能和施法校验均不在本 Increment 实现。
  - 新增 headless 断言覆盖满灵力消耗、连续消耗、余额不足、超量恢复、默认无灵力和 UI 绑定；现有战斗与血条回归继续通过。
- 范围：`game/pawns/data/*.tres`、`game/shared/resources/pawn_data.gd`、`game/pawns/pawn.gd`、`game/pawns/pawn.tscn`、`game/combat/**` 中资源消耗接口、必要的 `game/ui/pawn_status_bars.gd` 绑定与 `test/headless/spirit_pool_test.gd`。
- 非范围：主动技能、技能栏、冷却、施法前摇、功法、五行、灵根、分层生命、敌人技能、战斗平衡和自动回复策略。
- 依赖：`INC-CORE-002`、`INC-UI-003`、`INC-PAWNS-004`。
- 检索证据：执行 `git status --short`、`git diff --unified=0 -- agent-plan/`、`git diff --cached --unified=0 -- agent-plan/` 与 `git log --oneline -- agent-plan/`；工作区无暂存变更。父级 `INC-CROSS-003` 为 in_progress，顺序为 `INC-CORE-002 → INC-UI-003 → INC-PAWNS-004 → INC-COMBAT-002`，前三者已完成并通过 102/86/49 项断言（等待用户验收，未提交）。已验收基线仍为 `INC-PAWNS-003`（`a873c3f`）；允许范围严格限定为 PawnData 静态配置、Pawn 灵力池与消耗接口、`game/pawns/data/*.tres`、必要的 PawnStatusBars 绑定验证与 `test/headless/spirit_pool_test.gd`。
- 风险：把灵力回复和技能消耗规则写死进基础池；UI 在 `max_spirit = 0` 时错误显示空条；灵力归零与死亡语义混淆；PawnData 新增字段造成旧 `.tres` 默认值兼容问题。
- 实现说明：
  - 灵力是资源池的生产级第二消费者，用于证明抽象不是只为生命写死的伪通用组件。
  - `try_spend_spirit()` 只做原子扣除；技能系统未来负责“检查冷却、目标、施法条件”，不得把完整技能逻辑塞进资源组件。
  - 灵力条仅在最大灵力大于 0 时参与布局；其显示仍受 PawnStatusBars 组级隐藏计时控制。
  - `PawnData` 新增 `max_spirit`（默认 0）与 `initial_spirit_ratio`（默认 1.0，0..1）：默认 0 的单位完全不创建灵力池，因此也不会出现空灵力条；旧 `.tres` 不写字段时行为与迁移前一致。
  - 灵力池由 `Pawn._setup_spirit_pool()` 在 `_ready()` 中按需动态创建为 `Resources/Spirit`（ResourcePoolComponent），并以稳定 ID `spirit` 注册进 ResourceSetComponent；没有另建 Pawn 自持数值，`current_spirit` / `max_spirit` 都是资源池的只读代理。
  - `spirit_changed(pawn, current, max)` 由灵力池的 `value_changed` 驱动；灵力归零只保留资源池的 `depleted` 边沿，**不连接** `depleted → die()`，也不冒充 `health_state_changed`，因此不会弹出头顶血条或让单位死亡。
  - `restore_spirit()` 只做按上限截断的恢复，返回实际恢复量；基础池与 Pawn 都不实现自动再生 tick，恢复时机留给后续战斗规则。
  - 本 Increment 不改动 `pawn.tscn`、也不把头顶血条换成 `PawnStatusBars`：`INC-UI-003` 的通用资源条通过 headless 绑定验证（生命/护盾/灵力三条独立刷新与延迟追赶），实际接入头顶 UI 属于后续 Increment。
- 变更文件：
  - `game/shared/resources/pawn_data.gd`
  - `game/pawns/pawn.gd`
  - `game/pawns/data/player_pawn.tres`
  - `test/headless/spirit_pool_test.gd`
  - `test/headless/spirit_pool_test.gd.uid`
  - `test/headless/pawn_resource_pools_test.gd`（3 条“当前只应有 health/shield”的临时断言随灵力池落地更新，见测试证据）
- 测试证据：
  - Godot MCP `validate`：`pawn_data.gd`、`pawn.gd`、`spirit_pool_test.gd` 全部 `valid: true`，无解析或类型错误。
  - 新增 headless 断言：`spirit_pool_test.gd` 退出码 0，`CHECKS=63 FAILURES=0`、`SPIRIT_POOL_TEST_OK`；覆盖默认无灵力、正上限建池、一次性扣满、余额不足不变量、非法消耗、超量恢复、归零不致死与 UI 绑定/延迟追赶。
  - 全量回归：`spirit_pool_test` 63/0、`pawn_resource_pools_test` 49/0、`health_component_test` 55/0、`health_bar_visibility_test` 38/0、`resource_pool_component_test` 102/0、`resource_bar_test` 86/0，合计 393 项断言全部通过，退出码均为 0。
  - `pawn_resource_pools_test.gd` 的 3 条断言因本 Increment 增加了灵力池而更新（“只应有 health/shield” → “灵力池只在 `max_spirit > 0` 时存在”），复跑 49/0 通过，其余断言未改动。
  - 运行态冒烟（MCP `run_project` + `run_script`，真实窗口）：玩家 `get_resource_ids() = ["health","shield","spirit"]`、灵力 `100/100`（来自 `PawnData.max_spirit`）；敌人仍只有 `["health","shield"]`，`try_spend_spirit` 返回 false、`restore_spirit` 返回 0。
  - 运行态灵力语义：`try_spend_spirit(40)` → true 且灵力 60、只发出一次 `spirit_changed(60,100)`、`health_changed`/`shield_changed` 未触发、血量护盾不变、Pawn 存活、头顶血条保持隐藏；`try_spend_spirit(999)` → false 且灵力仍为 60、无新信号；`restore_spirit(9999)` → 返回 40 且补满到 100。
  - 运行态通用资源条绑定：把 `PawnStatusBars` 实例挂到主场景并绑定生命/护盾/灵力三池后，三条矩形为 `(480,120)/(480,138)/(480,156)`，互不重叠；灵力条 `visible = true`、目标值随灵力池立即变为 65、显示值按 `delayed_drain` 追赶后对齐 65，且未回写灵力池数值（截图为 `.mcp/godot-runtime/screenshots/screenshot_1790319971_481.png`，已忽略不入库）。
  - 运行态战斗回归：真实 AI 攻击后玩家护盾池由 40 降到 33、生命池不变，说明生命/护盾链路未受灵力改动影响。
  - `git diff --check` 退出码 0；运行日志 `errors` 为空。
  - 命令行 stderr 中的 `Failed to open log file for writing: user://logs/godot.log` 为本地用户日志目录写入限制，不影响断言与退出码。
- 验证状态：验证通过
- 验证时间：2026-09-25T15:06:34+08:00
- 已知问题：
  - 灵力条尚未接入 Pawn 头顶 UI（Pawn 仍使用已验收的 `PawnHealthBar`）；`PawnStatusBars` 的灵力显示目前由 headless 断言与运行态手动绑定验证，接入棋盘/头顶 UI 需另立 Increment。
  - 灵力自然恢复速率、战斗内恢复规则与技能消耗公式尚未设计；本 Increment 只提供池与原子接口。
  - `HUD/SelectedLabel` 仍未显示灵力（`game/main/main.gd` 不在本 Increment 范围）。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `f6cdebf`
- 备注：父 Increment 为 `INC-CROSS-003`；本 Increment 完成后仍不宣称技能系统可用。

## INC-COMBAT-003：实现首个主动技能执行闭环

- 状态：accepted
- 创建时间：2026-09-25T15:25:30+08:00
- 最后修改：2026-09-25T15:37:12+08:00
- 主题：combat
- 目标：在已验证的普通攻击与灵力池之上，增加数据驱动的主动技能执行契约：技能定义、施法前置校验、灵力原子扣除、伤害结算、冷却推进与 AI 自动施放。完成后灵力资源第一次拥有真实战斗消费者，但本 Increment 不接入玩家键位和技能栏 UI。
- 验收标准：
  - 新增 `ActiveSkillDefinition extends Resource`，至少描述稳定技能 ID、显示名、灵力消耗、冷却时间、施法距离和伤害倍率；资源只保存静态配置，不保存当前冷却。
  - `PawnData` 可配置一个可选主动技能；未配置技能的单位保持普通攻击行为完全不变。
  - Pawn 提供 `cast_skill(skill, target)` / `can_cast_skill(skill, target)` / `is_skill_ready(skill)` / `get_skill_cooldown_remaining(skill_id)`，并由 `_physics_process()` 推进冷却。
  - 施法前必须一次性检查：施法者存活、目标有效且为敌方活体、目标在施法距离内、技能已冷却、灵力足够；任一检查失败时不得扣灵力、不得造成伤害、不得进入冷却。
  - 施法成功时先原子扣除灵力，再调用目标 `take_damage()`，最后进入冷却并发出 `skill_cast` / 冷却变化信号；同一个技能在冷却归零前不能重复施放。
  - AI 控制器在目标进入技能距离且技能可用时优先施放技能，随后继续普通攻击；无技能或无灵力配置的单位行为不变。
  - 新增 GdUnit4 单元/集成用例覆盖资源默认值与距离回退、成功路径、灵力不足无副作用、冷却阻断与归零、无效目标和 AI 自动施放。
- 范围：`game/shared/resources/active_skill_definition.gd`、`game/pawns/data/*.tres`、`game/shared/resources/pawn_data.gd`、`game/pawns/pawn.gd`、`game/pawns/controllers/ai_controller.gd`、`test/unit/active_skill_definition_test.gd`、`test/integration/active_skill_execution_test.gd`；以及仅用于计划回写与测试基线同步的 `agent-plan/combat.md`、`agent-plan/_index.md`、`AGENTS.md`。
- 非范围：玩家键位、技能栏、目标选择 UI、功法/Build、范围伤害、五行、暴击、状态异常、灵力自然恢复、技能动画与正式特效。
- 依赖：`INC-COMBAT-002`（灵力池、`spirit_changed`、`try_spend_spirit`）；该依赖已实现并通过验证，并已随本批次验收通过。
- 检索证据：
  - 执行 `git status --short --branch`：当前分支为 `main`，相对 `origin/main` ahead 1；工作区同时存在 `INC-CROSS-003`、`INC-CROSS-004`、`INC-PAWNS-006`、`INC-TESTING-001` 等未提交变更。
  - 执行 `git diff --unified=0 -- agent-plan/`：识别到 `INC-CORE-002`、`INC-UI-003`、`INC-PAWNS-004`、`INC-COMBAT-002`、`INC-PAWNS-005`、`INC-UI-004`、`INC-PAWNS-006`、`INC-TESTING-001` 的计划变更；暂存区为空。
  - 执行 `git log --oneline -- agent-plan/`：最新计划提交为 `3bd28fb`，历史中不存在 `INC-COMBAT-003`。
  - 执行 `git grep -n -E "INC-COMBAT-003|active_skill|cast_skill|skill_cooldown"`：仅匹配到 AGENTS.md 的编号示例，业务代码与计划中没有已有主动技能实现。
  - 结构核对：`Pawn.try_spend_spirit()` 已存在并保持原子语义；`AIController` 目前只做靠近与普通攻击，没有技能消费者。启动时测试基线为 GdUnit4 三层 34 个用例、9 个 headless 套件 480 项断言，统一 runner 实测通过；完成后 GdUnit4 用例增至 44 个（unit 25 / integration 14 / gameplay 5，见测试证据）。
- 风险：
  - 技能伤害仍经过目标 `take_damage()` 的防御减免；测试必须断言伤害“通过既有伤害路由”，不能假设倍率等于最终扣血。
  - 冷却推进必须使用 `_physics_process(delta)`，不能使用 `_process` 绕过暂停；暂停时冷却应冻结。
  - 需要保证失败路径完全无副作用，特别是灵力、目标生命和冷却三者不能被部分修改。
  - 只修改 combat 主题范围；玩家输入、HUD 技能文本和技能栏必须留给后续 Increment，避免把本 Increment 扩成跨主题特性。
- 实现说明：
  - `ActiveSkillDefinition extends Resource` 只保存稳定技能 ID、显示名、灵力消耗、冷却、施法距离与伤害倍率等静态配置；提供 `is_configured()`、距离回退与负数归一化读取，当前冷却不写入资源，避免多个 Pawn 共享资源时污染状态。
  - `PawnData` 新增可选 `active_skill`。`player_pawn.tres` 引用 `player_sword_skill.tres`（`御剑斩`：25 灵力、2.5 秒冷却、110 施法距离、1.8 倍攻击）；未配置技能的单位仍只走普通攻击路径。
  - `Pawn.can_cast_skill()` 在一次入口中校验：技能有效、施法者存活、目标有效且为敌方活体、目标在施法距离内、技能未冷却、灵力足够。失败路径只返回 `false`，不扣灵力、不造成伤害、不进入冷却。
  - `Pawn.cast_skill()` 成功顺序固定为：原子扣除灵力 → 调用目标 `take_damage()` → 写入按 `skill.id` 索引的冷却 → 发出 `skill_cast` 与 `skill_cooldown_changed`。冷却由 `_physics_process()` 推进；Pawn 死亡后不推进，暂停时因物理帧冻结而自然冻结。
  - `AIController` 在激活延迟后、进入技能距离且技能可用时优先施放一次技能，否则继续既有的接近与普通攻击流程。
  - 复杂度控制：没有引入全局技能管理器、事件总线或对象池；单个 Pawn 的冷却字典足以支撑当前每单位单技能切片，后续多技能装配再另行抽象。
- 变更文件：
  - 新增 `game/shared/resources/active_skill_definition.gd` 与 `.uid`。
  - 修改 `game/shared/resources/pawn_data.gd`。
  - 修改 `game/pawns/pawn.gd`：新增技能信号、施法校验/执行、冷却查询与物理推进。
  - 修改 `game/pawns/controllers/ai_controller.gd`：新增技能优先施放分支。
  - 新增 `game/pawns/data/player_sword_skill.tres`。
  - 修改 `game/pawns/data/player_pawn.tres`：增加 `active_skill` 资源引用。
  - 新增 `test/unit/active_skill_definition_test.gd` 与 `.uid`。
  - 新增 `test/integration/active_skill_execution_test.gd` 与 `.uid`。
  - 修改 `agent-plan/combat.md`、`agent-plan/_index.md`、`AGENTS.md`（计划回写与测试基线同步）。
- 测试证据：
  - MCP Godot `validate` 批量校验（2026-09-25T15:36:24+08:00 左右）：`active_skill_definition.gd`、`pawn_data.gd`、`pawn.gd`、`ai_controller.gd`、两个新增测试脚本均返回 `valid: true`，`errors: []`。
  - 统一测试门禁（2026-09-25T15:35 左右，`pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all`）：GdUnit4 `unit 25 例 / integration 14 例 / gameplay 5 例`，汇总 `44 cases, 0 failures`；headless `9 suites, 480 assertions, 0 failing suites`；输出 `RESULT: PASS`，退出码 `0`。
  - 编辑器工程校验（`--headless --path <repo> --editor --quit`）：退出码 `0`，Godot 4.7.2 成功注册 `ActiveSkillDefinition` 并完成资源扫描；仅有 headless 环境无法写 `user://` editor settings/log 的环境警告，无项目脚本错误。
  - 运行态冒烟（`--headless --path <repo> --quit-after 120`）：退出码 `0`；仅有 `user://logs/godot.log` 无法创建的环境级错误，无项目脚本错误。
  - 技能专项集成用例覆盖：成功施法扣灵力并造成防御减免后的伤害、进入冷却、重复施法阻断；灵力不足完全无副作用；超距/同阵营/自身/空目标/已死亡目标全部拒绝；物理推进后冷却归零并可再次施放；AI 激活延迟后自动施放。
- 验证状态：验证通过
- 验证时间：2026-09-25T15:37:12+08:00
- 已知问题：
  - 玩家侧尚无键位、技能栏或施法目标选择入口；本切片只提供 Pawn API，AI 可自动使用，玩家 Pawn 的 `active_skill` 配置当前不会被 `PlayerController` 主动触发。
  - 正式 `main.tscn` 的试炼傀儡继续保持既有 `max_spirit = 0`、不绑定灵力条的契约，因此当前没有自带主动技能；AI 自动施放由集成用例注入临时 `PawnData` 验证。要让实战单位施放技能，需后续 Increment 明确正式单位的灵力配置并更新对应回归基线。
  - 无技能动画、施法前摇、命中特效、伤害数字和音效；伤害只有单一瞬时结算。
  - 灵力自然恢复、技能升级、功法/Build、范围伤害、五行、暴击、状态异常和多个技能装配均不在本 Increment 范围。
  - 冷却状态位于 Pawn 实例内，不参与存档；单位死亡后冷却冻结，当前没有复活/重置契约。
  - AI 只有在目标进入技能距离后才施放；不会为了技能主动脱离或调整站位。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `193c1c5`
- 备注：本 Increment 是主动技能系统的第一个可验证切片，只证明“技能可以安全消耗灵力、造成一次伤害并进入冷却”；玩家操作、技能栏和技能编辑/装配不在此范围。

## INC-COMBAT-004：SkillSlot 战斗状态读模型

- 状态：accepted
- 创建时间：2026-09-25T17:01:58+08:00
- 最后修改：2026-09-25T17:17:48+08:00
- 主题：combat
- 目标：把技能格的可用状态、冷却比例与资源不足原因收敛为只读状态模型，供 UI 显示，不把冷却/资源计算复制到 SkillSlot。
- 验收标准：
  - 对空技能、无效 Pawn、死亡 Pawn、冷却中、灵力不足和可用技能分别返回稳定状态：`EMPTY` / `DISABLED` / `COOLDOWN` / `NO_RESOURCE` / `READY`；同时保留 `SELECTED` / `TARGETING` 状态常量供交互层扩展。
  - 冷却状态返回 `cooldown_remaining`、`cooldown_total`、`cooldown_ratio = remaining / total`，并满足 `1.0` 为刚进入冷却、`0.0` 为冷却完成。
  - 灵力不足时即使冷却完成也返回 `NO_RESOURCE`，并返回当前灵力、消耗与可读原因；模型不得修改 Pawn、资源池或冷却状态。
  - 纯逻辑用例覆盖边界（无技能、冷却中点、冷却完成、刚好够灵力、灵力不足、死亡单位）。
- 范围：新增 `game/combat/skill/skill_slot_state.gd`、对应 unit 测试。
- 非范围：SkillSlot 场景/视觉、技能目标选择、冷却推进、资源扣除、技能释放。
- 依赖：`INC-COMBAT-003`、`INC-PAWNS-013`（技能列表）；均需满足后开始。
- 检索证据：已执行 `git status --short --branch`（`main...origin/main`，仅 `docs/战斗技能ui.md` 未跟踪）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（暂存区为空）、`git log --oneline -- agent-plan/`（最新计划提交 `ae16ef9`）与 `git grep -n -E "INC-[A-Z]+-[0-9]{3}" -- agent-plan/`（UI 最高 `INC-UI-009`、战斗最高 `INC-COMBAT-003`、Pawns 最高 `INC-PAWNS-012`、Core 最高 `INC-CORE-004`、Testing 最高 `INC-TESTING-002`）。Graphify 图谱缺失且本机缺少 `networkx`，本轮以 Godot MCP 场景树 + 定向源码读取补足结构基线；主场景当前 `HUD/PawnInfoPanel` 为右下锚定，尚无 SkillBar / SkillSlot。
- 风险：状态判定顺序必须固定（DISABLED / COOLDOWN / NO_RESOURCE / READY），否则 UI 与测试容易对同一状态给出不同解释。
- 实现说明：模型只读取 `Pawn.get_skill_cooldown_remaining()`、`Pawn.current_spirit` 与 `ActiveSkillDefinition` 的规范化字段；状态名称使用 StringName，UI 不解析中文文案。
- 变更文件：`game/combat/skill/skill_slot_state.gd`（+.uid）、`test/unit/skill_slot_state_test.gd`（+.uid）。
- 测试证据：统一门禁通过：unit 80 / integration 54 / gameplay 26，共 160 cases、0 failures；`skill_slot_state_test.gd` 6 例覆盖 EMPTY / DISABLED / COOLDOWN / NO_RESOURCE / READY 与冷却比例边界。headless 10 suites、549 assertions、0 failing；Godot MCP validate 通过。
- 验证状态：验证通过
- 验证时间：2026-09-25T17:17:48+08:00
- 已知问题：`SELECTED` / `TARGETING` 本轮只提供状态常量与高亮接口，不是目标选择系统。
- 用户验收：已验收
- 验收时间：2026-09-25T17:17:48+08:00
- Git：`main` / `70a09f1`
- 备注：父 Increment 为 `INC-CROSS-011`。


## INC-COMBAT-005：技能目标类型与控制器目标解析

- 状态：accepted
- 创建时间：2026-09-25T17:31:30+08:00
- 最后修改：2026-09-25T17:34:51+08:00
- 主题：combat
- 来源：`docs/build-mvp.md` MVP-2。
- 目标：让 `SELF` / `ALLY` / `ENEMY` 成为技能执行的真实规则，而不是只存在于编辑器字段；玩家控制器、AI 控制器与 Pawn 施法校验必须对同一目标类型给出一致结论。
- 验收标准：
  - `Pawn.can_cast_skill(skill, target)` 按 `skill.target_type` 校验：SELF 只能指向施法者自身，ALLY 只能指向同阵营存活单位且不等于施法者，ENEMY 只能指向不同阵营存活单位；失败路径不得扣灵力、造成效果或进入冷却。
  - `PlayerController.order_skill_instance(skill, target = null)` 对 SELF 自动解析为施法者，对 ALLY/ENEMY 使用显式目标或当前攻击目标；目标类型不合法时返回 `false` 且不覆盖既有命令。
  - 控制器接近距离或直接施法的判定统一使用同一解析目标；SELF 技能无需移动即可施法。
  - AI 至少支持 SELF 自动施法，并继续支持对当前敌人目标施放 ENEMY 技能；ALLY 无合法目标时安全回退，不误伤敌人。
  - 单元/集成测试覆盖三种目标类型、同阵营排除自身、死亡目标、错误类型无副作用与 SELF 立即施法。
- 范围：`game/pawns/pawn.gd`、`game/pawns/controllers/player_controller.gd`、`game/pawns/controllers/ai_controller.gd`、对应 unit/integration 测试。
- 非范围：鼠标目标选择 UI、范围/AOE、地面目标、友军列表编成、目标高亮。
- 依赖：`INC-PAWNS-014`。
- 检索证据：待 PAWNS-014 计划落库后按 Git Diff 复核；当前控制器硬编码 `_is_valid_enemy_target()`，Pawn 也硬编码“目标必须是敌人”。
- 风险：旧 Q/技能栏调用依赖“默认敌方目标”；解析逻辑必须保留旧默认行为，且不能在失败时破坏普通攻击目标。
- 实现说明：目标类型判断只保留一个来源，控制器负责解析，Pawn 负责最终裁决；两个入口不得复制不同规则。
- 变更文件：`game/pawns/pawn.gd`、`game/pawns/controllers/player_controller.gd`、`game/pawns/controllers/ai_controller.gd`、`test/integration/skill_target_type_test.gd`（新增）。
- 测试证据：统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 通过：GdUnit4 unit 87 / integration 58 / gameplay 26，共 171 cases、0 failures；headless 10 suites、549 assertions、0 failing suites。定向用例 `test/integration/skill_target_type_test.gd` 4 例：Pawn 按 SELF / ALLY / ENEMY 裁决、SELF 由控制器解析为施法者、ALLY 需要显式目标、AI 对 SELF 技能自动施法且不覆盖敌人目标。Godot MCP `validate` 对 `pawn.gd`、`player_controller.gd`、`ai_controller.gd`、`skill_target_type_test.gd` 通过；`git diff --check` 通过。
- 验证状态：验证通过
- 验证时间：2026-09-25T17:34:51+08:00
- 已知问题：ALLY 暂无友军目标提供方：玩家入口需要显式传入友军目标，AI 在缺少友军目标时安全跳过；友军列表与编成属于后续非范围。
- 用户验收：已验收
- 验收时间：2026-09-25T17:34:51+08:00
- Git：`main` / `df36f24`
- 备注：父 Increment 为 `INC-CROSS-012`；本 Increment 不实现 Effect System。验收依据：用户 2026-09-25T17:31+08:00 回复“验收通过，分increment提交”。

## INC-COMBAT-006：最小 Skill Effect System（Damage / Heal / Shield / Stun）

- 状态：accepted
- 创建时间：2026-09-25T17:31:30+08:00
- 最后修改：2026-09-25T17:57:16+08:00
- 主题：combat
- 来源：`docs/build-mvp.md` MVP-3。
- 目标：把主动技能的成功结算从 `Pawn.cast_skill()` 内的单一伤害代码抽出为最小 Effect Resolver，支持 Damage、Heal、Shield、Stun 四种效果，并让 Stun 成为可观察、可推进、可恢复的战斗状态。
- 验收标准：
  - 新增最小 Effect Resolver，统一执行“技能校验 → 灵力原子扣除 → 按 `effect_type` 应用效果 → 记录冷却 → 发出信号”的顺序；失败路径不得出现部分结算。
  - DAMAGE 继续通过既有 `Pawn.take_damage()` 防御/护盾路由；HEAL 通过生命资源池增加生命；SHIELD 通过护盾资源池增加护盾并按上限截断；STUN 给目标增加有限持续时间并立即停止移动。
  - 被眩晕单位在持续期间不能移动、普通攻击或施放技能；眩晕只影响行动，不应直接扣血或致死；物理帧推进后恢复，并发出可测试的状态信号。
  - `Pawn.cast_skill()` 不再包含四类效果的业务分支，只调用 Resolver；旧伤害技能与旧测试保持通过。
  - 单元/集成测试覆盖四种效果、满血治疗/满盾截断、灵力不足无副作用、眩晕期间行为阻断与到期恢复。
- 范围：新增 `game/combat/skill/` 下的最小 Effect Resolver 与状态接口；修改 `game/pawns/pawn.gd`、必要的技能执行测试。
- 非范围：Buff/Debuff 编辑器、堆叠、免疫、抗性、沉默、持续伤害、复杂 Trigger/Condition/Modifier、动画与 VFX。
- 依赖：`INC-COMBAT-005`。
- 检索证据：待 COMBAT-005 计划落库后按 Git Diff 复核；当前 `Pawn.cast_skill()` 直接执行伤害，Pawn 没有 Stun 字段或行为阻断接口。
- 风险：Stun 推进必须使用 `_physics_process(delta)` 以在暂停时冻结；冷却与状态计时不能混用同一个字典；治疗/护盾不能把资源池变成第二个真相。
- 实现说明：第一版只支持单效果技能，不提前实现 Effect 数组；Resolver 通过 Pawn 的受控业务接口修改资源，不直接写资源池内部字段。
- 变更文件：`game/combat/skill/skill_effect_resolver.gd`（新增）、`game/pawns/pawn.gd`、`test/integration/skill_effect_test.gd`（新增）。
- 测试证据：统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 通过：GdUnit4 unit 87 / integration 63 / gameplay 26，共 176 cases、0 failures；headless 10 suites、549 assertions、0 failing suites。定向用例 `test/integration/skill_effect_test.gd` 5 例：DAMAGE 由 `effect_value` 决定伤害并继续走“先护盾、后生命”路由；HEAL 按上限截断（30 / 30 / 15 / 满血 0）；SHIELD 按护盾上限截断且无护盾上限时为空操作；STUN 封锁移动 / 普攻 / 施法、不造成伤害、物理帧到期恢复并发出 `stun_changed`，重复施加取较长剩余时间；灵力不足时四类效果均无任何部分结算。Godot MCP `validate` 对 `skill_effect_resolver.gd` 与 `pawn.gd` 通过；`Pawn.cast_skill()` 已确认只保留一行转发到 Resolver。
- 验证状态：验证通过
- 验证时间：2026-09-25T17:39:59+08:00
- 已知问题：`Pawn` 与 `SkillEffectResolver` 互相引用，GDScript 4 在函数签名上标注双方 `class_name` 会触发脚本循环依赖编译失败，因此 Resolver 的 `caster` / `target` 参数不加 `Pawn` 静态类型（已在文件内注明，调用契约由 `Pawn.cast_skill()` 单点保证）；第一版仅支持单效果技能，无 Buff 容器、叠加、免疫与持续伤害。
- 用户验收：已验收
- 验收时间：2026-09-25T17:39:59+08:00
- Git：`main` / `0438397`、`60355ae`（新增脚本 UID）
- 备注：父 Increment 为 `INC-CROSS-012`；本 Increment 只实现最小效果系统。验收依据：用户 2026-09-25T17:31+08:00 回复“验收通过，分increment提交”。

## INC-COMBAT-007：Build 容量约束贯穿施法裁决

- 状态：accepted
- 创建时间：2026-09-25T18:00:42+08:00
- 最后修改：2026-09-25T18:10:00+08:00
- 主题：combat
- 目标：让超容量主动技能在所有施法入口都被同一条 `Pawn` 容量事实拒绝，即使调用方绕过 SkillBar 也不能扣除灵力、推进冷却、移动或造成效果。
- 验收标准：
  - `Pawn.can_cast_skill()` 在目标、距离、冷却与灵力检查前先拒绝未启用技能；`SkillEffectResolver` 的既有失败无副作用语义保持不变。
  - `PlayerController.order_skill_instance()` 拒绝超容量技能且不覆盖既有移动/攻击/技能命令。
  - `AIController` 只遍历 `Pawn.get_enabled_active_skills()`，不会尝试超容量技能；无境界单位的天生技能仍可施放。
  - 集成测试证明超容量技能直接调用 `cast_skill()` 返回 false，且灵力、冷却、位置、生命/护盾、命令状态均不变化。
- 范围：`game/pawns/pawn.gd`、`game/pawns/controllers/player_controller.gd`、`game/pawns/controllers/ai_controller.gd` 与对应集成测试。
- 非范围：技能伤害/效果重平衡、目标规则变更、AI 决策升级、技能栏视觉。
- 依赖：`INC-PAWNS-015`。
- 检索证据：已执行 `git status --short`（工作区干净，`main...origin/main`）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）与 `git log --oneline -5 -- agent-plan/`（当前计划基线 `cbccdb8`）；全量检索确认现有最高主题编号为 PAWNS-014 / COMBAT-006 / UI-012 / CORE-006 / TESTING-004，CROSS-012 已验收，无未完成 planned Increment。 `git grep` 实测：`BuildValidator` 已能报告 `over_capacity`，但 `Pawn.can_cast_skill()` 不检查容量，`PlayerController.order_skill_instance()` 只检查 known skill，`AIController` 直接遍历 `data.get_active_skills()`，`SkillBar.refresh()` 用 `max(capacity, skills.size())` 显示全部技能却未把多余技能置为 DISABLED。因此“校验能发现错误”与“运行时实际禁止错误 Build”之间仍有缺口。
- 风险：必须保持既有正常 Build（炼气 2/2）行为不变；不得让无境界的怪物/傀儡因缺少 Build 容量而失去天生技能；不得只修 UI 而留下控制器或 AI 旁路；不得静默截断技能列表。
- 实现说明：所有控制器只消费 Pawn 的容量投影；`can_cast_skill()` 作为最终权威，控制器拒绝作为无副作用的前置过滤。
- 变更文件：`game/pawns/pawn.gd`（`can_cast_skill()` 最终容量门禁，随 PAWNS-015 基线提交）、`game/pawns/controllers/player_controller.gd`、`game/pawns/controllers/ai_controller.gd`、`test/integration/active_skill_execution_test.gd`。
- 测试证据：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer integration` 返回 PASS：73 cases / 0 failures；新增用例证明超容量技能经 `can_cast_skill()` 与 `cast_skill()` 均 no-op，灵力/冷却/生命/护盾/位置/命令不变，PlayerController 拒绝时不覆盖既有命令，AI 只遍历启用技能。`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 返回 PASS：GdUnit4 207 cases / 0 failures（unit 94、integration 73、gameplay 40），headless 10 suites / 549 assertions / 0 failing suites。Godot MCP `validate` 对 13 个本次变更脚本/测试目标返回 `valid: true`、`errors: []`；`git diff --check` 无输出。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:10:00+08:00
- 已知问题：无新增阻塞。控制器只消费 Pawn 容量投影，不复制规则。
- 用户验收：已验收
- 验收时间：2026-09-25T18:10:00+08:00
- Git：`main` / `1fb0b2f`
- 备注：父 Increment 为 `INC-CROSS-013`；本 Increment 不改变技能效果规则。


## INC-COMBAT-008：技能价值标定与遭遇威胁轴对齐

- 状态：accepted
- 创建时间：2026-09-25T18:20:31+08:00
- 最后修改：2026-09-25T18:28:15+08:00
- 主题：combat
- 来源：`docs/build-mvp.md` MVP-5 与用户 2026-09-25 建议优先级 5；该文件明确要求「如果三个技能不能产生不同决策，MVP-1 不算完成」。
- 目标：按「同一次灵力投入在不同遭遇下的实际效果」标定三类技能（御剑斩 = 输出 / 护体真气 = 生存 / 定身术 = 控制）的价值，使每一类在适配的威胁轴上具备可测量的优势，并把标定表与推导过程记录到本文件；若标定显示某类技能在两条威胁轴上都劣于同类，则调整该技能资源数值，而不是削弱验证断言。
- 验收标准：
  - 产出标定表：三类技能 × 两类威胁档案的「灵力效率」与「最优档位」——输出按每点灵力的伤害贡献，生存按护盾实际吸收量，控制按敌人失效时间（秒）与由此规避的伤害。
  - 标定后不存在单一统治解：至少一个档案的最优两槽组合包含输出技能，另一个档案的最优组合包含控制或生存技能；若某类技能在全部档案下都被支配，必须调整数值后重新标定。
  - 允许调整的数值字段仅限 `player_sword_skill.tres` / `player_guard_skill.tres` / `player_binding_skill.tres` 的 `spirit_cost`、`cooldown`、`effect_value`、`effect_duration`。
  - 不允许改动 `active_skill_definition.gd` 的语义、不允许新增效果类型。
  - 任何数值调整必须同步更新受影响的既有测试期望（例如 `build_tactical_trajectory_test.gd` 的灵力与伤害排序断言），并保持统一门禁全绿；禁止让断言随实现漂移。
- 范围：`game/pawns/data/player_*_skill.tres`（仅在标定需要时）、`agent-plan/combat.md` 的标定记录、受影响测试的期望同步。
- 非范围：新增技能、新增效果类型、持续伤害 / Buff / Debuff 容器、AOE、属性抗性、暴击、装备词条、复杂 `Effect[]`。
- 依赖：`INC-PAWNS-016`（威胁档案）、`INC-PAWNS-014`（技能数据契约）、`INC-COMBAT-006`（Effect System，均已验收）。
- 检索证据：已执行 `git status --short --branch`（`main...origin/main`，工作区干净）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）与 `git log --oneline -6 -- agent-plan/`（`c442822`）；`git grep` 确认最高编号 COMBAT-007 已验收，且 `INC-TESTING-004` 的既有结论明确写道「本用例是固定场景的确定性过程证据，不是正式平衡结论；数值仍可能随后续战斗调参改变」——这正是本 Increment 的直接前置缺口。当前技能数值（御剑斩 25 灵力 / 2.5s 冷却 / 1.8 倍率；护体真气 30 灵力 / 8s 冷却 / 30 护盾；定身术 35 灵力 / 10s 冷却 / 2.0s 眩晕）与唯一敌人档案（12 攻击 / 1.1s 间隔）之间从未做过价值标定。
- 风险：改动既有技能数值会影响 `INC-TESTING-004` 的固定轨迹证据与 `INC-CROSS-012` 的结论摘要，必须同步更新并在本 Increment 记录差异；标定必须以真实结算结果为准，不得用手算公式替代运行证据。
- 实现说明：先按「标称灵力效率」推导三类技能在不同威胁轴上的边际收益，再用 `INC-TESTING-006` 的终局实测校准。标定结果显示三类技能在当前数值下已具备互补价值，因此**未改动任何技能数值**，差异由 `INC-PAWNS-016` 的遭遇档案提供；调参过程中只调整了新建档案的敌人数值（铁壁傀儡攻击 8 → 16、血刃刺客攻击 45 → 60），两处调整都在 `INC-PAWNS-016` 的变更范围内。

#### 威胁档案 × 技能价值标定表（标称换算，用于解释调参方向）

换算口径（按数据字段推导，用于解释「哪类技能适配哪类遭遇」，不作为实测结论）：

| 技能 | 灵力 | 效果 | 对铁壁傀儡（攻 16/1.6s、防 6） | 对试炼傀儡（攻 12/1.1s、防 3） | 对血刃刺客（攻 60/1.5s、防 2） |
|---|---|---|---|---|---|
| 御剑斩（输出） | 25 | 1.8 × 攻击 28 = 50.4 原始伤害 | 44.4 伤害 = 1.78 / 灵力 | 47.4 伤害 = 1.90 / 灵力 | 48.4 伤害 = 1.94 / 灵力 |
| 护体真气（生存） | 30 | 30 点护盾 | 需 2.73 次命中才打穿 = 1.00 / 灵力 | 需 4.29 次命中才打穿 = 1.00 / 灵力 | 一次命中即打穿 = 1.00 / 灵力 |
| 定身术（控制） | 35 | 敌人失效 2.0s | 阻止约 13.75 伤害 = 0.39 / 灵力 | 阻止约 12.73 伤害 = 0.36 / 灵力 | 阻止约 73.33 伤害 = 2.10 / 灵力 |

标定结论：

- **输出**的价值随敌方有效生命上升而上升：敌方越耐打，50.4 点前置伤害节省的击杀时间越长。
- **生存**的收益是**固定点数**（30 点护盾），与敌方单次伤害无关；在低频低伤的长线遭遇里性价比最高（要 2.73 次命中才打穿）。
- **控制**的收益与敌方单次伤害成**线性放大**：同样 2.0 秒失效，在血刃刺客身上能阻止约 73 点伤害，是铁壁傀儡（13.75）的 5.3 倍。
- 因此「长线遭遇 → 生存优先、爆发遭遇 → 控制优先」不是测试造出来的差异，而是灵力投入边际收益随威胁轴变化的直接结果。**本次未改动任何技能数值**（御剑斩 25/2.5s/1.8、护体真气 30/8s/30、定身术 35/10s/2.0 保持不变），差异完全由 `INC-PAWNS-016` 的遭遇档案提供；实测证据见 `INC-TESTING-006`。

#### 实测最优档位（来自 `INC-TESTING-006`）

| 档案 | 最优 Build（存活余命优先） | 最差 Build | 无技能对照 | 决策代价（余命比差） |
|---|---|---|---|---|
| 试炼傀儡（基线） | 输出+控制（0.913） | 生存+控制（0.825） | 胜（0.781） | 8.75 个百分点 |
| 铁壁傀儡（长线） | **生存+控制（0.363）** | 输出+控制（0.244） | 胜（0.038） | 11.88 个百分点 |
| 血刃刺客（爆发） | **输出+控制（0.656）** | 生存+控制（0.500） | **败（0.000）** | 15.63 个百分点 |

- 变更文件：`agent-plan/combat.md`（本标定表与结论）。技能资源文件与 Effect System 代码均未改动。
- 测试证据：标定依赖的实测证据由 `INC-TESTING-006` 提供（`test/gameplay/build_decision_differentiation_test.gd`，12 个组合 + 3 个无技能对照全部跑到终局）。统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 返回 GdUnit4 210 cases / 0 failures 与 headless 10 suites / 549 assertions / 0 failing；`git diff --check` 无输出。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:28:15+08:00
- 已知问题：本 Increment 只处理单体技能的三类价值轴，不覆盖 AOE、治疗与友方目标的平衡。标定表内的灵力效率是**标称换算**（按数据字段推导），只用于解释调参方向，实测结论以 `INC-TESTING-006` 的终局表为准。
- 用户验收：已验收
- 验收时间：2026-09-25T18:28:15+08:00
- Git：`-`（提交后由计划回写提交补记 hash）
- 备注：父 Increment 为 `INC-CROSS-014`；本 Increment 承接 `INC-TESTING-004`「不是正式平衡结论」的已知问题。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」（承接「验收通过，分increment提交」），按 AGENTS.md §4.1 记录为明确验收。
