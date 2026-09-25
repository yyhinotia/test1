class_name PawnStatusBars
extends Control

## 多资源条的组级容器：统一绑定、布局和自动隐藏计时。
## 子条只负责显示一个资源池；此容器不解释生命、护盾或灵力业务规则。

const DEFAULT_AUTO_HIDE_DELAY: float = 2.0

@export var auto_hide_delay: float = DEFAULT_AUTO_HIDE_DELAY

@onready var bars_container: VBoxContainer = $Bars
@onready var health_bar: ResourceBar = $Bars/HealthBar
@onready var shield_bar: ResourceBar = $Bars/ShieldBar
@onready var spirit_bar: ResourceBar = $Bars/SpiritBar

var _bars_by_id: Dictionary = {}
var _hide_countdown: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bars_by_id = {
		&"health": health_bar,
		&"shield": shield_bar,
		&"spirit": spirit_bar,
	}
	for bar: ResourceBar in _bars_by_id.values():
		bar.target_value_changed.connect(_handle_bar_target_value_changed)
	if auto_hide_delay <= 0.0:
		_update_bar_visibility()
	else:
		hide_now()

func _process(delta: float) -> void:
	tick(delta)

func bind_pool(resource_id: StringName, pool: ResourcePoolComponent) -> bool:
	var bar: ResourceBar = get_bar(resource_id)
	if bar == null or pool == null:
		return false
	bar.bind_pool(pool)
	_update_bar_visibility()
	return true

func unbind_pool(resource_id: StringName) -> bool:
	var bar: ResourceBar = get_bar(resource_id)
	if bar == null:
		return false
	bar.unbind_pool()
	_update_bar_visibility()
	return true

func get_bar(resource_id: StringName) -> ResourceBar:
	var bar: Variant = _bars_by_id.get(resource_id)
	return bar as ResourceBar

func has_valid_bars() -> bool:
	for bar: ResourceBar in _bars_by_id.values():
		if bar.has_valid_pool():
			return true
	return false

## 当前已成功绑定资源池的稳定资源 ID；用于装配验证和调试，不改变任何条状态。
func get_bound_resource_ids() -> Array[StringName]:
	var bound_ids: Array[StringName] = []
	for resource_id: StringName in _bars_by_id:
		var bar: ResourceBar = _bars_by_id[resource_id] as ResourceBar
		if bar != null and bar.has_pool():
			bound_ids.append(resource_id)
	return bound_ids

## 立即显示整组，并从此刻重新开始统一隐藏计时。
func reveal() -> void:
	_update_bar_visibility()
	if not has_valid_bars():
		hide_now()
		return

	visible = true
	if auto_hide_delay <= 0.0:
		_hide_countdown = 0.0
		set_process(false)
		return
	_hide_countdown = auto_hide_delay
	set_process(true)

func hide_now() -> void:
	visible = false
	_hide_countdown = 0.0
	set_process(false)

func tick(delta: float) -> void:
	if not visible or auto_hide_delay <= 0.0:
		return
	_hide_countdown = maxf(_hide_countdown - delta, 0.0)
	if _hide_countdown <= 0.0:
		hide_now()

func get_remaining_hide_time() -> float:
	return _hide_countdown

func is_hide_countdown_running() -> bool:
	return visible and auto_hide_delay > 0.0 and _hide_countdown > 0.0

func _handle_bar_target_value_changed(_current_value: float, _max_value: float) -> void:
	_update_bar_visibility()
	if has_valid_bars():
		reveal()

func _update_bar_visibility() -> void:
	var has_valid: bool = false
	for bar: ResourceBar in _bars_by_id.values():
		var bar_valid: bool = bar.has_valid_pool()
		bar.visible = bar_valid
		has_valid = has_valid or bar_valid
	bars_container.queue_sort()

	if not has_valid:
		hide_now()
	elif auto_hide_delay <= 0.0:
		visible = true
		set_process(false)
