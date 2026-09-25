# 宗门主题计划（洞府 / 聚灵阵 / 灵田 / 丹房 / 炼器房 / 藏经阁）

> 最后修改：2026-09-25T19:38:41+08:00
> 主题：sect
> 规则来源：`../AGENTS.md`
> 设计源：`../docs/project_summary.md` §十五（秘境 → 资源 → 宗门 → Build 闭环）、§十七 / §十八 ⑤（最小宗门）

## 主题定位

宗门不是第二套游戏，只回答一件事：

> **「我要回去修炼 / 制作 / 强化，然后再次出发。」**

因此本主题的每个 Increment 都必须能连回「秘境收益 → 宗门产出 → 修士变强 → 再打一轮」，不做人口、食物、住房、满意度等 Colony Sim 系统（`docs/project_summary.md` §十九、风险 4）。

## INC-SECT-001：宗门设施静态定义与六座设施数据

- 状态：accepted
- 创建时间：2026-09-25T19:22:00+08:00
- 最后修改：2026-09-25T19:38:41+08:00
- 主题：sect
- 目标：把 `docs/project_summary.md` §十八 ⑤ 列出的六座最小宗门设施（洞府 / 聚灵阵 / 灵田 / 丹房 / 炼器房 / 藏经阁）落成可复用的静态资源，回答「这座设施是什么、能升到几级、升级要多少灵石、单次转化消耗什么、每级产出多少」，作为运行时 `SectState` 与宗门面板的唯一数据来源。
- 验收标准：
  - 新增 `SectFacilityDefinition`（`id` / `display_name` / `kind` / `description` / `base_upgrade_cost` / `upgrade_cost_growth` / `max_level` / `required_realm_tier` / `spirit_stone_cost` / `herb_cost` / `yield_per_level`），提供 `is_configured()`、`get_upgrade_cost(level)`、`can_upgrade(level)`、`get_yield(level)` 与静态 `kind_label(kind)`。
  - `get_upgrade_cost(level)`：`level < 0` 或 `level >= max_level` 返回 `-1`（调用方据此判断不可升级）；`0 <= level < max_level` 返回 `base_upgrade_cost + upgrade_cost_growth * level`，负花费与负成长按 0 截断。
  - `get_yield(level)`：`max(level, 0) * yield_per_level`，负产出按 0 截断；未知 `kind` 的标签回退为占位文案，不返回空串。
  - 六座设施数据落盘在 `game/sect/data/facilities/`，且 `id` 与文件名一致、`kind` 互不重复、每座 `max_level >= 1` 且 `base_upgrade_cost > 0`。
  - 洞府 / 聚灵阵 / 灵田 / 丹房 / 炼器房 / 藏经阁 的 `kind` 分别为 `cave_dwelling` / `spirit_array` / `spirit_field` / `alchemy_room` / `forge_room` / `scripture_pavilion`；六座设施 `required_realm_tier` 均为 1（门槛字段本 Increment 只落地语义，不引入更高门槛）。
  - 新增单元用例覆盖：默认值与空 id / 空显示名的未配置判定、升级花费随等级线性递增与满级 / 负等级返回 -1、产出随等级增长与负等级截断、未知 kind 的标签回退，以及六座设施资源的真实字段与 id 唯一性。
