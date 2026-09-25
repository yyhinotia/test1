extends GdUnitTestSuite

## 玩法层：人工轮 CombatEvent 取证链路（INC-TESTING-014）。
##
## 验证的是「玩家实机打完一局后，入口会把只读事实追加到记录文件」这条装置链路：
## 每局结算必须落盘、第二局必须追加而不是覆盖、未结算的会话不得写文件。
## 本用例不判断玩法：它用真实 `take_damage()` 走完死亡路径只是为了触发结算信号，
## 「玩家是否重构 Build」这类结论仍然只能来自 `INC-TESTING-011` 的人工轮。

const ENTRY_SCENE_PATH: String = "res://tests/scenario_build_replay.tscn"
const SELFTEST_RECORD_PATH: String = "res://.mcp/godot-runtime/screenshots/human_replay_events_selftest.md"
const EXPECTED_ENCOUNTER_ID: String = "build_test_1v1"


func before_test() -> void:
	# 可控开局用例会暂停 SceneTree；每个用例开始前先恢复到实时运行，避免测试框架被挂住。
	get_tree().paused = false
	_remove_selftest_record()


func after_test() -> void:
	get_tree().paused = false
	_remove_selftest_record()


func _remove_selftest_record() -> void:
	if FileAccess.file_exists(SELFTEST_RECORD_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SELFTEST_RECORD_PATH))


func _read_selftest_record() -> String:
	if not FileAccess.file_exists(SELFTEST_RECORD_PATH):
		return ""
	var file: FileAccess = FileAccess.open(SELFTEST_RECORD_PATH, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


## 只碰真实 Pawn 的伤害入口，不直接改会话状态：结算必须由单位的死亡信号自然产生。
func _finish_round(session: EncounterSession) -> void:
	for enemy: Pawn in session.get_enemy_units():
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive():
			enemy.take_damage(enemy.data.defense + enemy.data.max_health + enemy.data.max_shield + 50.0)


func _spawn_entry(pause_on_start: bool = false) -> Node2D:
	var entry: Node2D = (load(ENTRY_SCENE_PATH) as PackedScene).instantiate() as Node2D
	# 自检使用独立记录路径，绝不写人工轮的 human_replay_events.md。
	entry.set("record_path", SELFTEST_RECORD_PATH)
	entry.set("pause_on_start", pause_on_start)
	auto_free(entry)
	add_child(entry)
	return entry


func _await_session(entry: Node2D) -> EncounterSession:
	# 必须等入口完成全部异步摆放并挂上记录器；只等 session 会在记录器挂载前结算第一局。
	for _frame: int in 60:
		await await_idle_frame()
		var session: EncounterSession = entry.get("session") as EncounterSession
		if session != null and bool(entry.get("entry_ready")):
			return session
	return null


## 未结算的会话不得写文件：自动化的入口体检不能污染人工轮记录。
func test_record_file_is_not_created_before_a_round_finishes() -> void:
	var entry: Node2D = _spawn_entry()
	var session: EncounterSession = await _await_session(entry)
	assert_object(session).is_not_null()
	assert_bool(bool(entry.get("record_combat_events"))).is_true()
	assert_str(String(session.get_active_encounter().id)).is_equal(EXPECTED_ENCOUNTER_ID)
	assert_int(session.get_combat_event_log().get_event_count()).is_zero()
	assert_bool(FileAccess.file_exists(SELFTEST_RECORD_PATH)).is_false()


## 每局结算落盘，第二局追加而不是覆盖，且事件行来自生产的 CombatEventLog。
func test_each_finished_round_is_appended_to_the_record() -> void:
	var entry: Node2D = _spawn_entry()
	var session: EncounterSession = await _await_session(entry)
	assert_object(session).is_not_null()

	_finish_round(session)
	await await_idle_frame()
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	var first_round: String = _read_selftest_record()
	assert_str(first_round).contains("scenario_build_replay.tscn")
	assert_str(first_round).contains("## 第 1 局")
	assert_str(first_round).contains(EXPECTED_ENCOUNTER_ID)
	assert_str(first_round).contains(EncounterSession.get_outcome_label(EncounterSession.State.PLAYER_WIN))
	assert_str(first_round).contains("combat_end")
	assert_str(first_round).contains("unit_died")
	# 首通奖励只解锁、不自动装配：记录里的装配仍是 Build A。
	assert_str(first_round).contains("binding_spell")
	assert_str(first_round).contains("sword_strike, guard_true_qi")

	assert_bool(session.restart()).is_true()
	await await_idle_frame()
	assert_int(session.get_combat_event_log().get_event_count()).is_zero()
	_finish_round(session)
	await await_idle_frame()
	var both_rounds: String = _read_selftest_record()
	assert_str(both_rounds).contains("## 第 1 局")
	assert_str(both_rounds).contains("## 第 2 局")


## 人工轮可控开局：pause_on_start 必须在入口就绪后暂停，并能恢复；
## 不传 --pause-on-start 时既有入口行为不变。
func test_pause_on_start_pauses_after_entry_is_ready() -> void:
	var entry: Node2D = _spawn_entry(true)
	# 暂停时普通 awaiter 可能挂住测试框架；使用 process_always 计时器等待。
	for _i: int in 120:
		await get_tree().create_timer(0.01, true).timeout
		if bool(entry.get("entry_ready")):
			break
	assert_bool(bool(entry.get("entry_ready"))).is_true()
	assert_bool(get_tree().paused).is_true()
	var main: Node2D = entry.get("main") as Node2D
	assert_object(main).is_not_null()
	main.call("_set_paused", false)
	await get_tree().create_timer(0.01, true).timeout
	assert_bool(get_tree().paused).is_false()
