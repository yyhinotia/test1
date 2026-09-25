extends SceneTree

## 自建 headless 验证（项目尚未引入 GUT / GdUnit）。
## 验证目标：ResourcePoolComponent / ResourceSetComponent 的通用数值池契约。
## 运行方式：
##   godot --headless --path . --script res://test/headless/resource_pool_component_test.gd
## 退出码：0 = 全部通过；1 = 存在失败项。

const DEFINITION_PATH: String = "res://game/shared/resources/resource_pool_definition.gd"
const POOL_PATH: String = "res://game/shared/core/resource_pool_component.gd"
const SET_PATH: String = "res://game/shared/core/resource_set_component.gd"

var _failures: Array[String] = []
var _check_count: int = 0
var _events: Array[String] = []

func _initialize() -> void:
	await process_frame
	_test_definition_is_static_data()
	_test_configure_and_reset_are_silent()
	_test_increase_decrease_boundaries()
	_test_atomic_spend()
	_test_signal_delta_and_source()
	_test_resource_set_lookup()
	_test_ready_auto_configuration()
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("RESOURCE_POOL_COMPONENT_TEST_OK")
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

func _new_unconfigured_pool() -> ResourcePoolComponent:
	var pool: ResourcePoolComponent = load(POOL_PATH).new()
	root.add_child(pool)
	return pool

func _new_pool(definition: ResourcePoolDefinition) -> ResourcePoolComponent:
	var pool: ResourcePoolComponent = _new_unconfigured_pool()
	pool.configure(definition)
	return pool

func _track_pool(pool: ResourcePoolComponent) -> void:
	pool.value_changed.connect(func(_current: float, _max: float, _delta: float, _source: StringName) -> void:
		_events.append("value=%.1f/%.1f,delta=%.1f,source=%s" % [_current, _max, _delta, String(_source)])
	)
	pool.depleted.connect(func(_component: ResourcePoolComponent) -> void:
		_events.append("depleted")
	)
	pool.restored.connect(func(_component: ResourcePoolComponent) -> void:
		_events.append("restored")
	)

func _test_definition_is_static_data() -> void:
	var definition: ResourcePoolDefinition = _new_definition(&"mana", 100.0, 0.25)
	_check(definition.get_script().resource_path == DEFINITION_PATH, "定义脚本路径应为 %s" % DEFINITION_PATH)
	_check(definition is Resource, "ResourcePoolDefinition 必须继承 Resource")
	_check(definition.resource_id == &"mana", "资源 ID 应保留为稳定 StringName")
	_check(is_equal_approx(definition.get_initial_value(), 25.0), "初始值应由 max_value * initial_ratio 计算，实际 %.1f" % definition.get_initial_value())

	definition.initial_ratio = 2.0
	_check(is_equal_approx(definition.get_initial_value(), 100.0), "初始比例应在上限处截断")
	definition.initial_ratio = -1.0
	_check(is_equal_approx(definition.get_initial_value(), 0.0), "初始比例应在下限处截断")
	definition.initial_ratio = 0.5
	definition.max_value = -5.0
	_check(is_equal_approx(definition.get_normalized_max_value(), 0.0), "负上限应规范化为 0")
	_check(is_equal_approx(definition.get_initial_value(), 0.0), "负上限时初始值应为 0")
	_check(definition.auto_regenerate == false, "auto_regenerate 默认应为 false")
	_check(definition.depleted_behavior == ResourcePoolDefinition.DepletedBehavior.NONE, "归零语义默认应为 NONE")

	var has_runtime_value: bool = false
	for property: Dictionary in definition.get_property_list():
		var property_name: String = String(property.get("name", ""))
		if property_name == "current_value" or property_name == "runtime_value":
			has_runtime_value = true
	_check(not has_runtime_value, "静态 Resource 不得声明运行时当前值字段")

