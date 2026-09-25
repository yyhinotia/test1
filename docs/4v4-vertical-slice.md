# 4v4 Vertical Slice 设计

> 状态：accepted（设计基线）  
> 设计时间：2026-09-25T20:43:57+08:00  
> 验收时间：2026-09-25T20:47:54+08:00  
> 父 Increment：`INC-CROSS-019`  
> 输入依据：`docs/project_summary.md` §八（4v4 / 4–8 单位、实时战斗 + 暂停操作）、§十七（MVP 主线）、§十八 MVP Top 5 ②（战斗框架）与 §二十二（先做 4v4 Vertical Slice）；`docs/build-mvp.md` MVP-5（Build → Skill → Combat 闭环）。

## 1. 唯一问题

本阶段不是“把战场人数从 2 扩到 8”的功能扩张。

本阶段只回答：

> **玩家完成第一轮秘境后，会不会因为获得了可用的新功法 / 装备，而主动想重构自己的修士，再打一轮？**

判定规则：

- 答案是“会”，并且玩家能说出想换哪条 Build、为什么换，才允许继续扩内容、职业、秘境和宗门。
- 答案是“不会”，或玩家只看到数值增加而没有真实重构欲望，必须停止加系统，回到战斗核心设计。
- 自动化测试只能证明机制闭环存在，不能替代这个人工玩法验收。

## 2. 阶段目标

用最小内容跑通一条完整链路：

```text
4 人小队
  ↓
暂停指挥 4v4
  ↓
胜负与损耗
  ↓
秘境奖励
  ↓
获得新功法 / 可用 Build 选项
  ↓
重构主角 Build
  ↓
再战一轮
```

必须同时满足：

1. 玩家能选单位、下令、暂停观察、放技能，而不是看 AI 自动打完。
2. 一场战斗确实存在 4 名玩家单位和 4 名敌方单位。
3. 队友阵亡、主角阵亡、敌人全灭是三种不同的战场事实。
4. 第一轮结束后能拿到一个真正改变战斗方式的选择，而不只是 +N 数值。
5. 第二轮必须能用不同 Build 产生不同战斗轨迹。

## 3. 非目标

本阶段明确不做：

- 不做整个秘境都变成 4v4；Vertical Slice 只做 2v2 → 3v3 → 4v4 三段。
- 不做修士招募、队友长期养成、换人、职业树、编队编辑器。
- 不做拖拽式 Build 编辑器；只做“预设战术配置”切换。
- 不做复杂 AI、仇恨表、仇恨值、技能优先级、阵型 AI、路径寻路优化。
- 不做范围伤害、AOE 指示器、持续伤害、Buff/Debuff 堆叠、五行克制。
- 不做存档 / 读档、跨进程迁移、多人联机。
- 不做正式美术、技能特效、音效。
- 不把宗门继续扩成 Colony Sim。

## 4. 玩家体验

### 4.1 主角与队友

Vertical Slice 的队伍固定为 4 人：

| 位置 | 定位 | 运行时来源 |
|---|---|---|
| 主角 | 玩家本人，唯一可重构 Build 的修士 | 现有 `player_pawn.tres` 与运行时进度 |
| 护法弟子 | 护盾 / 生存 | 固定队友档案 |
| 控场弟子 | 定身 / 控制 | 固定队友档案 |
| 剑修弟子 | 输出 | 固定队友档案 |

设计约束：

- 主角身份由 `SectState` 绑定，只有主角的 Build 奖励与重构进入长期循环。
- 队友是本阶段用来验证 4v4 战场结构的固定单位，不进入长期养成。
- 主角阵亡表示本次秘境失败；队友阵亡不等于立即失败。
- 主角存活但队友全部阵亡时，仍可继续战斗到敌人全灭或主角阵亡。

### 4.2 战术操作

保留现有“实时运行 + 暂停操作”方向，第一版只做以下操作：

| 输入 | 行为 |
|---|---|
| 左键点友方单位 | 选中该单位，成为主选中单位 |
| Shift + 左键 | 加入 / 移出多选 |
| Ctrl + A / 新增 `select_all` | 选中全部存活玩家单位 |
| 右键地面 | 所有选中单位按简单阵型偏移移动到目标点 |
| 右键敌方单位 | 所有选中单位集火该目标 |
| 空格 | 暂停 / 恢复；暂停时允许观察、选单位和下令 |
| 1~6 / Q | 主动技能只作用于当前主选中单位 |
| 点击队伍卡 | 切换主选中单位 |

