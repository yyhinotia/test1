# World 主题计划（地图 / 秘境 / 遭遇 / 事件 / 探索）

> 最后修改：2026-09-26T01:56:11+08:00
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

## INC-WORLD-003：秘境房间链定义（DungeonRoom / DungeonDefinition）

- 状态：accepted
- 创建时间：2026-09-25T18:53:44+08:00
- 最后修改：2026-09-25T19:07:54+08:00
- 主题：world
- 来源：`docs/project_summary.md` §十 秘境系统基本循环、§十八 MVP ④「一个秘境 + 5～10 个房间 + 1 个 Boss」。
- 目标：把「一个秘境 = 若干房间 + 1 个 Boss」表达成数据资源，让运行时与 UI 只依赖定义，不硬编码房间数、奖励与 Boss 位置。
- 验收标准：
  - 新增 `game/shared/resources/dungeon_room.gd`（`class_name DungeonRoom extends Resource`）：`display_name: String`、`encounter: EncounterDefinition`、`reward_spirit_stones: int`、`is_boss: bool`；`is_configured()` 要求 `display_name` 非空、`encounter` 已配置（`encounter.is_configured()`）、`reward_spirit_stones >= 0`。
  - 新增 `game/shared/resources/dungeon_definition.gd`（`class_name DungeonDefinition extends Resource`）：`id: StringName`、`display_name: String`、`description: String`、`rooms: Array[DungeonRoom]`；提供 `is_configured()`（id / 名称非空、房间数 ≥ 1、每个房间都已配置）、`get_room_count()`、`get_room(index)`（越界返回 null）、`has_boss()`、`get_boss_index()`（无 Boss 返回 -1）、`get_room_reward(index)`、`get_max_reward()`（全部房间奖励之和，用于显示「最多能拿多少」）。
  - 新增 `game/world/data/encounters/encounter_dungeon_boss.tres`：引用 `INC-PAWNS-017` 的 Boss 档案，`threat_tag` 取 `ENDURANCE`（持续压制），不复制任何数值。
  - 新增 `game/world/data/dungeons/trial_dungeon.tres`：一个秘境、6 个房间（5 个普通房间 + 1 个 Boss 房间），最后一间 `is_boss = true`；房间奖励随深度递增且 Boss 房间最高；威胁逐层升级（试炼傀儡 → 试炼傀儡 → 铁壁傀儡 → 血刃刺客 → 铁壁傀儡 → 镇狱魔君），全部引用既有正式敌人档案。
  - 单元用例覆盖：未配置实例与空房间列表为 false；越界 `get_room()` / `get_room_reward()` 安全返回；试炼秘境恰好 6 间、恰好 1 间 Boss 且位于最后一间；奖励单调不减且末间最高；房间引用的敌人档案全部来自 `game/pawns/data/` 正式目录。
