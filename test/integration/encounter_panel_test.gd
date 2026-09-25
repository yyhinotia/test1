extends GdUnitTestSuite

## 集成层：EncounterPanel 的按钮映射、信号边界与运行态交互（INC-UI-014）。
##
## 面板是纯入口：它只把「玩家想进入哪一个遭遇」变成信号，
## 不实例化 Pawn、不调用 EncounterSession、不写任何战斗状态。

const PANEL_SCENE_PATH: String = "res://game/ui/encounter_panel.tscn"
const TRIAL_ENCOUNTER_PATH: String = "res://game/world/data/encounters/encounter_trial_puppet.tres"
const IRON_GUARD_ENCOUNTER_PATH: String = "res://game/world/data/encounters/encounter_iron_guard.tres"
const BLOOD_BLADE_ENCOUNTER_PATH: String = "res://game/world/data/encounters/encounter_blood_blade.tres"


func _load_encounter(path: String) -> EncounterDefinition:
	return load(path) as EncounterDefinition


func _formal_encounters() -> Array[EncounterDefinition]:
	var encounters: Array[EncounterDefinition] = []
	encounters.append(_load_encounter(TRIAL_ENCOUNTER_PATH))
	encounters.append(_load_encounter(IRON_GUARD_ENCOUNTER_PATH))
	encounters.append(_load_encounter(BLOOD_BLADE_ENCOUNTER_PATH))
	return encounters


## encounters 必须在入树前赋值，按钮在 _ready() 里按它生成。
func _spawn_panel(encounters: Array[EncounterDefinition]) -> EncounterPanel:
	var scene: PackedScene = load(PANEL_SCENE_PATH)
	var panel: EncounterPanel = scene.instantiate() as EncounterPanel
	panel.encounters = encounters
	auto_free(panel)
	add_child(panel)
	return panel


func _restart_button(panel: EncounterPanel) -> Button:
	return panel.get_node("RestartButton") as Button


func _count_descendant_pawns(node: Node) -> int:
	var total: int = 0
	for child: Node in node.get_children():
		if child is Pawn:
			total += 1
		total += _count_descendant_pawns(child)
	return total


func test_buttons_follow_configured_encounters_in_order() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())

	assert_int(panel.get_encounter_count()).is_equal(3)
	var buttons: Array[Button] = panel.get_encounter_buttons()
	var expected: Array[EncounterDefinition] = _formal_encounters()
	for index: int in buttons.size():
		assert_str(buttons[index].text).is_equal(expected[index].display_name)


func test_button_press_emits_selected_encounter_exactly_once() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())
	var selected: Array = []
	panel.encounter_selected.connect(func(encounter: EncounterDefinition) -> void:
		selected.append(encounter)
	)

	panel.get_encounter_buttons()[1].pressed.emit()

	assert_int(selected.size()).is_equal(1)
	assert_object(selected[0]).is_same(_load_encounter(IRON_GUARD_ENCOUNTER_PATH))


func test_restart_button_emits_request() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())
	var requests: Array[int] = [0]
	panel.restart_requested.connect(func() -> void:
		requests[0] += 1
	)

	_restart_button(panel).pressed.emit()

	assert_int(requests[0]).is_equal(1)


func test_running_state_blocks_encounter_buttons_but_keeps_restart_available() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())
	panel.set_active_encounter(_load_encounter(TRIAL_ENCOUNTER_PATH))
	var selected: Array = []
	panel.encounter_selected.connect(func(encounter: EncounterDefinition) -> void:
		selected.append(encounter)
	)

	panel.set_running(true)

	for button: Button in panel.get_encounter_buttons():
		assert_bool(button.disabled).is_true()
	# 运行中仍然可以重开当前对局（「重新挑战」）。
	assert_bool(_restart_button(panel).disabled).is_false()
	# 即使被程序化触发也不得转发，语义不依赖按钮的 disabled 属性。
	panel.get_encounter_buttons()[0].pressed.emit()
	assert_int(selected.size()).is_zero()

	panel.set_running(false)

	for button: Button in panel.get_encounter_buttons():
		assert_bool(button.disabled).is_false()
	panel.get_encounter_buttons()[0].pressed.emit()
	assert_int(selected.size()).is_equal(1)


func test_restart_stays_disabled_until_an_encounter_is_active() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())

	assert_bool(_restart_button(panel).disabled).is_true()

	panel.set_active_encounter(_load_encounter(TRIAL_ENCOUNTER_PATH))

	assert_bool(_restart_button(panel).disabled).is_false()


func test_empty_and_unconfigured_encounters_degrade_safely() -> void:
	var empty: EncounterPanel = _spawn_panel([] as Array[EncounterDefinition])
	assert_int(empty.get_encounter_count()).is_zero()
	assert_object(empty.get_active_encounter()).is_null()
	empty.set_active_encounter(null)
	assert_str(empty.get_status_text()).is_equal(EncounterPanel.EMPTY_STATUS)

	var sparse: Array[EncounterDefinition] = [null, EncounterDefinition.new(), _load_encounter(TRIAL_ENCOUNTER_PATH)]
	var partial: EncounterPanel = _spawn_panel(sparse)
	# 只给能真正进入的遭遇生成按钮：空槽位与未配置资源都不产生可点入口。
	assert_int(partial.get_encounter_count()).is_equal(1)
	assert_str(partial.get_encounter_buttons()[0].text).is_equal(_load_encounter(TRIAL_ENCOUNTER_PATH).display_name)


func test_status_and_active_encounter_only_update_text() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())
	var status_label: Label = panel.get_node("StatusLabel") as Label
	var title_label: Label = panel.get_node("TitleLabel") as Label
	assert_str(status_label.text).is_equal(EncounterPanel.EMPTY_STATUS)

	panel.set_status("进行中：试炼傀儡")
	panel.set_active_encounter(_load_encounter(TRIAL_ENCOUNTER_PATH))

	assert_str(panel.get_status_text()).is_equal("进行中：试炼傀儡")
	assert_str(status_label.text).is_equal("进行中：试炼傀儡")
	assert_str(title_label.text).is_equal("当前遭遇：%s" % _load_encounter(TRIAL_ENCOUNTER_PATH).display_name)
	assert_int(_count_descendant_pawns(panel)).is_zero()


func test_panel_never_spawns_units_when_browsed() -> void:
	var panel: EncounterPanel = _spawn_panel(_formal_encounters())

	for button: Button in panel.get_encounter_buttons():
		button.pressed.emit()

	assert_int(_count_descendant_pawns(panel)).is_zero()
	assert_int(panel.get_encounter_count()).is_equal(3)
