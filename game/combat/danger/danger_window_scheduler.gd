class_name DangerWindowScheduler
extends RefCounted

## 危险技能窗口调度（INC-COMBAT-009）。
##
## 职责：按静态数据固定节奏打开窗口 → 玩家可感知 → 若施法者被眩晕则取消；
## 未被取消时释放危险技能。危险技能不进入 PawnData.active_skills，
## 因此 AIController 不会把它当普通技能施放，节奏只由 dangerous_skill + 两个时长字段决定。

signal danger_window_opened(caster: Pawn, skill: ActiveSkillDefinition, target: Pawn)
signal danger_window_cancelled_by_stun(caster: Pawn, skill: ActiveSkillDefinition, target: Pawn)
## 在效果真正结算前发出：EncounterSession 先记录 skill_cast 与 hit/blocked，再让伤害触发死亡，
## 这样「命中事件 → 单位死亡」的顺序不会因为 Pawn.died 的同步发射而颠倒。
signal dangerous_skill_released(caster: Pawn, skill: ActiveSkillDefinition, target: Pawn, blocked: bool)

var _caster: Pawn
var _target: Pawn
var _time_since_last_window: float = 0.0
var _window_open: bool = false
var _window_remaining: float = 0.0


func _init(p_caster: Pawn = null, p_target: Pawn = null) -> void:
	_caster = p_caster
	_target = p_target


func get_caster() -> Pawn:
	return _caster


func get_target() -> Pawn:
	return _target


func set_target(target: Pawn) -> void:
	_target = target


func get_skill() -> ActiveSkillDefinition:
	if _caster == null or _caster.data == null:
		return null
	return _caster.data.dangerous_skill


func is_configured() -> bool:
	return _caster != null and _caster.data != null and _caster.data.has_danger_window()


func is_window_open() -> bool:
	return _window_open


func get_window_remaining() -> float:
	return _window_remaining if _window_open else 0.0


func get_time_since_last_window() -> float:
	return _time_since_last_window


func advance(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta) or not is_configured():
		return
	if _caster.is_dead():
		return
	if _window_open:
		_advance_open_window(delta)
		return

	_time_since_last_window += delta
	if _time_since_last_window >= _caster.data.danger_window_interval:
		_open_window()


## 控制优先于计时：窗口内只要施法者处于眩晕，就先取消，即使本帧原本应当释放。
func _advance_open_window(delta: float) -> void:
	if _caster.is_stunned():
		_cancel_by_stun()
		return
	_window_remaining = maxf(_window_remaining - delta, 0.0)
	if _window_remaining <= 0.0:
		_release()


func _open_window() -> void:
	var skill: ActiveSkillDefinition = get_skill()
	if skill == null:
		return
	_window_open = true
	_window_remaining = _caster.data.danger_window_duration
	_time_since_last_window = 0.0
	_caster.set_danger_highlight(true)
	danger_window_opened.emit(_caster, skill, _target)


func _cancel_by_stun() -> void:
	var skill: ActiveSkillDefinition = get_skill()
	if not _window_open:
		return
	_window_open = false
	_window_remaining = 0.0
	_time_since_last_window = 0.0
	_caster.set_danger_highlight(false)
	if skill != null:
		danger_window_cancelled_by_stun.emit(_caster, skill, _target)


func _release() -> void:
	var skill: ActiveSkillDefinition = get_skill()
	if skill == null:
		_close_window()
		return
	var caster: Pawn = _caster
	var target: Pawn = _target
	_window_open = false
	_window_remaining = 0.0
	_time_since_last_window = 0.0
	caster.set_danger_highlight(false)
	var blocked: bool = _is_expected_blocked(caster, skill, target)
	dangerous_skill_released.emit(caster, skill, target, blocked)
	if target != null and is_instance_valid(target) and target.is_alive():
		SkillEffectResolver.apply_effect(caster, skill, target)


## 释放前按现有结算公式预判：防御后的伤害能否被当前护盾完整吸收。
## 预判只决定事件类型（skill_blocked / skill_hit），不改变实际结算路径。
func _is_expected_blocked(caster: Pawn, skill: ActiveSkillDefinition, target: Pawn) -> bool:
	if caster == null or skill == null or target == null or not is_instance_valid(target):
		return false
	if not target.is_alive() or target.data == null:
		return false
	if skill.effect_type != ActiveSkillDefinition.SkillEffectType.DAMAGE:
		return false
	var raw_damage: float = SkillEffectResolver.get_damage_amount(caster, skill)
	var post_defense: float = maxf(1.0, raw_damage - target.data.defense)
	return target.current_shield >= post_defense


func _close_window() -> void:
	_window_open = false
	_window_remaining = 0.0