- 范围：`game/shared/resources/dungeon_room.gd`（新增）、`game/shared/resources/dungeon_definition.gd`（新增）、`game/world/data/encounters/encounter_dungeon_boss.tres`（新增）、`game/world/data/dungeons/trial_dungeon.tres`（新增）、`test/unit/dungeon_definition_test.gd`（新增）。
- 非范围：随机生成 / 分支路线 / 房间事件 / 掉落表 / 存档 / 难度自适应 / 多秘境目录 / 房间 UI。
- 依赖：`INC-WORLD-001`（已验收，EncounterDefinition）、`INC-PAWNS-017`（Boss 档案）。
- 检索证据：同一轮检索（工作区干净、无 pending Increment）；`game/world/data/` 下现有 `encounters/` 三份遭遇，尚无秘境（dungeon）层定义；`EncounterDefinition` 已确立「只引用 PawnData、不复制数值」的写法，本 Increment 沿用同一模式把多个遭遇串成有序房间链。
- 风险：如果把「房间数、奖励、Boss 在第几间」写进脚本常量，后续调难度就必须改代码；因此房间链的全部内容都放在资源里，脚本只读不判。另一风险是奖励过早做成掉落表（物品 / 权重 / 稀有度），MVP 阶段只保留一种可累加货币（灵石）与一个整数奖励。
- 实现说明：新增 `DungeonRoom` / `DungeonDefinition` 两个只读资源类，并用一个正式秘境数据把它们串起来：`trial_dungeon.tres` 共 6 间房（5 普通 + 1 Boss），奖励 10 / 15 / 25 / 40 / 60 / 100 单调递增，敌人顺序为试炼傀儡 → 试炼傀儡 → 铁壁傀儡 → 血刃刺客 → 铁壁傀儡 → 镇狱魔君，全部引用 `game/pawns/data/` 的正式档案；`encounter_dungeon_boss.tres` 只引用 `enemy_dungeon_boss.tres` 并标记 `ENDURANCE`，不复制数值。越界读取返回 null / 0，未配置房间与空房间链一律 `is_configured() == false`。
- 变更文件：`game/shared/resources/dungeon_room.gd`（新增）、`game/shared/resources/dungeon_definition.gd`（新增）、`game/world/data/encounters/encounter_dungeon_boss.tres`（新增）、`game/world/data/dungeons/trial_dungeon.tres`（新增）、`test/unit/dungeon_definition_test.gd`（新增）。
- 测试证据：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer unit` → PASS（GdUnit4 unit 112 cases / 0 failures，退出码 0）。新增 6 个用例覆盖：未配置 / 空房间链拒绝；越界 `get_room()` / `get_room_reward()` 安全返回；试炼秘境恰好 6 间、恰好 1 间 Boss 且在最后一间；奖励单调不减且末间最高、`get_max_reward()` 等于逐间求和；威胁顺序与正式敌人档案 id 一致；所有房间的敌人档案都来自 `game/pawns/data/`。
- 验证状态：验证通过
- 验证时间：2026-09-25T19:01:28+08:00
- 已知问题：「恰好一个 Boss」由配置与测试约束，`DungeonDefinition` 只提供返回首个 Boss 的 `get_boss_index()`，不在运行时拦截多 Boss；随机生成与多秘境目录属于非范围。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「分批incre单独推送后继续开发」）
- 验收时间：2026-09-25T19:07:54+08:00
- Git：`main` / `5ee2549`
- 备注：父 Increment 为 `INC-CROSS-016`；本 Increment 是「秘境 = 5～10 个房间 + 1 个 Boss」的数据表达。

## INC-WORLD-004：秘境运行时（DungeonRun：房间推进 / 资源延续 / 继续或撤退）

- 状态：accepted
- 创建时间：2026-09-25T18:53:44+08:00
- 最后修改：2026-09-25T19:07:54+08:00
- 主题：world
- 目标：新增 `DungeonRun` 运行时节点，把「一场秘境」的收益与风险显式化：清空一间房按定义结算灵石收益，玩家在「继续深入」与「见好就收」之间选择；继续则带着上一间剩下的生命 / 护盾 / 灵力进入下一间，战败则本局收益全部落空。这是「越深入，收益越高，风险越大」的代码落点。
- 验收标准：
  - 新增 `game/world/dungeon_run.gd`（`class_name DungeonRun extends Node`），对外 API 至少为：`start(dungeon: DungeonDefinition) -> bool`、`advance() -> bool`、`retreat() -> bool`、`get_state() -> int`、`get_active_dungeon()`、`get_room_index() -> int`、`get_depth() -> int`（1 起的当前层数）、`get_room_count() -> int`、`get_earned_spirit_stones() -> int`、`is_awaiting_decision() -> bool`、`static get_outcome_label(outcome: int) -> String`。
  - 状态机：`IDLE → RUNNING（当前房间对局中）→ AWAITING_DECISION（已清空非 Boss 房间，等待玩家决定）→ RUNNING → … → CLEARED（清空最后一间）/ DEFEATED（任一间战败）/ RETREATED（玩家主动撤退）`；非 `AWAITING_DECISION` 状态调用 `advance()` / `retreat()` 必须返回 false 且不改变任何状态。
  - 信号：`run_started(dungeon, room_index)`、`room_cleared(dungeon, room_index, reward, total)`、`run_finished(dungeon, outcome, earned_spirit_stones)`。
  - 收益语义：每清空一间房按该房间定义的 `reward_spirit_stones` 累加；`DEFEATED` 时 `get_earned_spirit_stones()` 归零（本局收益落空）；`RETREATED` 与 `CLEARED` 保留。
  - 资源延续语义：`advance()` 在换房间前从 `EncounterSession` 的当前玩家单位采集生命 / 护盾 / 灵力（按 `Pawn.get_resource_ids()` 遍历，不硬编码资源 id），下一间开局后写回采集值；玩家档案（Build / 数据）沿用既有 `_resolve_player_data()` 优先级链。第一间房必须满状态起局。
  - 新增 `game/shared/core/pawn_resource_snapshot.gd`：`static capture(pawn: Pawn) -> PawnResourceSnapshot` 与 `apply_to(pawn: Pawn) -> void`；空单位、无资源池必须安全返回，不抛错。
  - `game/world/encounter_session.gd` 扩展：新增 `capture_player_state() -> PawnResourceSnapshot` 与 `begin_with_state(encounter: EncounterDefinition, state: PawnResourceSnapshot) -> bool`；`begin()` 语义完全不变（等价于 `begin_with_state(encounter, null)`），`INC-WORLD-002` 既有 12 个用例必须继续通过。
  - 集成用例覆盖：合法秘境可开局且第一间满状态；清空非 Boss 房间进入 `AWAITING_DECISION` 且收益累加；`advance()` 后深度 +1 且带走上一间剩余的生命 / 灵力（断言小于满值）；Boss 房间清空后 `CLEARED` 且收益保留；战败进入 `DEFEATED` 且收益归零；`retreat()` 保留收益并结束；非法状态调用 `advance()` / `retreat()` 无效；重复结算不二次广播。
- 范围：`game/world/dungeon_run.gd`（新增）、`game/shared/core/pawn_resource_snapshot.gd`（新增）、`game/world/encounter_session.gd`（只新增两个方法，不改既有语义）、`test/integration/dungeon_run_test.gd`（新增）。
- 非范围：随机事件、分支路线、商店 / 存档、掉落物入库、疲劳或复活机制、多人、AI 行为改动、UI 文本。
- 依赖：`INC-WORLD-003`、`INC-WORLD-002`（已验收，会话起局 / 换敌 / 结算 / 控制器绑定）。
- 检索证据：同一轮检索（工作区干净、无 pending Increment）；`EncounterSession` 已提供 `begin()` / `restart()` / `get_state()` / `get_player_pawn()` 与两处信号，但 `begin()` 每次都按档案重建单位、资源池回到初始比例，因此「风险累积」必须在会话之上新增一层；`Pawn` 已暴露 `get_resource_ids()` 与 `get_resource_pool(id)`，`ResourcePoolComponent` 已提供 `set_value()`，可以在不新增数值系统的前提下完成状态延续。
- 风险：本 Increment 会改动已验收的 `EncounterSession`，属于「已接受接口的扩展」，必须只新增方法、不改既有方法语义，并让 WORLD-002 既有用例继续通过；若必须改既有行为，应另立 Increment 并记录破坏性变更。另一风险是资源写回的时序——必须在新单位入树后再写入资源值，否则会被 `_ready()` 里的池初始化覆盖。
- 实现说明：新增 `PawnResourceSnapshot`（按 `Pawn.get_resource_ids()` 采集 / 写回，不硬编码任何资源 id；空单位与缺失资源池安全降级）与 `DungeonRun`（状态机 IDLE → RUNNING → AWAITING_DECISION → … → CLEARED / DEFEATED / RETREATED；清空房间按定义累加灵石，`DEFEATED` 归零，`CLEARED` / `RETREATED` 保留；`advance()` 先采集当前玩家快照，下一间开局并完成资源池初始化后写回）。`EncounterSession` 只新增 `begin_with_state()` 与 `capture_player_state()`，`begin()` 等价改写为 `begin_with_state(encounter, null)`，既有语义不变。推进决策唯一在 `DungeonRun`：会话只判单间胜负，运行只判「还有没有下一间」，避免双重推进。
- 变更文件：`game/world/dungeon_run.gd`（新增）、`game/shared/core/pawn_resource_snapshot.gd`（新增）、`game/world/encounter_session.gd`（只新增两个方法并等价改写 `begin()`）、`test/integration/dungeon_run_test.gd`（新增）。
- 测试证据：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer integration` → PASS（GdUnit4 integration 102 cases / 0 failures，退出码 0），既有的 `INC-WORLD-002` 12 个会话用例继续通过。新增 9 个用例覆盖：未配置秘境拒绝开局且第一间满状态；清空非 Boss 房间进入 `AWAITING_DECISION` 并按定义累加；继续深入深度 +1、敌人换成下一间档案、玩家携带上一间剩余的生命 / 护盾 / 灵力（断言小于满值）；Boss 清空后 `CLEARED` 且收益保留；战败 `DEFEATED` 且收益归零；撤退 `RETREATED` 保留收益且不创建新对局；非法状态推进 / 撤退零副作用；重复结算不二次计数；资源快照对空单位 / 空目标安全降级。
- 验证状态：验证通过
- 验证时间：2026-09-25T19:01:28+08:00
- 已知问题：资源延续只覆盖玩家单位，敌人每间按档案满状态重建（设计如此）；技能冷却与眩晕不跨房间延续，属于非范围。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「分批incre单独推送后继续开发」）
- 验收时间：2026-09-25T19:07:54+08:00
- Git：`main` / `7b8f1b1`
- 备注：父 Increment 为 `INC-CROSS-016`；本 Increment 是「贪不贪」决策的运行时主体，收益只在 `CLEARED` / `RETREATED` 时保留。

