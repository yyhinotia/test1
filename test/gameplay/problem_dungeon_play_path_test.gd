extends GdUnitTestSuite

## 玩法层：问题秘境在正常主场景路径上的可达性与首通奖励链（INC-TESTING-020）。
##
## 待回答：F5 进入的默认秘境，玩家是否真的能在清空首间房后拿到定身术，
## 并且能在本局结束后切换到试炼秘境——而不是只在数据 / 集成层成立？

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const PROBLEM_DUNGEON_PATH: String = "res://game/world/data/dungeons/problem_dungeon.tres"
const TRIAL_DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"

const DUNGEON_RUN_PATH: String = "DungeonRun"
const DUNGEON_PANEL_PATH: String = "HUD/BottomLeftDock/DungeonPanel"
const SESSION_PATH: String = "EncounterSession"


## 安全护栏：真实主场景会改全局暂停状态，任何用例后都必须恢复。
func after_test() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _spawn_main() -> Node2D:
	var scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	var main: Node2D = scene.instantiate() as Node2D
	auto_free(main)
	add_child(main)
	return main


func _run(main: Node2D) -> DungeonRun:
	return main.get_node(DUNGEON_RUN_PATH) as DungeonRun


func _session(main: Node2D) -> EncounterSession:
	return main.get_node(SESSION_PATH) as EncounterSession


func _panel(main: Node2D) -> DungeonPanel:
	return main.get_node(DUNGEON_PANEL_PATH) as DungeonPanel


## 用真实死亡路径清空当前房间的全部敌人（问题房间用 enemy_squad，不止一个）。
func _clear_room(main: Node2D) -> void:
	for enemy: Pawn in _session(main).get_enemy_units():
		enemy.take_damage(enemy.data.defense + enemy.data.max_health + enemy.data.max_shield + 50.0)


## Gate 1 + Gate 4：默认进入问题秘境，首间首通奖励在游玩路径上解锁定身术且不自动装配。
func test_default_play_path_clears_first_problem_room_and_unlocks_binding() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var session: EncounterSession = _session(main)
	var player: Pawn = session.get_player_pawn()

	assert_str(run.get_active_dungeon().resource_path).is_equal(PROBLEM_DUNGEON_PATH)
	assert_int(run.get_depth()).is_equal(1)
	# 奖励 id 从该房间的正式资源读取，不在用例里复制数值或写死技能名。
	var first_encounter: EncounterDefinition = session.get_active_encounter()
	assert_bool(first_encounter.has_first_clear_reward()).is_true()
	var reward_id: StringName = first_encounter.first_clear_skill_reward.id
	assert_bool(player.has_learned_active_skill(reward_id)).is_false()

	_clear_room(main)
	await await_idle_frame()

	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_bool(run.is_awaiting_decision()).is_true()
	var cleared_player: Pawn = session.get_player_pawn()
	assert_bool(cleared_player.has_learned_active_skill(reward_id)).is_true()
	# 只解锁不装配：静态 Build A（御剑斩 + 护体真气）原样保留。
	assert_bool(cleared_player.has_explicit_active_skill_loadout()).is_false()


## Gate 2 + Gate 3：本局进行中选择区锁定；结算后可从面板切到试炼秘境。
func test_panel_can_switch_to_trial_only_after_the_run_is_over() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)

	# 面板选项顺序由 main.tscn 注入：0 = 试炼秘境，1 = 问题秘境；文案来自资源本身。
	var trial: DungeonDefinition = load(TRIAL_DUNGEON_PATH) as DungeonDefinition
	var problem: DungeonDefinition = load(PROBLEM_DUNGEON_PATH) as DungeonDefinition
	assert_str(panel.get_option_button(0).text).is_equal(trial.display_name)
	assert_str(panel.get_option_button(1).text).is_equal(problem.display_name)

	# 进行中：选择区锁定。
	assert_bool(panel.get_option_button(0).disabled).is_true()

	_clear_room(main)
	await await_idle_frame()
	# 等待抉择仍属进行中：此时切换等于绕过累积损耗，必须继续锁定。
	assert_bool(run.is_awaiting_decision()).is_true()
	assert_bool(panel.get_option_button(0).disabled).is_true()

	# 见好就收结束本局 → 选择区恢复；点击试炼秘境选项后秘境事实与面板一致。
	(panel.get_node("RetreatButton") as Button).pressed.emit()
	await await_idle_frame()
	assert_bool(run.is_finished()).is_true()
	assert_bool(panel.get_option_button(0).disabled).is_false()

	panel.get_option_button(0).pressed.emit()
	await await_idle_frame()

	assert_str(run.get_active_dungeon().resource_path).is_equal(TRIAL_DUNGEON_PATH)
	assert_int(run.get_depth()).is_equal(1)
	assert_str(panel.get_depth_text()).contains(str(run.get_active_dungeon().get_room_count()))