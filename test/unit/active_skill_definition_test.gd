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
	assert_str(skill.description).is_equal("")
	assert_float(skill.spirit_cost).is_equal_approx(0.0, APPROX)
	assert_float(skill.cooldown).is_equal_approx(1.0, APPROX)
	assert_float(skill.cast_range).is_equal_approx(0.0, APPROX)
	assert_float(skill.damage_multiplier).is_equal_approx(1.0, APPROX)
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.DAMAGE)
	assert_float(skill.effect_value).is_equal_approx(0.0, APPROX)
	assert_float(skill.effect_duration).is_equal_approx(0.0, APPROX)
	assert_float(skill.controlled_bonus_multiplier).is_equal_approx(1.0, APPROX)
	assert_bool(skill.has_controlled_bonus()).is_false()
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
	assert_float(skill.get_normalized_effect_value()).is_zero()
	assert_float(skill.get_normalized_effect_duration()).is_zero()
	assert_float(skill.get_normalized_aoe_radius()).is_zero()
	# 吸血比例是 0~1 的夹取，超出范围必须被收敛而不是原样透传。
	skill.lifesteal_ratio = -1.0
	assert_float(skill.get_normalized_lifesteal_ratio()).is_zero()
	skill.lifesteal_ratio = 2.0
	assert_float(skill.get_normalized_lifesteal_ratio()).is_equal_approx(1.0, APPROX)
	# 条件伤害倍率（INC-COMBAT-012）：小于 1 的值被抬回 1.0，保证「条件」只增不减。
	skill.controlled_bonus_multiplier = -2.0
	assert_float(skill.get_normalized_controlled_bonus_multiplier()).is_equal_approx(1.0, APPROX)
	assert_bool(skill.has_controlled_bonus()).is_false()
	skill.controlled_bonus_multiplier = 0.5
	assert_float(skill.get_normalized_controlled_bonus_multiplier()).is_equal_approx(1.0, APPROX)
	skill.controlled_bonus_multiplier = 2.0
	assert_float(skill.get_normalized_controlled_bonus_multiplier()).is_equal_approx(2.0, APPROX)
	assert_bool(skill.has_controlled_bonus()).is_true()


func test_empty_or_whitespace_id_is_not_configured() -> void:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()

	skill.id = &""
	assert_bool(skill.is_configured()).is_false()

	skill.id = &"   "
	assert_bool(skill.is_configured()).is_false()

	skill.id = &"sword_strike"
	assert_bool(skill.is_configured()).is_true()


func test_effect_value_falls_back_to_legacy_damage_multiplier() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"legacy", 10.0, 1.0, 50.0, 1.7)

	assert_float(skill.get_normalized_effect_value()).is_equal_approx(1.7, APPROX)
	skill.effect_value = 2.2
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(2.2, APPROX)
	skill.effect_type = ActiveSkillDefinition.SkillEffectType.SHIELD
	skill.effect_value = -1.0
	assert_float(skill.get_normalized_effect_value()).is_zero()


func test_self_target_skill_ignores_cast_range() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"self_guard", 10.0, 1.0, 200.0, 0.0)
	skill.target_type = ActiveSkillDefinition.SkillTargetType.SELF

	assert_bool(skill.is_self_targeted()).is_true()
	assert_float(skill.get_effective_cast_range(42.0)).is_zero()


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
	assert_int(data.active_skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_int(data.active_skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.DAMAGE)
	assert_float(data.active_skill.get_normalized_effect_value()).is_equal_approx(1.8, APPROX)
	assert_int(data.get_active_skills().size()).is_equal(2)
	assert_str(String(data.get_active_skills()[1].id)).is_equal("guard_true_qi")


## 新增效果只能追加在既有四项之后：按序号比较 effect_type 的旧数据不能静默错配。
func test_new_effect_types_are_appended_after_stun() -> void:
	assert_int(ActiveSkillDefinition.SkillEffectType.DAMAGE).is_zero()
	assert_int(ActiveSkillDefinition.SkillEffectType.HEAL).is_equal(1)
	assert_int(ActiveSkillDefinition.SkillEffectType.SHIELD).is_equal(2)
	assert_int(ActiveSkillDefinition.SkillEffectType.STUN).is_equal(3)
	assert_int(ActiveSkillDefinition.SkillEffectType.DASH).is_equal(4)
	assert_int(ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE).is_equal(5)
	assert_int(ActiveSkillDefinition.SkillEffectType.LIFESTEAL).is_equal(6)


## 追加效果（INC-COMBAT-013）：默认没有追加效果；只有 id 配好的资源才算数，半配置不得产生空结算。
func test_followup_skill_is_optional_and_ignores_unconfigured_resource() -> void:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	assert_bool(skill.has_followup_skill()).is_false()
	assert_object(skill.get_followup_skill()).is_null()

	var payload: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.followup_skill = payload
	assert_bool(skill.has_followup_skill()).is_true()
	assert_object(skill.get_followup_skill()).is_same(payload)

	# 半配置：资源在、id 为空 / 全空格，按「没有追加效果」处理。
	payload.id = &""
	assert_bool(skill.has_followup_skill()).is_false()
	assert_object(skill.get_followup_skill()).is_null()
	payload.id = &"   "
	assert_bool(skill.has_followup_skill()).is_false()

	payload.id = &"charge_hardstop"
	assert_bool(skill.has_followup_skill()).is_true()
	assert_object(skill.get_followup_skill()).is_same(payload)
