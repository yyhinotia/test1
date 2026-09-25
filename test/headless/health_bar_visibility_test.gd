extends SceneTree

## 自建 headless 验证（项目尚未引入 GUT / GdUnit，因此使用最小自建脚本）。
## 验证目标：血条“生命状态变化时显示、最后一次变化后 2 秒隐藏”。
## 运行方式：
##   godot --headless --path . --script res://test/headless/health_bar_visibility_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const BAR_SCENE_PATH: String = "res://game/ui/pawn_health_bar.tscn"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const EXPECTED_DELAY: float = 2.0

var _failures: Array[String] = []
var _check_count: int = 0

func _initialize() -> void:
	# 等一帧，确保节点进入场景树后 _ready / @onready 已完成初始化。
	await process_frame
	_test_bar_scene_contract()
	_test_visibility_cycle()
	_test_countdown_reset_on_repeated_change()
	_test_shield_change_reveals_bar()
	_test_pawn_structure_and_anchor()
	_test_pawn_damage_and_death_reveal()
	await _test_runtime_visibility_timing()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _spawn_bar() -> PawnHealthBar:
	var scene: PackedScene = load(BAR_SCENE_PATH)
	var bar: PawnHealthBar = scene.instantiate()
	root.add_child(bar)
	return bar

func _spawn_pawn() -> Pawn:
	var scene: PackedScene = load(PLAYER_PAWN_SCENE_PATH)
	var pawn: Pawn = scene.instantiate()
	root.add_child(pawn)
	return pawn

func _test_bar_scene_contract() -> void:
	var bar: PawnHealthBar = _spawn_bar()
	_check(bar.get_script().resource_path == "res://game/ui/pawn_health_bar.gd", "血条场景根节点应挂载 pawn_health_bar.gd")
	_check(bar.visible == false, "血条初始状态必须隐藏，而不是常驻显示")
	_check(is_equal_approx(bar.auto_hide_delay, EXPECTED_DELAY), "默认隐藏延迟应为 2.0 秒，实际 %.2f" % bar.auto_hide_delay)
	_check(bar.size == Vector2(72.0, 16.0), "血条尺寸应为 72x16，实际 %s" % bar.size)
	bar.queue_free()

func _test_visibility_cycle() -> void:
	var bar: PawnHealthBar = _spawn_bar()
	bar.notify_health_state_changed(80.0, 120.0, 40.0, 40.0)
	_check(bar.visible, "生命状态变化后血条必须在同一帧显示")
	_check(is_equal_approx(bar.get_remaining_hide_time(), EXPECTED_DELAY), "显示后隐藏计时应重置为 2.0 秒")
	_check(bar.is_hide_countdown_running(), "显示后隐藏计时应处于运行状态")
	bar.tick(1.9)
	_check(bar.visible, "最后一次变化后 1.9 秒内血条应保持可见")
	bar.tick(0.2)
	_check(bar.visible == false, "最后一次变化 2.0 秒后血条应自动隐藏")
	_check(bar.is_processing() == false, "血条隐藏后应停止隐藏计时处理，避免空转")
	bar.queue_free()

func _test_countdown_reset_on_repeated_change() -> void:
	var bar: PawnHealthBar = _spawn_bar()
	bar.notify_health_state_changed(120.0, 120.0, 40.0, 40.0)
	bar.tick(1.0)
	bar.notify_health_state_changed(110.0, 120.0, 40.0, 40.0)
	bar.tick(1.0)
	_check(bar.visible, "连续变化应重置隐藏计时：第 2 次变化后 1 秒仍应可见")
	bar.tick(0.5)
	_check(bar.visible, "连续变化后累计 1.5 秒仍应可见")
	bar.tick(0.6)
	_check(bar.visible == false, "最后一次变化满 2 秒后应隐藏（累计 2.1 秒）")
	bar.queue_free()

func _test_shield_change_reveals_bar() -> void:
	var pawn: Pawn = _spawn_pawn()
	var bar: PawnHealthBar = pawn.health_bar
	var health_before: float = pawn.current_health
	var shield_before: float = pawn.current_shield
	pawn.take_damage(pawn.data.defense + 5.0)
	_check(pawn.current_shield < shield_before, "本次伤害应消耗护盾")
	_check(is_equal_approx(pawn.current_health, health_before), "护盾吸收伤害时生命不应变化")
	_check(bar.visible, "护盾变化（不只是掉血）也必须触发血条显示")
	bar.hide_now()
	bar.set_values(1.0, 2.0, 3.0, 4.0)
	_check(bar.visible == false, "set_values 只同步数值，不应改变可见性")
	pawn.queue_free()

