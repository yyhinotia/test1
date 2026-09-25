# 4v4 Vertical Slice 设计

> 状态：accepted（设计基线）  
> 设计时间：2026-09-25T20:43:57+08:00  
> 验收时间：2026-09-25T20:47:54+08:00  
> 修订时间：2026-09-25T21:14:43+08:00（按玩法验证评审收紧为 Gate A + Gate B）\
> 父 Increment：`INC-CROSS-019`  
> 输入依据：`docs/project_summary.md` §八（4v4 / 4–8 单位、实时战斗 + 暂停操作）、§十七（MVP 主线）、§十八 MVP Top 5 ②（战斗框架）与 §二十二（先做 4v4 Vertical Slice）；`docs/build-mvp.md` MVP-5（Build → Skill → Combat 闭环）。

## 1. 唯一问题

本阶段的实验问题不是「4v4 能不能做出来」，而是：

> **玩家完成第一轮 4v4 Boss 后获得一个改变战斗方式的新能力，是否会主动重构 Build，并愿意用新 Build 再打一轮？**

再收紧一层，验证的是：

```text
奖励 → 新策略 → 重构 → 新的战斗过程
```

而不是：

```text
奖励 → 更强 → 再打一遍
```

判定规则：

- 必须同时成立两件事：① 奖励产生了重构意图；② 重构后的战斗真的出现决策变化。
- 答案是「会」、玩家能说出想换什么与为什么换、并且第二轮过程确实改变，才允许继续扩内容、职业、秘境和宗门。
- 答案是「不会」，或玩家只是好奇试一下却说不出战术原因，必须停止加系统，回到战斗核心设计。
- 玩家原话是主证据；自动化和归档标签只作辅助，不能替代人工回答。
## 2. 阶段目标

本阶段拆成两层 Gate，必须同时成立。

### 2.1 Gate A：战斗技术成立（Combat Vertical Slice Gate）

```text
4 人小队
  ↓
2v2 → 3v3 → 4v4
  ↓
多选 / 暂停 / 移动 / 集火
  ↓
队友死亡继续、主角死亡失败、敌人全灭胜利
  ↓
AI 目标失效后重选
```

Gate A 回答「多人战斗系统从 2 扩到 4 是否成立」，不直接回答玩法问题；2v2 / 3v3 只是技术验证的中间规模。

### 2.2 Gate B：玩法假设成立

```text
Round 1  A Build（御剑斩 + 护体真气）
  ↓
同一个 4v4 Boss
  ↓
首通 100% 解锁定身术（立即可装备）
  ↓
玩家主动选择 B Build（御剑斩 + 定身术）
  ↓
Round 2  重打同一个 4v4 Boss
  ↓
过程是否出现可解释的变化
```

- Gate B1：奖励是否产生「我想换 Build」的意图。
- Gate B2：换完之后，战斗是否真的出现决策 / 过程变化。
- Gate B 只重打同一个核心 Boss，不要求重播 2v2 / 3v3；这样能把「学习效应」与「Build 变化」尽量分开。

必须同时满足：

1. 玩家能选单位、下令、暂停观察、放技能，而不是看 AI 自动打完。
2. 一场战斗确实存在 4 名玩家单位和 4 名敌方单位。
3. 队友阵亡、主角阵亡、敌人全灭是三种不同的战场事实。
4. 第一轮结束后能拿到一个真正改变战斗方式的选择，而不只是 +N 数值。
5. 第二轮能用不同 Build 产生不同轨迹，并且玩家能解释为什么。
## 3. 非目标

本阶段明确不做：

- 不做整个秘境都变成 4v4；2v2 → 3v3 → 4v4 只用于 Gate A 技术验证，Gate B 玩法对照只打第三间那个 4v4 Boss。
- 不做修士招募、队友长期养成、换人、职业树、编队编辑器。
- 不做拖拽式 Build 编辑器；只做「预设战术配置」切换。
- 不做复杂 AI、仇恨表、仇恨值、技能优先级、阵型 AI、路径寻路优化。
- 不做范围伤害、AOE 指示器、持续伤害、Buff/Debuff 堆叠、五行克制。
- 不做存档 / 读档、跨进程迁移、多人联机。
- 不做正式美术、技能特效、音效。
- 不把宗门继续扩成 Colony Sim。
- 不把 45 灵石做成第一轮玩法验证的主要变量；奖励侧第一轮只验证「新能力 → Build 重构」。
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