## INC-WORLD-005：跨对局修士运行时进度延续（功法 / 强化 / 修为）

- 状态：accepted
- 创建时间：2026-09-25T19:58:19+08:00
- 最后修改：2026-09-25T20:04:33+08:00
- 主题：world
- 目标：让 EncounterSession 在同一场景生命周期内，把玩家单位的运行时 Build（领悟功法 / 武器强化）与修为进度，从旧单位延续到新单位，使秘境换房与重新开局后仍然带着宗门成长再战。
- 验收标准：
  - EncounterSession 在每次重建玩家单位前采集当前玩家运行时的强化等级、领悟功法与修为；新玩家入树后、广播 `encounter_started` 前写回。
  - `begin()` / `begin_with_state()` / `restart()` 的既有资源与胜负语义不变；资源是否延续仍由传入的 `PawnResourceSnapshot` 决定，新一局资源重置，但运行时进度继续。
  - 静态 `PawnData` / `TechniqueDefinition` / `WeaponDefinition` 不被修改；同类功法不重复、强化不越上限、修为按目标单位上限截断；空单位 / 无修炼组件安全降级。
  - 集成用例证明连续两次 `begin()` 后强化等级、领悟功法 id、修为当前值保持一致；`INC-TESTING-009` 的真实主场景闭环用例重新开局后攻击力确实高于未强化基线。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all` 全绿，headless 10 suites / 549 assertions 不下降。
- 范围：`game/world/encounter_session.gd`、`test/integration/encounter_session_test.gd`，以及只读消费本能力的 `test/gameplay/sect_loop_test.gd`。
- 非范围：存档落盘、跨进程 / 跨场景持久化、装备替换、境界突破、技能冷却延续、敌人运行时进度、宗门规则改动。
- 依赖：`INC-WORLD-004`（资源延续语义）、`INC-PAWNS-018`（运行时 Build API）、`INC-CORE-010`（宗门接线）；由 `INC-TESTING-009` 的真实闭环失败证据触发。
- 检索证据（2026-09-25T19:58:19+08:00）：`INC-TESTING-009` 的 `test/gameplay/sect_loop_test.gd` 在真实 `main.tscn` 上跑通收益 / 设施 / 修炼 / 炼丹 / 强化后，第一次重开断言修为 12.0 但新单位为 0.0，第二次重开断言强化等级 1 但新单位为 0，攻击力仍为 28.0；`game/world/encounter_session.gd` 只通过 `PawnResourceSnapshot` 延续生命 / 护盾 / 灵力，`begin_with_state()` 重建玩家时没有采集或写回 Pawn 的运行时覆盖层与 `CultivationProgressComponent`。因此本 Increment 是缺口修复的唯一写入者。
- 风险：EncounterSession 是已验收的高复用会话层，新增延续只扩展现有 `begin_with_state()` 的起局顺序，不改变资源快照与胜负判定；写回必须发生在新单位 `_ready()` 初始化之后，否则会被档案初始值覆盖。另一风险是重复恢复功法 / 强化触发多余信号，因此写回固定在 `encounter_started` 广播之前，并依赖 Pawn 现有去重与封顶规则。
- 实现说明：
  - `begin_with_state()` 在调用 `_retire_units()` 之前用 `_capture_player_progress()` 采集旧玩家进度；新单位入树、资源快照写回校验通过之后、`encounter_started` 广播之前用 `_apply_player_progress()` 写回。
  - 新增私有辅助 `_capture_player_progress()` / `_apply_player_progress(player, progress)`：只读公开 API，不持有 Pawn 引用、不新建资源；写回复用 `Pawn.strengthen_weapon()`（沿用 `MAX_FORGE_LEVEL` 封顶）、`Pawn.learn_technique()`（沿用 Pawn 去重）、`Pawn.set_cultivation_exp()`（沿用目标单位突破阈值截断）。
  - 资源快照语义保持不变：是否延续生命 / 护盾 / 灵力仍由调用方传入的 `PawnResourceSnapshot` 决定；`state == null` 的新一局仍按档案满状态起局，只有同代修士的运行时进度延续。
  - 空单位 / 空进度 / 缺组件一律安全降级，不报错也不代建资源；失败路径（快照为死亡状态、单位创建失败）不写回进度。
- 变更文件：
  - `game/world/encounter_session.gd`（进度采集 / 写回与两处调用点）
  - `test/integration/encounter_session_test.gd`（新增两个用例、`APPROX` 常量与 `_cultivation_exp()` 读取辅助）
- 测试证据：
  - `& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/integration/encounter_session_test.gd -rd res://reports/debug_world005 --ignoreHeadlessMode`：退出码 0，`Overall Summary: 14 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`；新增的 `test_runtime_build_and_cultivation_survive_repeated_begin` 与 `test_carried_cultivation_is_clamped_by_target_realm` 均 PASSED。
  - `& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/gameplay/sect_loop_test.gd -rd res://reports/debug_sect_loop --ignoreHeadlessMode`：退出码 0，`2 test cases | 0 errors | 0 failures | 0 orphans`；重开后修为 / 强化等级 / 攻击力三处失败断言全部转为通过。
  - `pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all`：退出码 0，`GdUnit4 : 324 cases, 0 failures`（unit 125 / integration 139 / gameplay 60）、`headless : 10 suites, 549 assertions, 0 failing suites`、`RESULT: PASS`。
