extends GdUnitTestSuite

## 集成层：SkillSlot / SkillBar 的 TARGETING 交互状态与 Pawn 目标高亮（`INC-UI-012`）。
## UI 只发 `cast_requested` / `targeting_started` / `targeting_cancelled` 请求；
## 进入或取消瞄准都不得修改 Pawn 的灵力、冷却、位置或控制器命令。

const BAR_SCENE_PATH: String = "res://game/ui/skill_bar.tscn"
const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const APPROX: float = 0.001


func _spawn_bar() -> SkillBar:
	var scene: PackedScene = load(BAR_SCENE_PATH)
	var bar: SkillBar = scene.instantiate() as SkillBar
	auto_free(bar)
	add_child(bar)
	return bar


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _make_skill(id: StringName, target_type: ActiveSkillDefinition.SkillTargetType) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.target_type = target_type
	skill.effect_type = ActiveSkillDefinition.SkillEffectType.DAMAGE
	skill.spirit_cost = 10.0
	skill.cooldown = 1.0
	skill.cast_range = 120.0
	skill.damage_multiplier = 1.0
	return skill


func _make_data(skills: Array[ActiveSkillDefinition]) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	# 让本用例聚焦 TARGETING 交互；容量一致性由专用容量测试覆盖。
	if data.realm != null:
		var realm: RealmDefinition = data.realm.duplicate(true) as RealmDefinition
		realm.active_skill_slots = maxi(skills.size(), 2)
		data.realm = realm
	var first: ActiveSkillDefinition = skills[0] if not skills.is_empty() else null
	data.active_skill = first
	data.active_skills = skills
	data.initial_spirit_ratio = 1.0
	return data


func _click(slot: SkillSlot) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	slot._gui_input(event)


## 点击需要目标的技能进入 TARGETING，SELF 技能跳过瞄准直接请求施法。
func test_targeted_skill_enters_targeting_and_self_skill_skips_it() -> void:
	var strike: ActiveSkillDefinition = _make_skill(&"enemy_strike", ActiveSkillDefinition.SkillTargetType.ENEMY)
	var guard: ActiveSkillDefinition = _make_skill(&"self_guard", ActiveSkillDefinition.SkillTargetType.SELF)
	var bind: ActiveSkillDefinition = _make_skill(&"enemy_bind", ActiveSkillDefinition.SkillTargetType.ENEMY)
	var skills: Array[ActiveSkillDefinition] = [strike, guard, bind]
	var player: Pawn = _spawn_pawn(PLAYER_SCENE_PATH, _make_data(skills))
	var bar: SkillBar = _spawn_bar()
	await await_idle_frame()
	bar.bind_pawn(player)
	await await_idle_frame()

	var requests: Array[StringName] = []
	var started: Array[StringName] = []
	var cancelled: Array[String] = []
	bar.skill_requested.connect(func(skill: ActiveSkillDefinition) -> void: requests.append(skill.id))
	bar.targeting_started.connect(func(skill: ActiveSkillDefinition) -> void: started.append(skill.id))
	bar.targeting_cancelled.connect(func() -> void: cancelled.append("cancel"))

	assert_int(bar.get_slot_count()).is_equal(3)
	var strike_slot: SkillSlot = bar.get_slots()[0]
	var guard_slot: SkillSlot = bar.get_slots()[1]
	var bind_slot: SkillSlot = bar.get_slots()[2]

	# ENEMY 技能：进入 TARGETING，且没有直接施法请求。
	_click(strike_slot)
	assert_bool(bar.is_targeting()).is_true()
	assert_str(strike_slot.get_interaction_state_name()).is_equal("TARGETING")
	assert_bool((strike_slot.get_node("TargetingHighlight") as Panel).visible).is_true()
	assert_str(guard_slot.get_interaction_state_name()).is_equal("NORMAL")
	assert_array(started).contains_exactly([&"enemy_strike"])
	assert_array(requests).is_empty()

	# SELF 技能：不进入 TARGETING，直接发施法请求，并解除上一个瞄准。
	_click(guard_slot)
	assert_bool(bar.is_targeting()).is_false()
	assert_str(strike_slot.get_interaction_state_name()).is_equal("NORMAL")
	assert_str(guard_slot.get_interaction_state_name()).is_equal("NORMAL")
	assert_bool((strike_slot.get_node("TargetingHighlight") as Panel).visible).is_false()
	assert_array(requests).contains_exactly([&"self_guard"])
	assert_array(cancelled).contains_exactly(["cancel"])

	# 重新选择另一个需要目标的技能：旧格子回到 NORMAL，新格子进入 TARGETING。
	_click(bind_slot)
	assert_str(bind_slot.get_interaction_state_name()).is_equal("TARGETING")
	assert_str(guard_slot.get_interaction_state_name()).is_equal("NORMAL")
	assert_array(started).contains_exactly([&"enemy_strike", &"enemy_bind"])
	assert_array(requests).contains_exactly([&"self_guard"])


