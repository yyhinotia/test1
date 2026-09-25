extends GdUnitTestSuite

## 单元层（纯逻辑）：ResourcePoolDefinition 的默认值、上限归一化与初始值计算。
## 这是“配置层”的唯一入口，池组件的上限与初始值全部由它推导。


func test_new_definition_uses_documented_defaults() -> void:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()

	assert_str(String(definition.resource_id)).is_equal("resource")
	assert_str(definition.display_name).is_equal("Resource")
	assert_float(definition.max_value).is_equal(100.0)
	assert_float(definition.initial_ratio).is_equal(1.0)
	assert_bool(definition.auto_regenerate).is_false()
	assert_int(definition.depleted_behavior).is_equal(ResourcePoolDefinition.DepletedBehavior.NONE)


## 负数上限必须归一化为 0，否则池组件会得到负上限并让 clamp 行为失真。
func test_normalized_max_value_never_goes_negative() -> void:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()

	definition.max_value = -25.0
	assert_float(definition.get_normalized_max_value()).is_zero()

	definition.max_value = 0.0
	assert_float(definition.get_normalized_max_value()).is_zero()

	definition.max_value = 42.5
	assert_float(definition.get_normalized_max_value()).is_equal(42.5)


func test_initial_value_scales_with_ratio() -> void:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()
	definition.max_value = 200.0

	definition.initial_ratio = 0.25
	assert_float(definition.get_initial_value()).is_equal_approx(50.0, 0.001)

	definition.initial_ratio = 0.0
	assert_float(definition.get_initial_value()).is_zero()

	definition.initial_ratio = 1.0
	assert_float(definition.get_initial_value()).is_equal_approx(200.0, 0.001)


## 比例超出 0..1 必须被截断，而不是外推出越界数值。
func test_initial_ratio_is_clamped_into_unit_range() -> void:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()
	definition.max_value = 200.0

	definition.initial_ratio = 1.75
	assert_float(definition.get_initial_value()).is_equal_approx(200.0, 0.001)

	definition.initial_ratio = -0.5
	assert_float(definition.get_initial_value()).is_zero()


## 上限为 0 的资源必须得到 0 初始值，而不是 NaN 或越界值。
func test_zero_max_definition_yields_zero_initial_value() -> void:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()

	definition.max_value = 0.0
	definition.initial_ratio = 1.0
	assert_float(definition.get_initial_value()).is_zero()

	definition.max_value = -10.0
	definition.initial_ratio = 0.5
	assert_float(definition.get_initial_value()).is_zero()
