# Agent Plan Index

> 最后修改：2026-09-26T12:34:31+08:00
> 规则来源：`../AGENTS.md`

## 主题索引

| 主题 | 计划文件 | 状态 | 当前 Increment | 最后修改 |
|---|---|---|---|---|
| UI | `ui.md` | 待验收 | `INC-UI-019` | 2026-09-26T01:48:20+08:00 |
| 战斗 | `combat.md` | 已验收 | `INC-COMBAT-012` | 2026-09-26T11:50:07+08:00 |
| Pawns | `pawns.md` | 已验收 | `INC-PAWNS-023` | 2026-09-26T11:50:07+08:00 |
| 修炼 | `cultivation.md` | 已验收 | `INC-CULT-005` | 2026-09-25T20:16:30+08:00 |
| 宗门 | `sect.md` | 已验收 | `INC-SECT-003` | 2026-09-25T19:38:41+08:00 |
| 世界 | `world.md` | 已验收 | `INC-WORLD-008` | 2026-09-26T11:58:09+08:00 |
| 背包 | `inventory.md` | 已验收 | `INC-INVENTORY-001` | 2026-09-25T16:51:32+08:00 |
| 存档 | `save.md` | 未创建 | - | - |
| 音频 | `audio.md` | 未创建 | - | - |
| 核心 | `core.md` | 已验收（输入路由） | `INC-CORE-013` | 2026-09-26T01:48:20+08:00 |
| 工具 | `tools.md` | 已验收 | `INC-TOOLS-002` | 2026-09-25T13:54:46+08:00 |
| 测试 | `testing.md` | 已验收 | `INC-TESTING-019` | 2026-09-26T12:30:44+08:00 |

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
| `INC-CROSS-011` | `accepted` | `INC-PAWNS-013`、`INC-COMBAT-004`、`INC-UI-010`、`INC-UI-011`、`INC-CORE-005`、`INC-TESTING-003` | 战斗技能栏 SkillBar、技能状态读模型、1~6/点击施法入口与左下角 HUD 布局起点 | 通过 | 已验收 | 2026-09-25T17:17:48+08:00 |
| `INC-CROSS-012` | `accepted` | `INC-PAWNS-014`、`INC-COMBAT-005`、`INC-COMBAT-006`、`INC-UI-012`、`INC-CORE-006`、`INC-TESTING-004` | 三种战术技能与 Build → Combat 玩法闭环 | 通过 | 已验收 | 2026-09-25T17:57:16+08:00 |
| `INC-CROSS-013` | `accepted` | `INC-PAWNS-015`、`INC-COMBAT-007`、`INC-UI-013`、`INC-CORE-007`、`INC-TESTING-005` | Build 容量一致性执行：所有技能可见，超容量技能禁用且任何入口不可施放 | 通过 | 已验收 | 2026-09-25T18:11:27+08:00 |
| `INC-CROSS-014` | `accepted` | `INC-PAWNS-016`、`INC-COMBAT-008`、`INC-TESTING-006` | Gameplay 调参：三类技能是否产生真实决策（最优 Build 随敌人威胁档案改变） | 通过 | 已验收 | 2026-09-25T18:30:17+08:00 |
| `INC-CROSS-016` | `accepted` | `INC-PAWNS-017`、`INC-WORLD-003`、`INC-WORLD-004`、`INC-UI-015`、`INC-CORE-009`、`INC-TESTING-008` | 秘境深入：把「一次遭遇」升级成「房间链 + 收益 + 继续/撤退 + Boss」，验证「越深入收益越高、风险越大」的贪不贪决策 | 通过 | 已验收 | 2026-09-25T19:16:03+08:00 |
| `INC-CROSS-015` | `accepted` | `INC-WORLD-001`、`INC-WORLD-002`、`INC-UI-014`、`INC-CORE-008`、`INC-TESTING-007` | 秘境遭遇入口：把敌人威胁档案变成玩家可进入的遭遇（选择 → 战斗 → 结果 → 重选） | 通过 | 已验收 | 2026-09-25T18:52:41+08:00 |
| `INC-CROSS-017` | `accepted` | `INC-SECT-001`、`INC-SECT-002`、`INC-SECT-003`、`INC-PAWNS-018`、`INC-UI-016`、`INC-CORE-010`、`INC-WORLD-005`、`INC-TESTING-009` | 最小宗门（MVP-⑤）：把秘境灵石收益变成可升级的宗门设施，产出修为 / 灵草 / 丹药 / 功法 / 强化武器，形成「回去修炼 / 制作 / 强化，然后再次出发」的闭环 | 通过 | 已验收 | 2026-09-25T20:05:25+08:00 |
| `INC-CROSS-018` | `in_progress` | `INC-CULT-005`、`INC-PAWNS-019`、`INC-WORLD-006`、`INC-UI-017`、`INC-CORE-011`、`INC-TESTING-010` | 突破 → Build 重构：突破执行、运行时境界覆盖、跨遭遇延续、玩家入口与再战证据 | 进行中（4/6 子项已验收） | 待验收 | 2026-09-25T20:39:32+08:00 |
| `INC-CROSS-019` | `accepted` | `INC-COMBAT-009`、`INC-PAWNS-021`、`INC-WORLD-007`、`INC-UI-018`、`INC-TESTING-011`、`INC-TESTING-012`、`INC-TESTING-013`、`INC-TESTING-014`、`INC-TESTING-015`、`INC-TESTING-016`、`INC-TESTING-017`（已实现前置：`INC-PAWNS-020` 多单位运行时；已退役：`INC-CORE-012`） | 1v1 → 1vN Build 玩法验证（Build Gameplay Validation） | 验证通过（Gate 0 机制层 + 1v1 首通奖励、Build 切换面板与跨遭遇延续、`tests/` 场景化人工入口、Build Replay 自动化证据与 Round 1/2 客观对照、Stage 2 `1v1 / 1v2 / 1v3` 运行时终局收敛与重开清洁、测试入口自证（横幅 / 名牌 / `enemy_names` / `run_scenario.ps1`）） | 已验收 | 2026-09-26T02:09:20+08:00 |
| `INC-CROSS-020` | `accepted` | `INC-CORE-013`、`INC-UI-019`、`INC-TESTING-018` | 左键统一操作模型：选择 / 移动 / 技能目标选择，选中敌方显示敌方信息 | 验证通过（gameplay 输入路由用例 + 统一门禁 `RESULT: PASS` + 真实窗口与 OS 级鼠标输入冒烟） | 已验收 | 2026-09-26T01:48:20+08:00 |
| `INC-CROSS-021` | `accepted` | `INC-COMBAT-010`、`INC-COMBAT-011`、`INC-COMBAT-012`、`INC-PAWNS-022`、`INC-PAWNS-023`、`INC-WORLD-008`、`INC-TESTING-019` | Skill × Enemy Interaction 验证：技能池 / 问题型敌人 / 问题房间 | 通过（7/7 子项全部验证并验收：`INC-COMBAT-010` / `INC-PAWNS-022` / `INC-COMBAT-011` / `INC-COMBAT-012` / `INC-PAWNS-023` / `INC-WORLD-008` / `INC-TESTING-019`） | 已验收 | 2026-09-26T12:34:31+08:00 |

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

### INC-CROSS-011：战斗技能栏与左下角 HUD 布局基线

- 状态：accepted
- 创建时间：2026-09-25T17:01:58+08:00
- 最后修改：2026-09-25T17:17:48+08:00
- 来源：`docs/战斗技能ui.md`，以及用户要求把 Pawn 信息卡移至屏幕左下角，并固定左下角为建筑/操作/信息卡的显示起点。
- 目标：建立可复用的 SkillBar / SkillSlot，使玩家能在暂停式战斗中通过点击或 1~6 释放当前目标的主动技能；同时把 Pawn 信息卡与技能栏纳入统一左下 Dock，由左下向右、向上扩展。
- 子 Increment：`INC-PAWNS-013`、`INC-COMBAT-004`、`INC-UI-010`、`INC-UI-011`、`INC-CORE-005`、`INC-TESTING-003`。
- 实施顺序：`INC-PAWNS-013` → `INC-COMBAT-004` → `INC-UI-010` → `INC-UI-011` → `INC-CORE-005` → `INC-TESTING-003`；`main.tscn`、`main.gd`、`project.godot`、`agent-plan/_index.md` 串行写入。
- 验收标准与证据：
  - SkillSlot 固定 64×64，节点结构完整；冷却使用真实剩余比例从上往下覆盖，显示剩余秒数；消耗固定右下角、快捷键固定左上角。
  - SkillBar 按境界主动技能容量自动支持 2/3/4/5/6 个槽位；技能状态至少区分 READY / COOLDOWN / NO_RESOURCE / DISABLED，并保留 SELECTED / TARGETING 扩展状态。
  - 灵力不足时即使冷却完成也不显示为可释放，SkillSlot 不修改资源、冷却或伤害；点击只发出使用请求。
  - 选中玩家后可通过鼠标点击技能格和 1~6 快捷键释放当前有效目标，Q 保持释放第一个技能的兼容行为。
  - PawnInfoPanel 迁至左下 Dock，Dock 从屏幕左下方向右、向上扩展；建筑/操作/信息卡后续可在同一 Dock 追加，不与顶部 HUD、暂停标签或暂停遮罩冲突。
  - 验证证据包含 Godot MCP validate、统一测试门禁、真实窗口 16:9 / 16:10 / 窄屏报告与截图、`git diff --check`。
- 非范围：技能装配/卸载、技能树、目标选择圈、范围指示器、4v4 编队栏、正式技能图标素材、建筑与操作菜单业务实现。
- 风险：多主动技能数据兼容；tscn 冲突；Container 尺寸；左下 Dock 与窄屏顶部 HUD 的重叠；点击与快捷键重复触发。
- 验证结论：验证通过。统一门禁 160 cases、0 failures；headless 10 suites、549 assertions、0 failing；Godot MCP validate 通过；真实窗口布局报告 `FAILURES=0`。
- 验收时间：2026-09-25T17:17:48+08:00（用户要求推送并保持本地远端一致，视为验收授权）
- Git：`main` / `200e822`、`70a09f1`、`3938038`、`84d5ef7`、`182190b`、`cecc91d`
- 备注：六个子 Increment 均已验证并按 Increment 拆分提交；最终计划回写提交记录在 `_index.md` v4.6。

### INC-CROSS-012：三种战术技能与 Build → Combat 玩法闭环

- 状态：accepted
- 创建时间：2026-09-25T17:31:30+08:00
- 最后修改：2026-09-25T17:57:16+08:00
- 来源：`docs/build-mvp.md`（用户要求按 docs 新需求细化 Increment 并开发）。
- 目标：把目前的“多技能工程链”推进为最小可验证玩法闭环：三种真正不同的技能效果（输出 / 生存 / 控制）、Self/Ally/Enemy 目标类型、最小 Effect System、鼠标目标选择和两槽 Build 实战差异同时成立。
- 子 Increment：`INC-PAWNS-014`、`INC-COMBAT-005`、`INC-COMBAT-006`、`INC-UI-012`、`INC-CORE-006`、`INC-TESTING-004`。
- 实施顺序：PAWNS-014 → COMBAT-005 → COMBAT-006 → UI-012 → CORE-006 → TESTING-004；高冲突文件 `main.tscn`、`main.gd`、`project.godot`、`pawn.tscn`、`_index.md` 串行写入。
- 验收标准与证据：
  - 御剑斩、护体真气、定身术在数据层分别声明 DAMAGE / SHIELD / STUN 与 ENEMY / SELF / ENEMY 目标，三者不是同一伤害效果换数值。
  - 玩家可以点击技能格进入目标选择，点击合法目标确认；Self 技能立即施放；右键/Escape 可取消；非法目标不能产生资源、冷却或伤害副作用。
  - 治疗、护盾、眩晕能在真实战斗状态中观察到；眩晕期间目标不能移动/攻击/施法，持续时间到期后恢复。
  - 两槽 Build 至少形成输出+生存、输出+控制、生存+控制三种不同战斗过程，自动化测试能给出轨迹差异证据。
  - 完成时必须有 Godot MCP validate、统一测试门禁、专项 integration/gameplay 证据与 `git diff --check`；不把“三个按钮可点击”当作玩法闭环完成。
- 非范围：完整 Buff 编辑器、Effect[]/Condition/Trigger/Modifier、AOE/地面指示器、正式数值平衡、技能升级、存档、网络同步、复杂 AI 与正式 VFX。
- 依赖：`INC-CROSS-011` 已验收；`docs/build-mvp.md` 为需求来源。
- 风险：目标类型会改变旧控制器的“默认敌方目标”假设；Effect System 容易膨胀；Stun 容易与暂停/冷却混用；目标选择 UI 会增加主场景与 Pawn 场景的几何回归面。
- 验证结论：验证通过。六个子 Increment 均已验收；统一门禁 2026-09-25T17:55:34+08:00 返回 192 cases / 0 failures（unit 87 / integration 67 / gameplay 38）与 headless 10 suites / 549 assertions / 0 failing；专项技能目标选择与三套 Build 轨迹证据通过；Godot MCP validate 与 `git diff --check` 通过。
- 验收时间：2026-09-25T17:31:30+08:00（用户授权“验收通过，分increment提交”；随后要求“推送，保持本地远端一致”）
- Git：`main` / `65a494d`、`df36f24`、`0438397`、`cbe098b`、`a72f475`、`a895e2b`
- 备注：六个子 Increment 均已按 Increment 拆分提交；父级最终计划与 hash 回写随本次文档提交落库。

### INC-CROSS-013：Build 容量一致性执行

- 状态：accepted
- 创建时间：2026-09-25T18:00:42+08:00
- 最后修改：2026-09-25T18:11:27+08:00
- 来源：用户 2026-09-25 的下一阶段建议（Build Validator 优先级 4）与 `docs/build-mvp.md` MVP-5；建议明确指出当前 `Build capacity = 2` 与更多技能配置之间需要明确方案 A/B/C。
- 目标：让 `BuildValidator` 的容量结论真正贯穿 Pawn、Controller、AI、SkillBar、主场景快捷键与 HUD；采用方案 B——保留所有技能可见，超容量技能明确 `DISABLED`，不采用静默截断方案 C。
- 子 Increment：`INC-PAWNS-015`、`INC-COMBAT-007`、`INC-UI-013`、`INC-CORE-007`、`INC-TESTING-005`。
- 实施顺序：PAWNS-015 → COMBAT-007 → UI-013 → CORE-007 → TESTING-005；`pawn.gd`、`skill_slot_state.gd`、`skill_bar.gd`、`main.gd` 串行写入。
- 验收标准与证据：
  - `Pawn` 提供唯一的主动技能容量投影：有效境界返回前 N 个技能为可用，完整列表仍用于 `BuildValidator` 的 `over_capacity` 诊断。
  - 超容量技能在所有施法入口被拒绝，且无灵力、冷却、位置、资源或命令副作用；AI 不会消费超容量技能。
  - SkillBar 继续显示所有技能，超容量技能显示 `DISABLED` 且不能点击/进入 TARGETING；容量内技能与空槽行为不回归。
  - HUD 对超容量首技能显示明确 Build 禁用原因，Q/数字键不绕过 UI 裁决。
  - 三层测试覆盖容量 0 / 1 / 2 / 4、无境界兼容、完整 loadout 诊断与 4 技能 / 2 槽 gameplay 场景；统一门禁、Godot MCP validate 与 `git diff --check` 通过。
- 非范围：Build 编辑器、拖拽装备、技能商店/升级、五行与属性门槛扩展、正式数值平衡、存档迁移、AOE/目标类型扩展。
- 依赖：`INC-CROSS-012` 已验收；容量来源沿用 `INC-CULT-001` / `INC-CULT-002`。
- 风险：无境界单位与玩家 Build 语义必须区分；只在 UI 禁用会留下控制器/AI 旁路；截断完整技能列表会让 `BuildValidator` 失去诊断依据；超容量状态不得影响正常 2/2 Build。
- 验证结论：验证通过。五个子 Increment 均已验收；统一门禁返回 GdUnit4 207 cases / 0 failures（unit 94 / integration 73 / gameplay 40）与 headless 10 suites / 549 assertions / 0 failing suites；Godot MCP validate 13 个目标全部 valid，`git diff --check` 无输出。
- 验收时间：2026-09-25T18:11:27+08:00（用户授权“验收通过，分increment提交”，随后要求“推送，保持本地远端一致”）
- Git：`main` / `a8e1ea1`、`1fb0b2f`、`4ca845a`、`fcd5c65`、`f79b627`
- 备注：五个子 Increment 均已按 Increment 拆分提交；父级最终计划与 hash 回写随本次文档提交落库。

### INC-CROSS-014：Gameplay 调参——三类技能是否产生真实决策

- 状态：accepted
- 创建时间：2026-09-25T18:20:31+08:00
- 最后修改：2026-09-25T18:30:17+08:00
- 来源：`docs/build-mvp.md` MVP-5（Build → Skill → Combat 闭环）与用户 2026-09-25 的下一阶段建议优先级 5「Gameplay 调参：验证输出/生存/控制三类技能是否真正产生决策」。MVP-5 原文明确要求「不要测试三个 Build 都能打赢，应测试不同 Build 是否产生不同战斗过程」，并给出方向：敌人攻击高时倾向御剑+护体，敌人血低但行动危险时倾向御剑+定身。
- 目标：回答 MVP-5 的核心问题——在 2 个主动技能槽下从「输出/生存/控制」三类技能中选择两个，玩家是否因为**遭遇不同**而产生真实决策；结论必须以「最优 Build 随遭遇改变（不存在单一统治解）」的可复核证据为准，而不是「三套 Build 都能打赢」。
- 子 Increment：`INC-PAWNS-016`（敌人威胁档案数据）、`INC-COMBAT-008`（技能价值标定）、`INC-TESTING-006`（决策差异证据）。
- 实施顺序：PAWNS-016 → COMBAT-008 → TESTING-006；`agent-plan/_index.md` 与共享测试入口为高冲突文件，串行写入。
- 验收标准与证据：
  - 存在至少两类可区分的敌人威胁档案（长线高有效生命低 DPS / 短时低有效生命高爆发），全部为 `PawnData` 数据资源，不新增系统。
  - 三套 Build 在两类档案下的终局结果（胜负、击杀耗时、剩余有效生命、灵力消耗、护盾峰值、敌人失效时长、双方普通攻击次数）有可复核记录。
  - 结论满足「无单一统治解」：至少一个档案的最优 Build 与另一个档案的最优 Build 不同；若标定后发现某类技能在两轴上都被支配，必须回到 `INC-COMBAT-008` 调参或如实上报设计缺口，禁止用测试构造假差异。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP `validate` 与 `git diff --check` 全部通过。