- 验证状态：验证通过
- 验证时间：2026-09-25T20:04:33+08:00
- 已知问题：`INC-UI-016` 遗留的 `test/integration/sect_panel_test.gd` 在 GdUnit4 目录模式下报 288 orphans，使该层进程退出码为 101（该文件自身 0 failures / 0 errors）；`run_tests.ps1` 汇总仍为 `RESULT: PASS`。该孤儿由 `INC-UI-016` 引入，与本次改动无关，属既有测试整洁度债务。
- 用户验收：已验收
- 验收时间：2026-09-25T20:04:33+08:00
- 验收依据：用户指令「分批increment单独推送后继续开发」（2026-09-25），授权本批次按 Increment 分批提交并逐一推送。
- Git：`main` / `6f0be8c`
- 备注：父 Increment 为 `INC-CROSS-017`；这是「宗门产出 → 修士成长 → 再战」闭环的会话层延续补丁，不改变第一间房资源满状态起局的既有设计。

## INC-WORLD-006：跨遭遇延续运行时境界

- 状态：accepted
- 创建时间：2026-09-25T20:11:34+08:00
- 最后修改：2026-09-25T20:17:57+08:00
- 主题：世界
- 目标：把已经通过 `INC-PAWNS-019` 建立的运行时境界覆盖纳入 EncounterSession 的修士进度延续，保证秘境换房 / 重开 / 换遭遇后不会回退到静态炼气期。
- 验收标准：
  - `_capture_player_progress()` 在旧玩家退场前采集运行时 `RealmDefinition` 与当前境界修为。
  - `_apply_player_progress()` 先按可达链恢复境界，再写入该境界内的修为；恢复失败时保持新单位初始境界并安全降级。
  - 集成用例证明「补满 → 突破 → 重新 begin」后新 Pawn 的境界、容量、修为与突破前一致，且静态 `PawnData.realm` 未被改写。
  - 不改变 `PawnResourceSnapshot` 对生命 / 护盾 / 灵力的既有语义，不扩展敌人进度延续。
