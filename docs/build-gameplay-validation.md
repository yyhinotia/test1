# Build 玩法验证：1v1 → 1vN（INC-CROSS-019 设计基线）

> 状态：当前有效设计基线
> 父 Increment：`INC-CROSS-019`（Build Gameplay Validation）
> 替代：`docs/4v4-vertical-slice.md`（4v4 Vertical Slice，2026-09-25 起冻结延后）
> 最后修改：2026-09-25T21:45:00+08:00

## 1. 唯一验证问题

本阶段不验证：4v4 是否好玩、多单位控制是否好玩、队友养成是否好玩、秘境规模是否合理、宗门是否有足够内容、装备系统是否成立。

本阶段只回答一个问题：

> 当玩家在战斗中遇到一个明确的问题，并获得一个可以解决该问题的新技能后，玩家是否会主动重构自己的 Build，再次进入战斗？

拆成两个必要条件：

```text
Gate A：Build 是否产生主动重构欲望？
玩家："我刚才的问题是 X"
        ↓
获得新能力 Y
        ↓
"如果我换成 Y，我可以解决 X"
        ↓
主动修改 Build
```

```text
Gate B：Build 是否真正改变战斗？
Build A → 玩家采用解决方案 A
Build B → 玩家采用解决方案 B
```

## 2. 为什么暂时放弃 4v4

直接进入 4v4 会同时引入多单位 Pawn、队伍数据、多单位快照、多单位选择、编组命令、团队胜负、AI 目标重选、队伍 HUD、队友死亡、多单位技能路由——这些都属于**战斗系统工程问题**，而当前真正的未知是「Build 有没有玩法价值」。

验证顺序：

```text
1v1 → 1v2 / 1v3 → Build 重构 → 重复战斗
```

如果 1v1 都无法让玩家产生重构欲望，就没有必要先投入大量工程成本做 4v4。

## 3. 核心玩法模型

```text
战斗 → 玩家遇到问题 → 获得新的能力 → 玩家理解能力价值
  → 主动修改 Build → 再次战斗 → 用不同方式解决原问题
  → 形成反馈 → 下一次 Build
```

核心不是「新 Build 数值更高」，而是**新 Build 允许玩家采用不同的解决方案**。

## 4. 三阶段实验结构

```text
Stage 1：1v1
Stage 2：1vN
Stage 3：Build Replay
```

### Stage 1：1v1

玩家 vs 单个敌人；初始 Build = 御剑斩 + 护体真气。敌人必须同时具备普通攻击与**危险技能**，危险技能要形成玩家可以识别的问题，例如「每 8 秒准备一次强力攻击，玩家没有定身无法打断，只能承受」。

第一场战斗不追求困难，而追求「可解释的问题」：

- 玩家可以赢，但不能完全无脑赢。
- 危险技能无法被直接干预，造成明显损耗。
- 战斗结束后玩家能指出「刚才这个技能比较麻烦」。

### Stage 2：1vN（仅在 Stage 1 成立后）

玩家始终只有 1 个 Pawn，敌人从 1v2 增加到 1v3。敌人不能是同一敌人复制 N 份，而应是行为角色组合：

```text
Enemy A：近战输出（持续贴身）
Enemy B：远程输出（持续输出）
Enemy C：危险技能（周期性危险窗口）
```

玩家面对的问题：优先杀谁？什么时候定身？定身谁？是否先处理远程？

### Stage 3：Build Replay

用**同一个 Boss、一致行为模式**重打同一问题，观察：

```text
第一次：危险技能 → 只能承受
第二次：危险技能 → 主动定身 → Boss 被控制 → 玩家继续输出
```

第二轮不要求更快、不要求少掉血；只要求玩家采用了与第一轮不同的解决方案。

## 5. 奖励与 Build 设计

```text
Boss 首通 → 100% 获得定身术 → 立即可装备 → 直接进入 Build 重构 → 再打一轮
```

- 第一次验证的奖励必须极纯：`Combat Problem → New Ability`，**不得**同时给灵石 / 装备 / 强化 / 随机掉落。
- `定身术` 不是「伤害 +20%」，而是「使目标停止行动 X 秒、较长 CD、可覆盖 Boss 的危险动作窗口」。
- 两套固定 Build：

```text
Build A：御剑斩 + 护体真气
Build B：御剑斩 + 定身术
```

- `护体真气 = 降低问题造成的损失`；`定身术 = 改变问题本身`。两者不是 DPS 差异。
- 禁止自动切换：必须由玩家主动点击「使用 Build B」，否则无法验证「玩家是否产生重构行为」。
- 不做拖拽、技能排序、多套保存、Build 命名 / 删除 / 分享。

## 6. 轻量 CombatEvent

