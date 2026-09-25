extends GdUnitTestSuite

## 单元层（纯逻辑）：ResourcePoolComponent 的数值边界、原子性与信号契约。
## 不加载任何场景，只验证“单个资源池”这一层的算术与信号。

const RESOURCE_ID: StringName = &"test_resource"
const APPROX: float = 0.001


func _tracked_pool() -> ResourcePoolComponent:
	var pool: ResourcePoolComponent = ResourcePoolComponent.new()
	auto_free(pool)
	return pool


func _definition(max_value: float, initial_ratio: float = 1.0) -> ResourcePoolDefinition:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()
	definition.resource_id = RESOURCE_ID
	definition.display_name = "测试资源"
	definition.max_value = max_value
	definition.initial_ratio = initial_ratio
	return definition


func _make_pool(max_value: float, initial_ratio: float = 1.0) -> ResourcePoolComponent:
	var pool: ResourcePoolComponent = _tracked_pool()
	pool.configure(_definition(max_value, initial_ratio))
	return pool


## 初始化必须静默：出生不应该触发任何提示或动画。
func test_configure_is_silent_and_applies_initial_ratio() -> void:
	var pool: ResourcePoolComponent = _tracked_pool()
	var events: Array[String] = []
	pool.value_changed.connect(func(_c: float, _m: float, _d: float, _s: StringName) -> void: events.append("value_changed"))
	pool.depleted.connect(func(_p: ResourcePoolComponent) -> void: events.append("depleted"))
	pool.restored.connect(func(_p: ResourcePoolComponent) -> void: events.append("restored"))

	pool.configure(_definition(120.0, 0.5))

	assert_float(pool.max_value).is_equal(120.0)
	assert_float(pool.current_value).is_equal_approx(60.0, APPROX)
	assert_array(events).is_empty()


func test_increase_clamps_at_max_and_reports_applied_amount() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 0.0)

	assert_float(pool.increase(30.0)).is_equal_approx(30.0, APPROX)
	assert_float(pool.current_value).is_equal_approx(30.0, APPROX)

	assert_float(pool.increase(1000.0)).is_equal_approx(70.0, APPROX)
	assert_float(pool.current_value).is_equal_approx(100.0, APPROX)

	# 已满时继续增加不产生变化，返回 0。
	assert_float(pool.increase(10.0)).is_zero()
	assert_float(pool.current_value).is_equal_approx(100.0, APPROX)


func test_decrease_clamps_at_zero_and_reports_applied_amount() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 1.0)

	assert_float(pool.decrease(30.0)).is_equal_approx(30.0, APPROX)
	assert_float(pool.current_value).is_equal_approx(70.0, APPROX)

	assert_float(pool.decrease(1000.0)).is_equal_approx(70.0, APPROX)
	assert_float(pool.current_value).is_zero()

	assert_float(pool.decrease(10.0)).is_zero()
	assert_float(pool.current_value).is_zero()


## 0、负数与非有限值必须是完全无副作用：数值不变且不产生信号。
func test_invalid_amounts_are_complete_no_ops() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 0.5)
	var events: Array[String] = []
	pool.value_changed.connect(func(_c: float, _m: float, _d: float, _s: StringName) -> void: events.append("value_changed"))

	assert_float(pool.increase(0.0)).is_zero()
	assert_float(pool.increase(-25.0)).is_zero()
	assert_float(pool.increase(NAN)).is_zero()
	assert_float(pool.decrease(0.0)).is_zero()
	assert_float(pool.decrease(-25.0)).is_zero()
	assert_float(pool.decrease(INF)).is_zero()
	assert_float(pool.set_value(NAN)).is_zero()

	assert_float(pool.current_value).is_equal_approx(50.0, APPROX)
	assert_array(events).is_empty()


## 原子消耗：余额不足时必须“完全不发生”，而不是扣到 0。
func test_try_spend_is_atomic_when_balance_is_insufficient() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 0.5)
	var events: Array[String] = []
	pool.value_changed.connect(func(_c: float, _m: float, _d: float, _s: StringName) -> void: events.append("value_changed"))

	assert_bool(pool.try_spend(50.1)).is_false()
	assert_float(pool.current_value).is_equal_approx(50.0, APPROX)
	assert_array(events).is_empty()

	assert_bool(pool.try_spend(50.0)).is_true()
	assert_float(pool.current_value).is_zero()
	assert_bool(pool.is_depleted()).is_true()


func test_set_value_clamps_into_bounds() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 0.0)

	assert_float(pool.set_value(150.0)).is_equal_approx(100.0, APPROX)
	assert_float(pool.current_value).is_equal_approx(100.0, APPROX)

	assert_float(pool.set_value(-10.0)).is_equal_approx(100.0, APPROX)
	assert_float(pool.current_value).is_zero()

	assert_float(pool.set_value(42.0)).is_equal_approx(42.0, APPROX)
	assert_float(pool.current_value).is_equal_approx(42.0, APPROX)


func test_get_ratio_handles_zero_max() -> void:
	var empty_pool: ResourcePoolComponent = _make_pool(0.0, 1.0)
	assert_float(empty_pool.get_ratio()).is_zero()

	var pool: ResourcePoolComponent = _make_pool(100.0, 0.25)
	assert_float(pool.get_ratio()).is_equal_approx(0.25, APPROX)


## depleted / restored 是边沿信号：每次跨越只发一次。
## 注意：GDScript 匿名函数按值捕获局部基本类型，计数必须用引用类型（Array）收集。
func test_depleted_and_restored_emit_once_per_transition() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 0.5)
	var depleted_events: Array[String] = []
	var restored_events: Array[String] = []
	pool.depleted.connect(func(_p: ResourcePoolComponent) -> void: depleted_events.append("depleted"))
	pool.restored.connect(func(_p: ResourcePoolComponent) -> void: restored_events.append("restored"))

	pool.decrease(50.0)
	assert_int(depleted_events.size()).is_equal(1)
	assert_bool(pool.is_depleted()).is_true()

	pool.decrease(10.0)
	assert_int(depleted_events.size()).is_equal(1)

	pool.increase(10.0)
	assert_int(restored_events.size()).is_equal(1)
	assert_bool(pool.is_depleted()).is_false()

	pool.increase(10.0)
	assert_int(restored_events.size()).is_equal(1)


func test_value_changed_reports_delta_and_source() -> void:
	var pool: ResourcePoolComponent = _make_pool(100.0, 1.0)
	var deltas: Array[float] = []
	var sources: Array[StringName] = []
	pool.value_changed.connect(func(_c: float, _m: float, delta: float, source: StringName) -> void:
		deltas.append(delta)
		sources.append(source)
	)

	pool.decrease(30.0, &"unit_test_source")

	assert_array(deltas).has_size(1)
	assert_float(deltas[0]).is_equal_approx(-30.0, APPROX)
	assert_array(sources).has_size(1)
	assert_str(String(sources[0])).is_equal("unit_test_source")


func test_reset_restores_initial_ratio() -> void:
	var pool: ResourcePoolComponent = _make_pool(80.0, 0.25)
	assert_float(pool.current_value).is_equal_approx(20.0, APPROX)

	pool.increase(60.0)
	assert_float(pool.current_value).is_equal_approx(80.0, APPROX)

	pool.reset()
	assert_float(pool.current_value).is_equal_approx(20.0, APPROX)
	assert_float(pool.max_value).is_equal_approx(80.0, APPROX)