- 范围：`game/shared/resources/sect_facility_definition.gd`（新增）、`game/sect/data/facilities/*.tres`（新增 6 份）、`test/unit/sect_facility_definition_test.gd`（新增）。
- 非范围：库存与升级执行、产出结算、宗门面板与输入、存档、建筑美术（贴图 / 图标 / 动效）、设施建造与拆除、灵根或流派对设施效率的影响、真实时间挂机产出。
- 依赖：无（纯静态资源与纯逻辑）；被 `INC-SECT-002`、`INC-SECT-003` 依赖。
- 检索证据：`git status --short` 为空（干净工作区）；`git diff --unified=0 -- agent-plan/` 与 `git diff --cached --unified=0 -- agent-plan/` 均为空；`git log --oneline -5 -- agent-plan/` 顶部为 `0845f91`（`INC-CROSS-016` 收尾）；`git grep -o -E "INC-(SECT|CROSS|PAWNS|UI|CORE|TESTING)-[0-9]{3}" -- agent-plan/` 确认 SECT 编号完全未占用、CROSS 最高 016、PAWNS 最高 017、UI 最高 015、CORE 最高 009、TESTING 最高 008；`git grep -n -i -E "sect|宗门" -- agent-plan/ game/` 命中的全部是既有 Increment 的「非范围」声明（`_index.md` 主题索引中宗门为「未创建」），确认 `game/sect/` 与 `game/shared/resources/sect_facility_definition.gd` 在代码层完全缺失。结论：本 Increment 未被占用，允许范围仅限上述设施定义、六份设施数据与对应单元测试。
- 风险：设施数值一旦写得过大，宗门会立刻替代秘境成为收益来源，破坏「秘境是主要风险收益场」的设计；因此本 Increment 只落地字段与相对关系，绝对数值在 `INC-SECT-002` 的集成用例中按「一轮满额秘境收益 ≈ 一次升级」标定。另一风险是设施类型被当成万能开关，后续把 Colony Sim 内容塞进 `kind`，因此 `kind` 只表达六座设施的功能分类，不表达等级、产出或消耗。
- 实现说明：`SectFacilityDefinition` 只持有静态配置与纯函数派生规则（升级花费 / 可否升级 / 等级产出 / 类别标签），不持有等级、库存或任何运行时数值；升级花费按 `base + growth × level` 线性递增，越界与满级统一返回 `UPGRADE_COST_UNAVAILABLE = -1`，避免调用方各自判断「满级」；负花费、负成长与负产出一律按 0 截断，防止配置笔误变成负收益。六座设施各写一份 `.tres`，`kind` 与 `ALL_KINDS` 一一对应：洞府（效率倍率，`yield_per_level = 0`）、聚灵阵（8 修为 / 级）、灵田（2 灵草 / 级）、丹房（消耗 2 灵草 → 1 丹药 / 级）、炼器房（消耗 40 灵石 → 1 级强化）、藏经阁（消耗 45 灵石 → 1 份功法）。数值按「`INC-CROSS-016` 试炼秘境满额 250 灵石 ≈ 一轮完整的一级宗门建设」标定：六座设施 1→2 级合计 380 灵石、2→3 级合计 620 灵石，避免宗门在一次秘境后立刻失去升级空间。
- 变更文件：
  - `game/shared/resources/sect_facility_definition.gd`（新增，含 `.uid`）
  - `game/sect/data/facilities/cave_dwelling.tres`（新增）
  - `game/sect/data/facilities/spirit_array.tres`（新增）
  - `game/sect/data/facilities/spirit_field.tres`（新增）
  - `game/sect/data/facilities/alchemy_room.tres`（新增）
  - `game/sect/data/facilities/forge_room.tres`（新增）
  - `game/sect/data/facilities/scripture_pavilion.tres`（新增）
  - `test/unit/sect_facility_definition_test.gd`（新增）
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer unit` → `RESULT: PASS`，退出码 0；`GdUnit4 unit 119 cases / 0 failures`（本 Increment 前为 112 cases），新增 7 个用例全通过：未配置判定、升级花费线性递增与满级 / 负等级返回 -1、负花费与负产出截断、产出随等级缩放、六类标签覆盖与未知回退、六份正式设施的 id / kind 唯一性与字段约束、六座设施的功能分工（洞府不产修为、丹房耗灵草、炼器房与藏经阁耗灵石）。
  - 六份 `.tres` 由单元用例按 `resource_path` 真实加载并断言字段，因此「资源存在且能解析」由用例本身证明，不使用复制数值。
  - `<godot> --headless --path . --import` → 退出码 0，`SectFacilityDefinition` 全局类注册成功并生成 `sect_facility_definition.gd.uid`（导入过程仅有沙箱外的编辑器设置写盘告警，与工程无关）。
- 验证状态：验证通过
- 验证时间：2026-09-25T19:23:44+08:00
- 已知问题：
  - 设施只有静态定义与数值派生规则：升级、产出、转化与面板全部留给 `INC-SECT-002` / `INC-SECT-003` / `INC-UI-016`。
  - 六座设施的 `required_realm_tier` 目前统一为 1，只落地字段语义，尚未出现「高境界才能升级」的设施。
  - 设施数值只按「一轮秘境 ≈ 一轮建设」做相对标定，真实节奏要等 `INC-TESTING-009` 的闭环用例与后续调参。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「推送」）
- 验收时间：2026-09-25T19:38:41+08:00
- Git：`main` / `c25ffbc`
- 备注：父 Increment 为 `INC-CROSS-017`。

## INC-SECT-002：SectState 运行时（灵石 / 灵草库存、设施等级、升级与产出）

- 状态：accepted
- 创建时间：2026-09-25T19:22:00+08:00
- 最后修改：2026-09-25T19:38:41+08:00
- 主题：sect
- 目标：建立宗门运行时，把秘境收益真正存下来：持有灵石 / 灵草 / 丹药库存、记录六座设施等级、执行「消耗灵石升级设施」，并提供「打坐修炼（产修为）」与「灵田收获（产灵草）」两条基础产出，让「回去修炼一下再出发」成立。
- 验收标准：
  - 新增 `game/sect/sect_state.gd`（`class_name SectState extends Node`）：设施来自 `@export var facilities: Array[SectFacilityDefinition]`，运行时模块不硬编码设施 id、花费或产出数值。
  - 库存：`spirit_stones` / `spirit_herbs` / `pills` 初始均为 0；`deposit_spirit_stones(amount)` 只接受正有限值，返回实际入账量，负值 / NaN / 无穷不改变任何库存。
  - 设施等级：`get_facility_level(id)` 对未知 id 返回 0；已注入设施初始等级为 1；`get_facility(id)` 越界或未知返回 null。
  - 升级：`can_upgrade_facility(id)` / `get_upgrade_cost(id)` / `upgrade_facility(id)` 三者共用同一判定（设施存在 + 未满级 + 灵石足够 + 修士境界 tier ≥ `required_realm_tier`）；任一条不满足时返回 false / -1 且不扣任何灵石；成功时扣灵石、等级 +1，并广播 `facility_upgraded` 与库存信号。
  - 修炼：`cultivate()` 给绑定修士增加修为，数值为「聚灵阵产出 ×（1 + 洞府等级 × 0.5）」，写入 `Pawn.gain_cultivation_exp()`（不直接改 `CultivationProgressComponent`）；未绑定修士、聚灵阵等级为 0 或修为收益为 0 时返回 0 且无副作用。
  - 灵田收获：`harvest_spirit_field()` 把「灵田等级 × `yield_per_level`」加入灵草库存并返回实际入库量；灵田等级为 0 时返回 0。
  - `get_snapshot()` 返回 UI 可直接渲染的只读字典：三种库存 + 每座设施（id / 名称 / kind / 等级 / 上限 / 下次升级花费 / 是否可升级 / 不可升级原因），不泄漏内部字典引用。
  - 新增集成用例在真实 `Pawn` 场景上跑通「秘境收益入账 → 升级扣费 → 打坐涨修为 → 灵田收草」，并断言「灵石不足」「已满级」「境界门槛不足」「未绑定修士」四条拒绝路径都不产生副作用；数值标定为 `INC-CROSS-016` 试炼秘境的满额收益（225）至少够一次首级升级。
- 范围：`game/sect/sect_state.gd`（新增）、`test/integration/sect_state_test.gd`（新增）。
- 非范围：藏经阁 / 炼器房 / 丹房的转化行为（由 `INC-SECT-003` 实现）、秘境接线与面板（`INC-CORE-010` / `INC-UI-016`）、存档与读档、设施建造 / 拆除、离线或真实时间挂机产出、宗门人口 / 贡献度 / 声望。
- 依赖：`INC-SECT-001`（已验收后才进入本 Increment 实现阶段）。
- 检索证据：Git Diff 优先检索结论同 `INC-SECT-001`；`git grep -n -E "SectState|sect_state" -- game/ test/` 无匹配，确认宗门运行时尚未存在；`DungeonRun.get_earned_spirit_stones()` 已存在但收益只存在于本局内存中，没有任何持久化或入账目标（`game/world/dungeon_run.gd`），因此本 Increment 是「收益落地」的唯一新增写入者。
- 风险：宗门一旦持有灵石库存，就出现了第二个「收益权威」；若允许 `SectState` 自己产生灵石，秘境收益会被架空，因此本 Increment 明确规定灵石只能通过 `deposit_spirit_stones()` 从外部入账。另一风险是设施生产效率写成硬编码常量，导致数值调整要改代码，因此所有产出与消耗都必须来自 `SectFacilityDefinition`。
- 实现说明：`SectState` 是 `Node` 子类，六座设施通过 `@export var facilities` 注入，`_ready()` 调用幂等的 `initialize_facilities()`，为每座设施建立初始等级 1；模块只硬编码三条「职责 id」（洞府 = 效率倍率、聚灵阵 = 修为产出、灵田 = 灵草产出），所有花费与产出数值都来自设施定义。升级判定收敛为单一函数 `get_upgrade_block_reason()`：设施存在 → 未满级 → 灵石足够 → 修士境界达标，`can_upgrade_facility()` / `upgrade_facility()` 都复用它，因此面板展示的原因与运行时裁决不可能不一致。灵石只能从 `deposit_spirit_stones()` 入账，宗门自身不产生灵石，保证秘境仍是唯一收益来源。打坐按「聚灵阵产出 ×（1 + 洞府等级 × 0.5）」计算，并调用 `Pawn.gain_cultivation_exp()` 写入修为——修为写入的唯一出口仍是 `CultivationProgressComponent`，宗门不复制境界数值；由于修为在境界阈值处被截断，免费打坐天然被瓶颈封顶。`get_snapshot()` 每次返回全新字典与全新条目字典，UI 只读渲染，外部改动不回流。
- 变更文件：
  - `game/sect/sect_state.gd`（新增，含 `.uid`）
  - `test/integration/sect_state_test.gd`（新增）
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer integration` → `RESULT: PASS`，退出码 0；`GdUnit4 integration 119 cases / 0 failures`（本 Increment 前为 108 cases），新增 11 个用例全通过：只接受正数入账、六座设施初始 1 级与未知 id 归零、升级扣费与 `facility_upgraded` 信号、灵石不足时零副作用、满级后返回 -1 且拒绝升级、未绑定修士 / tier 3 设施的境界门槛拒绝、打坐随聚灵阵与洞府等级变化（12 → 16 → 32）、打坐止于突破阈值、未绑定修士打坐为 0、灵田收获随等级变化（2 → 4）、快照为只读副本。
  - 「秘境收益入账」的数值直接取正式 `trial_dungeon.tres` 的 `get_max_reward()`（250），不复制奖励常量。
  - `<godot> --headless --path . --import` → 退出码 0，`SectState` 全局类注册成功并生成 `sect_state.gd.uid`。