- 非范围：新增技能与效果类型、AOE、Buff/Debuff 容器、正式平衡表、UI 美化、遭遇选择 UI、网络同步、存档迁移。
- 依赖：`INC-CROSS-013` 已验收；技能数据契约来自 `INC-PAWNS-014`，结算来自 `INC-COMBAT-006`。
- 风险：若在「不新增系统」的前提下无法造出非统治解，说明当前三类技能确实同质，这属于设计结论而非测试失败；必须记录并反馈，而不是降低验证标准。
- 验证结论：验证通过（2026-09-25T18:28:15+08:00）。三类技能在当前数值下确实产生随遭遇变化的决策，而不是同质按钮：
  - 敌人档案：新增「铁壁傀儡」（520 + 80 有效生命 / 攻击 16 / 间隔 1.6s，长线低威胁）与「血刃刺客」（140 有效生命 / 攻击 60 / 间隔 1.5s，短时高爆发），加上既有「试炼傀儡」基线共三档；档案只使用 `PawnData` 既有字段。
  - 终局对照（3 档案 × 3 套 Build + 无技能对照，全部跑到一方死亡）：试炼傀儡最优「输出+控制」（余命 0.913）；**铁壁傀儡最优「生存+控制」（余命 0.363）**；**血刃刺客最优「输出+控制」（余命 0.656）**。铁壁与血刃的最优解不同 → 不存在单一统治解。
  - 技能真实有效：血刃刺客档案下「无主动技能」对照直接战败（余命 0），铁壁傀儡档案下无技能只剩 3.75% 余命。
  - 机制解释（标定表见 `agent-plan/combat.md`）：护盾收益是固定 30 点，控制收益与敌方单次伤害线性放大（同样 2.0s 失效在血刃身上阻止约 73 点伤害，在铁壁身上只有约 13.75 点），所以长线遭遇偏向生存、爆发遭遇偏向控制。本次未改动任何技能数值，差异全部来自遭遇档案。
  - 真实取舍如实记录：铁壁档案下「输出+生存」击杀最快（15.72s，比最优解快 6.50s）但余命更低（0.3125 对 0.3625），两者互不支配，结论是「存在取舍」而不是「绝对唯一最优」；为让结论不依赖「余命与耗时谁更重要」的口径，证据层补充支配关系（`INC-TESTING-006` 断言 5）：铁壁档案下「输出+控制」被「生存+控制」严格支配，爆发档案下「生存+控制」被「输出+控制」严格支配——同一个「输出+控制」在长线遭遇里是明确错误选择、在爆发遭遇里是最优解。
  - 门禁：GdUnit4 210 cases / 0 failures（unit 96 / integration 73 / gameplay 41），headless 10 suites / 549 assertions / 0 failing suites；Godot MCP validate 通过；`git diff --check` 无输出。
- 验收时间：2026-09-25T18:30:17+08:00
- Git：`main` / `090949a`、`156e055`、`bd1c577`（+ 本计划回写提交）
- 备注：本父 Increment 是 `docs/build-mvp.md` 中 MVP-1~MVP-4 完成后唯一剩余的 MVP-5 验收项；前四项已由 `INC-CROSS-011` / `INC-CROSS-012` / `INC-CROSS-013` 覆盖。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」（承接「验收通过，分increment提交」），按 AGENTS.md §4.1 记录为明确验收；三个子 Increment 已按 PAWNS-016 → COMBAT-008 → TESTING-006 拆分提交。

### INC-CROSS-015：秘境遭遇入口（MVP-④ 第一刀）

- 状态：accepted
- 创建时间：2026-09-25T18:33:02+08:00
- 最后修改：2026-09-25T18:52:41+08:00
- 来源：`docs/project_summary.md` §十（秘境系统）与 §十八 MVP ④「一个秘境 + 5～10 个房间 + 1 个 Boss」；以及 `INC-PAWNS-016` 已知问题「档案数据尚无游戏内入口（遭遇选择 UI / 秘境流程属于非范围，需另立 Increment）」。
- 目标：先做秘境的第一刀，把已经用测试证明的「最优 Build 随遭遇改变」变成玩家可体验的最小闭环——玩家在实机里选择一份秘境遭遇 → 敌人按该档案起局 → 打完看到结果 → 改选别的遭遇或重新挑战。房间推进、随机事件、奖励与 Boss 不在本父级内。
- 子 Increment：`INC-WORLD-001`（遭遇定义与目录）、`INC-WORLD-002`（遭遇会话：起局/换敌/结算）、`INC-UI-014`（遭遇选择面板）、`INC-CORE-008`（主场景路由与引用刷新）、`INC-TESTING-007`（闭环证据）。
- 实施顺序：WORLD-001 → WORLD-002 → UI-014 → CORE-008 → TESTING-007；`agent-plan/_index.md`、`main.gd`、`main.tscn` 为高冲突文件，必须串行写入。
- 验收标准与证据：
  - 存在 ≥3 份可被玩家选择的遭遇，全部引用 `INC-PAWNS-016` 的正式敌人档案，不新增敌人数值、不复制公式。
  - 实机上选择不同遭遇会真的换掉敌人单位与其 `PawnData`，而不是只改文案（由 `INC-TESTING-007` 在真实 `main.tscn` 上断言）。
  - 一局结束后玩家能看到胜负结果，并能重新挑战或改选下一个遭遇；重复结算不会产生第二次结果广播。
  - 换遭遇后选中态、技能栏、信息卡、目标高亮全部指向新单位，不出现悬空引用；目标选择中点空白仍然无副作用。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP `validate` 与 `git diff --check` 全部通过。
  - 门禁实测（2026-09-25）：GdUnit4 241 cases（unit 102 / integration 93 / gameplay 46）、0 failures；headless 10 suites / 549 assertions / 0 failing suites；退出码 0、无孤儿节点。Godot MCP `validate` 通过（脚本内动态接线会被 `signals` 检查误报 `orphaned_handler`，已按脚本校验加真实主场景用例确认）；`git diff --check` 无输出。
- 非范围：房间推进与路线选择、随机事件、掉落与奖励结算、Boss、存档迁移、4v4 编队、AI 行为改动、技能与数值改动、UI 美化。
- 依赖：`INC-CROSS-012`、`INC-CROSS-013`、`INC-CROSS-014`（均已验收）。
- 风险：单位在运行时被替换是本项目第一次出现，最容易出问题的是上层缓存旧 Pawn 引用；因此本父级把「会话」与「路由」拆成两个 Increment，并要求会话通过信号驱动上层重新取引用。另一风险是范围膨胀成完整秘境；本父级只交付「一次遭遇」的闭环，房间与 Boss 另立 Increment。
- 验收时间：2026-09-25T18:52:41+08:00
- Git：`main` / `f7d1cc4`、`5646769`、`d4b8cd3`、`6f15121`、`e2a0594`（+ 本计划回写提交）
- 备注：本父级是 MVP-④（秘境）的第一步，不是完整秘境；完成后玩家第一次可以在实机中「按遭遇选对手」，而不是只能接受写死的单场对局。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」，按 `AGENTS.md` §4.1 与本仓库 `INC-CROSS-011`~ `INC-CROSS-014` 的既有约定记录为明确验收；五个子 Increment 按 WORLD-001 → WORLD-002 → UI-014 → CORE-008 → TESTING-007 顺序实施并按 Increment 拆分提交。

### INC-CROSS-016：秘境深入（MVP-④ 第二刀：房间链 + Boss + 贪不贪）

- 状态：accepted
- 创建时间：2026-09-25T18:54:11+08:00
- 最后修改：2026-09-25T19:16:03+08:00
- 来源：`docs/project_summary.md` §十 秘境系统基本循环（进入 → 探索 → 选路 → 事件 → 战斗 → 获取资源 → 继续深入 / 撤退 → Boss → 稀有奖励）与 §十八 MVP ④「一个秘境 + 5～10 个房间 + 1 个 Boss」；以及 `INC-CROSS-015` 的非范围声明「房间推进与路线选择、掉落与奖励结算、Boss」。
- 目标：完成 MVP-④ 的核心命题——**越深入，收益越高，风险越大**。把已经跑通的「一次遭遇」串成一条房间链：清空一间房结算灵石收益，玩家决定「继续深入」还是「见好就收」；继续就带着上一间剩下的生命 / 护盾 / 灵力进入下一间，战败则本局收益全部落空，最后一间是 Boss。随机事件、分支路线、商店与存档不在本父级内。
- 子 Increment：`INC-PAWNS-017`（Boss 档案）、`INC-WORLD-003`（房间链定义）、`INC-WORLD-004`（DungeonRun 运行时与资源延续）、`INC-UI-015`（秘境进度面板）、`INC-CORE-009`（主场景接线）、`INC-TESTING-008`（贪不贪闭环证据）。
- 实施顺序：PAWNS-017 → WORLD-003 → WORLD-004 → UI-015 → CORE-009 → TESTING-008；`agent-plan/_index.md`、`main.gd`、`main.tscn`、`encounter_session.gd` 为高冲突文件，必须串行写入。
- 验收标准与证据：
  - 存在一个秘境定义，含 5～10 个房间与 1 个 Boss，房间奖励随深度递增，全部引用正式敌人档案，不复制数值。
  - 清空房间后玩家能在「继续深入」与「见好就收」之间选择；两者产生**不同的终局状态**（`CLEARED` / `RETREATED`），而不是同一结果的两种文案。
  - 继续深入必须真的承担上一间的损耗：第 N+1 间开局的玩家生命 / 灵力小于满值（由 `INC-TESTING-008` 在真实 `main.tscn` 上断言）。
  - 战败必须让本局收益归零（`DEFEATED` 时 `get_earned_spirit_stones() == 0`），使「贪」有真实代价。
  - 既有行为不被破坏：`INC-WORLD-002` 的 12 个会话用例、`INC-TESTING-007` 的 5 个主场景遭遇用例继续通过。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP `validate` 与 `git diff --check` 全部通过。
- 非范围：随机生成与分支路线、房间随机事件、掉落物入库 / 背包 / 炼丹炼器、商店、存档与迁移、4v4 编队、技能与数值改动、Boss 分阶段机制、UI 美化。
- 依赖：`INC-CROSS-015`（已验收，遭遇入口与 EncounterSession）、`INC-PAWNS-016`（已验收，敌人威胁档案）、`INC-CROSS-014`（已验收，Build 决策差异证据）。
- 风险：本项目第一次引入「跨对局的玩家状态延续」，最容易出问题的是资源写回时序（新单位 `_ready()` 会按档案重置资源池）与换房时的孤儿节点；因此把资源采集 / 写回做成独立快照对象，并把「谁决定推进」严格限定在 `DungeonRun`。另一风险是范围膨胀成完整秘境（事件 / 商店 / 存档）；本父级只交付「房间链 + 收益 + 继续/撤退 + Boss」。
- 验收时间：2026-09-25T19:16:03+08:00
- Git（逐 Increment 单独提交）：`8fe713b`（PAWNS-017）、`5ee2549`（WORLD-003）、`7b8f1b1`（WORLD-004）、`9fefcaa`（UI-015）、`b16efb2`（CORE-009）、`8880733`（TESTING-008），另有两次 `docs(plan)` 回写提交（首批验收 / 本次 CROSS-016 收尾）
- 备注：本父级是 MVP-④ 的第二刀；完成后玩家第一次面对「现在收手还是再深一层」的风险决策。验收依据：用户 2026-09-25 指令「验收通过，分increment提交」与「分批incre单独推送后继续开发」，六个子 Increment 按 PAWNS-017 → WORLD-003 → WORLD-004 → UI-015 → CORE-009 → TESTING-008 顺序实施并逐个单独提交、逐个推送。
- 语义变更（已记录，非回归）：为了让「损耗累积」不可绕过，秘境进行中会锁住 `EncounterPanel` 的单场遭遇与「重新挑战」入口，因此 `INC-TESTING-007` 的 5 个主场景用例中有 2 个（换敌 / 结算）改为「先见好就收结束本局，再换敌」并在断言中显式验证锁定；其余 3 个用例未改。

## 活跃 Increment