## 取消瞄准后所有技能格回到 NORMAL，且不会重复发取消信号。
func test_cancel_targeting_returns_all_slots_to_normal() -> void:
	var strike: ActiveSkillDefinition = _make_skill(&"enemy_strike", ActiveSkillDefinition.SkillTargetType.ENEMY)
	var skills: Array[ActiveSkillDefinition] = [strike]
	var player: Pawn = _spawn_pawn(PLAYER_SCENE_PATH, _make_data(skills))
	var bar: SkillBar = _spawn_bar()
	await await_idle_frame()
	bar.bind_pawn(player)
	await await_idle_frame()

	var cancelled: Array[String] = []
	bar.targeting_cancelled.connect(func() -> void: cancelled.append("cancel"))

	assert_bool(bar.begin_targeting(strike)).is_true()
	var slot: SkillSlot = bar.get_slots()[0]
	assert_str(slot.get_interaction_state_name()).is_equal("TARGETING")

	assert_bool(bar.cancel_targeting()).is_true()
	assert_bool(bar.is_targeting()).is_false()
	assert_str(slot.get_interaction_state_name()).is_equal("NORMAL")
	assert_bool((slot.get_node("TargetingHighlight") as Panel).visible).is_false()
	assert_array(cancelled).contains_exactly(["cancel"])

	assert_bool(bar.cancel_targeting()).is_false()
	assert_array(cancelled).contains_exactly(["cancel"])

	# 不在 Build 中的技能不能进入瞄准。
	var foreign: ActiveSkillDefinition = _make_skill(&"foreign", ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_bool(bar.begin_targeting(foreign)).is_false()
	assert_bool(bar.is_targeting()).is_false()


## 目标高亮只对存活且合法的目标显示；非法目标不给出可确认状态。
func test_target_highlight_requires_legal_living_target() -> void:
	var player: Pawn = _spawn_pawn(PLAYER_SCENE_PATH)
	var enemy: Pawn = _spawn_pawn(ENEMY_SCENE_PATH)
	await await_idle_frame()

	var indicator: Line2D = player.get_node_or_null("TargetIndicator") as Line2D
	assert_object(indicator).is_not_null()
	assert_bool(indicator.visible).is_false()

	player.set_target_highlight(true)
	assert_bool(player.is_target_highlight_visible()).is_true()
	assert_bool(indicator.visible).is_true()

	# 非法目标：不显示可确认高亮。
	player.set_target_highlight(true, false)
	assert_bool(player.is_target_highlight_visible()).is_false()
	assert_bool(indicator.visible).is_false()

	player.set_target_highlight(true)
	assert_bool(indicator.visible).is_true()
	player.set_target_highlight(false)
	assert_bool(indicator.visible).is_false()

	# 已死亡单位不能成为目标。
	enemy.take_damage(enemy.data.defense + enemy.data.max_shield + enemy.data.max_health + 10.0)
	assert_bool(enemy.is_dead()).is_true()
	enemy.set_target_highlight(true)
	assert_bool(enemy.is_target_highlight_visible()).is_false()
	assert_bool((enemy.get_node("TargetIndicator") as Line2D).visible).is_false()


## UI 只发请求：瞄准与取消结束后，Pawn 数值与控制器命令必须完全未受影响。
func test_targeting_requests_do_not_mutate_pawn_state() -> void:
	var strike: ActiveSkillDefinition = _make_skill(&"enemy_strike", ActiveSkillDefinition.SkillTargetType.ENEMY)
	var skills: Array[ActiveSkillDefinition] = [strike]
	var player: Pawn = _spawn_pawn(PLAYER_SCENE_PATH, _make_data(skills))
	var enemy: Pawn = _spawn_pawn(ENEMY_SCENE_PATH)
	var bar: SkillBar = _spawn_bar()
	await await_idle_frame()
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)
	bar.bind_pawn(player)
	await await_idle_frame()

	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)
	var spirit_before: float = player.current_spirit
	var cooldown_before: float = player.get_skill_cooldown_remaining(strike.id)
	var order_before: String = controller.get_order_description()
	var enemy_total_before: float = enemy.current_shield + enemy.current_health

	_click(bar.get_slots()[0])
	enemy.set_target_highlight(true)
	enemy.set_target_highlight(false)
	assert_bool(bar.cancel_targeting()).is_true()

	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(strike.id)).is_equal_approx(cooldown_before, APPROX)
	assert_float(player.global_position.x).is_equal_approx(0.0, APPROX)
	assert_str(controller.get_order_description()).is_equal(order_before)
	assert_float(enemy.current_shield + enemy.current_health).is_equal_approx(enemy_total_before, APPROX)
