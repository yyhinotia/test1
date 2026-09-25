extends GdUnitTestSuite

## 集成层：真实 Player Pawn 场景 + 真实 PawnData / WeaponDefinition 资源，
## 验证运行时 Build 覆盖层只改变本代修士的读模型，并能沿真实攻击路径产生伤害差异。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const PLAYER_WEAPON_PATH: String = "res://game/inventory/data/weapons/qingfeng_sword.tres"
const APPROX: float = 0.001


func _spawn_pawn(scene_path: String) -> Pawn:
	var scene: PackedScene = load(scene_path) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _make_technique(id: StringName) -> TechniqueDefinition:
	var technique: TechniqueDefinition = TechniqueDefinition.new()
	technique.id = id
	technique.display_name = String(id)
	return technique


func _total_pool(pawn: Pawn) -> float:
	return pawn.current_health + pawn.current_shield


func _measure_attack_damage(strengthen_weapon: bool) -> float:
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(32.0, 0.0)
	if strengthen_weapon:
		assert_int(player.strengthen_weapon()).is_equal(1)
	var before: float = _total_pool(enemy)
	assert_bool(player.try_attack(enemy)).is_true()
	return before - _total_pool(enemy)


func test_scene_runtime_technique_appends_to_loadout_without_changing_pawn_data() -> void:
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	var static_count: int = player.data.techniques.size()
	var learned: TechniqueDefinition = _make_technique(&"integration_learned")
	var changes: Array[Pawn] = []
	player.build_changed.connect(func(changed: Pawn) -> void:
		changes.append(changed)
	)

	assert_bool(player.learn_technique(learned)).is_true()
	assert_int(changes.size()).is_equal(1)
	assert_int(player.data.techniques.size()).is_equal(static_count)
	assert_int(player.get_build_loadout().techniques.size()).is_equal(static_count + 1)
	assert_object(player.get_build_loadout().techniques[static_count]).is_same(learned)


func test_scene_weapon_forge_increases_real_attack_damage() -> void:
	var basic_damage: float = await _measure_attack_damage(false)
	var forged_damage: float = await _measure_attack_damage(true)

	assert_float(forged_damage - basic_damage).is_equal_approx(Pawn.FORGE_ATTACK_BONUS_PER_LEVEL, APPROX)
	assert_float(basic_damage).is_equal_approx(25.0, APPROX)
	assert_float(forged_damage).is_equal_approx(31.0, APPROX)


func test_real_player_and_weapon_resources_remain_unmodified_by_runtime_overrides() -> void:
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	var data: PawnData = player.data
	var weapon: WeaponDefinition = data.weapon
	var technique_count_before: int = data.techniques.size()
	var attack_before: float = data.attack
	var weapon_id_before: StringName = weapon.id
	var weapon_name_before: String = weapon.display_name
	var weapon_tier_before: int = weapon.required_realm_tier

	assert_bool(player.learn_technique(_make_technique(&"resource_integrity"))).is_true()
	assert_int(player.strengthen_weapon()).is_equal(1)

	var real_data: PawnData = load(PLAYER_DATA_PATH) as PawnData
	var real_weapon: WeaponDefinition = load(PLAYER_WEAPON_PATH) as WeaponDefinition
	assert_object(real_data).is_same(data)
	assert_object(real_weapon).is_same(weapon)
	assert_int(real_data.techniques.size()).is_equal(technique_count_before)
	assert_float(real_data.attack).is_equal_approx(attack_before, APPROX)
	assert_str(String(real_weapon.id)).is_equal(String(weapon_id_before))
	assert_str(real_weapon.display_name).is_equal(weapon_name_before)
	assert_int(real_weapon.required_realm_tier).is_equal(weapon_tier_before)
