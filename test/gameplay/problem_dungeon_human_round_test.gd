extends GdUnitTestSuite

## 玩法层：问题秘境人工轮入口与只读进度取证（INC-TESTING-022）。
##
## 验证的是装置链路：入口能否直接跑问题秘境、每层进度与每次 Build 变更是否落盘、记录里是不是只有事实。
## 本用例不判断「玩家是否愿意换 Build」——那只能来自 `INC-CROSS-021` 的人工轮三问。

const ENTRY_SCENE_PATH: String = "res://tests/scenario_problem_dungeon.tscn"
const PROBLEM_DUNGEON_PATH: String = "res://game/world/data/dungeons/problem_dungeon.tres"
const SELFTEST_RECORD_PATH: String = "res://.mcp/godot-runtime/screenshots/problem_dungeon_round_selftest.md"
const SELFTEST_DISABLED_PATH: String = "res://.mcp/godot-runtime/screenshots/problem_dungeon_round_selftest_disabled.md"

const DUNGEON_RUN_PATH: String = "DungeonRun"
const SESSION_PATH: String = "EncounterSession"
const DUNGEON_PANEL_PATH: String = "HUD/BottomLeftDock/DungeonPanel"
const BUILD_PANEL_PATH: String = "HUD/BuildLoadoutPanel"
const NON_BUILD_MENU_PATH: String = "HUD/BottomLeftDock/EncounterPanel/Buttons"

## 入口会改全局暂停状态，任何用例后都必须恢复，否则测试框架会被挂住。
func before_test() -> void:
	get_tree().paused = false
	_remove_file(SELFTEST_RECORD_PATH)


func after_test() -> void:
	get_tree().paused = false
	_remove_file(SELFTEST_RECORD_PATH)
	_remove_file(SELFTEST_DISABLED_PATH)


## 实例化人工轮入口并等它摆放完成；记录路径必须在入树前改写，否则会污染人工记录。
func _spawn_entry(record_enabled: bool = true) -> Node2D:
	var entry: Node2D = (load(ENTRY_SCENE_PATH) as PackedScene).instantiate() as Node2D
	entry.set("dungeon_record_path", SELFTEST_RECORD_PATH)
	entry.set("record_dungeon_progress", record_enabled)
	auto_free(entry)
	add_child(entry)
	for _i: int in 120:
		await get_tree().process_frame
		if bool(entry.get("entry_ready")):
			break
	return entry


## 入口下的正式主场景：入口只负责摆放，秘境 / HUD 节点都在它下面。
func _main_of(entry: Node2D) -> Node2D:
	return entry.get("main") as Node2D


## 用真实死亡路径清空当前房间（问题房间用 enemy_squad，不止一个敌人）。
func _clear_room(session: EncounterSession) -> void:
	for enemy: Pawn in session.get_enemy_units():
		enemy.take_damage(enemy.data.defense + enemy.data.max_health + enemy.data.max_shield + 50.0)


func _read_record(path: String = SELFTEST_RECORD_PATH) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Gate 3（入口）：入口开局即问题秘境第 1 间，秘境面板保留可见（它是被观察对象），
## 与 Build 无关的换敌菜单仍然隐藏。
func test_entry_starts_the_problem_dungeon_and_keeps_its_panel_visible() -> void:
	var entry: Node2D = await _spawn_entry()
	var run: DungeonRun = _main_of(entry).get_node(DUNGEON_RUN_PATH) as DungeonRun
	var session: EncounterSession = entry.get("session") as EncounterSession

	assert_str(run.get_active_dungeon().resource_path).is_equal(PROBLEM_DUNGEON_PATH)
	assert_int(run.get_depth()).is_equal(1)
	assert_bool(session.get_active_encounter() != null).is_true()
	assert_bool((_main_of(entry).get_node(DUNGEON_PANEL_PATH) as DungeonPanel).visible).is_true()
	assert_bool((_main_of(entry).get_node(NON_BUILD_MENU_PATH) as CanvasItem).visible).is_false()