```text
CombatEvent：timestamp / actor_id / target_id / event_type / skill_id
```

至少记录：`danger_window_opened`、`skill_cast`、`skill_hit`、`skill_blocked`、`skill_stunned`、`skill_cancelled`、`unit_died`、`combat_end`。

事件流示例：

```text
Round 1：Boss danger_window_opened → dangerous_skill_cast → dangerous_skill_hit
Round 2：Boss danger_window_opened → player_binding_cast → boss_stunned → dangerous_skill_cancelled
```

两轮对照的客观判据：Round 1 不得出现 `skill_cancelled`；Round 2 必须出现 `skill_stunned` → `skill_cancelled` 且该次危险技能伤害未结算。两轮应对序列相同即判定 Failure 4，即使玩家自述「换了打法」。

## 7. 自动化与人工的边界

自动化只证明机制成立：

1. 技能可以学习；2. 技能进入 known skills；3. 技能可以进入 equipped skills；4. Build A 可以加载；5. Build B 可以加载；6. Build B 的技能真实进入 SkillBar；7. 定身实际可以作用于敌人；8. 定身能够改变敌人的行动状态；9. 战斗结束后可以再次进入同一遭遇。

自动化**不得**判断「这个 Build 好不好玩」，也不得替代「玩家是否愿意重构」这一结论。

## 8. 验收：Gate 0（技术）+ 五道玩法 Gate

### Gate 0：技术成立（前置门，未通过不得进入人工验收）

| 检查 | 通过条件 |
|---|---|
| 终局判定 | 1v1 / 1v2 / 1v3 均为「敌方全灭才判胜、玩家单位死亡即失败」，主目标单独死亡不提前结束 |
| 问题窗口 | 1v1 危险窗口可稳定复现，且无控制手段时无法干预 |
| 控制有效性 | 定身可真实打断危险技能：`skill_stunned` → `skill_cancelled`，该次伤害不结算 |
| Build 生效 | Build A / B 均可加载，切换后 SkillBar / 信息卡当帧跟随 |
| 可重复性 | 同一遭遇可重复挑战，单位与事件序列不跨局污染 |
| 入口组织 | 每个测试场景在 `tests/` 有独立入口，`main.tscn` 只保留正式入口职责 |

判定顺序：**Gate 0 → Gate A / B → Gate C / D / E**。Gate 0 未成立时人工验收结论无效，不得记入 Gate A~E。

### 五道玩法 Gate

| Gate | 通过条件 |
|---|---|
| Gate A | 玩家能够描述第一轮中的具体战斗问题（例：「Boss 那个大招很烦」），而不是「挺难的」 |
| Gate B | 玩家能够理解「定身 → 可以解决第一轮的问题」 |
| Gate C | 玩家在没有强制要求的情况下主动选择 Build B |
| Gate D | 第二轮玩家主动使用定身，并将其用于解决第一轮遇到的问题 |
| Gate E | 玩家能够解释为什么第二轮选择这个 Build |

### 人工三问（保留原话，不得诱导）

- Q1 第一轮战斗中，你觉得最麻烦的问题是什么？
- Q2 拿到定身术后，你为什么选择 / 不选择换 Build？
- Q3 第二次战斗和第一次相比，你具体改变了什么？
- Q4（附加、非门控、可选记录）：如果这次没有拿到新能力，你还会主动再打一轮吗？

Q1~Q3 是硬门提问；Q4 只作参考，不参与 Gate 判定，同样必须保留原话。

归档标签：`ReplayIntent`（yes / no）、`BuildChange`（none / A→B / other）、`Reason`（tactical / numerical / curiosity / completion / other）、`PerceivedImpact`（none / low / medium / high）。标签只做归档，**必须同时保留玩家原话**。

## 9. 失败条件

| 编号 | 现象 | 说明 |
|---|---|---|
| Failure 1 | 「定身挺好的」但不想换 Build | 新能力没有产生重构欲望 |
| Failure 2 | 换了 Build，但第二轮照第一次的方式打 | Build 没有真正改变玩法 |
| Failure 3 | 换 Build 是因为「你让我试试」 | 行为来自实验指令而非玩家需求 |
| Failure 4 | A / B 实际战斗体验几乎完全一样 | 技能系统存在，但 Build 不产生玩法差异；客观判据：两轮危险窗口应对序列相同（Round 2 未出现 `skill_cancelled`），即使玩家自述换了打法 |
| Failure 5 | 只关注伤害更高 / 数值更大 | 当前 Build 更接近数值成长而非战术构筑 |

任一命中即禁止继续扩 Build 系统，必须回到战斗核心重设 Increment。

Gate D 的判定证据为「玩家原话 + CombatEvent 客观佐证（`skill_cancelled`）」；两者冲突时以事件序列为准。

