extends GdUnitTestSuite

## 集成层：真实 Pawn 场景装配 CultivationProgress，并保持 Pawn → UI 可用的信号契约。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const APPROX: float = 0.0001


func _spawn_pawn(scene_path: String) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	auto_free(pawn)
	add_child(pawn)
	return pawn


func test_player_pawn_has_configured_cultivation_progress() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()

	var component: CultivationProgressComponent = pawn.get_cultivation_progress()
	assert_object(component).is_not_null()
	assert_bool(component.is_configured()).is_true()
	assert_bool(component.has_next_realm()).is_true()
	assert_float(component.get_required_exp()).is_equal_approx(100.0, APPROX)
	assert_float(component.get_current_exp()).is_zero()

	var snapshot: Dictionary = pawn.get_cultivation_snapshot()
	assert_str(String(snapshot["realm_name"])).is_equal("炼气")
	assert_str(String(snapshot["next_realm_name"])).is_equal("筑基")
	assert_bool(bool(snapshot["ready"])).is_false()


func test_pawn_forwards_cultivation_progress_and_ready_events() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()

	var progress_events: Array[Dictionary] = []
	var ready_events: Array[Pawn] = []
	pawn.cultivation_changed.connect(func(changed: Pawn, current_exp: float, required_exp: float) -> void:
		progress_events.append({"pawn": changed, "current": current_exp, "required": required_exp})
	)
	pawn.cultivation_ready.connect(func(ready_pawn: Pawn) -> void:
		ready_events.append(ready_pawn)
	)

	assert_float(pawn.gain_cultivation_exp(72.0, &"test_gain")).is_equal_approx(72.0, APPROX)
	assert_int(progress_events.size()).is_equal(1)
	assert_float(float(progress_events[0]["current"])).is_equal_approx(72.0, APPROX)
	assert_float(pawn.get_cultivation_snapshot()["ratio"]).is_equal_approx(0.72, APPROX)

	assert_float(pawn.set_cultivation_exp(100.0, &"test_ready")).is_equal_approx(28.0, APPROX)
	assert_int(progress_events.size()).is_equal(2)
	assert_int(ready_events.size()).is_equal(1)
	assert_bool(pawn.is_ready_for_breakthrough()).is_true()

	assert_float(pawn.gain_cultivation_exp(50.0, &"overflow")).is_zero()
	assert_int(ready_events.size()).is_equal(1)


func test_enemy_without_realm_has_no_implicit_cultivation_progress() -> void:
	var pawn: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()

	var snapshot: Dictionary = pawn.get_cultivation_snapshot()
	assert_bool(bool(snapshot["has_next_realm"])).is_false()
	assert_bool(pawn.is_ready_for_breakthrough()).is_false()
	assert_float(pawn.gain_cultivation_exp(100.0)).is_zero()
	assert_float(float(snapshot["required_exp"])).is_zero()