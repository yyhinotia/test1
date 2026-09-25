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


## 目标进入任一主动技能距离且该技能可施放时优先使用；按列表顺序尝试，失败则继续普通移动/攻击流程。
## SELF 技能自动指向施法者；ALLY 尚无目标提供方时安全跳过，ENEMY 使用当前敌人目标。
func _try_cast_active_skill(distance_to_target: float) -> bool:
	if pawn == null or pawn.data == null:
		return false
	if _target == null or not is_instance_valid(_target) or not _target.is_alive():
		return false

	for skill: ActiveSkillDefinition in pawn.get_enabled_active_skills():
		var skill_target: Pawn = _target
		if skill.target_type == ActiveSkillDefinition.SkillTargetType.SELF:
			skill_target = pawn
		elif skill.target_type == ActiveSkillDefinition.SkillTargetType.ALLY:
			continue

		var cast_range: float = skill.get_effective_cast_range(pawn.data.attack_range)
		if skill_target != pawn and distance_to_target > cast_range:
			continue
		if not pawn.cast_skill(skill, skill_target):
			continue
		pawn.stop_moving()
		return true
	return false
