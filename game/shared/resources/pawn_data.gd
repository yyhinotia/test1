class_name PawnData
extends Resource

## Static configuration for a Pawn. Runtime values must stay on Pawn itself.
@export var id: StringName = &"pawn_000"
@export var display_name: String = "Pawn"
@export var faction: StringName = &"neutral"
@export var max_health: float = 100.0
@export var max_shield: float = 0.0
@export var attack: float = 10.0
@export var defense: float = 0.0
@export var move_speed: float = 100.0
@export var attack_range: float = 48.0
@export var attack_interval: float = 1.0
@export var display_color: Color = Color(0.85, 0.85, 0.85, 1.0)