| ID | 父 Increment | 主题 | 状态 | 摘要 | 最后修改 | 验证 | 验收 | Git |
|---|---|---|---|---|---|---|---|---|
| `INC-CROSS-017` | - | cross | `accepted` | 最小宗门：秘境收益 → 设施升级 → 修为 / 灵草 / 丹药 / 功法 / 强化 → 再战 | 2026-09-25T20:05:25+08:00 | 通过 | 已验收 | - |
| `INC-CULT-005` | `INC-CROSS-018` | cultivation | `accepted` | 突破执行：消费修为并沿境界链推进 | 2026-09-25T20:16:30+08:00 | 验证通过 | 已验收 | `main` / `d9213d2` |
| `INC-PAWNS-019` | `INC-CROSS-018` | pawns | `accepted` | 运行时境界覆盖层、突破入口与恢复校验 | 2026-09-25T20:16:30+08:00 | 验证通过 | 已验收 | `main` / `ff07dbe` |
| `INC-WORLD-006` | `INC-CROSS-018` | world | `accepted` | 跨遭遇延续运行时境界与容量 | 2026-09-25T20:16:30+08:00 | 验证通过 | 已验收 | `main` / `dba3f01` |
| `INC-UI-017` | `INC-CROSS-018` | ui | `accepted` | 突破入口与突破后容量预览 | 2026-09-25T20:39:32+08:00 | 验证通过 | 已验收 | `main` / `8de54d9` |
| `INC-PAWNS-020` | `INC-CROSS-019` | pawns | `awaiting_acceptance` | 多单位运行时（队伍契约 + 1vN 敌人集合；多玩家部分冻结） | 2026-09-25T21:45:00+08:00 | 验证通过（unit 12 / integration 8 / encounter 10，统一门禁 PASS） | 待验收 | `develop` / `4513e65` |
| `INC-PAWNS-021` | `INC-CROSS-019` | pawns | `awaiting_acceptance` | 最小运行时 Skill Loadout（技能学习与 Build 重配） | 2026-09-25T21:45:00+08:00 | 验证通过（unit 7 / integration 4 / capacity 5，统一门禁 368 cases + 549 assertions PASS） | 待验收 | `develop` / `4e92091` |
| `INC-COMBAT-009` | `INC-CROSS-019` | combat | `awaiting_acceptance` | 1v1 战斗问题窗口与轻量 CombatEvent | 2026-09-25T22:05:26+08:00 | 验证通过（unit 4 / integration 5 cases，统一门禁 377 cases + 549 assertions PASS） | 待验收 | `develop` / `a8a3c9e` |
| `INC-WORLD-007` | `INC-CROSS-019` | world | `awaiting_acceptance` | 固定 1v1 / 1v2 / 1v3 遭遇与首通定身术解锁 | 2026-09-25T22:21:30+08:00 | 验证通过（unit 5 / integration 4 cases，统一门禁 386 cases + 549 assertions PASS） | 待验收 | `develop` / `e591f33` |
| `INC-CORE-012` | `INC-CROSS-019` | core | `superseded` | 多单位选择、编组命令与暂停战术路由（4v4 冻结退役） | 2026-09-25T21:45:00+08:00 | 未验证 | 未验收（已退役） | 无提交 |
| `INC-UI-018` | `INC-CROSS-019` | ui | `awaiting_acceptance` | 最小 Build A/B 切换面板 | 2026-09-25T22:30:00+08:00 | 验证通过（integration 9 cases；统一门禁 395 cases + 549 assertions PASS；三档真实窗口取证 FAILURES=0） | 待验收 | `develop` / `1cce5bf` |
| `INC-TESTING-011` | `INC-CROSS-019` | testing | `awaiting_acceptance` | Build Replay 实验记录（自动化证据 + 人工三问） | 2026-09-25T23:05:40+08:00 | 验证通过（机制层 + 客观对照判据：单套件 2 cases；记录 FAILURES=0；统一门禁 397 cases + 549 assertions PASS；Gate A~E 属人工轮） | 待验收 | `develop` / `d6bd273` |
| `INC-TESTING-012` | `INC-CROSS-019` | testing | `awaiting_acceptance` | 场景化测试入口拆分到 `tests/` | 2026-09-25T22:33:49+08:00 | 验证通过（入口体检 FAILURES=0 / 5 入口 × 2 次；gameplay 60 cases；统一门禁 395 cases + 549 assertions PASS） | 待验收 | `develop` / `fd3eda8` |
| `INC-TESTING-013` | `INC-CROSS-019` | testing | `awaiting_acceptance` | Stage 2（1v1 / 1v2 / 1v3）运行时终局收敛与重开清洁证据 | 2026-09-25T23:55:00+08:00 | 验证通过（单套件 gameplay 2 cases / 0 orphans；1v1 / 1v2 / 1v3 均在 10~19s 内跑到终局，1v2 胜利需打掉两名敌人；统一门禁 399 cases + 549 assertions PASS） | 待验收 | `develop` / `6d7b388` |
| `INC-TESTING-014` | `INC-CROSS-019` | testing | `awaiting_acceptance` | 人工轮 CombatEvent 取证（实机每局应对序列落盘） | 2026-09-25T23:01:35+08:00 | 验证通过（单套件 2 cases / 0 failures / 0 orphans；入口体检 6 入口 × 2 次 FAILURES=0；统一门禁 401 cases + 549 assertions PASS） | 待验收 | `develop` / `3549aa1` |
| `INC-TESTING-015` | `INC-CROSS-019` | testing | `accepted` | 人工轮可控开局（支持 --pause-on-start） | 2026-09-26T00:19:06+08:00 | 验证通过（单套件 3 cases / 0 failures / 0 orphans，含 `test_pause_on_start_pauses_after_entry_is_ready`；统一门禁 402 cases + 549 assertions PASS） | 已验收 | `develop` / `b5550ce` |
| `INC-TESTING-016` | `INC-CROSS-019` | testing | `accepted` | 测试入口聚焦 Build（隐藏非 Build 菜单） | 2026-09-25T23:52:10+08:00 | 验证通过（入口体检 6 入口 × 2 次 FAILURES=0；真实窗口可见控件核对无换敌 / 秘境 / 宗门面板；统一门禁 402 cases + 549 assertions PASS） | 已验收 | `develop` / `b5550ce` |
| `INC-TESTING-017` | `INC-CROSS-019` | testing | `accepted` | 测试入口自证与敌我标识（横幅 + 名牌） | 2026-09-26T00:19:06+08:00 | 验证通过（入口体检 6 入口 × 2 次 FAILURES=0，含横幅与名牌断言；真实窗口 1v2 / 1v3 分别 2 / 3 个敌方名牌且宗门等菜单隐藏；F5 反向对照无横幅无名牌；统一门禁 402 cases + 549 assertions PASS） | 已验收 | `develop` / `b5550ce` |
| `INC-CROSS-020` | - | cross | `accepted` | 左键统一操作模型：选择 / 移动 / 技能目标选择，选中敌方显示敌方信息 | 2026-09-26T01:48:20+08:00 | 验证通过（402→406 cases 中的 4 个新输入路由用例 + 统一门禁 `RESULT: PASS` + 真实窗口 / OS 级鼠标输入冒烟） | 已验收 | `develop` / `e69a420` |
| `INC-CORE-013` | `INC-CROSS-020` | core | `accepted` | 左键统一入口：选中任意单位 / 左键移动 / 右键不再移动 | 2026-09-26T01:48:20+08:00 | 验证通过（gameplay 5 个输入路由用例 + 真实窗口 `指令：移动到 (320, 520)` / 右键零命令；统一门禁 `RESULT: PASS`） | 已验收 | `develop` / `d405bbe` |
| `INC-UI-019` | `INC-CROSS-020` | ui | `accepted` | 选中敌方单位时的信息 UI 口径（信息卡绑定 / 玩家面板解绑 / HUD 文案） | 2026-09-26T01:48:20+08:00 | 验证通过（gameplay 断言信息卡绑定敌方且技能栏与 Build 面板解绑；可见控件清单无 `SkillBar`、信息卡显示 `气血/护体` 无灵力行） | 已验收 | `develop` / `bb1d502` |
| `INC-TESTING-018` | `INC-CROSS-020` | testing | `accepted` | 输入模型测试矩阵（左键移动 / 敌方选中 / 右键不移动） | 2026-09-26T01:48:20+08:00 | 验证通过（删除 1 个旧契约用例、新增 5 个；统一门禁 `RESULT: PASS`，GdUnit4 402 → 406 cases / 0 failures，exit 0） | 已验收 | `develop` / `3955517` |
| `INC-CROSS-021` | - | cross | `accepted` | Skill × Enemy Interaction 验证：技能池 / 问题型敌人 / 问题房间 | 2026-09-26T12:34:31+08:00 | 通过（7/7 子项全部验证并验收：`INC-COMBAT-010` / `INC-COMBAT-011` / `INC-COMBAT-012` / `INC-PAWNS-022` / `INC-PAWNS-023` / `INC-WORLD-008` / `INC-TESTING-019`；已知限制：`problem_dungeon.tres` 尚未接入游玩入口） | 已验收 | `develop` / `4c0061d`、`0f20ed2`、`f3537e2`、`1f222b6`、`5f5ffeb`、`f1abebd`、`a963738`、`a7da57c`、`ec10b0f` |
| `INC-COMBAT-010` | `INC-CROSS-021` | combat | `accepted` | 技能效果类型扩展（位移 / 范围伤害 / 吸血） | 2026-09-26T02:01:11+08:00 | 验证通过（unit 8 cases / integration 8 cases / 0 failures；统一门禁 GdUnit4 415 cases / 0 failures + headless 549 assertions，`RESULT: PASS`，exit 0） | 已验收 | `develop` / `4c0061d` |
| `INC-COMBAT-011` | `INC-CROSS-021` | combat | `accepted` | 敌人技能特征差异化（问题型敌人） | 2026-09-26T02:24:14+08:00 | 验证通过（unit 6 cases + integration 4 + 1 cases / 0 failures；六档案问题标签与价值轴各自唯一、召唤增援按 1.0s / 3.0s 节奏生成且计入终局、召唤者死后调度停止、危险窗口契约不变；统一门禁 GdUnit4 424 cases + headless 549 assertions PASS） | 已验收 | `develop` / `5f5ffeb` |
| `INC-COMBAT-012` | `INC-CROSS-021` | combat | `accepted` | 条件伤害（对受控目标额外倍率） | 2026-09-26T11:50:07+08:00 | 验证通过（validate 6 脚本全通过；unit 8 cases + integration 10 cases + catalog 12 cases + runtime 5 cases / 0 failures；默认 1.0 零影响、受控叠加、非 DAMAGE 不参与；统一门禁 GdUnit4 429 cases / 0 failures + headless 549 assertions，`RESULT: PASS`，exit 0） | 已验收 | `develop` / `f1abebd` |
| `INC-PAWNS-022` | `INC-CROSS-021` | pawns | `accepted` | 玩家技能池扩到六类价值轴（保持 2 槽） | 2026-09-26T02:01:11+08:00 | 验证通过（unit 10 cases / 0 failures，六技能 id / effect_type 唯一且覆盖六类价值轴；统一门禁 GdUnit4 415 cases / 0 failures + headless 549 assertions，`RESULT: PASS`，exit 0） | 已验收 | `develop` / `0f20ed2` |
| `INC-PAWNS-023` | `INC-CROSS-021` | pawns | `accepted` | 玩家技能池扩到 8 个（条件爆发 + 主动回复） | 2026-09-26T11:50:07+08:00 | 验证通过（catalog 12 cases + runtime 5 cases / 0 failures；八技能价值轴互不重复、破军斩受控 3.36× 反超御剑斩 1.8× 且未受控 1.4× 更弱、回春术 55 点自疗、炼气期仍 2 槽；统一门禁 GdUnit4 429 cases / 0 failures + headless 549 assertions，`RESULT: PASS`，exit 0） | 已验收 | `develop` / `a963738` |
| `INC-WORLD-008` | `INC-CROSS-021` | world | `accepted` | 秘境问题房间（按战斗问题组合） | 2026-09-26T11:58:09+08:00 | 验证通过（12 间问题房间；六类问题型全覆盖；前 6 间首通技能链；同一 Build 的高防 / 高爆发房间差异可复现；奖励单调；统一门禁 GdUnit4 438 cases / 0 failures + headless 549 assertions，`RESULT: PASS`，exit 0） | 已验收 | `develop` / `a7da57c` |
| `INC-TESTING-019` | `INC-CROSS-021` | testing | `accepted` | Skill × Enemy 交互矩阵（同一 Build 面对不同问题） | 2026-09-26T12:30:44+08:00 | 验证通过（单套件 3 cases / 0 failures / 0 orphans，连续 5 次跨进程重跑一致方向；六格矩阵 5 格差异超噪声、6 格互有胜负、胜出 Build ≥2 个；数值 × 条件轴反向对照成立；统一门禁 `RESULT: PASS`，GdUnit4 441 cases / 0 failures） | 已验收 | `develop` / `ec10b0f` |
| `INC-SECT-001` | `INC-CROSS-017` | sect | `accepted` | 宗门设施静态定义与六座设施数据 | 2026-09-25T19:38:41+08:00 | 通过 | 已验收 | `main` / `c25ffbc` |
| `INC-SECT-002` | `INC-CROSS-017` | sect | `accepted` | SectState 运行时：库存 / 设施等级 / 升级 / 修炼 / 收获 | 2026-09-25T19:38:41+08:00 | 通过 | 已验收 | `main` / `8c65ff1` |
| `INC-SECT-003` | `INC-CROSS-017` | sect | `accepted` | 转化设施：藏经阁参悟 / 炼器房强化 / 丹房炼丹 | 2026-09-25T19:38:41+08:00 | 通过 | 已验收 | `main` / `9c97ef9` |
| `INC-PAWNS-018` | `INC-CROSS-017` | pawns | `accepted` | 运行时 Build 覆盖层：领悟功法与武器强化不改写静态资源 | 2026-09-25T19:38:41+08:00 | 通过 | 已验收 | `main` / `626c9c8` |
| `INC-UI-016` | `INC-CROSS-017` | ui | `accepted` | 宗门面板：库存 / 设施列表 / 升级与转化入口 | 2026-09-25T19:38:41+08:00 | 通过 | 已验收 | `main` / `cc1c2b9` |
| `INC-CORE-010` | `INC-CROSS-017` | core | `accepted` | 主场景宗门接线与秘境收益入账 | 2026-09-25T19:52:42+08:00 | 通过 | 已验收 | `main` / `224b7f6` |
| `INC-WORLD-005` | `INC-CROSS-017` | world | `accepted` | 跨对局修士运行时进度延续（功法 / 强化 / 修为） | 2026-09-25T20:05:25+08:00 | 通过 | 已验收 | `main` / `6f0be8c` |
| `INC-TESTING-009` | `INC-CROSS-017` | testing | `accepted` | 宗门闭环证据：收益 → 修炼 / 制作 / 强化 → 再战 | 2026-09-25T20:05:25+08:00 | 通过 | 已验收 | `main` / `06200f2` |
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
| `INC-PAWNS-013` | `INC-CROSS-011` | pawns | `accepted` | 多主动技能配置与 Build 汇总 | 2026-09-25T17:17:48+08:00 | 通过 | 已验收 | `main` / `200e822` |
| `INC-COMBAT-004` | `INC-CROSS-011` | combat | `accepted` | SkillSlot 战斗状态读模型 | 2026-09-25T17:17:48+08:00 | 通过 | 已验收 | `main` / `70a09f1` |
| `INC-UI-010` | `INC-CROSS-011` | ui | `accepted` | SkillSlot 固定技能格组件 | 2026-09-25T17:17:48+08:00 | 通过 | 已验收 | `main` / `3938038` |
| `INC-UI-011` | `INC-CROSS-011` | ui | `accepted` | SkillBar 动态技能栏与左下角 HUD 起点 | 2026-09-25T17:17:48+08:00 | 通过 | 已验收 | `main` / `84d5ef7` |
| `INC-CORE-005` | `INC-CROSS-011` | core | `accepted` | 主场景技能栏接入与 1~6 快捷键 | 2026-09-25T17:17:48+08:00 | 通过 | 已验收 | `main` / `182190b` |
| `INC-TESTING-003` | `INC-CROSS-011` | testing | `accepted` | 技能栏与左下角布局证据 | 2026-09-25T17:17:48+08:00 | 通过 | 已验收 | `main` / `cecc91d` |
| `INC-CROSS-012` | - | cross | `accepted` | 三种战术技能与 Build → Combat 玩法闭环 | 2026-09-25T17:57:16+08:00 | 通过 | 已验收 | `main` / `65a494d`、`df36f24`、`0438397`、`cbe098b`、`a72f475`、`a895e2b` |
| `INC-PAWNS-014` | `INC-CROSS-012` | pawns | `accepted` | 三种战术主动技能与数据契约 | 2026-09-25T17:34:51+08:00 | 验证通过 | 已验收 | `main` / `65a494d` |
| `INC-COMBAT-005` | `INC-CROSS-012` | combat | `accepted` | 技能目标类型与控制器目标解析 | 2026-09-25T17:34:51+08:00 | 验证通过 | 已验收 | `main` / `df36f24` |
| `INC-COMBAT-006` | `INC-CROSS-012` | combat | `accepted` | 最小 Skill Effect System（Damage/Heal/Shield/Stun） | 2026-09-25T17:57:16+08:00 | 验证通过 | 已验收 | `main` / `0438397`、`60355ae` |
| `INC-UI-012` | `INC-CROSS-012` | ui | `accepted` | 技能目标选择交互状态与合法目标高亮 | 2026-09-25T17:57:16+08:00 | 验证通过 | 已验收 | `main` / `cbe098b` |
| `INC-CORE-006` | `INC-CROSS-012` | core | `accepted` | 主场景技能目标选择与取消路由 | 2026-09-25T17:57:16+08:00 | 验证通过 | 已验收 | `main` / `a72f475` |
| `INC-TESTING-004` | `INC-CROSS-012` | testing | `accepted` | 三种技能战术差异与 Build 变化证据 | 2026-09-25T17:57:16+08:00 | 验证通过 | 已验收 | `main` / `a895e2b` |
| `INC-CROSS-013` | - | cross | `accepted` | Build 容量一致性执行 | 2026-09-25T18:11:27+08:00 | 验证通过 | 已验收 | `main` / `a8e1ea1`、`1fb0b2f`、`4ca845a`、`fcd5c65`、`f79b627` |
| `INC-PAWNS-015` | `INC-CROSS-013` | pawns | `accepted` | 主动技能容量的运行时投影 | 2026-09-25T18:11:27+08:00 | 验证通过 | 已验收 | `main` / `a8e1ea1` |
| `INC-COMBAT-007` | `INC-CROSS-013` | combat | `accepted` | Build 容量约束贯穿施法裁决 | 2026-09-25T18:11:27+08:00 | 验证通过 | 已验收 | `main` / `1fb0b2f` |
| `INC-UI-013` | `INC-CROSS-013` | ui | `accepted` | 超容量技能槽的禁用显示与请求拦截 | 2026-09-25T18:11:27+08:00 | 验证通过 | 已验收 | `main` / `4ca845a` |
| `INC-CORE-007` | `INC-CROSS-013` | core | `accepted` | HUD 与快捷键的 Build 容量一致性 | 2026-09-25T18:11:27+08:00 | 验证通过 | 已验收 | `main` / `fcd5c65` |
| `INC-TESTING-005` | `INC-CROSS-013` | testing | `accepted` | Build 容量一致的自动化证据 | 2026-09-25T18:11:27+08:00 | 验证通过 | 已验收 | `main` / `f79b627` |
| `INC-CROSS-014` | - | cross | `accepted` | Gameplay 调参：三类技能是否产生真实决策 | 2026-09-25T18:30:17+08:00 | 验证通过 | 已验收 | `main` / `090949a`、`156e055`、`bd1c577` |
| `INC-PAWNS-016` | `INC-CROSS-014` | pawns | `accepted` | 敌人威胁档案预设（长线型 / 爆发型） | 2026-09-25T18:30:17+08:00 | 验证通过 | 已验收 | `main` / `090949a` |
| `INC-COMBAT-008` | `INC-CROSS-014` | combat | `accepted` | 技能价值标定与遭遇威胁轴对齐 | 2026-09-25T18:30:17+08:00 | 验证通过 | 已验收 | `main` / `156e055` |
| `INC-TESTING-006` | `INC-CROSS-014` | testing | `accepted` | Build 决策差异证据（威胁档案 × 三套 Build 终局对照） | 2026-09-25T18:30:17+08:00 | 验证通过 | 已验收 | `main` / `bd1c577` |
| `INC-CROSS-015` | - | cross | `accepted` | 秘境遭遇入口：选择 → 战斗 → 结果 → 重选 | 2026-09-25T18:52:41+08:00 | 验证通过 | 已验收 | `f7d1cc4`、`5646769`、`d4b8cd3`、`6f15121`、`e2a0594` |
| `INC-WORLD-001` | `INC-CROSS-015` | world | `accepted` | 遭遇定义与秘境遭遇目录 | 2026-09-25T18:52:41+08:00 | 验证通过 | 已验收 | `f7d1cc4` |
| `INC-WORLD-002` | `INC-CROSS-015` | world | `accepted` | 遭遇会话：起局 / 换敌 / 结算 | 2026-09-25T18:52:41+08:00 | 验证通过 | 已验收 | `5646769` |
| `INC-UI-014` | `INC-CROSS-015` | ui | `accepted` | 遭遇选择面板 | 2026-09-25T18:52:41+08:00 | 验证通过 | 已验收 | `d4b8cd3` |
| `INC-CORE-008` | `INC-CROSS-015` | core | `accepted` | 主场景遭遇路由与引用刷新 | 2026-09-25T18:52:41+08:00 | 验证通过 | 已验收 | `6f15121` |
| `INC-CROSS-016` | - | cross | `accepted` | 秘境深入：房间链 + 收益 + 继续/撤退 + Boss | 2026-09-25T19:16:03+08:00 | 通过 | 已验收 | `b16efb2`、`8880733`（+ 计划回写提交） |
| `INC-PAWNS-017` | `INC-CROSS-016` | pawns | `accepted` | 秘境 Boss 敌人档案 | 2026-09-25T19:10:05+08:00 | 验证通过 | 已验收 | `8fe713b` |
| `INC-WORLD-003` | `INC-CROSS-016` | world | `accepted` | 秘境房间链定义 | 2026-09-25T19:10:05+08:00 | 验证通过 | 已验收 | `5ee2549` |
| `INC-WORLD-004` | `INC-CROSS-016` | world | `accepted` | 秘境运行时：房间推进 / 资源延续 / 撤退 | 2026-09-25T19:10:05+08:00 | 验证通过 | 已验收 | `7b8f1b1` |
| `INC-UI-015` | `INC-CROSS-016` | ui | `accepted` | 秘境进度面板（继续 / 撤退） | 2026-09-25T19:10:05+08:00 | 验证通过 | 已验收 | `9fefcaa` |
| `INC-CORE-009` | `INC-CROSS-016` | core | `accepted` | 主场景秘境接线 | 2026-09-25T19:16:03+08:00 | 验证通过 | 已验收 | `b16efb2` |
| `INC-TESTING-008` | `INC-CROSS-016` | testing | `accepted` | 秘境贪不贪闭环证据 | 2026-09-25T19:16:03+08:00 | 验证通过 | 已验收 | `8880733` |
| `INC-TESTING-007` | `INC-CROSS-015` | testing | `accepted` | 遭遇闭环自动化证据 | 2026-09-25T18:52:41+08:00 | 验证通过 | 已验收 | `e2a0594` |

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
| `INC-CROSS-011` | cross（含 pawns / combat / ui / core / testing 子 Increment） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `200e822`、`70a09f1`、`3938038`、`84d5ef7`、`182190b`、`cecc91d` |
| `INC-PAWNS-013` | pawns（多主动技能配置与 Build 汇总） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `200e822` |
| `INC-COMBAT-004` | combat（SkillSlot 状态读模型） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `70a09f1` |
| `INC-UI-010` | ui（SkillSlot 固定技能格） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `3938038` |
| `INC-UI-011` | ui（SkillBar 与左下角布局） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `84d5ef7` |
| `INC-CORE-005` | core（主场景技能栏与 1~6 快捷键） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `182190b` |
| `INC-TESTING-003` | testing（真实窗口布局证据） | 2026-09-25T17:17:48+08:00 | 2026-09-25T17:17:48+08:00 | `cecc91d` |
| `INC-CROSS-012` | cross（含 pawns / combat / ui / core / testing 子 Increment） | 2026-09-25T17:55:34+08:00 | 2026-09-25T17:31:30+08:00 | `65a494d`、`df36f24`、`0438397`、`cbe098b`、`a72f475`、`a895e2b` |
| `INC-PAWNS-014` | pawns（三种战术主动技能与数据契约） | 2026-09-25T17:34:51+08:00 | 2026-09-25T17:31:30+08:00 | `65a494d` |
| `INC-COMBAT-005` | combat（技能目标类型与控制器目标解析） | 2026-09-25T17:34:51+08:00 | 2026-09-25T17:31:30+08:00 | `df36f24` |
| `INC-COMBAT-006` | combat（最小 Skill Effect System） | 2026-09-25T17:39:59+08:00 | 2026-09-25T17:31:30+08:00 | `0438397`、`60355ae` |
| `INC-UI-012` | ui（技能目标选择交互状态与合法目标高亮） | 2026-09-25T17:43:37+08:00 | 2026-09-25T17:31:30+08:00 | `cbe098b` |
| `INC-CORE-006` | core（主场景技能目标选择与取消路由） | 2026-09-25T17:55:34+08:00 | 2026-09-25T17:31:30+08:00 | `a72f475` |
| `INC-TESTING-004` | testing（三种技能战术差异与 Build 变化证据） | 2026-09-25T17:55:34+08:00 | 2026-09-25T17:31:30+08:00 | `a895e2b` |
| `INC-CROSS-013` | cross（含 pawns / combat / ui / core / testing 子 Increment） | 2026-09-25T18:11:27+08:00 | 2026-09-25T18:11:27+08:00 | `a8e1ea1`、`1fb0b2f`、`4ca845a`、`fcd5c65`、`f79b627` |
| `INC-PAWNS-015` | pawns（主动技能容量投影） | 2026-09-25T18:11:27+08:00 | 2026-09-25T18:11:27+08:00 | `a8e1ea1` |
| `INC-COMBAT-007` | combat（施法路径容量拒绝） | 2026-09-25T18:11:27+08:00 | 2026-09-25T18:11:27+08:00 | `1fb0b2f` |
| `INC-UI-013` | ui（超容量技能槽禁用） | 2026-09-25T18:11:27+08:00 | 2026-09-25T18:11:27+08:00 | `4ca845a` |
| `INC-CORE-007` | core（HUD 与快捷键容量一致性） | 2026-09-25T18:11:27+08:00 | 2026-09-25T18:11:27+08:00 | `fcd5c65` |
| `INC-TESTING-005` | testing（跨层容量证据） | 2026-09-25T18:11:27+08:00 | 2026-09-25T18:11:27+08:00 | `f79b627` |
| `INC-CROSS-014` | cross（含 pawns / combat / testing 子 Increment） | 2026-09-25T18:30:17+08:00 | 2026-09-25T18:30:17+08:00 | `090949a`、`156e055`、`bd1c577` |
| `INC-PAWNS-016` | pawns（敌人威胁档案预设） | 2026-09-25T18:30:17+08:00 | 2026-09-25T18:30:17+08:00 | `090949a` |
| `INC-COMBAT-008` | combat（技能价值标定与威胁轴对齐） | 2026-09-25T18:30:17+08:00 | 2026-09-25T18:30:17+08:00 | `156e055` |
| `INC-TESTING-006` | testing（Build 决策差异证据） | 2026-09-25T18:30:17+08:00 | 2026-09-25T18:30:17+08:00 | `bd1c577` |
| `INC-CROSS-015` | cross（含 world / ui / core / testing 子 Increment） | 2026-09-25T18:52:41+08:00 | 2026-09-25T18:52:41+08:00 | `f7d1cc4`、`5646769`、`d4b8cd3`、`6f15121`、`e2a0594` |
| `INC-WORLD-001` | world（遭遇定义与秘境遭遇目录） | 2026-09-25T18:52:41+08:00 | 2026-09-25T18:52:41+08:00 | `f7d1cc4` |
| `INC-WORLD-002` | world（遭遇会话起局 / 换敌 / 结算） | 2026-09-25T18:52:41+08:00 | 2026-09-25T18:52:41+08:00 | `5646769` |
| `INC-UI-014` | ui（遭遇选择面板） | 2026-09-25T18:52:41+08:00 | 2026-09-25T18:52:41+08:00 | `d4b8cd3` |
| `INC-CORE-008` | core（主场景遭遇路由与引用刷新） | 2026-09-25T18:52:41+08:00 | 2026-09-25T18:52:41+08:00 | `6f15121` |
| `INC-TESTING-007` | testing（遭遇闭环自动化证据） | 2026-09-25T18:52:41+08:00 | 2026-09-25T18:52:41+08:00 | `e2a0594` |
| `INC-CROSS-016` | cross（含 pawns / world / ui / core / testing 子 Increment） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:54:11+08:00 | `8fe713b`、`5ee2549`、`7b8f1b1`、`9fefcaa`、`b16efb2`、`8880733` |
| `INC-PAWNS-017` | pawns（秘境 Boss 敌人档案） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:53:44+08:00 | `8fe713b` |
| `INC-WORLD-003` | world（秘境房间链定义） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:53:44+08:00 | `5ee2549` |
| `INC-WORLD-004` | world（DungeonRun 运行时与跨房间资源延续） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:53:44+08:00 | `7b8f1b1` |
| `INC-UI-015` | ui（秘境进度面板） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:53:57+08:00 | `9fefcaa` |
| `INC-CORE-009` | core（主场景秘境接线与入口锁定） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:53:57+08:00 | `b16efb2` |
| `INC-TESTING-008` | testing（秘境贪不贪闭环证据） | 2026-09-25T19:16:10+08:00 | 2026-09-25T18:53:57+08:00 | `8880733` |
| `INC-CROSS-017` | cross（含 sect / pawns / ui / core / world / testing 子 Increment） | 2026-09-25T20:05:25+08:00 | 2026-09-25T20:05:25+08:00 | `c25ffbc`、`8c65ff1`、`9c97ef9`、`626c9c8`、`cc1c2b9`、`224b7f6`、`6f0be8c`、`06200f2` |
| `INC-SECT-001` | sect（宗门设施静态定义与六座设施数据） | 2026-09-25T19:38:41+08:00 | 2026-09-25T19:38:41+08:00 | `c25ffbc` |
| `INC-SECT-002` | sect（SectState 运行时：库存 / 设施等级 / 升级 / 修炼 / 收获） | 2026-09-25T19:38:41+08:00 | 2026-09-25T19:38:41+08:00 | `8c65ff1` |
| `INC-SECT-003` | sect（转化设施：藏经阁参悟 / 炼器房强化 / 丹房炼丹） | 2026-09-25T19:38:41+08:00 | 2026-09-25T19:38:41+08:00 | `9c97ef9` |
| `INC-PAWNS-018` | pawns（运行时 Build 覆盖层） | 2026-09-25T19:38:41+08:00 | 2026-09-25T19:38:41+08:00 | `626c9c8` |
| `INC-UI-016` | ui（宗门面板） | 2026-09-25T19:38:41+08:00 | 2026-09-25T19:38:41+08:00 | `cc1c2b9` |
| `INC-CORE-010` | core（主场景宗门接线与秘境收益入账） | 2026-09-25T19:52:42+08:00 | 2026-09-25T19:52:42+08:00 | `224b7f6`、`7706de2` |
| `INC-WORLD-005` | world（跨对局修士运行时进度延续） | 2026-09-25T20:05:25+08:00 | 2026-09-25T20:05:25+08:00 | `6f0be8c` |
| `INC-TESTING-009` | testing（宗门闭环证据：收益 → 修炼 / 制作 / 强化 → 再战） | 2026-09-25T20:05:25+08:00 | 2026-09-25T20:05:25+08:00 | `06200f2` |
| `INC-CULT-005` | cultivation（突破执行与境界推进） | 2026-09-25T20:16:30+08:00 | 2026-09-25T20:16:30+08:00 | `d9213d2` |
| `INC-PAWNS-019` | pawns（运行时境界覆盖层与突破入口） | 2026-09-25T20:16:30+08:00 | 2026-09-25T20:16:30+08:00 | `ff07dbe` |
| `INC-WORLD-006` | world（跨遭遇延续运行时境界） | 2026-09-25T20:16:30+08:00 | 2026-09-25T20:16:30+08:00 | `dba3f01` |

