extends GdUnitTestSuite

## 单元层（纯逻辑）：秘境 Boss 敌人档案（INC-PAWNS-017）。
##
## 锁定「终局对手 = 更硬、更能持续压制的敌人」这一数据定位，
## 并加一条回归护栏：本 Increment 只允许新增 Boss 档案，不允许顺手改动既有敌人数值。

const BOSS_PATH: String = "res://game/pawns/data/enemies/enemy_dungeon_boss.tres"
const IRON_GUARD_PATH: String = "res://game/pawns/data/enemies/enemy_iron_guard.tres"
const BLOOD_BLADE_PATH: String = "res://game/pawns/data/enemies/enemy_blood_blade.tres"
const TRIAL_PUPPET_PATH: String = "res://game/pawns/data/enemy_pawn.tres"


func _load_pawn_data(path: String) -> PawnData:
	return load(path) as PawnData


func test_boss_profile_is_configured() -> void:
	var boss: PawnData = _load_pawn_data(BOSS_PATH)

	assert_object(boss).is_not_null()
	assert_str(String(boss.id)).is_equal("enemy_dungeon_boss")
	assert_str(String(boss.faction)).is_equal("enemy")
	assert_bool(boss.display_name.strip_edges().is_empty()).is_false()


## Boss 要比「长线」型更硬、更能打，但不得变成「血刃刺客」那种单发高伤：
## 单发高伤会让房间链退化成「谁先手谁赢」，而父级要验证的是资源延续与取舍。
func test_boss_is_tougher_than_iron_guard_but_not_a_burst_killer() -> void:
	var boss: PawnData = _load_pawn_data(BOSS_PATH)
	var iron_guard: PawnData = _load_pawn_data(IRON_GUARD_PATH)
	var blood_blade: PawnData = _load_pawn_data(BLOOD_BLADE_PATH)

	assert_float(boss.max_health).is_greater(iron_guard.max_health)
	assert_float(boss.max_shield).is_greater_equal(iron_guard.max_shield)
	assert_float(boss.attack).is_greater(iron_guard.attack)
	assert_float(boss.attack).is_less(blood_blade.attack)
	assert_float(boss.move_speed).is_less_equal(iron_guard.move_speed)


## 傀儡 / 敌人档案不参与 Build 校验：Boss 也不得引入境界、功法、武器或技能字段。
func test_boss_has_no_build_contract_and_no_skills() -> void:
	var boss: PawnData = _load_pawn_data(BOSS_PATH)

	assert_object(boss.realm).is_null()
	assert_object(boss.weapon).is_null()
	assert_object(boss.active_skill).is_null()
	assert_int(boss.techniques.size()).is_equal(0)
	assert_int(boss.active_skills.size()).is_equal(0)
	assert_array(boss.get_active_skills()).is_empty()


## 回归护栏：既有三份敌人档案的数值基线不得被本 Increment 改动。
func test_existing_enemy_profiles_are_untouched() -> void:
	var trial: PawnData = _load_pawn_data(TRIAL_PUPPET_PATH)
	var iron_guard: PawnData = _load_pawn_data(IRON_GUARD_PATH)
	var blood_blade: PawnData = _load_pawn_data(BLOOD_BLADE_PATH)

	assert_str(String(trial.id)).is_equal("enemy_001")
	assert_float(trial.max_health).is_equal(180.0)
	assert_float(trial.max_shield).is_equal(20.0)
	assert_float(trial.attack).is_equal(12.0)

	assert_str(String(iron_guard.id)).is_equal("enemy_iron_guard")
	assert_float(iron_guard.max_health).is_equal(520.0)
	assert_float(iron_guard.max_shield).is_equal(80.0)
	assert_float(iron_guard.attack).is_equal(16.0)

	assert_str(String(blood_blade.id)).is_equal("enemy_blood_blade")
	assert_float(blood_blade.max_health).is_equal(140.0)
	assert_float(blood_blade.attack).is_equal(60.0)
	assert_float(blood_blade.move_speed).is_equal(140.0)
