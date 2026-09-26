extends GdUnitTestSuite

## 单元层：三种战术技能资源必须表达不同的目标与效果，而不是同一伤害技能换数值。

const SWORD_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BINDING_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"
const DASH_PATH: String = "res://game/pawns/data/skills/player_dash_skill.tres"
const AOE_PATH: String = "res://game/pawns/data/skills/player_sword_aoe_skill.tres"
const DRAIN_PATH: String = "res://game/pawns/data/skills/player_lifesteal_skill.tres"
const BREAKING_SLASH_PATH: String = "res://game/pawns/data/skills/player_breaking_slash.tres"
const REJUVENATION_PATH: String = "res://game/pawns/data/skills/player_rejuvenation_skill.tres"
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


func test_dash_skill_is_enemy_dash() -> void:
	var skill: ActiveSkillDefinition = _load_skill(DASH_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("dash_step")
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.DASH)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(0.9, APPROX)
	assert_float(skill.get_normalized_aoe_radius()).is_zero()


func test_sword_aoe_skill_is_enemy_area_damage() -> void:
	var skill: ActiveSkillDefinition = _load_skill(AOE_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("sword_aoe")
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(1.2, APPROX)
	assert_float(skill.get_normalized_aoe_radius()).is_equal_approx(90.0, APPROX)


func test_blood_drain_skill_is_enemy_lifesteal() -> void:
	var skill: ActiveSkillDefinition = _load_skill(DRAIN_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("blood_drain")
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.LIFESTEAL)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(1.3, APPROX)
	assert_float(skill.get_normalized_lifesteal_ratio()).is_equal_approx(0.5, APPROX)


## 条件爆发（INC-PAWNS-023）：破军斩单独使用严格劣于御剑斩，只有目标被控住才反超。
func test_breaking_slash_is_conditional_damage() -> void:
	var skill: ActiveSkillDefinition = _load_skill(BREAKING_SLASH_PATH)
	var sword: ActiveSkillDefinition = _load_skill(SWORD_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("breaking_slash")
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.DAMAGE)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(1.4, APPROX)
	assert_bool(skill.has_controlled_bonus()).is_true()
	assert_float(skill.get_normalized_controlled_bonus_multiplier()).is_equal_approx(2.4, APPROX)
	# 单独使用严格劣于御剑斩：基础倍率更低，灵力与冷却都更高。
	assert_bool(skill.get_normalized_effect_value() < sword.get_normalized_effect_value()).is_true()
	assert_bool(skill.get_normalized_spirit_cost() > sword.get_normalized_spirit_cost()).is_true()
	assert_bool(skill.get_normalized_cooldown() > sword.get_normalized_cooldown()).is_true()
	# 目标受控时的总倍率反而高于御剑斩，条件爆发才成立。
	var controlled_total: float = (
		skill.get_normalized_effect_value() * skill.get_normalized_controlled_bonus_multiplier()
	)
	assert_bool(controlled_total > sword.get_normalized_effect_value()).is_true()


## 主动回复（INC-PAWNS-023）：回春术是自疗，与血引术的「打人回血」分属两条轴。
func test_rejuvenation_is_self_heal() -> void:
	var skill: ActiveSkillDefinition = _load_skill(REJUVENATION_PATH)
	var drain: ActiveSkillDefinition = _load_skill(DRAIN_PATH)

	assert_object(skill).is_not_null()
	assert_str(String(skill.id)).is_equal("rejuvenation")
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.SELF)
	assert_int(skill.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.HEAL)
	assert_float(skill.get_normalized_effect_value()).is_equal_approx(55.0, APPROX)
	assert_bool(skill.is_self_targeted()).is_true()
	assert_float(skill.get_effective_cast_range(76.0)).is_zero()
	# 单次回复量（55）高于血引术在炼气期玩家（attack 28）上的单次吸血（约 17 点）。
	assert_bool(skill.get_normalized_effect_value() > 30.0).is_true()
	# 更强的一次性回复用更高灵力与更长冷却换取。
	assert_bool(skill.get_normalized_spirit_cost() > drain.get_normalized_spirit_cost()).is_true()
	assert_bool(skill.get_normalized_cooldown() > drain.get_normalized_cooldown()).is_true()


## 八类价值轴：输出 / 条件爆发 / 防御 / 控制 / 位移 / 范围 / 吸血 / 主动回复。
## 轴键包含「条件加成」维度，因此破军斩不会被误判成御剑斩的又一次换数值。
func test_eight_tactical_skills_cover_distinct_value_axes() -> void:
	var skills: Array[ActiveSkillDefinition] = [
		_load_skill(SWORD_PATH),
		_load_skill(BREAKING_SLASH_PATH),
		_load_skill(GUARD_PATH),
		_load_skill(BINDING_PATH),
		_load_skill(DASH_PATH),
		_load_skill(AOE_PATH),
		_load_skill(DRAIN_PATH),
		_load_skill(REJUVENATION_PATH),
	]
	var ids: Array[String] = []
	var axes: Array[String] = []
	var effects: Array[int] = []
	for skill: ActiveSkillDefinition in skills:
		assert_object(skill).is_not_null()
		assert_bool(skill.is_configured()).is_true()
		ids.append(String(skill.id))
		axes.append(_value_axis(skill))
		effects.append(skill.effect_type)

	assert_int(ids.size()).is_equal(8)
	assert_int(_unique_count(ids)).is_equal(8)
	assert_int(_unique_count(axes)).is_equal(8)
	for expected: int in [
		ActiveSkillDefinition.SkillEffectType.DAMAGE,
		ActiveSkillDefinition.SkillEffectType.SHIELD,
		ActiveSkillDefinition.SkillEffectType.STUN,
		ActiveSkillDefinition.SkillEffectType.DASH,
		ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE,
		ActiveSkillDefinition.SkillEffectType.LIFESTEAL,
		ActiveSkillDefinition.SkillEffectType.HEAL,
	]:
		assert_bool(effects.has(expected)).is_true()
	# 两个 DAMAGE 技能之所以不算重复，是因为条件加成把它们分到不同的价值轴上。
	assert_int(effects.count(ActiveSkillDefinition.SkillEffectType.DAMAGE)).is_equal(2)


## 新技能进入技能池不等于进入初始装配：解锁路径仍由「遇到问题 → 获得技能」承担。
func test_new_skills_stay_out_of_the_initial_loadout() -> void:
	var data: PawnData = load(PLAYER_PATH) as PawnData
	var ids: Array[String] = []
	for skill: ActiveSkillDefinition in data.get_active_skills():
		ids.append(String(skill.id))
	for new_id: String in [
		"dash_step",
		"sword_aoe",
		"blood_drain",
		"breaking_slash",
		"rejuvenation",
	]:
		assert_bool(ids.has(new_id)).is_false()
	assert_int(data.realm.active_skill_slots).is_equal(2)


## 价值轴 = 效果类型 + 是否携带条件加成；同轴换数值会被这层拦下。
func _value_axis(skill: ActiveSkillDefinition) -> String:
	if skill.has_controlled_bonus():
		return "%d|conditional" % skill.effect_type
	return "%d|base" % skill.effect_type


func _unique_count(values: Array) -> int:
	var seen: Dictionary = {}
	for value: Variant in values:
		seen[value] = true
	return seen.size()