- 范围：`game/world/encounter_session.gd`、`test/integration/encounter_session_test.gd`。
- 非范围：存档落盘、跨进程持久化、`DungeonRun` 奖励规则、宗师 / 宗门规则、敌人境界推进。
- 依赖：`INC-PAWNS-019`、`INC-WORLD-005`（修为 / Build 延续，已验收）。
- 检索证据：同 `INC-CULT-005`；`game/world/encounter_session.gd` 的 `_capture_player_progress()` 当前只采集 `forge_level`、`techniques`、`cultivation_exp`，没有境界资源；`_apply_player_progress()` 当前只调用 `set_cultivation_exp()`，因此运行时境界无法跨 `begin_with_state()` 存活。
- 风险：恢复境界必须发生在新 Pawn `_ready()` 配置之后、`encounter_started.emit()` 之前；否则 UI 会先读取炼气容量再被刷新，或者静态初始化覆盖恢复值。恢复 API 必须拒绝可达链外的境界，防止会话层意外越级。
- 实现说明：`_capture_player_progress()` 在旧 Pawn 退场前采集 `RealmDefinition` 与当前境界内修为；`_apply_player_progress()` 先调用 `restore_realm()` 恢复运行时境界和修为，再写强化与功法。若进度缺少有效 `RealmDefinition`，回落到既有 `set_cultivation_exp(..., &"encounter_carry")` 语义，保持旧存档 / 测试夹具兼容。
- 变更文件：`game/world/encounter_session.gd`、`test/integration/encounter_session_test.gd`。
- 测试证据：2026-09-25T20:15:50+08:00 执行 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/integration/encounter_session_test.gd -rd res://reports/inc_world_006 --ignoreHeadlessMode`，GdUnit4 报告 `15 test cases | 0 errors | 0 failures | 0 orphans`，`Exit code: 0`；MCP `validate` 对会话脚本与测试返回 `valid: true`。新增用例断言突破后的筑基境界、境界内 37 点修为、主动技能容量 3 与静态炼气基线均跨 `begin_with_state()` 存活。
- 验证状态：验证通过
- 验证时间：2026-09-25T20:15:50+08:00
- 已知问题：只延续玩家单位的运行时境界；敌人仍按档案重建。跨进程存档、技能冷却与负面状态延续不在本 Increment。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「分批increment单独推送后继续开发」；验证通过后按该授权进入 Git）
- 验收时间：2026-09-25T20:16:30+08:00
- Git：`main` / `dba3f01`
- 备注：父 Increment 为 `INC-CROSS-018`；本 Increment 保证突破成果在同一代修士的多次遭遇之间不丢失。

## INC-WORLD-007：固定 1v1 / 1v2 / 1v3 Build 验证遭遇

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T20:47:54+08:00
- 最后修改：2026-09-25T22:21:30+08:00
- 主题：world
- 重定义说明：本 Increment 原定义「4v4 Vertical Slice 秘境、奖励与定点数据」于 2026-09-25T21:45:00+08:00 按用户 objective 重定义为「固定 1v1 / 1v2 / 1v3 Build 验证遭遇」；原定义原文保留在 Git 历史 `b36e9c0`（`develop`）。
- 调整说明（2026-09-25T22:20:30+08:00）：进入实现前的三处口径澄清——① 「重开不残留技能状态」只指**瞬时战斗状态**（冷却、控制中、施法进行中、护盾增益），
  已解锁技能与已装配 Build 属于本代修士的养成进度，按 `INC-WORLD-005` / `INC-WORLD-006` 的延续规则**必须保留**；若连它们一起清掉，Stage 3 的「换 Build 再战」在机制上不成立。
  ② 把两处必要接线纳入本 Increment 范围：`EncounterDefinition` 增加首通奖励字段并由 `EncounterSession` 在胜利结算时发放；`SquadProgressSnapshot` 增加「已解锁 / 已装配主动技能」的采集与写回（`INC-PAWNS-021` 的运行时覆盖层此前只在单位存活期间有效，换局即丢）。
  ③ 1v2 / 1v3 的近战 / 远程角色以**最小新增**敌人档案实现（远程 = 高 `attack_range` 的持续输出档案），不引入新系统。
  原调整说明（2026-09-25T22:12:40+08:00）：按 objective §25「资源结构」把定身术资源纳入本 Increment 的验收标准——`player_binding_skill.tres` 当前仍在 `game/pawns/data/` 根目录，而 `INC-COMBAT-009` 新增的 `enemy_boss_cleave.tres` 已落在 `game/pawns/data/skills/`，为保持技能资源同目录、避免后续技能继续散落在 `data/` 根，本 Increment 顺带完成目录整理与引用更新；不新增 Increment、不改任何技能数值。原调整说明（2026-09-25T21:50:38+08:00）：按外部设计评审意见补齐 Stage 2 的两处前提——① 1v3 的第三名敌人必须复用 1v1 的同一个核心 Boss，否则 Stage 3 的「同一 Boss」对照不成立；② 1v2 / 1v3 的胜利条件依赖 `INC-COMBAT-009` 的「敌方全灭才判胜」，否则第一名敌人死亡即提前终局。奖励口径不变：首通只给 `player_binding_skill.tres`，不含灵石 / 装备 / 强化 / 随机掉落。
