extends GdUnitTestSuite

## 集成层：Pawn → HealthComponent → 资源池 的伤害路由契约。
## 本层实例化真实 Pawn 场景，验证“防御结算 → 先护盾、后生命”的跨组件链路。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const APPROX: float = 0.001


func _spawn_pawn(scene_path: String) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate()
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _spawn_player() -> Pawn:
	return _spawn_pawn(PLAYER_PAWN_SCENE_PATH)


func test_scene_boot_configures_pools_from_data() -> void:
	var pawn: Pawn = _spawn_player()

	assert_object(pawn.data).is_not_null()
	assert_float(pawn.current_health).is_equal_approx(pawn.data.max_health, APPROX)
	assert_float(pawn.current_shield).is_equal_approx(pawn.data.max_shield, APPROX)
	assert_bool(pawn.is_alive()).is_true()

	var health_pool: ResourcePoolComponent = pawn.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID)
	var shield_pool: ResourcePoolComponent = pawn.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID)
	assert_object(health_pool).is_not_null()
	assert_object(shield_pool).is_not_null()
	assert_float(pawn.current_health).is_equal_approx(health_pool.current_value, APPROX)
	assert_float(pawn.current_shield).is_equal_approx(shield_pool.current_value, APPROX)


## 防御在路由之前结算：10 点护盾伤害必须来自 (防御 + 10) 的攻击。
func test_defense_is_applied_before_shield_absorption() -> void:
	var pawn: Pawn = _spawn_player()
	var shield_before: float = pawn.current_shield

	pawn.take_damage(pawn.data.defense + 10.0)

	assert_float(pawn.current_shield).is_equal_approx(shield_before - 10.0, APPROX)
	assert_float(pawn.current_health).is_equal_approx(pawn.data.max_health, APPROX)


## 已验收规则：攻击被防御完全抵消时仍至少造成 1 点伤害。
func test_damage_floor_never_drops_below_one() -> void:
	var pawn: Pawn = _spawn_player()
	var shield_before: float = pawn.current_shield

	pawn.take_damage(pawn.data.defense)
	assert_float(pawn.current_shield).is_equal_approx(shield_before - 1.0, APPROX)

	pawn.take_damage(0.0)
	assert_float(pawn.current_shield).is_equal_approx(shield_before - 2.0, APPROX)


func test_shield_absorbs_before_health() -> void:
	var pawn: Pawn = _spawn_player()
	var overflow: float = 60.0

	pawn.take_damage(pawn.data.defense + overflow)

	assert_float(pawn.current_shield).is_zero()
	assert_float(pawn.current_health).is_equal_approx(pawn.data.max_health - (overflow - pawn.data.max_shield), APPROX)
	assert_bool(pawn.is_alive()).is_true()


## 跨组件信号顺序：护盾变化必须排在生命变化之前，HUD 与 UI 依赖该顺序。
func test_signal_order_is_shield_then_health() -> void:
	var pawn: Pawn = _spawn_player()
	var order: Array[String] = []
	pawn.shield_changed.connect(func(_p: Pawn, _c: float, _m: float) -> void: order.append("shield"))
	pawn.health_changed.connect(func(_p: Pawn, _c: float, _m: float) -> void: order.append("health"))

	pawn.take_damage(pawn.data.defense + pawn.data.max_shield + 15.0)

	assert_array(order).contains_exactly(["shield", "health"])


## 注意：GDScript 匿名函数按值捕获局部基本类型，计数必须用引用类型（Array）收集。
func test_lethal_damage_kills_and_further_damage_is_ignored() -> void:
	var pawn: Pawn = _spawn_player()
	var death_events: Array[String] = []
	pawn.died.connect(func(_p: Pawn) -> void: death_events.append("died"))

	var lethal: float = pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0
	pawn.take_damage(lethal)

	assert_bool(pawn.is_dead()).is_true()
	assert_float(pawn.current_health).is_zero()
	assert_int(death_events.size()).is_equal(1)
	assert_int(pawn.collision_layer).is_zero()

	pawn.take_damage(10.0)
	assert_int(death_events.size()).is_equal(1)
	assert_float(pawn.current_health).is_zero()


## 治疗按上限截断，且不会复活已归零的单位（复活属于非范围）。
func test_heal_clamps_at_max_and_does_not_revive() -> void:
	var pawn: Pawn = _spawn_player()
	pawn.take_damage(pawn.data.defense + pawn.data.max_shield + 30.0)
	var damaged_health: float = pawn.current_health
	assert_float(damaged_health).is_less(pawn.data.max_health)

	pawn.health.heal(1000.0)
	assert_float(pawn.current_health).is_equal_approx(pawn.data.max_health, APPROX)

	var lethal: float = pawn.data.defense + pawn.data.max_health + 100.0
	pawn.take_damage(lethal)
	assert_bool(pawn.is_dead()).is_true()

	pawn.health.heal(50.0)
	assert_float(pawn.current_health).is_zero()
	assert_bool(pawn.is_dead()).is_true()


## 灵力池按 max_spirit 按需创建：玩家有、敌人没有。
func test_spirit_pool_is_created_only_for_units_with_spirit() -> void:
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	assert_object(player.spirit_pool).is_not_null()
	assert_float(player.max_spirit).is_equal_approx(player.data.max_spirit, APPROX)
	assert_float(player.current_spirit).is_equal_approx(player.data.max_spirit, APPROX)

	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	assert_object(enemy.spirit_pool).is_null()
	assert_float(enemy.max_spirit).is_zero()
	assert_object(enemy.get_resource_pool(Pawn.SPIRIT_RESOURCE_ID)).is_null()
	assert_bool(enemy.try_spend_spirit(1.0)).is_false()
	assert_float(enemy.restore_spirit(10.0)).is_zero()


## 灵力原子消耗：余额不足时完全不发生变化。
func test_spirit_spend_is_atomic_and_restore_clamps() -> void:
	var pawn: Pawn = _spawn_player()
	var max_spirit: float = pawn.max_spirit
	assert_float(pawn.current_spirit).is_equal_approx(max_spirit, APPROX)

	assert_bool(pawn.try_spend_spirit(max_spirit + 1.0)).is_false()
	assert_float(pawn.current_spirit).is_equal_approx(max_spirit, APPROX)

	assert_bool(pawn.try_spend_spirit(30.0)).is_true()
	assert_float(pawn.current_spirit).is_equal_approx(max_spirit - 30.0, APPROX)

	assert_float(pawn.restore_spirit(1000.0)).is_equal_approx(30.0, APPROX)
	assert_float(pawn.current_spirit).is_equal_approx(max_spirit, APPROX)