func _test_configure_and_reset_are_silent() -> void:
	_events.clear()
	var pool: ResourcePoolComponent = _new_unconfigured_pool()
	_track_pool(pool)
	var definition: ResourcePoolDefinition = _new_definition(&"health", 100.0, 0.25)

	pool.configure(definition)
	_check(is_equal_approx(pool.max_value, 100.0), "configure 应写入上限，实际 %.1f" % pool.max_value)
	_check(is_equal_approx(pool.current_value, 25.0), "configure 应按初始比例初始化，实际 %.1f" % pool.current_value)
	_check(is_equal_approx(pool.get_ratio(), 0.25), "configure 后比例应为 0.25")
	_check(not pool.is_depleted(), "初始值大于 0 时不应标记归零")
	_check(pool.get_resource_id() == &"health", "资源池应暴露稳定资源 ID")
	var silent_expected: Array[String] = []
	_check(_events == silent_expected, "configure 必须静默，实际 %s" % str(_events))

	pool.decrease(5.0, &"damage")
	_check(is_equal_approx(pool.current_value, 20.0), "减少后当前值应为 20，实际 %.1f" % pool.current_value)
	var decreased_expected: Array[String] = ["value=20.0/100.0,delta=-5.0,source=damage"]
	_check(_events == decreased_expected, "真实减少应发一次 value_changed，实际 %s" % str(_events))

	_events.clear()
	pool.reset()
	_check(is_equal_approx(pool.current_value, 25.0), "reset 应静默恢复到定义初始值")
	_check(_events.is_empty(), "reset 不得发出变化/归零/恢复信号，实际 %s" % str(_events))

	var empty_definition: ResourcePoolDefinition = _new_definition(&"empty", 100.0, 0.0)
	pool.configure(empty_definition)
	_check(is_equal_approx(pool.current_value, 0.0), "初始比例为 0 时应初始化到归零状态")
	_check(pool.is_depleted(), "初始归零应静默标记 depleted")
	_check(_events.is_empty(), "configure 转入归零状态也必须静默，实际 %s" % str(_events))

	_events.clear()
	pool.configure(null)
	_check(is_equal_approx(pool.max_value, 0.0), "空定义应安全规范化为 0 上限")
	_check(is_equal_approx(pool.current_value, 0.0), "空定义应安全规范化为 0 当前值")
	_check(pool.is_depleted(), "空定义应处于归零状态")
	_check(_events.is_empty(), "空定义 configure 必须静默")

func _test_increase_decrease_boundaries() -> void:
	_events.clear()
	var pool: ResourcePoolComponent = _new_pool(_new_definition(&"shield", 100.0, 1.0))
	_track_pool(pool)

	_check(is_equal_approx(pool.increase(0.0), 0.0), "增加 0 应返回 0")
	_check(is_equal_approx(pool.increase(-5.0), 0.0), "增加负数应返回 0")
	_check(is_equal_approx(pool.decrease(0.0), 0.0), "减少 0 应返回 0")
	_check(is_equal_approx(pool.decrease(-5.0), 0.0), "减少负数应返回 0")
	_check(_events.is_empty(), "0/负数操作不得改变数值或发信号，实际 %s" % str(_events))
	_check(is_equal_approx(pool.increase(10.0), 0.0), "满值增加应返回 0")

	var decreased: float = pool.decrease(150.0, &"damage")
	_check(is_equal_approx(decreased, 100.0), "超量减少应只返回实际变化 100，实际 %.1f" % decreased)
	_check(is_equal_approx(pool.current_value, 0.0), "超量减少应截断到 0")
	_check(pool.is_depleted(), "减少到 0 后应标记 depleted")
	var depleted_expected: Array[String] = ["value=0.0/100.0,delta=-100.0,source=damage", "depleted"]
	_check(_events == depleted_expected, "归零顺序应为 value_changed 后 depleted，实际 %s" % str(_events))

	_events.clear()
	_check(is_equal_approx(pool.decrease(1.0), 0.0), "已归零后继续减少应返回 0")
	_check(not pool.try_spend(1.0), "已归零时原子消耗应失败")
	_check(_events.is_empty(), "已归零后的无效操作不得发信号，实际 %s" % str(_events))

	_check(is_equal_approx(pool.increase(30.0, &"restore"), 30.0), "从归零增加应返回实际值 30")
	_check(is_equal_approx(pool.current_value, 30.0), "从归零增加后当前值应为 30")
	var restored_expected: Array[String] = ["value=30.0/100.0,delta=30.0,source=restore", "restored"]
	_check(_events == restored_expected, "恢复顺序应为 value_changed 后 restored，实际 %s" % str(_events))

	_events.clear()
	_check(is_equal_approx(pool.increase(1000.0), 70.0), "超上限增加应返回实际变化 70")
	_check(is_equal_approx(pool.current_value, 100.0), "超上限增加应截断到上限")
	_check(is_equal_approx(pool.set_value(120.0), 0.0), "set_value 超上限且数值已满时不应产生变化")
	_check(_events.size() == 1, "超上限增加只应发一次真实变化信号，实际 %s" % str(_events))

	_events.clear()
	_check(is_equal_approx(pool.set_value(-5.0, &"debug"), 100.0), "set_value 负数应截断到 0 并返回实际变化")
	_check(is_equal_approx(pool.current_value, 0.0), "set_value 负数后当前值应为 0")
	_check(pool.is_depleted(), "set_value 到 0 应标记归零")
	_check(_events.size() == 2, "set_value 到 0 应发 value_changed + depleted，实际 %s" % str(_events))

