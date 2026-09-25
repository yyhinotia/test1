extends GdUnitTestSuite

## 单元层：三种战术技能资源必须表达不同的目标与效果，而不是同一伤害技能换数值。

const SWORD_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BINDING_PATH: String = "res://game/pawns/data/player_binding_skill.tres"
const PLAYER_PATH: String = "res://game/pawns/data/player_pawn.tres"
const APPROX: float = 0.001


func _load_skill(path: String) -> ActiveSkillDefinition:
	return load(path) as ActiveSkillDefinition


func test_sword_strike_is_enemy_damage() -> void:
	var skill: ActiveSkillDefinition = _load_skill(SWORD_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("sword_strike")
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.DAMAGE)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(1.8, APPROX)
	assert_float(skill.get_normalized_effect_duration()).is_zero()


func test_guard_true_qi_is_self_shield() -> void:
	var skill: ActiveSkillDefinition = _load_skill(GUARD_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("guard_true_qi")
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.SELF)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.SHIELD)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(30.0, APPROX)
	assert_bool(skill.is_self_targeted()).is_true()


func test_binding_spell_is_enemy_stun() -> void:
	var skill: ActiveSkillDefinition = _load_skill(BINDING_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("binding_spell")
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.STUN)
	assert_float(skill.get_normalized_effect_value()).is_zero()
	assert_float(skill.get_normalized_effect_duration()).is_equal_approx(2.0, APPROX)


func test_three_tactical_skills_do_not_share_effect_type() -> void:
	var skills: Array[ActiveSkillDefinition] = [
		_load_skill(SWORD_PATH),
		_load_skill(GUARD_PATH),
		_load_skill(BINDING_PATH),
	]
	var effects: Array[int] = []
	for skill: ActiveSkillDefinition in skills:
		effects.append(skill.effect_type)

	assert_int(effects.size()).is_equal(3)
	assert_bool(effects.has(ActiveSkillDefinition.SkillEffectType.DAMAGE)).is_true()
	assert_bool(effects.has(ActiveSkillDefinition.SkillEffectType.SHIELD)).is_true()
	assert_bool(effects.has(ActiveSkillDefinition.SkillEffectType.STUN)).is_true()


func test_player_preset_uses_two_slot_tactical_build() -> void:
	var data: PawnData = load(PLAYER_PATH) as PawnData
	var skills: Array[ActiveSkillDefinition] = data.get_active_skills()

	assert_int(skills.size()).is_equal(2)
	assert_str(String(skills[0].id)).is_equal("sword_strike")
	assert_str(String(skills[1].id)).is_equal("guard_true_qi")
	assert_int(data.realm.active_skill_slots).is_equal(2)
	for skill: ActiveSkillDefinition in skills:
		assert_bool(skill.is_configured()).is_true()
