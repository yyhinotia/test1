extends GdUnitTestSuite

## 集成层：宗门转化设施（INC-SECT-003）。
##
## 使用真实 Pawn 场景、真实设施资源与真实秘境收益入账路径，验证：
## 藏经阁 → 运行时功法；炼器房 → 运行时强化；丹房 → 丹药 → 生命 / 灵力恢复。
## 所有路径都必须只写运行时状态，不污染静态 PawnData / WeaponDefinition / TechniqueDefinition。

const APPROX: float = 0.001
const FACILITY_DIR: String = "res://game/sect/data/facilities"
const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const PLAYER_WEAPON_PATH: String = "res://game/inventory/data/weapons/qingfeng_sword.tres"
const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"
const FACILITY_IDS: Array[String] = [
	"cave_dwelling",
	"spirit_array",
	"spirit_field",
	"alchemy_room",
	"forge_room",
	"scripture_pavilion",
]


func _load_facilities() -> Array[SectFacilityDefinition]:
	var result: Array[SectFacilityDefinition] = []
	for facility_id: String in FACILITY_IDS:
		result.append(load("%s/%s.tres" % [FACILITY_DIR, facility_id]) as SectFacilityDefinition)
	return result


func _spawn_state() -> SectState:
	var state: SectState = SectState.new()
	state.name = "SectStateConversion"
	state.facilities = _load_facilities()
	auto_free(state)
	add_child(state)
	return state


func _spawn_pawn(scene_path: String) -> Pawn:
	var scene: PackedScene = load(scene_path) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _spawn_player() -> Pawn:
	return _spawn_pawn(PLAYER_SCENE_PATH)


func _make_technique(id: StringName, tier: int = 1) -> TechniqueDefinition:
	var technique: TechniqueDefinition = TechniqueDefinition.new()
	technique.id = id
	technique.display_name = String(id)
	technique.required_realm_tier = tier
	return technique


func _dungeon_max_reward() -> int:
	var dungeon: DungeonDefinition = load(DUNGEON_PATH) as DungeonDefinition
	return dungeon.get_max_reward()


func test_learn_technique_consumes_stones_and_uses_runtime_override() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	state.deposit_spirit_stones(_dungeon_max_reward() * 5)

	var learned: TechniqueDefinition = _make_technique(&"pavilion_runtime_technique")
	var static_count: int = player.data.techniques.size()
	var stones_before: int = state.get_spirit_stones()
	var learned_events: Array[TechniqueDefinition] = []
	var data_build_events: Array[PawnData] = []
	state.technique_learned.connect(
		func(_state: SectState, _pawn: Pawn, technique: TechniqueDefinition) -> void:
			learned_events.append(technique)
	)
	player.data.build_changed.connect(func(changed: PawnData) -> void:
		data_build_events.append(changed)
	)

	assert_bool(state.learn_technique_from_pavilion(learned)).is_true()
	assert_int(state.get_spirit_stones()).is_equal(stones_before - 45)
	assert_int(player.data.techniques.size()).is_equal(static_count)
	assert_int(player.get_learned_techniques().size()).is_equal(1)
	assert_bool(player.has_learned_technique(learned.id)).is_true()
	assert_bool(player.has_technique(learned.id)).is_true()
	assert_int(player.get_build_loadout().techniques.size()).is_equal(static_count + 1)
	assert_array(learned_events).contains_exactly([learned])
	assert_array(data_build_events).is_empty()


