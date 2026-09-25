# Agent Plan Index

> 最后修改：2026-09-25T16:51:32+08:00
> 规则来源：`../AGENTS.md`

## 主题索引

| 主题 | 计划文件 | 状态 | 当前 Increment | 最后修改 |
|---|---|---|---|---|
| UI | `ui.md` | 已验收 | `INC-UI-009` | 2026-09-25T16:51:32+08:00 |
| 战斗 | `combat.md` | 已验收 | `INC-COMBAT-003` | 2026-09-25T16:51:32+08:00 |
| Pawns | `pawns.md` | 已验收 | `INC-PAWNS-012` | 2026-09-25T16:51:32+08:00 |
| 修炼 | `cultivation.md` | 已验收 | `INC-CULT-004` | 2026-09-25T16:51:32+08:00 |
| 宗门 | `sect.md` | 未创建 | - | - |
| 世界 | `world.md` | 未创建 | - | - |
| 背包 | `inventory.md` | 已验收 | `INC-INVENTORY-001` | 2026-09-25T16:51:32+08:00 |
| 存档 | `save.md` | 未创建 | - | - |
| 音频 | `audio.md` | 未创建 | - | - |
| 核心 | `core.md` | 已验收 | `INC-CORE-004` | 2026-09-25T16:51:32+08:00 |
| 工具 | `tools.md` | 已验收 | `INC-TOOLS-002` | 2026-09-25T13:54:46+08:00 |
| 测试 | `testing.md` | 已验收 | `INC-TESTING-002` | 2026-09-25T16:51:32+08:00 |

## 跨主题父 Increment

| ID | 状态 | 子 Increment | 目标 | 验证 | 验收 | 最后修改 |
|---|---|---|---|---|---|---|
| `INC-CROSS-001` | `accepted` | `INC-PAWNS-001`、`INC-COMBAT-001`、`INC-UI-001`、`INC-CORE-001` | 完成第一个可操作 Pawn MVP | 通过 | 已验收 | 2026-09-25T13:44:10+08:00 |
| `INC-CROSS-002` | `accepted` | `INC-UI-002`、`INC-PAWNS-002` | 血条按生命状态变化显示、2 秒无变化后隐藏 | 通过 | 已验收 | 2026-09-25T14:09:53+08:00 |
| `INC-CROSS-003` | `accepted` | `INC-CORE-002`、`INC-UI-003`、`INC-PAWNS-004`、`INC-COMBAT-002` | 通用资源池与多资源条抽象，覆盖生命、护盾、灵力 | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-004` | `accepted` | `INC-PAWNS-005`、`INC-UI-004` | 将通用资源条接入 Pawn 实战头顶 UI，并在 HUD 显示灵力 | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-005` | `accepted` | `INC-TESTING-001` | 建立可回归的自动化测试框架（GdUnit4 三层 + headless 回归） | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-006` | `accepted` | `INC-PAWNS-007`、`INC-CORE-003`、`INC-UI-005` | 玩家主动技能操作闭环：Q 输入、接近施法与 HUD 技能状态 | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-007` | `accepted` | `INC-CULT-001`、`INC-CULT-002`、`INC-PAWNS-008`、`INC-UI-006` | 境界容量与 Build 校验：五个境界容量表、功法互斥/门槛校验与 HUD Build 行 | 通过（子项范围内，统一门禁存在外部阻塞） | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-008` | `accepted` | `INC-PAWNS-009`、`INC-PAWNS-010`、`INC-UI-007`、`INC-CORE-004` | Pawn 信息卡 MVP：数据契约、身份/资源/属性/Build 只读面板与主场景路由 | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-009` | `accepted` | `INC-CULT-003`、`INC-PAWNS-011`、`INC-UI-008` | 修为进度与下一境界：境界进阶链、运行时修为组件与信息卡展示 | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |
| `INC-CROSS-010` | `accepted` | `INC-INVENTORY-001`、`INC-CULT-004`、`INC-PAWNS-012`、`INC-UI-009` | Build 信息卡与武器槽（Phase 2 第一步）：武器静态定义与五行、武器槽容量、PawnData 武器字段与校验、信息卡四类槽位显示 | 通过 | 已验收 | 2026-09-25T16:51:32+08:00 |

### INC-CROSS-001：第一个 Pawn MVP

- 创建时间：2026-09-25T13:21:58+08:00
- 目标：在 Godot 中验证可控制、可战斗、可暂停的基础单位。
- 验收标准与证据：
  - 场景中存在玩家 Pawn 和敌方 Pawn：主场景实例化 `player_pawn.tscn` 与 `enemy_pawn.tscn`。
  - 玩家可选中 Player Pawn：左键后 `SelectionIndicator.visible = true`，HUD 显示玩家属性。
  - 玩家 Pawn 可右键移动到地面目标：HUD 指令变化后玩家位置从 `(870,410)` 移动到 `(669.58,401.94)` 等目标附近。
  - 玩家 Pawn 可右键敌方目标，自动接近并攻击：HUD 显示 `指令：攻击 试炼傀儡`，敌人生命/护盾持续下降。
  - 敌方 AI Pawn 可以移动和攻击玩家：敌人位置自主变化，玩家护盾从 40 降到 0、生命继续下降。
  - HP/护盾能够下降，HP=0 后 Pawn 死亡：敌人从 100 总有效生命（80 生命 + 20 护盾）降到 0，状态为 `DEAD`；玩家在敌人攻击期间生命从 120 降到 104。
  - Space 暂停后所有 Pawn 完全停止，恢复后继续运行：玩家和敌人的位置、生命在暂停 1 秒期间完全不变；恢复后位置继续变化。
  - 复验（本轮复跑）：select、move、attack、damage、death、pause 六条交互路径由 MCP simulate_input 重新实测通过，运行日志 errors 为空，截图与证据记录一致。
- 非范围：完整修士系统、4v4 战斗、技能、功法、境界、装备、秘境、宗门和正式美术。
- 证据要求：脚本/场景静态验证结果、运行日志、选中/移动/攻击/死亡/暂停状态读取、MCP 冒烟测试。
- 验证结论：上述子 Increment 均已通过验证，并已通过用户验收。
- 验收时间：2026-09-25T13:42:33+08:00
- 备注：父 Increment 只有在子 Increment 验证通过且用户明确验收后才能进入 `accepted`；验收前不创建 Git commit。

### INC-CROSS-002：血条按生命状态变化显示

- 创建时间：2026-09-25T13:54:57+08:00
- 来源：`docs/血条ui需求.txt`（用户提供的血条 UI 需求为“Pawn 头顶血条 + 状态变化触发显示 + 短暂延迟后隐藏”）。
- 目标：把 Pawn 头顶血条从常驻显示改为“生命状态变化时显示、最后一次变化后 2 秒隐藏”，降低战场视觉噪音。
- 子 Increment：`INC-UI-002`（血条显示策略与独立场景）、`INC-PAWNS-002`（生命状态变化统一入口与挂载结构）。
- 验收标准与证据：
  - 初始隐藏、变化同帧显示、2 秒无变化隐藏、连续变化重置计时、护盾与死亡同样触发：由 `test/headless/health_bar_visibility_test.gd` 的 headless 断言与运行态计时证据共同支撑。
  - 结构与挂载：`Pawn/HealthBarAnchor/HealthBar` 节点路径、实例场景加载、信号连接必须通过静态验证。
  - 需要截图或运行态读取记录血条出现与消失的实际表现。
- 非范围：渐隐动画（需求文档第二阶段）、治疗/护盾技能、分层生命（护体灵力/真元/气血/元神）、HealthComponent 抽取（`INC-PAWNS-003`）。
- 验证结论：`INC-UI-002` 与 `INC-PAWNS-002` 均已验证通过：headless 38 项断言全通过（`CHECKS=38 FAILURES=0`）；运行态隐藏耗时 1964ms、暂停中保持可见、恢复后 2035ms 隐藏；16:9（1152x648）/ 16:10（1152x720）/ 窄屏（800x720 → 逻辑视口 1152x1036）三档真实渲染截图的像素核验与布局读取一致。用户已于 2026-09-25 验收通过。
- 验收时间：2026-09-25T14:09:53+08:00
- 备注：已按 Acceptance/Git Gate 在用户验收通过后提交到 `main`（hash 见下方 Git 记录）；`docs/血条ui需求.txt` 作为计划输入已于 `761e15b` 入库。

