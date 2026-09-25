class_name Pawn
extends CharacterBody2D

signal health_changed(pawn: Pawn, current_health: float, max_health: float)
signal shield_changed(pawn: Pawn, current_shield: float, max_shield: float)
signal state_changed(pawn: Pawn, new_state: int)
signal attack_performed(target: Pawn)
signal died(pawn: Pawn)

enum State {
	IDLE,
	MOVING,
	ATTACKING,
	DEAD,
}

@export var data: PawnData

@onready var visual: Sprite2D = $Visual/Sprite2D
@onready var collision_shape: CollisionShape2D = $Collision/CollisionShape2D
@onready var health_bar: PawnHealthBar = $HealthBar
@onready var selection_indicator: CanvasItem = $SelectionIndicator
@onready var controller: PawnController = $Controller

var current_health: float = 0.0
var current_shield: float = 0.0

var _state: int = State.IDLE
var _attack_cooldown: float = 0.0
var _attack_state_remaining: float = 0.0
var _visual_tween: Tween
var _selected: bool = false

var state: int:
	get:
		return _state

func _ready() -> void:
	if data == null:
		push_error("Pawn requires a PawnData resource: %s" % get_path())
		return

	current_health = data.max_health
	current_shield = data.max_shield
	visual.modulate = data.display_color
	health_bar.set_values(current_health, data.max_health, current_shield, data.max_shield)
	set_selected(false)
	_set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	if is_dead():
		return

	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_state_remaining > 0.0:
		_attack_state_remaining = maxf(_attack_state_remaining - delta, 0.0)
		if _attack_state_remaining <= 0.0 and _state == State.ATTACKING:
			_set_state(State.IDLE)

func get_controller() -> PawnController:
	return controller

func is_alive() -> bool:
	return _state != State.DEAD and current_health > 0.0

func is_dead() -> bool:
	return not is_alive()

func can_move() -> bool:
	return is_alive()

func can_attack() -> bool:
	return is_alive() and _attack_cooldown <= 0.0

func move_towards(target_position: Vector2) -> void:
	if not can_move():
		stop_moving()
		return

	var direction: Vector2 = target_position - global_position
	if direction.length_squared() <= 4.0:
		stop_moving()
		return

	velocity = direction.normalized() * data.move_speed
	_attack_state_remaining = 0.0
	_set_state(State.MOVING)
	move_and_slide()

func stop_moving() -> void:
	velocity = Vector2.ZERO
	if _state == State.MOVING:
		_set_state(State.IDLE)

func try_attack(target: Pawn) -> bool:
	if not can_attack() or target == null or not target.is_alive():
		return false

	if global_position.distance_to(target.global_position) > data.attack_range:
		return false

	_attack_cooldown = data.attack_interval
	_attack_state_remaining = minf(0.18, data.attack_interval * 0.5)
	_set_state(State.ATTACKING)
	target.take_damage(data.attack)
	attack_performed.emit(target)
	_play_attack_pulse()
	return true

func take_damage(raw_attack: float) -> void:
	if is_dead():
		return

	var remaining_damage: float = maxf(1.0, raw_attack - data.defense)

	if current_shield > 0.0:
		var absorbed: float = minf(current_shield, remaining_damage)
		current_shield -= absorbed
		remaining_damage -= absorbed
		shield_changed.emit(self, current_shield, data.max_shield)

	if remaining_damage > 0.0:
		current_health = maxf(current_health - remaining_damage, 0.0)
		health_changed.emit(self, current_health, data.max_health)

	if current_health <= 0.0:
		die()

func die() -> void:
	if _state == State.DEAD:
		return

	velocity = Vector2.ZERO
	set_selected(false)
	_set_state(State.DEAD)
	collision_shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	visual.modulate = Color(0.35, 0.35, 0.38, 0.72)
	health_bar.queue_redraw()
	died.emit(self)

func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	selection_indicator.visible = _selected

func get_state_label() -> String:
	match _state:
		State.IDLE:
			return "待命"
		State.MOVING:
			return "移动"
		State.ATTACKING:
			return "攻击"
		State.DEAD:
			return "死亡"
		_:
			return "未知"

func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(self, _state)

func _play_attack_pulse() -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	visual.scale = Vector2(1.18, 1.18)
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_QUAD)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(visual, "scale", Vector2.ONE, 0.14)