- 目标：用三份独立、可重复挑战的遭遇数据支撑 Build 玩法验证——1v1 用来产生并观察「战斗问题」，1v2 / 1v3 用来观察 Build 是否带来多目标决策差异；首次通关 1v1 只发放定身术，不叠加任何资源奖励。
- 验收标准：
  - 新增 `game/world/data/encounters/build_test_1v1.tres`、`build_test_1v2.tres`、`build_test_1v3.tres` 三份独立遭遇资源，不覆盖既有 `trial_dungeon.tres` 与既有遭遇目录。
  - 1v1 使用核心 Boss（危险技能行为模式与 `INC-COMBAT-009` 一致）；1v2 / 1v3 使用行为角色不同的敌人组合（近战输出 / 远程输出 / 危险技能），不得是同一敌人复制 N 份。
  - 玩家侧始终只有 1 个 Pawn：三份遭遇的玩家数为 1，敌人数量依次为 1 / 2 / 3。
  - 1v3 的第三名敌人必须是 1v1 使用的同一个核心 Boss（同一数据与同一危险技能行为模式），近战 / 远程角色作为另外两名敌人，保证 Stage 3 的「同一 Boss」对照成立。
  - 1v2 / 1v3 的胜利条件依赖 `INC-COMBAT-009` 的「敌方全灭才判胜」；该判定未落地前 1v2 / 1v3 不得进入人工验收，只允许 1v1 先验收。
  - 三份遭遇均可在同一运行内重复挑战，重开不残留上一局单位、事件记录或技能状态。
  - 首次通关 1v1 后 100% 解锁 `player_binding_skill.tres`（定身术）并立即可装备；重复通关不重复发放首次解锁。
  - 首通奖励只有定身术：不得同时发放灵石、装备、强化或随机掉落，避免污染 Build 动机归因。
  - 数据测试断言三份遭遇的玩家 / 敌人数量、阵营、敌人 id 唯一性与奖励数量；不依赖截图或人工数值复述。
  - 定身术资源按 objective §25 的建议结构移动到 `game/pawns/data/skills/player_binding_skill.tres`，与 `enemy_boss_cleave.tres` 同目录，并更新全部引用路径（`.tres` / `.tscn` / 脚本 / 测试）；移动后既有 unit / integration 用例（含 `INC-PAWNS-021` 的装配用例）必须全绿。
  - 「重开不残留上一局状态」限定为**瞬时战斗状态**与事件记录：重开后不得残留上一局单位、上一局 CombatEvent、冷却 / 控制 / 施法进行中状态；已解锁技能与已装配 Build 按跨遭遇延续规则保留。
  - 跨遭遇延续：`SquadProgressSnapshot` 采集并写回「已解锁主动技能」与「显式装配过的主动技能列表」；在同一运行内「首通 1v1 解锁定身术 → 装配成 Build B → 重开同一遭遇」后，新单位的已掌握技能与已装配 Build 与重开前一致。
  - 三份试剑遭遇接到 `game/main/main.tscn` 的遭遇面板，实机可直接进入 1v1 / 1v2 / 1v3；面板按钮、遭遇资源、敌人数与站位一一对应（场景化 `tests/` 入口由 `INC-TESTING-012` 另行提供）。