## 流程版本

| 版本 | 时间 | 变更 |
|---|---|---|
| v5.40 | 2026-09-26T11:50:07+08:00 | 用户验收通过 `INC-COMBAT-012`（条件伤害）与 `INC-PAWNS-023`（玩家技能池扩到 8 个），用户原话「本次验收通过」；代码提交 `f1abebd` / `a963738`，父 Increment `INC-CROSS-021` 子项进度推进到 5/7 已验收，剩余 `INC-WORLD-008` / `INC-TESTING-019`。 |
| v5.41 | 2026-09-26T11:58:09+08:00 | 用户验收通过 `INC-WORLD-008`（秘境问题房间），用户原话「本次验收通过」；代码提交 `a7da57c`，父 Increment `INC-CROSS-021` 子项进度推进到 6/7 已验收，仅剩 `INC-TESTING-019`。 |
| v5.42 | 2026-09-26T12:01:09+08:00 | 启动 `INC-TESTING-019`（Skill × Enemy 交互矩阵）：用确定性驱动对 6 类问题型敌人记录适用 / 不适用技能的通关耗时、剩余生命、灵力消耗，并要求至少 2 组换技能差异；同时显式区分纯数值升级与价值轴变化。 |
| v5.39 | 2026-09-26T02:25:25+08:00 | 完成 `INC-COMBAT-012`（条件伤害：`controlled_bonus_multiplier` 默认 1.0、只作用于 DAMAGE、受控时按 `effect_value × 倍率` 结算）与 `INC-PAWNS-023`（玩家技能池扩到 8 个：破军斩走条件爆发轴、回春术补首个主动回复轴，炼气期仍 2 槽 / C(8,2)=28）：`mcp__godot::validate` 全通过，单套件 unit 8 + integration 10 + catalog 12 + runtime 5 cases 均 0 failures，统一门禁 `RESULT: PASS`（GdUnit4 429 cases / 0 failures、headless 10 suites / 549 assertions），exit 0；计划已回填为 `awaiting_acceptance`，等待用户验收。 |
| v5.45 | 2026-09-26T12:34:31+08:00 | 用户以「本次验收通过」接受父 Increment `INC-CROSS-021`（Skill × Enemy Interaction 验证），7/7 子项（`INC-COMBAT-010` / `INC-COMBAT-011` / `INC-COMBAT-012` / `INC-PAWNS-022` / `INC-PAWNS-023` / `INC-WORLD-008` / `INC-TESTING-019`）全部验证并验收；本轮只补验收记录，不改 `game/` 实现与数值。同时记录本轮复核发现的真实缺口：`game/world/data/dungeons/problem_dungeon.tres`（11 个问题房间 + Boss、含首通技能奖励链）在 `game/` 与 `tests/` 中除测试引用外没有任何游玩入口，`main.tscn` 的 `DungeonRun.default_dungeon` 仍指向 `trial_dungeon.tres`（6 房间、无问题房间），因此 Gate 3 的「遇到问题 → 获得技能 → 再遇到需要该技能的问题」目前只在机制层与数据层成立，尚不能由正常游玩路径自然观察到，已登记为下一阶段最高优先级修补项 |
| v5.44 | 2026-09-26T12:30:44+08:00 | 用户验收通过 `INC-TESTING-019`（Skill × Enemy 交互矩阵），用户原话「本次验收通过」；代码提交 `ec10b0f`，父 Increment `INC-CROSS-021` 7/7 子项全部验收完毕并进入 `awaiting_acceptance`（父级自身仍待用户验收）。 |
| v5.43 | 2026-09-26T12:30:04+08:00 | 完成 `INC-TESTING-019`（Skill × Enemy 交互矩阵）：新增集成层套件用固定 1/60 手工步进跑六类问题房间 × 两个「只差一个技能」的 Build，同配置重复运行逐位相同；6 格中 5 格换技能后差异超出噪声、6 格全部互有胜负、胜出 Build 至少涉及两个不同 id；反向对照验证「纯倍率升级」不是新价值轴（接上定身后排序反转）；危险窗口只有控制技能能取消。`mcp__godot::validate` 通过，单套件连续 5 次 3 cases / 0 failures，统一门禁 `RESULT: PASS`（GdUnit4 441 cases / 0 failures、headless 10 suites / 549 assertions），exit 0；计划已回填为 `awaiting_acceptance`，等待用户验收。 |
| v5.38 | 2026-09-26T02:24:14+08:00 | 用户验收通过 `INC-COMBAT-011`（敌人技能特征差异化 / 问题型敌人），用户原话「本次验收通过」；本批只补验收记录，不改玩法数值与 `game/` 实现；父 Increment `INC-CROSS-021` 子项进度推进到 3/7 已验收，剩余 `INC-COMBAT-012` / `INC-PAWNS-023`（已立项待开发）、`INC-WORLD-008` / `INC-TESTING-019`。 |
| v5.37 | 2026-09-26T02:19:07+08:00 | 按用户指令「接下来增加技能incre开发测试」新建两个父级子 Increment：`INC-COMBAT-012`（**条件伤害**——DAMAGE 技能对处于控制状态的目标按 `controlled_bonus_multiplier` 额外倍率结算，让「先控后打」成为数据表达的连招，默认 1.0 保证既有技能零影响）与 `INC-PAWNS-023`（**玩家技能池扩到 8 个**——破军斩走新引入的条件爆发轴、回春术用既有 HEAL 类型补上首个「主动回复」轴，炼气期仍 2 槽 / C(8,2)=28 组合）；开发顺序 COMBAT-012 → PAWNS-023。 |
| v5.36 | 2026-09-26T02:16:27+08:00 | 完成 `INC-COMBAT-011`（敌人技能特征差异化 / 问题型敌人）：① `PawnData` 新增 `ProblemTag` 七值枚举与 `problem_tag`，六份既有敌人档案各自标上唯一问题标签，`get_skill_value_axis()` 把标签映射到六类技能价值轴；② 新增召唤契约 `summon_minion` / `summon_initial_delay` / `summon_interval` / `summon_max_count` 与 `can_summon()`，新增 `game/combat/summon/summon_scheduler.gd`（RefCounted，与危险窗口调度器同模式，只广播请求不实例化节点）；③ `EncounterSession` 接线增援：`_spawn_reinforcement()` 走既有 `_spawn_unit()`、加入 `_enemy_units`、接 `died` / `skill_cast`、绑定 `AIController` 与玩家目标，终局自动要求「敌方全灭」；④ `CombatEvent` 新增 `SUMMONED`；⑤ 新增敌人档案 `enemy_summoner.tres`（聚魂邪修 / 240HP + 30 护盾 / 远程 150）与 `enemy_summon_minion.tres`（召魂傀 / 60HP）；⑥ 首次修复：初版召唤调度器建在 `has_danger_window()` 之后被 `continue` 短路（召唤者无危险技能导致增援永不生成），改为两个条件独立判断。验证：`mcp__godot::validate` 8 文件全通过；单套件 unit 6 cases / integration 4 + 1 cases 均 0 failures；统一门禁 `RESULT: PASS`（GdUnit4 424 cases / 0 failures、headless 10 suites / 549 assertions）。 |
| v5.35 | 2026-09-26T02:09:20+08:00 | 用户验收通过 `INC-CROSS-019`（1v1 → 1vN Build 玩法验证）及其三个测试入口补强子 Increment（`INC-TESTING-015` 人工轮可控开局 / `INC-TESTING-016` 测试入口聚焦 Build / `INC-TESTING-017` 测试入口自证与敌我标识），用户原话「本次验收通过」；本批只改测试入口装置与记录口径，不改玩法数值与 `game/` 实现。 |
| v5.34 | 2026-09-26T02:01:11+08:00 | 用户验收通过 `INC-CROSS-021` 本轮两个子 Increment：`INC-COMBAT-010`（技能效果扩展 DASH / AOE_DAMAGE / LIFESTEAL，枚举末尾追加、归一化字段、位移不越目标、AOE 每单位一次、吸血按实际伤害回血）与 `INC-PAWNS-022`（技能池扩到 6 个、覆盖六类价值轴、初始装配不变、炼气期仍 2 槽）；`mcp__godot::validate` 全部通过，单套件 integration 8 cases / unit 8 cases / catalog 10 cases 均 0 failures，统一门禁 `RESULT: PASS`（GdUnit4 415 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing），exit 0；父级保持 `in_progress`（2/5），后续按 `INC-COMBAT-011` → `INC-WORLD-008` → `INC-TESTING-019` 顺序推进 |
| v5.33 | 2026-09-26T01:56:11+08:00 | 新建父 Increment `INC-CROSS-021`（**Skill × Enemy Interaction 验证**）：按用户 objective 把下一阶段从「增加技能数量」重定义为「证明不同敌人让不同 Skill 的价值发生变化，玩家据此主动重构 Build」；据此解冻 `INC-CROSS-019` objective §28 里冻结的 AOE / 新技能约束，但保留边界——不同时扩张装备、属性、随机掉落与职业系统；子 Increment：`INC-COMBAT-010`（效果扩展：位移 / 范围 / 吸血）、`INC-PAWNS-022`（技能池扩到六类价值轴）、`INC-COMBAT-011`（问题型敌人）、`INC-WORLD-008`（问题房间）、`INC-TESTING-019`（交互矩阵）；本轮先实现 `INC-COMBAT-010` 与 `INC-PAWNS-022` |
| v5.32 | 2026-09-26T01:52:12+08:00 | 用户验收通过 `INC-CROSS-020`（左键统一操作模型）及其三个子 Increment（`INC-CORE-013` / `INC-UI-019` / `INC-TESTING-018`），并按其拆分提交到 `develop`；本次验收采纳的交互口径是：左键点敌方只做选中并显示信息（不顺手攻击）、移动需先选中玩家自己的单位——两项如需更动另立 Increment |
| v5.31 | 2026-09-26T00:58:00+08:00 | 完成 `INC-CROSS-020` 的三个子 Increment（`INC-CORE-013` / `INC-UI-019` / `INC-TESTING-018`）：① 左键成为唯一世界交互入口——命中任意存活单位（含敌方）即选中并结束分流，空白地只在「玩家单位被选中」时下达 `order_move()`；② 右键收窄为「TARGETING 取消」+「命中敌方下达 `order_attack()`」，删除移动分支，`project.godot` 的 InputMap 与动作名不变；③ 选中敌方时信息卡绑定敌方、`SkillBar` 与 `BuildLoadoutPanel` 解绑隐藏、`OrderLabel` 显示 `指令：-`、`InstructionsLabel` 与 `main.tscn` 静态文案同步；④ 新增 `_watch_selected_pawn_signals()` 让任意被选中单位的资源 / 状态变化刷新 HUD；⑤ 改写旧契约用例 `test_right_click_cancels_without_move_command` 并新增 4 个用例，统一门禁 `RESULT: PASS`（GdUnit4 402 → 406 cases / 0 failures、headless 549 assertions，exit 0）；⑥ 真实窗口 1v2 入口用 `simulate_input`（OS 级鼠标）复核左键选敌方 / 左键移动 / 右键不移动 / 右键攻击；不新增 InputMap 动作、不改玩法数值与 `Pawn` API |
| v5.30 | 2026-09-26T00:47:00+08:00 | 新建 `INC-CROSS-020`（左键统一操作模型）：用户指令「左键选择（人物选择，技能对象选择），移动，而非右键移动，选中敌方时需要显示敌方信息ui」；拆分为 `INC-CORE-013`（输入路由：`_handle_select` 成为唯一左键入口，左键选中任意单位 / 空白地移动，右键不再移动但保留取消瞄准与对敌方普通攻击）、`INC-UI-019`（选中敌方时信息卡绑定敌方、技能栏与 Build 面板解绑，HUD 指令行与操作提示文案同步）、`INC-TESTING-018`（改写 `test_right_click_cancels_without_move_command` 旧契约并新增左键移动 / 选中敌方用例）；不新增 InputMap 动作、不改玩法数值与 `Pawn` API |
| v5.29 | 2026-09-26T00:19:06+08:00 | 完成 `INC-TESTING-017`（测试入口自证与敌我标识）并补齐 `INC-TESTING-015`（人工轮可控开局）记录：① 横幅——测试入口运行时在右下角 Build 面板上方挂 `CanvasLayer(layer=20)` + `PanelContainer` + `Label`，写明 `[测试入口] tests/<文件>` / 场景标题 / `遭遇：<display_name>（<encounter id>） · 敌方 N：<名单>` / 结算后的本局结果，跑 `main.tscn`（F5）时没有这条横幅；② 敌我标识——每次 `encounter_started` 重建 `ScenarioNameplate` 名牌（`敌 · <display_name>` / `玩家 · <display_name>`）并按名单顺序染 `Sprite2D.modulate`（玩家绿，敌人红 / 黄 / 紫 / 青），因此重开后名牌不会丢；③ `get_scenario_report()` 增加 `enemy_names`，人工与自动化读同一字段；④ 体检脚本新增名单 / 横幅 / 名牌断言并统一 TAB 缩进，二次加载还要证明名牌已重建，期间抓到并修掉「横幅只写 display_name 导致体检 FAILURES=3」的真实缺陷；⑤ 新增 `tests/run_scenario.ps1`（名字路由 + `-List` + `-PauseOnStart`，用法错误 exit 2），`tests/README.md` 增加 F5/F6 启动方式对照表与自证口径；⑥ 反向对照证明本次实机反馈的根因是运行入口错位：不传 scene 运行 → `main.tscn` / `encounter_trial_puppet` / 无横幅无名牌 / 宗门与秘境菜单全部可见；入口体检 `FAILURES=0`、统一门禁 `RESULT: PASS`（GdUnit4 402 cases / headless 549 assertions，exit 0）；不新增美术资源、不改 `game/` 与玩法数值 |
| v5.28 | 2026-09-26T00:10:56+08:00 | 新建 `INC-TESTING-017`（测试入口自证与敌我标识）：实机反馈「1v1 / 1v2 / 1v3 与旧傀儡测试看不出区别且没隐藏宗门等 UI」，运行时复核定位为主因——按 F5 跑的是 `main.tscn`（`default_dungeon=trial_dungeon` → 试炼傀儡 + 完整 HUD），只有 F6 运行 `tests/scenario_*.tscn` 才走测试入口；次因是所有 Pawn 共用占位图且无名字标识。本 Increment 给测试入口加运行时测试横幅（入口 id / 场景标题 / 遭遇 display_name / 敌方名单）、给敌我 Pawn 加名牌与配色（挂在 `encounter_started` 上以便重开重建）、给 `get_scenario_report()` 增加 `enemy_names`，并新增 `tests/run_scenario.ps1` 启动封装；不新增美术资源、不改 `game/` 与玩法数值 |
| v5.27 | 2026-09-25T23:52:10+08:00 | 完成 `INC-TESTING-016`（测试入口聚焦 Build）：6 个 `tests/` 入口都只验证 Build，但打开后带出正式入口的完整 HUD（遭遇选择按钮 / 秘境 / 宗门），与本次验收无关且增加误操作面；本 Increment 给 `tests/scenario_entry.gd` 增加 `hide_non_build_panels` 导出参数，入口实例化主场景后只把 `EncounterPanel/Buttons`、`DungeonPanel`、`SectPanel` 的 `visible` 置为 `false`，保留 SkillBar / 信息卡 / Build 面板 / 当前遭遇与结算状态 / 「重新挑战」（人工轮 Round 2 与 Gate 0 重复挑战入口）；刻意不 `queue_free`，避免 `main.gd` 的 `@onready` 引用失效；`verify_scenario_entries.gd` 增加可见性断言；不改变玩法规则与正式入口；入口体检 6 入口 × 2 次 `FAILURES=0`（每项 `HIDDEN=3 VISIBLE=4`）、真实窗口可见控件核对只剩「重新挑战」与 Build 面板、统一门禁 `RESULT: PASS`（GdUnit4 402 cases / headless 549 assertions，exit 0） |
| v5.26 | 2026-09-25T23:07:54+08:00 | 新建 `INC-TESTING-015`（人工轮可控开局）：实测 MCP 桥接启动期间无人操作会让第一局自动失败并写入无效记录，人工入口缺少「就绪后再开始」的控制；本 Increment 给 `tests/scenario_entry.gd` 增加 `pause_on_start` 导出参数与 `-- --pause-on-start` 用户参数识别，入口完成 `SCENARIO_READY` 后调用生产暂停入口 `_set_paused(true)`，玩家按 Space 才恢复实时战斗；不改变玩法规则、不改数值与实现 |
| v5.25 | 2026-09-25T23:01:35+08:00 | 完成 `INC-TESTING-014`（人工轮 CombatEvent 取证）：人工入口 `tests/scenario_build_replay.tscn` 原有 `SCENARIO_READY` 但没有 CombatEvent 落盘，Gate D 的「事件佐证」未绑定人工轮；本 Increment 在 `tests/scenario_entry.gd` 加只读事件记录器（每局结算追加局号 / 遭遇 / 结算 / 时钟 / 装配 / 完整事件行到不入库的 `.mcp/godot-runtime/screenshots/human_replay_events.md`），新增 `entry_ready` 就绪标志避免记录器挂载前结算，并新增 `test/gameplay/human_round_record_test.gd` 覆盖「未结算不写 + 首局落盘 + 第二局追加」；单套件 `2 cases | 0 failures | 0 orphans`，入口体检 6 入口 × 2 次 `FAILURES=0`，统一门禁 `RESULT: PASS`（GdUnit4 401 cases / headless 549 assertions，exit 0）；状态 `awaiting_acceptance`，不新增玩法内容、不改数值与实现 |
| v5.24 | 2026-09-25T23:55:00+08:00 | 完成 `INC-TESTING-013`（Stage 2：1v1 / 1v2 / 1v3 运行时终局收敛与重开清洁证据）：`INC-CROSS-019` §27「技术」退出条件要求「1v1 / 1v2 / 1v3 可稳定运行、同一遭遇可以重复挑战」，复核后确认 1v2 / 1v3 原来只有数据目录用例（`build_test_encounter_catalog_test.gd`）与 `tests/` 入口加载体检（`verify_scenario_entries.gd`），缺真实运行时终局证据，故新增 gameplay 用例 `test/gameplay/build_test_stage2_stability_test.gd`：用正式 `EncounterSession` + 真实 `PlayerController` / `AIController` 把三份遭遇跑到终局（1v1 16.68s 落败、1v2 12.32s 胜利且换目标 2 次、1v3 9.93s 落败），并验证 `restart()` 后满血 / 无定身 / 事件清空 / 无残留单位且能第二次跑到终局；单套件 `2 test cases | 0 failures | 0 orphans`，统一门禁 `RESULT: PASS`（GdUnit4 399 cases / headless 549 assertions，exit 0）；不新增玩法内容、不改数值与实现 |
| v5.23 | 2026-09-25T23:05:40+08:00 | 完成 `INC-CROSS-019` 开发顺序最后一步 `INC-TESTING-011`（Build Replay 实验记录）：新增共用驱动层 `test/tools/build_replay_driver.gd`（真实 `main.tscn` → 关默认秘境 → 跨物理帧走位到定身距离 → 危险窗口 Round 1 不干预 / Round 2 施放定身 → 走到原结算时刻之外确认无补结算）、玩法用例 `test/gameplay/build_replay_loop_test.gd`（2 cases：机制事实 + 跨局不污染与 Failure 4 客观判据）、取证脚本 `test/tools/capture_build_replay_record.gd`（产出 `build_replay_record` md/json，自动段填机制事实、人工段留「待人工」）与人工入口 `tests/scenario_build_replay.tscn`（登记进入口体检）；记录事实 Round 1 `danger_window_opened → skill_cast → skill_hit`（承伤 5.0/40.0）、Round 2 `... → skill_stunned → skill_cancelled`（承伤 0.0/0.0），Failure 4 未触发；单套件 2 cases、取证 `FAILURES=0`、入口体检 `FAILURES=0`（6 入口）、统一门禁 `RESULT: PASS`（GdUnit4 397 cases / headless 549 assertions，exit 0）；不新增 Increment、不改玩法数值 |
| v5.22 | 2026-09-25T22:33:49+08:00 | 完成 `INC-CROSS-019` 开发顺序第 5 步 `INC-TESTING-012`（场景化测试入口拆分到 `tests/`）：新增 `tests/` 目录与 `tests/README.md`（职责边界、入口清单、命令行 / MCP 运行方式）、唯一入口脚本 `tests/scenario_entry.gd`（`scenario_id` / `encounter` / 前置条件导出 + 窗口标题 + `SCENARIO_READY` 报告）与 5 个入口场景（1v1 / 1v2 / 1v3 / Build 切换 / 首通奖励），`game/main/main.tscn` 移出 `INC-WORLD-007` 临时接入的三份试剑遭遇（只剩三份正式遭遇），`test/README.md` 与 `test/gameplay/main_scene_encounter_test.gd` 同步（新增 `buttons.size() == 3`），新增 `test/tools/verify_scenario_entries.gd` 入口体检；入口体检真实窗口 `FAILURES=0`（5 入口 × 2 次），统一门禁 `RESULT: PASS`（GdUnit4 395 cases / headless 549 assertions，exit 0）；不新增 Increment、不改玩法数值 |
| v5.21 | 2026-09-25T22:30:00+08:00 | 完成 `INC-CROSS-019` 开发顺序第 4 步 `INC-UI-018`（最小 Build A/B 切换面板）：新增 `game/ui/build/build_loadout_panel.tscn` + `.gd`（两套固定预设、只读可用性、点击唯一出口 `Pawn.set_active_skill_loadout()`、失败可复核）、`main.gd` 选中绑定与遭遇锁定接线、`main.tscn` 右下角独立锚点实例与 5 条 `ext_resource`；integration 9 cases 通过，统一门禁 `RESULT: PASS`（GdUnit4 395 cases / headless 549 assertions，exit 0），真实窗口三档取证 `FAILURES=0`（含真实鼠标点击切换与 SkillBar 同帧跟随）；不新增 Increment、不改玩法数值 |
| v5.20 | 2026-09-25T22:22:00+08:00 | 增量口径对齐：`INC-WORLD-007` 已实现并把三份试剑遭遇临时接入 `main.tscn` 遭遇面板（本 Increment 的实机入口），按用户「测试入口拆分到 `tests/`，不要都放在 `main` 中」的硬要求，明确由 `INC-TESTING-012` 把这批临时条目移出到 `tests/` 场景入口，并同步 `main_scene_encounter_test.gd` 断言；`INC-WORLD-007` / `INC-TESTING-012` 的范围、验收标准与已知问题同步更新，不新增 Increment、不改玩法数值 |
| v5.19 | 2026-09-25T22:21:30+08:00 | 完成 `INC-CROSS-019` 开发顺序第 3 步 `INC-WORLD-007`（固定 1v1 / 1v2 / 1v3 Build 验证遭遇与首通定身术解锁）：新增三份试剑遭遇、三份敌人档案（镇狱影傀 / 赤拳战修 / 灵弓修者）与两份敌方编组，`EncounterDefinition.first_clear_skill_reward` + `EncounterSession._grant_first_clear_reward()` 在敌方全灭判胜时只解锁不装配（重复通关按 id 去重），`SquadProgressSnapshot` 采集 / 写回已解锁与显式装配的主动技能使 Build B 跨遭遇延续，定身术资源移动到 `game/pawns/data/skills/` 并同步 4 处引用，`game/main/main.tscn` 把三份遭遇接入遭遇面板；单套件 unit 5 / integration 4 cases 通过，统一门禁 `RESULT: PASS`（GdUnit4 386 cases / headless 549 assertions，exit 0），提交 `e591f33` 到 `develop`，状态 `awaiting_acceptance`；1v2 / 1v3 的人工验收仍须等 `INC-UI-018` 与 `INC-TESTING-012` |
| v5.18 | 2026-09-25T22:12:40+08:00 | 按 objective §25「资源结构」把技能资源目录整理纳入 `INC-WORLD-007` 的验收标准与范围：`player_binding_skill.tres` 由 `game/pawns/data/` 移到 `game/pawns/data/skills/`（与 `INC-COMBAT-009` 新增的 `enemy_boss_cleave.tres` 同目录），要求同步更新全部引用并保持既有 unit / integration 用例全绿；不新增 Increment、不改技能数值 |
| v5.17 | 2026-09-25T22:15:00+08:00 | 完成 `INC-CROSS-019` 开发顺序第 1 步 `INC-COMBAT-009`（1v1 战斗问题窗口与轻量 CombatEvent）：新增 `CombatEvent` / `CombatEventLog`（5 字段 + 8 类白名单事件）、`DangerWindowScheduler`（固定周期开窗、控制优先于释放、打断即零伤害）与 Boss 危险技能数据，`EncounterSession` 接线事件记录并把终局判定落地为 1vN「敌方全灭才判胜、玩家单位死亡即失败」；单套件 unit 4 / integration 5 cases 通过，统一门禁 `RESULT: PASS`（GdUnit4 377 cases / headless 549 assertions，exit 0）；按用户指令推送到 `develop` / `a8a3c9e`（未进 `main`），状态 `awaiting_acceptance` |
| v5.16 | 2026-09-25T21:50:38+08:00 | 按外部设计评审意见对 `INC-CROSS-019` 做增量调整（不新增 Increment、不改玩法数值）：① 新增 **Gate 0（技术成立前置门）** 与「Gate 0 → Gate A/B → Gate C/D/E」判定顺序，Gate 0 未成立时人工结论无效；② 修正 `INC-COMBAT-009` 的终局判定为 1vN 语义（敌方全灭才判胜、玩家单位死亡即失败、主目标单独死亡不提前结束），对齐 `INC-PAWNS-020` 与 `encounter_session.gd` 遗留的「终局判定交给 `INC-COMBAT-009` 接线」约定；③ `INC-WORLD-007` 明确 1v3 的第三名敌人必须是 1v1 的同一个核心 Boss，且 1v2 / 1v3 在全灭判胜落地前不得进入人工验收；④ `INC-TESTING-011` 增加 Round 1 / Round 2 危险窗口应对序列的客观对照判据（Round 1 无 `skill_cancelled`、Round 2 必须出现 `skill_stunned` → `skill_cancelled` 且伤害不结算；序列相同即判 Failure 4），并把 Gate D 改为「原话 + 事件佐证」双证据；⑤ 保留三问硬门，另加非门控问题 Q4「如果这次没有拿到新能力，你还会主动再打一轮吗？」。同步更新 `docs/build-gameplay-validation.md` 的 §6 / §8 / §9 / §10 / §13 与新增修订记录 |
| v5.15 | 2026-09-25T21:45:00+08:00 | 按用户 objective 把 `INC-CROSS-019` 从 4v4 Vertical Slice 重定义为 **1v1 → 1vN Build 玩法验证**（Build Gameplay Validation）：唯一问题改为「战斗问题 → 新能力 → 主动 Build 重构 → 再战并改变打法」，单一变量改为「定身术」且第一轮奖励不含灵石 / 装备 / 强化 / 随机掉落，验收口径改为 Gate A~E 与 Failure 1~5，人工提问改为开放式三问并保留原话；子 Increment 重定义为 `INC-COMBAT-009`（1v1 问题窗口 + CombatEvent）、`INC-PAWNS-021`（最小运行时 Skill Loadout，编号因 `INC-PAWNS-020` 已被 4v4 队伍契约占用而顺延）、`INC-WORLD-007`（固定 1v1 / 1v2 / 1v3 遭遇）、`INC-UI-018`（最小 Build A/B 切换面板）、`INC-TESTING-011`（Build Replay 实验记录）、`INC-TESTING-012`（`tests/` 场景入口）；`INC-CORE-012` 按 §3.2 标记 `superseded`，4v4 / 队友 / 队伍 HUD / 多选 / 编队 / 仇恨 / AOE / 技能树等按 objective §28 冻结 |
| v5.14 | 2026-09-25T21:28:47+08:00 | 按评审收紧后的 Gate A / Gate B 口径完成并推送 `INC-PAWNS-020`（`4513e65`，`develop`）：`SquadDefinition` 队伍静态契约（成员 id 唯一、站位数量一致、默认偏移生成）、`SquadResourceSnapshot` / `SquadProgressSnapshot` 按成员 id 捕获与写回、`EncounterDefinition` 新增可选 `enemy_squad` / `player_count`（旧 `enemy_profile` 行为不变）、`EncounterSession` 多单位集合与主单位代理（终局仍单点，团队胜负留给 `INC-COMBAT-009`）；新增 unit 12 / integration 8 / encounter 10 用例，unit 层 20/20 套件与统一门禁 357 cases + 549 assertions `RESULT: PASS`；`main` 保持不动，等待用户验收后再并入 |
| v5.13 | 2026-09-25T21:14:43+08:00 | 按 4v4 玩法验证评审收紧 INC-CROSS-019：父 Increment 拆成 Gate A（技术 Slice）与 Gate B（玩法假设），把「玩家想重构」与「重构后战斗真的发生决策变化」设为两个独立检查点；45 灵石与定身术解锁解耦，Gate B 只重打同一个 4v4 Boss 而不重播 2v2 / 3v3；人工验收从二元「会 / 不会」升级为五问 + 保留原话 + Failure A~D；新增 §5.1 / §12.6 的 `tests/` 场景化测试入口目录规范，并登记 `INC-TESTING-012` |
| v5.12 | 2026-09-25T20:47:54+08:00 | 持久化 `INC-CROSS-019` 4v4 Vertical Slice 设计基线与 7 个子 Increment（`INC-PAWNS-020` / `INC-PAWNS-021` / `INC-COMBAT-009` / `INC-WORLD-007` / `INC-CORE-012` / `INC-UI-018` / `INC-TESTING-011`）；以 `docs/4v4-vertical-slice.md` 为唯一问题硬门，依赖 `INC-CROSS-018` 收尾后按计划顺序开发 |
| v5.11 | 2026-09-25T20:39:32+08:00 | 完成并推送 `INC-UI-017`（`8de54d9`）（信息卡突破入口）：`PawnInfoModel` 用运行时境界覆盖静态档案并派生「突破后容量：功法 / 武器 / 主动 / 被动」预览，`PawnInfoPanel` 新增 `breakthrough_requested(pawn)` 与「突破」按钮（只在修为已满且有下一境界时可用，只发意图不改数值）；为在固定尺寸信息卡内放下新增行，按钮行压到 16px 并把面板最小高度 354 → 366、`BottomLeftDock.offset_top` -370 → -382；unit 15 / integration 10（另含 skill_bar 回归 8）0 failures，真实窗口三档取证 `FAILURES=0`；父 `INC-CROSS-018` 继续开发主场景接线与 gameplay 证据 |
| v5.10 | 2026-09-25T20:17:57+08:00 | 分批完成并推送 `INC-CULT-005`（`d9213d2`）、`INC-PAWNS-019`（`ff07dbe`）、`INC-WORLD-006`（`dba3f01`）：修为达标可原子突破、Pawn 以组件为唯一运行时境界源、秘境换房 / 重开保留境界与容量；三个子项各自独立提交推送，父 `INC-CROSS-018` 继续开发 UI / 主场景 / gameplay 证据 |
| v5.9 | 2026-09-25T20:05:25+08:00 | 完成并验收 `INC-CROSS-017`（最小宗门，MVP-⑤）：六座宗门设施静态定义与数据、SectState 运行时（灵石 / 灵草 / 丹药库存与设施等级）、藏经阁 / 炼器房 / 丹房转化、Pawn 运行时 Build 覆盖层、宗门面板、主场景接线与秘境收益一次性入账，并补齐 `INC-WORLD-005`（同代修士运行时进度跨对局延续）与 `INC-TESTING-009`（真实 main.tscn 闭环证据：收益 → 设施 / 修炼 / 炼丹 / 强化 → 重开再战）；GdUnit4 unit 125 / integration 139 / gameplay 60（324 cases、0 failures）、headless 10 suites / 549 assertions / 0 failing，三档分辨率取证 FAILURES=0 |
| v5.8 | 2026-09-25T19:22:00+08:00 | 按 `docs/project_summary.md` §十七 / §十八 ⑤ 启动 `INC-CROSS-017`（最小宗门，MVP-⑤）：新建 sect 主题与 `agent-plan/sect.md`，登记 `INC-SECT-001`（设施静态定义与六座设施数据）、`INC-SECT-002`（SectState 运行时：灵石 / 灵草 / 丹药库存、设施等级、升级、修炼与灵田收获）、`INC-SECT-003`（转化设施：藏经阁参悟功法 / 炼器房强化武器 / 丹房炼丹）、`INC-PAWNS-018`（运行时 Build 覆盖层，禁止改写静态 `.tres`）、`INC-UI-016`（宗门面板）、`INC-CORE-010`（主场景接线与 `run_finished` 收益入账，含 `main.gd` 只做信号转发的约束）、`INC-TESTING-009`（收益 → 修炼 / 制作 / 强化 → 再战的闭环证据） |
| v5.7 | 2026-09-25T19:16:10+08:00 | 完成并验收 `INC-CROSS-016`（秘境深入，MVP-④ 第二刀）：新增秘境 Boss 档案、`DungeonRoom` / `DungeonDefinition` 房间链与 6 层试炼秘境（奖励 10/15/25/40/60/100，末层镇狱魔君）、`DungeonRun` 状态机（收益累加、战败归零、撤退保留、跨房间生命/灵力延续）、秘境进度面板（继续深入 / 见好就收 / 重新开始）与主场景接线（秘境进行中锁住单场遭遇与重新挑战入口）；GdUnit4 unit 112 / integration 108 / gameplay 52（272 cases、0 failures）、headless 10 suites / 549 assertions / 0 failing；六个子 Increment 逐个单独提交并推送（`8fe713b`、`5ee2549`、`7b8f1b1`、`9fefcaa`、`b16efb2`、`8880733`） |
| v5.6 | 2026-09-25T18:54:11+08:00 | 按 `docs/project_summary.md` §十八 ④ 与 `INC-CROSS-015` 的非范围声明启动 `INC-CROSS-016`（秘境深入，MVP-④ 第二刀）：把「一次遭遇」升级为「房间链 + 灵石收益 + 继续/撤退 + Boss」，拆为 PAWNS-017 Boss 档案 → WORLD-003 房间链定义 → WORLD-004 DungeonRun 运行时（含跨房间资源延续快照）→ UI-015 秘境进度面板 → CORE-009 主场景接线 → TESTING-008 贪不贪闭环证据，要求 `main.gd` 继续只做信号转发 |
| v5.5 | 2026-09-25T18:52:41+08:00 | 完成并验收 `INC-CROSS-015`（秘境遭遇入口，MVP-④ 第一刀）：新增 `EncounterDefinition` 与 3 份秘境遭遇资源（试炼傀儡 / 铁壁傀儡 / 血刃刺客，全部引用 `INC-PAWNS-016` 正式档案、数值零复制）、`EncounterSession` 起局/换敌/结算运行时、左下 Dock 遭遇选择面板与主场景路由；`main.tscn` 移除写死的两个 Pawn 与 8 条静态接线，`main.gd` 只做信号转发与引用刷新；GdUnit4 241 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing，按 WORLD-001 → WORLD-002 → UI-014 → CORE-008 → TESTING-007 拆分提交并回填 hash |
| v5.4 | 2026-09-25T18:33:02+08:00 | 按 `docs/project_summary.md` §十八 ④ 与 `INC-PAWNS-016` 已知问题启动 `INC-CROSS-015`（秘境遭遇入口，MVP-④ 第一刀）：新建世界主题 `agent-plan/world.md`，拆为 WORLD-001 遭遇定义 → WORLD-002 遭遇会话 → UI-014 遭遇面板 → CORE-008 主场景路由 → TESTING-007 闭环证据，要求 `main.gd` 只做信号转发与引用刷新 |
| v5.3 | 2026-09-25T18:30:17+08:00 | 完成并验收 `INC-CROSS-014`（MVP-5 Gameplay 调参）：新增两份敌人威胁档案（铁壁傀儡 520+80/攻16、血刃刺客 140/攻60）而不新增系统，产出「威胁档案 × 三套两槽 Build + 无技能对照」的 12 组终局对照，证明最优 Build 随遭遇改变（长线→生存+控制、爆发→输出+控制、无技能在爆发档案直接战败），并补支配关系证据使「明确错误选择」不依赖评价口径；GdUnit4 210 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing，按 PAWNS-016 → COMBAT-008 → TESTING-006 拆分提交并回填 hash |
| v5.2 | 2026-09-25T18:11:27+08:00 | 完成并验收 `INC-CROSS-013`：Pawn 建立主动技能容量投影，PlayerController/AI/can_cast 全入口拒绝超容量技能，SkillBar 保留全部槽位并将超容量技能置 DISABLED，Q/数字键与 HUD 文案统一遵守容量事实；GdUnit4 207 cases / 0 failures、headless 10 suites / 549 assertions 全通过，按 PAWNS-015 → COMBAT-007 → UI-013 → CORE-007 → TESTING-005 拆分提交并回填 hash |
| v5.1 | 2026-09-25T18:00:42+08:00 | 按建议启动 `INC-CROSS-013`（Build 容量一致性）：采用方案 B，完整技能列表继续用于诊断与展示，Pawn 提供容量投影，超容量技能在 SkillBar / HUD / Controller / AI 全链路禁用；拆为 PAWNS-015、COMBAT-007、UI-013、CORE-007、TESTING-005 |
| v5.0 | 2026-09-25T17:57:16+08:00 | 完成并验收 `INC-CROSS-012` 全部六个子 Increment：三种战术技能数据契约、SELF/ALLY/ENEMY 目标解析、最小 Skill Effect System、目标选择 UI、主场景选择/取消路由与三套 Build 轨迹证据；GdUnit4 192 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing；按 Increment 提交并回填 Git hash |
| v4.9 | 2026-09-25T17:43:37+08:00 | 完成并验收 `INC-UI-012`：SkillSlot 分离 NORMAL / SELECTED / TARGETING 交互状态，SkillBar 按目标类型路由 SELF 直发或 TARGETING，并新增取消清理与 Pawn 合法目标高亮；GdUnit4 unit 87 / integration 67 / gameplay 26（180 cases、0 failures）、headless 10 suites / 549 assertions 全部通过 |
| v4.8 | 2026-09-25T17:35:46+08:00 | 完成并验收 `INC-CROSS-012` 前两个子 Increment：`INC-PAWNS-014`（技能数据契约与御剑斩 / 护体真气 / 定身术三份资源，`65a494d`）与 `INC-COMBAT-005`（SELF / ALLY / ENEMY 目标解析，`df36f24`）；统一门禁 GdUnit4 unit 87 / integration 58 / gameplay 26、headless 10 suites 549 assertions 全通过；`INC-COMBAT-006`、`INC-UI-012`、`INC-CORE-006`、`INC-TESTING-004` 仍为 planned，待后续开发 |
| v4.7 | 2026-09-25T17:31:30+08:00 | 按 `docs/build-mvp.md` 细化并启动 `INC-CROSS-012`：把三种战术技能、Self/Ally/Enemy 目标解析、Damage/Heal/Shield/Stun Effect System、技能目标选择与两槽 Build 战斗差异拆成 6 个可独立验证的 Increment；先启动 `INC-PAWNS-014` 建立技能数据契约与三份技能资源 |
| v4.6 | 2026-09-25T17:17:48+08:00 | 完成 `INC-CROSS-011` 六个子 Increment 并验收落库：多主动技能、SkillSlot 状态读模型、固定技能格、动态 SkillBar/左下 Dock、主场景 1~6/点击接线与真实窗口布局证据；GdUnit4 160 cases、0 failures，headless 549 assertions、0 failing；按 Increment 拆分 6 个功能/测试提交（`200e822`、`70a09f1`、`3938038`、`84d5ef7`、`182190b`、`cecc91d`），随后执行本计划回写提交 |
| v4.5 | 2026-09-25T17:01:58+08:00 | 启动 `INC-CROSS-011`（战斗技能栏与左下角 HUD 布局，来源 `docs/战斗技能ui.md`）：按 pawns → combat → ui → core → testing 顺序登记六个子 Increment，先建立多主动技能数据/命令、冷却与灵力状态读模型和固定 SkillSlot，再实现动态 SkillBar、左下 Dock 与主场景 1~6/点击接线 |
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

