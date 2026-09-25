extends GdUnitTestSuite

## 玩法层：真实 main.tscn 上的秘境遭遇闭环（INC-CORE-008 / INC-TESTING-007）。
##
## 待回答的问题：玩家在实机里选不同秘境遭遇，是否真的换掉敌人并给出可读结果，
## 而不是只换文案、或者在换敌时留下悬空引用？
##
## 做法：只通过「面板按钮按下 = 玩家点击」这一条入口驱动主场景，
## 用固定 60fps 时间步推进真实 Pawn / PlayerController / AIController 到终局。
## 敌人档案全部来自 game/world/data/encounters/ 的正式遭遇资源，用例不复制任何伤害或胜负公式。
##
## INC-CORE-009 起主场景开机即进入秘境第 1 间房：只要秘境还在进行（`DungeonRun.is_active()`），
## 单场遭遇入口（换敌 / 重新挑战）就保持锁定，本文件的换敌用例先「见好就收」结束本局再换。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const DELTA: float = 1.0 / 60.0
## 终局上限 60 秒，与既有 gameplay 用例同一口径；到点未分胜负即视为未结算，不伪造结果。
const MAX_STEPS: int = 3600

const SESSION_PATH: String = "EncounterSession"
const PANEL_PATH: String = "HUD/BottomLeftDock/EncounterPanel"
const INFO_PANEL_PATH: String = "HUD/BottomLeftDock/PawnInfoPanel"
const SKILL_BAR_PATH: String = "HUD/BottomLeftDock/SkillBar"
const SELECTED_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/SelectedLabel"
const PAWNS_PATH: String = "Pawns"
const ENEMY_PAWN_PATH: String = "Pawns/EnemyPawn"

const ENCOUNTER_DIR: String = "res://game/world/data/encounters/"
const DUNGEON_RUN_PATH: String = "DungeonRun"
const DUNGEON_PANEL_PATH: String = "HUD/BottomLeftDock/DungeonPanel"


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


func _session(main: Node2D) -> EncounterSession:
	return main.get_node(SESSION_PATH) as EncounterSession


func _panel(main: Node2D) -> EncounterPanel:
	return main.get_node(PANEL_PATH) as EncounterPanel


func _dungeon_run(main: Node2D) -> DungeonRun:
	return main.get_node(DUNGEON_RUN_PATH) as DungeonRun


func _dungeon_panel(main: Node2D) -> DungeonPanel:
	return main.get_node(DUNGEON_PANEL_PATH) as DungeonPanel


func _restart_button(panel: EncounterPanel) -> Button:
	return panel.get_node("RestartButton") as Button


## 程序化按下秘境面板按钮：面板自身的兜底与遭遇面板同构，非法状态不转发。
func _press_dungeon_button(main: Node2D, button_name: String) -> bool:
	var button: Button = _dungeon_panel(main).get_node_or_null(NodePath(button_name)) as Button
	if button == null:
		return false
	button.pressed.emit()
	return true


## 唯一换遭遇入口：按按钮文案找到面板按钮并按下，测试不直接调用 EncounterSession.begin。
func _press_encounter_button(main: Node2D, display_name: String) -> bool:
	for button: Button in _panel(main).get_encounter_buttons():
		if button.text == display_name:
			button.pressed.emit()
			return true
	return false


func _encounter_for_player_facing(main: Node2D, display_name: String) -> EncounterDefinition:
	for candidate: EncounterDefinition in _panel(main).encounters:
		if candidate != null and candidate.display_name == display_name:
			return candidate
	return null


## 关掉引擎物理帧，改为手工固定步进，保证终局可重复。
func _isolate_units(main: Node2D) -> void:
	var session: EncounterSession = _session(main)
	for pawn: Pawn in [session.get_player_pawn(), session.get_enemy_pawn()]:
		pawn.set_physics_process(false)
		var controller: PawnController = pawn.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


func _run_until_settled(main: Node2D) -> int:
	var session: EncounterSession = _session(main)
	var player: Pawn = session.get_player_pawn()
	var enemy: Pawn = session.get_enemy_pawn()
	var player_controller: PlayerController = player.get_controller() as PlayerController
	var ai_controller: AIController = enemy.get_controller() as AIController
	player_controller.order_attack(enemy)
	for _step: int in MAX_STEPS:
		player_controller.update_controller(DELTA)
		ai_controller.update_controller(DELTA)
		player._physics_process(DELTA)
		enemy._physics_process(DELTA)
		if session.get_state() != EncounterSession.State.RUNNING:
			break
	return session.get_state()


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


