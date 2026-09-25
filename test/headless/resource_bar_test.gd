extends SceneTree

## 自建 headless 验证（项目尚未引入 GUT / GdUnit）。
## 验证目标：ResourceBar 的延迟追赶与 PawnStatusBars 的组级显隐/多资源独立性。
## 运行方式：
##   godot --headless --path . --script res://test/headless/resource_bar_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const BAR_SCENE_PATH: String = "res://game/ui/resource_bar.tscn"
const STATUS_BARS_SCENE_PATH: String = "res://game/ui/pawn_status_bars.tscn"
const DEFINITION_PATH: String = "res://game/shared/resources/resource_pool_definition.gd"
const POOL_PATH: String = "res://game/shared/core/resource_pool_component.gd"

var _failures: Array[String] = []
var _check_count: int = 0

func _initialize() -> void:
	await process_frame
	_test_bar_scene_contract()
	_test_bind_and_immediate_increase()
	_test_delayed_drain()
	_test_delayed_drain_disabled()
	_test_retarget_during_drain()
	_test_zero_max_hides_bar()
	await _test_status_bars_scene_and_layout()
	await _test_status_bars_group_timing_and_independence()
	await _test_pause_freezes_drain()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("RESOURCE_BAR_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)

func _new_definition(resource_id: StringName, max_value: float, initial_ratio: float) -> ResourcePoolDefinition:
	var definition: ResourcePoolDefinition = load(DEFINITION_PATH).new()
	definition.resource_id = resource_id
	definition.display_name = String(resource_id)
	definition.max_value = max_value
	definition.initial_ratio = initial_ratio
	return definition

func _new_pool(resource_id: StringName, max_value: float, initial_ratio: float = 1.0) -> ResourcePoolComponent:
	var pool: ResourcePoolComponent = load(POOL_PATH).new()
	pool.resource_definition = _new_definition(resource_id, max_value, initial_ratio)
	root.add_child(pool)
	return pool

func _spawn_bar() -> ResourceBar:
	var scene: PackedScene = load(BAR_SCENE_PATH)
	var bar: ResourceBar = scene.instantiate()
	root.add_child(bar)
	return bar

func _spawn_status_bars() -> PawnStatusBars:
	var scene: PackedScene = load(STATUS_BARS_SCENE_PATH)
	var bars: PawnStatusBars = scene.instantiate()
	root.add_child(bars)
	return bars

func _test_bar_scene_contract() -> void:
	var bar: ResourceBar = _spawn_bar()
	_check(bar.get_script().resource_path == "res://game/ui/resource_bar.gd", "ResourceBar 场景应挂载 resource_bar.gd")
	_check(bar.size == Vector2(80.0, 16.0), "ResourceBar 默认尺寸应为 80x16，实际 %s" % bar.size)
	_check(is_equal_approx(bar.delayed_drain_delay, 0.2), "默认追赶延迟应为 0.2 秒")
	_check(is_equal_approx(bar.delayed_drain_duration, 0.4), "默认追赶时长应为 0.4 秒")
	_check(bar.visible == false, "未绑定资源池时 ResourceBar 应隐藏")
	_check(bar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ResourceBar 不应拦截鼠标输入")
	_check(not bar.has_valid_pool(), "未绑定资源池时不应有有效范围")
	bar.queue_free()

func _test_bind_and_immediate_increase() -> void:
	var pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	var bar: ResourceBar = _spawn_bar()
	bar.bind_pool(pool)
	_check(bar.visible, "绑定正上限资源池后 ResourceBar 应可见")
	_check(is_equal_approx(bar.get_target_value(), 100.0), "绑定后目标值应等于资源池当前值")
	_check(is_equal_approx(bar.get_displayed_value(), 100.0), "绑定后显示值应直接对齐目标值")
	_check(is_equal_approx(bar.get_target_ratio(), 1.0), "绑定后目标比例应为 1")
	_check(not bar.is_draining(), "绑定初始化不应启动追赶")

	pool.decrease(20.0)
	_check(is_equal_approx(bar.get_target_value(), 80.0), "减少后目标值应立即变化")
	_check(is_equal_approx(bar.get_displayed_value(), 100.0), "减少后延迟期间显示值应保持旧值")
	_check(bar.is_draining(), "延迟减少应进入追赶状态")
	_check(is_equal_approx(pool.current_value, 80.0), "延迟显示不得回写或阻止真实数值变化")

	bar.snap_to_target()
	pool.increase(10.0)
	_check(is_equal_approx(bar.get_target_value(), 90.0), "增加后目标值应更新")
	_check(is_equal_approx(bar.get_displayed_value(), 90.0), "增加默认应立即补齐显示值")
	_check(not bar.is_draining(), "增加立即补齐后不应继续追赶")
	bar.queue_free()

func _test_delayed_drain() -> void:
	var pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	var bar: ResourceBar = _spawn_bar()
	bar.bind_pool(pool)
	bar.delayed_drain_delay = 0.2
	bar.delayed_drain_duration = 0.4
	pool.decrease(20.0)

	bar.tick(0.1)
	_check(is_equal_approx(bar.get_displayed_value(), 100.0), "延迟未结束时显示值不应变化")
	bar.tick(0.1)
	_check(is_equal_approx(bar.get_displayed_value(), 100.0), "延迟恰好结束时仍不应跳跃")
	bar.tick(0.2)
	_check(is_equal_approx(bar.get_displayed_value(), 90.0), "追赶中点应线性显示 90，实际 %.2f" % bar.get_displayed_value())
	bar.tick(0.3)
	_check(is_equal_approx(bar.get_displayed_value(), 80.0), "追赶结束应精确对齐目标值")
	_check(not bar.is_draining(), "追赶结束应退出 draining")
	_check(not bar.is_processing(), "追赶结束应停止 _process")
	bar.queue_free()

func _test_delayed_drain_disabled() -> void:
	var pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	var bar: ResourceBar = _spawn_bar()
	bar.bind_pool(pool)
	bar.delayed_drain_delay = 1.0
	bar.delayed_drain_duration = 0.0
	pool.decrease(20.0)
	_check(is_equal_approx(bar.get_displayed_value(), 80.0), "追赶时长 <= 0 时应立即显示真实值")
	_check(not bar.is_draining(), "关闭追赶后不应进入 draining")

	bar.delayed_drain_duration = -1.0
	pool.increase(10.0)
	_check(is_equal_approx(bar.get_displayed_value(), 90.0), "增加仍应立即补齐")
	bar.queue_free()

func _test_retarget_during_drain() -> void:
	var pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	var bar: ResourceBar = _spawn_bar()
	bar.bind_pool(pool)
	bar.delayed_drain_delay = 0.2
	bar.delayed_drain_duration = 1.0
	pool.decrease(20.0)
	bar.tick(0.3)
	_check(is_equal_approx(bar.get_displayed_value(), 98.0), "首次追赶应到达 98，实际 %.2f" % bar.get_displayed_value())

	pool.decrease(20.0)
	_check(is_equal_approx(bar.get_target_value(), 60.0), "连续减少应更新目标值为 60")
	_check(is_equal_approx(bar.get_displayed_value(), 98.0), "重定向追赶不应瞬间跳值")
	bar.tick(0.2)
	_check(is_equal_approx(bar.get_displayed_value(), 98.0), "重定向后新的延迟应重新生效")
	bar.tick(0.5)
	_check(is_equal_approx(bar.get_displayed_value(), 79.0), "从 98 追赶到 60 的中点应为 79，实际 %.2f" % bar.get_displayed_value())
	bar.tick(0.5)
	_check(is_equal_approx(bar.get_displayed_value(), 60.0), "第二次追赶结束应对齐 60")
	bar.queue_free()

func _test_zero_max_hides_bar() -> void:
	var pool: ResourcePoolComponent = _new_pool(&"spirit", 0.0, 0.0)
	var bar: ResourceBar = _spawn_bar()
	bar.bind_pool(pool)
	_check(not bar.has_valid_pool(), "最大值为 0 的资源池不是有效可视化范围")
	_check(bar.visible == false, "最大值为 0 时 ResourceBar 应隐藏")
	_check(is_equal_approx(bar.get_target_ratio(), 0.0), "无效范围目标比例应为 0")
	_check(is_equal_approx(bar.get_displayed_ratio(), 0.0), "无效范围显示比例应为 0")
	bar.queue_free()

func _test_status_bars_scene_and_layout() -> void:
	var bars: PawnStatusBars = _spawn_status_bars()
	_check(bars.get_script().resource_path == "res://game/ui/pawn_status_bars.gd", "PawnStatusBars 场景应挂载对应脚本")
	_check(bars.size == Vector2(80.0, 52.0), "PawnStatusBars 默认尺寸应为 80x52，实际 %s" % bars.size)
	_check(is_equal_approx(bars.auto_hide_delay, 2.0), "PawnStatusBars 默认统一隐藏延迟应为 2.0 秒")
	_check(bars.visible == false, "PawnStatusBars 初始应隐藏")
	_check(bars.get_bar(&"health") == bars.health_bar, "应按 health ID 找到生命条")
	_check(bars.get_bar(&"shield") == bars.shield_bar, "应按 shield ID 找到护盾条")
	_check(bars.get_bar(&"spirit") == bars.spirit_bar, "应按 spirit ID 找到灵力条")
	_check(bars.get_bar(&"mana") == null, "未知资源 ID 应返回 null")

	var health_pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	var shield_pool: ResourcePoolComponent = _new_pool(&"shield", 40.0)
	var spirit_pool: ResourcePoolComponent = _new_pool(&"spirit", 20.0)
	_check(bars.bind_pool(&"health", health_pool), "应能绑定生命池")
	_check(bars.bind_pool(&"shield", shield_pool), "应能绑定护盾池")
	_check(bars.bind_pool(&"spirit", spirit_pool), "应能绑定灵力池")
	_check(not bars.bind_pool(&"mana", spirit_pool), "未知 ID 绑定应失败")
	_check(not bars.bind_pool(&"health", null), "空池绑定应失败")
	bars.reveal()
	await process_frame
	_check(bars.health_bar.position.y < bars.shield_bar.position.y, "生命条应排在护盾条之前")
	_check(bars.shield_bar.position.y < bars.spirit_bar.position.y, "护盾条应排在灵力条之前")
	_check(bars.health_bar.visible and bars.shield_bar.visible and bars.spirit_bar.visible, "有效资源池对应的子条应可见")
	_check(bars.health_bar.global_position.y + bars.health_bar.size.y <= bars.shield_bar.global_position.y, "生命条与护盾条不得重叠")
	_check(bars.shield_bar.global_position.y + bars.shield_bar.size.y <= bars.spirit_bar.global_position.y, "护盾条与灵力条不得重叠")
	_check(bars.health_bar.fill_color != bars.shield_bar.fill_color, "生命与护盾条应支持不同颜色")
	_check(bars.shield_bar.fill_color != bars.spirit_bar.fill_color, "护盾与灵力条应支持不同颜色")
	bars.queue_free()

func _test_status_bars_group_timing_and_independence() -> void:
	var bars: PawnStatusBars = _spawn_status_bars()
	var health_pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	var shield_pool: ResourcePoolComponent = _new_pool(&"shield", 40.0)
	var spirit_pool: ResourcePoolComponent = _new_pool(&"spirit", 20.0)
	bars.bind_pool(&"health", health_pool)
	bars.bind_pool(&"shield", shield_pool)
	bars.bind_pool(&"spirit", spirit_pool)
	_check(bars.visible == false, "仅绑定但未变化时整组应保持隐藏")

	health_pool.decrease(20.0)
	_check(bars.visible, "任一资源变化应显示整组")
	_check(is_equal_approx(bars.get_remaining_hide_time(), 2.0), "资源变化应重置组级 2 秒计时")
	_check(is_equal_approx(bars.health_bar.get_target_value(), 80.0), "生命条目标应独立刷新为 80")
	_check(is_equal_approx(bars.health_bar.get_displayed_value(), 100.0), "生命条显示应保持延迟追赶")
	_check(is_equal_approx(bars.shield_bar.get_target_value(), 40.0), "护盾条目标不应受生命变化影响")
	_check(is_equal_approx(bars.spirit_bar.get_target_value(), 20.0), "灵力条目标不应受生命变化影响")

	bars.tick(1.5)
	bars.health_bar.tick(1.5)
	_check(bars.visible, "单一组级计时 1.5 秒内应保持可见")
	shield_pool.decrease(5.0)
	_check(is_equal_approx(bars.get_remaining_hide_time(), 2.0), "另一资源变化应重置统一计时")
	_check(is_equal_approx(bars.health_bar.get_displayed_value(), 80.0), "护盾变化不应回退已完成的生命显示")
	bars.tick(1.9)
	_check(bars.visible, "组级计时 1.9 秒内仍应可见")
	bars.tick(0.2)
	_check(bars.visible == false, "最后一次资源变化满 2 秒后整组应隐藏")
	_check(not bars.is_hide_countdown_running(), "隐藏后组级计时应停止")

	health_pool.decrease(5.0)
	bars.hide_now()
	_check(bars.visible == false, "hide_now 应可立即隐藏整组")
	_check(is_equal_approx(bars.get_remaining_hide_time(), 0.0), "hide_now 应清零计时")

	var zero_spirit: ResourcePoolComponent = _new_pool(&"spirit", 0.0, 0.0)
	var zero_bars: PawnStatusBars = _spawn_status_bars()
	zero_bars.bind_pool(&"spirit", zero_spirit)
	_check(zero_bars.spirit_bar.visible == false, "最大值为 0 的子资源条应由组容器隐藏")
	_check(not zero_bars.has_valid_bars(), "没有有效资源时组容器不应报告有效条")
	_check(zero_bars.visible == false, "没有有效资源时整组应隐藏")

	zero_bars.bind_pool(&"health", health_pool)
	zero_bars.auto_hide_delay = 0.0
	health_pool.decrease(5.0)
	_check(zero_bars.visible, "auto_hide_delay <= 0 时应进入常驻显示模式")
	zero_bars.tick(10.0)
	_check(zero_bars.visible, "常驻模式下 tick 不应隐藏整组")

	bars.queue_free()
	zero_bars.queue_free()

func _test_pause_freezes_drain() -> void:
	var parent: Node = Node.new()
	parent.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.add_child(parent)
	var bars_scene: PackedScene = load(STATUS_BARS_SCENE_PATH)
	var bars: PawnStatusBars = bars_scene.instantiate()
	parent.add_child(bars)
	var pool: ResourcePoolComponent = _new_pool(&"health", 100.0)
	bars.bind_pool(&"health", pool)
	pool.decrease(20.0)
	_check(bars.visible, "暂停测试：变化后整组应显示")
	_check(bars.health_bar.is_draining(), "暂停测试：血条应处于延迟追赶")

	var displayed_before_pause: float = bars.health_bar.get_displayed_value()
	var group_timer_before_pause: float = bars.get_remaining_hide_time()
	self.paused = true
	for _i: int in 30:
		await process_frame
	_check(is_equal_approx(bars.health_bar.get_displayed_value(), displayed_before_pause), "暂停期间延迟追赶必须冻结")
	_check(is_equal_approx(bars.get_remaining_hide_time(), group_timer_before_pause), "暂停期间组级隐藏计时必须冻结")
	_check(bars.visible, "暂停期间整组应保持原可见状态")
	self.paused = false

	var drain_started_at: int = Time.get_ticks_msec()
	while bars.health_bar.is_draining() and Time.get_ticks_msec() - drain_started_at < 3000:
		await process_frame
	_check(not bars.health_bar.is_draining(), "恢复运行后延迟追赶应继续并完成")
	_check(is_equal_approx(bars.health_bar.get_displayed_value(), 80.0), "恢复后显示值应对齐真实目标")

	var hide_started_at: int = Time.get_ticks_msec()
	while bars.visible and Time.get_ticks_msec() - hide_started_at < 5000:
		await process_frame
	_check(bars.visible == false, "恢复运行后组级隐藏计时应继续并最终隐藏")
	parent.queue_free()
