# Combat 主题计划

> 最后修改：2026-09-25T13:43:51+08:00  
> 主题：combat  
> 规则来源：`../AGENTS.md`

## INC-COMBAT-001：实现基础普通攻击闭环

- 状态：accepted
- 创建时间：2026-09-25T13:21:58+08:00
- 最后修改：2026-09-25T13:43:51+08:00
- 主题：combat
- 目标：验证 `Target -> Move To Range -> Attack -> Damage -> Death` 的最小战斗闭环。
- 验收标准：
  - 右键敌方 Pawn 后，玩家 Pawn 自动接近到攻击距离并停止。
  - Pawn 按攻击间隔持续发动普通攻击，不出现每帧伤害。
  - 伤害名称使用 `max(1, attack - defense)`，先扣护盾再扣生命。
  - 受击后生命/护盾数据与 UI 同步更新。
  - 生命归零后进入 `DEAD` 状态，停止移动并停止攻击。
  - 敌方 AI Pawn 会主动接近并攻击玩家 Pawn。
- 范围：`game/combat/**`、`game/pawns/pawn.gd`、`game/pawns/data/*.tres` 中的战斗属性。
- 非范围：技能、功法、五行、伤害类型、暴击、范围伤害、仇恨表、状态异常和复杂目标选择。
- 依赖：`INC-PAWNS-001`；基础 Pawn 移动和生命接口。
- 风险：攻速、伤害和攻击距离如果未数据化，后续平衡会返工；本 Increment 将攻击间隔和数据放入 `PawnData`。
- 实现说明：
  - `Pawn.try_attack()` 通过攻击冷却生成普通攻击；`Pawn.take_damage()` 负责防御减免、护盾吸收和生命扣除。
  - 敌人 AI 延迟 3 秒启动，随后主动接近玩家并进入普通攻击循环。
  - `PlayerController` 保存移动/攻击指令，自动接近目标；`AIController` 使用同一 Pawn 攻击接口。
- 变更文件：
  - `game/pawns/pawn.gd`
  - `game/pawns/data/player_pawn.tres`
  - `game/pawns/data/enemy_pawn.tres`
  - `game/pawns/controllers/player_controller.gd`
  - `game/pawns/controllers/ai_controller.gd`
- 测试证据：
  - 右击敌人后 HUD 指令变为 `指令：攻击 试炼傀儡`，玩家随后与敌人互相攻击。
  - 运行态读取：敌人 `current_health` 从 80 降到 0、`current_shield` 从 20 降到 0，最终 `state = DEAD`（枚举值 3）。
  - 运行态读取：玩家在敌人普通攻击下 `current_shield` 从 40 降到 0，`current_health` 从 120 降到 104，证明敌人伤害通过同一 `take_damage()` 流程。
  - 敌人死亡后玩家生命在后续等待中保持不变，未出现死亡目标继续攻击。
  - `get_debug_output()` 最终 `errors` 为空。
  - 复验（攻击指令）：右键敌人后 HUD 指令由 待命 变为 指令：攻击 试炼傀儡，玩家在 64.9 像素距离内立即进入攻击循环。
  - 复验（伤害闭环）：敌人护盾 20 到 0、生命 80 到 50 到 0，最终 state = 3（DEAD）；同期玩家在敌人普攻下生命 120 到 90 到 62 到 55 到 48，双方共用同一 take_damage() 流程。
  - 复验（死亡后行为）：敌人死亡后玩家生命保持 48 不变，敌人不再发起攻击，攻击指令自动清回 待命。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:43:51+08:00
- 已知问题：暂无攻击动画、命中特效、伤害数字、攻击前摇和复杂命中判定。
- 用户验收：已验收
- 验收时间：2026-09-25T13:43:51+08:00
- Git：分支 main，commit d7c2e1e（feat(pawns): add pawn MVP with movement, combat, HUD and pause [INC-CROSS-001]）
- 备注：此 Increment 是 `INC-CROSS-001` 的子 Increment。