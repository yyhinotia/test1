extends GdUnitTestSuite

## 集成层：SectPanel 的只读展示与信号边界（INC-UI-016）。
## 面板不持有 SectState、不扣资源、不升级设施；测试只观察它如何把状态映射成文本与信号。

const PANEL_SCENE_PATH: String = "res://game/ui/sect_panel.tscn"
const FACILITY_DIR: String = "res://game/sect/data/facilities"
const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const FACILITY_IDS: Array[String] = [
	"cave_dwelling",
	"spirit_array",
	"spirit_field",
	"alchemy_room",
	"forge_room",
	"scripture_pavilion",
]


func _load_facilities() -> Array[SectFacilityDefinition]:
	var result: Array[SectFacilityDefinition] = []
	for facility_id: String in FACILITY_IDS:
		result.append(load("%s/%s.tres" % [FACILITY_DIR, facility_id]) as SectFacilityDefinition)
	return result


func _spawn_state() -> SectState:
	var state: SectState = SectState.new()
	state.name = "SectPanelState"
	state.facilities = _load_facilities()
	auto_free(state)
	add_child(state)
	return state


func _spawn_player() -> Pawn:
	var scene: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _spawn_panel() -> SectPanel:
	var scene: PackedScene = load(PANEL_SCENE_PATH) as PackedScene
	var panel: SectPanel = scene.instantiate() as SectPanel
	auto_free(panel)
	add_child(panel)
	return panel


func _action_button(panel: SectPanel, node_name: String) -> Button:
	return panel.get_node(node_name) as Button


func _make_technique(id: StringName) -> TechniqueDefinition:
	var technique: TechniqueDefinition = TechniqueDefinition.new()
	technique.id = id
	technique.display_name = String(id)
	return technique


func _count_descendant_pawns(node: Node) -> int:
	var total: int = 0
	for child: Node in node.get_children():
		if child is Pawn:
			total += 1
		total += _count_descendant_pawns(child)
	return total


func test_unbound_panel_uses_placeholders_and_forwards_nothing() -> void:
	var panel: SectPanel = _spawn_panel()
	var events: Array[StringName] = []
	panel.upgrade_requested.connect(func(facility_id: StringName) -> void: events.append(facility_id))
	panel.cultivate_requested.connect(func() -> void: events.append(&"cultivate"))
	panel.harvest_requested.connect(func() -> void: events.append(&"harvest"))
	panel.strengthen_requested.connect(func() -> void: events.append(&"strengthen"))
	panel.refine_pill_requested.connect(func() -> void: events.append(&"refine"))
	panel.use_pill_requested.connect(func() -> void: events.append(&"use"))

	assert_bool(panel.is_bound()).is_false()
	assert_str(panel.get_spirit_stones_text()).is_equal("灵石：-")
	assert_str(panel.get_spirit_herbs_text()).is_equal("灵草：-")
	assert_str(panel.get_pills_text()).is_equal("丹药：-")
	assert_int(panel.get_facility_count()).is_zero()
	assert_int(_count_descendant_pawns(panel)).is_zero()
	assert_str(panel.get_status_text()).is_equal(SectPanel.EMPTY_STATUS)

	_action_button(panel, "CultivateButton").pressed.emit()
	_action_button(panel, "HarvestButton").pressed.emit()
	_action_button(panel, "StrengthenButton").pressed.emit()
	_action_button(panel, "RefinePillButton").pressed.emit()
	_action_button(panel, "UsePillButton").pressed.emit()
	assert_array(events).is_empty()


func test_binding_state_rebuilds_inventory_and_facility_rows() -> void:
	var state: SectState = _spawn_state()
	var panel: SectPanel = _spawn_panel()
	panel.bind_state(state)

	assert_bool(panel.is_bound()).is_true()
	assert_str(panel.get_spirit_stones_text()).is_equal("灵石：0")
	assert_str(panel.get_spirit_herbs_text()).is_equal("灵草：0")
	assert_str(panel.get_pills_text()).is_equal("丹药：0")
	assert_int(panel.get_facility_count()).is_equal(FACILITY_IDS.size())
	for facility_id: String in FACILITY_IDS:
		var button: Button = panel.get_upgrade_button(StringName(facility_id))
		assert_object(button).is_not_null()
		assert_bool(button.disabled).is_true()
		assert_str(panel.get_upgrade_reason_text(StringName(facility_id))).is_equal("灵石不足")


