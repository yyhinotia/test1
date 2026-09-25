# Pawns 主题计划

> 最后修改：2026-09-25T13:42:33+08:00  
> 主题：pawns  
> 规则来源：`../AGENTS.md`

## INC-PAWNS-001：建立 Pawn 基础运行时

- 状态：accepted
- 创建时间：2026-09-25T13:21:58+08:00
- 最后修改：2026-09-25T13:42:33+08:00
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
- 验证时间：2026-09-25T13:42:33+08:00
- 已知问题：当前仅有两个 Pawn；使用直线位移而非网格寻路；占位 SVG 不是最终人物美术。
- 用户验收：已验收
- 验收时间：2026-09-25T13:42:33+08:00
- Git：main / 待记录 commit hash
- 备注：此 Increment 是 `INC-CROSS-001` 的子 Increment。