- 范围：`game/world/data/encounters/build_test_1v1.tres` / `build_test_1v2.tres` / `build_test_1v3.tres`、必要的首通解锁奖励字段、1v2 / 1v3 敌人组合所需的既有敌人档案复用或最小新增、`player_binding_skill.tres` 的目录整理（`game/pawns/data/` → `game/pawns/data/skills/`）与全量引用更新、相关数据测试；`EncounterDefinition` 的首通奖励字段与 `EncounterSession` 的胜利结算发放接线；`SquadProgressSnapshot` 的主动技能采集 / 写回扩展与 `Pawn` 的装配状态只读查询；`game/main/main.tscn` 把三份试剑遭遇接到既有遭遇面板作为实机入口。
- 依赖：`INC-COMBAT-009`（危险窗口与事件）、`INC-PAWNS-021`（技能掌握与装配）；父 Increment `INC-CROSS-019`。
- 检索证据：2026-09-25T22:20:30+08:00 执行 `git status --short`（`INC-COMBAT-009` 已提交后工作区仅剩 Godot 编辑器重写噪音）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）、`git log --oneline -3 -- agent-plan/`（HEAD `46ffe71`）与 `git grep -n -E "INC-(WORLD-007|UI-018|TESTING-011)" -- agent-plan/`；结论：`INC-WORLD-007` 仍为 `planned`、无任何实现，可安全开工。依赖核对：`INC-COMBAT-009` 已提供危险窗口与 `dangerous_skill` 字段（`game/pawns/data/enemies/enemy_dungeon_boss.tres` 已配置 8 秒 / 2 秒窗口）、`INC-PAWNS-021` 已提供 `learn_active_skill()` / `set_active_skill_loadout()` / `get_known_active_skills()` / `get_equipped_active_skills()` / `get_enabled_active_skills()`；`EncounterDefinition` 已支持 `enemy_squad` 与 `player_count`；**缺口**：`SquadProgressSnapshot.capture_progress()` 只携带强化等级 / 功法 / 境界 / 修为，不含主动技能的解锁与装配，因此换局会丢失定身术与 Build B（本次补齐）；`EncounterDefinition` 尚无首通奖励字段。 历史记录（2026-09-25T22:12:40+08:00）：`git status --short`（`INC-COMBAT-009` 工作区改动 + 编辑器噪音）、`git diff --unified=0 -- agent-plan/`（读取本批调整）、`git log --oneline -5 -- agent-plan/`（最新 `ca3f2f2`）与 `git grep -n "INC-WORLD-007"`；`INC-WORLD-007` 仍为 `planned`、未实现。既有 `game/world/data/encounters/` 提供 3 份单人遭遇；`SquadDefinition.MAX_MEMBERS = 4`，`get_spawn_offsets()` 可自动生成站位，多敌人数据无需新契约。
- 风险：如果首通奖励同时给资源，玩家第二轮再战的动机无法归因到定身术；必须坚持「奖励 = 新能力」单一变量。第二个风险是 1v2 / 1v3 退化成同一敌人复制，导致目标选择没有真实差异，必须使用行为角色不同的敌人组合。第三个风险是重复挑战残留上一局状态，必须由重开路径显式清理。
- 实现说明：三份试剑遭遇落地为独立数据资源：`build_test_1v1.tres` 指向新增 Boss 档案 `enemy_build_test_boss.tres`（520 血 / 60 盾、8 秒开窗 / 2 秒危险技能），
  `build_test_1v2.tres` / `build_test_1v3.tres` 用 `SquadDefinition` 组合「赤拳战修（近战 62）+ 灵弓修者（远程 230）」，且 1v3 的第三名成员就是 1v1 的同一个 Boss 资源实例；三份都显式 `player_count = 1`。
  首通奖励只描述「奖励是什么」：`EncounterDefinition.first_clear_skill_reward`（null 表示无奖励）+ `EncounterSession._grant_first_clear_reward()` 在「敌方全灭判胜」那一刻调用 `Pawn.learn_active_skill()`——只解锁、不装配；
  重复通关按技能 id 去重返回 false，因此不需要额外的发放记账。
  跨遭遇延续补齐：`SquadProgressSnapshot.capture_progress()` 增加「已解锁主动技能 / 是否显式重配过 / 已装配列表」，`apply_progress()` 在**恢复境界之后**写回装配，
  避免新单位用静态炼气容量误判 Build B；`Pawn.has_explicit_active_skill_loadout()` 让「从未重配」与「显式清空」保持可区分。
  技能资源按 objective §25 的结构从 `game/pawns/data/` 移到 `game/pawns/data/skills/`，4 处引用同步更新；`game/main/main.tscn` 追加三条 `ext_resource` 并把三份遭遇接进遭遇面板作为实机入口。
- 变更文件：
  - 数据：`game/world/data/encounters/build_test_1v1.tres`、`build_test_1v2.tres`、`build_test_1v3.tres`、`game/world/data/squads/build_test_squad_1v2.tres`、`build_test_squad_1v3.tres`、`game/pawns/data/enemies/enemy_build_test_boss.tres`、`enemy_melee_raider.tres`、`enemy_spirit_archer.tres`、`game/pawns/data/skills/player_binding_skill.tres`（由 `game/pawns/data/player_binding_skill.tres` 移动）。
  - 代码：`game/shared/resources/encounter_definition.gd`（首通奖励字段与 `has_first_clear_reward()`）、`game/world/encounter_session.gd`（`_grant_first_clear_reward()`）、`game/shared/core/squad_progress_snapshot.gd`（主动技能采集 / 写回）、`game/pawns/pawn.gd`（`has_explicit_active_skill_loadout()`）、`game/main/main.tscn`（三份遭遇接线）。
  - 测试：`test/unit/build_test_encounter_catalog_test.gd`（新增）、`test/integration/first_clear_reward_test.gd`（新增）、`test/gameplay/main_scene_encounter_test.gd`（遭遇面板断言兼容 `enemy_squad`）、`test/gameplay/build_decision_differentiation_test.gd` / `build_tactical_trajectory_test.gd` / `test/integration/danger_window_combat_event_test.gd` / `test/unit/tactical_skill_catalog_test.gd`（技能资源路径更新）。
- 测试证据：
  - 单套件（数据层）：`godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/unit/build_test_encounter_catalog_test.gd --ignoreHeadlessMode` → `5 test cases | 0 errors | 0 failures | 0 orphans`，Exit code 0。
  - 单套件（集成层）：同命令跑 `res://test/integration/first_clear_reward_test.gd` → `4 test cases | 0 errors | 0 failures | 0 orphans`，Exit code 0。
  - 全量门禁：`pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all` → `RESULT: PASS`，exit 0；`GdUnit4 : 386 cases, 0 failures`（unit 161 / integration 165 / gameplay 60）、`headless : 10 suites, 549 assertions, 0 failing suites`。
  - 首轮暴露两处真实问题并修复后复跑：① 1v2 / 1v3 走 `enemy_squad`，既有 `main_scene_encounter_test.gd` 只接受 `enemy_profile`，已改为「至少一侧是正式档案 + 敌人数与站位一一对应」；② 数据用例最初把敌人 id 唯一性写成跨遭遇唯一（1v3 刻意复用 1v2 的两名角色与 1v1 的 Boss），已改为按场唯一并把复用写成显式期望。
  - 覆盖点：玩家数恒为 1 且敌人数依次 1 / 2 / 3、敌人阵营与场内 id 唯一、奖励只挂在 1v1 且只有 `binding_spell`、1v3 复用同一 Boss 实例、1v2 近战 / 远程射程差 2 倍以上；首通只解锁不自动装配、无奖励遭遇不发技能、重开清瞬时状态但保留解锁且不重复记账、玩家显式换 Build B 后跨遭遇仍为「御剑斩 + 定身术」。