### INC-CROSS-003：通用资源池与多资源条抽象

- 状态：accepted
- 创建时间：2026-09-25T14:31:51+08:00
- 最后修改：2026-09-25T15:06:40+08:00
- 来源：用户提出的 `resourceComponent` 设想，以及 `docs/project_summary.md` 中生命、护盾、灵力与分层生命规划。
- 目标：把“单个数值池的增减”和“条状显示与延迟追赶”拆成可组合基础能力，使生命、护盾和灵力共用实现，同时保持战斗规则、显示策略和 Godot Resource 静态数据职责分离。
- 子 Increment：`INC-CORE-002`（资源池与集合基础）、`INC-UI-003`（通用 ResourceBar 与多资源条）、`INC-PAWNS-004`（生命/护盾兼容迁移）、`INC-COMBAT-002`（灵力资源与原子消耗）。
- 核心架构决策：
  - 不采用“一个万能 ResourceComponent 同时管理生命、护盾、灵力、业务规则和 UI”的方案。
  - 数据层采用 `ResourcePoolDefinition extends Resource`、`ResourcePoolComponent extends Node`、`ResourceSetComponent extends Node` 的组合。
  - 表现层采用 `ResourceBar extends Control` 与 `PawnStatusBars` 容器；真实数值立即变化，延迟减少只是显示层效果。
  - 护盾优先吸收、生命归零死亡、灵力不能透支等规则由 Pawn、战斗路由器或资源定义处理，不进入基础池。
  - HealthComponent 在迁移期作为兼容门面保留，禁止继续扩张为多资源万能组件；后续退役需另立 Increment。
- 验收标准与证据：
  - `INC-CORE-002` 的通用池断言通过，证明单个资源可以独立增减、原子消耗、归零和恢复。
  - `INC-UI-003` 证明单个 ResourceBar 可绑定通用池，延迟减少不修改真实数值，组级显隐不会因多资源计时冲突。
  - `INC-PAWNS-004` 证明生命/护盾迁移不改变已验收的 Pawn 信号、血条行为和战斗结果。
  - `INC-COMBAT-002` 证明灵力作为第二个生产级资源可以复用同一套池和条组件。
  - 全部子 Increment 验证通过、运行态冒烟通过、多分辨率无 UI 越界后，才允许请求用户验收。
- 非范围：完整技能系统、功法、五行、分层生命（护体灵力/真元/气血/元神）、状态异常、存档格式迁移、正式美术、网络同步和战斗平衡。
- 验证结论：四个子 Increment 全部验证通过：`INC-CORE-002` 102/0（通用资源池、原子消耗、归零/恢复边沿）、`INC-UI-003` 86/0 + 16:9/16:10/窄屏三档真实渲染无重叠越界、`INC-PAWNS-004` 49/0（生命/护盾迁移到资源池且对外契约不变）、`INC-COMBAT-002` 63/0（灵力作为第二个生产级资源与非死亡资源）。合计 393 项断言全部通过；运行态冒烟覆盖伤害路由、AI 实弹链路、灵力原子消耗与通用资源条绑定，运行日志 errors 为空。等待用户验收后再进入 Git 稳定版本。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `f6cdebf`
- 备注：父 Increment 只有全部子 Increment 验证通过且用户明确验收后，才能进入 `accepted` 并提交稳定版本；在此之前禁止把计划状态描述为已实现。


### INC-CROSS-004：通用资源条接入 Pawn 实战 UI 与灵力 HUD

- 状态：accepted
- 创建时间：2026-09-25T15:09:23+08:00
- 最后修改：2026-09-25T15:14:42+08:00
- 来源：`INC-PAWNS-004` 与 `INC-COMBAT-002` 的已知问题：`PawnStatusBars` 尚未接入 Pawn，HUD 尚未显示灵力。
- 目标：完成通用资源池抽象的生产接入闭环，让生命、护盾、灵力的真实数值变化直接驱动 Pawn 头顶资源条；选中 HUD 能读取并显示灵力。
- 子 Increment：`INC-PAWNS-005`（Pawn 头顶资源条接入）、`INC-UI-004`（HUD 灵力显示）。
- 核心架构决策：
  - Pawn 只负责装配资源池与资源条，不复制数值、不解释 UI 颜色或动画。
  - 灵力条继续只在 `max_spirit > 0` 时存在；无灵力单位既没有池，也没有可显示的条。
  - 旧的 `PawnHealthBar` 暂时保留为兼容组件，但不再是 Pawn 的实战节点；退役另立 Increment。
- 验收标准与证据：
  - Pawn 实战场景包含 `HealthBarAnchor/StatusBars`，生命/护盾/灵力绑定到正确资源池。
  - 资源变化触发同帧显示，最后一次变化后 2 秒隐藏；暂停冻结隐藏计时。
  - HUD 在选中玩家 Pawn 时显示灵力行，无灵力单位不显示；灵力变化能刷新 HUD。
  - headless 断言、真实窗口运行态截图和 `git diff --check` 全部通过。
- 非范围：技能系统、灵力恢复规则、正式美术、Old `PawnHealthBar` 的删除退役、网络同步和存档格式。
- 验证结论：`INC-PAWNS-005` 37/0（玩家三资源池与敌人双资源池绑定、组级显隐、UI 不回写、运行态 2 秒隐藏），`INC-UI-004` 8/0（有灵力玩家显示、消耗即时刷新、无灵力敌人不显示、取消选中恢复）；8 个 headless 套件合计 447 项断言全部通过。真实窗口 1152x648 / 1152x720 / 800x720 下资源条矩形均为 (830,320,80,52)，三子条不重叠、居中于 Pawn 头顶且在视口内；HUD SelectedLabel 也位于视口内。MCP 运行时日志 errors 为空。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `6df4fbb`
- 备注：本父级依赖 `INC-CROSS-003` 的四个子 Increment；在 `INC-CROSS-003` 用户验收前，所有实现只能停留在工作区，不得提交稳定版本。

### INC-CROSS-005：建立可回归的自动化测试框架

- 创建时间：2026-09-25T15:23:00+08:00
- 目标：为项目建立可命令行一键运行、按层组织、可接入 CI 的自动化测试能力，使每个后续 Increment 在请求验收前都能产出可复现的回归证据，而不是依赖一次性人工冒烟。
- 子 Increment：`INC-TESTING-001`（GdUnit4 选型与三层测试框架）。
- 验收标准与证据：
  - 测试框架选型唯一，GdUnit4 / GUT / 自建 headless 的取舍有实证支撑，记录在 `agent-plan/testing.md`。
  - 一条命令跑完全部测试层级，退出码 0 表示全通过、非 0 表示存在失败。
  - 三层职责固定且各有真实用例：`test/unit`（纯逻辑）、`test/integration`（系统组合）、`test/gameplay`（场景与玩法）。
  - 既有 `test/headless` 套件保持可运行，断言总数不低于基线，不因引入框架而降低回归强度。
  - 报告为可重建产物（JUnit XML / HTML），不入库；文档不写入 Godot 本机绝对路径。
- 非范围：把既有 headless 套件改写为 GdUnit4 风格、修改 `game/` 业务代码、CI 平台接入（GitHub Actions 等，留待后续 Increment）。
- 验证结论：`INC-TESTING-001` 三层共 34 个 GdUnit4 用例、9 个 headless 套件 480 项断言全部通过，统一入口退出码 0。
- 验收时间：2026-09-25T16:52:24+08:00
- Git：`main` / `b11c9b0`
- 备注：本父级只建立测试基础设施与用例骨架；测试过程中发现的业务缺陷另立对应主题 Increment，不在本父级内顺手修复。