### INC-CROSS-018：突破 → Build 重构

- 状态：planned
- 创建时间：2026-09-25T20:11:34+08:00
- 最后修改：2026-09-25T20:39:32+08:00
- 目标：把设计文档定义的核心成长循环补到可运行状态：修为达到阈值后玩家可以显式突破；突破推进运行时境界并扩大 Build 容量；成果在秘境换房 / 重开后仍属于同一代修士；主场景 UI 能展示并完成这一节点。
- 验收标准：
  - 六个子 Increment 全部 `validated`，并且 unit / integration / gameplay 三层按依赖顺序通过。
  - 真实主场景中通过信息卡按钮完成一次突破，突破后境界、Build 容量、技能可用性、宗门境界门槛与修为进度一致。
  - 静态 `PawnData.realm` 与 `RealmDefinition` 资源保持零污染；运行时突破状态不是通过修改共享 `.tres` 实现。
  - 换房 / 重开后新 Pawn 仍保持突破后的境界与容量；不可达境界恢复、未就绪突破、终点境界突破均保持零副作用。
  - 全量门禁 `test/run_tests.ps1 -Layer all` 不出现新增失败；已知的 `sect_panel_test.gd` 孤儿债务单独记录，不作为本批完成依据。
- 范围：`INC-CULT-005`、`INC-PAWNS-019`、`INC-WORLD-006`、`INC-UI-017`、`INC-CORE-011`、`INC-TESTING-010` 的并集。
- 非范围：4v4 战斗 Vertical Slice、境界属性增加公式、突破失败 / 渡劫表现、Build 拖拽编辑、存档落盘、宗门完整经营扩张。
- 依赖：已验收的 `INC-CROSS-009`（修为进度）、`INC-CROSS-010`（容量 / 武器）、`INC-CROSS-013`（容量执行）、`INC-CROSS-017`（宗门成长与运行时 Build 覆盖）。
- 检索证据：2026-09-25T20:11:34+08:00 执行 `git status --short`（空）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）、`git log --oneline -- agent-plan/`（最新 `c22f226`）与 `git grep` 编号检查；六个候选编号均未被占用。
- 风险：若只实现组件推进而不处理 Pawn / 信息卡 / 会话延续，会得到“修为归零但容量和再战回退”的假闭环；因此必须以 `INC-TESTING-010` 的真实主场景证据作为父级验收条件。
- 实现说明：待实现。
- 变更文件：待实现。
- 测试证据：待实现。
- 验证状态：待验证
- 验证时间：待验证
- 已知问题：`test/integration/sect_panel_test.gd` 在目录模式下仍有 288 orphans 的既有测试债务，本批不顺手清理。
- 用户验收：已验收（用户原话「本次验收通过」，2026-09-26）
- 验收时间：2026-09-26T12:34:31+08:00
- Git：`develop` / 子项代码提交 `1f222b6`、`5f5ffeb`、`f1abebd`、`a963738`、`a7da57c`、`ec10b0f`（含 `95df451` 验收记录）
- 备注：4v4 战斗是下一候选父 Increment，仍属于 MVP 缺口；本批完成不等于整个 MVP 完成。