- 验证状态：验证通过（数据层 + 集成层 + 全量门禁）
- 验证时间：2026-09-25T22:21:30+08:00
- 已知问题：`INC-TESTING-012`（场景化测试入口拆分到 `tests/`）尚未落地，当前实机入口是主场景遭遇面板里**临时**追加的三份试剑遭遇；按用户「测试入口拆分到 `tests/`」的硬要求，这三条 `main.tscn` 条目由 `INC-TESTING-012` 移出并改为 `tests/` 场景入口（本 Increment 只保证数据与解锁链路成立）。1v2 / 1v3 的人工玩法验收必须等 `INC-UI-018`（Build A/B 切换面板）与 `INC-TESTING-012` 完成。
  三份试剑遭遇的数值是首版手感值，未做平衡校验，本 Increment 不验证平衡性。
  本机 Godot 编辑器打开本工程时会把 `main.tscn` / `trial_dungeon.tres` 重新序列化（补 `unique_id` / `uid`、改写 `Array[ExtResource(...)]`），提交前必须还原这些编辑器噪音，否则提交会把无关改动混进增量。
- 用户验收：待验收
- 验收时间：待验收
- Git：待提交（本 Increment 实现提交，提交后补记 hash）
- 备注：实现顺序上本 Increment 在 `INC-COMBAT-009` / `INC-PAWNS-021` 之后、`INC-UI-018` 之前；它只提供「可重复进入的三档遭遇 + 首通解锁 + 跨遭遇延续」这三件实验器材，不提供人工结论。定身术是本次实验唯一的主要变量，45 灵石等经济奖励不进入本 Increment。1v2 / 1v3 只有在 1v1 的 Build 闭环成立后才进入人工验收（`INC-CROSS-019` Stage 2）。

## INC-WORLD-008：秘境问题房间（按战斗问题组合，而非数值递增）

- 状态：planned
- 创建时间：2026-09-26T01:56:11+08:00
- 最后修改：2026-09-26T01:56:11+08:00
- 主题：world
- 目标：把秘境房间从「随机 / 递增的敌人组合」改成「明确的战斗问题组合」——每个房间由 1~2 个压力型（近战压力 / 远程压力 / 控制压力 / 高爆发压力 / 群体压力 / 高防御压力）构成，玩家在不同房间遇到的问题不同，而不是同一个问题数值变大。
- 验收标准：
  - 建立 10~15 个「问题房间」定义，每个房间显式声明它考查的问题型，且敌人阵容与该问题型一致。
  - 房间链上的解锁顺序形成「遇到问题 → 获得技能 → 再遇到需要该技能的问题」的闭环；至少一条链上出现 2~3 次这样的因果。
  - 同一 Build 连续通过两个不同问题型的房间时，出现「不换技能就明显更吃力」的可复现差异（以通关耗时 / 灵力消耗 / 剩余生命为客观量）。
  - 房间组合不引入随机掉落、装备、属性膨胀等第二变量。
  - 统一门禁 `RESULT: PASS`。
- 范围：`game/world/data/dungeons/`、`game/world/data/encounters/`、`game/world/data/squads/`、必要的 `game/world/encounter_session.gd` 与秘境面板接线、`test/unit/dungeon_definition_test.gd`、`test/integration/dungeon_run_test.gd`。
- 非范围：程序化随机生成、地图 / 关卡美术、房间内解谜、商店 / 掉落、难度自适应、Boss 分阶段。
- 依赖：`INC-COMBAT-011`（问题型敌人）、`INC-PAWNS-022`（玩家技能池）。
- 检索证据：2026-09-26T01:56+08:00 `git grep` 确认 `INC-WORLD` 已用至 007；读取 `game/world/data/encounters/*.tres` 与 `game/world/data/dungeons/trial_dungeon.tres`，现有遭遇共 7 份且以单敌人档案为主，秘境只有一份试炼秘境，没有「问题型房间」这一层表达。
- 风险：① 房间数量上升会放大既有 orphan 债务与运行时用例时长；② 问题型如果只写在 description 里而数据不可查询，就无法被自动化验证；③ 若在同一轮同时引入敌人机制与房间链，出问题时无法定位是敌人还是编排导致。
- 实现说明：
- 变更文件：
- 测试证据：
- 验证状态：未验证
- 验证时间：
- 已知问题：
- 用户验收：未验收
- 验收时间：
- Git：待提交
- 备注：父 Increment 为 `INC-CROSS-021`；本项把 `INC-COMBAT-011` 的问题型敌人编排成玩家可感的顺序。
