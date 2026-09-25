class_name AIController
extends PawnController

@export var activation_delay: float = 3.0

var _target: Pawn
var _elapsed: float = 0.0

func set_target(target: Pawn) -> void:
	_target = target
	_elapsed = 0.0

func update_controller(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _target.is_alive():
		_target = null
		if pawn.state == Pawn.State.MOVING:
			pawn.stop_moving()
		return

	_elapsed += delta
	if _elapsed < activation_delay:
		return

	var distance_to_target: float = pawn.global_position.distance_to(_target.global_position)
	if distance_to_target > pawn.data.attack_range:
		pawn.move_towards(_target.global_position)
		return

	pawn.stop_moving()
	pawn.try_attack(_target)