### INC-CROSS-006：玩家主动技能操作闭环

- 状态：accepted
- 创建时间：2026-09-25T15:38:42+08:00
- 最后修改：2026-09-25T15:44:38+08:00
- 来源：`INC-COMBAT-003` 已提供主动技能执行契约，但正式场景没有玩家施放入口；`docs/project_summary.md` MVP Top 5 ② 要求技能进入战斗框架。
- 目标：让玩家在暂停 RTS 中通过 Q 对当前攻击目标下达一次主动技能命令，自动接近施法距离并施放；HUD 同步显示技能名称、消耗、冷却和可用状态。
- 子 Increment：`INC-PAWNS-007`（玩家技能命令与接近逻辑）、`INC-CORE-003`（Q 输入映射与主场景路由）、`INC-UI-005`（HUD 技能状态）。
- 实施顺序：`INC-PAWNS-007` → `INC-CORE-003` → `INC-UI-005`；`game/main/main.gd` / `main.tscn` 由后两个子 Increment 串行修改，不并行写入。
- 验收标准与证据：
  - `cast_skill` 输入动作存在，Q 键在玩家 Pawn 被选中且有有效敌方目标时触发技能命令；无选中、无目标、目标死亡或非敌方目标时不产生副作用。
  - `PlayerController` 在目标超出技能距离时先移动，进入距离后施放一次；成功路径与 `Pawn.cast_skill()` 的灵力、伤害、冷却契约一致。
  - HUD 显示当前选中 Pawn 的技能名、灵力消耗、剩余冷却和可用/不可用原因；灵力变化、技能冷却变化与施法成功后即时刷新。
  - 现有选中、移动、普通攻击、AI、资源条、暂停和既有 44 个 GdUnit4 用例（本父级完成后扩展为 58 个）继续通过。
  - 证据需包含 GdUnit4 集成/玩法用例、MCP 或 CLI 编辑器校验、统一 runner 退出码 0 与 `git diff --check`。
- 非范围：技能栏鼠标点击、多个技能槽、技能装配/卸载、目标选择新 UI、功法/Build、4v4、范围伤害、五行、暴击、状态异常、正式动画与特效。
- 依赖：`INC-COMBAT-003` 的 `ActiveSkillDefinition` / `Pawn.can_cast_skill()` / `Pawn.cast_skill()`；该 Increment 已随本批次验收通过。
- 风险：暂停状态下的输入投递时机；技能命令与普通攻击/移动命令互相覆盖；冷却或灵力不足时命令是否保留；HUD 文案随选中目标切换产生陈旧状态。
- 验证结论：`INC-PAWNS-007` / `INC-CORE-003` / `INC-UI-005` 均已实现并通过验证：GdUnit4 用例 44 → 58（新增 integration 7 例、gameplay 7 例），9 个 headless 套件 480 项断言保持通过，统一 runner `RESULT: PASS`、退出码 0；MCP `validate` 脚本全部 `valid: true`，`--headless --editor --quit` 与 `--headless --quit-after 120` 退出码 0，`git diff --check` 退出码 0；MCP 运行态端到端复验（选中玩家 → 右键敌人 → 按 Q）确认指令由 `攻击 试炼傀儡` 变为 `施放技能 御剑斩 → 试炼傀儡`，灵力 100 → 75、敌人护盾 20 → 0 且生命 80 → 52.6，HUD 冷却由 2.5s 递减，运行日志 errors 为空。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `5f39e5f`
- 备注：本父级只实现玩家单技能操作闭环，不改变 `INC-COMBAT-003` 的静态技能契约。

### INC-CROSS-007：境界容量与 Build 校验（MVP ③）

- 状态：accepted
- 创建时间：2026-09-25T15:48:32+08:00
- 最后修改：2026-09-25T15:56:30+08:00
- 来源：`docs/project_summary.md` §4.1（境界改变 Build 容量）、§六（功法冲突 / 属性要求 / 五行 / 灵力消耗 / 技能前置 / Build 容量）与 MVP 实现优先级 ③“Build 容量/冲突系统”；`INC-CROSS-006` 已提供玩家单主动技能闭环，但没有任何境界、功法或容量概念。
- 目标：建立“境界 → Build 容量”的数据契约与功法互斥/境界门槛校验，并让选中单位的当前 Build 在 HUD 可读。
- 子 Increment：`INC-CULT-001`（境界定义与容量表）、`INC-CULT-002`（功法/被动定义与 Build 校验器）、`INC-PAWNS-008`（Pawn 境界与 Build 汇总接口）、`INC-UI-006`（HUD 境界与 Build 容量行）。
- 实施顺序：`INC-CULT-001` → `INC-CULT-002` → `INC-PAWNS-008` → `INC-UI-006`；`game/main/main.gd` 与 `main.tscn` 只在最后一个子 Increment 写入。
- 验收标准与证据：
  - 炼气/筑基/金丹/元婴/化神 的功法、主动、被动容量与设计文档一致，且由 `RealmDefinition.get_slot_capacity()` 单一来源提供。
  - Build 校验覆盖缺境界、容量超限、同类重复、功法互斥、境界不足、条目未配置，并返回结构化错误码与可直接展示的文案。
  - 正式玩家预设（炼气 + 剑修 + 御剑斩）汇总为 功法 1/1、主动 1/2、被动 0/1 且校验通过；试炼傀儡无境界时不报错、战斗行为不变。
  - HUD 显示境界与三类容量占用，Build 不可用时显示首条原因。
  - 证据需包含新增 GdUnit4 用例、`test/run_tests.ps1 -Layer all` 退出码 0、`git diff --check` 与 MCP/CLI 校验结果。
- 非范围：突破流程、境界属性加成、五行关系、属性要求、技能前置、功法授予技能、武器/装备槽、Build 编辑界面、秘境与宗门。
- 依赖：`INC-CROSS-006` 的 `ActiveSkillDefinition` / `Pawn` 技能契约（已验收）；`INC-TESTING-001` 的统一测试入口。
- 风险：境界/功法数据与设计文档漂移；把容量校验实现成自动卸载技能；HUD 行数继续增加造成布局拥挤；`PawnData` 新增导出字段影响既有 `.tres` 加载。
- 验证结论：四个子 Increment 均已实现并通过本层验证：`INC-CULT-001` 5 例、`INC-CULT-002` 11 例、`INC-PAWNS-008` 4 例、`INC-UI-006` 4 例；GdUnit4 用例由 58 增至 83（unit 42 / integration 25 / gameplay 16），9 个 headless 套件保持 480 项断言。MCP `validate` 14 个目标全部 `valid: true`；MCP 运行态复验确认 HUD Build 行三态（`Build：-` → `境界：炼气    功法 1 / 1    主动 1 / 2    被动 0 / 1` → `境界：无    Build：不适用`）、玩家 Build 校验通过且 `error_codes = []`、试炼傀儡只报 `missing_realm`、`HudMargin.offset_bottom = 222`，Build 行在 1152x648 / 1152x720 / 1152x1036 三档逻辑视口内、与技能行间距 6px 且不与暂停状态标签重叠，运行日志 `errors` 为空；`git diff --check` 退出码 0。
- 已知问题（阻塞统一门禁）：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 当前退出码 1，两条失败均来自与本父级无关、且本父级未触碰的工作区外部改动 `game/pawns/data/enemy_pawn.tres`（`max_health` 由 80.0 改为 180.0，同时携带编辑器写入的 `uid` 与 `Color` 规范化，文件 mtime 早于本父级实现）：(1) `res://test/unit/pawn_data_defaults_test.gd > test_enemy_preset_declares_no_spirit` → `Expecting: 80.000000`；(2) `res://test/headless/hud_spirit_display_test.gd` → `FAILED: 敌人仍应显示自身生命行`（断言 `HP：80 / 80`）。按 `../AGENTS.md` §6 没有为了变绿修改既有断言期望值，需要用户裁决后另行处理：回退为 80，或把该数值改动登记为独立 Increment 并同步更新这两处基线断言。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `3351bc1`
- 备注：本父级只覆盖 MVP ③ 的“容量与冲突”最小闭环；境界属性加成与突破属于后续父 Increment。

