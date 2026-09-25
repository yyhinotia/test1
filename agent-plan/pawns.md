# Pawns 主题计划

> 最后修改：2026-09-25T13:54:28+08:00  
> 主题：pawns  
> 规则来源：`../AGENTS.md`

## INC-PAWNS-001：建立 Pawn 基础运行时

- 状态：accepted
- 创建时间：2026-09-25T13:21:58+08:00
- 最后修改：2026-09-25T13:43:51+08:00
- 主题：pawns
- 目标：建立可被玩家、敌人和 NPC 复用的 Pawn 静态数据、运行时状态与控制器分离基础。
- 验收标准：
  - `PawnData` 只保存静态配置，`Pawn` 只保存运行时状态。
  - 场景中可同时实例化玩家 Pawn 和敌方 Pawn。
  - Pawn 支持 `IDLE`、`MOVING`、`ATTACKING`、`DEAD` 状态。
  - Pawn 拥有生命、护盾、移动、攻击、受伤和死亡接口。
  - Pawn 本身不读取鼠标输入，也不自行选择玩家/AI 决策。
  - 控制器与 Pawn 分离，玩家和 AI 可以复用同一个 Pawn 场景。
- 范围：`game/shared/resources/pawn_data.gd`、`game/pawns/**`、`game/combat/**` 中与 Pawn 攻击接口直接相关的改动。
- 非范围：境界、功法、灵根、五行、装备、背包、宗门、社交、饥饿、睡眠、复杂 AI、寻路和技能系统。
- 依赖：Godot 4.7.2；项目已有 `icon.svg`；无外部插件。
- 风险：如果 Pawn 承担输入、目标选择或 AI 决策，会退化为 God Object；本 Increment 将决策放入控制器。
- 实现说明：
  - `PawnData` 使用自定义 `Resource` 保存静态配置，`Pawn` 使用 `CharacterBody2D` 保存运行时生命、护盾、位置和状态。
  - `pawn.tscn` 提供 Visual、Collision、HealthBar、Controller、SelectionIndicator 基础结构。
  - `player_pawn.tscn` 和 `enemy_pawn.tscn` 继承基础 Pawn 场景，分别覆盖 `PlayerController` 和 `AIController`。
  - Pawn 不读取输入；主场景只负责把选择、移动和攻击意图交给 `PlayerController`。
  - 场景根节点规范化：pawn.tscn 根节点由 root 改名 Pawn，main.tscn 根节点由 root 改名 Main，去除 MCP 默认节点名，与 MVP 场景结构定义一致。
- 变更文件：
  - `game/shared/resources/pawn_data.gd`
  - `game/shared/core/physics_layers.gd`
  - `game/pawns/pawn.gd`
  - `game/pawns/pawn.tscn`
  - `game/pawns/player_pawn.tscn`
  - `game/pawns/enemy_pawn.tscn`
  - `game/pawns/data/player_pawn.tres`
  - `game/pawns/data/enemy_pawn.tres`
  - `game/pawns/controllers/pawn_controller.gd`
  - `game/pawns/controllers/player_controller.gd`
  - `game/pawns/controllers/ai_controller.gd`
  - `game/pawns/art/pawn_placeholder.svg`
- 测试证据：
  - `validate`：`pawn_data.gd`、`pawn.gd`、三个控制器、`pawn.tscn`、`player_pawn.tscn`、`enemy_pawn.tscn` 全部通过。
  - 运行态脚本读取：玩家控制器为 `player_controller.gd`，敌人控制器为 `ai_controller.gd`；玩家 `data.id` 为 `player_001`，敌人 `data.id` 为 `enemy_001`。
  - 运行态脚本读取：玩家死亡前 `SelectionIndicator.visible = true`，说明选择标识与运行时 Pawn 状态绑定。
  - 运行日志无脚本解析错误、节点缺失或信号断链错误。
  - 复验（场景结构）：pawn.tscn 实例化后根节点名为 Pawn，子节点为 Visual(Node2D) > Sprite2D、Collision(Node2D) > CollisionShape2D、HealthBar(Control)、SelectionIndicator(Line2D)、Controller(Node)，与 MVP 要求的场景结构逐项一致。
  - 复验（控制器分离）：运行态读取玩家控制器脚本为 player_controller.gd、敌人控制器为 ai_controller.gd，两者复用同一个 pawn.tscn 基础场景。
  - 复验（静态验证）：9 个脚本、4 个场景与主场景信号检查全部 valid=true，errors 为空。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:43:51+08:00
- 已知问题：当前仅有两个 Pawn；使用直线位移而非网格寻路；占位 SVG 不是最终人物美术。
- 用户验收：已验收
- 验收时间：2026-09-25T13:43:51+08:00
- Git：分支 main，commit d7c2e1e（feat(pawns): add pawn MVP with movement, combat, HUD and pause [INC-CROSS-001]）
- 备注：此 Increment 是 `INC-CROSS-001` 的子 Increment。

## INC-PAWNS-002：Pawn 生命状态变化统一入口与血条挂载结构

- 状态：accepted
- 创建时间：2026-09-25T13:54:28+08:00
- 最后修改：2026-09-25T14:09:39+08:00
- 主题：pawns
- 目标：让 Pawn 提供唯一的“生命状态变化”入口，使血条显示与伤害、护盾、死亡解耦，并把血条改为“独立场景 + 头顶锚点”的可复用结构。
- 验收标准：
  - `Pawn.notify_health_state_changed()` 是生命状态变化通知血条的唯一入口，`take_damage()` 与 `die()` 都通过它。
  - Pawn 场景结构为 `HealthBarAnchor(Node2D) > HealthBar(pawn_health_bar.tscn 实例)`，不再内联血条节点与血条脚本。
  - 初始血条隐藏；伤害、护盾变化、死亡后同一帧显示。
  - 对外信号 `health_changed` / `shield_changed` / `state_changed` / `died` 的参数与时序不变，HUD 与 `main.tscn` 连接不受影响。
  - 不引入解析错误、场景加载错误和信号断链；`player_pawn.tscn`、`enemy_pawn.tscn` 实例仍可正常加载。