### INC-CROSS-019：1v1 → 1vN Build 玩法验证（Build Gameplay Validation）

- 状态：accepted
- 创建时间：2026-09-25T20:47:54+08:00
- 最后修改：2026-09-26T02:09:20+08:00
- 重定义说明：本父 Increment 原为「4v4 Vertical Slice 玩法验证（Gate A + Gate B）」，2026-09-25T21:45:00+08:00 按用户 objective（`INC-CROSS-019：1v1 → 1vN Build 玩法验证`）重定义为当前的 Build 玩法验证实验；4v4 专用范围（队友、队伍 HUD、多单位选择、编队、仇恨、玩家队伍快照）按 objective §28 冻结延后。原定义原文保留在 Git 历史 `b36e9c0`（`develop`）。
- 目标：用一个最小实验装置回答唯一玩法问题——当玩家在战斗中遇到一个明确的问题、并获得一个可以解决该问题的新技能后，玩家是否会主动重构自己的 Build 并再次进入战斗，而且第二轮真的采用了不同的解决方案。
- 唯一玩法问题：不是「奖励 → 更强 → 再打一遍」，而是「奖励 → 新策略 → 重构 → 新的战斗过程」。判定必须来自玩家原话，不能由自动化断言代替。
- 本 Increment 不验证：4v4、多单位控制、队友养成、秘境规模、宗门内容量、装备系统。
- 实验结构（三阶段）：
  - Stage 1 — 1v1：用 Build A（御剑斩 + 护体真气）面对一个有「危险技能窗口」的敌人；玩家可以赢，但不能完全无脑赢，且危险技能无法被干预。首通 100% 解锁定身术。
  - Stage 2 — 1vN：只有 Stage 1 成立后才进入 1v2 → 1v3；玩家始终只有 1 个 Pawn，敌人是行为角色不同的组合（近战输出 / 远程输出 / 危险技能），用来验证「多目标决策是否让 Build 更有价值」。
  - Stage 3 — Build Replay：用同一 Boss、一致行为模式重打同一问题，观察玩家是否主动使用定身术改变战斗过程。
