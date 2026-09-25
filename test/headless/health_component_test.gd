extends SceneTree

## 自建 headless 验证（项目尚未引入 GUT / GdUnit）。
## 验证目标：`HealthComponent` 是生命/护盾的单一数据源，且 Pawn 已验收的对外接口不变。
## 运行方式：
##   godot --headless --path . --script res://test/headless/health_component_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const COMPONENT_PATH: String = "res://game/pawns/health_component.gd"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"

var _failures: Array[String] = []
var _check_count: int = 0

## 记录一次信号发射，用来锁定“参数 + 顺序”这类接口契约。
var _emissions: Array[String] = []

func _initialize() -> void:
	await process_frame
	_test_component_configure_is_silent()
	_test_shield_absorption_and_order()
	_test_depleted_once_and_stops_further_changes()
	_test_heal_and_grant_shield()
	_test_pawn_delegates_to_component()
	_test_pawn_signal_contract()
	_test_pawn_death_contract()
	_test_missing_data_is_dead()
	await _test_hud_still_updates()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("HEALTH_COMPONENT_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)

func _new_component(max_health: float, max_shield: float) -> HealthComponent:
	var component: HealthComponent = load(COMPONENT_PATH).new()
	root.add_child(component)
	component.configure(max_health, max_shield)
	return component

func _spawn_pawn() -> Pawn:
	var scene: PackedScene = load(PLAYER_PAWN_SCENE_PATH)
	var pawn: Pawn = scene.instantiate()
	root.add_child(pawn)
	return pawn

func _track_component(component: HealthComponent) -> void:
	component.health_changed.connect(func(current_value: float, max_value: float) -> void: _emissions.append("health_changed:%d/%d" % [roundi(current_value), roundi(max_value)]))
	component.shield_changed.connect(func(current_value: float, max_value: float) -> void: _emissions.append("shield_changed:%d/%d" % [roundi(current_value), roundi(max_value)]))
	component.health_state_changed.connect(func(_component: HealthComponent) -> void: _emissions.append("health_state_changed"))
	component.depleted.connect(func(_component: HealthComponent) -> void: _emissions.append("depleted"))

func _track_pawn(pawn: Pawn) -> void:
	pawn.health_changed.connect(func(_pawn: Pawn, current_value: float, max_value: float) -> void: _emissions.append("pawn_health_changed:%d/%d" % [roundi(current_value), roundi(max_value)]))
	pawn.shield_changed.connect(func(_pawn: Pawn, current_value: float, max_value: float) -> void: _emissions.append("pawn_shield_changed:%d/%d" % [roundi(current_value), roundi(max_value)]))
	pawn.state_changed.connect(func(_pawn: Pawn, new_state: int) -> void: _emissions.append("pawn_state_changed:%d" % new_state))
	pawn.died.connect(func(_pawn: Pawn) -> void: _emissions.append("pawn_died"))

func _test_component_configure_is_silent() -> void:
	_emissions.clear()
	var component: HealthComponent = load(COMPONENT_PATH).new()
	root.add_child(component)
	_track_component(component)
	component.configure(120.0, 40.0)
	_check(component.get_script().resource_path == COMPONENT_PATH, "组件脚本路径应为 %s" % COMPONENT_PATH)
	_check(is_equal_approx(component.max_health, 120.0), "configure 应写入 max_health，实际 %.1f" % component.max_health)
	_check(is_equal_approx(component.max_shield, 40.0), "configure 应写入 max_shield，实际 %.1f" % component.max_shield)
	_check(is_equal_approx(component.current_health, 120.0), "configure 后生命应等于上限，实际 %.1f" % component.current_health)
	_check(is_equal_approx(component.current_shield, 40.0), "configure 后护盾应等于上限，实际 %.1f" % component.current_shield)
	_check(component.is_alive(), "configure 后组件应处于存活状态")
	var expected: Array[String] = []
	_check(_emissions == expected, "configure 必须静默（出生不能弹血条），实际 %s" % str(_emissions))
	component.queue_free()

func _test_shield_absorption_and_order() -> void:
	_emissions.clear()
	var component: HealthComponent = _new_component(120.0, 40.0)
	_track_component(component)

	component.apply_damage(15.0)
	_check(is_equal_approx(component.current_shield, 25.0), "伤害应先扣护盾，实际护盾 %.1f" % component.current_shield)
	_check(is_equal_approx(component.current_health, 120.0), "护盾未耗尽时不应扣生命，实际生命 %.1f" % component.current_health)
	var absorbed_expected: Array[String] = ["shield_changed:25/40", "health_state_changed"]
	_check(_emissions == absorbed_expected, "护盾吸收时只应发出 shield_changed + health_state_changed（不得发 health_changed），实际 %s" % str(_emissions))

	_emissions.clear()
	component.apply_damage(45.0)
	_check(is_equal_approx(component.current_shield, 0.0), "25 点护盾应被 45 点伤害打破，实际护盾 %.1f" % component.current_shield)
	_check(is_equal_approx(component.current_health, 100.0), "溢出伤害应扣生命，实际生命 %.1f" % component.current_health)
	var broken_expected: Array[String] = ["shield_changed:0/40", "health_changed:100/120", "health_state_changed"]
	_check(_emissions == broken_expected, "护盾破碎时应先护盾后生命，实际 %s" % str(_emissions))
	component.queue_free()

func _test_depleted_once_and_stops_further_changes() -> void:
	_emissions.clear()
	var component: HealthComponent = _new_component(50.0, 10.0)
	_track_component(component)

	component.apply_damage(1000.0)
	_check(is_equal_approx(component.current_health, 0.0), "致命伤害后生命应为 0，实际 %.1f" % component.current_health)
	_check(component.is_depleted(), "生命归零后 is_depleted 应为 true")
	_check(not component.is_alive(), "生命归零后 is_alive 应为 false")
	var expected: Array[String] = ["shield_changed:0/10", "health_changed:0/50", "health_state_changed", "depleted"]
	_check(_emissions == expected, "归零顺序应为 护盾→生命→状态→归零，实际 %s" % str(_emissions))

	_emissions.clear()
	component.apply_damage(10.0)
	component.heal(10.0)
	component.grant_shield(10.0)
	var no_signal_expected: Array[String] = []
	_check(_emissions == no_signal_expected, "归零后受伤/治疗/加盾都不应产生信号（复活为非范围），实际 %s" % str(_emissions))
	component.queue_free()

func _test_heal_and_grant_shield() -> void:
	_emissions.clear()
	var component: HealthComponent = _new_component(100.0, 30.0)
	_track_component(component)
	component.apply_damage(60.0)
	_check(is_equal_approx(component.current_health, 70.0), "60 点伤害应打掉 30 护盾 + 30 生命，实际 %.1f" % component.current_health)

	_emissions.clear()
	component.heal(10.0)
	_check(is_equal_approx(component.current_health, 80.0), "治疗应提升生命，实际 %.1f" % component.current_health)
	var heal_expected: Array[String] = ["health_changed:80/100", "health_state_changed"]
	_check(_emissions == heal_expected, "治疗属于状态变化，应触发血条显示入口，实际 %s" % str(_emissions))

	_emissions.clear()
	component.grant_shield(15.0)
	_check(is_equal_approx(component.current_shield, 15.0), "加盾应提升护盾，实际 %.1f" % component.current_shield)
	var shield_expected: Array[String] = ["shield_changed:15/30", "health_state_changed"]
	_check(_emissions == shield_expected, "护盾生成属于状态变化，应触发血条显示入口，实际 %s" % str(_emissions))

	component.heal(999.0)
	_check(is_equal_approx(component.current_health, 100.0), "治疗应按上限截断，实际 %.1f" % component.current_health)
	component.grant_shield(999.0)
	_check(is_equal_approx(component.current_shield, 30.0), "加盾应按上限截断，实际 %.1f" % component.current_shield)

	_emissions.clear()
	component.heal(10.0)
	component.grant_shield(10.0)
	var full_expected: Array[String] = []
	_check(_emissions == full_expected, "满值治疗/加盾没有实际变化，不应发信号，实际 %s" % str(_emissions))
	component.queue_free()

func _test_pawn_delegates_to_component() -> void:
	var pawn: Pawn = _spawn_pawn()
	var component: HealthComponent = pawn.get_node_or_null("HealthComponent")
	_check(component != null, "Pawn 场景应包含 HealthComponent 子节点")
	_check(pawn.health == component, "Pawn.health 应指向 HealthComponent 子节点")
	_check(pawn.get_controller() is PlayerController, "继承场景的 Controller 覆写仍应生效（PlayerController）")
	if component != null:
		_check(is_equal_approx(component.max_health, pawn.data.max_health), "组件生命上限应来自 PawnData")
		_check(is_equal_approx(component.max_shield, pawn.data.max_shield), "组件护盾上限应来自 PawnData")
		_check(is_equal_approx(pawn.current_health, component.current_health), "Pawn.current_health 应是组件的只读代理")
		_check(is_equal_approx(pawn.current_shield, component.current_shield), "Pawn.current_shield 应是组件的只读代理")
	_check(is_equal_approx(pawn.current_health, pawn.data.max_health), "实例化后生命应等于上限")
	_check(is_equal_approx(pawn.current_shield, pawn.data.max_shield), "实例化后护盾应等于上限")
	_check(pawn.status_bars.visible == false, "实例化完成后血条仍应初始隐藏")
	pawn.queue_free()

func _test_pawn_signal_contract() -> void:
	_emissions.clear()
	var pawn: Pawn = _spawn_pawn()
	_track_pawn(pawn)
	var defense: float = pawn.data.defense
	var shield_after: float = pawn.data.max_shield - 5.0

	pawn.take_damage(defense + 5.0)
	_check(is_equal_approx(pawn.current_shield, shield_after), "Pawn.take_damage 应先扣 defense 再交给组件，实际护盾 %.1f" % pawn.current_shield)
	_check(is_equal_approx(pawn.current_health, pawn.data.max_health), "护盾吸收时生命不应变化")
	var absorbed_expected: Array[String] = ["pawn_shield_changed:%d/%d" % [roundi(shield_after), roundi(pawn.data.max_shield)]]
	_check(_emissions == absorbed_expected, "护盾吸收时 Pawn 只应转发 shield_changed，实际 %s" % str(_emissions))
	_check(pawn.status_bars.visible, "生命状态变化后血条应显示（沿用 INC-UI-002 行为）")

	_emissions.clear()
	var overflow_damage: float = 100.0
	var absorbed: float = minf(shield_after, overflow_damage)
	var health_after: float = pawn.data.max_health - (overflow_damage - absorbed)
	pawn.take_damage(defense + overflow_damage)
	var broken_expected: Array[String] = [
		"pawn_shield_changed:%d/%d" % [roundi(0.0), roundi(pawn.data.max_shield)],
		"pawn_health_changed:%d/%d" % [roundi(health_after), roundi(pawn.data.max_health)],
	]
	_check(_emissions == broken_expected, "护盾破碎时 Pawn 应保持“先护盾、后生命”的转发顺序，实际 %s" % str(_emissions))
	_check(is_equal_approx(pawn.current_health, health_after), "Pawn.current_health 应与组件一致，实际 %.1f" % pawn.current_health)
	pawn.queue_free()

func _test_pawn_death_contract() -> void:
	_emissions.clear()
	var pawn: Pawn = _spawn_pawn()
	_track_pawn(pawn)
	var lethal: float = pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0

	pawn.take_damage(lethal)
	_check(pawn.is_dead(), "致命伤害后 Pawn 应进入死亡状态")
	_check(pawn.health.is_depleted(), "致命伤害后组件应标记为归零")
	_check(is_equal_approx(pawn.current_health, 0.0), "死亡后生命应为 0，实际 %.1f" % pawn.current_health)
	_check(pawn.status_bars.visible, "死亡时血条应显示（沿用 INC-UI-002 行为）")
	_check(_emissions.count("pawn_died") == 1, "died 信号应只发一次，实际 %s" % str(_emissions))
	_check(pawn.collision_layer == 0, "死亡后应清除碰撞层")

	_emissions.clear()
	pawn.take_damage(10.0)
	var no_signal_expected: Array[String] = []
	_check(_emissions == no_signal_expected, "死亡后再受伤不应产生信号，实际 %s" % str(_emissions))
	pawn.queue_free()

## 配置错误路径：没有 PawnData 的 Pawn 必须视为生命为 0（与重构前行为一致）。
## 注意：本用例会刻意触发一次 `Pawn._ready()` 里的 push_error，日志中的 ERROR 行是预期行为。
func _test_missing_data_is_dead() -> void:
	var pawn: Pawn = (load("res://game/pawns/pawn.tscn") as PackedScene).instantiate()
	root.add_child(pawn)
	_check(pawn.data == null, "基础 pawn.tscn 不应自带 PawnData")
	_check(pawn.is_dead(), "缺少 PawnData 的 Pawn 应视为已死亡（保持旧行为）")
	_check(is_equal_approx(pawn.current_health, 0.0), "缺少 PawnData 时生命应为 0，实际 %.1f" % pawn.current_health)
	_check(pawn.health.is_depleted(), "缺少 PawnData 时组件应标记为归零")
	pawn.queue_free()

## 集成回归：main.tscn 的 HUD 走的仍是 Pawn 转发信号，重构后必须照常刷新。
func _test_hud_still_updates() -> void:
	var main: Node2D = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(main)
	main.get_node("Pawns/EnemyPawn").global_position = Vector2(-2000.0, -2000.0)
	await process_frame

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var selected_label: Label = main.get_node("HUD/HudMargin/HudPanel/HudContent/SelectedLabel")
	main.call("_set_selected_pawn", player)
	await process_frame
	var before: String = selected_label.text

	player.take_damage(player.data.defense + 10.0)
	await process_frame
	var after: String = selected_label.text
	_check(after != before, "HUD 应通过 Pawn 转发信号刷新，选中信息未变化：%s" % after)
	var expected_shield: float = player.data.max_shield - 10.0
	var expected_text: String = "护盾：%.0f / %.0f" % [expected_shield, player.data.max_shield]
	_check(after.contains(expected_text), "HUD 护盾数值应同步为 %s，实际 %s" % [expected_text, after])
	main.queue_free()