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
@onready var health: HealthComponent = $HealthComponent
@onready var health_bar: PawnHealthBar = $HealthBarAnchor/HealthBar
@onready var selection_indicator: CanvasItem = $SelectionIndicator
@onready var controller: PawnController = $Controller

## 运行时生命数值由 `HealthComponent` 持有；这里只保留只读代理，
## 让 HUD、测试等既有调用方继续用 `pawn.current_health` 读取。
var current_health: float:
	get:
		return (health.current_health if health != null else 0.0)

var current_shield: float:
	get:
		return (health.current_shield if health != null else 0.0)

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
		# 保持配置错误时的旧行为：没有 PawnData 的单位视为生命为 0（已死亡），
		# 而不是把组件默认上限当成存活单位。
		health.configure(0.0, 0.0)
		return

	health.health_changed.connect(_on_health_changed)
	health.shield_changed.connect(_on_shield_changed)
	health.health_state_changed.connect(_on_health_state_changed)
	health.depleted.connect(_on_health_depleted)
	# 静默初始化：出生时不触发血条显示。
	health.configure(data.max_health, data.max_shield)

	visual.modulate = data.display_color
	health_bar.set_values(health.current_health, health.max_health, health.current_shield, health.max_shield)
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

## 伤害入口：先按 `data.defense` 结算，再把剩余伤害交给 HealthComponent。
## 组件负责“先护盾、后生命”的扣减与变化信号。
func take_damage(raw_attack: float) -> void:
	if is_dead():
		return

	var remaining_damage: float = maxf(1.0, raw_attack - data.defense)
	health.apply_damage(remaining_damage)

## 生命状态变化的统一入口：把组件里的最新数值转发给头顶血条。
## 伤害、护盾、治疗、死亡都会经由 `HealthComponent` 的信号走到这里。
func notify_health_state_changed() -> void:
	if health_bar == null or health == null:
		return
	health_bar.notify_health_state_changed(health.current_health, health.max_health, health.current_shield, health.max_shield)

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
	notify_health_state_changed()
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

## 以下转发保持 `INC-CROSS-001` 已验收的对外信号签名与发射顺序（先护盾、后生命）。
func _on_health_changed(current_value: float, max_value: float) -> void:
	health_changed.emit(self, current_value, max_value)

func _on_shield_changed(current_value: float, max_value: float) -> void:
	shield_changed.emit(self, current_value, max_value)

func _on_health_state_changed(_component: HealthComponent) -> void:
	notify_health_state_changed()

func _on_health_depleted(_component: HealthComponent) -> void:
	die()