- 验证状态：验证通过
- 验证时间：2026-09-25T19:25:11+08:00
- 已知问题：
  - 转化设施尚未实现：藏经阁 / 炼器房 / 丹房的按钮与数值属于 `INC-SECT-003`；`pills` 目前恒为 0，只作为库存字段与面板占位。
  - 打坐不消耗灵石，产出只被境界阈值封顶；若后续开放突破，需要重新标定修炼成本（否则「回去修炼」会退化为无限刷修为）。
  - 宗门状态只存在于内存：换局不重置，但退出游戏不保留（存档属于 save 主题的后续 Increment）。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「推送」）
- 验收时间：2026-09-25T19:38:41+08:00
- Git：`main` / `8c65ff1`
- 备注：父 Increment 为 `INC-CROSS-017`。

## INC-SECT-003：转化设施（藏经阁参悟 / 炼器房强化 / 丹房炼丹）

- 状态：accepted
- 创建时间：2026-09-25T19:22:00+08:00
- 最后修改：2026-09-25T19:38:41+08:00
- 主题：sect
- 目标：让宗门从「产资源」升级为「产 Build」：藏经阁用灵石参悟新功法并进入修士运行时功法列表、炼器房用灵石强化主武器、丹房用灵草炼出丹药并可在出发前服用恢复生命 / 灵力，三者都把结果落在运行时覆盖层上，不改写任何静态 `.tres`。
- 验收标准：
  - 藏经阁 `learn_technique_from_pavilion(technique) -> bool`：校验设施等级 ≥ 1、灵石足够、修士境界 tier ≥ 功法 `required_realm_tier`、功法已配置且未领悟；成功时扣 `spirit_stone_cost`、把功法写入修士运行时列表并发出 `technique_learned`，返回 true；失败返回 false 且不扣灵石、不改变修士状态。
  - 炼器房 `strengthen_weapon() -> bool`：校验设施等级 ≥ 1、灵石足够、修士有主武器且强化等级未达设施等级上限；成功时扣 `spirit_stone_cost`、修士强化等级 +1 并发出 `weapon_strengthened`，返回 true；失败返回 false 且无副作用。
  - 丹房 `refine_pill() -> int`：校验设施等级 ≥ 1、灵草 ≥ `herb_cost`；成功时扣灵草、丹药 +`get_yield(level)` 并发出 `pill_refined`，返回本次产出数量，失败返回 0 且无副作用。`use_pill() -> float` 在丹药 > 0 且修士存活时消耗 1 颗，按 `设施等级 × PILL_RESTORE_PER_LEVEL` 分别恢复生命与灵力，返回两者实际恢复量之和并发出 `pill_used`；丹药为 0、修士未绑定或已死亡时返回 0 且不消耗丹药。
  - 三条转化路径都不修改 `PawnData`、`WeaponDefinition`、`TechniqueDefinition` 的任何字段（用 `resource_path` 读取真实资源断言），只通过 `INC-PAWNS-018` 提供的运行时覆盖层生效。
  - 新增集成用例覆盖：三条成功路径的数值与信号、以及「灵石不足」「灵草不足」「功法门槛不足」「重复领悟」「无武器」「丹药为 0」六条拒绝路径。