func _test_atomic_spend() -> void:
	_events.clear()
	var pool: ResourcePoolComponent = _new_pool(_new_definition(&"spirit", 50.0, 1.0))
	_track_pool(pool)

	_check(not pool.try_spend(0.0), "消耗 0 应失败且不改变数值")
	_check(not pool.try_spend(-1.0), "消耗负数应失败且不改变数值")
	_check(not pool.try_spend(51.0), "余额不足应返回 false")
	_check(is_equal_approx(pool.current_value, 50.0), "余额不足时数值必须完全不变")
	_check(_events.is_empty(), "无效消耗不得发信号，实际 %s" % str(_events))

	_check(pool.try_spend(20.0, &"skill"), "余额足够时原子消耗应返回 true")
	_check(is_equal_approx(pool.current_value, 30.0), "消耗 20 后当前值应为 30")
	_check(_events.size() == 1, "一次成功消耗应发一次 value_changed，实际 %s" % str(_events))

	_events.clear()
	_check(not pool.try_spend(31.0), "差额不足时应整体失败")
	_check(is_equal_approx(pool.current_value, 30.0), "失败消耗不得产生部分扣除")
	_check(_events.is_empty(), "失败消耗不得产生信号，实际 %s" % str(_events))

	_check(pool.try_spend(30.0), "消耗全部余额应成功")
	_check(is_equal_approx(pool.current_value, 0.0), "全部消耗后当前值应为 0")
	_check(pool.is_depleted(), "全部消耗后应标记归零")
	var spent_expected: Array[String] = ["value=0.0/50.0,delta=-30.0,source=spend", "depleted"]
	_check(_events == spent_expected, "全量消耗应保持默认 source=spend，实际 %s" % str(_events))

	_events.clear()
	_check(not pool.try_spend(1.0), "归零后继续消耗应失败")
	_check(_events.is_empty(), "归零后失败消耗不得新增信号")
	_check(is_equal_approx(pool.increase(10.0, &"restore"), 10.0), "灵力可恢复")
	_check(not pool.is_depleted(), "灵力恢复后应清除归零状态")

	_events.clear()
	_check(pool.try_spend(10.0), "恢复后可再次原子消耗")
	_check(is_equal_approx(pool.current_value, 0.0), "再次消耗后当前值应为 0")
	_check(pool.is_depleted(), "再次归零应重新标记 depleted")
	var respent_expected: Array[String] = ["value=0.0/50.0,delta=-10.0,source=spend", "depleted"]
	_check(_events == respent_expected, "再次归零应重新发一次 depleted，实际 %s" % str(_events))

