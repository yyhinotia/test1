extends GdUnitTestSuite

## 玩法层：真实 main.tscn 上的秘境「贪不贪」闭环（INC-TESTING-008）。
##
## 待回答的问题：清空一间房之后，「继续深入」与「见好就收」是否真的通向**不同的终局与不同的收益**，
## 并且「继续深入」必须带着上一间剩下的生命 / 灵力，而不是每间满血重置？
##
## 做法：只通过主场景面板上的按钮驱动（等价于玩家点击），终局只走真实死亡路径；
## 房间数、敌人档案与灵石收益一律从 game/world/data/dungeons/ 的正式资源读取，
## 用例只断言关系（深度递增、收益累加、战败归零、损耗延续），不复制任何数值公式。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"

const DUNGEON_RUN_PATH: String = "DungeonRun"
const DUNGEON_PANEL_PATH: String = "HUD/BottomLeftDock/DungeonPanel"
const SESSION_PATH: String = "EncounterSession"
const ENCOUNTER_PANEL_PATH: String = "HUD/BottomLeftDock/EncounterPanel"
const ENEMY_PAWN_PATH: String = "Pawns/EnemyPawn"


## 安全护栏：真实主场景会改全局暂停状态，任何用例后都必须恢复。
func after_test() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _spawn_main() -> Node2D:
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node2D = scene.instantiate()
	auto_free(main)
	add_child(main)
	return main


func _run(main: Node2D) -> DungeonRun:
	return main.get_node(DUNGEON_RUN_PATH) as DungeonRun


func _panel(main: Node2D) -> DungeonPanel:
	return main.get_node(DUNGEON_PANEL_PATH) as DungeonPanel


func _session(main: Node2D) -> EncounterSession:
	return main.get_node(SESSION_PATH) as EncounterSession


func _encounter_panel(main: Node2D) -> EncounterPanel:
	return main.get_node(ENCOUNTER_PANEL_PATH) as EncounterPanel


func _load_dungeon() -> DungeonDefinition:
	return load(DUNGEON_PATH) as DungeonDefinition


## 玩家按键等价物：程序化按下面板按钮，测试不直接调用 DungeonRun.advance / retreat。
func _press(main: Node2D, button_name: String) -> bool:
	var button: Button = _panel(main).get_node_or_null(NodePath(button_name)) as Button
	if button == null:
		return false
	button.pressed.emit()
	return true


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 用真实死亡路径清空当前房间（不直接改 DungeonRun 状态）。
func _clear_current_room(main: Node2D) -> void:
	var enemy: Pawn = _session(main).get_enemy_pawn()
	enemy.take_damage(_lethal_damage(enemy))


## 把当前玩家打到「非满血非满灵力」：用于验证下一间真的带着损耗开局。
func _wear_down_player(main: Node2D, health_loss: float, spirit_loss: float) -> Vector2:
	var player: Pawn = _session(main).get_player_pawn()
	player.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID).decrease(health_loss, &"test")
	player.get_resource_pool(Pawn.SPIRIT_RESOURCE_ID).decrease(spirit_loss, &"test")
	return Vector2(player.current_health, player.current_spirit)


func test_boot_enters_definition_first_room_and_locks_single_encounter_entry() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)
	var session: EncounterSession = _session(main)
	var dungeon: DungeonDefinition = _load_dungeon()

	# 开机即进入秘境第 1 间，深度 / 层数 / 收益都与正式秘境资源一致。
	assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
	assert_int(run.get_depth()).is_equal(1)
	assert_int(run.get_room_count()).is_equal(dungeon.get_room_count())
	assert_int(run.get_earned_spirit_stones()).is_zero()
	assert_bool(run.is_active()).is_true()
	assert_str(String(session.get_enemy_pawn().data.id)).is_equal(
		String(dungeon.get_room(0).encounter.enemy_profile.id)
	)
	assert_str(run.get_active_dungeon().resource_path).is_equal(DUNGEON_PATH)
	# 面板不在用例里造数据：分层 / 收益文案来自 DungeonRun 的事实。
	assert_str(panel.get_depth_text()).contains(str(dungeon.get_room_count()))
	assert_str(panel.get_reward_text()).contains("0")
	assert_bool(panel.is_awaiting_decision()).is_false()
	# 秘境进行中，单场入口与「重新挑战」都被锁住（否则等于送一次满状态重开）。
	assert_bool(_encounter_panel(main).is_running()).is_true()
	assert_bool((_encounter_panel(main).get_node("RestartButton") as Button).disabled).is_true()