- 范围：`game/sect/sect_state.gd`（新增转化部分）、`test/integration/sect_state_conversion_test.gd`（新增）。
- 非范围：功法 / 武器的正式掉落表、装备槽更换与卸下、丹药作为背包物品的抽象与堆叠上限、炼丹配方系统、强化失败与保底、炼器房多武器选择、藏经阁随机功法池。`PILL_RESTORE_PER_LEVEL` 只定义 MVP 的每级恢复量，不引入药品品质 / 持续时间 / 战斗中使用。
- 依赖：`INC-SECT-001`、`INC-SECT-002`、`INC-PAWNS-018`。
- 检索证据：Git Diff 优先检索结论同 `INC-SECT-001`；`git grep -n -E "learn_technique|strengthen_weapon|refine_pill|use_pill" -- game/ test/` 无匹配，确认三条转化路径均未实现；`game/shared/resources/technique_definition.gd` 明确声明「功法本身不授予技能、不结算属性；授予与解锁属于后续 Increment」，本 Increment 正是该声明的兑现者。
- 风险：最大风险是把「领悟功法」实现成直接改 `PawnData.techniques`，那会污染共享静态资源并让其它使用同一档案的单位一起变强，因此本 Increment 强制依赖运行时覆盖层。第二风险是丹房被做成完整物品 / 背包系统，本 Increment 只做「丹药计数 + 立刻恢复」，把物品化留给后续库存主题。
- 实现说明：`SectState` 新增四条转化路径与四个变更信号。藏经阁先做设施 / 修士 / 境界 / 查重 / 灵石五重校验，再调用 `Pawn.learn_technique()` 写运行时列表；炼器房以 `min(设施等级, Pawn.MAX_FORGE_LEVEL)` 为上限，先确认 `Pawn.strengthen_weapon()` 确实递增再扣灵石；丹房把灵草换成 `get_yield(level)` 颗丹药；服丹按 `丹房等级 × PILL_RESTORE_PER_LEVEL` 分别调用 `Pawn.restore_health()` 与 `Pawn.restore_spirit()`，返回实际恢复总量。所有路径都只写 `SectState` 库存与 `Pawn` 运行时覆盖层。
- 变更文件：`game/sect/sect_state.gd`（新增转化方法、信号与 `PILL_RESTORE_PER_LEVEL`）、`test/integration/sect_state_conversion_test.gd`（新增，含 `.uid`）。
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer integration` → `RESULT: PASS`，退出码 0；`GdUnit4 integration 130 cases / 0 failures`（本 Increment 前为 122 cases），新增 8 个用例覆盖藏经阁成功 / 灵石不足 / 空功法 / 重复 / 境界不足、炼器房成功 / 武器不存在 / 灵石不足 / 设施等级封顶、丹房成功 / 灵草不足、服丹恢复生命与灵力 / 无修士 / 已死亡拒绝，以及三条路径对真实静态资源零污染。
  - 丹药恢复用例使用真实 Player Pawn：`100/120` 生命与 `60/100` 灵力，1 级丹房服丹后恢复到 `115/120` 与 `75/100`，实际恢复量 = 30。
- 验证状态：验证通过
- 验证时间：2026-09-25T19:32:01+08:00
- 已知问题：丹药目前是宗门库存计数，不是背包物品；强化与参悟没有二次确认、冷却或失败率；`PILL_RESTORE_PER_LEVEL` 是 MVP 固定值，药品品质与战斗中使用属于后续主题；转化设施面板入口由 `INC-UI-016` 实现。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「推送」）
- 验收时间：2026-09-25T19:38:41+08:00
- Git：`main` / `9c97ef9`
- 备注：父 Increment 为 `INC-CROSS-017`。
