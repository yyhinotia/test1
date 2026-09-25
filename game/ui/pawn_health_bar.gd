class_name PawnHealthBar
extends Control

## 战场血条显示策略：
## 默认保持隐藏，只在生命状态发生变化时立即显示；
## 最后一次变化之后 auto_hide_delay 秒内没有新变化，就自动隐藏（MVP 不做渐隐）。
const DEFAULT_AUTO_HIDE_DELAY: float = 2.0

@export var background_color: Color = Color(0.08, 0.08, 0.10, 0.92)
@export var health_color: Color = Color(0.25, 0.88, 0.42, 1.0)
@export var shield_color: Color = Color(0.25, 0.78, 1.0, 1.0)
@export var border_color: Color = Color(0.0, 0.0, 0.0, 0.95)
## 最后一次生命状态变化之后保持可见的秒数；<= 0 表示常驻显示、不做自动隐藏。
@export var auto_hide_delay: float = DEFAULT_AUTO_HIDE_DELAY

var _current_health: float = 0.0
var _max_health: float = 1.0
var _current_shield: float = 0.0
var _max_shield: float = 0.0
var _hide_countdown: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if auto_hide_delay <= 0.0:
		visible = true
		set_process(false)
	else:
		hide_now()
	queue_redraw()

func _process(delta: float) -> void:
	tick(delta)

## 只刷新数值，不改变可见性：用于初始化或没有事件来源的同步。
func set_values(current_health: float, max_health: float, current_shield: float, max_shield: float) -> void:
	_current_health = maxf(current_health, 0.0)
	_max_health = maxf(max_health, 1.0)
	_current_shield = maxf(current_shield, 0.0)
	_max_shield = maxf(max_shield, 0.0)
	queue_redraw()

## 生命状态变化统一入口：刷新数值、本帧显示，并重置隐藏计时。
## 伤害、护盾变化、治疗、死亡等都应该走这个入口，而不是只针对掉血。
func notify_health_state_changed(current_health: float, max_health: float, current_shield: float, max_shield: float) -> void:
	set_values(current_health, max_health, current_shield, max_shield)
	reveal()

## 立即显示血条，并重新开始隐藏计时。
func reveal() -> void:
	visible = true
	if auto_hide_delay <= 0.0:
		_hide_countdown = 0.0
		set_process(false)
		return
	_hide_countdown = auto_hide_delay
	set_process(true)

## 立即隐藏血条，不等待计时结束。
func hide_now() -> void:
	visible = false
	_hide_countdown = 0.0
	set_process(false)

## 推进隐藏计时；拆成公开方法便于 headless 测试确定性地推进时间。
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

func _draw() -> void:
	var bar_width: float = maxf(size.x, 1.0)
	var bar_height: float = maxf(size.y, 1.0)
	var shield_height: float = 4.0 if _max_shield > 0.0 else 0.0
	var gap: float = 2.0 if shield_height > 0.0 else 0.0
	var health_y: float = shield_height + gap
	var health_height: float = maxf(bar_height - health_y, 1.0)

	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width, bar_height)), background_color)

	if shield_height > 0.0:
		var shield_ratio: float = clampf(_current_shield / _max_shield, 0.0, 1.0)
		if shield_ratio > 0.0:
			draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width * shield_ratio, shield_height)), shield_color)

	var health_ratio: float = clampf(_current_health / _max_health, 0.0, 1.0)
	if health_ratio > 0.0:
		draw_rect(Rect2(Vector2(0.0, health_y), Vector2(bar_width * health_ratio, health_height)), health_color)

	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width, bar_height)), border_color, false, 1.0)