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
	if _try_cast_active_skill(distance_to_target):
		return
	if distance_to_target > pawn.data.attack_range:
		pawn.move_towards(_target.global_position)
		return

	pawn.stop_moving()
	pawn.try_attack(_target)


## 目标进入技能距离且技能已就绪时优先施放一次主动技能；失败则继续普通移动/攻击流程。
func _try_cast_active_skill(distance_to_target: float) -> bool:
	if pawn == null or pawn.data == null or pawn.data.active_skill == null:
		return false
	if _target == null or not is_instance_valid(_target) or not _target.is_alive():
		return false

	var skill: ActiveSkillDefinition = pawn.data.active_skill
	if distance_to_target > skill.get_effective_cast_range(pawn.data.attack_range):
		return false
	if not pawn.cast_skill(skill, _target):
		return false

	pawn.stop_moving()
	return true