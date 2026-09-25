extends GdUnitTestSuite

## 集成层：Pawn 的 Build 汇总接口 —— 境界 + 功法 + 当前主动技能 → 容量占用与校验结果。
## 使用真实 Pawn 场景与真实预设资源；本层同时证明这些接口是只读的，不会改动战斗状态。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const REALM_DIR: String = "res://game/cultivation/data/realms/"
const TECHNIQUE_DIR: String = "res://game/cultivation/data/techniques/"
const APPROX: float = 0.001


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _realm(file_name: String) -> RealmDefinition:
	return load(REALM_DIR + file_name) as RealmDefinition


func _technique(file_name: String) -> TechniqueDefinition:
	return load(TECHNIQUE_DIR + file_name) as TechniqueDefinition


func _player_data_with(realm: RealmDefinition, techniques: Array[TechniqueDefinition]) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.realm = realm
	data.techniques.assign(techniques)
	return data


func test_player_preset_reports_realm_and_valid_build() -> void:
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()

	var realm: RealmDefinition = player.get_realm()
	assert_object(realm).is_not_null()
	assert_str(String(realm.id)).is_equal("qi_refining")
	assert_str(realm.display_name).is_equal("炼气")

	var loadout: BuildLoadout = player.get_build_loadout()
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(2)
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_str(String(loadout.get_weapon().id)).is_equal("qingfeng_sword")
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_PASSIVE_SKILL)).is_zero()
	assert_int(loadout.get_capacity(RealmDefinition.KIND_PASSIVE_SKILL)).is_equal(1)
	assert_str(String(loadout.techniques[0].id)).is_equal("sword_cultivation")
	assert_str(String(loadout.active_skills[0].id)).is_equal("sword_strike")

	var validation: BuildValidationResult = player.get_build_validation()
	assert_bool(validation.is_valid()).is_true()
	assert_str(validation.get_summary()).is_empty()


## 武器容量来自境界而不是硬编码：把境界武器槽改成 0 后，同一把武器必须报容量超限。
func test_weapon_over_capacity_is_reported_from_realm_data() -> void:
	var realm: RealmDefinition = _realm("qi_refining.tres").duplicate(true) as RealmDefinition
	realm.weapon_slots = 0
	var data: PawnData = _player_data_with(realm, [_technique("sword_cultivation.tres")])
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, data)
	await await_idle_frame()

	var validation: BuildValidationResult = player.get_build_validation()
	assert_array(validation.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_OVER_CAPACITY])
	assert_str(String(validation.get_errors()[0]["kind"])).is_equal("weapon")
	assert_int(player.get_build_loadout().get_used_slots(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_int(player.get_build_loadout().get_capacity(RealmDefinition.KIND_WEAPON)).is_zero()


## 没有武器与没有境界的单位都不应该产生武器相关错误以外的新结论。
func test_enemy_without_weapon_has_no_weapon_errors() -> void:
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()

	var loadout: BuildLoadout = enemy.get_build_loadout()
	assert_object(loadout.get_weapon()).is_null()
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_WEAPON)).is_zero()
	assert_array(enemy.get_build_validation().get_error_codes() as Array).contains_exactly([
		BuildValidationResult.CODE_MISSING_REALM,
	])


func test_unit_without_realm_reports_missing_realm_read_only() -> void:
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()

	assert_object(enemy.get_realm()).is_null()
	var health_before: float = enemy.current_health
	var shield_before: float = enemy.current_shield
	var position_before: Vector2 = enemy.global_position
	var state_before: int = enemy.state

	var validation: BuildValidationResult = enemy.get_build_validation()
	assert_array(validation.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_MISSING_REALM])
	assert_str(validation.get_summary()).is_equal("未配置境界，无法计算 Build 容量")
	assert_int(enemy.get_build_loadout().get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_zero()

	assert_float(enemy.current_health).is_equal_approx(health_before, APPROX)
	assert_float(enemy.current_shield).is_equal_approx(shield_before, APPROX)
	assert_that(enemy.global_position).is_equal(position_before)
	assert_int(enemy.state).is_equal(state_before)
	assert_bool(enemy.is_alive()).is_true()


func test_conflicting_techniques_are_reported_from_pawn_data() -> void:
	var techniques: Array[TechniqueDefinition] = [
		_technique("sword_cultivation.tres"),
		_technique("body_cultivation.tres"),
	]
	var player: Pawn = _spawn_pawn(
		PLAYER_PAWN_SCENE_PATH,
		_player_data_with(_realm("foundation_establishment.tres"), techniques)
	)
	await await_idle_frame()

	var validation: BuildValidationResult = player.get_build_validation()
	assert_array(validation.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_TECHNIQUE_CONFLICT])
	assert_bool(validation.get_summary().contains("功法互斥")).is_true()
	# 筑基期功法容量为 2：冲突是唯一原因，与容量无关。
	assert_int(player.get_build_loadout().get_used_slots(RealmDefinition.KIND_TECHNIQUE)).is_equal(2)
	assert_int(player.get_build_loadout().get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(2)


func test_build_summary_counts_are_stable_across_runtime_changes() -> void:
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(40.0, 0.0)
	await await_idle_frame()

	var spirit_before: float = player.current_spirit
	var skill: ActiveSkillDefinition = player.data.active_skill
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_bool(player.cast_skill(skill, enemy)).is_true()
	await await_idle_frame()

	# 施法只改灵力与冷却；Build 汇总计数与校验结论不受影响。
	assert_float(player.current_spirit).is_less(spirit_before)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_greater(0.0)
	assert_int(player.get_build_loadout().get_used_slots(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(1)
	assert_int(player.get_build_loadout().get_used_slots(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_bool(player.get_build_validation().is_valid()).is_true()

	# 返回的汇总与预设解耦：改动返回值不得污染 PawnData。
	var loadout: BuildLoadout = player.get_build_loadout()
	loadout.techniques.clear()
	assert_int(player.data.techniques.size()).is_equal(1)