func test_main_scene_boots_into_default_encounter() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var session: EncounterSession = _session(main)
	var panel: EncounterPanel = _panel(main)
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_object(session.get_active_encounter()).is_not_null()
	assert_object(panel.get_active_encounter()).is_same(session.get_active_encounter())
	# 面板文案与真实对局一致，而不是写死的静态文本。
	assert_str(panel.get_status_text()).contains(EncounterSession.get_outcome_label(EncounterSession.State.RUNNING))
	assert_bool(panel.is_running()).is_true()
	# 开机默认对局的敌人就是初始遭遇定义的敌人档案。
	assert_str(String(main.get_node(ENEMY_PAWN_PATH).data.id)).is_equal(
		String(session.get_active_encounter().enemy_profile.id)
	)


func test_every_panel_button_maps_to_a_formal_encounter_resource() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var buttons: Array[Button] = _panel(main).get_encounter_buttons()
	assert_int(buttons.size()).is_equal(_panel(main).encounters.size())
	for index: int in buttons.size():
		var encounter: EncounterDefinition = _panel(main).encounters[index]
		# 结果不依赖测试自造数值：进入的必须是仓库里的正式遭遇资源。
		assert_str(encounter.resource_path).starts_with(ENCOUNTER_DIR)
		assert_bool(encounter.is_configured()).is_true()
		# 单人遭遇用 enemy_profile，1vN 遭遇用 enemy_squad：至少一侧必须是正式敌人档案，
		# 且敌人数与站位一一对应（INC-WORLD-007 的 1v2 / 1v3 就是队伍路径）。
		assert_bool(encounter.enemy_profile != null or encounter.enemy_squad != null).is_true()
		assert_int(encounter.get_enemy_count()).is_equal(encounter.get_enemy_spawn_offsets().size())
		assert_str(buttons[index].text).is_equal(encounter.display_name)


func test_pressing_button_swaps_enemy_and_keeps_all_references_on_new_units() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var session: EncounterSession = _session(main)
	var panel: EncounterPanel = _panel(main)
	var old_player: Pawn = session.get_player_pawn()
	var old_enemy: Pawn = main.get_node(ENEMY_PAWN_PATH)
	var old_enemy_id: int = old_enemy.get_instance_id()
	var old_player_id: int = old_player.get_instance_id()
	_isolate_units(main)
	# 手动选中玩家，等价于玩家左键点自己：这样换遭遇后才有「选中态跟着新单位走」可验证。
	main.call("_set_selected_pawn", old_player)

	# 秘境语义（INC-CORE-009）：清空一间房只是本局的一步，单场入口必须继续锁着，
	# 否则玩家能绕过 DungeonRun 直接换敌，把累积的损耗洗掉。
	var run: DungeonRun = _dungeon_run(main)
	var enemy: Pawn = session.get_enemy_pawn()
	enemy.take_damage(_lethal_damage(enemy))
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_bool(run.is_awaiting_decision()).is_true()
	assert_bool(panel.is_running()).is_true()
	assert_bool(_restart_button(panel).disabled).is_true()

	var blocked_encounter: EncounterDefinition = panel.encounters[1]
	assert_bool(_press_encounter_button(main, blocked_encounter.display_name)).is_true()
	# 锁定不靠 disabled：程序化触发同样不换敌，敌人仍是本间的那一个。
	assert_str(String(main.get_node(ENEMY_PAWN_PATH).data.id)).is_equal(String(old_enemy.data.id))

	# 见好就收结束本局 → 单场入口与重新挑战恢复可用，此时换敌才真的发生。
	assert_bool(_press_dungeon_button(main, "RetreatButton")).is_true()
	assert_bool(run.is_finished()).is_true()
	assert_bool(panel.is_running()).is_false()
	assert_bool(_restart_button(panel).disabled).is_false()

	var target_encounter: EncounterDefinition = panel.encounters[1]
	assert_bool(_press_encounter_button(main, target_encounter.display_name)).is_true()
	await await_idle_frame()

	var pawns: Node2D = main.get_node(PAWNS_PATH)
	var new_player: Pawn = session.get_player_pawn()
	var new_enemy: Pawn = main.get_node(ENEMY_PAWN_PATH)
	# 换敌不是只改文案：敌人单位本身被替换，旧敌人已经离开 Pawns 容器。
	assert_bool(new_enemy.get_instance_id() == old_enemy_id).is_false()
	assert_int(pawns.get_child_count()).is_equal(2)
	for child: Node in pawns.get_children():
		assert_bool(child.get_instance_id() == old_enemy_id).is_false()
	assert_object(new_enemy.get_parent()).is_same(pawns)
	assert_str(String(new_enemy.data.id)).is_equal(String(target_encounter.enemy_profile.id))

	# 引用完整性：玩家单位也被重建，且所有持有 Pawn 的 UI 都指向新单位。
	assert_bool(new_player.get_instance_id() == old_player_id).is_false()
	assert_bool(is_instance_valid(new_player)).is_true()
	assert_bool(new_player.is_alive()).is_true()
	assert_object(new_player.get_parent()).is_same(pawns)
	assert_object((main.get_node(SKILL_BAR_PATH) as SkillBar).get_bound_pawn()).is_same(new_player)
	assert_object((main.get_node(INFO_PANEL_PATH) as PawnInfoPanel).get_bound_pawn()).is_same(new_player)
	var selected_label: Label = main.get_node(SELECTED_LABEL_PATH)
	assert_str(selected_label.text).contains(new_player.data.display_name)
	assert_str(_panel(main).get_status_text()).contains(target_encounter.display_name)