func test_learn_technique_rejects_invalid_paths_without_side_effects() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	var learned: TechniqueDefinition = _make_technique(&"pavilion_rejected")
	var duplicate: TechniqueDefinition = player.data.techniques[0]
	var high_tier: TechniqueDefinition = _make_technique(&"pavilion_high_tier", 2)
	var unconfigured: TechniqueDefinition = _make_technique(&"   ")

	assert_bool(state.learn_technique_from_pavilion(learned)).is_false()
	assert_int(state.get_spirit_stones()).is_zero()

	state.deposit_spirit_stones(_dungeon_max_reward() * 5)
	var funded: int = state.get_spirit_stones()
	assert_bool(state.learn_technique_from_pavilion(null)).is_false()
	assert_bool(state.learn_technique_from_pavilion(unconfigured)).is_false()
	assert_bool(state.learn_technique_from_pavilion(duplicate)).is_false()
	assert_bool(state.learn_technique_from_pavilion(high_tier)).is_false()
	assert_int(state.get_spirit_stones()).is_equal(funded)
	assert_int(player.get_learned_techniques().size()).is_zero()
	assert_int(player.data.techniques.size()).is_equal(1)


func test_strengthen_weapon_consumes_stones_and_respects_facility_level_cap() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	state.deposit_spirit_stones(_dungeon_max_reward() * 5)

	var events: Array[int] = []
	state.weapon_strengthened.connect(
		func(_state: SectState, _pawn: Pawn, level: int) -> void:
			events.append(level)
	)

	assert_bool(state.strengthen_weapon()).is_true()
	assert_int(player.get_forge_level()).is_equal(1)
	assert_int(state.get_spirit_stones()).is_equal(_dungeon_max_reward() * 5 - 40)

	# 炼器房 1 级只允许强化到 1 级：再次强化必须无副作用。
	var after_first: int = state.get_spirit_stones()
	assert_bool(state.strengthen_weapon()).is_false()
	assert_int(player.get_forge_level()).is_equal(1)
	assert_int(state.get_spirit_stones()).is_equal(after_first)

	assert_bool(state.upgrade_facility(&"forge_room")).is_true()
	assert_bool(state.strengthen_weapon()).is_true()
	assert_int(player.get_forge_level()).is_equal(2)
	assert_bool(state.strengthen_weapon()).is_false()
	assert_bool(state.upgrade_facility(&"forge_room")).is_true()
	assert_bool(state.strengthen_weapon()).is_true()
	assert_int(player.get_forge_level()).is_equal(Pawn.MAX_FORGE_LEVEL)
	assert_bool(state.strengthen_weapon()).is_false()
	assert_array(events).contains_exactly([1, 2, 3])


func test_strengthen_weapon_rejects_without_weapon_or_stones() -> void:
	var state_without_weapon: SectState = _spawn_state()
	var enemy: Pawn = _spawn_pawn(ENEMY_SCENE_PATH)
	await await_idle_frame()
	state_without_weapon.bind_cultivator(enemy)
	state_without_weapon.deposit_spirit_stones(_dungeon_max_reward())
	var enemy_funds: int = state_without_weapon.get_spirit_stones()
	assert_bool(state_without_weapon.strengthen_weapon()).is_false()
	assert_int(state_without_weapon.get_spirit_stones()).is_equal(enemy_funds)

	var state_without_stones: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state_without_stones.bind_cultivator(player)
	assert_bool(state_without_stones.strengthen_weapon()).is_false()
	assert_int(player.get_forge_level()).is_zero()
	assert_int(state_without_stones.get_spirit_stones()).is_zero()


