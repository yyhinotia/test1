extends GdUnitTestSuite

## 集成层：DungeonPanel 的信号边界与交互态（INC-UI-015）。
##
## 面板是纯入口：只把「继续深入 / 见好就收 / 重新开始秘境」变成信号，
## 不持有 DungeonRun、不推进房间、不累加收益，也不创建任何单位。

const PANEL_SCENE_PATH: String = "res://game/ui/dungeon_panel.tscn"
const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"


func _spawn_panel() -> DungeonPanel:
	var scene: PackedScene = load(PANEL_SCENE_PATH)
	var panel: DungeonPanel = scene.instantiate() as DungeonPanel
	auto_free(panel)
	add_child(panel)
	return panel


func _load_dungeon() -> DungeonDefinition:
	return load(DUNGEON_PATH) as DungeonDefinition


func _advance_button(panel: DungeonPanel) -> Button:
	return panel.get_node("AdvanceButton") as Button


func _retreat_button(panel: DungeonPanel) -> Button:
	return panel.get_node("RetreatButton") as Button


func _restart_button(panel: DungeonPanel) -> Button:
	return panel.get_node("RestartButton") as Button


func _record(panel: DungeonPanel) -> Array:
	var log: Array = []
	panel.advance_requested.connect(func() -> void:
		log.append("advance")
	)
	panel.retreat_requested.connect(func() -> void:
		log.append("retreat")
	)
	panel.restart_requested.connect(func() -> void:
		log.append("restart")
	)
	return log


func _count(log: Array, event_name: String) -> int:
	var total: int = 0
	for entry: Variant in log:
		if entry == event_name:
			total += 1
	return total


func _count_descendant_pawns(node: Node) -> int:
	var total: int = 0
	for child: Node in node.get_children():
		if child is Pawn:
			total += 1
		total += _count_descendant_pawns(child)
	return total


func test_unconfigured_dungeon_disables_every_entry_and_shows_no_numbers() -> void:
	var panel: DungeonPanel = _spawn_panel()
	var events: Array = _record(panel)

	assert_object(panel.get_dungeon()).is_null()
	assert_str(panel.get_depth_text()).is_equal(DungeonPanel.EMPTY_DEPTH_TEXT)
	assert_str(panel.get_reward_text()).is_equal(DungeonPanel.EMPTY_REWARD_TEXT)
	assert_bool(panel.is_awaiting_decision()).is_false()
	assert_bool(panel.is_can_restart()).is_false()
	assert_bool(_advance_button(panel).disabled).is_true()
	assert_bool(_retreat_button(panel).disabled).is_true()
	assert_bool(_restart_button(panel).disabled).is_true()

	# 程序化触发也不得转发。
	_advance_button(panel).pressed.emit()
	_retreat_button(panel).pressed.emit()
	_restart_button(panel).pressed.emit()
	assert_int(events.size()).is_zero()

	panel.set_dungeon(null)
	assert_str(panel.get_depth_text()).is_equal(DungeonPanel.EMPTY_DEPTH_TEXT)
	assert_str(panel.get_reward_text()).is_equal(DungeonPanel.EMPTY_REWARD_TEXT)


func test_set_depth_and_reward_only_change_text_and_dungeon_definition_is_read_only() -> void:
	var panel: DungeonPanel = _spawn_panel()
	var dungeon: DungeonDefinition = _load_dungeon()
	var max_reward_before: int = dungeon.get_max_reward()
	panel.set_dungeon(dungeon)

	panel.set_depth(2, dungeon.get_room_count())
	panel.set_reward(25)

	assert_str(panel.get_depth_text()).contains("2")
	assert_str(panel.get_depth_text()).contains(str(dungeon.get_room_count()))
	assert_str(panel.get_reward_text()).contains("25")
	assert_str((panel.get_node("TitleLabel") as Label).text).contains(dungeon.display_name)
	# 面板只呈现文本，不允许改到秘境定义本身。
	assert_int(dungeon.get_max_reward()).is_equal(max_reward_before)
	# 未进入等待决策时，推进 / 撤退 / 重启都保持禁用。
	assert_bool(_advance_button(panel).disabled).is_true()
	assert_bool(_retreat_button(panel).disabled).is_true()
	assert_bool(_restart_button(panel).disabled).is_true()


func test_decision_buttons_only_forward_while_awaiting_decision() -> void:
	var panel: DungeonPanel = _spawn_panel()
	panel.set_dungeon(_load_dungeon())
	var events: Array = _record(panel)

	panel.set_awaiting_decision(false)
	_advance_button(panel).pressed.emit()
	_retreat_button(panel).pressed.emit()
	assert_int(events.size()).is_zero()

	panel.set_awaiting_decision(true)
	assert_bool(_advance_button(panel).disabled).is_false()
	assert_bool(_retreat_button(panel).disabled).is_false()
	assert_bool(_restart_button(panel).disabled).is_true()

	_advance_button(panel).pressed.emit()
	_retreat_button(panel).pressed.emit()
	# 非法状态下的重开入口即使被程序化触发也不转发。
	_restart_button(panel).pressed.emit()

	assert_int(_count(events, "advance")).is_equal(1)
	assert_int(_count(events, "retreat")).is_equal(1)
	assert_int(_count(events, "restart")).is_zero()


func test_restart_only_forwards_after_run_is_finished() -> void:
	var panel: DungeonPanel = _spawn_panel()
	panel.set_dungeon(_load_dungeon())
	var events: Array = _record(panel)

	panel.set_can_restart(false)
	_restart_button(panel).pressed.emit()
	assert_int(_count(events, "restart")).is_zero()
	assert_bool(_restart_button(panel).disabled).is_true()

	panel.set_can_restart(true)
	assert_bool(_restart_button(panel).disabled).is_false()
	assert_bool(_advance_button(panel).disabled).is_true()
	assert_bool(_retreat_button(panel).disabled).is_true()
	_restart_button(panel).pressed.emit()

	assert_int(_count(events, "restart")).is_equal(1)


func test_awaiting_decision_and_restart_states_are_mutually_exclusive() -> void:
	var panel: DungeonPanel = _spawn_panel()
	panel.set_dungeon(_load_dungeon())

	panel.set_awaiting_decision(true)
	panel.set_can_restart(true)
	assert_bool(panel.is_can_restart()).is_true()
	assert_bool(panel.is_awaiting_decision()).is_false()
	assert_bool(_restart_button(panel).disabled).is_false()
	assert_bool(_advance_button(panel).disabled).is_true()

	panel.set_awaiting_decision(true)
	assert_bool(panel.is_awaiting_decision()).is_true()
	assert_bool(panel.is_can_restart()).is_false()
	assert_bool(_advance_button(panel).disabled).is_false()
	assert_bool(_retreat_button(panel).disabled).is_false()
	assert_bool(_restart_button(panel).disabled).is_true()


func test_panel_never_spawns_units_and_status_is_pure_text() -> void:
	var panel: DungeonPanel = _spawn_panel()
	panel.set_dungeon(_load_dungeon())
	panel.set_depth(3, 6)
	panel.set_reward(999)

	assert_int(_count_descendant_pawns(panel)).is_zero()

	panel.set_status("第 1 层已清空：试炼傀儡")
	assert_str(panel.get_status_text()).is_equal("第 1 层已清空：试炼傀儡")
	assert_str((panel.get_node("StatusLabel") as Label).text).is_equal("第 1 层已清空：试炼傀儡")
