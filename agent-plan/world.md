# World 主题计划（地图 / 秘境 / 遭遇 / 事件 / 探索）

> 最后修改：2026-09-25T18:52:41+08:00
> 主题：world
> 规则来源：`../AGENTS.md`
> 设计源：`../docs/project_summary.md` §十（秘境系统）、§十八 MVP ④（一个秘境 + 房间 + Boss）

秘境的完整循环（进入 → 探索 → 选路 → 事件 → 战斗 → 收获 → 深入/撤退 → Boss）在 MVP 阶段不一次做完。
本主题按「一次一刀」推进：先把**战斗遭遇**从写死的单场对局，变成玩家可以选择的秘境遭遇，形成
`选择遭遇 → 战斗 → 结果 → 再选择` 的最小闭环，再叠加房间推进、随机事件与奖励。

## INC-WORLD-001：遭遇定义（EncounterDefinition）与秘境遭遇目录

- 状态：accepted
- 创建时间：2026-09-25T18:33:02+08:00
- 最后修改：2026-09-25T18:52:41+08:00
- 主题：world
- 来源：`docs/project_summary.md` §十 秘境系统与 §十八 MVP ④；`INC-PAWNS-016` 的已知问题「档案数据尚无游戏内入口（遭遇选择 UI / 秘境流程属于非范围，需另立 Increment）」。
- 目标：新增 `EncounterDefinition` 数据资源与 `game/world/data/encounters/` 目录，把「敌人威胁档案」包装成玩家可理解的遭遇（名称、说明、敌人档案、威胁标签），让上层（会话、UI、测试）只依赖遭遇定义而不直接认识敌人 .tres 路径。
- 验收标准：
  - 新增 `game/shared/resources/encounter_definition.gd`（`class_name EncounterDefinition extends Resource`），字段：`id: StringName`、`display_name: String`、`description: String`、`enemy_profile: PawnData`、`threat_tag: StringName`（长线 / 爆发 / 基线三类之一），并提供 `is_configured()` 与 `get_enemy_display_name()`。
  - `is_configured()` 至少要求 `id` 非空、`display_name` 非空、`enemy_profile` 非空且 `enemy_profile.id` 非空；任一缺失返回 false。
  - `game/world/data/encounters/` 至少三份遭遇资源，分别引用既有 `enemy_pawn.tres`（试炼傀儡基线）、`enemies/enemy_iron_guard.tres`（长线）、`enemies/enemy_blood_blade.tres`（爆发），不复制敌人数值、不新增敌人。
  - 三份遭遇的 `id` 全局唯一，且 `enemy_profile` 的 `id` 互不相同。
  - 新增单元用例覆盖：未配置实例为 false；三份资源字段完整且 id 唯一；遭遇引用的敌人档案就是 `INC-PAWNS-016` 的三份正式档案（按 resource_path 断言，不硬编码数值）。