不做的操作：

- 不编队（1/2/3 号队伍）。
- 不做技能队列与多单位技能编排。
- 不做拖拽框选；先用 `Ctrl + A` 与 Shift 多选验证玩法。
- 不做单位朝向、掩体、高低差。

### 4.3 第一轮：不能“轻松自动赢”

第一轮使用初始 Build：

```text
御剑斩 + 护体真气
```

战斗分为三间：

| 房间 | 规模 | 敌人 | 考验 |
|---|---|---|---|
| 第一间 | 2v2 | 试炼傀儡小队 | 认识多单位移动与集火 |
| 第二间 | 3v3 | 铁卫巡队 | 生存、护盾与持续输出 |
| 第三间 | 4v4 | 镇狱小队 + Boss | 目标优先级、暂停决策、技能时机 |

要求：

- 初始 Build 能通关，但不应干净无伤。
- 第三间必须有至少一个危险输出窗口，让“定身”与“护盾”产生不同价值。
- 战斗过程必须能被记录：谁先死、何时暂停、何时放技能、最终剩余生命。

### 4.4 奖励与 Build 重构

第三间 Boss 首次通关固定获得：

- 解锁 `player_binding_skill.tres`（定身术）为**已掌握技能**。
- 灵石奖励总计至少 45，保证玩家可以做一次炼器房强化或藏经阁选择。

通关后的 Build 选择不做自由拖拽，只提供两个预设：

```text
配置 A：御剑斩 + 护体真气     （输出 + 生存）
配置 B：御剑斩 + 定身术       （输出 + 控制）
```

设计原因：

- 配置 A 与 B 都已经有真实技能效果，不需要新 Effect System。
- 定身术能改变 Boss 的行动窗口，而不是只改伤害数字。
- 玩家仍可选择把灵石花在炼器房强化武器，或保留灵石给后续宗门升级；Build 重构与资源分配都是真实选择。

### 4.5 第二轮：证明“重构有意义”

第二轮至少满足一个可观察差异：

- 定身术使 Boss 的某次危险输出被延后或跳过。
- 玩家承受的总伤害明显下降。
- 击杀顺序或战斗时长出现可解释的变化。
- 玩家在复盘时能说出“因为第一轮 Boss 的危险窗口，所以第二轮换了控制”。

不要求第二轮一定“更强通关”；要求的是不同 Build 产生不同过程。

## 5. 系统设计

### 5.1 `SquadDefinition`

新增静态资源：

```text
SquadDefinition
  id
  display_name
  members: Array[PawnData]         # 1..4，id 唯一
  default_spawn_offsets: PackedVector2Array
```

职责：

- 只描述静态成员与默认站位。
- 不持有运行时生命、冷却、境界或 Build 状态。
- `is_configured()` 校验成员数量、空成员、重复 id 与偏移合法性。
- 偏移不足时由运行时给出安全默认阵型，不隐式改写资源。

### 5.2 `EncounterDefinition` 扩展

保留现有单敌人契约作为兼容路径：

```text
enemy_profile: PawnData             # 旧字段，1v1 继续可用
enemy_squad: SquadDefinition        # 新增；非空时优先
player_count: int                   # 0 = 按敌人数量取玩家队伍前 N 人
```

兼容规则：

- `enemy_squad` 为空时，`get_enemy_members()` 返回 `[enemy_profile]`。
- `player_count == 0` 时，按敌人数量取玩家队伍前 N 人。
- 旧的单敌人测试与 `trial_dungeon.tres` 必须继续加载与通过。

### 5.3 多单位会话

`EncounterSession` 由单 Pawn 扩展为数组：

```text
_player_units: Array[Pawn]
_enemy_units: Array[Pawn]
_owned_units: Array[Pawn]
```

兼容入口：

```text
get_player_units() -> Array[Pawn]
get_enemy_units() -> Array[Pawn]
get_player_pawn() -> Pawn      # 主单位，保持旧调用可用
get_enemy_pawn() -> Pawn       # 首个敌人，保持旧调用可用
```

团队胜负：

