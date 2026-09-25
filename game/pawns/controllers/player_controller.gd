class_name PlayerController
extends PawnController

## 玩家 Pawn 的 RTS 指令控制器：移动、普通攻击与一次主动技能命令共用同一目标。
## 本类不读取输入、不写 HUD，只暴露可测试的命令 API；键位映射与文案由主场景负责。

var _attack_target: Pawn
var _move_target: Vector2 = Vector2.ZERO
var _has_move_order: bool = false
var _skill_target: Pawn
var _ordered_skill: ActiveSkillDefinition
var _has_skill_order: bool = false

func order_move(target_position: Vector2) -> void:
	_attack_target = null
	_clear_skill_order()
	_move_target = target_position
	_has_move_order = true

func order_attack(target: Pawn) -> void:
	if target == null or not target.is_alive():
		return
	_attack_target = target
	_has_move_order = false
	_clear_skill_order()

## 旧入口：默认下达第一个主动技能；未传目标时沿用当前攻击目标。
func order_skill(target: Pawn = null) -> bool:
	return order_skill_instance(_get_active_skill(), target)

## 按具体技能实例下达一次主动技能命令。
## 技能必须来自 Pawn 当前生效的技能列表；无技能、无效目标时返回 false，且不修改既有指令与资源数值。
func order_skill_instance(skill: ActiveSkillDefinition, target: Pawn = null) -> bool:
	if not _is_known_skill(skill):
		return false
	# 超容量技能与未知技能一样必须零副作用拒绝；不得改写既有攻击/移动/技能命令。
	if not pawn.is_active_skill_enabled(skill):
		return false
	var resolved_target: Pawn = _resolve_skill_target(skill, target)
	if resolved_target == null or pawn == null or not pawn.is_valid_skill_target(skill, resolved_target):
		return false

	_ordered_skill = skill
	_skill_target = resolved_target
	_has_skill_order = true
	# 敌方技能结束后继续追击同一敌人；友方/自身技能不覆盖既有普通攻击目标。
	if skill.target_type == ActiveSkillDefinition.SkillTargetType.ENEMY:
		_attack_target = resolved_target
	_has_move_order = false
	return true

func clear_orders() -> void:
	_attack_target = null
	_has_move_order = false
	_clear_skill_order()

func get_order_description() -> String:
	if _has_skill_order and pawn != null and _is_valid_skill_target(_skill_target, _get_ordered_skill()):
		var skill: ActiveSkillDefinition = _get_ordered_skill()
		if skill != null:
			if skill.target_type == ActiveSkillDefinition.SkillTargetType.SELF:
				return "施放技能 %s → 自身" % skill.display_name
			return "施放技能 %s → %s" % [skill.display_name, _skill_target.data.display_name]
	if _attack_target != null and is_instance_valid(_attack_target) and _attack_target.is_alive():
		return "攻击 %s" % _attack_target.data.display_name
	if _has_move_order:
		return "移动到 (%.0f, %.0f)" % [_move_target.x, _move_target.y]
	return "待命"

func update_controller(_delta: float) -> void:
	if _attack_target != null and (not is_instance_valid(_attack_target) or not _attack_target.is_alive()):
		_attack_target = null
	# 容量变化后旧技能命令必须先失效，不能继续瞄准或替换成其它技能。
	if _has_skill_order and (_ordered_skill == null or not pawn.is_active_skill_enabled(_ordered_skill)):
		_clear_skill_order()
	# 技能目标死亡、失效或切阵营时必须在产生任何副作用前失效，并回退到普通攻击。
	if _has_skill_order and not _is_valid_skill_target(_skill_target, _get_ordered_skill()):
		_clear_skill_order()

	if _has_skill_order:
		_tick_skill_order()
		return

	if _attack_target != null:
		_tick_attack_order()
		return

	if _has_move_order:
		_tick_move_order()
		return

	if pawn.state == Pawn.State.MOVING:
		pawn.stop_moving()

## 技能命令优先于普通攻击：先接近到技能距离，再交回 Pawn 统一裁决灵力、冷却与目标合法性。
func _tick_skill_order() -> void:
	var skill: ActiveSkillDefinition = _get_ordered_skill()
	if skill == null:
		_clear_skill_order()
		return

	var cast_range: float = skill.get_effective_cast_range(pawn.data.attack_range)
	if pawn.global_position.distance_to(_skill_target.global_position) > cast_range:
		pawn.move_towards(_skill_target.global_position)
		return

	pawn.stop_moving()
	if pawn.cast_skill(skill, _skill_target):
		_clear_skill_order()
		return
	# 灵力不足或冷却中：清除技能命令，保留普通攻击目标以便下一帧继续接近/攻击。
	_clear_skill_order()

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

func _get_active_skill() -> ActiveSkillDefinition:
	if pawn == null or pawn.data == null:
		return null
	var enabled: Array[ActiveSkillDefinition] = pawn.get_enabled_active_skills()
	return enabled[0] if not enabled.is_empty() else null

## 技能命令优先使用下达时记录的具体技能；若引用失效则回退到第一个技能。
func _get_ordered_skill() -> ActiveSkillDefinition:
	if _ordered_skill != null and _is_known_skill(_ordered_skill) and pawn != null and pawn.is_active_skill_enabled(_ordered_skill):
		return _ordered_skill
	return _get_active_skill()

## 只接受当前 Pawn 生效技能列表中的实例，避免 UI 用任意资源绕过 Build 配置。
func _is_known_skill(skill: ActiveSkillDefinition) -> bool:
	if skill == null or pawn == null or pawn.data == null:
		return false
	for candidate: ActiveSkillDefinition in pawn.data.get_active_skills():
		if candidate == skill:
			return true
	return false

## 目标解析只处理“未显式传入目标”的默认值；最终合法性仍由 Pawn 按技能目标类型裁决。
func _resolve_skill_target(skill: ActiveSkillDefinition, target: Pawn) -> Pawn:
	if skill == null or pawn == null:
		return null
	match skill.target_type:
		ActiveSkillDefinition.SkillTargetType.SELF:
			if target == null or target == pawn:
				return pawn
			return null
		ActiveSkillDefinition.SkillTargetType.ALLY:
			return target if target != null else null
		ActiveSkillDefinition.SkillTargetType.ENEMY:
			return target if target != null else _attack_target
		_:
			return null

## 兼容旧入口的只读目标判断；新技能应优先使用 Pawn.is_valid_skill_target()。
func _is_valid_skill_target(target: Pawn, skill: ActiveSkillDefinition) -> bool:
	return pawn != null and pawn.is_valid_skill_target(skill, target)

func _clear_skill_order() -> void:
	_skill_target = null
	_ordered_skill = null
	_has_skill_order = false