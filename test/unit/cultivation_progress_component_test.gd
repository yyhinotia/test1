extends GdUnitTestSuite

## 单元层：修为进度组件的边界、信号与终点语义。
## 组件本身是 Node，但这里不加载场景；只验证“境界资源 + 运行时数值”的纯状态机契约。

const QI_REFINING_PATH: String = "res://game/cultivation/data/realms/qi_refining.tres"
const SPIRIT_TRANSFORMATION_PATH: String = "res://game/cultivation/data/realms/spirit_transformation.tres"
const APPROX: float = 0.0001


func _make_component() -> CultivationProgressComponent:
	var component: CultivationProgressComponent = CultivationProgressComponent.new()
	auto_free(component)
	return component


func _load_realm(path: String) -> RealmDefinition:
	return load(path) as RealmDefinition


func test_configure_reads_realm_chain_and_starting_exp() -> void:
	var component: CultivationProgressComponent = _make_component()
	component.configure(_load_realm(QI_REFINING_PATH), 72.0)

	assert_float(component.get_current_exp()).is_equal_approx(72.0, APPROX)
	assert_float(component.get_required_exp()).is_equal_approx(100.0, APPROX)
	assert_float(component.get_ratio()).is_equal_approx(0.72, APPROX)
	assert_bool(component.has_next_realm()).is_true()
	assert_bool(component.is_ready_for_breakthrough()).is_false()
	assert_str(String(component.get_next_realm().id)).is_equal("foundation_establishment")


func test_increase_clamps_at_threshold_and_emits_ready_once() -> void:
	var component: CultivationProgressComponent = _make_component()
	component.configure(_load_realm(QI_REFINING_PATH), 90.0)
	var progress_events: Array[Dictionary] = []
	var ready_events: Array[CultivationProgressComponent] = []
	component.progress_changed.connect(func(_component: CultivationProgressComponent, current_exp: float, required_exp: float, delta: float, source: StringName) -> void:
		progress_events.append({"current": current_exp, "required": required_exp, "delta": delta, "source": source})
	)
	component.became_ready.connect(func(ready_component: CultivationProgressComponent) -> void:
		ready_events.append(ready_component)
	)

	assert_float(component.increase(20.0, &"test_gain")).is_equal_approx(10.0, APPROX)
	assert_float(component.get_current_exp()).is_equal_approx(100.0, APPROX)
	assert_bool(component.is_ready_for_breakthrough()).is_true()
	assert_int(progress_events.size()).is_equal(1)
	assert_int(ready_events.size()).is_equal(1)
	assert_float(float(progress_events[0]["delta"])).is_equal_approx(10.0, APPROX)

	assert_float(component.increase(10.0, &"overflow")).is_zero()
	assert_int(progress_events.size()).is_equal(1)
	assert_int(ready_events.size()).is_equal(1)


func test_set_current_exp_rejects_invalid_values_and_reports_actual_delta() -> void:
	var component: CultivationProgressComponent = _make_component()
	component.configure(_load_realm(QI_REFINING_PATH), 0.0)

	assert_float(component.set_current_exp(-1.0)).is_zero()
	assert_float(component.get_current_exp()).is_zero()
	assert_float(component.set_current_exp(40.0)).is_equal_approx(40.0, APPROX)
	assert_float(component.set_current_exp(40.0)).is_zero()
	assert_float(component.set_current_exp(500.0)).is_equal_approx(60.0, APPROX)
	assert_float(component.get_current_exp()).is_equal_approx(100.0, APPROX)


func test_no_realm_and_terminal_realm_have_no_implicit_progress() -> void:
	var component: CultivationProgressComponent = _make_component()
	component.configure(null, 50.0)
	assert_bool(component.is_configured()).is_false()
	assert_bool(component.has_next_realm()).is_false()
	assert_float(component.get_required_exp()).is_zero()
	assert_float(component.get_current_exp()).is_zero()

	component.configure(_load_realm(SPIRIT_TRANSFORMATION_PATH), 50.0)
	assert_bool(component.is_configured()).is_true()
	assert_bool(component.has_next_realm()).is_false()
	assert_bool(component.is_ready_for_breakthrough()).is_false()
	assert_float(component.get_required_exp()).is_zero()
	assert_float(component.get_current_exp()).is_zero()


func test_configure_is_silent_and_snapshot_is_read_only_copy() -> void:
	var component: CultivationProgressComponent = _make_component()
	var progress_events: Array[Dictionary] = []
	component.progress_changed.connect(func(_component: CultivationProgressComponent, current_exp: float, required_exp: float, delta: float, source: StringName) -> void:
		progress_events.append({"current": current_exp, "required": required_exp, "delta": delta, "source": source})
	)
	component.configure(_load_realm(QI_REFINING_PATH), 25.0)
	assert_int(progress_events.size()).is_zero()

	var snapshot: Dictionary = component.get_snapshot()
	assert_float(float(snapshot["current_exp"])).is_equal_approx(25.0, APPROX)
	assert_float(float(snapshot["required_exp"])).is_equal_approx(100.0, APPROX)
	assert_float(float(snapshot["ratio"])).is_equal_approx(0.25, APPROX)
	assert_bool(bool(snapshot["has_next_realm"])).is_true()
	assert_str(String(snapshot["next_realm_name"])).is_equal("筑基")