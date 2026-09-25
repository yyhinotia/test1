extends GdUnitTestSuite

## 单元层：主动技能静态资源的字段默认值、距离回退和数值归一化。
## 本层不实例化 Pawn，也不触碰资源池或场景树。

const APPROX: float = 0.001


func _make_skill(
		id: StringName,
		cost: float,
		cooldown: float,
		cast_range: float,
		damage_multiplier: float
	) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	skill.damage_multiplier = damage_multiplier
	return skill


func test_default_definition_is_safe_and_configured() -> void:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()

	assert_str(String(skill.id)).is_equal("skill")
	assert_str(skill.display_name).is_equal("技能")
	assert_float(skill.spirit_cost).is_equal_approx(0.0, APPROX)
	assert_float(skill.cooldown).is_equal_approx(1.0, APPROX)
	assert_float(skill.cast_range).is_equal_approx(0.0, APPROX)
	assert_float(skill.damage_multiplier).is_equal_approx(1.0, APPROX)
	assert_bool(skill.is_configured()).is_true()


func test_effective_cast_range_uses_fallback_only_when_not_overridden() -> void:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()

	assert_float(skill.get_effective_cast_range(42.0)).is_equal_approx(42.0, APPROX)

	skill.cast_range = 88.0
	assert_float(skill.get_effective_cast_range(42.0)).is_equal_approx(88.0, APPROX)

	skill.cast_range = -10.0
	assert_float(skill.get_effective_cast_range(42.0)).is_equal_approx(42.0, APPROX)
	assert_float(skill.get_effective_cast_range(-1.0)).is_zero()


func test_runtime_values_are_normalized_before_use() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"normalize", -12.0, -3.0, 0.0, -0.5)

	assert_float(skill.get_normalized_spirit_cost()).is_zero()
	assert_float(skill.get_normalized_cooldown()).is_zero()
	assert_float(skill.get_normalized_damage_multiplier()).is_zero()


func test_empty_or_whitespace_id_is_not_configured() -> void:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()

	skill.id = &""
	assert_bool(skill.is_configured()).is_false()

	skill.id = &"   "
	assert_bool(skill.is_configured()).is_false()

	skill.id = &"sword_strike"
	assert_bool(skill.is_configured()).is_true()


func test_player_pawn_data_references_configured_skill() -> void:
	var data: PawnData = load("res://game/pawns/data/player_pawn.tres") as PawnData

	assert_object(data).is_not_null()
	assert_object(data.active_skill).is_not_null()
	assert_str(String(data.active_skill.id)).is_equal("sword_strike")
	assert_str(data.active_skill.display_name).is_equal("御剑斩")
	assert_float(data.active_skill.spirit_cost).is_equal_approx(25.0, APPROX)
	assert_float(data.active_skill.cooldown).is_equal_approx(2.5, APPROX)
	assert_float(data.active_skill.cast_range).is_equal_approx(110.0, APPROX)
	assert_float(data.active_skill.damage_multiplier).is_equal_approx(1.8, APPROX)
