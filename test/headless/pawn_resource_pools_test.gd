extends SceneTree

## 自建 headless 验证（项目尚未引入 GUT / GdUnit）。
## 验证目标（INC-PAWNS-004）：生命与护盾的运行时数值已迁移到 ResourcePoolComponent，
## 且 Pawn 已验收的对外数值、护盾优先规则与血条/HUD 行为没有回归。
## 运行方式：
##   godot --headless --path . --script res://test/headless/pawn_resource_pools_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"

var _failures: Array[String] = []
var _check_count: int = 0

## 记录资源池的真实变化顺序，用来锁定“先护盾、后生命”的资源路由契约。
var _pool_events: Array[String] = []

func _initialize() -> void:
	await process_frame
	_test_resource_pool_structure()
	_test_single_data_source()
	_test_shield_then_health_routing()
	_test_depleted_semantics()
	_test_enemy_pawn_inheritance()
	await _test_hud_and_health_bar_still_work()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("PAWN_RESOURCE_POOLS_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)

func _spawn_pawn(scene_path: String) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate()
	root.add_child(pawn)
	return pawn

func _health_id() -> StringName:
	return HealthComponent.HEALTH_RESOURCE_ID

func _shield_id() -> StringName:
	return HealthComponent.SHIELD_RESOURCE_ID

## 结构契约：Pawn 场景新增 Resources 资源集合，只注册 Health / Shield 两个池。
func _test_resource_pool_structure() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var resources: ResourceSetComponent = pawn.get_node_or_null("Resources") as ResourceSetComponent
	_check(resources != null, "Pawn 场景应包含 Resources 资源集合节点")
	_check(pawn.resources == resources, "Pawn.resources 应指向 Resources 节点")
	var expected_ids: Array[StringName] = [&"health", &"shield"]
	if pawn.data.max_spirit > 0.0:
		expected_ids.append(&"spirit")
	if resources != null:
		_check(resources.pool_count == expected_ids.size(), "Resources 应注册 %d 个资源池，实际 %d" % [expected_ids.size(), resources.pool_count])

	var health_pool: ResourcePoolComponent = pawn.get_node_or_null("Resources/Health") as ResourcePoolComponent
	var shield_pool: ResourcePoolComponent = pawn.get_node_or_null("Resources/Shield") as ResourcePoolComponent
	_check(health_pool != null, "应存在 Resources/Health 资源池节点")
	_check(shield_pool != null, "应存在 Resources/Shield 资源池节点")
	_check(pawn.health_pool == health_pool, "Pawn.health_pool 应指向 Resources/Health")
	_check(pawn.shield_pool == shield_pool, "Pawn.shield_pool 应指向 Resources/Shield")
	_check(pawn.get_resource_pool(_health_id()) == health_pool, "应按 health 资源 ID 命中生命池")
	_check(pawn.get_resource_pool(_shield_id()) == shield_pool, "应按 shield 资源 ID 命中护盾池")
	_check((pawn.get_resource_pool(&"spirit") != null) == (pawn.data.max_spirit > 0.0), "灵力池必须只在 max_spirit > 0 时存在（INC-COMBAT-002 起）")
	_check(pawn.get_resource_ids() == expected_ids, "资源 ID 应为 health/shield（配置灵力时追加 spirit），实际 %s" % str(pawn.get_resource_ids()))

	if health_pool != null:
		_check(health_pool.get_resource_id() == &"health", "生命池的 resource_definition.resource_id 应为 health")
		_check(is_equal_approx(health_pool.max_value, pawn.data.max_health), "生命池上限应来自 PawnData，实际 %.1f" % health_pool.max_value)
		_check(is_equal_approx(health_pool.current_value, pawn.data.max_health), "出生时生命池应为满值，实际 %.1f" % health_pool.current_value)
	if shield_pool != null:
		_check(shield_pool.get_resource_id() == &"shield", "护盾池的 resource_definition.resource_id 应为 shield")
		_check(is_equal_approx(shield_pool.max_value, pawn.data.max_shield), "护盾池上限应来自 PawnData，实际 %.1f" % shield_pool.max_value)
		_check(is_equal_approx(shield_pool.current_value, pawn.data.max_shield), "出生时护盾池应为满值")
	pawn.queue_free()

## 单一数据源：直接改资源池，Pawn 与门面必须立刻反映同一份数值。
func _test_single_data_source() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var health_pool: ResourcePoolComponent = pawn.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID)
	var shield_pool: ResourcePoolComponent = pawn.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID)
	_check(health_pool != null, "缺少生命池，无法验证单一数据源")
	_check(shield_pool != null, "缺少护盾池，无法验证单一数据源")
	if health_pool == null or shield_pool == null:
		pawn.queue_free()
		return

	_check(pawn.health.is_using_external_pools(), "Pawn.health 应绑定场景资源池，而不是自建内部池")
	_check(pawn.health.get_health_pool() == health_pool, "门面的生命源必须是同一个资源池实例")
	_check(pawn.health.get_shield_pool() == shield_pool, "门面的护盾源必须是同一个资源池实例")

	var target_value: float = pawn.data.max_health - 30.0
	health_pool.set_value(target_value)
	_check(is_equal_approx(pawn.current_health, target_value), "Pawn.current_health 必须直接读资源池，实际 %.1f" % pawn.current_health)
	_check(is_equal_approx(pawn.health.current_health, target_value), "门面 current_health 必须直接读资源池，实际 %.1f" % pawn.health.current_health)
	_check(is_equal_approx(pawn.health.current_shield, pawn.data.max_shield), "未改动的护盾池应保持满值")
	pawn.queue_free()

