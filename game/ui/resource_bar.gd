class_name ResourceBar
extends Control

## 单个资源池的通用条状显示组件。
## 真实数值由 ResourcePoolComponent 驱动；延迟减少只改变 displayed_value，不回写业务数值。

signal target_value_changed(current_value: float, max_value: float)
signal drain_finished()

const DEFAULT_DRAIN_DELAY: float = 0.2
const DEFAULT_DRAIN_DURATION: float = 0.4

@export var background_color: Color = Color(0.08, 0.08, 0.10, 0.92)
@export var fill_color: Color = Color(0.25, 0.88, 0.42, 1.0)
@export var border_color: Color = Color(0.0, 0.0, 0.0, 0.95)
@export var delayed_drain_delay: float = DEFAULT_DRAIN_DELAY
@export var delayed_drain_duration: float = DEFAULT_DRAIN_DURATION

var _pool: ResourcePoolComponent
var _target_value: float = 0.0
var _displayed_value: float = 0.0
var _drain_start_value: float = 0.0
var _drain_delay_remaining: float = 0.0
var _drain_elapsed: float = 0.0
var _draining: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_visibility_from_pool()
	queue_redraw()

func _process(delta: float) -> void:
	tick(delta)

func bind_pool(pool: ResourcePoolComponent) -> void:
	if _pool == pool:
		return
	_disconnect_pool()
	_pool = pool
	_stop_drain()
	if _pool == null:
		_target_value = 0.0
		_displayed_value = 0.0
	else:
		_pool.value_changed.connect(_handle_pool_value_changed)
		_target_value = _pool.current_value
		_displayed_value = _target_value
	_refresh_visibility_from_pool()
	queue_redraw()

func unbind_pool() -> void:
	bind_pool(null)

func has_pool() -> bool:
	return _pool != null

func has_valid_pool() -> bool:
	return _pool != null and _pool.max_value > 0.0

func get_target_value() -> float:
	return _target_value

func get_displayed_value() -> float:
	return _displayed_value

func get_target_ratio() -> float:
	if not has_valid_pool():
		return 0.0
	return clampf(_target_value / _pool.max_value, 0.0, 1.0)

func get_displayed_ratio() -> float:
	if not has_valid_pool():
		return 0.0
	return clampf(_displayed_value / _pool.max_value, 0.0, 1.0)

func is_draining() -> bool:
	return _draining

## 立即把显示值对齐到真实目标值，不发出 drain_finished。
func snap_to_target() -> void:
	_displayed_value = _target_value
	_stop_drain()
	queue_redraw()

## 公开 tick 便于测试确定性推进延迟追赶；_process 只是调用此方法。
func tick(delta: float) -> void:
	if not _draining or delta <= 0.0:
		return

	var remaining_delta: float = delta
	if _drain_delay_remaining > 0.0:
		var consumed_delay: float = minf(_drain_delay_remaining, remaining_delta)
		_drain_delay_remaining -= consumed_delay
		remaining_delta -= consumed_delay
		if _drain_delay_remaining > 0.0:
			return

	_drain_elapsed += remaining_delta
	if delayed_drain_duration <= 0.0:
		_finish_drain()
		return

	var progress: float = clampf(_drain_elapsed / delayed_drain_duration, 0.0, 1.0)
	_displayed_value = lerpf(_drain_start_value, _target_value, progress)
	queue_redraw()
	if progress >= 1.0:
		_finish_drain()

func _handle_pool_value_changed(current_value: float, _max_value: float, delta: float, _source: StringName) -> void:
	if _pool == null:
		return
	_target_value = clampf(current_value, 0.0, _pool.max_value)
	if not has_valid_pool():
		_displayed_value = 0.0
		_stop_drain()
	elif delta >= 0.0 or delayed_drain_duration <= 0.0 or _target_value >= _displayed_value:
		_displayed_value = _target_value
		_stop_drain()
	else:
		_begin_drain(_displayed_value)
	_refresh_visibility_from_pool()
	target_value_changed.emit(_target_value, _pool.max_value)
	queue_redraw()

func _begin_drain(from_value: float) -> void:
	_drain_start_value = from_value
	_drain_elapsed = 0.0
	_drain_delay_remaining = maxf(delayed_drain_delay, 0.0)
	_draining = true
	set_process(true)

func _finish_drain() -> void:
	_displayed_value = _target_value
	_stop_drain()
	queue_redraw()
	drain_finished.emit()

func _stop_drain() -> void:
	_draining = false
	_drain_elapsed = 0.0
	_drain_delay_remaining = 0.0
	set_process(false)

func _refresh_visibility_from_pool() -> void:
	visible = has_valid_pool()

func _disconnect_pool() -> void:
	if _pool != null and is_instance_valid(_pool) and _pool.value_changed.is_connected(_handle_pool_value_changed):
		_pool.value_changed.disconnect(_handle_pool_value_changed)
	_pool = null

func _draw() -> void:
	var bar_size: Vector2 = Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	draw_rect(Rect2(Vector2.ZERO, bar_size), background_color)
	if has_valid_pool():
		var fill_ratio: float = get_displayed_ratio()
		if fill_ratio > 0.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(bar_size.x * fill_ratio, bar_size.y)), fill_color)
	draw_rect(Rect2(Vector2.ZERO, bar_size), border_color, false, 1.0)