## Gate 3（落盘）：进层与清层各写一行只读事实，清层行必须点名本层首通奖励与随后掌握的技能。
func test_clearing_a_room_appends_a_readonly_progress_line() -> void:
	var entry: Node2D = await _spawn_entry()
	var run: DungeonRun = _main_of(entry).get_node(DUNGEON_RUN_PATH) as DungeonRun
	var session: EncounterSession = entry.get("session") as EncounterSession
	var room: DungeonRoom = run.get_current_room()
	assert_bool(room != null).is_true()
	# 奖励 id 从正式房间资源读取：用例不复制数值，也不写死技能名。
	var reward_id: String = String(room.encounter.first_clear_skill_reward.id)

	_clear_room(session)
	await get_tree().process_frame

	var text: String = _read_record()
	assert_str(text).contains("# 问题秘境人工轮进度记录")
	assert_str(text).contains("第 1 层开始")
	assert_str(text).contains("第 1 层清空")
	assert_str(text).contains("首通奖励：%s" % reward_id)
	assert_str(text).contains("已掌握：")
	assert_str(text).contains("进入时装配：")


## Gate 3（Build 变更）：玩家自选组合并应用后，记录里必须出现「提交了什么 / 成没成 / 变更后装配」三项事实。
func test_custom_build_change_is_recorded_with_the_result_and_equipped_ids() -> void:
	var entry: Node2D = await _spawn_entry()
	var session: EncounterSession = entry.get("session") as EncounterSession
	var panel: BuildLoadoutPanel = _main_of(entry).get_node(BUILD_PANEL_PATH) as BuildLoadoutPanel

	# 清掉第 1 层：① 战斗中锁定随之解除，② 首通奖励解锁本层技能（奖励来自正式房间资源）。
	_clear_room(session)
	await get_tree().process_frame
	assert_bool(panel.is_switch_locked()).is_false()

	var player: Pawn = session.get_player_pawn()
	var equipped_before: Array[ActiveSkillDefinition] = player.get_equipped_active_skills()
	assert_int(equipped_before.size()).is_equal(2)
	# 新解锁技能 = 技能池里「已掌握但还没装配」的那一个；用例不写死技能 id。
	var new_skill: ActiveSkillDefinition = null
	for skill: ActiveSkillDefinition in panel.get_available_skills():
		if panel.is_skill_selectable(skill) and not equipped_before.has(skill):
			new_skill = skill
			break
	assert_object(new_skill).is_not_null()

	# 真实操作序列：先取消一个槽位，再选新技能，最后显式点「应用」——面板绝不自动应用。
	panel.get_skill_button(equipped_before[0]).pressed.emit()
	panel.get_skill_button(new_skill).pressed.emit()
	panel.get_apply_button().pressed.emit()
	await get_tree().process_frame

	assert_bool(player.is_active_skill_known(new_skill)).is_true()
	assert_array(player.get_equipped_active_skills()).contains(new_skill)
	assert_bool(player.get_equipped_active_skills().has(equipped_before[0])).is_false()

	var text: String = _read_record()
	assert_str(text).contains("自定义 Build 应用")
	assert_str(text).contains("成功")
	assert_str(text).contains("提交组合：")
	assert_str(text).contains(String(new_skill.id))
	assert_str(text).contains("变更后装配：")
	# 装配内容直接从 Pawn 读，记录行必须与它一致，而不是记录器自己编一份。
	for skill: ActiveSkillDefinition in player.get_equipped_active_skills():
		assert_str(text).contains(String(skill.id))


## 负面对照：没有开启记录时不得凭空产生记录文件——取证必须是显式开关。
func test_disabled_recording_writes_nothing() -> void:
	_remove_file(SELFTEST_DISABLED_PATH)
	var entry: Node2D = (load(ENTRY_SCENE_PATH) as PackedScene).instantiate() as Node2D
	entry.set("dungeon_record_path", SELFTEST_DISABLED_PATH)
	entry.set("record_dungeon_progress", false)
	auto_free(entry)
	add_child(entry)
	for _i: int in 120:
		await get_tree().process_frame
		if bool(entry.get("entry_ready")):
			break

	_clear_room(entry.get("session") as EncounterSession)
	await get_tree().process_frame

	assert_bool(FileAccess.file_exists(SELFTEST_DISABLED_PATH)).is_false()
