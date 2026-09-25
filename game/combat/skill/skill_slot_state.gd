class_name SkillSlotState
extends RefCounted

## 技能格状态读模型：只解释“当前是否可释放、冷却比例是多少”，不修改 Pawn、资源或冷却。
## SkillSlot 只消费本模型的结果；目标距离、目标合法性和实际施法仍由 Pawn.cast_skill()/PlayerController 负责。

enum State {
	EMPTY,
	READY,
	COOLDOWN,
	NO_RESOURCE,
	DISABLED,
	SELECTED,
	TARGETING,
}

const STATE_EMPTY: StringName = &"EMPTY"
const STATE_READY: StringName = &"READY"
const STATE_COOLDOWN: StringName = &"COOLDOWN"
const STATE_NO_RESOURCE: StringName = &"NO_RESOURCE"
const STATE_DISABLED: StringName = &"DISABLED"
const STATE_SELECTED: StringName = &"SELECTED"
const STATE_TARGETING: StringName = &"TARGETING"


## 读取真实 Pawn 的只读状态后求值；调用方不需要重复查询冷却或灵力。
static func for_pawn(pawn: Pawn, skill: ActiveSkillDefinition) -> Dictionary:
	if pawn == null or not is_instance_valid(pawn) or skill == null:
		return evaluate(skill, 0.0, 0.0, false)
	var remaining: float = pawn.get_skill_cooldown_remaining(skill.id) if skill.is_configured() else 0.0
	return evaluate(skill, remaining, pawn.current_spirit, pawn.is_alive(), pawn.is_active_skill_enabled(skill))


## 纯逻辑入口：调用方提供只读快照，便于单元测试且不依赖场景树。
static func evaluate(
		skill: ActiveSkillDefinition,
		cooldown_remaining: float,
		current_spirit: float,
		unit_alive: bool,
		build_enabled: bool = true
	) -> Dictionary:
	var snapshot: Dictionary = {
		"state": State.EMPTY,
		"state_name": STATE_EMPTY,
		"skill_id": &"",
		"display_name": "",
		"cost": 0.0,
		"current_spirit": maxf(current_spirit, 0.0),
		"cooldown_remaining": 0.0,
		"cooldown_total": 0.0,
		"cooldown_ratio": 0.0,
		"can_cast": false,
		"build_enabled": build_enabled,
		"reason": "",
	}
	if skill == null:
		return snapshot

	snapshot["skill_id"] = skill.id
	snapshot["display_name"] = skill.display_name
	if not skill.is_configured():
		return _disabled(snapshot, "技能未配置")
	if not build_enabled:
		return _disabled(snapshot, "超出主动技能容量")
	snapshot["cost"] = skill.get_normalized_spirit_cost()
	if not unit_alive:
		return _disabled(snapshot, "单位不存在或已死亡")

	var total: float = skill.get_normalized_cooldown()
	var remaining: float = maxf(cooldown_remaining, 0.0)
	snapshot["cooldown_total"] = total
	snapshot["cooldown_remaining"] = remaining
	snapshot["cooldown_ratio"] = (remaining / total) if total > 0.0 else 0.0
	if remaining > 0.0:
		snapshot["state"] = State.COOLDOWN
		snapshot["state_name"] = STATE_COOLDOWN
		snapshot["reason"] = "冷却中 %.1fs" % remaining
		return snapshot

	var cost: float = snapshot["cost"]
	if cost > snapshot["current_spirit"]:
		snapshot["state"] = State.NO_RESOURCE
		snapshot["state_name"] = STATE_NO_RESOURCE
		snapshot["reason"] = "灵力不足 %.0f / %.0f" % [snapshot["current_spirit"], cost]
		return snapshot

	snapshot["state"] = State.READY
	snapshot["state_name"] = STATE_READY
	snapshot["can_cast"] = true
	return snapshot


## 状态编号转稳定名称；交互层需要 SELECTED / TARGETING 时复用同一命名。
static func state_name(state: int) -> StringName:
	match state:
		State.EMPTY:
			return STATE_EMPTY
		State.READY:
			return STATE_READY
		State.COOLDOWN:
			return STATE_COOLDOWN
		State.NO_RESOURCE:
			return STATE_NO_RESOURCE
		State.DISABLED:
			return STATE_DISABLED
		State.SELECTED:
			return STATE_SELECTED
		State.TARGETING:
			return STATE_TARGETING
		_:
			return STATE_DISABLED


static func _disabled(snapshot: Dictionary, reason: String) -> Dictionary:
	snapshot["state"] = State.DISABLED
	snapshot["state_name"] = STATE_DISABLED
	snapshot["can_cast"] = false
	snapshot["reason"] = reason
	return snapshot