## 战斗路由：伤害必须真实落在两个资源池上，顺序仍是先护盾、后生命。
func _test_shield_then_health_routing() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var health_pool: ResourcePoolComponent = pawn.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID)
	var shield_pool: ResourcePoolComponent = pawn.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID)
	if health_pool == null or shield_pool == null:
		_check(false, "缺少资源池，无法验证伤害路由")
		pawn.queue_free()
		return

	_pool_events.clear()
	health_pool.value_changed.connect(_on_health_pool_changed)
	shield_pool.value_changed.connect(_on_shield_pool_changed)

	var raw_attack: float = pawn.data.defense + pawn.data.max_shield + 25.0
	var incoming: float = maxf(1.0, raw_attack - pawn.data.defense)
	var absorbed: float = minf(pawn.data.max_shield, incoming)
	var expected_health: float = pawn.data.max_health - (incoming - absorbed)
	pawn.take_damage(raw_attack)

	var expected_events: Array[String] = [
		"shield:%d" % roundi(pawn.data.max_shield - absorbed),
		"health:%d" % roundi(expected_health),
	]
	_check(_pool_events == expected_events, "资源池变化顺序必须先护盾后生命，实际 %s" % str(_pool_events))
	_check(is_equal_approx(shield_pool.current_value, pawn.data.max_shield - absorbed), "护盾池应扣除吸伤部分，实际 %.1f" % shield_pool.current_value)
	_check(is_equal_approx(health_pool.current_value, expected_health), "生命池应扣除溢出伤害，实际 %.1f" % health_pool.current_value)
	_check(is_equal_approx(pawn.current_health, health_pool.current_value), "Pawn.current_health 应与生命池一致")
	pawn.queue_free()

func _on_health_pool_changed(current_value: float, _max_value: float, _delta: float, _source: StringName) -> void:
	_pool_events.append("health:%d" % roundi(current_value))

func _on_shield_pool_changed(current_value: float, _max_value: float, _delta: float, _source: StringName) -> void:
	_pool_events.append("shield:%d" % roundi(current_value))