## 10. 最小技术实现与资源结构

```text
Pawn
 ├─ known_active_skills
 └─ equipped_active_skills
```

API：`learn_active_skill(skill)`、`set_active_skill_loadout(skills)`、`get_equipped_active_skills()`。

```text
game/
├── pawns/data/skills/player_binding_skill.tres      （当前位于 game/pawns/data/player_binding_skill.tres）
├── world/data/encounters/
│   ├── build_test_1v1.tres
│   ├── build_test_1v2.tres
│   └── build_test_1v3.tres
└── ui/build/build_loadout_panel.tscn
```

不创建：`squad/`、`party/`、`formation/`、`multi_selection/`、`team_hud/`。

场景化测试入口统一放在 `tests/`，每个测试场景一个独立 `.tscn`；`main.tscn` 只保留正式游戏入口职责。

战斗终局判定：1v1 / 1v2 / 1v3 统一为「敌方全灭才判胜、玩家单位死亡即失败」（由 `INC-COMBAT-009` 实现），1v3 的第三名敌人与 1v1 为同一个核心 Boss。

## 11. Increment 拆分与顺序

| Increment | 内容 | 目的 |
|---|---|---|
| `INC-COMBAT-009` | 1v1 战斗问题窗口（+ 轻量 CombatEvent） | 建立可被 Build 解决的战斗问题 |
| `INC-PAWNS-021` | 最小运行时 Skill Loadout | 让技能可以真正被学习 / 装配（objective 中标注为 `INC-PAWNS-020`，因编号已被 4v4 队伍契约占用而顺延） |
| `INC-WORLD-007` | 固定 1v1 / 1vN 遭遇 | 提供可重复实验场景 |
| `INC-UI-018` | 最小 Build 切换 UI | 玩家主动切换 A / B |
| `INC-TESTING-011` | Build Replay 实验记录 | 自动化 + 人工验收 |
| `INC-TESTING-012` | 场景化测试入口拆分到 `tests/` | 每个场景独立入口 |

开发顺序：

```text
INC-COMBAT-009 → INC-PAWNS-021 → INC-WORLD-007 → INC-UI-018 → INC-TESTING-011
```

> 每一个子 Increment 都不应该独立追求完整系统，它们共同组成一个实验装置。

## 12. 本阶段明确禁止的扩展

在 `INC-CROSS-019` 验证结束之前，不允许因为「感觉以后需要」而加入：

```text
❌ 4v4            ❌ 队友            ❌ 队伍 HUD
❌ 多单位选择      ❌ 编队            ❌ 仇恨系统
❌ 复杂 AI         ❌ 装备系统        ❌ 随机掉落
❌ 多套 Build 保存 ❌ Build 编辑器     ❌ 技能树
❌ 五行            ❌ AOE            ❌ 大量新技能 / 敌人 / 职业
```

## 13. 最终退出条件

只有以下条件全部满足，`INC-CROSS-019` 才能 `accepted`：

- 技术（Gate 0）：1v1 / 1v2 / 1v3 可稳定运行且终局为敌方全灭才判胜；技能可学习并可进入运行时 Loadout；Build A / B 可切换；定身可真实改变敌人状态；同一遭遇可重复挑战；CombatEvent 可记录关键行为。
- 玩法：第一轮存在玩家可明确识别的问题；新技能与问题直接相关；玩家能理解新技能用途；玩家主动修改 Build；第二轮实际采用了不同的战斗策略；玩家能解释为什么修改 Build。

真正的成功信号不是「测试 0 failures」，而是玩家说出：

```text
"这个 Boss 的大招我只能硬吃。"
   ↓ 获得定身
"我可以换掉护体，用定身控制它。"
   ↓ 第二次
Boss 准备大招 → 玩家主动定身 → 战斗方式发生变化
```

即：**玩家不是因为系统要求而换 Build，而是因为战斗问题让他自己产生了 Build 需求。**

## 14. 修订记录

| 版本 | 时间 | 变更 |
|---|---|---|
| v2 | 2026-09-25T21:50:38+08:00 | 按外部设计评审意见做增量调整：新增 Gate 0（技术成立前置门）与判定顺序；明确 1vN「敌方全灭才判胜」；1v3 第三名敌人与 1v1 为同一 Boss；Round 1 / Round 2 危险窗口应对序列的客观对照判据（Failure 4 客观化）；Gate D 改为「原话 + 事件佐证」双证据；保留三问硬门并新增非门控问题 Q4 |
| v1 | 2026-09-25T21:45:00+08:00 | 首次落盘：1v1 → 1vN Build 玩法验证设计基线（唯一问题、三阶段、奖励与 Build、CombatEvent、Gate A~E、Failure 1~5、资源结构与禁止扩展） |
