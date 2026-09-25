# Cultivation 主题计划（境界 / 功法 / 突破 / 修炼）

> 最后修改：2026-09-25T20:17:57+08:00
> 主题：cultivation  
> 规则来源：`../AGENTS.md`

## INC-CULT-001：境界定义与 Build 容量表

- 状态：accepted
- 创建时间：2026-09-25T15:48:08+08:00
- 最后修改：2026-09-25T15:56:30+08:00
- 主题：cultivation
- 目标：把“境界决定 Build 容量”落成可复用的 `RealmDefinition` 资源与炼气→化神五个境界数据，供 Build 校验与 HUD 读取。
- 验收标准：
  - 新增 `RealmDefinition`（`id` / `display_name` / `tier` / `technique_slots` / `active_skill_slots` / `passive_skill_slots`），提供 `is_configured()` 与 `get_slot_capacity(kind)`；未知 kind 返回 0。
  - 五个境界资源落在 `game/cultivation/data/realms/`，容量与 `docs/project_summary.md` §4.1 一致：炼气 1/2/1、筑基 2/3/2、金丹 3/4/3、元婴 4/5/4、化神 5/6/5，`tier` 依次 1..5。
  - 未配置的新实例 `is_configured()` 为假；两个实例互不共享可变数值。
  - 新增单元用例覆盖默认值、容量映射与五个境界的表格数值。