### INC-CROSS-008：Pawn 信息卡 MVP（Phase 0 + Phase 1 数据可行部分）

- 状态：accepted
- 创建时间：2026-09-25T16:04:30+08:00
- 最后修改：2026-09-25T16:19:12+08:00
- 来源：`docs/pawns信息ui.md`（用户提供的“Pawns 信息卡分阶段需求设计文档”，Phase 0 数据契约与 UI 骨架、Phase 1 MVP 最小信息卡），以及 `docs/project_summary.md` §十八 MVP Top 5 ①（角色 + 境界）。
- 目标：把“我是谁、我是什么境界、我带了什么 Build、我下一步怎么成长”做成真实数据驱动的信息卡入口，先跑通 `Pawn → PawnData → PawnInfoPanel`，再补修为进度与 Build 槽位交互。
- 子 Increment：`INC-PAWNS-009`（同步敌人预设 180 生命的数据基线，解除统一门禁阻塞）、`INC-PAWNS-010`（`PawnData` 身份字段与视图信号）、`INC-UI-007`（`PawnInfoModel` + `PawnInfoPanel` 骨架与绑定）、`INC-CORE-004`（主场景选中/暂停路由）。
- 实施顺序：`INC-PAWNS-010` → `INC-UI-007` → `INC-CORE-004`；`game/main/main.gd` 与 `main.tscn` 只在最后一个子 Increment 中修改，避免与 `INC-UI-006` 的场景改动交叉。
- 关键架构决策：
  - 面板绑定 `Pawn` 而不是仅绑定 `PawnData`：运行时数值（生命/护盾/灵力）按既有架构只存在于 `Pawn/Resources/*` 的 `ResourcePoolComponent`，`PawnData` 保持纯静态配置；UI 不写回、不在 Pawn 上挂 UI 字段。
  - 读模型与渲染分离：`PawnInfoModel` 是纯函数读模型（静态取自 `PawnData`、运行时由调用方传入），可在单元层验证派生文案；`PawnInfoPanel` 只负责绑定信号与渲染。
  - 资源区复用 `INC-UI-003` 的 `ResourceBar`，不新建第二套条组件。
  - Build 标签由功法流派与主动技能派生，不新增与 Build 数据重复的字段。
- 验收标准（本父级）：
  - 选中玩家 Pawn 时信息卡显示真实姓名、境界、灵根、Build 标签、三层资源、核心属性与 Build 容量摘要；未配置字段显示 `—`，不出现假数据。
  - 生命/护盾/灵力变化与静态数据变更都能事件驱动刷新面板；解除绑定后旧单位信号不再影响面板。
  - 暂停时显示完整信息卡，战斗中显示精简信息卡；面板在 16:9（1152x648）、16:10（1152x720）与窄屏（800x720 → 逻辑视口 1152x1036）三档下均不与顶部 HUD、右上暂停标签重叠且不越出视口（顶部 HUD 实测下沿 y=262）。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all` 退出码 0。
- 非范围：法强/暴击等当前无数据来源的属性、修为进度与突破条件（Phase 3）、Build 槽位点击更换与容量预览（Phase 2）、敌人/中立 Pawn 点击查看（Phase 4）、状态图标/装备详情/人物关系/宗门贡献/立绘、存档格式变更。
- 依赖：`INC-PAWNS-008`、`INC-UI-006`、`INC-UI-003`、`INC-CROSS-004` 的实现均已在工作区（本批次已验收）；`INC-PAWNS-009` 用于把外部数据改动登记为基线并解除统一门禁阻塞。
- 风险：信息卡与既有顶部 HUD 在窄屏下重叠；重复实现 Build 文案导致与 HUD 漂移；`unbind()` 后残留信号连接；运行中的 Godot 编辑器可能用旧场景覆盖 `main.tscn`。
- 验证结论：4 个子 Increment 全部 `验证通过`。`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`，退出码 0（GdUnit4 105 例：unit 52 / integration 33 / gameplay 20；headless 10 套 541 项断言 0 失败）。真实窗口取证（`test/tools/capture_pawn_info_panel_evidence.gd`）三档窗口 × 精简/暂停两种模式全部 `BOUNDS_INSIDE_VIEWPORT=true`、`HUD_OVERLAP=false`、`PAUSE_LABEL_OVERLAP=false`、`CONTENT_FITS=true`，暂停遮罩 `DRAWN_ABOVE_PANEL=true`。
- 关键发现（父级）：顶部 HUD 的真实高度由内容撑到 246px（下沿 y=262），并非 `main.tscn` 里 `HudMargin.offset_bottom = 222` 所暗示的 206px；面板原始高度 384 会在 1152x648 下与 HUD 重叠 14px。该问题只在真实窗口渲染下暴露（`--headless` 的 dummy 视口固定 64x64），已按实测把面板高度改为 354。
- 已知问题：
  - **编辑器覆盖风险未解除**：Godot 编辑器 PID 11224 全程持有本项目，`main.tscn` 是直接写入磁盘的；需在编辑器执行 Project → Reload Current Project 或关闭编辑器后再操作场景。
  - 编辑器持续占用 CPU（采样约 30% 单核）导致两套墙钟计时断言假失败，已另立 `INC-TESTING-002` 修复测试测量口径。
  - 顶部 HUD 高度是内容驱动的；后续 HUD 增删行需要重新实测信息卡避让间距。
  - Phase 2/3/4（Build 槽位交互、修为进度与突破、敌人/中立查看、状态图标与立绘）不在本父级范围。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `78ecb97`
- 备注：父 Increment 只有在子 Increment 验证通过且用户明确验收后才能进入 `accepted`；验收前不创建 Git commit。本父级不覆盖 Phase 2/3/4。
### INC-CROSS-009：修为进度与下一境界

- 状态：accepted
- 创建时间：2026-09-25T16:24:12+08:00
- 最后修改：2026-09-25T16:33:34+08:00
- 来源：`docs/pawns信息ui.md` Phase 1 的“修为进度与下一境界”要求，以及 Phase 3 对下一境界和突破预览的数据前置。
- 目标：在不实现实际突破流程的前提下，把“当前修为 / 突破所需修为 / 下一境界 / 是否达到阈值”做成真实数据链路，并显示在 Pawn 信息卡完整模式中；战斗中精简模式仍只显示身份与资源。
- 子 Increment：`INC-CULT-003`（境界进阶链与突破所需修为）、`INC-PAWNS-011`（运行时修为组件与 Pawn 接口）、`INC-UI-008`（信息卡修为进度显示）。
- 实施顺序：`INC-CULT-003` → `INC-PAWNS-011` → `INC-UI-008`。
- 验收标准：
  - 五个境界资源形成正确进阶链；非终点境界声明突破所需修为，终点境界明确无下一境界。
  - 运行时修为只由 `Pawn/CultivationProgress` 持有；Pawn 只转发只读快照和变更信号，UI 不写回。
  - 信息卡完整模式显示修为与下一境界，精简模式隐藏；修为变化与达到阈值时事件驱动刷新。
  - 新增单元/集成测试通过，既有 GdUnit4 与 headless 回归不下降，统一门禁退出码 0。
  - 16:9、16:10、窄屏真实窗口下信息卡不与顶部 HUD / 暂停状态标签重叠，内容不溢出。
- 非范围：实际突破执行、境界属性加成、突破材料/条件、存档迁移、法强/暴击属性、Build 槽位交互。
- 依赖：`INC-CROSS-008` 的实现（已验收）、`INC-CULT-001`、`INC-CULT-002`、`INC-PAWNS-010`、`INC-UI-007`。
- 风险：`RealmDefinition` 新增资源引用可能改变资源加载顺序；`pawn.tscn` 与信息卡场景都是高冲突文件，必须按 CULT-003 → PAWNS-011 → UI-008 顺序单写入；新增信息行可能在 1152x648 下挤压布局。
- 验证结论：`INC-CULT-003`、`INC-PAWNS-011`、`INC-UI-008` 均已实现并通过验证。`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 119 例：unit 62 / integration 37 / gameplay 20；headless 10 套 548 项断言 0 失败）。真实窗口取证三档窗口 × 精简/暂停全部 `BOUNDS_INSIDE_VIEWPORT=true`、`HUD_OVERLAP=false`、`PAUSE_LABEL_OVERLAP=false`、`CONTENT_FITS=true`；MCP 校验三份 UI 目标全部 `valid: true`，`git diff --check` 退出码 0。
- 已知问题：修为突破阈值当前是原型基线 `100.0`，不是最终平衡曲线；实际突破执行仍未实现。为容纳信息卡修为区，`pawn_info_panel.tscn` 的内容间距与进度条高度已压缩，后续增删节点必须重跑真实窗口取证。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `8e1f0de`
- 备注：本父级只补齐 Phase 1 的修为显示，并为 Phase 3 提供数据基础；验收前所有变更留在工作区，不提交稳定版本。
### INC-CROSS-010：Build 信息卡与武器槽（Phase 2 第一步）