func test_clearing_room_awaits_decision_and_accumulates_definition_reward() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)
	var dungeon: DungeonDefinition = _load_dungeon()

	_clear_current_room(main)
	await await_idle_frame()

	var first_reward: int = dungeon.get_room_reward(0)
	assert_int(run.get_state()).is_equal(DungeonRun.State.AWAITING_DECISION)
	assert_bool(run.is_awaiting_decision()).is_true()
	assert_int(run.get_earned_spirit_stones()).is_equal(first_reward)
	assert_str(panel.get_status_text()).contains(
		DungeonRun.get_outcome_label(DungeonRun.State.AWAITING_DECISION)
	)
	assert_str(panel.get_reward_text()).contains(str(first_reward))
	# 等待抉择时两个入口可用，重开仍被锁住。
	assert_bool(panel.is_awaiting_decision()).is_true()
	assert_bool((panel.get_node("AdvanceButton") as Button).disabled).is_false()
	assert_bool((panel.get_node("RetreatButton") as Button).disabled).is_false()
	assert_bool((panel.get_node("RestartButton") as Button).disabled).is_true()
	# 本局还没结束：单场入口必须仍然锁着。
	assert_bool(_encounter_panel(main).is_running()).is_true()


func test_retreat_keeps_reward_and_creates_no_new_encounter() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)
	var session: EncounterSession = _session(main)
	var dungeon: DungeonDefinition = _load_dungeon()

	_clear_current_room(main)
	await await_idle_frame()
	var accumulated: int = dungeon.get_room_reward(0)
	var encounter_before: EncounterDefinition = session.get_active_encounter()
	var player_id_before: int = session.get_player_pawn().get_instance_id()

	assert_bool(_press(main, "RetreatButton")).is_true()
	await await_idle_frame()

	assert_int(run.get_state()).is_equal(DungeonRun.State.RETREATED)
	assert_bool(run.is_finished()).is_true()
	# 见好就收：收益保留，且不创建新对局。
	assert_int(run.get_earned_spirit_stones()).is_equal(accumulated)
	assert_object(session.get_active_encounter()).is_same(encounter_before)
	assert_int(session.get_player_pawn().get_instance_id()).is_equal(player_id_before)
	assert_str(panel.get_status_text()).contains(
		DungeonRun.get_outcome_label(DungeonRun.State.RETREATED)
	)
	assert_str(panel.get_status_text()).contains(str(accumulated))
	assert_bool(panel.is_can_restart()).is_true()
	assert_bool(_encounter_panel(main).is_running()).is_false()

	# 结算后再点「继续深入」不得复活本局（面板兜底 + DungeonRun 状态机双重保护）。
	assert_bool(_press(main, "AdvanceButton")).is_true()
	assert_int(run.get_state()).is_equal(DungeonRun.State.RETREATED)
	assert_int(run.get_earned_spirit_stones()).is_equal(accumulated)


func test_restart_starts_a_fresh_run_at_depth_one_with_zero_reward() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)
	var session: EncounterSession = _session(main)
	var dungeon: DungeonDefinition = _load_dungeon()

	_clear_current_room(main)
	await await_idle_frame()
	assert_bool(_press(main, "RetreatButton")).is_true()
	await await_idle_frame()
	assert_bool(panel.is_can_restart()).is_true()

	assert_bool(_press(main, "RestartButton")).is_true()
	await await_idle_frame()

	assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
	assert_int(run.get_depth()).is_equal(1)
	assert_int(run.get_earned_spirit_stones()).is_zero()
	assert_bool(panel.is_awaiting_decision()).is_false()
	assert_bool(panel.is_can_restart()).is_false()
	# 新一局第 1 间仍是满状态起局，且敌人回到第 1 间定义的档案。
	var player: Pawn = session.get_player_pawn()
	assert_float(player.current_health).is_equal(player.data.max_health)
	assert_str(String(session.get_enemy_pawn().data.id)).is_equal(
		String(dungeon.get_room(0).encounter.enemy_profile.id)
	)