- 范围：`game/shared/resources/realm_definition.gd`（新增）、`game/cultivation/data/realms/*.tres`（新增 5 个）、`test/unit/realm_definition_test.gd`（新增）。
- 非范围：境界属性加成、突破流程、修炼速度、境界美术与存档字段。
- 依赖：无（纯静态数据 + 纯逻辑）。
- 检索证据：执行 `git status --short --branch`、`git grep -n -E "INC-CULT-|INC-CROSS-007|RealmDefinition|BuildValidator|TechniqueDefinition"`（无匹配）、`git log --oneline -- agent-plan/cultivation.md`（文件未创建）；`agent-plan/_index.md` 主题索引中“修炼”此前状态为“未创建”；当前 `HEAD=3bd28fb`，工作区含待验收的 `INC-CROSS-002`~`INC-CROSS-006` 变更，与本 Increment 无文件重叠。
- 风险：容量数值散落在测试与文档之外产生漂移；Resource 默认值共享；后续扩展境界时必须保持 `tier` 单调递增。
- 实现说明：`RealmDefinition` 只保存静态配置，容量查询统一走 `get_slot_capacity(kind)`（未知类别返回 0）；三个容量字段使用 `@export_range(..., "or_greater")`，避免出现负容量。五个境界资源按 `docs/project_summary.md` §4.1 表格落盘，`tier` 1..5 与 `id` 一一对应，作为 `BuildValidator` 境界门槛判定的唯一依据。
- 变更文件：`game/shared/resources/realm_definition.gd`（新增）、`game/shared/resources/realm_definition.gd.uid`（新增）、`game/cultivation/data/realms/qi_refining.tres`、`foundation_establishment.tres`、`golden_core.tres`、`nascent_soul.tres`、`spirit_transformation.tres`（新增）、`test/unit/realm_definition_test.gd` 与其 `.uid`（新增，5 例）。
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer unit` → `[GdUnit4] unit ... FAIL (42 cases, 0 errors, 1 failures)`；本 Increment 的 `test/unit/realm_definition_test.gd` 5 例全部通过（默认值、空 id 与未知 kind、五个境界容量对照设计表、tier 单调、实例不共享容量）。
  - Godot MCP `validate`：`game/shared/resources/realm_definition.gd` → `valid: true`。
  - `git diff --check` 退出码 0。
- 验证状态：验证通过（本 Increment 范围内）
- 验证时间：2026-09-25T15:56:30+08:00
- 已知问题：`-Layer unit` 的唯一失败是 `test/unit/pawn_data_defaults_test.gd > test_enemy_preset_declares_no_spirit`（`max_health` 期望 80、实际 180），与本 Increment 无关；来源与处置见父级 `INC-CROSS-007` 的“验证结论”和“已知问题”。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `3351bc1`
- 备注：父 Increment 为 `INC-CROSS-007`；本 Increment 只建立境界容量数据契约，不改变任何运行时数值。

## INC-CULT-002：功法/被动技能定义与 Build 容量冲突校验

- 状态：accepted
- 创建时间：2026-09-25T15:48:08+08:00
- 最后修改：2026-09-25T15:56:30+08:00
- 主题：cultivation
- 目标：定义功法与被动技能的静态资源，并建立 Build 容量、重复、功法互斥与境界门槛校验器，让“更高境界 ≠ 自动装备所有强力技能”成为可测试规则。
- 验收标准：
  - 新增 `TechniqueDefinition`（`id` / `display_name` / `school` / `description` / `required_realm_tier` / `conflict_tags`）与 `PassiveSkillDefinition`（`id` / `display_name` / `required_realm_tier`），均提供 `is_configured()`；功法提供 `get_shared_conflict_tag(other) -> StringName`。
  - 新增 `BuildLoadout`（`realm` + `techniques` + `active_skills` + `passives`）与 `BuildValidator.validate(loadout) -> BuildValidationResult`，覆盖规则：缺境界、容量超限、同类重复、功法互斥、境界不足、条目未配置。
  - `BuildValidationResult` 暴露 `is_valid()`、`has_errors()`、`get_errors()`（每项含 `code` / `kind` / `entry_id` / `message`）、`get_error_codes()` 与 `get_summary()`，错误文案可直接给 HUD 使用。
  - 三个功法资源落在 `game/cultivation/data/techniques/`：剑修（基线，无冲突标签）、雷修（`required_realm_tier = 2`）、体修（与剑修共享 `sword_body_conflict`）。
  - 新增单元用例逐条覆盖上述规则、组合错误与 `get_summary()` 文案。
- 范围：`game/shared/resources/technique_definition.gd`、`game/shared/resources/passive_skill_definition.gd`、`game/shared/build/build_loadout.gd`、`game/shared/build/build_validation_result.gd`、`game/shared/build/build_validator.gd`（以上新增）、`game/cultivation/data/techniques/*.tres`（新增 3 个）、`test/unit/build_validator_test.gd`（新增）。
- 非范围：功法授予/解锁技能、五行关系、属性要求、技能前置、武器与装备槽、被动效果实际生效、Build 持久化。
- 依赖：`INC-CULT-001`（境界容量表）。
- 检索证据：执行 `git grep -n -E "BuildValidator|TechniqueDefinition|PassiveSkillDefinition"`（无匹配）；`agent-plan/combat.md` 的 `INC-COMBAT-002/003` 只覆盖灵力与单个主动技能，没有容量/冲突规则；`docs/project_summary.md` §六列出“功法冲突 / 属性要求 / 五行 / 灵力消耗 / 技能前置 / Build 容量 / 协同排斥”，本 Increment 只实现容量、重复、互斥与境界门槛四项。
- 风险：错误码与中文文案耦合；后续五行/属性要求可能在同类规则上重复实现；Resource 内数组默认值共享；把“校验”误写成“自动安装/自动禁用”。
- 实现说明：`TechniqueDefinition` / `PassiveSkillDefinition` 只描述静态规则（流派、境界门槛、互斥标签），不授予技能也不结算属性；`BuildLoadout` 只承载数据，容量查询统一走 `realm.get_slot_capacity()`（无境界时容量为 0）；`BuildValidator` 是无副作用静态校验，错误以 `code / kind / entry_id / message` 结构化返回，`get_summary()` 给出 HUD 可直接使用的首条文案。缺少境界时只报一条 `missing_realm` 并跳过容量与门槛判定，避免“无境界 → 全部超容量”的伪错误掩盖真实原因；同一功法重复装备只报 `duplicate_entry`（互斥判定跳过同 id 条目），避免同一问题重复计数。
- 变更文件：`game/shared/resources/technique_definition.gd`、`game/shared/resources/passive_skill_definition.gd`、`game/shared/build/build_loadout.gd`、`game/shared/build/build_validation_result.gd`、`game/shared/build/build_validator.gd`（以上新增，含各自 `.uid`）、`game/cultivation/data/techniques/sword_cultivation.tres`、`thunder_cultivation.tres`、`body_cultivation.tres`（新增）、`test/unit/build_validator_test.gd` 与其 `.uid`（新增，11 例）。
- 测试证据：
  - `-Layer unit`：`FAIL (42 cases, 0 errors, 1 failures)`，其中 `test/unit/build_validator_test.gd` 11 例全部通过，逐条覆盖缺境界、容量超限、同类重复、功法互斥、境界不足、条目未配置与空条目、按类别容量、首条摘要与只读副本语义。
  - `-Layer all`：`[GdUnit4] integration ... PASS (25 cases)`、`[GdUnit4] gameplay ... PASS (16 cases)`；`headless` 9 套 480 项断言（唯一失败项见“已知问题”）。
  - Godot MCP `validate`：5 个新增脚本全部 `valid: true`。
  - `git diff --check` 退出码 0。
- 验证状态：验证通过（本 Increment 范围内）
- 验证时间：2026-09-25T15:56:30+08:00
- 已知问题：与 `INC-CULT-001` 相同的两条外部失败（工作区中 `game/pawns/data/enemy_pawn.tres` 的 `max_health` 80 → 180）在 `-Layer all` 中仍然存在：`test/unit/pawn_data_defaults_test.gd > test_enemy_preset_declares_no_spirit`、`test/headless/hud_spirit_display_test.gd` 的 `HP：80 / 80` 检查。按 `../AGENTS.md` §6 不得为变绿修改断言期望值，需用户裁决后另行处理。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `3351bc1`
- 备注：父 Increment 为 `INC-CROSS-007`；校验器是纯逻辑，不修改 Pawn、灵力、冷却或 UI。
## INC-CULT-003：境界进阶链与突破所需修为

- 状态：accepted
- 创建时间：2026-09-25T16:24:12+08:00
- 最后修改：2026-09-25T16:33:34+08:00
- 主题：cultivation
- 来源：`docs/pawns信息ui.md` Phase 1「显示修为进度与下一境界」与 Phase 3「显示下一境界、突破后容量预览」的数据前置。
- 目标：让境界资源自身声明“下一个境界”和“突破所需修为”，形成炼气→筑基→金丹→元婴→化神可查询的静态进阶链，供运行时进度组件与信息卡读取。
- 验收标准：
  - `RealmDefinition` 新增 `next_realm: RealmDefinition` 与 `breakthrough_exp: float`，提供 `has_next_realm()`、`get_next_realm()`、`get_breakthrough_exp()`，不影响既有 `is_configured()` 与 Build 容量查询。
  - 五个境界资源正确串联：炼气→筑基→金丹→元婴→化神；化神为当前终点，`next_realm == null` 且 `breakthrough_exp == 0`。
  - 非终点境界的本阶段原型突破阈值统一为 `100.0`，该值只是可替换的配置基线，不包含平衡曲线；资源文本可被测试直接审计。
  - 单元用例覆盖：默认值、链式关系、终点语义、阈值非负、容量表不回归。
- 范围：`game/shared/resources/realm_definition.gd`、`game/cultivation/data/realms/*.tres`（5 个）、`test/unit/realm_definition_test.gd`。
- 非范围：境界属性加成、实际突破执行、突破条件（丹药/灵石/任务）、修为获取来源、平衡曲线、存档迁移。
- 依赖：`INC-CULT-001`（境界容量表，实现已在工作区）与 `INC-CULT-002`（Build 校验，实现已在工作区）；本 Increment 只扩展静态资源契约。
- 检索证据：已执行 `git status --short --branch`、`git diff --unified=0 -- agent-plan/`、`git diff --cached --unified=0 -- agent-plan/`、`git log --oneline -- agent-plan/` 与 `git grep -n -E "INC-(CULT|PAWNS|UI|CROSS)-[0-9]{3}" -- agent-plan/`；工作区无暂存变更，`INC-CULT-001/002` 已占用，`INC-CULT-003` 未被占用；允许范围仅限上述境界定义、五个境界资源和对应单元测试。
- 风险：资源间新增引用会改变 `.tres` 加载顺序；必须保持终点无引用，避免循环链；突破阈值是原型占位配置，后续平衡任务可以替换数值但不能改变接口语义。
- 实现说明：`next_realm` 采用显式资源引用而不是按 `tier` 动态搜索，避免运行时扫描资源目录；`breakthrough_exp` 由境界资源唯一持有，运行时进度组件只读该值。所有非终点境界使用统一 `100.0`，在实现说明和测试中明确这是可调的基线配置，而不是最终数值设计。
- 变更文件：`game/shared/resources/realm_definition.gd`、`game/shared/resources/realm_definition.gd.uid`、`game/cultivation/data/realms/qi_refining.tres`、`foundation_establishment.tres`、`golden_core.tres`、`nascent_soul.tres`、`spirit_transformation.tres`（共 5 个）、`test/unit/realm_definition_test.gd` 及其 `.uid`。
- 测试证据：
  - `test/unit/realm_definition_test.gd` 8 例：默认无下一境界、链式顺序与 `tier + 1`、五个境界容量不回归、负阈值/无效引用边界全部通过。
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer unit` → `PASS (62 cases, 0 failures)`；`-Layer all` → `PASS (119 cases, 0 failures)`，统一门禁退出码 0。
  - Godot MCP `validate` `game/shared/resources/realm_definition.gd` → `valid: true`；`git diff --check` 退出码 0。
- 验证状态：验证通过
- 验证时间：2026-09-25T16:33:34+08:00
- 已知问题：非终点境界的突破阈值当前统一为原型基线 `100.0`，不是最终平衡曲线；实际突破执行、条件与奖励仍未实现。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `8e1f0de`
- 备注：父 Increment 为 `INC-CROSS-009`；本 Increment 是 `INC-PAWNS-011` 与 `INC-UI-008` 的静态数据依赖。

## INC-CULT-004：武器槽容量与境界容量表扩展

- 状态：accepted
- 创建时间：2026-09-25T16:38:52+08:00
- 最后修改：2026-09-25T16:45:46+08:00
- 主题：cultivation
- 目标：把“武器”纳入境界容量表，让 Build 容量查询对四类槽位（功法/武器/主动/被动）只有一个来源，为信息卡 Build 区武器槽提供真实上限。
- 验收标准：
  - `RealmDefinition` 新增 `KIND_WEAPON` 常量与 `weapon_slots` 导出字段，`get_slot_capacity(KIND_WEAPON)` 返回该值，`ALL_KINDS` 覆盖四类槽位。
  - 五个境界资源补充 `weapon_slots = 1`；功法/主动/被动容量与 `docs/project_summary.md` §4.1 表格保持不回归。
  - 武器容量不随境界递增（设计文档的突破预览只扩容功法/主动/被动），该结论在数据与测试中固定下来。
  - 单元用例覆盖武器容量、`ALL_KINDS` 完整性、未知类别仍返回 0，以及五个境界的武器槽数值。
- 范围：`game/shared/resources/realm_definition.gd`、`game/cultivation/data/realms/*.tres`（5 个）、`test/unit/realm_definition_test.gd`。
- 非范围：武器定义资源与五行（`INC-INVENTORY-001`）、PawnData 武器字段与校验（`INC-PAWNS-012`）、信息卡显示（`INC-UI-009`）、境界属性加成与突破执行。
- 依赖：`INC-CULT-001`（境界容量表，实现已在工作区）；被 `INC-PAWNS-012` 与 `INC-UI-009` 依赖。
- 检索证据：已执行 `git status --short --branch`、`git diff --unified=0 -- agent-plan/`、`git diff --cached --unified=0 -- agent-plan/`（暂存区为空）、`git log --oneline -- agent-plan/`（已验收基线 `HEAD=3bd28fb`）与 `git grep -n -E "INC-(CULT|PAWNS|UI|INVENTORY|CROSS)-00[0-9]" -- agent-plan/`；`INC-CULT-001`~`003` 已存在且为 `awaiting_acceptance`，`INC-CULT-004` 未被占用；`git grep "weapon" -- game/ test/` 无匹配，说明武器容量是全新类别而不是既有字段改名。允许修改范围仅限上述境界定义、五个境界资源与对应单元测试。
- 风险：`ALL_KINDS` 可能被 HUD / 信息卡遍历消费，新增类别会改变遍历结果；`.tres` 是共享资源，必须一次性补齐五个文件，避免出现容量为 0 的中间态。
- 实现说明：容量仍由 `RealmDefinition` 唯一持有，不新增平行查询入口；`weapon_slots` 默认 1，对应“一名修士同一时间持一把主武器”的 MVP 假设，字段保留为可配置以便后续多武器方案，但本轮不因境界递增。
- 变更文件：
  - `game/shared/resources/realm_definition.gd`
  - `game/cultivation/data/realms/*.tres`（5 个境界资源补 `weapon_slots = 1`）
  - `test/unit/realm_definition_test.gd`
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot $GODOT_PATH -Layer all` → `RESULT: PASS`（GdUnit4 130 例 0 失败：unit 71 / integration 39 / gameplay 20；headless 10 套 549 断言 0 失败），退出码 0。
  - `test/unit/realm_definition_test.gd` 覆盖四类槽位容量、`ALL_KINDS` 完整性、未知类别仍返回 0，以及「武器槽不随境界递增」的固定结论。
  - Godot MCP `validate game/shared/resources/realm_definition.gd` → `valid: true`。
  - 功法/主动/被动容量回归由 unit + integration + gameplay 全层通过确认，未被新增武器槽破坏。
- 验证状态：验证通过
- 验证时间：2026-09-25T16:45:46+08:00
- 已知问题：
  - `weapon_slots` 固定为 1 且不随境界递增；若玩法改为多武器，必须另立 Increment 并同步信息卡行数。
  - `ALL_KINDS` 新增类别会改变遍历消费方结果，本轮已同步信息卡，但后续再新增类别仍需逐个检查消费方。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `c21d8ec`
- 备注：父 Increment 为 `INC-CROSS-010`；本 Increment 只扩展静态容量契约，不改变任何运行时数值。

## INC-CULT-005：突破执行与境界推进

- 状态：accepted
- 创建时间：2026-09-25T20:11:34+08:00
- 最后修改：2026-09-25T20:17:57+08:00
- 主题：修炼
- 目标：让已经达到突破阈值的 `CultivationProgressComponent` 能显式消费 `became_ready`，按 `RealmDefinition.next_realm` 推进到下一境界，并为后续 Pawn / UI / 会话延续提供唯一运行时境界状态源。
- 验收标准：
  - 新增 `advance_realm() -> bool` 与 `realm_advanced(component, previous_realm, new_realm)` 信号。
  - 未就绪、无下一境界、终点境界、未配置境界时返回 `false`，修为、境界、信号全部零副作用。
  - 就绪时把当前修为作为突破消耗，境界切到 `get_next_realm()`，当前修为归零，所需修为切到新境界的 `breakthrough_exp`，且每个成功突破只发一次 `realm_advanced`。
  - `get_snapshot()` 的 `realm` / `realm_id` / `realm_name` / `next_realm_name` / `required_exp` / `ready` 全部反映突破后的状态；`configure()` 仍保持静默。
  - 单元用例覆盖炼气 → 筑基、筑基 → 金丹门槛、终点境界拒绝、未就绪拒绝与“突破消耗而非结转”的语义。
- 范围：`game/shared/core/cultivation_progress_component.gd`、`test/unit/cultivation_progress_component_test.gd`。
- 非范围：Pawn 运行时境界覆盖与信号转发（`INC-PAWNS-019`）、跨遭遇延续（`INC-WORLD-006`）、突破 UI（`INC-UI-017`）、主场景入口（`INC-CORE-011`）、境界属性加成、突破失败率 / 丹药 / 任务前置。
- 依赖：`INC-CULT-003`（境界链与突破阈值，已验收）、`INC-CULT-004`（容量链，已验收）。
- 检索证据：`git status --short` 为空；`git diff --unified=0 -- agent-plan/`、`git diff --cached --unified=0 -- agent-plan/` 均为空；`git log --oneline -- agent-plan/` 最新为 `c22f226`；`git grep -n -E "INC-CULT-005|INC-PAWNS-019|INC-WORLD-006|INC-UI-017|INC-CORE-011|INC-TESTING-010|INC-CROSS-018" -- agent-plan/` 无匹配。`CultivationProgressComponent` 当前只有配置 / 增加 / 设置与只读快照，`became_ready` 没有消费者，因此本 Increment 是突破执行的唯一新增写入者。
- 风险：突破语义若同时承担“重置”和“结转”，会与现有 `set_current_exp()` 的阈值截断规则冲突；本 Increment 明确选择“消耗全部当前修为、下一境界从 0 开始”，不保留溢出。另一个风险是组件直接改 `_realm` 后旧监听方只看 `progress_changed`，所以必须额外发布专用 `realm_advanced` 信号并由 Pawn 转发。
- 实现说明：在 `CultivationProgressComponent` 中新增 `realm_advanced` 信号与 `advance_realm() -> bool`。推进前用 `is_ready_for_breakthrough()` 和 `get_next_realm()` 做无副作用拒绝；成功后消费当前全部修为，把境界切到下一境界、`required_exp` 切到新境界的 `breakthrough_exp`、当前修为归零并清除 ready 缓存，然后依次发布 `progress_changed(delta = -consumed_exp, source = &"breakthrough")` 与 `realm_advanced(previous_realm, new_realm)`。本 Increment 固定采用“突破消耗当前全部修为、不结转溢出”的语义。
- 变更文件：`game/shared/core/cultivation_progress_component.gd`、`test/unit/cultivation_progress_component_test.gd`。
- 测试证据：2026-09-25T20:15:50+08:00 执行 `godot --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/unit/cultivation_progress_component_test.gd -rd res://reports/inc_cult_005 --ignoreHeadlessMode`，GdUnit4 报告 `7 test cases | 0 errors | 0 failures | 0 orphans`，`Exit code: 0`；MCP `validate` 对组件脚本返回 `valid: true`。用例覆盖炼气到筑基、筑基到金丹、未就绪、终点境界与无下一境界零副作用。
- 验证状态：验证通过
- 验证时间：2026-09-25T20:15:50+08:00
- 已知问题：突破失败率、丹药、渡劫表现和境界属性加成不在本 Increment；当前 API 只负责原子推进，不负责表现层。
- 用户验收：已验收（依据用户 2026-09-25 指令「验收通过，分increment提交」与「分批increment单独推送后继续开发」；验证通过后按该授权进入 Git）
- 验收时间：2026-09-25T20:16:30+08:00
- Git：`main` / `d9213d2`
- 备注：父 Increment 为 `INC-CROSS-018`；这是「突破 → Build 重构」的第一个运行时前置。