- 状态：accepted
- 创建时间：2026-09-25T16:38:52+08:00
- 最后修改：2026-09-25T16:46:30+08:00
- 来源：`docs/pawns信息ui.md` Phase 2「Build 信息卡」（功法槽 / 武器槽 / 主动技能槽 / 被动技能槽 + 每个槽位显示当前 / 最大容量）与 `docs/project_summary.md` §五 Build 分层（功法 → 武器 → 主动 → 被动）。
- 目标：补齐 Build 分层里完全缺失的“武器”一层（静态定义、五行属性、境界容量、Pawn 装备字段与校验），让信息卡 Build 区从三类槽位扩展为四类槽位并显示真实占用 / 容量；槽位点击详情、装备更换与突破预览留给后续父 Increment。
- 子 Increment：`INC-INVENTORY-001`（武器定义与五行属性表）、`INC-CULT-004`（武器槽容量）、`INC-PAWNS-012`（PawnData 武器字段与 Build 汇总 / 校验接入）、`INC-UI-009`（信息卡 Build 四类槽位行）。
- 实施顺序：`INC-INVENTORY-001` → `INC-CULT-004` → `INC-PAWNS-012` → `INC-UI-009`。
- 验收标准：
  - `RealmDefinition` 提供 `KIND_WEAPON` 容量，五个境界数据补充 `weapon_slots`，功法 / 主动 / 被动容量与设计表不回归。
  - 武器有独立静态资源（`WeaponDefinition`），五行取值受约束且标签只有一个来源；武器槽进入 `BuildLoadout` 与 `BuildValidator`（容量 / 重复 / 未配置 / 境界门槛）。
  - 玩家预设装备武器后，信息卡 Build 区显示四类槽位的“已占 / 上限”与已装备名称，武器条目带类型与五行标签。
  - 容量或 Build 数据变化时事件驱动刷新，不引入每帧轮询。
  - 新增单元 / 集成测试通过；统一门禁退出码 0；真实窗口三档（1152x648 / 1152x720 / 800x720）下信息卡不与顶部 HUD、暂停标签重叠且内容不溢出。