- 敌方全部死亡 → `PLAYER_WIN`。
- 主角死亡 → `ENEMY_WIN`。
- 玩家单位全部死亡 → `ENEMY_WIN`。
- 队友死亡但主角存活 → 战斗继续。
- 旧 1v1 中唯一玩家单位即主角；旧语义不变。

资源与进度：

- `SquadResourceSnapshot` 按成员 id 保存每个单位的生命 / 护盾 / 灵力。
- `SquadProgressSnapshot` 按成员 id 保存强化等级、已掌握功法、已掌握技能、境界与修为。
- 快照不持有 Pawn 引用；换房 / 重开时按 id 写回新实例。
- 主角的进度继续跨局延续；队友资源在本局房间间延续，下一轮重新按档案初始化。

### 5.4 AI 与目标

AI 第一版只做：

- 每个敌人从存活的玩家单位中选择最近目标。
- 目标死亡 / 无效时重新选敌。
- 技能目标仍走既有 `Pawn.is_valid_skill_target()`。
- 不做仇恨值、集火指令、护送、撤退或复杂技能优先级。

玩家集火由 `PlayerController.order_attack(target)` 逐单位下达，不由 AI 自动代劳。

### 5.5 多单位选择与命令路由

主场景新增独立选择模型，不在每个 Controller 里复制选中状态：

```text
_selected_pawns: Array[Pawn]
_primary_selected_pawn: Pawn
```

路由规则：

- 信息卡与技能栏只绑定 `_primary_selected_pawn`。
- 右键移动时，以点击点为中心按固定偏移给每个选中单位下达 `order_move()`。
- 右键敌人时，所有选中单位下达 `order_attack()`。
- 单位死亡时从选择集合移除；主选中死亡时自动顺延到下一个存活玩家单位。
- 敌方单位不可被玩家选中指挥。

### 5.6 运行时主动技能装配

现有 `PawnData.active_skills` 是静态技能表，`get_enabled_active_skills()` 只按容量截取前 N 个。要让“重构”成为真实行为，需要新增运行时装配层：

```text
_known_active_skills: Array[ActiveSkillDefinition]
_equipped_active_skills: Array[ActiveSkillDefinition]
```

接口：

```text
get_known_active_skills() -> Array[ActiveSkillDefinition]
get_equipped_active_skills() -> Array[ActiveSkillDefinition]
learn_active_skill(skill) -> bool
set_active_skill_loadout(skills) -> bool
```

约束：

- 只接受已掌握、已配置、唯一且不超过当前境界容量的技能。
- 失败必须零副作用。
- 未设置运行时装配时，完全沿用 `PawnData.active_skills` 的旧行为。
- `BuildLoadout`、`SkillBar`、`PlayerController`、`PawnInfoModel` 必须统一读取新的装配列表，禁止继续各自读取 `PawnData.active_skills`。

本阶段不做：

- 拖拽排序。
- 保存装配方案。
- 功法战斗属性加成。
- 多套 Build 存档。

### 5.7 UI 结构

新增 `SquadPanel`：

- 位置：屏幕底部中央，避免继续撑宽左下 `BottomLeftDock`。
- 内容：4 张紧凑单位卡，显示名称、生命比例、护盾状态、存活状态、主选中高亮。
- 交互：点击卡片切换主选中单位。
- 不显示敌人完整卡片；敌人信息通过头顶血条与当前遭遇文本表达。

Build 重配面板：

- 通关后显示两个预设配置。
- 只发“选择配置”意图，由 `Pawn.set_active_skill_loadout()` 统一裁决。
- 不直接修改 Pawn 字段，不在 UI 复制容量规则。

### 5.8 内容数据

Vertical Slice 使用独立数据，不覆盖现有 `trial_dungeon.tres`：

```text
game/world/data/dungeons/vertical_slice_dungeon.tres
game/pawns/data/squads/vertical_slice_party.tres
game/pawns/data/squads/vertical_slice_enemy_*.tres
game/world/data/encounters/vertical_slice_room_*.tres
```

数据结构必须由资源引用连接：

```text
DungeonRoom
  → EncounterDefinition
    → SquadDefinition
      → PawnData
```

不在 `main.gd` 或 `DungeonRun` 中硬编码房间数、敌人数或成员名单。

## 6. Increment 拆分

