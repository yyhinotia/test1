class_name CombatEvent
extends RefCounted

## 轻量战斗事件（INC-COMBAT-009）：只记录 Build 验证需要的最小事实，不扩展为通用战斗日志。
## 事件类型采用白名单；未知类型在 CombatEventLog 中会被拒绝，避免日志被其它系统无限扩张。

const DANGER_WINDOW_OPENED: StringName = &"danger_window_opened"
const SKILL_CAST: StringName = &"skill_cast"
const SKILL_HIT: StringName = &"skill_hit"
const SKILL_BLOCKED: StringName = &"skill_blocked"
const SKILL_STUNNED: StringName = &"skill_stunned"
const SKILL_CANCELLED: StringName = &"skill_cancelled"
const UNIT_DIED: StringName = &"unit_died"
const COMBAT_END: StringName = &"combat_end"

var timestamp: float = 0.0
var actor_id: StringName = &""
var target_id: StringName = &""
var event_type: StringName = &""
var skill_id: StringName = &""


static func create(
		event_type: StringName,
		actor_id: StringName,
		target_id: StringName = &"",
		skill_id: StringName = &"",
		timestamp: float = 0.0
	) -> CombatEvent:
	var event: CombatEvent = CombatEvent.new()
	event.timestamp = maxf(timestamp, 0.0)
	event.actor_id = actor_id
	event.target_id = target_id
	event.event_type = event_type
	event.skill_id = skill_id
	return event


static func get_known_event_types() -> Array[StringName]:
	var types: Array[StringName] = [
		DANGER_WINDOW_OPENED,
		SKILL_CAST,
		SKILL_HIT,
		SKILL_BLOCKED,
		SKILL_STUNNED,
		SKILL_CANCELLED,
		UNIT_DIED,
		COMBAT_END,
	]
	return types


static func is_known_event_type(event_type: StringName) -> bool:
	return get_known_event_types().has(event_type)


func to_dictionary() -> Dictionary:
	return {
		"timestamp": timestamp,
		"actor_id": actor_id,
		"target_id": target_id,
		"event_type": event_type,
		"skill_id": skill_id,
	}


func format_line() -> String:
	return "%.2f %s -> %s %s %s" % [
		timestamp,
		String(actor_id),
		String(target_id),
		String(event_type),
		String(skill_id),
	]