- 100% 解锁 `player_binding_skill.tres`（定身术）为**已掌握技能**，并且**立即可装备**。
- 灵石奖励可以保留（后续宗门经济继续用它），但**不参与**本阶段第一轮的 Build 重构裁决，也不是重构面板的前置条件。

通关后的 Build 选择不做自由拖拽，只提供两个预设：

```text
配置 A：御剑斩 + 护体真气     （输出 + 生存）
配置 B：御剑斩 + 定身术       （输出 + 控制）
```

设计原因：

- 配置 A 与 B 都已经有真实技能效果，不需要新 Effect System。
- 定身术改变的是 Boss 的行动窗口（战术维度），而不是伤害数字。
- 灵石单独记录、单独结算；避免玩家是因为「拿了资源想花掉」而不是「定身术改变了打法」产生重构意图。
- 第一次验证的变量越干净，结论越可信；资源 / 装备 / 宗门成长留给后续验证轮次。

### 4.5 第二轮：证明「重构有意义」

第二轮**必须重新面对同一个核心 4v4 Boss**，不重播 2v2 / 3v3。

理由：

- 只重打同一个 Boss，才能把两轮的差异尽量归因到 Build，而不是「又打了一遍更熟练了」或「敌人换了」。
- 同样的目标、同样的危险窗口，定身术与护体真气的差别才可以直接对照：

```text
A：Boss 危险窗口出现 → 只能硬扛 / 靠护盾
B：Boss 危险窗口出现 → 定身打断 → 行动被延后或跳过 → 战斗过程变化
```

第二轮至少满足一个可观察差异：

- 定身术使 Boss 的某次危险输出被延后或跳过。
- 玩家承受的总伤害明显下降。
- 击杀顺序或战斗时长出现可解释的变化。
- 玩家在复盘时能说出「因为第一轮 Boss 的危险窗口，所以第二轮换了控制」。

不要求第二轮一定「更强通关」；要求的是不同 Build 产生不同过程。第二轮不是严格 A/B Test（存在学习效应），因此结论必须结合玩家原话，而不是只看时长或伤害差值。
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

| Increment | 主题 | Gate | 目标 | 依赖 |
|---|---|---|---|---|
| `INC-PAWNS-020` | pawns | A | 四人队伍数据契约与多单位运行时快照 | `INC-CROSS-018` accepted |
| `INC-PAWNS-021` | pawns | B1 | 运行时主动技能装配与 Build 重配 | `INC-PAWNS-020` |
| `INC-COMBAT-009` | combat | A | 四方战队遭遇、团队胜负与 AI 目标重选 | `INC-PAWNS-020` |
| `INC-WORLD-007` | world | A + B1 | 4v4 Vertical Slice 秘境、首通奖励与可重开的同一个 Boss | `INC-COMBAT-009` |
| `INC-CORE-012` | core | A + B | 多单位选择、编组命令与暂停战术路由（含同 Boss 再战入口） | `INC-PAWNS-020`、`INC-COMBAT-009` |
| `INC-UI-018` | ui | B1 | 四人队伍 HUD 与 Build 重配面板（只由定身术解锁驱动） | `INC-CORE-012`、`INC-PAWNS-021` |
| `INC-TESTING-011` | testing | A + B | Gate A 闭环证据、同 Boss 再战对照与人工五问剧本 | 以上全部 |
| `INC-TESTING-012` | testing | A + B | 场景化测试入口拆分到 `tests/`（每个测试场景一个独立入口） | `INC-WORLD-007`、`INC-CORE-012` |

建议实现顺序：

```text
PAWNS-020
  → PAWNS-021
  → COMBAT-009
  → WORLD-007
  → CORE-012
  → UI-018
  → TESTING-011
  → TESTING-012
```

`tests/` 与既有 `test/` 并存：`test/` 负责 GdUnit4 自动化断言，`tests/` 负责可交互的场景化测试入口，`main.tscn` 只保留正式游戏入口职责。
## 7. 验收与退出判定