- 非范围：槽位点击详情、装备更换 / 卸下交互、武器数值与战斗结算、武器掉落与背包、五行与灵根相容校验、突破预览与突破执行（Phase 3）、存档字段。
- 依赖：`INC-CULT-001`、`INC-CULT-002`、`INC-PAWNS-008`、`INC-UI-007`、`INC-UI-008`（实现均在工作区，本批次已验收）。
- 风险：`pawn_info_panel.tscn` 是固定 356x354 的高冲突场景，新增第四行 Build 行必须重跑真实窗口取证；`player_pawn.tres` 是已登记基线数据，改动必须同步 `test/unit/pawn_data_defaults_test.gd`；新增 `game/inventory/` 目录需要与主题文件一一对应。
- 实现说明：武器槽容量在五个境界统一为 1，因为设计文档的“突破后预览”只列出功法 / 主动 / 被动三类扩容，武器不做境界扩容；`PawnData.weapon` 采用与 `active_skill` 相同的“单入口字段 + 汇总数组”约定，避免两套表示漂移；五行只是显示与后续校验的静态标签，本轮不参与战斗结算。
- 变更文件：见各子 Increment（武器静态定义与数据、境界四类槽位容量、PawnData 武器字段与 Build 校验、信息卡四类槽位显示）。
- 测试证据：
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot $GODOT_PATH -Layer all` → `RESULT: PASS`（GdUnit4 130 例 0 失败：unit 71 / integration 39 / gameplay 20；headless 10 套 549 断言 0 失败），退出码 0。
  - 四个子 Increment 的验收标准逐条由对应三层测试覆盖：武器静态契约与标签回退、四类槽位容量与 `ALL_KINDS`、武器 Build 校验（容量超限 / 境界门槛 / 未配置）、信息卡四行 Build 与武器标签。
  - 真实窗口取证 `test/tools/capture_pawn_info_panel_evidence.gd`：三档窗口（1152x648 / 1152x720 / 800x720）× 精简/暂停 共 6 次测量全部 `CAPTURE_DONE FAILURES=0`、`BOUNDS_INSIDE_VIEWPORT=true`、`HUD_OVERLAP=false`、`PAUSE_LABEL_OVERLAP=false`、`CONTENT_FITS=true`；6 次 Build 行一致包含 `武器  1 / 1    青锋剑（剑 · 金）`。
  - Godot MCP `validate` 覆盖四个子 Increment 的全部脚本 / 场景 / 资源目标 → 全部 `valid: true`；`git diff --check` 退出码 0。
- 验证状态：验证通过
- 验证时间：2026-09-25T16:46:30+08:00
- 已知问题：
  - 武器只参与 Build 校验与信息卡展示，不参与战斗结算与属性加成；五行不参与相容 / 克制校验。
  - 槽位点击详情、装备更换 / 卸下、更换后 Build 标签即时刷新未实现（Phase 2 剩余）。
  - 面板固定 356x354：为容纳武器行移除了修为区标题与分隔线，后续任何增删节点都必须重跑真实窗口取证。
- 验收时间：2026-09-25T16:51:32+08:00
- Git：`main` / `c21d8ec`
- 备注：父 Increment 只有在子 Increment 验证通过且用户明确验收后才能进入 `accepted`；验收前不创建 Git commit。本父级只做 Phase 2 第一步，不做槽位交互与 Phase 3。
## 活跃 Increment

| ID | 父 Increment | 主题 | 状态 | 摘要 | 最后修改 | 验证 | 验收 | Git |
|---|---|---|---|---|---|---|---|---|
| `INC-CROSS-001` | - | cross | `accepted` | 第一个可操作 Pawn MVP | 2026-09-25T13:44:10+08:00 | 通过 | 已验收 | `main` / `d7c2e1e` |
| `INC-PAWNS-001` | `INC-CROSS-001` | pawns | `accepted` | Pawn 基础数据、运行时和控制器拆分 | 2026-09-25T13:44:10+08:00 | 通过 | 已验收 | `main` / `d7c2e1e` |
| `INC-COMBAT-001` | `INC-CROSS-001` | combat | `accepted` | 普通攻击、受伤、死亡闭环 | 2026-09-25T13:44:10+08:00 | 通过 | 已验收 | `main` / `d7c2e1e` |
| `INC-UI-001` | `INC-CROSS-001` | ui | `accepted` | 选中、血条、暂停 HUD | 2026-09-25T13:44:10+08:00 | 通过 | 已验收 | `main` / `d7c2e1e` |
| `INC-CORE-001` | `INC-CROSS-001` | core | `accepted` | 主场景、InputMap、暂停 | 2026-09-25T13:44:10+08:00 | 通过 | 已验收 | `main` / `d7c2e1e` |
| `INC-TOOLS-001` | - | tools | `accepted` | 初始化 Git 仓库并配置 GitHub origin | 2026-09-25T13:54:46+08:00 | 通过 | 已验收（2026-09-25T13:45:00+08:00） | `main` / `origin` / 已 push（origin/main = 567b6e7） |
| `INC-TOOLS-002` | - | tools | `accepted` | 首次提交基线与素材入库策略 | 2026-09-25T13:54:46+08:00 | 通过 | 已验收（2026-09-25T13:45:00+08:00） | `main` / `d7c2e1e`（已 push） |
| `INC-UI-002` | `INC-CROSS-002` | ui | `accepted` | 血条按生命状态变化显示并延迟自动隐藏 | 2026-09-25T14:10:35+08:00 | 通过 | 已验收（2026-09-25T14:09:53+08:00） | `main` / `e233120` |
| `INC-PAWNS-002` | `INC-CROSS-002` | pawns | `accepted` | 生命状态变化统一入口与血条锚点结构 | 2026-09-25T14:10:35+08:00 | 通过 | 已验收（2026-09-25T14:09:53+08:00） | `main` / `e233120` |
| `INC-PAWNS-003` | - | pawns | `accepted` | 抽取 HealthComponent 作为生命状态单一数据源 | 2026-09-25T14:17:55+08:00 | 通过 | 已验收（2026-09-25T14:16:35+08:00） | `main` / `a873c3f` |
| `INC-CROSS-003` | - | cross | `accepted` | 通用资源池与多资源条抽象 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `f6cdebf` |
| `INC-CORE-002` | `INC-CROSS-003` | core | `accepted` | ResourcePoolComponent 资源池基础组件 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `f6cdebf` |
| `INC-UI-003` | `INC-CROSS-003` | ui | `accepted` | 通用 ResourceBar 与多资源条 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `f6cdebf` |
| `INC-PAWNS-004` | `INC-CROSS-003` | pawns | `accepted` | 生命/护盾迁移到资源池并保持接口 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `f6cdebf` |
| `INC-COMBAT-002` | `INC-CROSS-003` | combat | `accepted` | 灵力资源池与原子消耗能力 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `f6cdebf` |
| `INC-COMBAT-003` | - | combat | `accepted` | 首个主动技能执行闭环：定义、校验、灵力扣除、伤害、冷却与 AI 施放 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `193c1c5` |
| `INC-CROSS-006` | - | cross | `accepted` | 玩家主动技能操作闭环 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `5f39e5f` |
| `INC-PAWNS-007` | `INC-CROSS-006` | pawns | `accepted` | 玩家技能命令与施法接近逻辑 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `5f39e5f` |
| `INC-CORE-003` | `INC-CROSS-006` | core | `accepted` | 主动技能输入动作与主场景路由 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `5f39e5f` |
| `INC-UI-005` | `INC-CROSS-006` | ui | `accepted` | HUD 主动技能状态显示 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `5f39e5f` |
| `INC-CROSS-004` | - | cross | `accepted` | 通用资源条接入 Pawn 实战与 HUD 灵力 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `6df4fbb` |
| `INC-PAWNS-005` | `INC-CROSS-004` | pawns | `accepted` | 将通用资源条接入 Pawn 实战头顶 UI | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `6df4fbb` |
| `INC-UI-004` | `INC-CROSS-004` | ui | `accepted` | 在 HUD 中显示选中 Pawn 的灵力 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `6df4fbb` |
| `INC-PAWNS-006` | - | pawns | `accepted` | 生命资源池直接驱动死亡与状态条刷新 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `81e1b45` |
| `INC-CROSS-005` | - | cross | `accepted` | 建立可回归的自动化测试框架 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `b11c9b0` |
| `INC-TESTING-001` | `INC-CROSS-005` | testing | `accepted` | 引入 GdUnit4 v6.2.1 并建立三层测试框架与统一入口 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `b11c9b0` |
| `INC-TESTING-002` | `INC-CROSS-005` | testing | `accepted` | 修正自动隐藏计时的墙钟断言下界 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `ab4755d` |
| `INC-CROSS-007` | - | cross | `accepted` | 境界容量与 Build 校验 | 2026-09-25T16:51:32+08:00 | 通过（有外部阻塞） | 已验收 | `main` / `3351bc1` |
| `INC-CULT-001` | `INC-CROSS-007` | cultivation | `accepted` | 境界定义与 Build 容量表 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `3351bc1` |
| `INC-CULT-002` | `INC-CROSS-007` | cultivation | `accepted` | 功法/被动定义与 Build 容量冲突校验 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `3351bc1` |
| `INC-PAWNS-008` | `INC-CROSS-007` | pawns | `accepted` | Pawn 境界与 Build 汇总接口 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `3351bc1` |
| `INC-UI-006` | `INC-CROSS-007` | ui | `accepted` | HUD 境界与 Build 容量行 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `3351bc1` |
| `INC-PAWNS-009` | - | pawns | `accepted` | 同步敌人预设 180 生命的数据基线 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `83735d0` |
| `INC-CROSS-008` | - | cross | `accepted` | Pawn 信息卡 MVP（Phase 0 + Phase 1 数据可行部分） | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `78ecb97` |
| `INC-CROSS-009` | - | cross | `accepted` | 修为进度与下一境界 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `8e1f0de` |
| `INC-CULT-003` | `INC-CROSS-009` | cultivation | `accepted` | 境界进阶链与突破所需修为 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `8e1f0de` |
| `INC-PAWNS-011` | `INC-CROSS-009` | pawns | `accepted` | 修为进度组件与 Pawn 运行时接口 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `8e1f0de` |
| `INC-UI-008` | `INC-CROSS-009` | ui | `accepted` | 信息卡修为进度与下一境界显示 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `8e1f0de` |
| `INC-PAWNS-010` | `INC-CROSS-008` | pawns | `accepted` | PawnData 身份字段与数据变更视图信号 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `78ecb97` |
| `INC-UI-007` | `INC-CROSS-008` | ui | `accepted` | PawnInfoModel 与 PawnInfoPanel 信息卡骨架 | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `78ecb97` |
| `INC-CORE-004` | `INC-CROSS-008` | core | `accepted` | 主场景信息卡路由（选中/取消选中/暂停） | 2026-09-25T16:51:32+08:00 | 验证通过 | 已验收 | `main` / `78ecb97` |
| `INC-CROSS-010` | - | cross | `accepted` | Build 信息卡与武器槽（Phase 2 第一步） | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `c21d8ec` |
| `INC-INVENTORY-001` | `INC-CROSS-010` | inventory | `accepted` | 武器定义与五行属性表 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `c21d8ec` |
| `INC-CULT-004` | `INC-CROSS-010` | cultivation | `accepted` | 武器槽容量与境界容量表扩展 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `c21d8ec` |
| `INC-PAWNS-012` | `INC-CROSS-010` | pawns | `accepted` | PawnData 武器字段与 Build 汇总校验接入 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `c21d8ec` |
| `INC-UI-009` | `INC-CROSS-010` | ui | `accepted` | 信息卡 Build 区四类槽位与武器显示 | 2026-09-25T16:51:32+08:00 | 通过 | 已验收 | `main` / `c21d8ec` |

## 已完成 Increment

| ID | 主题 | 完成时间 | 验收时间 | Git commit |
|---|---|---|---|---|
| `INC-CROSS-001` | cross（含 pawns / combat / ui / core 子 Increment） | 2026-09-25T13:42:33+08:00 | 2026-09-25T13:42:33+08:00 | `d7c2e1e` |
| `INC-TOOLS-001` | tools（Git 仓库与 origin） | 2026-09-25T13:39:23+08:00 | 2026-09-25T13:45:00+08:00（按分钟记录） | `main` -> `origin/main`，2026-09-25T13:52:23+08:00 完成首次 push |
| `INC-TOOLS-002` | tools（首次提交基线） | 2026-09-25T13:43:51+08:00 | 2026-09-25T13:45:00+08:00（按分钟记录） | `d7c2e1e`、`ad6237a`、`567b6e7` |
| `INC-CROSS-002` | cross（含 ui / pawns 子 Increment） | 2026-09-25T14:02:26+08:00 | 2026-09-25T14:09:53+08:00 | `e233120`、docs(plan) 回写提交 |
| `INC-PAWNS-003` | pawns（HealthComponent 抽取） | 2026-09-25T14:16:35+08:00 | 2026-09-25T14:16:35+08:00 | `a873c3f`、docs(plan) 回写提交 |
| `INC-CROSS-003` | cross（含 core / ui / pawns / combat 子 Increment） | 2026-09-25T15:06:40+08:00 | 2026-09-25T16:51:32+08:00 | `f6cdebf` |
| `INC-CROSS-005` | cross（含 testing 子 Increment：GdUnit4 与三层测试框架） | 2026-09-25T15:23:00+08:00 | 2026-09-25T16:52:24+08:00 | `b11c9b0` |
| `INC-CROSS-004` | cross（含 pawns / ui 子 Increment） | 2026-09-25T15:14:42+08:00 | 2026-09-25T16:51:32+08:00 | `6df4fbb` |
| `INC-PAWNS-006` | pawns（生命池权威与状态条） | 2026-09-25T15:18:37+08:00 | 2026-09-25T16:51:32+08:00 | `81e1b45` |
| `INC-COMBAT-003` | combat（主动技能执行闭环） | 2026-09-25T15:37:12+08:00 | 2026-09-25T16:51:32+08:00 | `193c1c5` |
| `INC-CROSS-006` | cross（含 pawns / core / ui 子 Increment） | 2026-09-25T15:45:56+08:00 | 2026-09-25T16:51:32+08:00 | `5f39e5f` |
| `INC-CROSS-007` | cross（含 cultivation / pawns / ui 子 Increment） | 2026-09-25T15:56:30+08:00 | 2026-09-25T16:51:32+08:00 | `3351bc1` |
| `INC-PAWNS-009` | pawns（敌人预设 180 生命基线） | 2026-09-25T16:19:12+08:00 | 2026-09-25T16:51:32+08:00 | `83735d0` |
| `INC-CROSS-008` | cross（含 pawns / ui / core 子 Increment） | 2026-09-25T16:19:12+08:00 | 2026-09-25T16:51:32+08:00 | `78ecb97` |
| `INC-TESTING-002` | testing（自动隐藏计时墙钟断言） | 2026-09-25T16:19:12+08:00 | 2026-09-25T16:51:32+08:00 | `ab4755d` |
| `INC-CROSS-009` | cross（含 cultivation / pawns / ui 子 Increment） | 2026-09-25T16:33:34+08:00 | 2026-09-25T16:51:32+08:00 | `8e1f0de` |
| `INC-CROSS-010` | cross（含 inventory / cultivation / pawns / ui 子 Increment） | 2026-09-25T16:46:30+08:00 | 2026-09-25T16:51:32+08:00 | `c21d8ec` |

## 流程版本

| 版本 | 时间 | 变更 |
|---|---|---|
| v4.4 | 2026-09-25T16:51:32+08:00 | 用户验收通过 `INC-CROSS-003`~`INC-CROSS-010`（含独立 Increment `INC-COMBAT-003`、`INC-PAWNS-006`、`INC-PAWNS-009`）并按 Increment 回溯拆分提交：12 个功能/测试提交 + 1 个文档回写提交，工作区自 `3bd28fb` 起累积的全部待验收变更落库；被多个 Increment 共同修改的文件按其最终内容归入首次引入它的提交 |
| v4.3 | 2026-09-25T16:46:30+08:00 | 完成 `INC-CROSS-010` 全部四个子 Increment 并进入待验收：`INC-INVENTORY-001` 建立武器静态定义与五行标签、`INC-CULT-004` 把武器槽纳入境界容量表（四类槽位、不随境界递增）、`INC-PAWNS-012` 接入 `PawnData.weapon` 与 Build 汇总校验（顺序 功法→武器→主动→被动）、`INC-UI-009` 让信息卡 Build 区显示四类槽位与武器标签（移除修为区标题与分隔线以容纳第四行）；GdUnit4 用例增至 130 个（unit 71 / integration 39 / gameplay 20），10 个 headless 套件 549 项断言，真实窗口三档布局与 MCP 校验全部通过 |
| v4.2 | 2026-09-25T16:38:52+08:00 | 启动 `INC-CROSS-010`（Build 信息卡与武器槽，来源 `docs/pawns信息ui.md` Phase 2）：先建立武器静态定义与五行、把武器槽纳入境界容量表，再接入 `PawnData` 武器字段与 Build 校验，最后让信息卡 Build 区显示四类槽位；槽位点击详情、装备更换与 Phase 3 突破预览不在本父级范围 |
| v4.1 | 2026-09-25T16:33:34+08:00 | 完成 `INC-CROSS-009` 三子项并进入待验收：`INC-CULT-003` 串起炼气→筑基→金丹→元婴→化神并声明突破阈值、`INC-PAWNS-011` 建立运行时修为组件与 Pawn 快照/信号、`INC-UI-008` 在 Pawn 信息卡完整模式显示修为进度与下一境界；GdUnit4 用例增至 119 个（unit 62 / integration 37 / gameplay 20），10 个 headless 套件 548 项断言，真实窗口三档布局与 MCP 校验全部通过 |
| v4.0 | 2026-09-25T16:19:12+08:00 | 完成 `INC-CROSS-008` 全部子 Increment 并进入待验收：`INC-PAWNS-009` 登记敌人预设 180 生命基线、`INC-PAWNS-010` 补身份字段与视图信号、`INC-UI-007` 实现只读信息卡面板（真实窗口实测发现顶部 HUD 实高 246px 并修正面板高度）、`INC-CORE-004` 接入主场景选中/暂停路由；另立 `INC-TESTING-002` 修正自动隐藏计时的墙钟断言下界以消除负载导致的假失败 |
| v3.9 | 2026-09-25T16:04:30+08:00 | 启动 `INC-CROSS-008`（Pawn 信息卡 MVP，来源 `docs/pawns信息ui.md` Phase 0/1）与 `INC-PAWNS-009`（同步用户在 Godot 编辑器保存的敌人预设 180 生命基线）：先登记数据基线解除统一门禁阻塞，再按 pawns → ui → core 顺序实现身份字段、只读信息卡面板与主场景路由 |
| v3.7 | 2026-09-25T15:56:30+08:00 | 完成并验证 `INC-CROSS-007` 四子项（境界容量表、功法/被动定义与 Build 校验器、Pawn Build 汇总接口、HUD Build 行）：GdUnit4 用例增至 83 个（unit 42 / integration 25 / gameplay 16），9 个 headless 套件 480 项断言；统一门禁因工作区外部改动 `enemy_pawn.tres`（`max_health` 80 → 180）产生两条基线断言失败，登记为阻塞项等待用户裁决 |
| v3.6 | 2026-09-25T15:48:32+08:00 | 启动 `INC-CROSS-007`（MVP ③ Build 容量/冲突）：新建 `agent-plan/cultivation.md`，先建立境界容量表与功法互斥/境界门槛校验，再接入 Pawn 汇总与 HUD Build 行 |
| v3.5 | 2026-09-25T15:44:38+08:00 | 完成并验证 `INC-CROSS-006` 三子项：`PlayerController.order_skill()` 接近施法与回退、`cast_skill` Q 键输入路由、HUD `SkillLabel` 技能状态行；GdUnit4 用例增至 58 个（unit 25 / integration 21 / gameplay 12），9 个 headless 套件 480 项断言全通过，等待用户验收后提交 |
| v3.4 | 2026-09-25T15:38:42+08:00 | 启动 `INC-CROSS-006`：建立玩家主动技能操作闭环，按 pawns → core → ui 顺序实现 Q 命令、接近施法与 HUD 技能状态 |
| v3.3 | 2026-09-25T15:37:12+08:00 | 完成并验证 `INC-COMBAT-003`：新增 `ActiveSkillDefinition`、Pawn 施法校验/原子灵力消耗/伤害/冷却信号与 AI 优先施放；GdUnit4 用例增至 44 个（unit 25 / integration 14 / gameplay 5），9 个 headless 套件 480 项断言全通过，等待用户验收后提交 |
| v3.2 | 2026-09-25T15:25:30+08:00 | 启动 `INC-COMBAT-003`：在已实现但待验收的灵力池之上建立首个主动技能执行闭环，先以 player 御剑斩和 AI 自动施放验证资源消费者、冷却和失败无副作用语义 |
| v3.1 | 2026-09-25T15:23:00+08:00 | 完成并验证 `INC-TESTING-001`：引入 GdUnit4 v6.2.1 与 unit/integration/gameplay 三层测试，新增 `test/run_tests.ps1` 统一入口、`test/README.md`；34 个 GdUnit4 用例 + 9 个 headless 套件 480 项断言全通过，等待用户验收后提交 |
| v3.0 | 2026-09-25T15:18:37+08:00 | 完成并验证 `INC-PAWNS-006`：资源池事件直接驱动 Pawn 转发、状态条与死亡；新增 33 项断言，9 个 headless 套件合计 480/0，等待用户验收后提交 |
| v2.9 | 2026-09-25T15:16:16+08:00 | 启动 `INC-PAWNS-006`：让生命/护盾资源池直接驱动 Pawn 信号、状态条与死亡，修复直接操作 `Resources/Health` 绕过生命周期的已知问题 |
| v2.8 | 2026-09-25T15:14:42+08:00 | 完成 `INC-CROSS-004`：Pawn 实战接入三资源条，HUD 显示并刷新灵力；8 个 headless 套件 447 项断言全通过，等待用户验收后提交 |
| v2.7 | 2026-09-25T15:09:23+08:00 | 启动 `INC-CROSS-004`：建立 `INC-PAWNS-005` 与 `INC-UI-004`，把资源条接入 Pawn 实战头顶 UI，并让 HUD 显示选中 Pawn 的灵力 |
| v2.5 | 2026-09-25T15:06:40+08:00 | 完成并验证 `INC-COMBAT-002`：灵力池按需创建、原子消耗/恢复接口与归零不致死语义落地（63 项断言，合计 393 项全通过）；`INC-CROSS-003` 四个子 Increment 全部验证通过，父级转为待验收 |
| v2.4 | 2026-09-25T15:04:33+08:00 | 启动 `INC-COMBAT-002`：为 Pawn 增加灵力资源池、只读灵力代理与原子消耗/恢复接口，验证资源池抽象对第二个生产级资源（非死亡资源）成立 |
| v2.3 | 2026-09-25T15:03:59+08:00 | 完成并验证 `INC-PAWNS-004`：生命/护盾迁移到 `Resources/Health`、`Resources/Shield` 资源池，HealthComponent 转为兼容门面；新增 49 项断言，55/38/102/86 项既有回归全通过，运行态冒烟与 AI 实弹链路正常，等待用户验收 |
| v2.2 | 2026-09-25T14:58:00+08:00 | 启动 `INC-PAWNS-004`：把 Pawn 生命/护盾迁移到 ResourcePoolComponent，保留 HealthComponent 兼容门面与既有信号契约 |
| v2.1 | 2026-09-25T14:56:35+08:00 | 完成并验证 `INC-UI-003`：ResourceBar / PawnStatusBars 新增 86 项断言全通过，三资源条在 16:9、16:10、窄屏真实渲染无重叠，等待用户验收 |
| v2.0 | 2026-09-25T14:51:15+08:00 | 启动 `INC-UI-003`：抽取通用 ResourceBar 与 PawnStatusBars，依赖已验证但尚待验收的 `INC-CORE-002` API |
| v1.9 | 2026-09-25T14:49:30+08:00 | 启动并验证 `INC-CORE-002`：新增 ResourcePoolDefinition / ResourcePoolComponent / ResourceSetComponent；102 项新增断言与 93 项既有回归通过，等待用户验收 |
| v1.8 | 2026-09-25T14:38:49+08:00 | 流程变更：Increment 检索改为 Git Diff 优先；允许全量读取 agent-plan；新增检索证据字段、依赖顺序和全量读取规则 |
| v1.7 | 2026-09-25T14:31:51+08:00 | 持久化 `INC-CROSS-003` 通用资源池与多资源条计划，登记 `INC-CORE-002`、`INC-UI-003`、`INC-PAWNS-004`、`INC-COMBAT-002` 为 planned |
| v1.6 | 2026-09-25T14:17:55+08:00 | 回写 `INC-PAWNS-003` 实现提交 `a873c3f` 与提交时间，完成 git 稳定版本关联 |
| v1.5 | 2026-09-25T14:16:35+08:00 | 用户验收通过 `INC-PAWNS-003`：HealthComponent 成为生命/护盾单一数据源，进入 Git 提交与 hash 回写阶段 |
| v1.4 | 2026-09-25T14:14:29+08:00 | `INC-PAWNS-003` 实现完成并验证：HealthComponent 成为生命/护盾单一数据源，Pawn 只读代理 + 信号转发；55 项新增断言与 38 项回归断言全通过，等待用户验收 |
| v1.3 | 2026-09-25T14:12:20+08:00 | 细化并启动 `INC-PAWNS-003`（HealthComponent 抽取，来源 docs/血条ui需求.txt MVP 步骤①） |
| v1.2 | 2026-09-25T14:10:35+08:00 | 回写 `INC-CROSS-002` 的 commit hash `e233120` 到 ui.md / pawns.md / _index.md 与 AGENTS.md 基线 |
| v1.1 | 2026-09-25T14:09:53+08:00 | 用户验收通过 `INC-CROSS-002`；补齐 AGENTS.md §5.4 多分辨率（16:9 / 16:10 / 窄屏）真实渲染验证与像素核验，登记验收时间并进入 Git 提交阶段 |
| v1.0 | 2026-09-25T14:02:26+08:00 | 需求2 实现完成并验证：血条改为状态变化时显示 + 2 秒自动隐藏，独立血条场景、Pawn 统一生命状态入口；等待用户验收后再提交 |
| v0.9 | 2026-09-25T13:54:46+08:00 | 首次 push 到 origin/main；登记 INC-TOOLS-001/002 验收；建立 INC-CROSS-002 及 INC-UI-002 / INC-PAWNS-002 / INC-PAWNS-003（来源 docs/血条ui需求.txt） |
| v0.8 | 2026-09-25T13:43:51+08:00 | 完成首次提交 d7c2e1e 并回写验收与 commit 记录 |
| v0.7 | 2026-09-25T13:43:00+08:00 | 移除 AGENTS.md 中的本地绝对路径（满足 §8 提交约束） |
| v0.6 | 2026-09-25T13:42:33+08:00 | 记录 INC-CROSS-001 及四个子 Increment 的用户验收结论 |
| v0.5 | 2026-09-25T13:41:00+08:00 | 复核工程基线（.import 配对完整）、新增 INC-TOOLS-002 首次提交与素材入库策略 |
| v0.4 | 2026-09-25T13:39:23+08:00 | 复验 Pawn MVP 实现并规范化场景根节点命名，刷新验证证据 |
| v0.3 | 2026-09-25T13:34:13+08:00 | 同步首次 Pawn MVP 实现后的工程基线和验收状态 |
| v0.2 | 2026-09-25T13:09:29+08:00 | 按工作流总图优化 AGENTS.md，新增 validated 状态和阶段产物表 |
| v0.1 | 2026-09-25T13:06:47+08:00 | 建立 AGENTS.md、agent-plan 索引和 Increment 模板 |
