extends SceneTree

## 自建 headless 验证（INC-PAWNS-006）。
## 验证目标：Resources/Health 与 Resources/Shield 是真实事件源，必须直接驱动
## Pawn 的生命信号、状态条显示与死亡流程，不能依赖 HealthComponent 兼容门面的转发。
## 运行方式：
##   godot --headless --path . --script res://test/headless/health_pool_authority_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"

var _failures: Array[String] = []
var _check_count: int = 0
var _health_events: Array[String] = []
var _shield_events: Array[String] = []
var _died_count: int = 0

func _initialize() -> void:
	await process_frame
	_test_direct_health_pool_change_updates_signal_and_bars()
	_test_direct_shield_pool_change_does_not_kill()
	_test_direct_health_depletion_triggers_one_death()
	_test_take_damage_uses_one_direct_forwarding_path()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("HEALTH_POOL_AUTHORITY_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)

func _spawn_player() -> Pawn:
	var scene: PackedScene = load(PLAYER_PAWN_SCENE_PATH)
	var pawn: Pawn = scene.instantiate()
	root.add_child(pawn)
	_health_events.clear()
	_shield_events.clear()
	_died_count = 0
	pawn.health_changed.connect(_on_pawn_health_changed)
	pawn.shield_changed.connect(_on_pawn_shield_changed)
	pawn.died.connect(_on_pawn_died)
	pawn.status_bars.hide_now()
	return pawn

func _on_pawn_health_changed(_pawn: Pawn, current_value: float, max_value: float) -> void:
	_health_events.append("%d/%d" % [roundi(current_value), roundi(max_value)])

func _on_pawn_shield_changed(_pawn: Pawn, current_value: float, max_value: float) -> void:
	_shield_events.append("%d/%d" % [roundi(current_value), roundi(max_value)])

func _on_pawn_died(_pawn: Pawn) -> void:
	_died_count += 1

func _test_direct_health_pool_change_updates_signal_and_bars() -> void:
	var pawn: Pawn = _spawn_player()
	var target_health: float = pawn.data.max_health - 12.0

	pawn.health_pool.set_value(target_health, &"test_direct_health")

	_check(is_equal_approx(pawn.current_health, target_health), "直接改生命池后 Pawn.current_health 应读到同一数值")
	_check(_health_events == ["%d/%d" % [roundi(target_health), roundi(pawn.data.max_health)]], "直接改生命池应只转发一次 health_changed，实际 %s" % str(_health_events))
	_check(pawn.status_bars.visible, "直接改生命池后状态条应立即显示")
	_check(not pawn.is_dead(), "生命未归零时直接改池不应进入死亡状态")
	_check(_died_count == 0, "生命未归零时不得发出 died，实际 %d" % _died_count)
	pawn.queue_free()

func _test_direct_shield_pool_change_does_not_kill() -> void:
	var pawn: Pawn = _spawn_player()
	var target_shield: float = maxf(pawn.data.max_shield - 7.0, 0.0)

	pawn.shield_pool.set_value(target_shield, &"test_direct_shield")

	_check(is_equal_approx(pawn.current_shield, target_shield), "直接改护盾池后只读护盾值应同步")
	_check(_shield_events == ["%d/%d" % [roundi(target_shield), roundi(pawn.data.max_shield)]], "直接改护盾池应只转发一次 shield_changed，实际 %s" % str(_shield_events))
	_check(_health_events.is_empty(), "直接改护盾池不得冒充生命变化，实际 %s" % str(_health_events))
	_check(pawn.status_bars.visible, "护盾变化也应显示资源条")
	_check(not pawn.is_dead(), "护盾归零或减少不得杀死 Pawn")
	_check(_died_count == 0, "护盾变化不得发出 died，实际 %d" % _died_count)

	pawn.shield_pool.set_value(0.0, &"test_shield_zero")
	_check(is_equal_approx(pawn.current_shield, 0.0), "护盾应可直接归零")
	_check(not pawn.is_dead(), "护盾归零后 Pawn 仍应存活")
	_check(_died_count == 0, "护盾归零不得触发死亡，实际 %d" % _died_count)
	pawn.queue_free()

func _test_direct_health_depletion_triggers_one_death() -> void:
	var pawn: Pawn = _spawn_player()

	pawn.health_pool.set_value(0.0, &"test_direct_lethal")

	_check(is_equal_approx(pawn.current_health, 0.0), "直接清空生命池后生命应为 0")
	_check(pawn.is_dead(), "直接清空生命池必须让 Pawn 进入死亡语义")
	_check(pawn.state == Pawn.State.DEAD, "直接清空生命池后状态应为 DEAD")
	_check(pawn.collision_layer == 0, "死亡后应清除碰撞层")
	_check(pawn.status_bars.visible, "死亡后状态条仍应显示")
	_check(_health_events == ["0/%d" % roundi(pawn.data.max_health)], "直接致死应只转发一次 health_changed，实际 %s" % str(_health_events))
	_check(_died_count == 1, "直接致死必须恰好发出一次 died，实际 %d" % _died_count)

	pawn.health_pool.set_value(0.0, &"test_repeat_zero")
	_check(_died_count == 1, "重复写入 0 不得重复死亡，实际 %d" % _died_count)

	pawn.health_pool.increase(20.0, &"test_post_death_restore")
	_check(is_equal_approx(pawn.current_health, 20.0), "死亡后直接改池应保持单一数据源读数")
	_check(pawn.is_dead(), "直接增加生命不得复活已死亡 Pawn")
	_check(_died_count == 1, "死亡后恢复生命不得重复或撤销死亡记录，实际 %d" % _died_count)
	pawn.queue_free()

func _test_take_damage_uses_one_direct_forwarding_path() -> void:
	var pawn: Pawn = _spawn_player()
	var defense: float = pawn.data.defense
	var shield_damage: float = 5.0

	pawn.take_damage(defense + shield_damage)

	_check(is_equal_approx(pawn.current_shield, pawn.data.max_shield - shield_damage), "take_damage 仍应先扣护盾")
	_check(is_equal_approx(pawn.current_health, pawn.data.max_health), "护盾吸收时不得扣生命")
	_check(_shield_events.size() == 1, "take_damage 的护盾变化不得被门面和池重复转发，实际 %s" % str(_shield_events))
	_check(_health_events.is_empty(), "仅扣护盾不得发出 health_changed，实际 %s" % str(_health_events))

	_shield_events.clear()
	_health_events.clear()
	var lethal: float = defense + pawn.data.max_shield + pawn.data.max_health + 10.0
	pawn.take_damage(lethal)

	_check(_shield_events.size() == 1, "致命伤害应恰好转发一次护盾归零，实际 %s" % str(_shield_events))
	_check(_health_events.size() == 1, "致命伤害应恰好转发一次生命归零，实际 %s" % str(_health_events))
	_check(_died_count == 1, "致命伤害只应死亡一次，实际 %d" % _died_count)
	_check(pawn.is_dead(), "致命伤害后 Pawn 应死亡")
	pawn.queue_free()