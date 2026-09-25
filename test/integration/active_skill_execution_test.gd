extends GdUnitTestSuite

## 集成层：主动技能定义 → Pawn 施法条件 → 灵力池 → 伤害路由 → 冷却/AI。
## 使用真实 Pawn 场景和真实 ResourcePoolComponent，不直接改写 HP/灵力内部数值验证结果。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const APPROX: float = 0.001


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _make_skill(
		id: StringName,
		spirit_cost: float,
		cooldown: float,
		cast_range: float,
		damage_multiplier: float
	) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.spirit_cost = spirit_cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	skill.damage_multiplier = damage_multiplier
	return skill


func _make_player_data(skill: ActiveSkillDefinition, max_spirit: float = -1.0) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = skill
	if max_spirit >= 0.0:
		data.max_spirit = max_spirit
	return data


func _make_enemy_data(skill: ActiveSkillDefinition, max_spirit: float = 60.0) -> PawnData:
	var data: PawnData = (load(ENEMY_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = skill
	data.max_spirit = max_spirit
	data.initial_spirit_ratio = 1.0
	return data


func _total_effective_health(pawn: Pawn) -> float:
	return pawn.current_shield + pawn.current_health


func test_successful_cast_spends_spirit_damages_and_starts_cooldown() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"test_strike", 25.0, 2.5, 100.0, 1.8)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)

	var cast_events: Array[String] = []
	var cooldown_events: Array[float] = []
	player.skill_cast.connect(func(_pawn: Pawn, _skill: ActiveSkillDefinition, _target: Pawn) -> void:
		cast_events.append("cast")
	)
	player.skill_cooldown_changed.connect(func(_pawn: Pawn, _skill_id: StringName, remaining: float) -> void:
		cooldown_events.append(remaining)
	)

	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)
	var expected_damage: float = maxf(1.0, player.data.attack * skill.damage_multiplier - enemy.data.defense)

	assert_bool(player.can_cast_skill(skill, enemy)).is_true()
	assert_bool(player.cast_skill(skill, enemy)).is_true()

	assert_float(player.current_spirit).is_equal_approx(spirit_before - skill.spirit_cost, APPROX)
	assert_float(enemy_total_before - _total_effective_health(enemy)).is_equal_approx(expected_damage, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(skill.cooldown, APPROX)
	assert_bool(player.is_skill_ready(skill)).is_false()
	assert_array(cast_events).contains_exactly(["cast"])
	assert_array(cooldown_events).contains_exactly([skill.cooldown])

	var spirit_after: float = player.current_spirit
	var enemy_total_after: float = _total_effective_health(enemy)
	assert_bool(player.cast_skill(skill, enemy)).is_false()
	assert_float(player.current_spirit).is_equal_approx(spirit_after, APPROX)
	assert_float(_total_effective_health(enemy)).is_equal_approx(enemy_total_after, APPROX)


func test_insufficient_spirit_is_complete_no_op() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"expensive", 30.0, 1.0, 100.0, 2.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill, 10.0))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(60.0, 0.0)

	var cast_events: Array[String] = []
	player.skill_cast.connect(func(_pawn: Pawn, _skill: ActiveSkillDefinition, _target: Pawn) -> void:
		cast_events.append("cast")
	)
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)

	assert_bool(player.can_cast_skill(skill, enemy)).is_false()
	assert_bool(player.cast_skill(skill, enemy)).is_false()

	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(_total_effective_health(enemy)).is_equal_approx(enemy_total_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_array(cast_events).is_empty()


func test_invalid_target_and_out_of_range_are_complete_no_ops() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"ranged_strike", 20.0, 1.0, 60.0, 1.5)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(100.0, 0.0)

	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)
	assert_bool(player.can_cast_skill(skill, enemy)).is_false()
	assert_bool(player.cast_skill(skill, enemy)).is_false()

	enemy.global_position = Vector2(50.0, 0.0)
	assert_bool(player.can_cast_skill(skill, player)).is_false()
	assert_bool(player.cast_skill(skill, player)).is_false()
	assert_bool(player.cast_skill(skill, null)).is_false()

	var friendly: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	friendly.global_position = Vector2(40.0, 0.0)
	assert_bool(player.can_cast_skill(skill, friendly)).is_false()
	assert_bool(player.cast_skill(skill, friendly)).is_false()

	enemy.take_damage(enemy.data.defense + enemy.data.max_shield + enemy.data.max_health + 50.0)
	assert_bool(enemy.is_dead()).is_true()
	assert_bool(player.can_cast_skill(skill, enemy)).is_false()
	assert_bool(player.cast_skill(skill, enemy)).is_false()

	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_float(_total_effective_health(enemy)).is_zero()
	assert_bool(enemy_total_before > 0.0).is_true()


func test_cooldown_advances_on_physics_and_unlocks_recast() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"quick_strike", 5.0, 2.0, 100.0, 0.1)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)

	var cast_events: Array[String] = []
	var cooldown_events: Array[float] = []
	player.skill_cast.connect(func(_pawn: Pawn, _skill: ActiveSkillDefinition, _target: Pawn) -> void:
		cast_events.append("cast")
	)
	player.skill_cooldown_changed.connect(func(_pawn: Pawn, _skill_id: StringName, remaining: float) -> void:
		cooldown_events.append(remaining)
	)

	assert_bool(player.cast_skill(skill, enemy)).is_true()
	player._physics_process(1.0)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(1.0, APPROX)
	assert_bool(player.is_skill_ready(skill)).is_false()

	player._physics_process(1.1)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_bool(player.is_skill_ready(skill)).is_true()
	assert_bool(player.cast_skill(skill, enemy)).is_true()
	assert_array(cast_events).contains_exactly(["cast", "cast"])
	assert_array(cooldown_events).contains_exactly([skill.cooldown, 0.0, skill.cooldown])


func test_ai_uses_configured_skill_after_activation_delay() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"ai_burst", 30.0, 4.0, 120.0, 2.0)
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH, _make_enemy_data(skill))
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	enemy.global_position = Vector2(100.0, 0.0)
	player.global_position = Vector2.ZERO

	var ai: AIController = enemy.get_controller() as AIController
	ai.bind(enemy)
	ai.set_target(player)
	var spirit_before: float = enemy.current_spirit
	var player_total_before: float = _total_effective_health(player)
	var expected_damage: float = maxf(1.0, enemy.data.attack * skill.damage_multiplier - player.data.defense)

	ai.update_controller(1.0)
	assert_float(enemy.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(_total_effective_health(player)).is_equal_approx(player_total_before, APPROX)

	ai.update_controller(2.1)
	assert_float(enemy.current_spirit).is_equal_approx(spirit_before - skill.spirit_cost, APPROX)
	assert_float(player_total_before - _total_effective_health(player)).is_equal_approx(expected_damage, APPROX)
	assert_float(enemy.get_skill_cooldown_remaining(skill.id)).is_equal_approx(skill.cooldown, APPROX)