- Build 差异设计：Build A = 御剑斩 + 护体真气（降低问题造成的损失，被动处理问题）；Build B = 御剑斩 + 定身术（改变问题本身，主动选择何时阻止危险技能）。两者不是 DPS 差异。
- 变量控制：第一轮奖励只有定身术（`game/pawns/data/skills/player_binding_skill.tres`），不得同时给灵石 / 装备 / 强化 / 随机掉落；45 灵石等经济奖励不进入本实验。Build 只做两套固定预设，禁止自动切换，玩家必须主动点击「使用 Build B」。
- Gate 0（技术成立前置门，未通过不得进入人工验收）：1v1 危险窗口可稳定复现；1v2 / 1v3 采用「敌方全灭才判胜、玩家单位死亡即失败」的终局判定；定身可真实打断危险技能（`skill_stunned` → `skill_cancelled` 且该次伤害不结算）；Build A / B 均可加载并当帧影响 SkillBar；同一遭遇可重复挑战且事件序列不跨局污染；`tests/` 场景入口可独立启动。
- 判定顺序（不可颠倒）：Gate 0 技术成立 → Stage 1 判 Gate A / Gate B → Stage 3 判 Gate C / Gate D / Gate E。Gate 0 未成立时人工结论无效，不得记入 Gate A~E；Gate D 必须同时具备玩家原话与 CombatEvent 客观佐证（`skill_cancelled`），两者冲突时以事件序列为准。
- 五个玩法 Gate（全部成立才允许父级 `accepted`）：
  - Gate A：玩家能描述第一轮中的具体战斗问题（不是「挺难的」这类泛化描述）。
  - Gate B：玩家能理解「定身 → 可以解决第一轮的问题」这一关联。
  - Gate C：玩家在没有强制要求的情况下主动选择 Build B。
  - Gate D：第二轮玩家主动使用定身术，并将其用于解决第一轮遇到的问题。
  - Gate E：玩家能够解释为什么第二轮选择这个 Build。
- 失败条件（任一命中则禁止继续扩 Build 系统，必须回到战斗核心重设 Increment）：
  - Failure 1：玩家觉得定身不错，但不想换 Build。
  - Failure 2：玩家换了 Build，但第二轮仍按第一次的方式打。
  - Failure 3：换 Build 的原因是「因为你让我试试」，而不是第一轮的问题。
  - Failure 4：Build A / B 的实际战斗体验几乎完全一样。
  - Failure 5：玩家只关注伤害更高 / 数值更大，不关心技能交互与战术选择。
- 人工验收剧本（三问，开放式提问、保留原话、不得诱导）：① 用 Build A 打完 1v1 → ② 首通获得定身术 → ③ 玩家自行决定是否切换 Build → ④ 用当前 Build 重打同一个 1v1。Q1 第一轮战斗中，你觉得最麻烦的问题是什么？Q2 拿到定身术后，你为什么选择 / 不选择换 Build？Q3 第二次战斗和第一次相比，你具体改变了什么？归档标签为 `ReplayIntent` / `BuildChange` / `Reason` / `PerceivedImpact`，但必须同时保留原话。可附加记录非门控问题 Q4「如果这次没有拿到新能力，你还会主动再打一轮吗？」，该问题不参与 Gate 判定，仍须保留原话。
- 技术验收标准：
  - 1v1 / 1v2 / 1v3 遭遇均可稳定运行，且 1v1 为固定核心 Boss、行为模式在两次对照中保持一致；1v3 的第三名敌人与 1v1 为同一个 Boss。
  - 1vN 终局判定为「敌方全灭才判胜、玩家单位死亡即失败」，主目标单独死亡不提前结束战斗（由 `INC-COMBAT-009` 实现）。
  - 技能可以学习并进入运行时 Loadout；Build A / B 可以切换；定身可以真实改变敌人状态并取消被覆盖的危险技能。
  - 同一遭遇可以重复挑战且不残留上一局单位 / 事件；CombatEvent 可以记录关键行为。
  - `main.tscn` 只保留正式入口职责，测试场景入口拆分到 `tests/`；`test/` 自动化断言与 `tests/` 场景入口边界清晰。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 为 `RESULT: PASS`；自动化只证明机制成立，不得用于推断「玩家是否愿意重构」。
  - 三档分辨率 1152x648 / 1152x720 / 800x720 的布局证据无重叠 / 无溢出；未验收的增量只能停留在工作区或 `develop`，不得进入稳定 `main`。
- 玩法验收标准（硬门）：Gate A~E 全部成立，且人工原话可复核；只要出现任一 Failure 1~5，就必须停止扩内容并回到战斗核心。
- 范围：`INC-COMBAT-009`、`INC-PAWNS-021`、`INC-WORLD-007`、`INC-UI-018`、`INC-TESTING-011`、`INC-TESTING-012` 的并集；`INC-PAWNS-020` 已实现的多单位运行时作为 1vN 数据前置复用。
- 非范围（objective §28 明确禁止）：4v4、队友、队伍 HUD、多单位选择、编队、仇恨系统、复杂 AI、装备系统、随机掉落、多套 Build 保存、Build 编辑器、技能树、五行、AOE、大量新技能 / 敌人 / 职业。
- 推荐开发顺序：`INC-COMBAT-009` → `INC-PAWNS-021` → `INC-WORLD-007` → `INC-UI-018` → `INC-TESTING-011`。每个子 Increment 都不追求完整系统，它们共同组成一个实验装置。
- 依赖：`INC-CROSS-018` 已验收部分（运行时境界 / Build 延续）；设计基线 `docs/build-gameplay-validation.md`。
- 检索证据：2026-09-25T21:50:38+08:00 执行 `git status --short`（工作区干净）、`git diff --unified=0 -- agent-plan/` / `git diff --cached --unified=0 -- agent-plan/`（调整前均为空）、`git log --oneline -- agent-plan/`（HEAD `0f8fb41`）与 `git grep -n -E "INC-(COMBAT-009|WORLD-007|TESTING-011)" -- agent-plan/`；结论：本次只调整已存在且未实现的 `planned` 子 Increment，编号不变、不新增 Increment。历史记录（2026-09-25T21:45:00+08:00）执行 `git status --short`（`INC-PAWNS-021` 的 6 个脚本改动与 2 个新测试文件；`AGENTS.md` 编辑器噪音已还原）、`git diff --unified=0 -- agent-plan/`（读取本批重定义内容）、`git diff --cached --unified=0 -- agent-plan/`（空）、`git log --oneline -- agent-plan/`（`1dbdba5` → `4513e65` → `b36e9c0`）与 `git grep -n -E "INC-[A-Z]+-[0-9]{3}" -- agent-plan/`；`INC-COMBAT-009` / `INC-WORLD-007` / `INC-UI-018` / `INC-TESTING-011` / `INC-TESTING-012` 均为未实现的 `planned`，可安全重定义；`INC-PAWNS-020` 已被 4v4 队伍契约占用并提交，故 objective 中的「最小运行时 Skill Loadout」顺延为 `INC-PAWNS-021`。
- 风险：最大风险是一次引入过多变量（多单位、编队、队伍 HUD、复杂 AI）导致「玩家想再打一轮」无法归因，因此本阶段必须严格禁止 4v4 与队友系统。第二大风险是奖励不纯（定身术 + 灵石同时到账），必须坚持「奖励 = 新能力」单一变量。第三大风险是自动化替代人工结论，必须坚持 Gate A~E 由玩家原话判定。
- 退出规则：任一 Failure 1~5 命中，或人工回答显示玩家只是「被要求换」而不是因为战斗问题换，则禁止继续加技能 / 加秘境 / 加职业，必须回到战斗核心重设 Increment。
- 实现说明：`INC-PAWNS-021`（最小运行时 Skill Loadout）、`INC-COMBAT-009`（1v1 危险技能窗口 + 轻量 CombatEvent）与 `INC-WORLD-007`（固定 1v1 / 1v2 / 1v3 试剑遭遇 + 首通定身术解锁 + 主动技能跨遭遇延续）均已实现并验证通过，等待用户验收；`INC-UI-018`（最小 Build A/B 切换面板）与 `INC-TESTING-012`（`tests/` 场景化入口）均已实现并验证通过：`tests/` 提供 1v1 / 1v2 / 1v3 / Build 切换 / 首通奖励五个可交互入口，`main.tscn` 退回只保留三份正式遭遇（测试专用参数与资源引用全部下沉到 `tests/`）。`INC-TESTING-011`（Build Replay 实验记录）已实现：新增共用驱动层 `test/tools/build_replay_driver.gd`、真实主场景用例 `test/gameplay/build_replay_loop_test.gd`、取证脚本 `test/tools/capture_build_replay_record.gd` 与人工入口 `tests/scenario_build_replay.tscn`，产出 `build_replay_record`（机制事实自动填充，Q1~Q4 原话与 Gate A~E 留待人工轮）。至此 `INC-CROSS-019` 的六个子 Increment 全部落地，人工玩法 Gate 待用户按剧本实机跑一次。`INC-COMBAT-009` 同时把 `EncounterSession` 的终局判定落地为 1vN「敌方全灭才判胜、玩家单位死亡即失败」，为 Stage 2 的 1v2 / 1v3 解锁前提。设计基线 `docs/build-gameplay-validation.md` 随本批新增，`docs/4v4-vertical-slice.md` 标记为冻结延后。
- 变更文件：`test/gameplay/build_test_stage2_stability_test.gd`（含 `.uid`，INC-TESTING-013）、`agent-plan/index` 系列计划文件（`_index.md`、`combat.md`、`pawns.md`、`world.md`、`ui.md`、`core.md`、`testing.md`）、`docs/build-gameplay-validation.md`、`INC-PAWNS-021` 的代码与测试变更，以及 `INC-COMBAT-009` 的 `game/combat/events/`（`combat_event.gd`、`combat_event_log.gd`）、`game/combat/danger/danger_window_scheduler.gd`、`game/pawns/data/skills/enemy_boss_cleave.tres`、`game/shared/resources/pawn_data.gd`、`game/pawns/pawn.gd`、`game/pawns/data/enemies/enemy_dungeon_boss.tres`、`game/world/encounter_session.gd` 与 `test/unit/combat_event_test.gd`、`test/integration/danger_window_combat_event_test.gd`。
- 测试证据：`INC-PAWNS-021` 单套件 unit 7 / integration 4 / capacity 5 cases 全通过；`INC-COMBAT-009` 单套件 unit 4 / integration 5 cases 全通过（危险窗口周期、无控制承伤、定身打断与零伤害、敌方全灭才判胜、玩家死亡判负、重开重置；首轮暴露 `squad_session_test.gd` 玩家死亡判负回归并已修复复跑）；`INC-WORLD-007` 单套件 unit 5 / integration 4 cases 全通过（人数 1/2/3、敌人阵营与场内 id 唯一、奖励只挂 1v1 且只有 `binding_spell`、1v3 复用同一 Boss 实例；首通只解锁不自动装配、无奖励遭遇不发技能、重开清瞬时状态但保留解锁且不重复记账、显式 Build B 跨遭遇仍为「御剑斩 + 定身术」）；统一门禁 `RESULT: PASS`（GdUnit4 386 cases 0 failures、headless 10 suites 549 assertions 0 failing suites、exit 0）。`INC-UI-018` 单套件 integration 9 cases 全通过，并有三档真实窗口取证 `FAILURES=0`（战斗中锁定 / 敌方全灭结算后解锁、真实鼠标点击切换、`SkillBar` 同帧跟随、非交互背景不拦截点击）；`INC-TESTING-012` 入口体检（真实窗口）`FAILURES=0`（5 个入口各加载两次，敌我人数 / 状态 / 定身术解锁 / 窗口标题 / 无残留活动单位全部一致），受影响 gameplay 层 60 cases 0 failures，统一门禁 `RESULT: PASS`（GdUnit4 395 cases 0 failures、headless 10 suites 549 assertions 0 failing suites、exit 0）；`INC-TESTING-011` 单套件 gameplay 2 cases 全通过（`0 errors | 0 failures | 0 orphans`），取证脚本真实窗口 `BUILD_REPLAY_CAPTURE_DONE FAILURES=0`：Round 1 `danger_window_opened → skill_cast → skill_hit`（承伤 5.0 生命 / 40.0 护盾）与 Round 2 `danger_window_opened → skill_cast → skill_stunned → skill_cancelled`（承伤 0.0 / 0.0）序列不同，Failure 4 未触发；首通只解锁不装配、面板切换 `accepted=true` 且技能栏跟随；统一门禁 `RESULT: PASS`（GdUnit4 397 cases 0 failures、headless 10 suites 549 assertions 0 failing suites、exit 0）。`INC-TESTING-013` 单套件 gameplay 2 cases（`0 errors | 0 failures | 0 orphans`）：1v1 / 1v2 / 1v3 均在 10~19 秒内跑到终局（1v2 胜利需打掉两名敌人、`retargets=2`；1v1 / 1v3 为玩家落败），重开后满血 / 无定身 / 事件记录为空 / 无残留单位且能第二次跑到终局；统一门禁 `RESULT: PASS`（GdUnit4 399 cases 0 failures、headless 10 suites 549 assertions 0 failing suites、exit 0）。父级自身的玩法 Gate A~E 证据待人工轮产出。
- 验证状态：部分验证（`INC-PAWNS-021` / `INC-COMBAT-009` / `INC-WORLD-007` / `INC-UI-018` / `INC-TESTING-012` / `INC-TESTING-011` / `INC-TESTING-013` 的机制层、数据层、UI 工具层、测试入口层与 Replay 客观对照验证通过（Gate A~E 待人工轮）；Stage 1 人工玩法 Gate、Stage 2 阵容口径与「玩家是否真的重构 Build」仍待 `INC-TESTING-011` 人工验收）
- 验证时间：2026-09-25T23:55:00+08:00
- 已知问题：`INC-CROSS-018` 的 `INC-CORE-011`、`INC-TESTING-010` 仍为 `planned`；`INC-PAWNS-020` 已推送到 `develop` 但未验收，其多玩家队伍部分按新父级冻结；既有测试债务（`main_scene_sect_test.gd` 324 orphans、`sect_panel_test.gd` 目录模式 288 orphans）与本次无关。
- 用户验收：已验收（用户 2026-09-26T02:09:20+08:00 原话「本次验收通过」）
- 验收时间：2026-09-26T02:09:20+08:00
- Git：`INC-PAWNS-021` 已提交到 `develop` / `4e92091`；`INC-PAWNS-020` 已在 `develop` / `4513e65`；`INC-COMBAT-009` 已在 `develop` / `a8a3c9e`；`INC-WORLD-007` 已在 `develop` / `e591f33`；`INC-UI-018` 已在 `develop` / `1cce5bf`；`INC-TESTING-012` 已在 `develop` / `fd3eda8`；`INC-TESTING-011` 已在 `develop` / `d6bd273`；`INC-TESTING-013` 已在 `develop` / `6d7b388`
- 调整记录（2026-09-26T02:09:20+08:00）：用户验收通过本父 Increment——用户原话「本次验收通过」。本批补强集中在人工轮可用性（`INC-TESTING-015/016/017`），Stage 2 的 1v1 / 1v2 / 1v3 终局收敛、Build Replay 对照与 CombatEvent 取证均在上一轮交付；本 Increment 不再新增实现，只落验收结论。
- 调整记录（2026-09-25T23:55:00+08:00）：新建并完成 `INC-TESTING-013`（Stage 2 运行时终局收敛与重开清洁证据）——复核 §27「技术」退出条件后发现 1v2 / 1v3 只有数据目录用例与 `tests/` 入口加载体检，缺真实运行时终局证据，故补一个 gameplay 用例：用正式 `EncounterSession` + 真实控制器把三份遭遇跑到终局（不得用 `take_damage()` 抹敌人伪造结果），断言包含「胜 = 敌方全灭」「终局写进 CombatEvent」「重开清洁且能再打一局」，并顺手把「手工步进下 `move_and_slide()` 位移由引擎物理步给出」这条陷阱写进 `test/README.md`；不新增玩法内容、不改数值与实现。
- 调整记录（2026-09-25T23:05:40+08:00）：完成 `INC-CROSS-019` 开发顺序最后一步 `INC-TESTING-011`（Build Replay 实验记录）——① 驱动层与用例分离：`test/tools/build_replay_driver.gd` 是唯一驱动实现，用例与取证脚本共用，避免两份对照代码漂移；② 两轮可比条件锁定为「站位与时机相同」：先跨物理帧用真实 `PlayerController` 走到定身施放距离（走位期间不推进会话，时间原点留在战斗开始），Round 1 不干预、Round 2 施放定身；③ 客观判据按 `docs/build-gameplay-validation.md` §6 落地（Round 1 不得出现 `skill_cancelled`；Round 2 必须 `skill_stunned` → `skill_cancelled` 且伤害不结算；两轮序列相同即 Failure 4）；④ 承伤与时长只作对照数据，明确不写成通过条件；⑤ 记录分「自动机制事实」与「人工原话 / Gate 结论」两段，人工段保留 `待人工` 占位，自动化不得代填；不新增 Increment、不改玩法数值。
- 调整记录（2026-09-25T22:33:49+08:00）：完成 `INC-TESTING-012` 并补齐 `INC-UI-018` 的提交回写——① 场景化测试入口下沉到 `tests/`：唯一入口脚本 `tests/scenario_entry.gd` + 5 个入口场景，测试专用节点 / 参数 / 资源引用不再进入 `main.tscn`，`main.tscn` 移出 `INC-WORLD-007` 临时接入的三份试剑遭遇与 3 条 `ext_resource`，只剩三份正式遭遇；② 入口只做「状态摆放」，不复制战斗 / 奖励 / Build 规则，规则仍只在 `game/` 下，人工结论只能由人给出；③ 新增入口体检脚本作为提交前手工步骤（`--headless` 的 dummy 窗口固定 64x64，不足以核对布局与窗口标题），并把 `test/` 与 `tests/` 的职责边界写进两份 README 与 `AGENTS.md` §5.1 / §12.6；不新增 Increment、不改玩法数值。
- 调整记录（2026-09-25T22:30:00+08:00）：完成 `INC-UI-018` 并把它接入主场景——① 面板只提供「两套固定预设 + 一次点击」，可用性与「当前 Build」全部由 `Pawn` 只读 API 推导，点击是唯一状态变更出口（`Pawn.set_active_skill_loadout()`），失败写入可复核原因并广播；② 首通只让 Build B 变「可切换」，禁止任何自动装配（Gate C 的机制前提）；③ 主场景沿用 `EncounterPanel.set_restart_locked` 的既有外部锁模式：开局锁定、`encounter_finished` 解锁，避免战斗中途换 Build 污染实验时序；④ `main.tscn` 新增节点放在右下角独立锚点，不改已经超宽的 `BottomLeftDock`；不新增 Increment、不改玩法数值。
- 调整记录（2026-09-25T22:21:30+08:00）：本轮不新增 Increment，只把 `INC-WORLD-007` 的实现口径补齐为可验收状态——① 明确「重开不残留」只约束瞬时战斗状态与事件记录，已解锁技能与显式装配的 Build 属于本代修士进度必须延续（否则 Stage 3「换 Build 再战」在机制上不成立）；② 为实现该口径把两处必要接线纳入本 Increment（`EncounterDefinition` 首通奖励字段 + `EncounterSession` 胜利结算发放、`SquadProgressSnapshot` 主动技能采集 / 写回 + `Pawn` 装配状态只读查询）；③ 三份试剑遭遇接入 `game/main/main.tscn` 遭遇面板作为实机入口，`main_scene_encounter_test.gd` 同步放宽为「至少一侧为正式档案且敌人数与站位一致」以兼容 `enemy_squad` 遭遇；④ 奖励口径不变：首通只给 `player_binding_skill.tres`，不含灵石 / 装备 / 强化 / 随机掉落。
- 调整记录（2026-09-25T21:50:38+08:00）：按外部设计评审意见做 5 处增量调整（只改计划与设计基线，不新增 Increment、不改玩法数值）：① 新增 Gate 0（技术成立前置门）与「Gate 0 → Gate A/B → Gate C/D/E」判定顺序；② `INC-COMBAT-009` 终局判定修正为 1vN 全灭判胜（对齐 `INC-PAWNS-020` 与 `game/world/encounter_session.gd` 注释中的既有约定）；③ `INC-WORLD-007` 明确 1v3 第三名敌人 = 1v1 同一个 Boss，且 1v2 / 1v3 在全灭判胜落地前不得进入人工验收；④ `INC-TESTING-011` 增加 Round 1 / Round 2 危险窗口应对序列的客观对照判据，并把 Gate D 改为「原话 + 事件佐证」双证据；⑤ 保留三问硬门，新增非门控问题 Q4。
- 备注：本父 Increment 只有把「4v4 Vertical Slice」重定义为「Build Gameplay Validation」这一件事，它验证的是**Build 是否值得继续做**，而不是秘境 / 宗门 / 队伍系统是否完整。闭环成立之后，`1vN → NvN → 4v4` 才是逐步增加 Build 决策空间，而不是在猜玩法。

