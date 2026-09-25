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
- Git：
- 备注：父 Increment 为 `INC-CROSS-017`。

