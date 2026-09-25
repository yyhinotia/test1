extends GdUnitTestSuite

## 单元层：轻量 CombatEvent 与 CombatEventLog 的数据契约（INC-COMBAT-009）。
## 本层不加载战斗场景，只锁定字段、白名单、时钟与可复核文本格式。

const APPROX: float = 0.001


func test_create_event_keeps_required_fields() -> void:
	var event: CombatEvent = CombatEvent.create(
		CombatEvent.SKILL_HIT, &"player_001", &"enemy_dungeon_boss", &"sword_strike", 3.5
	)

	assert_float(event.timestamp).is_equal_approx(3.5, APPROX)
	assert_str(String(event.actor_id)).is_equal("player_001")
	assert_str(String(event.target_id)).is_equal("enemy_dungeon_boss")
	assert_str(String(event.event_type)).is_equal("skill_hit")
	assert_str(String(event.skill_id)).is_equal("sword_strike")


func test_known_event_types_are_the_documented_whitelist() -> void:
	var types: Array[StringName] = CombatEvent.get_known_event_types()

	assert_array(types).contains_exactly([
		&"danger_window_opened",
		&"skill_cast",
		&"skill_hit",
		&"skill_blocked",
		&"skill_stunned",
		&"skill_cancelled",
		&"unit_died",
		&"combat_end",
	])
	assert_bool(CombatEvent.is_known_event_type(CombatEvent.SKILL_HIT)).is_true()
	assert_bool(CombatEvent.is_known_event_type(&"unknown_event")).is_false()


func test_unknown_event_type_is_rejected_without_mutation() -> void:
	var log: CombatEventLog = CombatEventLog.new()

	var event: CombatEvent = log.record(&"unknown_event", &"actor")

	assert_object(event).is_null()
	assert_int(log.get_event_count()).is_zero()
	assert_array(log.get_event_types()).is_empty()


func test_log_order_clock_and_reset() -> void:
	var log: CombatEventLog = CombatEventLog.new()

	log.advance(1.25)
	assert_float(log.get_clock()).is_equal_approx(1.25, APPROX)
	log.record(CombatEvent.DANGER_WINDOW_OPENED, &"boss", &"player", &"boss_cleave")
	log.advance(0.75)
	log.record(CombatEvent.SKILL_HIT, &"boss", &"player", &"boss_cleave")

	assert_int(log.get_event_count()).is_equal(2)
	assert_array(log.get_event_types()).contains_exactly([
		CombatEvent.DANGER_WINDOW_OPENED,
		CombatEvent.SKILL_HIT,
	])
	assert_int(log.count_events_of_type(CombatEvent.SKILL_HIT)).is_equal(1)
	assert_float(log.get_first_event_of_type(CombatEvent.SKILL_HIT).timestamp).is_equal_approx(2.0, APPROX)
	assert_array(log.describe()).contains_exactly([
		"1.25 boss -> player danger_window_opened boss_cleave",
		"2.00 boss -> player skill_hit boss_cleave",
	])

	log.reset()
	assert_int(log.get_event_count()).is_zero()
	assert_float(log.get_clock()).is_zero()
