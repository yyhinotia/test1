class_name ArenaBackdrop
extends Node2D

@export var arena_size: Vector2 = Vector2(1072.0, 568.0)
@export var grid_step: int = 48
@export var background_color: Color = Color(0.055, 0.075, 0.085, 1.0)
@export var grid_color: Color = Color(0.16, 0.24, 0.24, 1.0)
@export var border_color: Color = Color(0.36, 0.55, 0.50, 1.0)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, arena_size), background_color)

	var x: float = 0.0
	while x <= arena_size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, arena_size.y), grid_color, 1.0)
		x += float(grid_step)

	var y: float = 0.0
	while y <= arena_size.y:
		draw_line(Vector2(0.0, y), Vector2(arena_size.x, y), grid_color, 1.0)
		y += float(grid_step)

	draw_rect(Rect2(Vector2.ZERO, arena_size), border_color, false, 2.0)