func test_refine_pill_consumes_herbs_and_use_pill_restores_real_resources() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)

	assert_int(state.harvest_spirit_field()).is_equal(2)
	assert_int(state.harvest_spirit_field()).is_equal(2)
	assert_int(state.get_spirit_herbs()).is_equal(4)
	var refined_events: Array[int] = []
	state.pill_refined.connect(func(_state: SectState, amount: int) -> void:
		refined_events.append(amount)
	)

	assert_int(state.refine_pill()).is_equal(1)
	assert_int(state.get_spirit_herbs()).is_equal(2)
	assert_int(state.get_pills()).is_equal(1)
	assert_array(refined_events).contains_exactly([1])

	player.take_damage(player.data.defense + player.data.max_shield + 20.0)
	assert_bool(player.try_spend_spirit(40.0)).is_true()
	var health_before: float = player.current_health
	var spirit_before: float = player.current_spirit
	assert_float(health_before).is_equal_approx(100.0, APPROX)
	assert_float(spirit_before).is_equal_approx(60.0, APPROX)

	var used_events: Array[float] = []
	state.pill_used.connect(
		func(_state: SectState, _pawn: Pawn, restored: float) -> void:
			used_events.append(restored)
	)
	var restored: float = state.use_pill()
	assert_float(restored).is_equal_approx(30.0, APPROX)
	assert_int(state.get_pills()).is_zero()
	assert_float(player.current_health).is_equal_approx(health_before + 15.0, APPROX)
	assert_float(player.current_spirit).is_equal_approx(spirit_before + 15.0, APPROX)
	assert_array(used_events).contains_exactly([30.0])
	assert_float(state.use_pill()).is_zero()
	assert_int(state.get_pills()).is_zero()


func test_refine_pill_rejects_without_herbs_and_keeps_inventory_unchanged() -> void:
	var state: SectState = _spawn_state()

	assert_int(state.refine_pill()).is_zero()
	assert_int(state.get_spirit_herbs()).is_zero()
	assert_int(state.get_pills()).is_zero()
	assert_int(state.harvest_spirit_field()).is_equal(2)
	assert_int(state.refine_pill()).is_equal(1)
	assert_int(state.get_spirit_herbs()).is_zero()
	assert_int(state.get_pills()).is_equal(1)
	assert_int(state.refine_pill()).is_zero()
	assert_int(state.get_spirit_herbs()).is_zero()
	assert_int(state.get_pills()).is_equal(1)


func test_use_pill_rejects_without_cultivator_or_living_target() -> void:
	var state: SectState = _spawn_state()
	assert_int(state.harvest_spirit_field()).is_equal(2)
	assert_int(state.refine_pill()).is_equal(1)
	assert_int(state.get_pills()).is_equal(1)

	assert_float(state.use_pill()).is_zero()
	assert_int(state.get_pills()).is_equal(1)

	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	player.take_damage(player.data.defense + player.data.max_health + player.data.max_shield + 100.0)
	assert_bool(player.is_dead()).is_true()
	assert_float(state.use_pill()).is_zero()
	assert_int(state.get_pills()).is_equal(1)


func test_conversion_paths_leave_real_static_resources_unmodified() -> void:
	var state: SectState = _spawn_state()
	var player: Pawn = _spawn_player()
	await await_idle_frame()
	state.bind_cultivator(player)
	state.deposit_spirit_stones(_dungeon_max_reward() * 5)

	var data: PawnData = player.data
	var real_data: PawnData = load(PLAYER_DATA_PATH) as PawnData
	var weapon: WeaponDefinition = data.weapon
	var real_weapon: WeaponDefinition = load(PLAYER_WEAPON_PATH) as WeaponDefinition
	assert_object(real_data).is_same(data)
	assert_object(real_weapon).is_same(weapon)
	var techniques_before: int = data.techniques.size()
	var attack_before: float = data.attack
	var weapon_id_before: StringName = weapon.id
	var weapon_tier_before: int = weapon.required_realm_tier

	assert_bool(state.learn_technique_from_pavilion(_make_technique(&"static_integrity"))).is_true()
	assert_bool(state.strengthen_weapon()).is_true()
	assert_int(state.harvest_spirit_field()).is_equal(2)
	assert_int(state.refine_pill()).is_equal(1)

	assert_int(real_data.techniques.size()).is_equal(techniques_before)
	assert_float(real_data.attack).is_equal_approx(attack_before, APPROX)
	assert_str(String(real_weapon.id)).is_equal(String(weapon_id_before))
	assert_int(real_weapon.required_realm_tier).is_equal(weapon_tier_before)
