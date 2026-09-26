extends GdUnitTestSuite

## 单元层：敌人威胁档案的数据契约（INC-PAWNS-016）。
## 只验证数据本身可推导的性质（有效生命 / 每秒伤害 / 单次伤害）与字段完整性，
## 不加载场景、不驱动战斗，也不复制任何战斗结算规则。

const BASELINE_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const IRON_GUARD_PATH: String = "res://game/pawns/data/enemies/enemy_iron_guard.tres"
const BLOOD_BLADE_PATH: String = "res://game/pawns/data/enemies/enemy_blood_blade.tres"
const MELEE_RAIDER_PATH: String = "res://game/pawns/data/enemies/enemy_melee_raider.tres"
const ARCHER_PATH: String = "res://game/pawns/data/enemies/enemy_spirit_archer.tres"
const BOSS_PATH: String = "res://game/pawns/data/enemies/enemy_build_test_boss.tres"
const CHARGE_ADEPT_PATH: String = "res://game/pawns/data/enemies/enemy_charge_adept.tres"
const SUMMONER_PATH: String = "res://game/pawns/data/enemies/enemy_summoner.tres"
const SUMMON_MINION_PATH: String = "res://game/pawns/data/enemies/enemy_summon_minion.tres"


func _load_profile(path: String) -> PawnData:
	var data: PawnData = load(path) as PawnData
	assert_object(data).is_not_null()
	return data


## 有效生命：长线型的核心威胁轴，按数据字段直接相加，不涉及战斗结算。
func _effective_health(data: PawnData) -> float:
	return data.max_health + data.max_shield


## 每秒伤害：单次攻击 / 攻击间隔的标称口径，只用于区分威胁档位，不代表真实战斗结果。
func _damage_per_second(data: PawnData) -> float:
	return data.attack / maxf(data.attack_interval, 0.001)


func test_all_threat_profiles_are_well_formed_enemy_data() -> void:
	for path: String in [BASELINE_PATH, IRON_GUARD_PATH, BLOOD_BLADE_PATH]:
		var data: PawnData = _load_profile(path)
		assert_bool(data.id != &"").is_true()
		assert_bool(data.display_name != "").is_true()
		assert_str(String(data.faction)).is_equal("enemy")
		assert_bool(data.max_health > 0.0).is_true()
		assert_bool(data.attack > 0.0).is_true()
		assert_bool(data.attack_interval > 0.0).is_true()
		assert_bool(data.attack_range > 0.0).is_true()
		assert_bool(data.move_speed > 0.0).is_true()
		# 傀儡类敌人没有修炼体系，也不携带主动技能：威胁只来自基础数值。
		assert_object(data.realm).is_null()
		assert_int(data.get_active_skills().size()).is_equal(0)

	# id 必须唯一，避免不同档案被当成同一单位。
	var baseline: PawnData = _load_profile(BASELINE_PATH)
	var iron_guard: PawnData = _load_profile(IRON_GUARD_PATH)
	var blood_blade: PawnData = _load_profile(BLOOD_BLADE_PATH)
	assert_bool(baseline.id != iron_guard.id).is_true()
	assert_bool(baseline.id != blood_blade.id).is_true()
	assert_bool(iron_guard.id != blood_blade.id).is_true()


func test_long_line_and_burst_profiles_separate_on_threat_axes() -> void:
	var baseline: PawnData = _load_profile(BASELINE_PATH)
	var iron_guard: PawnData = _load_profile(IRON_GUARD_PATH)
	var blood_blade: PawnData = _load_profile(BLOOD_BLADE_PATH)

	# 长线型：有效生命最高、标称每秒伤害最低——战斗被拉长，威胁低但耐打。
	assert_bool(_effective_health(iron_guard) > _effective_health(baseline)).is_true()
	assert_bool(_effective_health(iron_guard) > _effective_health(blood_blade)).is_true()
	assert_bool(_damage_per_second(iron_guard) < _damage_per_second(baseline)).is_true()
	assert_bool(_damage_per_second(iron_guard) < _damage_per_second(blood_blade)).is_true()

	# 爆发型：单次伤害与每秒伤害最高、有效生命最低——战斗很短但每一次攻击都很危险。
	assert_bool(blood_blade.attack > iron_guard.attack).is_true()
	assert_bool(blood_blade.attack > baseline.attack).is_true()
	assert_bool(_damage_per_second(blood_blade) > _damage_per_second(baseline)).is_true()
	assert_bool(_damage_per_second(blood_blade) > _damage_per_second(iron_guard)).is_true()
	assert_bool(_effective_health(blood_blade) < _effective_health(baseline)).is_true()
	assert_bool(_effective_health(blood_blade) < _effective_health(iron_guard)).is_true()

	# 基线档案保持既有数值，不参与本次威胁轴重标定。
	assert_float(baseline.max_health).is_equal_approx(180.0, 0.001)
	assert_float(baseline.attack).is_equal_approx(12.0, 0.001)
	assert_float(baseline.attack_interval).is_equal_approx(1.1, 0.001)


