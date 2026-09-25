extends GdUnitTestSuite

## 玩法层：真实 main.tscn 上的秘境遭遇闭环（INC-CORE-008 / INC-TESTING-007）。
##
## 待回答的问题：玩家在实机里选不同秘境遭遇，是否真的换掉敌人并给出可读结果，
## 而不是只换文案、或者在换敌时留下悬空引用？
##
## 做法：只通过「面板按钮按下 = 玩家点击」这一条入口驱动主场景，
## 用固定 60fps 时间步推进真实 Pawn / PlayerController / AIController 到终局。
## 敌人档案全部来自 game/world/data/encounters/ 的正式遭遇资源，用例不复制任何伤害或胜负公式。

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
		assert_object(encounter.enemy_profile).is_not_null()
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

	# 战斗进行中面板禁止换敌：先结束当前对局（击败敌人，玩家存活），再改选其它遭遇。
	var enemy: Pawn = session.get_enemy_pawn()
	enemy.take_damage(_lethal_damage(enemy))
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_bool(panel.is_running()).is_false()
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
	# 结算后回到可选状态，重新挑战可用。
	assert_bool(panel.is_running()).is_false()
	for button: Button in panel.get_encounter_buttons():
		assert_bool(button.disabled).is_false()

	# 重复死亡信号不得二次结算，也不得改写面板结论。
	var enemy: Pawn = session.get_enemy_pawn()
	enemy.died.emit(enemy)
	assert_int(session.get_state()).is_equal(outcome)
	assert_str(panel.get_status_text()).is_equal(status_text)
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
