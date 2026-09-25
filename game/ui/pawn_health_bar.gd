class_name PawnHealthBar
extends Control

@export var background_color: Color = Color(0.08, 0.08, 0.10, 0.92)
@export var health_color: Color = Color(0.25, 0.88, 0.42, 1.0)
@export var shield_color: Color = Color(0.25, 0.78, 1.0, 1.0)
@export var border_color: Color = Color(0.0, 0.0, 0.0, 0.95)

var _current_health: float = 0.0
var _max_health: float = 1.0
var _current_shield: float = 0.0
var _max_shield: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_values(current_health: float, max_health: float, current_shield: float, max_shield: float) -> void:
	_current_health = maxf(current_health, 0.0)
	_max_health = maxf(max_health, 1.0)
	_current_shield = maxf(current_shield, 0.0)
	_max_shield = maxf(max_shield, 0.0)
	queue_redraw()

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