- 范围：`game/shared/resources/encounter_definition.gd`（新增）、`game/world/data/encounters/*.tres`（新增 3 个）、`test/unit/encounter_definition_test.gd`（新增）。
- 非范围：房间/推进/随机事件/掉落/Boss/地图场景、遭遇难度曲线、奖励结算、存档、UI。
- 依赖：`INC-PAWNS-016`（已验收，三份敌人档案）、`INC-PAWNS-014`（已验收，PawnData 契约）。
- 检索证据：执行 `git status --short --branch`（`main...origin/main`，0/0，工作区干净）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）、`git log --oneline -5 -- agent-plan/`（顶部 `5123b8c`）与 `git grep -n -E "INC-[A-Z]+-[0-9]{3}" -- agent-plan/`；确认已无 planned/in_progress 的既有 Increment，最高编号为 CROSS-014 / PAWNS-016 / COMBAT-008 / UI-013 / CORE-007 / TESTING-006 / CULT-004 / INVENTORY-001，均已验收。`agent-plan/world.md` 此前不存在，本 Increment 首次建立世界主题；`game/world/` 目录不存在，`docs/project_summary.md` §十八 ④「一个秘境 + 5～10 个房间 + 1 个 Boss」是下一个未落地的 MVP 项，而 `INC-PAWNS-016` 的敌人档案当前只能在自动化测试里被引用，玩家在实机中无法进入。
- 风险：遭遇定义若直接依赖 .tres 路径字符串，会让数据层耦合实现细节；因此只暴露 `PawnData` 引用。另一风险是把房间/奖励等未来字段提前塞进本资源导致结构膨胀；MVP 阶段只保留「玩家选什么」和「打谁」两个信息。
- 实现说明：`EncounterDefinition` 只暴露「玩家看得懂的选择信息」加一个 `PawnData` 引用：`id`、`display_name`、`description`、`enemy_profile`、`threat_tag`（`THREAT_BASELINE = 0` / `THREAT_LONG_FIGHT = 1` / `THREAT_BURST = 2`）；既不持有敌人数值，也不在代码里写 `.tres` 路径字符串，使上层只依赖遭遇定义。`is_configured()` 在 `id`、`display_name`、`enemy_profile`、`enemy_profile.id` 任一缺失时返回 false，让 UI 与会话可以安全降级。三份遭遇资源全部通过 `ExtResource` 引用 `INC-PAWNS-016` 已验收的正式敌人档案（`game/pawns/data/enemy_pawn.tres`、`game/pawns/data/enemies/enemy_iron_guard.tres`、`game/pawns/data/enemies/enemy_blood_blade.tres`），数值零复制；`threat_tag` 与敌人档案的威胁轴一一对应（基线 / 长线 / 爆发）。
- 变更文件：`game/shared/resources/encounter_definition.gd`（新增）、`game/shared/resources/encounter_definition.gd.uid`（新增）、`game/world/data/encounters/encounter_trial_puppet.tres`（新增）、`game/world/data/encounters/encounter_iron_guard.tres`（新增）、`game/world/data/encounters/encounter_blood_blade.tres`（新增）、`test/unit/encounter_definition_test.gd`（新增）、`test/unit/encounter_definition_test.gd.uid`（新增）、`game/world/` 目录与 `agent-plan/world.md` 主题文件（新建）。
- 测试证据：
  - 新增单元用例 `test/unit/encounter_definition_test.gd`：6 个用例，覆盖「未配置实例 `is_configured()` 为 false」「三份资源字段完整且 `is_configured()` 为 true」「三份遭遇 `id` 全局唯一」「三份遭遇引用的敌人档案 `resource_path` 恰为 `INC-PAWNS-016` 的三份正式档案」。用例按 `resource_path` 断言，不硬编码敌人数值。
  - `--headless --import` 通过；三份 `.tres` 与新增脚本被引擎正常导入，生成的 `.gd.uid` 随源码提交。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`：GdUnit4 241 cases（unit 102 / integration 93 / gameplay 46）、0 failures；headless 10 suites / 549 assertions / 0 failing suites；退出码 0。
  - `git diff --check` 无输出。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:52:41+08:00
- 已知问题：`threat_tag` 目前只是静态标签，尚未参与难度排序、奖励计算或推荐逻辑（非范围）；遭遇资源只描述「打谁」，不含推荐境界、掉落或房间信息。
- 用户验收：已验收
- 验收时间：2026-09-25T18:52:41+08:00
- Git：`main` / `f7d1cc4`（+ `INC-CROSS-015` 计划回写提交）
- 备注：父 Increment 为 `INC-CROSS-015`；本 Increment 是「遭遇可被玩家选择」的数据前提。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」，按 `AGENTS.md` §4.1 与本仓库 `INC-CROSS-011`~ `INC-CROSS-014` 的既有约定记录为明确验收。

## INC-WORLD-002：遭遇会话（EncounterSession 起局 / 换敌 / 结算）

- 状态：accepted
- 创建时间：2026-09-25T18:33:02+08:00
- 最后修改：2026-09-25T18:52:41+08:00
- 主题：world
- 目标：新增 `EncounterSession` 运行时节点，把「按遭遇定义组织一场对局」的全部职责（清场、按档案实例化敌人、重置玩家、绑定控制器、判定胜负、广播结果）从主场景脚本中抽离出来，使 `main.gd` 只做转发，避免继续膨胀。
- 验收标准：
  - 新增 `game/world/encounter_session.gd`（`class_name EncounterSession extends Node`），对外 API 最少为：`begin(encounter: EncounterDefinition) -> bool`、`restart() -> bool`、`get_state() -> int`（`IDLE / RUNNING / PLAYER_WIN / ENEMY_WIN`）、`get_active_encounter() -> EncounterDefinition`、`get_player_pawn() -> Pawn`、`get_enemy_pawn() -> Pawn`。
  - 信号：`encounter_started(encounter: EncounterDefinition, player: Pawn, enemy: Pawn)`、`encounter_finished(encounter: EncounterDefinition, outcome: int)`。
  - 起局语义：清理上一次的单位与旧引用 → 用 `PAWNS_CONTAINER` 下新实例化的玩家/敌人 Pawn 承载定义里的 `PawnData`（玩家数据来自导出的 player 数据源，敌人数据取遭遇定义）→ 绑定 `PlayerController` / `AIController` 并互设目标 → 状态置 `RUNNING`。
  - 结算语义：任一方 `died` 立即结算一次并只广播一次（重复死亡信号不重复广播）；结算后 `get_state()` 不再是 `RUNNING`；结算不得自动重开对局。
  - 重复 `begin()` 必须幂等安全：先清场再起局，旧的对局不会残留监听或残留单位。
  - 会话不读输入、不碰 UI、不写 HUD 文本；单位位置由导出的出生点/间距决定。
- 范围：`game/world/encounter_session.gd`（新增）、`game/world/encounter_session.tscn`（如需挂载点）、`test/integration/encounter_session_test.gd`（新增）。
- 非范围：房间推进、Boss、奖励、存档、多人/4v4 编队、AI 行为改动、UI 文本、玩家 Build 编辑器。
- 依赖：`INC-WORLD-001`、`INC-PAWNS-016`、`INC-CROSS-012`（控制器与施法闭环，已验收）。
- 检索证据：见 `INC-WORLD-001` 的同一轮检索（工作区干净、无 pending Increment）；另用 Godot MCP 读取 `game/main/main.tscn` 场景树与 `game/main/main.gd`（292 行）确认当前主场景直接持有 `Pawns/PlayerPawn`、`Pawns/EnemyPawn` 两个写死单位，且 `_ready()` 里完成 `bind()` 与 `set_target()`；`test/gameplay/build_decision_differentiation_test.gd` 已证明「实例化 Pawn → 赋 data → add_child → 绑定控制器」是可行且确定性的起局方式，本 Increment 把同一方式产品化。
- 风险：单位在运行时被替换会把主场景里缓存的旧 Pawn 引用变成悬空引用（选中态、技能栏、信息卡、目标高亮都持有 Pawn）。因此会话必须通过信号让上层在 `encounter_started` 时重新取引用，并在替换前清理旧引用；本 Increment 只负责会话与信号，引用刷新由 `INC-CORE-008` 负责。另一个风险是重复结算与信号重复连接，必须有显式清理与一次性结算。
- 实现说明：`EncounterSession`（`Node`）把「组织一场对局」的职责从主场景抽离，对外只暴露 `begin(encounter)` / `restart()` / `start_initial_encounter()` / `get_state()` / `is_running()` / `get_active_encounter()` / `get_player_pawn()` / `get_enemy_pawn()` / `static get_outcome_label(outcome)` 与 `encounter_started` / `encounter_finished` 两个信号；不读输入、不碰 UI、不写 HUD 文本。起局顺序：`_retire_units()` 清场 → 在 `Pawns` 容器下实例化新单位并承载数据 → 绑定 `PlayerController` / `AIController` 并互设目标 → 置 `RUNNING`。两处关键设计：其一，单位 `data` 必须在 `add_child()` 之前赋值，因为 `Pawn._ready()` 会据此建立资源池；其二，退场单位先从容器 `remove_child()`、再寄存到会话节点下 `queue_free()`——先移除是必须的，否则新建的同名单位会被引擎改名、`Pawns/PlayerPawn` 等既有路径会指向正在销毁的旧单位；寄存而非直接脱离则避免产生孤儿节点，并保证同一帧内仍持有旧引用的 HUD / 技能栏不会拿到已释放对象。玩家数据源优先级为「上一场玩家 `data` → 容器内既有 `PlayerPawn.data` → 导出 `player_data` → 正式玩家档案」，因此测试在入树前覆盖数据不会丢失。结算走 `_on_unit_died()`：先判状态必须为 `RUNNING`，再结算并广播一次，重复死亡信号不会二次广播，也不会自动重开对局。
- 变更文件：`game/world/encounter_session.gd`（新增）、`game/world/encounter_session.gd.uid`（新增）、`test/integration/encounter_session_test.gd`（新增）、`test/integration/encounter_session_test.gd.uid`（新增）。
- 测试证据：
  - 新增集成用例 `test/integration/encounter_session_test.gd`：12 个用例，覆盖按遭遇定义起局并生成双方单位与控制器绑定、`encounter_started` 载荷正确、`begin()` 换敌后旧单位退场、玩家数据跨越换遭遇保持、`encounter_finished` 每局只广播一次、玩家死亡判为敌方胜利、真实控制器下超时对局可结算、重复 `begin()` 不留残留单位、`restart()` 必须有活动遭遇、`restart()` 重建同一遭遇、未配置 / 空遭遇被拒绝、`get_outcome_label()` 覆盖全部状态。
  - 首轮统一门禁曾出现 1 次失败：`test_begin_swaps_enemy_and_retires_previous_unit` 断言退场敌人 `get_parent()` 为 `null`。该断言与「退场单位寄存在会话下以避免孤儿节点」的实现相冲突，属断言本身过时；已改为断言「不再位于 `Pawns` 容器内 + `is_queued_for_deletion()` 为真 + 父节点为会话」，随后复跑通过。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`：GdUnit4 241 cases（unit 102 / integration 93 / gameplay 46）、0 failures；headless 10 suites / 549 assertions / 0 failing suites；退出码 0，无孤儿节点报告。
  - `git diff --check` 无输出。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:52:41+08:00
- 已知问题：编制固定为「1 玩家 vs 1 敌人」，多单位编队与 4v4 仍在非范围；换遭遇会重建玩家单位，因此每局资源池与冷却重置为档案初始值，不继承上一局战斗状态；会话不负责奖励或掉落。
- 用户验收：已验收
- 验收时间：2026-09-25T18:52:41+08:00
- Git：`main` / `5646769`（+ `INC-CROSS-015` 计划回写提交）
- 备注：父 Increment 为 `INC-CROSS-015`；本 Increment 是父级「选择遭遇 → 战斗 → 结果」闭环的运行时核心。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」，按 `AGENTS.md` §4.1 与本仓库 `INC-CROSS-011`~ `INC-CROSS-014` 的既有约定记录为明确验收。