func test_settlement_matches_panel_status_and_repeats_once() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var session: EncounterSession = _session(main)
	var panel: EncounterPanel = _panel(main)
	_isolate_units(main)

	var outcome: int = _run_until_settled(main)
	var status_text: String = panel.get_status_text()

	# 只断言「结果与状态一致」，不预设谁一定会赢。
	assert_bool(outcome == EncounterSession.State.PLAYER_WIN or outcome == EncounterSession.State.ENEMY_WIN).is_true()
	assert_int(session.get_state()).is_equal(outcome)
	assert_str(status_text).contains(EncounterSession.get_outcome_label(outcome))
	assert_str(status_text).contains(session.get_active_encounter().display_name)
	# 秘境语义：一间房结算不等于本局结算——本局还在进行时单场入口保持锁定，结束才恢复。
	var run: DungeonRun = _dungeon_run(main)
	assert_bool(panel.is_running()).is_equal(run.is_active())

	# 重复死亡信号不得二次结算：单场状态、面板文案、秘境状态与收益都不许被改写。
	var dungeon_state: int = run.get_state()
	var earned: int = run.get_earned_spirit_stones()
	var enemy: Pawn = session.get_enemy_pawn()
	enemy.died.emit(enemy)
	assert_int(session.get_state()).is_equal(outcome)
	assert_str(panel.get_status_text()).is_equal(status_text)
	assert_int(run.get_state()).is_equal(dungeon_state)
	assert_int(run.get_earned_spirit_stones()).is_equal(earned)
	await await_idle_frame()


func test_player_can_switch_encounter_after_defeat() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()
	var session: EncounterSession = _session(main)
	var panel: EncounterPanel = _panel(main)
	_isolate_units(main)
	var player: Pawn = session.get_player_pawn()

	player.take_damage(_lethal_damage(player))
	assert_int(session.get_state()).is_equal(EncounterSession.State.ENEMY_WIN)
	assert_bool(panel.is_running()).is_false()
	assert_str(panel.get_status_text()).contains(EncounterSession.get_outcome_label(EncounterSession.State.ENEMY_WIN))

	# 失败之后仍然可以改选其它秘境遭遇，并立刻开始新一轮对局。
	var next_encounter: EncounterDefinition = panel.encounters[2]
	assert_bool(_press_encounter_button(main, next_encounter.display_name)).is_true()
	await await_idle_frame()

	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_bool(panel.is_running()).is_true()
	assert_str(String(main.get_node(ENEMY_PAWN_PATH).data.id)).is_equal(
		String(next_encounter.enemy_profile.id)
	)
	assert_str(panel.get_status_text()).contains(next_encounter.display_name)
