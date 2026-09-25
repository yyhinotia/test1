extends GdUnitTestSuite

## 单元层：敌人威胁档案的数据契约（INC-PAWNS-016）。
## 只验证数据本身可推导的性质（有效生命 / 每秒伤害 / 单次伤害）与字段完整性，
## 不加载场景、不驱动战斗，也不复制任何战斗结算规则。

const BASELINE_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const IRON_GUARD_PATH: String = "res://game/pawns/data/enemies/enemy_iron_guard.tres"
const BLOOD_BLADE_PATH: String = "res://game/pawns/data/enemies/enemy_blood_blade.tres"


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