- 范围：`game/pawns/pawn.gd`、`game/pawns/pawn.tscn`。
- 非范围：HealthComponent 抽取（`INC-PAWNS-003`）、治疗/护盾/吸血技能、分层生命（护体灵力/真元/气血/元神）、寻路与 AI 决策。
- 依赖：`INC-PAWNS-001`、`INC-UI-002`。
- 风险：节点路径由 `Pawn/HealthBar` 变为 `Pawn/HealthBarAnchor/HealthBar`，会影响继承该场景的 `player_pawn.tscn` / `enemy_pawn.tscn`；本次在静态验证与运行态断言中一并检查新路径。
- 实现说明：
  - Pawn 新增 `notify_health_state_changed()`，作为生命状态变化通知血条的唯一入口；`take_damage()` 与 `die()` 都通过它刷新，对外信号 `health_changed` / `shield_changed` / `state_changed` / `died` 的参数与时序保持不变。
  - `pawn.tscn` 移除内联血条节点，改为 `HealthBarAnchor(Node2D, position = (0, -46))` + `pawn_health_bar.tscn` 实例（节点名 `HealthBar`），`pawn.gd` 使用 `$HealthBarAnchor/HealthBar`。
  - 血条节点保留 `PROCESS_MODE_INHERIT`，继承 Pawn 的 `PROCESS_MODE_PAUSABLE`，使暂停时隐藏计时冻结。
- 变更文件：
  - `game/pawns/pawn.gd`
  - `game/pawns/pawn.tscn`
- 测试证据：
  - 替代原因：本会话 Godot MCP 不可用（工具调用返回 `unsupported call`），按 `AGENTS.md` §6 改用 Godot 4.7.2 CLI headless 验证。
  - headless 断言（`test/headless/health_bar_visibility_test.gd`，退出码 0，`CHECKS=38 FAILURES=0`）：`Pawn/HealthBarAnchor/HealthBar` 路径存在、内联 `HealthBar` 已移除、锚点位置为 (0, -46)、血条全局位置符合锚点 + (-36, -8)、`player_pawn.tscn` 实例化后信号与 `@onready` 引用正常、护盾变化与死亡均经统一入口触发血条。
  - 主场景冒烟：`godot --headless --path . --quit-after 600` → 退出码 0，无脚本错误、节点缺失或信号断链；`player_pawn.tscn` / `enemy_pawn.tscn` 继承结构未受影响。
  - 多分辨率复验（AGENTS.md §5.4，真实窗口渲染）：16:9（1152x648）、16:10（1152x720）、窄屏（窗口 800x720 → 逻辑视口 1152x1036）三档下 `HealthBarAnchor/HealthBar` 的全局矩形均为 `(834,356,72,16)`，`BAR_CENTER.x` 与 Pawn 全局 x 完全一致（870），血条始终位于 Pawn 头顶且在逻辑视口内；证明锚点结构在 `canvas_items + expand` 拉伸下不随分辨率漂移。
  - 复跑（验收前最终一轮）：`test/headless/health_bar_visibility_test.gd` 退出码 0、`CHECKS=38 FAILURES=0`；主场景冒烟退出码 0。
- 验证状态：验证通过
- 验证时间：2026-09-25T14:09:39+08:00
- 已知问题：Pawn 仍直接持有 `current_health` / `current_shield`，尚未抽取为独立组件；该工作登记为 `INC-PAWNS-003`。
- 用户验收：已验收
- 验收时间：2026-09-25T14:09:39+08:00
- Git：分支 main，commit 待本次提交后回写（见后续 docs(plan) 提交）
- 备注：父 Increment 为 `INC-CROSS-002`。

## INC-PAWNS-003：抽取 HealthComponent（计划中）

- 状态：planned
- 创建时间：2026-09-25T13:54:28+08:00
- 最后修改：2026-09-25T14:02:20+08:00
- 主题：pawns
- 目标：把 Pawn 内的生命/护盾数据与信号抽取为独立 `HealthComponent`，作为多生命层（护体灵力/真元/气血/元神）以及治疗、护盾、持续伤害等状态效果的单一数据源。
- 验收标准：待细化。方向是 `HealthComponent` 持有 `current_hp` / `max_hp` / `current_shield` / `max_shield` 与 `health_state_changed` 信号，Pawn 只做转发，HUD 与血条订阅同一信号源，并复跑 `INC-PAWNS-002`、`INC-UI-002` 的验收路径。
- 范围：`game/pawns/health_component.gd`（新增）、`game/pawns/pawn.gd`、`game/pawns/pawn.tscn`、`game/main/main.tscn` 信号连接复核。
- 非范围：分层生命的数值设计、状态效果（中毒/灼烧/吸血）实现。
- 依赖：`INC-PAWNS-002`、`INC-COMBAT-001`。
- 风险：会触碰已验收的战斗与 HUD 信号连接，需要独立验证与用户验收，不能与血条显示策略混在同一个 Increment。
- 备注：来源为 `docs/血条ui需求.txt` 的“① HealthComponent”步骤；`INC-CROSS-002` 只实现“②③④⑤”与规则 1-4，未执行该抽取。
