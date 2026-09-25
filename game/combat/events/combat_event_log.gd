class_name CombatEventLog
extends RefCounted

## 轻量战斗事件日志（INC-COMBAT-009）。
## 时钟与事件列表都由本对象持有；每局开局必须 reset()，防止上一局的序列污染本局对照。

var _events: Array[CombatEvent] = []
var _clock: float = 0.0


func reset() -> void:
	_events.clear()
	_clock = 0.0


func advance(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta):
		return
	_clock += delta


func get_clock() -> float:
	return _clock


func record(
		event_type: StringName,
		actor_id: StringName,
		target_id: StringName = &"",
		skill_id: StringName = &""
	) -> CombatEvent:
	if not CombatEvent.is_known_event_type(event_type):
		return null
	var event: CombatEvent = CombatEvent.create(event_type, actor_id, target_id, skill_id, _clock)
	_events.append(event)
	return event


func get_events() -> Array[CombatEvent]:
	var result: Array[CombatEvent] = []
	result.assign(_events)
	return result


func get_event_count() -> int:
	return _events.size()


func get_event_types() -> Array[StringName]:
	var result: Array[StringName] = []
	for event: CombatEvent in _events:
		result.append(event.event_type)
	return result


func has_event_type(event_type: StringName) -> bool:
	return get_index_of_event_type(event_type) >= 0


func get_index_of_event_type(event_type: StringName) -> int:
	for index: int in _events.size():
		if _events[index].event_type == event_type:
			return index
	return -1


func count_events_of_type(event_type: StringName) -> int:
	var count: int = 0
	for event: CombatEvent in _events:
		if event.event_type == event_type:
			count += 1
	return count


func get_first_event_of_type(event_type: StringName) -> CombatEvent:
	var index: int = get_index_of_event_type(event_type)
	return _events[index] if index >= 0 else null


func describe() -> Array[String]:
	var lines: Array[String] = []
	for event: CombatEvent in _events:
		lines.append(event.format_line())
	return lines
