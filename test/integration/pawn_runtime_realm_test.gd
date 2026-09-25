extends GdUnitTestSuite

## 集成层：真实 Pawn 场景上的运行时境界覆盖、突破与恢复校验。
## 这里锁定“境界是运行时状态、静态 PawnData 是起始基线”的边界。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const QI_REFINING_PATH: String = "res://game/cultivation/data/realms/qi_refining.tres"
const FOUNDATION_PATH: String = "res://game/cultivation/data/realms/foundation_establishment.tres"
const GOLDEN_CORE_PATH: String = "res://game/cultivation/data/realms/golden_core.tres"
const APPROX: float = 0.0001


func _spawn_pawn(scene_path: String) -> Pawn:
	var scene: PackedScene = load(scene_path) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	auto_free(pawn)
	add_child(pawn)
	return pawn


func test_breakthrough_advances_runtime_realm_and_capacity_without_static_pollution() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	var base_realm: RealmDefinition = pawn.get_base_realm()
	var loadout: BuildLoadout = pawn.get_build_loadout()
	assert_str(String(base_realm.id)).is_equal("qi_refining")
	assert_int(loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(2)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_PASSIVE_SKILL)).is_equal(1)

	var realm_events: Array[Dictionary] = []
	var build_events: Array[Pawn] = []
	pawn.realm_changed.connect(func(_pawn: Pawn, previous_realm: RealmDefinition, current_realm: RealmDefinition) -> void:
		realm_events.append({"previous": previous_realm.id, "current": current_realm.id})
	)
	pawn.build_changed.connect(func(changed: Pawn) -> void:
		build_events.append(changed)
	)

	pawn.set_cultivation_exp(100.0, &"test_ready")
	assert_bool(pawn.is_ready_for_breakthrough()).is_true()
	assert_bool(pawn.try_breakthrough()).is_true()

	assert_str(String(pawn.get_realm().id)).is_equal("foundation_establishment")
	assert_str(String(pawn.get_base_realm().id)).is_equal("qi_refining")
	assert_float(pawn.get_cultivation_snapshot()["current_exp"]).is_equal_approx(0.0, APPROX)
	assert_float(pawn.get_cultivation_snapshot()["required_exp"]).is_equal_approx(100.0, APPROX)
	assert_bool(pawn.get_cultivation_snapshot()["ready"]).is_false()
	assert_int(realm_events.size()).is_equal(1)
	assert_str(String(realm_events[0]["previous"])).is_equal("qi_refining")
	assert_str(String(realm_events[0]["current"])).is_equal("foundation_establishment")
	assert_int(build_events.size()).is_equal(1)

	loadout = pawn.get_build_loadout()
	assert_str(String(loadout.realm.id)).is_equal("foundation_establishment")
	assert_int(loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(2)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(3)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_PASSIVE_SKILL)).is_equal(2)

	var static_data: PawnData = load(PLAYER_DATA_PATH) as PawnData
	assert_str(String(static_data.realm.id)).is_equal("qi_refining")
	assert_str(String((load(QI_REFINING_PATH) as RealmDefinition).id)).is_equal("qi_refining")


func test_restore_realm_accepts_forward_chain_and_rejects_regression_or_unreachable_realm() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()

	var foundation: RealmDefinition = load(FOUNDATION_PATH) as RealmDefinition
	var golden_core: RealmDefinition = load(GOLDEN_CORE_PATH) as RealmDefinition
	assert_bool(pawn.restore_realm(foundation, 42.0)).is_true()
	assert_str(String(pawn.get_realm().id)).is_equal("foundation_establishment")
	assert_float(pawn.get_cultivation_snapshot()["current_exp"]).is_equal_approx(42.0, APPROX)
	assert_str(String(pawn.get_base_realm().id)).is_equal("qi_refining")

	# 向后回退拒绝；从炼气链不可达的元婴拒绝；两者都不改变当前运行时境界。
	assert_bool(pawn.restore_realm(load(QI_REFINING_PATH) as RealmDefinition, 0.0)).is_false()
	var nascent_soul: RealmDefinition = load("res://game/cultivation/data/realms/nascent_soul.tres") as RealmDefinition
	assert_bool(pawn.restore_realm(nascent_soul, 0.0)).is_false()
	assert_str(String(pawn.get_realm().id)).is_equal("foundation_establishment")
	assert_float(pawn.get_cultivation_snapshot()["current_exp"]).is_equal_approx(42.0, APPROX)

	# 金丹在链上且高于当前，允许恢复。
	assert_bool(pawn.restore_realm(golden_core, 7.0)).is_true()
	assert_str(String(pawn.get_realm().id)).is_equal("golden_core")
	assert_float(pawn.get_cultivation_snapshot()["current_exp"]).is_equal_approx(7.0, APPROX)


func test_breakthrough_is_rejected_without_cultivation_or_ready_progress() -> void:
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()
	assert_bool(enemy.try_breakthrough()).is_false()

	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	assert_bool(pawn.try_breakthrough()).is_false()
	assert_str(String(pawn.get_realm().id)).is_equal("qi_refining")
	assert_float(pawn.get_cultivation_snapshot()["current_exp"]).is_zero()