func _test_signal_delta_and_source() -> void:
	_events.clear()
	var pool: ResourcePoolComponent = _new_pool(_new_definition(&"health", 100.0, 1.0))
	_track_pool(pool)

	_check(is_equal_approx(pool.decrease(12.5, &"damage"), 12.5), "减少应返回正值实际变化量")
	var damage_expected: Array[String] = ["value=87.5/100.0,delta=-12.5,source=damage"]
	_check(_events == damage_expected, "减少信号应带负 delta 和来源，实际 %s" % str(_events))

	_events.clear()
	_check(is_equal_approx(pool.increase(5.0, &"potion"), 5.0), "增加应返回正值实际变化量")
	var heal_expected: Array[String] = ["value=92.5/100.0,delta=5.0,source=potion"]
	_check(_events == heal_expected, "增加信号应带正 delta 和来源，实际 %s" % str(_events))

func _test_resource_set_lookup() -> void:
	var resource_set: ResourceSetComponent = load(SET_PATH).new()
	root.add_child(resource_set)
	var health_pool: ResourcePoolComponent = _new_pool(_new_definition(&"health", 100.0, 1.0))
	var shield_pool: ResourcePoolComponent = _new_pool(_new_definition(&"shield", 40.0, 1.0))
	var spirit_pool: ResourcePoolComponent = _new_pool(_new_definition(&"spirit", 20.0, 1.0))
	health_pool.decrease(10.0)
	shield_pool.decrease(5.0)

	_check(resource_set.register_pool(&"health", health_pool), "资源集合应能注册 health")
	_check(resource_set.register_pool(&"shield", shield_pool), "资源集合应能注册 shield")
	_check(resource_set.register_pool(&"spirit", spirit_pool), "资源集合应能注册 spirit")
	_check(not resource_set.register_pool(&"", health_pool), "空资源 ID 注册应失败")
	_check(not resource_set.register_pool(&"null", null), "空资源池注册应失败")
	_check(not resource_set.register_pool(&"health", health_pool), "重复资源 ID 注册应失败")
	_check(resource_set.pool_count == 3, "资源集合应包含 3 个池，实际 %d" % resource_set.pool_count)
	_check(resource_set.has_pool(&"health"), "资源集合应能判断资源存在")
	_check(not resource_set.has_pool(&"mana"), "未知资源 ID 不应存在")
	_check(resource_set.get_pool(&"shield") == shield_pool, "资源集合应按 ID 返回同一个池")
	_check(resource_set.get_pool(&"mana") == null, "未知资源 ID 应返回 null")

	var expected_ids: Array[StringName] = [&"health", &"shield", &"spirit"]
	_check(resource_set.get_resource_ids() == expected_ids, "资源 ID 应按稳定顺序返回，实际 %s" % str(resource_set.get_resource_ids()))
	_check(is_equal_approx(health_pool.current_value, 90.0), "注册/查找不得修改 health 数值")
	_check(is_equal_approx(shield_pool.current_value, 35.0), "注册/查找不得修改 shield 数值")
	_check(resource_set.unregister_pool(&"spirit"), "已注册资源应能注销")
	_check(not resource_set.unregister_pool(&"spirit"), "重复注销应返回 false")
	_check(resource_set.pool_count == 2, "注销后资源数量应减少")

func _test_ready_auto_configuration() -> void:
	var definition: ResourcePoolDefinition = _new_definition(&"ready_resource", 80.0, 0.5)
	var pool: ResourcePoolComponent = load(POOL_PATH).new()
	pool.resource_definition = definition
	root.add_child(pool)
	_check(is_equal_approx(pool.max_value, 80.0), "带定义进入场景树时应自动配置上限")
	_check(is_equal_approx(pool.current_value, 40.0), "带定义进入场景树时应自动配置初始值")
	_check(is_equal_approx(pool.get_ratio(), 0.5), "自动配置后比例应为 0.5")
	_check(not pool.is_depleted(), "自动配置到非零值不应标记归零")

	var pool_with_override: ResourcePoolComponent = _new_unconfigured_pool()
	pool_with_override.configure(definition, 0.25)
	_check(is_equal_approx(pool_with_override.current_value, 20.0), "显式初始比例应可覆盖定义")
	_check(is_equal_approx(pool_with_override.get_ratio(), 0.25), "覆盖后比例应为 0.25")
