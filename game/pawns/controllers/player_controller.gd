class_name PlayerController
extends PawnController

var _attack_target: Pawn
var _move_target: Vector2 = Vector2.ZERO
var _has_move_order: bool = false

func order_move(target_position: Vector2) -> void:
	_attack_target = null
	_move_target = target_position
	_has_move_order = true

func order_attack(target: Pawn) -> void:
	if target == null or not target.is_alive():
		return
	_attack_target = target
	_has_move_order = false

func clear_orders() -> void:
	_attack_target = null
	_has_move_order = false

func get_order_description() -> String:
	if _attack_target != null and is_instance_valid(_attack_target) and _attack_target.is_alive():
		return "攻击 %s" % _attack_target.data.display_name
	if _has_move_order:
		return "移动到 (%.0f, %.0f)" % [_move_target.x, _move_target.y]
	return "待命"

func update_controller(_delta: float) -> void:
	if _attack_target != null and (not is_instance_valid(_attack_target) or not _attack_target.is_alive()):
		_attack_target = null

	if _attack_target != null:
		_tick_attack_order()
		return

	if _has_move_order:
		_tick_move_order()
		return

	if pawn.state == Pawn.State.MOVING:
		pawn.stop_moving()

func _tick_attack_order() -> void:
	var distance_to_target: float = pawn.global_position.distance_to(_attack_target.global_position)
	if distance_to_target > pawn.data.attack_range:
		pawn.move_towards(_attack_target.global_position)
		return

	pawn.stop_moving()
	pawn.try_attack(_attack_target)

func _tick_move_order() -> void:
	var distance_to_destination: float = pawn.global_position.distance_to(_move_target)
	if distance_to_destination <= 3.0:
		_has_move_order = false
		pawn.stop_moving()
		return
	pawn.move_towards(_move_target)