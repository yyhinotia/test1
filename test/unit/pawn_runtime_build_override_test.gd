extends GdUnitTestSuite

## 单元层：Pawn 的运行时 Build 覆盖层只改变自身读模型，不改写 PawnData / WeaponDefinition。
## 这里不实例化场景，只验证功法领悟、武器强化、容量 / 冲突投影与信号所有权。

const TECHNIQUE_DIR: String = "res://game/cultivation/data/techniques/"
const REALM_DIR: String = "res://game/cultivation/data/realms/"
const WEAPON_DIR: String = "res://game/inventory/data/weapons/"
const APPROX: float = 0.001


func _realm(file_name: String) -> RealmDefinition:
	return load(REALM_DIR + file_name) as RealmDefinition


func _technique(file_name: String) -> TechniqueDefinition:
	return load(TECHNIQUE_DIR + file_name) as TechniqueDefinition


func _weapon(file_name: String) -> WeaponDefinition:
	return load(WEAPON_DIR + file_name) as WeaponDefinition


func _make_technique(id: StringName, display_name: String = "测试功法", tier: int = 1) -> TechniqueDefinition:
	var technique: TechniqueDefinition = TechniqueDefinition.new()
	technique.id = id
	technique.display_name = display_name
	technique.required_realm_tier = tier
	return technique


func _make_data(realm: RealmDefinition, techniques: Array[TechniqueDefinition] = [], weapon: WeaponDefinition = null) -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = &"runtime_build_test"
	data.realm = realm
	data.techniques = techniques
	data.weapon = weapon
	return data


func _make_pawn(data: PawnData) -> Pawn:
	var pawn: Pawn = Pawn.new()
	pawn.data = data
	auto_free(pawn)
	return pawn


func test_learn_technique_appends_in_order_and_keeps_static_data_unchanged() -> void:
	var static_technique: TechniqueDefinition = _technique("sword_cultivation.tres")
	var learned_a: TechniqueDefinition = _make_technique(&"learned_a")
	var learned_b: TechniqueDefinition = _make_technique(&"learned_b")
	var data: PawnData = _make_data(_realm("qi_refining.tres"), [static_technique])
	var pawn: Pawn = _make_pawn(data)

	assert_bool(pawn.learn_technique(learned_a)).is_true()
	assert_bool(pawn.learn_technique(learned_b)).is_true()

	var loadout: BuildLoadout = pawn.get_build_loadout()
	assert_int(loadout.techniques.size()).is_equal(3)
	assert_object(loadout.techniques[0]).is_same(static_technique)
	assert_object(loadout.techniques[1]).is_same(learned_a)
	assert_object(loadout.techniques[2]).is_same(learned_b)

	assert_int(data.techniques.size()).is_equal(1)
	assert_object(data.techniques[0]).is_same(static_technique)
	assert_int(pawn.get_learned_techniques().size()).is_equal(2)
	assert_bool(pawn.has_learned_technique(&"learned_a")).is_true()
	assert_bool(pawn.has_learned_technique(&"sword_cultivation")).is_false()
	assert_bool(pawn.has_technique(&"sword_cultivation")).is_true()
	assert_bool(pawn.has_technique(&"learned_b")).is_true()


func test_learn_technique_rejects_null_unconfigured_and_duplicate_without_side_effects() -> void:
	var static_technique: TechniqueDefinition = _technique("sword_cultivation.tres")
	var unconfigured: TechniqueDefinition = _make_technique(&"   ")
	var learned: TechniqueDefinition = _make_technique(&"learned_once")
	var data: PawnData = _make_data(_realm("qi_refining.tres"), [static_technique])
	var pawn: Pawn = _make_pawn(data)
	var changes: Array[Pawn] = []
	pawn.build_changed.connect(func(changed: Pawn) -> void:
		changes.append(changed)
	)

	assert_bool(pawn.learn_technique(null)).is_false()
	assert_bool(pawn.learn_technique(unconfigured)).is_false()
	assert_bool(pawn.learn_technique(static_technique)).is_false()
	assert_bool(pawn.learn_technique(learned)).is_true()
	assert_bool(pawn.learn_technique(learned)).is_false()

	assert_int(changes.size()).is_equal(1)
	assert_object(changes[0]).is_same(pawn)
	assert_int(pawn.get_learned_techniques().size()).is_equal(1)
	assert_int(pawn.get_build_loadout().techniques.size()).is_equal(2)


