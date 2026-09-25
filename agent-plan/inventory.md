# Inventory 主题计划（装备 / 物品 / 背包 / 炼丹 / 炼器）

> 最后修改：2026-09-25T16:50:57+08:00
> 主题：inventory
> 规则来源：`../AGENTS.md`

## INC-INVENTORY-001：武器定义与五行属性表

- 状态：accepted
- 创建时间：2026-09-25T16:38:52+08:00
- 最后修改：2026-09-25T16:45:46+08:00
- 主题：inventory
- 目标：把 `docs/project_summary.md` §五 Build 分层中的“武器”落成可复用的静态资源，作为信息卡 Build 区武器槽与后续装备流程的唯一数据来源。
- 验收标准：
  - 新增 `WeaponDefinition`（`id` / `display_name` / `weapon_type` / `element` / `required_realm_tier` / `description`），提供 `is_configured()`、`has_element()`、`get_element_label()`、`get_type_label()` 与静态 `element_label(element)`；未知或空五行返回占位文案，不返回空串。
  - 五行取值固定为 `metal` / `wood` / `water` / `fire` / `earth`，标签为 金 / 木 / 水 / 火 / 土，`ALL_ELEMENTS` 作为唯一顺序来源；武器类型标签覆盖 `sword`（剑）、`artifact`（法器）、`blade`（刀），未知类型回退为原值或占位。
  - 落盘两件武器数据：`qingfeng_sword.tres`（青锋剑 · 剑 · 金 · 炼气可用，供玩家预设装备）与 `chiyan_sword.tres`（赤炎剑 · 法器 · 火 · 炼气可用，供后续装备切换使用）。
  - 新增单元用例覆盖默认值、五行与类型标签映射、未知/空五行边界，以及两份数据资源的真实字段。
- 范围：`game/shared/resources/weapon_definition.gd`（新增）、`game/inventory/data/weapons/*.tres`（新增）、`test/unit/weapon_definition_test.gd`（新增）。
- 非范围：装备槽更换与卸下交互、武器数值与战斗结算、武器图标美术、掉落与背包容量、存档字段、五行与灵根相容校验。
- 依赖：无（纯静态资源与纯逻辑）；被 `INC-PAWNS-012` 与 `INC-UI-009` 依赖。
- 检索证据：已执行 `git status --short --branch`（`main...origin/main [ahead 1]`，工作区含 `INC-CROSS-003`~`INC-CROSS-009` 未提交变更，暂存区为空）、`git diff --unified=0 -- agent-plan/`（新增父级与主题条目均为 CROSS-003~009）、`git diff --cached --unified=0 -- agent-plan/`（空）、`git log --oneline -- agent-plan/`（已验收基线 `HEAD=3bd28fb`）、`git grep -n -E "INC-(CULT|PAWNS|UI|INVENTORY|CROSS)-00[0-9]" -- agent-plan/`（无 `INC-INVENTORY-*` / `INC-CROSS-010` / `INC-CULT-004` / `INC-PAWNS-012` / `INC-UI-009`）与 `git grep -n "WeaponDefinition\|weapon" -- game/ test/`（无匹配）。结论：武器层在代码中完全缺失，`INC-INVENTORY-001` 未被占用；本 Increment 的允许范围仅限上述武器定义、两份武器数据与对应单元测试。
- 风险：新增 `game/inventory/` 目录需要与主题文件一一对应；五行是显示层标签，必须与功法 `school`（剑/雷/体/阵/魂）区分，避免两套流派标签混用；武器资源后续若接入战斗数值，需要另立 Increment 并保持 `required_realm_tier` 语义不变。
- 实现说明：五行只保存 `StringName` 标识，标签由静态映射派生，避免在数据资源里重复维护中文；`required_realm_tier` 复用功法/被动的门槛语义（1 = 炼气可用），由 `BuildValidator` 统一判定；两份武器数据中的“青锋剑”按玩家预设的金灵根/剑修流派选择，“赤炎剑”来自 `docs/pawns信息ui.md` Phase 1 布局示例，用于后续切换装备测试。
- 变更文件：
  - `game/shared/resources/weapon_definition.gd`（新增，含 `.uid`）
  - `game/inventory/data/weapons/qingfeng_sword.tres`（新增）
  - `game/inventory/data/weapons/chiyan_sword.tres`（新增）
  - `test/unit/weapon_definition_test.gd`（新增）
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot $GODOT_PATH -Layer all` → `RESULT: PASS`（GdUnit4 130 例 0 失败：unit 71 / integration 39 / gameplay 20；headless 10 套 549 断言 0 失败），退出码 0。
  - `test/unit/weapon_definition_test.gd` 5 例随 unit 层全通过：默认值、五行与类型标签映射、未知/空五行回退占位，以及两份 `.tres` 的真实字段（含 `青锋剑（剑 · 金）` 组合）。
  - Godot MCP `validate`：`game/shared/resources/weapon_definition.gd`、`game/inventory/data/weapons/qingfeng_sword.tres`、`game/inventory/data/weapons/chiyan_sword.tres` 全部 `valid: true`。
  - `<godot> --headless --editor --path . --quit` → 退出码 0（全局类注册成功并生成 `weapon_definition.gd.uid`）。
- 验证状态：验证通过
- 验证时间：2026-09-25T16:45:46+08:00
- 已知问题：
  - 武器目前只是静态数据：不参与战斗结算、不提供数值加成、无图标美术。
  - 五行只是显示层标签，不参与任何相容/克制校验。
  - 没有装备槽更换、卸下、掉落与背包容量逻辑；`赤炎剑` 暂无引用入口，仅为后续切换测试预留。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `c21d8ec`
- 备注：父 Increment 为 `INC-CROSS-010`；本 Increment 只建立武器静态数据契约，不实现装备流程与战斗效果。