## 归零语义：护盾池归零不致死；生命池归零才通过门面让 Pawn 死亡。
func _test_depleted_semantics() -> void:
	var shield_only_pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var shield_pool: ResourcePoolComponent = shield_only_pawn.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID)
	shield_only_pawn.take_damage(shield_only_pawn.data.defense + shield_only_pawn.data.max_shield)
	if shield_pool != null:
		_check(is_equal_approx(shield_pool.current_value, 0.0), "本次伤害应打空护盾，实际 %.1f" % shield_pool.current_value)
		_check(shield_pool.is_depleted(), "护盾池归零应触发资源池的 depleted 边沿")
	_check(shield_only_pawn.is_alive(), "护盾归零不得让 Pawn 死亡")
	_check(not shield_only_pawn.health.is_depleted(), "护盾归零时生命门面不应进入归零状态")
	_check(is_equal_approx(shield_only_pawn.current_health, shield_only_pawn.data.max_health), "护盾吸收全部伤害时生命不应变化")
	shield_only_pawn.queue_free()

	var lethal_pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var health_pool: ResourcePoolComponent = lethal_pawn.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID)
	lethal_pawn.take_damage(lethal_pawn.data.defense + lethal_pawn.data.max_health + lethal_pawn.data.max_shield + 50.0)
	if health_pool != null:
		_check(is_equal_approx(health_pool.current_value, 0.0), "致命伤害后生命池应为 0，实际 %.1f" % health_pool.current_value)
		_check(health_pool.is_depleted(), "致命伤害后生命池应标记 depleted")
	_check(lethal_pawn.health.is_depleted(), "致命伤害后兼容门面应同步归零状态")
	_check(lethal_pawn.is_dead(), "生命池归零应通过门面让 Pawn 进入死亡状态")
	_check(is_equal_approx(lethal_pawn.current_health, 0.0), "死亡后 Pawn.current_health 应为 0")
	lethal_pawn.queue_free()

## 场景继承：敌人 Pawn 必须同时继承资源池与 Controller 覆写。
func _test_enemy_pawn_inheritance() -> void:
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	_check(enemy.get_controller() is AIController, "敌人继承场景的 Controller 覆写仍应生效（AIController）")
	var health_pool: ResourcePoolComponent = enemy.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID)
	_check(health_pool != null, "敌人应继承 Resources/Health 资源池")
	_check(enemy.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID) != null, "敌人应继承 Resources/Shield 资源池")
	if health_pool != null:
		_check(is_equal_approx(health_pool.max_value, enemy.data.max_health), "敌人生命池上限应来自自身 PawnData，实际 %.1f" % health_pool.max_value)
	_check(is_equal_approx(enemy.current_health, enemy.data.max_health), "敌人出生时生命应为满值")
	enemy.queue_free()

## 集成回归：HUD 与头顶血条走的仍是 Pawn 转发信号，迁移后必须照常刷新。
func _test_hud_and_health_bar_still_work() -> void:
	var main: Node2D = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(main)
	main.get_node("Pawns/EnemyPawn").global_position = Vector2(-2000.0, -2000.0)
	await process_frame

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var selected_label: Label = main.get_node("HUD/HudMargin/HudPanel/HudContent/SelectedLabel")
	_check(player.status_bars.visible == false, "实例化后血条仍应初始隐藏")
	main.call("_set_selected_pawn", player)
	await process_frame

	player.take_damage(player.data.defense + 10.0)
	await process_frame
	var expected_shield: float = player.data.max_shield - 10.0
	var expected_text: String = "护盾：%.0f / %.0f" % [expected_shield, player.data.max_shield]
	_check(selected_label.text.contains(expected_text), "HUD 护盾数值应来自资源池，实际 %s" % selected_label.text)
	_check(player.status_bars.visible, "伤害后头顶血条应在同一帧显示（沿用 INC-UI-002 行为）")
	var shield_pool: ResourcePoolComponent = player.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID)
	if shield_pool != null:
		_check(is_equal_approx(shield_pool.current_value, expected_shield), "护盾池数值应与 HUD 显示一致")
	var health_pool: ResourcePoolComponent = player.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID)
	if health_pool != null:
		_check(is_equal_approx(health_pool.current_value, player.data.max_health), "护盾吸收时生命池不应变化")
	main.queue_free()