func test_advancing_carries_previous_room_losses_into_next_room() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)
	var session: EncounterSession = _session(main)
	var dungeon: DungeonDefinition = _load_dungeon()

	_clear_current_room(main)
	await await_idle_frame()
	var old_player: Pawn = session.get_player_pawn()
	var old_player_id: int = old_player.get_instance_id()
	# 让「上一间的剩余状态」是一个明确的非满值，而不是依赖随机战斗结果。
	var carried: Vector2 = _wear_down_player(main, old_player.data.max_health * 0.4, old_player.max_spirit * 0.5)
	assert_float(carried.x).is_less(old_player.data.max_health)
	assert_float(carried.y).is_less(old_player.max_spirit)

	assert_bool(_press(main, "AdvanceButton")).is_true()
	await await_idle_frame()

	assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
	assert_int(run.get_depth()).is_equal(2)
	assert_str(panel.get_depth_text()).contains("2")
	# 收益只在清空房间时累加：刚进第 2 间仍是第 1 间的收益。
	assert_int(run.get_earned_spirit_stones()).is_equal(dungeon.get_room_reward(0))
	# 敌人换成第 2 间定义的档案，玩家单位被真实重建（不是原地满血续用）。
	var new_player: Pawn = session.get_player_pawn()
	assert_bool(new_player.get_instance_id() == old_player_id).is_false()
	assert_str(String(session.get_enemy_pawn().data.id)).is_equal(
		String(dungeon.get_room(1).encounter.enemy_profile.id)
	)
	# 贪的代价：生命 / 灵力带着上一间的损耗进入下一间。
	assert_float(new_player.current_health).is_equal(carried.x)
	assert_float(new_player.current_spirit).is_equal(carried.y)
	assert_float(new_player.current_health).is_less(new_player.data.max_health)
	assert_float(new_player.current_spirit).is_less(new_player.max_spirit)


func test_defeat_zeroes_run_rewards_and_matches_panel_status() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var run: DungeonRun = _run(main)
	var panel: DungeonPanel = _panel(main)
	var session: EncounterSession = _session(main)
	var dungeon: DungeonDefinition = _load_dungeon()

	_clear_current_room(main)
	await await_idle_frame()
	assert_bool(_press(main, "AdvanceButton")).is_true()
	await await_idle_frame()
	# 进第 2 间时手里已经有第 1 间的收益，战败必须让它归零。
	assert_int(run.get_earned_spirit_stones()).is_equal(dungeon.get_room_reward(0))

	var player: Pawn = session.get_player_pawn()
	player.take_damage(_lethal_damage(player))
	await await_idle_frame()

	assert_int(run.get_state()).is_equal(DungeonRun.State.DEFEATED)
	assert_bool(run.is_finished()).is_true()
	assert_int(run.get_earned_spirit_stones()).is_zero()
	assert_str(panel.get_status_text()).contains(
		DungeonRun.get_outcome_label(DungeonRun.State.DEFEATED)
	)
	assert_str(panel.get_status_text()).contains("0")
	assert_bool(panel.is_awaiting_decision()).is_false()
	assert_bool(panel.is_can_restart()).is_true()
	assert_bool(_encounter_panel(main).is_running()).is_false()

	# 结算后推进 / 撤退不再改变本局结论与收益。
	assert_bool(_press(main, "AdvanceButton")).is_true()
	assert_bool(_press(main, "RetreatButton")).is_true()
	assert_int(run.get_state()).is_equal(DungeonRun.State.DEFEATED)
	assert_int(run.get_earned_spirit_stones()).is_zero()