func test_runtime_technique_flows_into_build_validation() -> void:
	var static_technique: TechniqueDefinition = _technique("sword_cultivation.tres")
	var body_technique: TechniqueDefinition = _technique("body_cultivation.tres")
	var pawn: Pawn = _make_pawn(_make_data(_realm("qi_refining.tres"), [static_technique]))

	assert_bool(pawn.learn_technique(body_technique)).is_true()

	var codes: Array[StringName] = pawn.get_build_validation().get_error_codes()
	assert_bool(codes.has(BuildValidationResult.CODE_TECHNIQUE_CONFLICT)).is_true()
	assert_bool(codes.has(BuildValidationResult.CODE_OVER_CAPACITY)).is_true()
	assert_int(pawn.get_build_loadout().get_used_slots(RealmDefinition.KIND_TECHNIQUE)).is_equal(2)


func test_strengthen_weapon_reaches_cap_and_noops_without_weapon() -> void:
	var weapon: WeaponDefinition = _weapon("qingfeng_sword.tres")
	var data: PawnData = _make_data(_realm("qi_refining.tres"), [], weapon)
	var pawn: Pawn = _make_pawn(data)
	var changes: Array[Pawn] = []
	pawn.build_changed.connect(func(changed: Pawn) -> void:
		changes.append(changed)
	)

	assert_int(pawn.get_forge_level()).is_zero()
	assert_bool(pawn.can_strengthen_weapon()).is_true()
	assert_int(pawn.strengthen_weapon()).is_equal(1)
	assert_int(pawn.strengthen_weapon()).is_equal(2)
	assert_int(pawn.strengthen_weapon()).is_equal(3)
	assert_int(pawn.strengthen_weapon()).is_equal(3)
	assert_bool(pawn.can_strengthen_weapon()).is_false()
	assert_int(changes.size()).is_equal(3)

	var no_weapon: Pawn = _make_pawn(_make_data(_realm("qi_refining.tres")))
	assert_bool(no_weapon.can_strengthen_weapon()).is_false()
	assert_int(no_weapon.strengthen_weapon()).is_zero()
	assert_int(no_weapon.get_forge_level()).is_zero()
	assert_float(no_weapon.get_attack_power()).is_equal_approx(10.0, APPROX)


func test_attack_power_uses_forge_level_without_mutating_static_resources() -> void:
	var weapon: WeaponDefinition = _weapon("qingfeng_sword.tres")
	var data: PawnData = _make_data(_realm("qi_refining.tres"), [], weapon)
	data.attack = 28.0
	var pawn: Pawn = _make_pawn(data)
	var weapon_id: StringName = weapon.id
	var weapon_name: String = weapon.display_name
	var weapon_tier: int = weapon.required_realm_tier

	assert_float(pawn.get_attack_power()).is_equal_approx(28.0, APPROX)
	assert_int(pawn.strengthen_weapon()).is_equal(1)
	assert_float(pawn.get_attack_power()).is_equal_approx(28.0 + Pawn.FORGE_ATTACK_BONUS_PER_LEVEL, APPROX)

	assert_float(data.attack).is_equal_approx(28.0, APPROX)
	assert_str(String(weapon.id)).is_equal(String(weapon_id))
	assert_str(weapon.display_name).is_equal(weapon_name)
	assert_int(weapon.required_realm_tier).is_equal(weapon_tier)


func test_build_changed_is_pawn_owned_and_data_signal_is_not_faked() -> void:
	var data: PawnData = _make_data(_realm("qi_refining.tres"))
	var pawn: Pawn = _make_pawn(data)
	var pawn_changes: Array[Pawn] = []
	var data_changes: Array[PawnData] = []
	pawn.build_changed.connect(func(changed: Pawn) -> void:
		pawn_changes.append(changed)
	)
	data.build_changed.connect(func(changed: PawnData) -> void:
		data_changes.append(changed)
	)

	assert_bool(pawn.learn_technique(_make_technique(&"signal_test"))).is_true()
	assert_int(pawn.strengthen_weapon()).is_zero()
	assert_bool(pawn.learn_technique(null)).is_false()

	assert_int(pawn_changes.size()).is_equal(1)
	assert_int(data_changes.size()).is_zero()
