extends SceneTree

## 自建 headless 验证（项目尚未引入 GUT / GdUnit）。
## 验证目标（INC-COMBAT-002）：灵力（技能蓝条）作为第二个生产级资源，复用 ResourcePoolComponent，
## 并满足“不能透支、可恢复、归零不致死”的语义；同时验证灵力量可以驱动通用 ResourceBar。
## 运行方式：
##   godot --headless --path . --script res://test/headless/spirit_pool_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const STATUS_BARS_SCENE_PATH: String = "res://game/ui/pawn_status_bars.tscn"

var _failures: Array[String] = []
var _check_count: int = 0
var _spirit_events: Array[String] = []
var _other_events: Array[String] = []

func _initialize() -> void:
	await process_frame
	_test_default_pawn_has_no_spirit()
	_test_spirit_pool_is_created_for_positive_max()
	_test_atomic_spend_and_restore()
	_test_zero_spirit_does_not_kill()
	_test_spirit_drives_status_bars()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("SPIRIT_POOL_TEST_OK")
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

func _spawn_status_bars() -> PawnStatusBars:
	var bars: PawnStatusBars = (load(STATUS_BARS_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(bars)
	return bars

## 默认无灵力：max_spirit = 0 的单位不创建灵力池，也不能被消耗或恢复。
func _test_default_pawn_has_no_spirit() -> void:
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	_check(is_equal_approx(enemy.data.max_spirit, 0.0), "敌人 PawnData 默认 max_spirit 应为 0")
	_check(enemy.get_resource_pool(&"spirit") == null, "max_spirit = 0 时不应注册灵力资源池")
	_check(enemy.spirit_pool == null, "max_spirit = 0 时 Pawn.spirit_pool 应为 null")
	_check(is_equal_approx(enemy.max_spirit, 0.0), "没有灵力池时 max_spirit 应为 0")
	_check(is_equal_approx(enemy.current_spirit, 0.0), "没有灵力池时 current_spirit 应为 0")
	_check(enemy.try_spend_spirit(1.0) == false, "没有灵力池时 try_spend_spirit 必须返回 false")
	_check(is_equal_approx(enemy.restore_spirit(10.0), 0.0), "没有灵力池时 restore_spirit 应返回 0")
	var expected_ids: Array[StringName] = [&"health", &"shield"]
	_check(enemy.get_resource_ids() == expected_ids, "无灵力单位的资源 ID 仍应只有 health/shield，实际 %s" % str(enemy.get_resource_ids()))
	enemy.queue_free()

## 正灵力上限：创建 Spirit 资源池，上限与初始值来自 PawnData。
func _test_spirit_pool_is_created_for_positive_max() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	_check(pawn.data.max_spirit > 0.0, "玩家 PawnData 应配置正灵力上限")
	var pool: ResourcePoolComponent = pawn.get_resource_pool(&"spirit")
	_check(pool != null, "max_spirit > 0 时应创建并注册 Spirit 资源池")
	_check(pawn.spirit_pool == pool, "Pawn.spirit_pool 应指向注册的灵力池")
	_check(pool != null and pool.get_parent() == pawn.resources, "灵力池应挂在 Resources 资源集合下")
	_check(pool != null and pool.get_resource_id() == &"spirit", "灵力池的 resource_id 应为 spirit")
	_check(is_equal_approx(pawn.max_spirit, pawn.data.max_spirit), "max_spirit 应来自 PawnData，实际 %.1f" % pawn.max_spirit)
	_check(is_equal_approx(pawn.current_spirit, pawn.data.max_spirit), "初始灵力应按 initial_spirit_ratio 补满，实际 %.1f" % pawn.current_spirit)
	var expected_ids: Array[StringName] = [&"health", &"shield", &"spirit"]
	_check(pawn.get_resource_ids() == expected_ids, "有灵力单位的资源 ID 应为 health/shield/spirit，实际 %s" % str(pawn.get_resource_ids()))
	pawn.queue_free()

## 原子消耗与恢复：余额不足不得改变数值，恢复按上限截断。
func _test_atomic_spend_and_restore() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	if pawn.spirit_pool == null:
		_check(false, "缺少灵力池，无法验证消耗与恢复")
		pawn.queue_free()
		return

	_spirit_events.clear()
	_other_events.clear()
	pawn.spirit_changed.connect(func(_pawn: Pawn, current_value: float, max_value: float) -> void: _spirit_events.append("%d/%d" % [roundi(current_value), roundi(max_value)]))
	pawn.health_changed.connect(func(_pawn: Pawn, _current: float, _max: float) -> void: _other_events.append("health"))
	pawn.shield_changed.connect(func(_pawn: Pawn, _current: float, _max: float) -> void: _other_events.append("shield"))

	_check(pawn.try_spend_spirit(30.0), "满灵力时应能扣除 30 点")
	_check(is_equal_approx(pawn.current_spirit, 70.0), "扣除 30 后灵力应为 70，实际 %.1f" % pawn.current_spirit)
	var expected_spirit_events: Array[String] = ["70/100"]
	_check(_spirit_events == expected_spirit_events, "灵力变化应发出一次 spirit_changed(70,100)，实际 %s" % str(_spirit_events))

	_check(pawn.try_spend_spirit(70.0), "剩余灵力应能一次扣完")
	_check(is_equal_approx(pawn.current_spirit, 0.0), "连续消耗后灵力应为 0，实际 %.1f" % pawn.current_spirit)
	_check(pawn.spirit_pool.is_depleted(), "灵力归零应触发资源池 depleted 边沿")

	var events_before_denied: int = _spirit_events.size()
	_check(pawn.try_spend_spirit(1.0) == false, "灵力不足时必须返回 false")
	_check(is_equal_approx(pawn.current_spirit, 0.0), "余额不足时数值必须完全不变")
	_check(_spirit_events.size() == events_before_denied, "余额不足不得发出 spirit_changed，实际 %s" % str(_spirit_events))
	_check(pawn.try_spend_spirit(0.0) == false, "消耗 0 应返回 false（无意义消耗）")
	_check(pawn.try_spend_spirit(-5.0) == false, "负数消耗应返回 false")
	_check(is_equal_approx(pawn.current_spirit, 0.0), "非法消耗不得改变灵力")

	_check(is_equal_approx(pawn.restore_spirit(150.0), 100.0), "超量恢复应只补到上限，实际 %.1f" % pawn.current_spirit)
	_check(is_equal_approx(pawn.current_spirit, pawn.max_spirit), "超量恢复后灵力应等于上限")
	_check(is_equal_approx(pawn.restore_spirit(10.0), 0.0), "满灵力时恢复应为空操作")
	_check(pawn.try_spend_spirit(40.0), "恢复后应能再次消耗")
	_check(is_equal_approx(pawn.current_spirit, 60.0), "再次消耗 40 后应为 60，实际 %.1f" % pawn.current_spirit)
	_check(_other_events.is_empty(), "灵力增减不得触发 health_changed / shield_changed，实际 %s" % str(_other_events))
	pawn.queue_free()

## 灵力是非死亡资源：归零只产生资源池 depleted，不得让 Pawn 死亡；
## 但灵力条属于资源条组，灵力变化应触发展示，不得被误解为死亡或生命变化。
func _test_zero_spirit_does_not_kill() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	if pawn.spirit_pool == null:
		_check(false, "缺少灵力池，无法验证归零语义")
		pawn.queue_free()
		return

	var died_count: Array = [0]
	pawn.died.connect(func(_pawn: Pawn) -> void: died_count[0] += 1)
	var health_before: float = pawn.current_health
	var shield_before: float = pawn.current_shield
	pawn.status_bars.hide_now()

	_check(pawn.try_spend_spirit(pawn.max_spirit), "应能一次消耗全部灵力")
	_check(is_equal_approx(pawn.current_spirit, 0.0), "灵力应归零")
	_check(pawn.spirit_pool.is_depleted(), "灵力池应标记 depleted")
	_check(pawn.is_alive(), "灵力归零不得让 Pawn 死亡")
	_check(died_count[0] == 0, "灵力归零不得发出 died 信号")
	_check(not pawn.health.is_depleted(), "灵力归零不得影响生命门面的归零状态")
	_check(is_equal_approx(pawn.current_health, health_before), "灵力归零不得改变生命")
	_check(is_equal_approx(pawn.current_shield, shield_before), "灵力归零不得改变护盾")
	_check(pawn.status_bars.visible, "灵力变化应触发通用资源条组显示")
	_check(is_equal_approx(pawn.status_bars.spirit_bar.get_target_value(), 0.0), "灵力条目标值应映射归零后的灵力池")
	pawn.queue_free()

## UI 绑定：灵力池可直接驱动通用 ResourceBar / PawnStatusBars（延迟追赶只影响显示值）。
func _test_spirit_drives_status_bars() -> void:
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	if pawn.spirit_pool == null:
		_check(false, "缺少灵力池，无法验证资源条绑定")
		pawn.queue_free()
		return

	var bars: PawnStatusBars = _spawn_status_bars()
	_check(bars.bind_pool(&"health", pawn.get_resource_pool(&"health")), "通用资源条应能绑定生命池")
	_check(bars.bind_pool(&"shield", pawn.get_resource_pool(&"shield")), "通用资源条应能绑定护盾池")
	_check(bars.bind_pool(&"spirit", pawn.spirit_pool), "通用资源条应能绑定灵力池")
	_check(bars.spirit_bar.has_valid_pool(), "绑定灵力池后 SpiritBar 应处于可用状态")
	_check(bars.spirit_bar.visible, "有灵力上限时灵力条应参与布局显示")
	_check(bars.shield_bar.visible, "有护盾上限时护盾条应参与布局显示")
	_check(is_equal_approx(bars.spirit_bar.get_target_value(), pawn.max_spirit), "灵力条目标值应对齐灵力池")

	bars.reveal()
	_check(bars.visible, "任一资源变化后整组资源条应显示")
	_check(is_equal_approx(bars.get_remaining_hide_time(), bars.auto_hide_delay), "组级隐藏计时应重置为 auto_hide_delay")

	pawn.try_spend_spirit(40.0)
	_check(bars.visible, "灵力变化应显示整组资源条")
	_check(is_equal_approx(bars.spirit_bar.get_target_value(), 60.0), "灵力条目标值应立刻变为 60，实际 %.1f" % bars.spirit_bar.get_target_value())
	_check(bars.spirit_bar.is_draining(), "灵力减少应触发显示值延迟追赶")
	_check(is_equal_approx(bars.spirit_bar.get_displayed_value(), 100.0), "延迟追赶开始前显示值应仍是 100")
	bars.spirit_bar.tick(bars.spirit_bar.delayed_drain_delay + bars.spirit_bar.delayed_drain_duration + 0.1)
	_check(is_equal_approx(bars.spirit_bar.get_displayed_value(), 60.0), "追赶结束后显示值应对齐真实灵力")
	_check(is_equal_approx(pawn.current_spirit, 60.0), "显示层追赶不得回写灵力池真实数值")
	bars.queue_free()

	# 没有灵力池的单位：灵力条必须隐藏，其余资源条照常工作。
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	var enemy_bars: PawnStatusBars = _spawn_status_bars()
	_check(enemy_bars.bind_pool(&"health", enemy.get_resource_pool(&"health")), "敌人应能绑定生命池")
	_check(enemy_bars.bind_pool(&"shield", enemy.get_resource_pool(&"shield")), "敌人应能绑定护盾池")
	_check(enemy_bars.spirit_bar.visible == false, "没有灵力上限时灵力条必须隐藏")
	_check(enemy_bars.has_valid_bars(), "没有灵力上限不应影响其它资源条可用")
	enemy_bars.reveal()
	_check(enemy_bars.visible, "没有灵力条时其余资源条仍应能整组显示")

	pawn.queue_free()
	enemy.queue_free()
	enemy_bars.queue_free()