func _test_pawn_structure_and_anchor() -> void:
	var pawn: Pawn = _spawn_pawn()
	pawn.position = Vector2(400.0, 300.0)
	var anchor: Node2D = pawn.get_node_or_null("HealthBarAnchor")
	_check(anchor != null, "Pawn 场景应包含 HealthBarAnchor 节点")
	var bar: PawnHealthBar = pawn.get_node_or_null("HealthBarAnchor/HealthBar")
	_check(bar != null, "血条应挂在 Pawn/HealthBarAnchor/HealthBar 路径下")
	_check(pawn.get_node_or_null("HealthBar") == null, "不应再保留内联的 HealthBar 节点")
	if anchor != null and bar != null:
		_check(anchor.position == Vector2(0.0, -46.0), "血条锚点应位于 Pawn 头顶 (0, -46)，实际 %s" % anchor.position)
		_check(bar.global_position == Vector2(364.0, 246.0), "血条全局位置应为锚点 + (-36, -8)，实际 %s" % bar.global_position)
		_check(bar.visible == false, "Pawn 实例化完成后血条初始应隐藏")
		_check(bar.process_mode == Node.PROCESS_MODE_INHERIT, "血条应继承 Pawn 的 PROCESS_MODE_PAUSABLE，使暂停时隐藏计时冻结")
	pawn.queue_free()

func _test_pawn_damage_and_death_reveal() -> void:
	var pawn: Pawn = _spawn_pawn()
	var bar: PawnHealthBar = pawn.health_bar
	bar.hide_now()
	var health_before: float = pawn.current_health
	pawn.take_damage(pawn.data.defense + 50.0)
	_check(pawn.current_health < health_before, "伤害应降低生命")
	_check(bar.visible, "伤害后血条应在同一帧显示")
	bar.tick(EXPECTED_DELAY + 0.1)
	_check(bar.visible == false, "伤害后无新变化 2 秒血条应隐藏")
	pawn.take_damage(pawn.data.max_health + pawn.data.max_shield + 100.0)
	_check(pawn.is_dead(), "致命伤害后 Pawn 应进入死亡状态")
	_check(is_equal_approx(pawn.current_health, 0.0), "死亡后生命值应为 0")
	_check(bar.visible, "死亡时血条应显示")
	bar.tick(EXPECTED_DELAY + 0.1)
	_check(bar.visible == false, "死亡后无新变化 2 秒血条应隐藏")
	pawn.queue_free()

## 使用真实引擎帧与真实时间验证隐藏计时，并验证暂停冻结计时。
func _test_runtime_visibility_timing() -> void:
	var pawn: Pawn = _spawn_pawn()
	var bar: PawnHealthBar = pawn.health_bar
	_check(bar.visible == false, "运行态：未发生状态变化时血条保持隐藏")

	pawn.take_damage(pawn.data.defense + 5.0)
	_check(bar.visible, "运行态：伤害后血条在同一帧显示")

	var started_at: int = Time.get_ticks_msec()
	var frames: int = 0
	while bar.visible and Time.get_ticks_msec() - started_at < 6000:
		await process_frame
		frames += 1
	var elapsed_msec: int = Time.get_ticks_msec() - started_at
	_check(bar.visible == false, "运行态：最后一次变化后血条应自动隐藏")
	_check(elapsed_msec >= 1900 and elapsed_msec <= 3500, "运行态：隐藏耗时应接近 2 秒，实际 %d ms / %d 帧" % [elapsed_msec, frames])

	self.paused = true
	pawn.take_damage(pawn.data.defense + 5.0)
	_check(bar.visible, "运行态：暂停中发生状态变化仍应显示血条")
	for _i: int in 30:
		await process_frame
	_check(bar.visible, "运行态：暂停期间血条不应隐藏（隐藏计时随暂停冻结）")
	self.paused = false

	var resume_at: int = Time.get_ticks_msec()
	while bar.visible and Time.get_ticks_msec() - resume_at < 6000:
		await process_frame
	_check(bar.visible == false, "运行态：恢复运行后血条仍按同一规则隐藏")
	pawn.queue_free()

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("HEALTH_BAR_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)