| Increment | 主题 | 目标 | 依赖 |
|---|---|---|---|
| `INC-PAWNS-020` | pawns | 四人队伍数据契约与多单位运行时快照 | `INC-CROSS-018` accepted |
| `INC-PAWNS-021` | pawns | 运行时主动技能装配与 Build 重配 | `INC-PAWNS-020` |
| `INC-COMBAT-009` | combat | 四方战队遭遇、团队胜负与 AI 目标 | `INC-PAWNS-020` |
| `INC-WORLD-007` | world | 4v4 Vertical Slice 秘境、奖励与定点数据 | `INC-COMBAT-009` |
| `INC-CORE-012` | core | 多单位选择、编组命令与暂停战术路由 | `INC-PAWNS-020`、`INC-COMBAT-009` |
| `INC-UI-018` | ui | 四人队伍 HUD 与 Build 重配面板 | `INC-CORE-012`、`INC-PAWNS-021` |
| `INC-TESTING-011` | testing | 4v4 闭环、再战证据与人工验收剧本 | 以上全部 |

建议实现顺序：

```text
PAWNS-020
  → PAWNS-021
  → COMBAT-009
  → WORLD-007
  → CORE-012
  → UI-018
  → TESTING-011
```

## 7. 验收与退出判定

### 7.1 自动化证据

`INC-TESTING-011` 必须产出：

- 2v2、3v3、4v4 三种规模的真实单位数量与阵营断言。
- 单单位死亡不会提前终局、敌人全灭才胜利、主角死亡即失败的断言。
- 多单位移动 / 集火命令到达所有存活选中单位的断言。
- 首轮通关解锁定身术、Build 选择切换到 `御剑 + 定身`、第二轮产生不同战斗轨迹的断言。
- 1152x648、1152x720、800x720 三档布局截图与无重叠报告。
- 至少一份 `build_decision_before_after` 记录：Build A 与 Build B 的生存、控制、战斗时长对照。

### 7.2 人工验收

用户必须在真实主场景完成：

1. 用初始 Build 打完第一轮 4v4 Vertical Slice。
2. 看到 Boss 奖励与新技能解锁。
3. 选择是否重构 Build。
4. 使用新 Build 再打一轮。
5. 回答唯一问题：

> 你是否因为这次奖励，想主动重构并再打一轮？为什么？

### 7.3 通过 / 失败条件

通过：

- 所有子 Increment 验证通过。
- 真实主场景链路可复现。
- 用户明确回答“会”，并能说出想换什么、为什么换。
- 第二轮存在与第一轮不同的过程证据。

失败：

- 用户只认为数值变大，但没有重构欲望。
- 4v4 只是增加单位数量，玩家操作与决策没有变化。
- Build 切换不影响战斗过程。
- 失败后禁止继续加技能 / 加秘境 / 加职业；应新开战斗核心重设 Increment。

## 8. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 4v4 导致范围爆炸 | 固定 3 间房、固定 4 人队伍、固定 2 套 Build 预设 |
| UI 被 8 个血条淹没 | 队伍卡只显示玩家 4 人；敌人依靠头顶血条与当前目标高亮 |
| AI 太笨导致“人多但不好玩” | 只做最近目标与目标失效重选，先把决策空间交回玩家 |
| 主角 Build 与队友强度混淆 | 队友固定强度，奖励与重构只作用于主角，人工复盘明确主角变化 |
| 快照按 id 写回发生错位 | 成员 id 唯一；快照按 id 键值；缺成员安全跳过，不按数组下标写回 |
| 自动测试只能证明“能运行” | 人工验收问题作为父 Increment 的硬门，不能由测试替代 |
| 定身术只改数字不改过程 | 要求记录控制生效窗口、Boss 行动变化或承伤差异 |

## 9. 完成定义

`INC-CROSS-019` 只有在以下条件全部满足时才能 `accepted`：

- 7 个子 Increment 全部 `validated`。
- 真实主场景完成一次 2v2 → 3v3 → 4v4 的完整秘境。
- 主角 Build 能从 `御剑 + 护体` 切换到 `御剑 + 定身`。
- 第二轮战斗出现可解释的不同过程。
- 用户明确回答愿意因为奖励重构并再打一轮。
- 随后才允许规划下一阶段扩展。