func test_state_changes_refresh_texts_and_upgrade_availability() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	var panel: SectPanel = _spawn_panel()
	panel.bind_state(state)

	state.deposit_spirit_stones(250)
	assert_str(panel.get_spirit_stones_text()).is_equal("灵石：250")
	var cave_button: Button = panel.get_upgrade_button(SectState.FACILITY_CAVE_DWELLING)
	assert_bool(cave_button.disabled).is_false()
	assert_str(panel.get_upgrade_reason_text(SectState.FACILITY_CAVE_DWELLING)).is_equal("可升级")

	state.harvest_spirit_field()
	assert_str(panel.get_spirit_herbs_text()).is_equal("灵草：2")
	assert_int(state.refine_pill()).is_equal(1)
	assert_str(panel.get_pills_text()).is_equal("丹药：1")
	assert_bool(_action_button(panel, "UsePillButton").disabled).is_false()

	state.upgrade_facility(SectState.FACILITY_CAVE_DWELLING)
	assert_str(panel.get_upgrade_reason_text(SectState.FACILITY_SPIRIT_ARRAY)).is_equal("可升级")
	assert_bool(panel.get_upgrade_button(SectState.FACILITY_SPIRIT_ARRAY).disabled).is_false()


func test_upgrade_button_only_forwards_an_available_action() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	var panel: SectPanel = _spawn_panel()
	panel.bind_state(state)
	var requested: Array[StringName] = []
	panel.upgrade_requested.connect(func(facility_id: StringName) -> void: requested.append(facility_id))

	var blocked_button: Button = panel.get_upgrade_button(SectState.FACILITY_CAVE_DWELLING)
	blocked_button.pressed.emit()
	assert_array(requested).is_empty()

	state.deposit_spirit_stones(250)
	var available_button: Button = panel.get_upgrade_button(SectState.FACILITY_CAVE_DWELLING)
	available_button.pressed.emit()
	assert_array(requested).contains_exactly([SectState.FACILITY_CAVE_DWELLING])
	assert_int(state.get_facility_level(SectState.FACILITY_CAVE_DWELLING)).is_equal(1)


func test_action_buttons_forward_player_intent_without_settling() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	var panel: SectPanel = _spawn_panel()
	panel.bind_state(state)
	state.harvest_spirit_field()
	state.harvest_spirit_field()
	assert_int(state.refine_pill()).is_equal(1)

	var events: Array[StringName] = []
	panel.cultivate_requested.connect(func() -> void: events.append(&"cultivate"))
	panel.harvest_requested.connect(func() -> void: events.append(&"harvest"))
	panel.strengthen_requested.connect(func() -> void: events.append(&"strengthen"))
	panel.refine_pill_requested.connect(func() -> void: events.append(&"refine"))
	panel.use_pill_requested.connect(func() -> void: events.append(&"use"))

	_action_button(panel, "CultivateButton").pressed.emit()
	_action_button(panel, "HarvestButton").pressed.emit()
	_action_button(panel, "StrengthenButton").pressed.emit()
	_action_button(panel, "RefinePillButton").pressed.emit()
	_action_button(panel, "UsePillButton").pressed.emit()

	assert_array(events).contains_exactly([
		&"cultivate", &"harvest", &"strengthen", &"refine", &"use",
	])
	# 面板只广播意图：库存与设施等级不被它自行结算。
	assert_int(state.get_facility_level(SectState.FACILITY_FORGE_ROOM)).is_equal(1)
	assert_int(state.get_pills()).is_equal(1)


func test_learn_option_filters_invalid_entries_and_forwards_selected_id() -> void:
	var state: SectState = _spawn_state()
	var panel: SectPanel = _spawn_panel()
	panel.bind_state(state)

	var first: TechniqueDefinition = _make_technique(&"panel_learn_a")
	var second: TechniqueDefinition = _make_technique(&"panel_learn_b")
	var unconfigured: TechniqueDefinition = _make_technique(&"   ")
	panel.set_learnable_techniques([first, second, first, null, unconfigured])
	assert_int(panel.get_learnable_technique_count()).is_equal(2)

	var learn_requests: Array[StringName] = []
	panel.learn_requested.connect(func(technique_id: StringName) -> void:
		learn_requests.append(technique_id)
	)
	var option: OptionButton = panel.get_node("LearnRow/LearnOption") as OptionButton
	option.select(1)
	_action_button(panel, "LearnRow/LearnButton").pressed.emit()
	assert_array(learn_requests).contains_exactly([&"panel_learn_b"])


func test_status_is_pure_text_and_does_not_change_state() -> void:
	var state: SectState = _spawn_state()
	var panel: SectPanel = _spawn_panel()
	panel.bind_state(state)
	var stones_before: int = state.get_spirit_stones()
	panel.set_status("灵石不足：需要 40")

	assert_str(panel.get_status_text()).is_equal("灵石不足：需要 40")
	assert_str((panel.get_node("StatusLabel") as Label).text).is_equal("灵石不足：需要 40")
	assert_int(state.get_spirit_stones()).is_equal(stones_before)