## INC-COMBAT-011：六类问题型敌人必须互不重复，且各自映射到一个唯一的技能价值轴。
## 这是「不同敌人让不同 Skill 的价值发生变化」在数据层的可查询前提，不靠文档描述。
func test_problem_profiles_cover_six_distinct_skill_value_axes() -> void:
	var paths: Array[String] = [
		MELEE_RAIDER_PATH,
		ARCHER_PATH,
		BLOOD_BLADE_PATH,
		IRON_GUARD_PATH,
		BOSS_PATH,
		SUMMONER_PATH,
	]
	var tags: Array[int] = []
	var axes: Array[StringName] = []
	for path: String in paths:
		var data: PawnData = _load_profile(path)
		assert_bool(data.problem_tag != PawnData.ProblemTag.NONE).is_true()
		assert_bool(data.get_problem_tag_label() != "").is_true()
		assert_bool(tags.has(data.problem_tag)).is_false()
		assert_bool(axes.has(data.get_skill_value_axis())).is_false()
		tags.append(data.problem_tag)
		axes.append(data.get_skill_value_axis())
	assert_int(tags.size()).is_equal(6)
	assert_int(axes.size()).is_equal(6)


## 召唤增援契约：召唤者必须带问题标签与合法增援档案；召唤物本身不是问题源，也不能再次召唤。
func test_summoner_declares_reinforcement_contract() -> void:
	var summoner: PawnData = _load_profile(SUMMONER_PATH)
	assert_bool(summoner.problem_tag == PawnData.ProblemTag.SUMMON_REINFORCEMENT).is_true()
	assert_bool(summoner.can_summon()).is_true()
	assert_object(summoner.summon_minion).is_not_null()
	assert_str(String(summoner.summon_minion.id)).is_equal("enemy_summon_minion")
	assert_str(String(summoner.summon_minion.faction)).is_equal("enemy")
	assert_bool(summoner.summon_initial_delay > 0.0).is_true()
	assert_bool(summoner.summon_interval > 0.0).is_true()
	assert_bool(summoner.summon_max_count > 0).is_true()

	var minion: PawnData = _load_profile(SUMMON_MINION_PATH)
	assert_bool(minion.problem_tag == PawnData.ProblemTag.NONE).is_true()
	assert_bool(minion.can_summon()).is_false()


## 蓄力可打断：危险窗口契约仍由 dangerous_skill + 两个时长字段表达，不因问题标签而改语义。
func test_charge_interrupt_profiles_keep_danger_window_contract() -> void:
	var boss: PawnData = _load_profile(BOSS_PATH)
	assert_bool(boss.problem_tag == PawnData.ProblemTag.CHARGE_INTERRUPT).is_true()
	assert_bool(boss.has_danger_window()).is_true()
	assert_bool(boss.dangerous_skill != null).is_true()
	assert_float(boss.danger_window_interval).is_equal_approx(8.0, 0.001)
	assert_float(boss.danger_window_duration).is_equal_approx(2.0, 0.001)


## 非问题源（例如基线敌人与召唤物）必须返回 none，避免被误编排成问题型遭遇。
func test_non_problem_profiles_return_none_axis() -> void:
	var baseline: PawnData = _load_profile(BASELINE_PATH)
	var minion: PawnData = _load_profile(SUMMON_MINION_PATH)
	assert_bool(baseline.problem_tag == PawnData.ProblemTag.NONE).is_true()
	assert_str(String(baseline.get_skill_value_axis())).is_equal("none")
	assert_str(String(minion.get_skill_value_axis())).is_equal("none")
	assert_str(baseline.get_problem_tag_label()).is_equal("")


## 危险技能的追加代价（INC-COMBAT-013）：聚煞术士的聚煞一击带「护盾挡不住」的追加硬直；
## Boss 的镇狱裂岳斩保持不配置，Boss 战「可被护盾吸收」的口径不因本项改变。
func test_charge_adept_dangerous_skill_carries_stun_followup() -> void:
	var adept: PawnData = _load_profile(CHARGE_ADEPT_PATH)
	assert_bool(adept.problem_tag == PawnData.ProblemTag.CHARGE_INTERRUPT).is_true()
	assert_object(adept.dangerous_skill).is_not_null()
	assert_bool(adept.dangerous_skill.has_followup_skill()).is_true()

	var payload: ActiveSkillDefinition = adept.dangerous_skill.get_followup_skill()
	assert_str(String(payload.id)).is_equal("charge_hardstop")
	assert_int(payload.effect_type).is_equal(ActiveSkillDefinition.SkillEffectType.STUN)
	assert_float(payload.get_normalized_effect_duration()).is_equal_approx(1.6, 0.001)
	# 追加效果不是一个可以被主动施放的技能：它不进灵力与冷却账本，也不出现在档案的技能列表里。
	assert_float(payload.get_normalized_spirit_cost()).is_zero()
	assert_float(payload.get_normalized_cooldown()).is_zero()
	assert_bool(adept.get_active_skills().has(payload)).is_false()

	var boss: PawnData = _load_profile(BOSS_PATH)
	assert_object(boss.dangerous_skill).is_not_null()
	assert_bool(boss.dangerous_skill.has_followup_skill()).is_false()