### 7.1 Gate A 自动化证据

`INC-TESTING-011` 必须产出：

- 2v2、3v3、4v4 三种规模的真实单位数量、阵营与主选中单位断言。
- 队友死亡不提前终局、主角死亡即失败、敌人全灭才胜利的断言。
- AI 目标失效后重选最近有效目标的断言。
- 多单位移动 / 集火命令到达所有存活选中单位的断言，以及死亡单位自动移出选择集合。
- 首轮通关 100% 解锁定身术、重复通关不重复解锁的断言。
- Build 从 A 切到 B 后，装配结果只来自运行时统一装配，不出现 UI / SkillBar / PlayerController / Pawn 各自直读 `PawnData` 的技能分叉。

### 7.2 Gate B 对照证据

- 在**同一个 4v4 Boss** 上完成 Round 1（A Build）与 Round 2（B Build），不重播 2v2 / 3v3。
- 至少一份 `build_decision_before_after` 记录：两轮各自的危险窗口、控制生效、承伤、击杀顺序与战斗时长。
- 45 灵石与定身术分开记录；灵石不进入本阶段第一轮的主变量。
- 自动化只能证明「机制闭环 + 过程差异存在」，不能证明玩家「想不想重构」。

### 7.3 人工验收（五问 + 保留原话）

用户必须在真实主场景完成：

1. 用初始 A Build 打完第一轮 4v4。
2. 观察并记录 Boss 的危险窗口。
3. 首通获得定身术。
4. 自主决定是否重构为 B Build（御剑斩 + 定身术）。
5. 用 B Build 重打**同一个** 4v4 Boss。

然后回答：

- Q1 新奖励有没有让你产生「我想换 Build」的想法？
- Q2 你具体想换什么？
- Q3 为什么换（战术理由 / 好奇 / 数值 / 通关压力）？
- Q4 换完以后，战斗有没有按照你预期发生变化？
- Q5 如果没有这个奖励，你还会主动再打一轮吗？
- 追加：如果不换 Build，你认为第一轮战斗里的哪个问题仍然存在？

结论归档维度（只作辅助，必须同时保留玩家原话）：

```text
ReplayIntent:    yes / no
BuildChange:     none / A→B / other
Reason:          tactical / numerical / curiosity / completion / other
PerceivedImpact: none / low / medium / high
```

### 7.4 通过 / 失败条件

通过（缺一不可）：

- Gate A 全部子 Increment 验证通过，真实主场景链路可复现。
- Gate B1：玩家主动表达了「我想换 Build」，并能说出为什么换（战术理由，而不是「新技能比较强」）。
- Gate B2：第二轮至少一个可观察差异（Boss 行动窗口 / 控制成功 / 承伤 / 击杀顺序 / 时长 / 队友存活），且玩家能给出因果解释链。
- 三档分辨率 1152x648 / 1152x720 / 800x720 的布局截图与无重叠报告。

失败（任一命中即不得继续扩内容）：

- A：奖励没有产生 Build 动机。
- B：玩家只因好奇尝试，说不出战术原因。
- C：Build 改了，但战斗没有任何可观察变化。
- D：4v4 只是「人更多」，玩家不需要更多操作 / 选目标 / 暂停 / 调整策略。

失败后禁止加技能 / 加秘境 / 加职业；应回到战斗核心（战斗决策 / 奖励设计 / Build 差异 / 技能交互 / 敌人设计）新开 Increment。
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

- 8 个子 Increment（含 `INC-TESTING-012`）全部 `validated`。
- Gate A：真实主场景完成一次 2v2 → 3v3 → 4v4 的完整秘境。
- Gate B1：主角 Build 能从 `御剑 + 护体` 切换到 `御剑 + 定身`，玩家主动表达了重构意图并说出原因。
- Gate B2：在同一个 4v4 Boss 上重打一轮，出现可解释的不同战斗过程。
- 玩家五问回答已记录（含原话），且没有命中 Failure A~D。
- 三档分辨率布局证据通过。
- 随后才允许规划下一阶段扩展。
