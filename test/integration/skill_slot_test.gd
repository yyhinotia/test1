extends GdUnitTestSuite

## 集成层：SkillSlot 的固定结构、状态渲染与点击信号边界。
## 使用真实 Pawn 场景读取冷却/灵力；格子本身不执行技能，因此点击后业务数值必须保持不变。

const SLOT_SCENE_PATH: String = "res://game/ui/skill_slot.tscn"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const APPROX: float = 0.001


func _spawn_slot() -> SkillSlot:
	var scene: PackedScene = load(SLOT_SCENE_PATH)
	var slot: SkillSlot = scene.instantiate() as SkillSlot
	auto_free(slot)
	add_child(slot)
	return slot


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _make_skill(id: StringName, cost: float, cooldown: float, cast_range: float) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = "御剑斩"
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	skill.damage_multiplier = 1.5
	return skill


func _make_player_data(skill: ActiveSkillDefinition, max_spirit: float = 100.0) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = skill
	var skills: Array[ActiveSkillDefinition] = []
	skills.append(skill)
	data.active_skills = skills
	data.max_spirit = max_spirit
	data.initial_spirit_ratio = 1.0
	return data


func test_scene_exposes_required_structure_and_fixed_size() -> void:
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()

	assert_float(slot.custom_minimum_size.x).is_equal_approx(64.0, APPROX)
	assert_float(slot.custom_minimum_size.y).is_equal_approx(64.0, APPROX)
	assert_object(slot.get_node_or_null("Background")).is_not_null()
	assert_object(slot.get_node_or_null("Icon")).is_not_null()
	assert_object(slot.get_node_or_null("CooldownOverlay")).is_not_null()
	assert_object(slot.get_node_or_null("CooldownLabel")).is_not_null()
	assert_object(slot.get_node_or_null("CostLabel")).is_not_null()
	assert_object(slot.get_node_or_null("HotkeyLabel")).is_not_null()
	assert_object(slot.get_node_or_null("StateHighlight")).is_not_null()


func test_empty_slot_has_stable_placeholder() -> void:
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()

	slot.unbind()
	var snapshot: Dictionary = slot.get_snapshot()
	assert_str(String(snapshot["state_name"])).is_equal("EMPTY")
	assert_str((slot.get_node("Icon") as Label).text).is_equal("—")
	assert_bool((slot.get_node("CooldownOverlay") as ColorRect).visible).is_false()
	assert_bool((slot.get_node("CostLabel") as Label).visible).is_false()
	assert_bool(slot.has_skill()).is_false()


func test_ready_slot_renders_icon_hotkey_and_cost() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"sword_strike", 25.0, 2.5, 110.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()

	slot.bind_skill(player, skill, "1")
	assert_str(String(slot.get_snapshot()["state_name"])).is_equal("READY")
	assert_str((slot.get_node("Icon") as Label).text).is_equal("御")
	assert_str((slot.get_node("HotkeyLabel") as Label).text).is_equal("1")
	assert_str((slot.get_node("CostLabel") as Label).text).is_equal("25")
	assert_bool((slot.get_node("CooldownOverlay") as ColorRect).visible).is_false()


func test_cooldown_slot_uses_top_down_ratio_overlay() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"sword_strike", 25.0, 2.5, 110.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)
	# 冻结冷却推进，保证断言的冷却比例是施放瞬间的 1.0，而不是等待帧数后的漂移值。
	player.set_physics_process(false)
	assert_bool(player.cast_skill(skill, enemy)).is_true()
	slot.bind_skill(player, skill, "2")

	var snapshot: Dictionary = slot.get_snapshot()
	var overlay: ColorRect = slot.get_node("CooldownOverlay")
	assert_str(String(snapshot["state_name"])).is_equal("COOLDOWN")
	assert_float(float(snapshot["cooldown_ratio"])).is_equal_approx(1.0, APPROX)
	assert_bool(overlay.visible).is_true()
	assert_float(overlay.offset_bottom).is_equal_approx(64.0, APPROX)
	assert_str((slot.get_node("CooldownLabel") as Label).text).is_equal("2.5")


func test_no_resource_slot_dims_and_emphasizes_cost() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"expensive", 25.0, 2.0, 110.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill, 5.0))
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()

	slot.bind_skill(player, skill, "3")
	var snapshot: Dictionary = slot.get_snapshot()
	var cost_label: Label = slot.get_node("CostLabel")
	assert_str(String(snapshot["state_name"])).is_equal("NO_RESOURCE")
	assert_bool(slot.modulate.r < 1.0).is_true()
	assert_bool(cost_label.get_theme_color("font_color").r > 0.9).is_true()


func test_selected_uses_state_highlight_without_changing_model() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"sword_strike", 25.0, 2.5, 110.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()

	slot.bind_skill(player, skill, "1")
	slot.set_selected(true)
	assert_bool(slot.is_selected()).is_true()
	assert_bool((slot.get_node("StateHighlight") as Panel).visible).is_true()
	assert_str(String(slot.get_snapshot()["state_name"])).is_equal("READY")
	slot.set_selected(false)
	assert_bool((slot.get_node("StateHighlight") as Panel).visible).is_false()


func test_click_only_emits_request_and_does_not_mutate_pawn() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"sword_strike", 25.0, 2.5, 110.0)
	var data: PawnData = _make_player_data(skill)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, data)
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	var slot: SkillSlot = _spawn_slot()
	await await_idle_frame()
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(400.0, 0.0)
	slot.bind_skill(player, skill, "1")

	var requested: Array[ActiveSkillDefinition] = []
	slot.cast_requested.connect(func(cast_skill: ActiveSkillDefinition) -> void: requested.append(cast_skill))
	var spirit_before: float = player.current_spirit
	var enemy_health_before: float = enemy.current_health
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	slot._gui_input(event)

	assert_int(requested.size()).is_equal(1)
	assert_object(requested[0]).is_same(skill)
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_float(enemy.current_health).is_equal_approx(enemy_health_before, APPROX)
