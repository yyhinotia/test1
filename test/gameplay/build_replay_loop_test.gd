extends GdUnitTestSuite

## 玩法层：Build Replay 实验闭环（INC-TESTING-011）。
##
## 待回答的问题（docs/build-gameplay-validation.md §6 / §8）：
##   第一轮有一处「只能硬吃」的战斗问题 → 首通只解锁新能力 → 玩家主动重构 Build →
##   第二轮用新能力改变危险窗口的应对方式，而不是只换数值。
##
## 做法：在真实 `main.tscn` 上驱动脚本化 Replay（Round 1 = Build A 不干预，Round 2 = Build B 用定身），
## 断言只落在机制事实与 CombatEvent 客观判据上；驱动器与取证脚本共用 `test/tools/build_replay_driver.gd`。
## 「玩家是否愿意为了这个问题重构 Build」只能由玩家原话判定，本文件不得代出结论。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const BINDING_SKILL_ID: String = "binding_spell"
const SWORD_SKILL_ID: String = "sword_strike"
const GUARD_SKILL_ID: String = "guard_true_qi"
## Round 1 / Round 2 各只推进一次危险窗口（约 10.3s）；跨局累积计时会立刻超过这个上限。
const SINGLE_ROUND_MAX_SECONDS: float = 12.0
const APPROX: float = 0.001


## 安全护栏：真实主场景会改全局暂停状态，任何用例后都必须恢复。
func after_test() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _run_scripted_replay() -> Dictionary:
	var main: Node2D = BuildReplayDriver.instantiate_main_without_dungeon(self)
	auto_free(main)
	await await_idle_frame()
	return await BuildReplayDriver.run_scripted_replay(main)


func _round(record: Dictionary, label: String) -> Dictionary:
	return record.get(label, {}) as Dictionary


func _sequence(round_record: Dictionary, key: String) -> Array:
	return round_record.get(key, []) as Array


## 机制事实：第一轮无控制必被命中，首通只解锁不自动装配，面板可切换且技能栏当帧跟随。
func test_round_one_hits_without_control_and_reward_only_unlocks_build_b() -> void:
	var record: Dictionary = await _run_scripted_replay()
	var round_one: Dictionary = _round(record, BuildReplayDriver.ROUND_1_LABEL)
	var first_clear: Dictionary = record.get("first_clear", {}) as Dictionary
	var switch_result: Dictionary = record.get("build_switch", {}) as Dictionary

	# Round 1：Build A 下危险窗口真实打开且无法干预，只能用身体记住这个麻烦。
	assert_bool(round_one.get("danger_window_opened", false) as bool).is_true()
	assert_str(String(round_one.get("dangerous_skill_resolution", ""))).is_equal("hit")
	assert_bool(round_one.get("binding_cast", false) as bool).is_false()
	assert_bool(_sequence(round_one, "danger_window_sequence").has("skill_cancelled")).is_false()
	assert_array(round_one.get("equipped_active_skills", [])).contains_exactly([
		SWORD_SKILL_ID, GUARD_SKILL_ID,
	])
	# 承伤与时长只是对照数据，不参与通过条件（docs/build-gameplay-validation.md §8）。
	var round_one_damage: Dictionary = round_one.get("damage_taken", {}) as Dictionary
	assert_float(round_one_damage.get("health", 0.0) as float).is_greater(0.0)
	assert_float(round_one.get("duration_seconds", 0.0) as float).is_greater(0.0)

	# 首通奖励：只把定身术变成「已掌握」，绝不自动装配（Gate C 的机制前提）。
	assert_int(first_clear.get("outcome", -1) as int).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_array(first_clear.get("known_after", [])).contains(BINDING_SKILL_ID)
	assert_bool(first_clear.get("auto_equipped_by_reward", true) as bool).is_false()
	assert_array(first_clear.get("equipped_after_first_clear", [])).contains_exactly([
		SWORD_SKILL_ID, GUARD_SKILL_ID,
	])

	# 主动重构：只经由生产面板按钮，成功与原因由面板自己裁决。
	assert_bool(switch_result.get("accepted", false) as bool).is_true()
	assert_str(String(switch_result.get("reason", "?"))).is_equal(BuildLoadoutPanel.REASON_NONE)
	assert_array(switch_result.get("equipped_after", [])).contains_exactly([
		SWORD_SKILL_ID, BINDING_SKILL_ID,
	])
	# Build B 的技能真实进入技能栏，而不是只改了数据。
	assert_bool((record.get("skill_bar_after_switch", []) as Array).has(BINDING_SKILL_ID)).is_true()


## 客观判据：第二轮用定身改变危险窗口的应对方式，且事件序列不跨局污染。
func test_round_two_cancels_danger_window_and_keeps_event_log_isolated() -> void:
	var record: Dictionary = await _run_scripted_replay()
	var round_one: Dictionary = _round(record, BuildReplayDriver.ROUND_1_LABEL)
	var round_two: Dictionary = _round(record, BuildReplayDriver.ROUND_2_LABEL)
	var comparison: Dictionary = record.get("objective_comparison", {}) as Dictionary

	# Round 2：定身真实作用于敌人，危险技能被取消且该次伤害未结算。
	assert_bool(round_two.get("danger_window_opened", false) as bool).is_true()
	assert_bool(round_two.get("binding_cast", false) as bool).is_true()
	assert_bool(round_two.get("enemy_stunned_after_cast", false) as bool).is_true()
	assert_str(String(round_two.get("dangerous_skill_resolution", ""))).is_equal("cancelled_by_stun")
	assert_bool((round_two.get("event_sequence", []) as Array).has("skill_hit")).is_false()
	var window_sequence: Array = _sequence(round_two, "danger_window_sequence")
	assert_int(window_sequence.find("skill_stunned")).is_less(window_sequence.find("skill_cancelled"))
	assert_array(round_two.get("equipped_active_skills", [])).contains_exactly([
		SWORD_SKILL_ID, BINDING_SKILL_ID,
	])

	# 不跨局污染：每局都从零开始计时（Round 2 不会继承 Round 1 的时钟），且本局只有一次危险窗口。
	var round_one_seconds: float = round_one.get("duration_seconds", 0.0) as float
	var round_two_seconds: float = round_two.get("duration_seconds", 0.0) as float
	assert_float(round_one_seconds).is_less(SINGLE_ROUND_MAX_SECONDS)
	assert_float(round_two_seconds).is_less(SINGLE_ROUND_MAX_SECONDS)
	# Round 2 比 Round 1 只多推进了定身后的 STUN_SETTLE；若时钟累积，这里会是两倍。
	assert_float(round_two_seconds).is_less(round_one_seconds + 1.0)
	assert_int((round_two.get("event_sequence", []) as Array).count("danger_window_opened")).is_equal(1)
	assert_int((round_two.get("event_sequence", []) as Array).count("combat_end")).is_zero()

	# 客观对照：两轮应对序列不同才算「Build 真的改变了打法」（Failure 4 的客观判据）。
	assert_bool(comparison.get("same_window_sequence", true) as bool).is_false()
	assert_bool(comparison.get("failure_4_triggered", true) as bool).is_false()
	assert_str(String(comparison.get("round_1_resolution", ""))).is_equal("hit")
	assert_str(String(comparison.get("round_2_resolution", ""))).is_equal("cancelled_by_stun")