### INC-CROSS-020：左键统一操作模型（选择 / 移动 / 敌方信息）

- 状态：accepted
- 创建时间：2026-09-26T00:45:00+08:00
- 最后修改：2026-09-26T01:48:20+08:00
- 来源：用户 2026-09-26 指令「先将操作进行修改，左键选择（人物选择，技能对象选择），移动，而非右键移动，选中敌方时需要显示敌方信息ui」。
- 目标：把鼠标操作收敛成一套不需要记忆的模型——左键同时承担「选中单位 / 选择技能目标 / 移动」，右键不再负责移动；被选中的敌方单位立刻显示自己的信息 UI，而不是点击后无反应。
- 子 Increment：`INC-CORE-013`（输入路由与选中模型）、`INC-UI-019`（选中敌方时的信息 UI 口径）、`INC-TESTING-018`（输入模型测试矩阵）。
- 验收标准（父级）：
  - 左键点击己方单位 → 选中；左键点击空白地 → 已选中的玩家单位移动过去。
  - 左键点击敌方单位 → 选中该敌方并显示其信息 UI（信息卡 + HUD 选中行），且不产生任何攻击 / 移动副作用。
  - 技能目标选择期间左键点击合法目标仍然只确认一次技能命令（`INC-CORE-006` 契约不回归）。
  - 右键不再产生移动命令；右键保留「取消瞄准」与「对敌方下达普通攻击」的既有能力。
  - 上述四条都有自动化证据，并有真实窗口的 MCP 冒烟证据。
- 非范围：多单位选择与 Shift 编队（`INC-CORE-012` 已按 4v4 冻结退役）、右键菜单、悬停提示、地面点击特效、手柄 / 键位重绑定、4v4 输入模型（`docs/4v4-vertical-slice.md` 保持冻结历史文档）、美术表现。
- 依赖：`INC-CORE-001`（InputMap 与主场景输入入口）、`INC-CORE-006`（技能目标选择路由）、`INC-CORE-004`（信息卡路由）、`INC-UI-007` / `INC-UI-008` / `INC-UI-009`（信息卡与敌方空态）、`INC-UI-011`（技能栏）、`INC-UI-018`（Build 面板）、`INC-PAWNS-020`（1vN 多条敌人，任意敌人可被选中）。
- 判定顺序：先 `INC-CORE-013`（路由）→ 再 `INC-UI-019`（UI 口径）→ 最后 `INC-TESTING-018`（测试矩阵）；三者验证通过后父级才进入 `awaiting_acceptance`。
- 检索证据：2026-09-26T00:42+08:00 在仓库根目录执行 `git status --short`（`develop...origin/develop`，工作区含 `INC-TESTING-015/016/017` 未提交改动与若干非本 Increment 改动：`AGENTS.md`、`project.godot`、`game/world/data/dungeons/trial_dungeon.tres`、`test/gameplay/build_decision_differentiation_test.gd`、部分 `tests/*.tscn` 的 UID 重存）、`git diff --unified=0 -- agent-plan/`（新增行仅涉及 `INC-TESTING-015/016/017`）、`git grep -n -E "INC-CROSS-020|INC-CORE-013|INC-UI-019|INC-TESTING-018" -- agent-plan/`（无命中，编号未占用）；结论：本次是独立于 `INC-CROSS-019` 的新父 Increment，不得与 019 的未验收改动混提。
- 风险：最大风险是「一条左键承担三种语义」出现串台（点敌人却下达攻击 / 点地面却只改选中）；第二风险是右键能力收窄造成静默失效；第三风险是敌方单位缺少 HUD 订阅导致信息看起来静止。三者分别由 `INC-CORE-013` 的分流实现、`INC-CORE-013` 的 `order_move()` 调用点收敛与 `INC-TESTING-018` 的用例矩阵兜底。
- 实现说明：
  - 三个子 Increment 一次落地但职责分明：`INC-CORE-013` 负责「左键单入口 + 右键收窄 + HUD 订阅」，`INC-UI-019` 负责「选中敌方时的面板绑定与文案口径」，`INC-TESTING-018` 负责把新契约锁进用例矩阵。生产代码只落在 `game/main/main.gd` 与 `game/main/main.tscn`，UI 组件（`PawnInfoPanel` / `SkillBar` / `BuildLoadoutPanel`）本身零改动。
  - 关键设计决策一：左键点敌方**只做选中**、不下达攻击命令。理由是用户的原始需求把「选择」和「显示敌方信息」绑在一起，若同一次点击顺手发攻击，玩家就无法只查看敌人；普通攻击因此保留在右键（本次只收窄「移动」）。
  - 关键设计决策二：命令前置条件收敛为 `_can_command_player()`（玩家单位被选中且存活），因此移动与攻击都不会因为「当前看的是敌人」而误发到玩家单位上。
  - 关键设计决策三：玩家专属面板（技能栏 / Build 面板）以 `pawn == player_pawn` 为唯一判据，而不是按 `faction` 判断。这样即便将来出现友方单位（`faction == player`），也不会出现「技能栏绑定到别人、点了没反应」的静默死路。
  - 未触碰 `project.godot`（该文件当前另有非本 Increment 的未提交改动），InputMap 动作与物理按键完全不变。
- 变更文件：
  - `game/main/main.gd`
  - `game/main/main.tscn`
  - `test/gameplay/main_scene_skill_targeting_test.gd`
  - `agent-plan/_index.md`、`agent-plan/core.md`、`agent-plan/ui.md`、`agent-plan/testing.md`
- 测试证据：
  - 静态校验：`mcp__godot::validate` 校验 `game/main/main.gd` 与 `test/gameplay/main_scene_skill_targeting_test.gd` → `valid: true`、`errors: []`。
  - 统一门禁：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 406 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing suites，exit 0；改动前 402 cases）。
  - gameplay 输入路由用例：左键点己方 / 左键点地面移动 / 左键点敌方选中并绑定敌方信息卡 / 右键不再移动 / 右键点敌方仍攻击，共 5 个用例。
  - 真实窗口冒烟：`tests/scenario_build_test_1v2.tscn` 下左键点敌方 → 信息卡绑定 `赤拳战修`、技能栏解绑隐藏、`指令：-`、控制器指令无副作用；左键点第二名敌人 `灵弓修者` → 信息卡跟随；左键点地面 → `指令：移动到 (320, 520)`；右键点地面 → 指令不变；右键点敌方 → `指令：攻击 赤拳战修`。
  - OS 级鼠标输入（MCP `simulate_input`）：左键点敌方 (788,589) 后 `Main._selected_pawn` 变为 `EnemyPawn`，左键点己方 (1926,907) 变回 `PlayerPawn`，左键点地面 (708,1151) 得到 `移动到 (320, 520)`，右键点另一处地面 (1550,332) 不改指令。
  - 可见控件清单（`get_ui_elements`）：敌方选中态下可见项无 `SkillBar`、`BuildLoadoutPanel` 显示 `未绑定单位` 且按钮 disabled、信息卡只有 `气血 200 / 200` 与 `护体 20 / 20`（无灵力行）。
  - 截图：`.mcp/godot-runtime/screenshots/screenshot_1790354832_205.png`（2560x1434，`.mcp/` 不入库）。
- 验证状态：验证通过
- 验证时间：2026-09-26T00:57:00+08:00
- 已知问题：
  - 移动命令仍要求玩家自己的单位处于选中态，选中敌方后需先点回自己才能移动（沿用既有契约）；若要改成「点地面无条件移动玩家」，另立 Increment。
  - 普通攻击的鼠标入口只剩「右键点敌方」；用户若希望左键点敌方也直接攻击，需要显式放弃「点敌方只看信息」的语义，另立 Increment 决策。
  - `docs/4v4-vertical-slice.md` 第 121~125 行仍是冻结的 4v4 输入设计原文（左键选择 / 右键移动），本次未同步，属非范围。
  - 用户侧 Godot 编辑器在验证期间保持打开（PID 26484）；若编辑器再次保存 `main.tscn`，`InstructionsLabel` 静态文案可能被内存中的旧值覆盖，提交前需要复核该行。
  - 既有 orphan 债务（gameplay 324 / integration 288）与门禁 stderr 噪音与本 Increment 无关。
- 用户验收：已验收
- 验收时间：2026-09-26T01:48:20+08:00
- Git：`develop` / 子项代码提交 `1f222b6`、`5f5ffeb`、`f1abebd`、`a963738`、`a7da57c`、`ec10b0f`（含 `95df451` 验收记录）
- 备注：本父 Increment 只改玩家与鼠标之间的输入层契约，不改战斗 / 技能 / 奖励 / 敌人 AI；`docs/4v4-vertical-slice.md` 的第 121~125 行仍是已冻结的 4v4 设计原文，如需让该文档跟随本次变更，另立文档类 Increment。

## INC-CROSS-021：Skill × Enemy Interaction 验证

- 状态：in_progress
- 创建时间：2026-09-26T01:56:11+08:00
- 最后修改：2026-09-26T11:58:09+08:00
- 类型：跨主题父 Increment
- 涉及主题：combat / pawns / world / testing
- 目标：回答 CROSS-019 之后真正悬而未决的问题——**当技能数量与敌人行为开始增加时，玩家能否通过技能组合形成有意义的 Build，而不是「哪个技能面板伤害高就装哪个」**。判断标准不是技能数量，而是：不同敌人让不同技能的价值发生变化，且玩家会因为遇到新问题而主动重构 Build。
- 用户原始 objective 摘要：把下一阶段定义为「Skill × Enemy Interaction 验证」而不是「增加技能」；玩家技能控制在 6~8、敌人类型 6~8、核心 Build 3~4 种、秘境房间 10~15 个；**不要同时扩张技能数量、敌人数量、敌人机制、装备与属性系统**；秘境生成应从「随机生成敌人」转向「生成战斗问题」。
- 验收标准（父级 Gate）：
  - Gate 1 技能池：玩家可用技能 ≥ 6 个，且覆盖单体输出 / 防御 / 控制 / 位移 / 范围 / 生存六类价值轴，不出现两个技能回答同一个问题。
  - Gate 2 问题型敌人：≥ 6 类敌人各自对应一个可被特定技能回答的问题（近战压力 / 远程压力 / 蓄力可打断 / 高爆发 / 高防御 / 召唤增援），且问题来自数据而不是文档描述。
  - Gate 3 问题房间：10~15 个秘境房间按问题型组合，链上至少 2~3 次出现「遇到问题 → 获得技能 → 再遇到需要该技能的问题」的因果。
  - Gate 4 客观对照：至少 2 组「仅替换一个技能、客观量（通关耗时 / 灵力消耗 / 剩余生命）差异可复现且超出噪声」的证据。
  - Gate 5 反向对照：两个只差数值的同型技能，其差异被显式排除在「Build 变化」之外，防止把数值升级当成 Build。
  - Gate 6 门禁：统一 `test/run_tests.ps1 -Layer all` → `RESULT: PASS`。
- Failure 条件：做完 6 个技能与 6 类敌人后，玩家仍然只会按面板伤害选技能，或不同敌人对 Build 选择没有可测影响——此时结论应为「当前仍是技能数值系统，不是 Build 系统」，而不是继续堆技能。
- 子 Increment：`INC-COMBAT-010`（技能效果扩展：位移 / 范围 / 吸血，已验收）、`INC-PAWNS-022`（玩家技能池扩到六类价值轴，已验收）、`INC-COMBAT-011`（问题型敌人，含召唤，已验收）、`INC-COMBAT-012`（条件伤害，已验收）、`INC-PAWNS-023`（玩家技能池扩到 8 个，已验收）、`INC-WORLD-008`（秘境问题房间，已验收）、`INC-TESTING-019`（Skill × Enemy 交互矩阵，已验收）。
- 判定顺序：先 `INC-COMBAT-010`（效果能不能表达）→ 再 `INC-PAWNS-022` / `INC-PAWNS-023`（玩家有没有可选项）→ 再 `INC-COMBAT-011` / `INC-COMBAT-012`（敌人是否提出问题 / 控制能否兑现输出）→ 再 `INC-WORLD-008`（问题是否被编排成链）→ 最后 `INC-TESTING-019`（对照是否客观成立）；父级只有在七个子项全部通过验证后才进入 `awaiting_acceptance`。
- 进度：2026-09-26T12:34:08+08:00 用户以「本次验收通过」接受父级 INC-CROSS-021，7/7 子项全部验收；此前 2026-09-26T11:58:09+08:00 用户验收通过 INC-WORLD-008（秘境问题房间），子项进度 6/7——`INC-COMBAT-010` / `INC-PAWNS-022` / `INC-COMBAT-011` / `INC-COMBAT-012` / `INC-PAWNS-023` / `INC-WORLD-008` 均已验收；后续仅剩 `INC-TESTING-019`（Skill × Enemy 交互矩阵）。
- 非范围（保留 CROSS-019 冻结思路，只解冻必要部分）：技能树、技能升级与等级、装备词条与属性膨胀、随机掉落、存档迁移、联网同步、4v4 与队友系统、正式美术与动画、平衡数值定稿。
- 检索证据：2026-09-26T01:56+08:00 在仓库根目录执行 `git status --short --branch`（`develop...origin/develop` 一致，工作区含尚未验收的 `INC-TESTING-015/016/017` 与若干非本次改动）、`git grep -h -o -E "INC-...-[0-9]{3}" -- agent-plan/`（各主题最大编号：COMBAT 009 / PAWNS 021 / WORLD 007 / UI 019 / TESTING 018 / CROSS 020，本批编号均未被占用）；读取 `game/shared/resources/active_skill_definition.gd`（`SkillEffectType` 只有 DAMAGE / HEAL / SHIELD / STUN）、`game/combat/skill/skill_effect_resolver.gd`（单效果分派与「先扣灵力后生效」顺序）、`game/pawns/data/` 下的技能与敌人资源（玩家技能 3 个、敌人档案 6 份）、`game/cultivation/data/realms/qi_refining.tres`（`active_skill_slots = 2`）确认「技能池只有 3 个、效果类型无法表达位移 / 范围 / 吸血、玩家只有 2 个槽位」是当前的真实瓶颈。
- 风险：① 效果扩展会同时改枚举、分派与 Pawn 接口，边界若失控会滑向通用 Buff 系统——必须严格限制为「单效果 + 三类新类型」；② 六技能只有两槽，若出现「任何情况下都不值得装」的技能，说明问题设计重叠，必须靠问题差异化解决而不是加槽位；③ 敌人问题型与房间链两件事同时上会互相掩盖因果，必须按判定顺序串行落地；④ 客观对照容易受 AI 时序影响，必须先解决确定性与噪声阈值。
- 用户验收：已验收（用户原话「本次验收通过」，2026-09-26）
- 验收时间：2026-09-26T12:34:31+08:00
- Git：`develop` / 子项代码提交 `1f222b6`、`5f5ffeb`、`f1abebd`、`a963738`、`a7da57c`、`ec10b0f`（含 `95df451` 验收记录）
- 备注：本父 Increment 取代 `INC-CROSS-019` objective §28 中「冻结 AOE / 大量新技能」的约束（仅就该批解冻），CROSS-019 自身的 1v1 → 1vN 结论不受影响；本项仍遵守「不同时扩张一切」的原则，装备、属性、掉落与存档均保持冻结。
