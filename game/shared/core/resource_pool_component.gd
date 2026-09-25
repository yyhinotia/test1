class_name ResourcePoolComponent
extends Node

## 单个资源池的运行时数据源。
## 一个实例只管理一种资源；生命、护盾、灵力等业务语义不进入此组件。

signal value_changed(current_value: float, max_value: float, delta: float, source: StringName)
signal depleted(component: ResourcePoolComponent)
signal restored(component: ResourcePoolComponent)

@export var resource_definition: ResourcePoolDefinition

var _current_value: float = 0.0
var _max_value: float = 0.0
var _is_depleted: bool = true

var current_value: float:
	get:
		return _current_value

var max_value: float:
	get:
		return _max_value

func _ready() -> void:
	if resource_definition != null:
		configure(resource_definition)

## 静默初始化。initial_ratio_override >= 0 时覆盖定义中的初始比例。
func configure(definition: ResourcePoolDefinition, initial_ratio_override: float = -1.0) -> void:
	resource_definition = definition
	if definition == null:
		_max_value = 0.0
		_current_value = 0.0
	else:
		_max_value = definition.get_normalized_max_value()
		var initial_ratio: float = definition.initial_ratio
		if initial_ratio_override >= 0.0:
			initial_ratio = initial_ratio_override
		_current_value = _max_value * clampf(initial_ratio, 0.0, 1.0)
	_refresh_depleted_state()

## 静默恢复到定义的初始比例。上层业务若需要“恢复到满值”，应配置 initial_ratio = 1.0。
func reset() -> void:
	configure(resource_definition)

func increase(amount: float, source: StringName = &"") -> float:
	if not is_finite(amount) or amount <= 0.0:
		return 0.0
	return _set_bounded_value(_current_value + amount, source)

func decrease(amount: float, source: StringName = &"") -> float:
	if not is_finite(amount) or amount <= 0.0:
		return 0.0
	return _set_bounded_value(_current_value - amount, source)

## 原子消耗：余额不足时返回 false，且不产生任何数值或信号变化。
func try_spend(amount: float, source: StringName = &"spend") -> bool:
	if not is_finite(amount) or amount <= 0.0 or _current_value < amount:
		return false
	return decrease(amount, source) > 0.0

func set_value(new_value: float, source: StringName = &"set") -> float:
	if not is_finite(new_value):
		return 0.0
	return _set_bounded_value(new_value, source)

func get_ratio() -> float:
	if _max_value <= 0.0:
		return 0.0
	return clampf(_current_value / _max_value, 0.0, 1.0)

func is_depleted() -> bool:
	return _is_depleted

func get_resource_id() -> StringName:
	if resource_definition == null:
		return &""
	return resource_definition.resource_id

func _set_bounded_value(new_value: float, source: StringName) -> float:
	var bounded_value: float = clampf(new_value, 0.0, _max_value)
	if is_equal_approx(bounded_value, _current_value):
		return 0.0

	var previous_value: float = _current_value
	_current_value = bounded_value
	var delta: float = _current_value - previous_value
	value_changed.emit(_current_value, _max_value, delta, source)
	_update_depleted_state()
	return absf(delta)

func _refresh_depleted_state() -> void:
	_is_depleted = _current_value <= 0.0

func _update_depleted_state() -> void:
	var now_depleted: bool = _current_value <= 0.0
	if now_depleted == _is_depleted:
		return
	_is_depleted = now_depleted
	if now_depleted:
		depleted.emit(self)
	else:
		restored.emit(self)
