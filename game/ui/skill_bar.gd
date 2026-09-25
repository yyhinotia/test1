class_name SkillBar
extends HBoxContainer

## 动态技能栏：槽位数量由 Pawn 当前境界的主动技能容量决定，已配置技能由 SkillSlot 渲染。
## SkillBar 只转发点击请求，不执行施法、不扣除灵力、不推进冷却。

signal skill_requested(skill: ActiveSkillDefinition)
## 需要目标的技能不直接请求施法，而是先进入 TARGETING；目标由主场景输入路由提供。
signal targeting_started(skill: ActiveSkillDefinition)
signal targeting_cancelled()

const SLOT_SCENE_PATH: String = "res://game/ui/skill_slot.tscn"
const MAX_SLOTS: int = 6

var _pawn: Pawn
var _slots: Array[SkillSlot] = []
var _targeting_skill: ActiveSkillDefinition

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(0.0, SkillSlot.SLOT_SIZE)
	visible = false

func bind_pawn(pawn: Pawn) -> void:
	if _pawn == pawn and pawn != null:
		refresh()
		return
	# 绑定对象切换时旧瞄准必然失效，先回到 NORMAL 再重建槽位。
	cancel_targeting()
	_disconnect_pawn_signals()
	_pawn = pawn
	_connect_pawn_signals()
	refresh()

func unbind() -> void:
	cancel_targeting()
	_disconnect_pawn_signals()
	_pawn = null
	_clear_slots()
	visible = false

func get_bound_pawn() -> Pawn:
	return _pawn

func get_slots() -> Array[SkillSlot]:
	return _slots.duplicate()

func get_slot_count() -> int:
	return _slots.size()

func is_targeting() -> bool:
	return _targeting_skill != null


func get_targeting_skill() -> ActiveSkillDefinition:
	return _targeting_skill


## 点击槽位的唯一入口：SELF 技能不需要玩家再点目标，其余技能进入 TARGETING。
## 本方法只发请求信号与改自身交互状态，绝不施法、扣灵力或推进冷却。
func request_skill(skill: ActiveSkillDefinition) -> bool:
	if skill == null or not skill.is_configured():
		return false
	if _pawn != null and not _is_enabled_skill(skill):
		return false
	if skill.target_type == ActiveSkillDefinition.SkillTargetType.SELF:
		cancel_targeting()
		skill_requested.emit(skill)
		return true
	return begin_targeting(skill)


## 进入目标选择：同一时间只允许一个技能处于 TARGETING。
func begin_targeting(skill: ActiveSkillDefinition) -> bool:
	if skill == null or not skill.is_configured():
		return false
	if _pawn != null and not _is_enabled_skill(skill):
		return false
	_targeting_skill = skill
	_apply_interaction_states()
	targeting_started.emit(skill)
	return true


## 取消目标选择；没有进行中的瞄准时返回 false 且不发信号。
func cancel_targeting() -> bool:
	if _targeting_skill == null:
		return false
	_targeting_skill = null
	_apply_interaction_states()
	targeting_cancelled.emit()
	return true


## 交互状态只落在槽位自身；可施放状态仍由每个 SkillSlot 的读模型决定。
func _apply_interaction_states() -> void:
	for slot: SkillSlot in _slots:
		if slot == null or not is_instance_valid(slot):
			continue
		var is_targeting_slot: bool = _targeting_skill != null and slot.get_skill() == _targeting_skill
		slot.set_interaction_state(
			SkillSlot.InteractionState.TARGETING if is_targeting_slot else SkillSlot.InteractionState.NORMAL
		)

## 只读刷新：境界容量与技能列表决定槽位；冷却、灵力与死亡状态由每个 SkillSlot 自行读取。
func refresh() -> void:
	if _pawn == null or not is_instance_valid(_pawn) or _pawn.data == null:
		_clear_slots()
		visible = false
		return
	visible = true
	# 技能列表或容量变化后原瞄准对象可能已失效，必须自动取消并清掉 TARGETING。
	if _targeting_skill != null and not _is_enabled_skill(_targeting_skill):
		cancel_targeting()
	# 超容量技能仍保留槽位以便显示 DISABLED；无境界时容量哨兵按 0 槽参与布局。
	var capacity: int = maxi(_pawn.get_active_skill_capacity(), 0)
	# 技能栏读的是运行时装配结果：重配后槽位内容必须立刻跟随，且不回退到 PawnData。
	var skills: Array[ActiveSkillDefinition] = _pawn.get_equipped_active_skills()
	var count: int = clampi(maxi(capacity, skills.size()), 0, MAX_SLOTS)
	_ensure_slot_count(count)
	for index: int in count:
		var slot: SkillSlot = _slots[index]
		if index < skills.size():
			slot.bind_skill(_pawn, skills[index], str(index + 1))
		else:
			slot.show_empty(str(index + 1))

## 瞄准对象必须仍属于当前 Pawn 已掌握技能列表，避免 UI 用任意资源绕过 Build 配置。
func _is_known_skill(skill: ActiveSkillDefinition) -> bool:
	if skill == null or _pawn == null:
		return false
	return _pawn.is_active_skill_known(skill)


## 瞄准对象必须同时属于完整技能列表且位于当前容量投影内。
func _is_enabled_skill(skill: ActiveSkillDefinition) -> bool:
	return _is_known_skill(skill) and _pawn != null and _pawn.is_active_skill_enabled(skill)


func _ensure_slot_count(count: int) -> void:
	while _slots.size() < count:
		var scene: PackedScene = load(SLOT_SCENE_PATH)
		var slot: SkillSlot = scene.instantiate() as SkillSlot
		add_child(slot)
		slot.cast_requested.connect(_on_slot_cast_requested)
		_slots.append(slot)
	while _slots.size() > count:
		var removed: SkillSlot = _slots.pop_back()
		if removed != null:
			remove_child(removed)
			removed.free()

func _clear_slots() -> void:
	for slot: SkillSlot in _slots:
		if slot != null and is_instance_valid(slot):
			remove_child(slot)
			slot.free()
	_slots.clear()

func _on_slot_cast_requested(skill: ActiveSkillDefinition) -> void:
	request_skill(skill)

func _connect_pawn_signals() -> void:
	if _pawn == null:
		return
	_connect_signal(_pawn.spirit_changed, _on_spirit_changed)
	_connect_signal(_pawn.skill_cooldown_changed, _on_skill_cooldown_changed)
	_connect_signal(_pawn.skill_cast, _on_skill_cast)
	_connect_signal(_pawn.died, _on_died)
	_connect_signal(_pawn.state_changed, _on_state_changed)
	# 运行时解锁 / 重配只广播 Pawn 自己的 build_changed，技能栏必须据此重建槽位。
	_connect_signal(_pawn.build_changed, _on_runtime_build_changed)
	if _pawn.data != null:
		_connect_signal(_pawn.data.build_changed, _on_data_changed)
		_connect_signal(_pawn.data.realm_changed, _on_data_changed)

func _disconnect_pawn_signals() -> void:
	if _pawn == null or not is_instance_valid(_pawn):
		return
	_disconnect_signal(_pawn.spirit_changed, _on_spirit_changed)
	_disconnect_signal(_pawn.skill_cooldown_changed, _on_skill_cooldown_changed)
	_disconnect_signal(_pawn.skill_cast, _on_skill_cast)
	_disconnect_signal(_pawn.died, _on_died)
	_disconnect_signal(_pawn.state_changed, _on_state_changed)
	_disconnect_signal(_pawn.build_changed, _on_runtime_build_changed)
	if _pawn.data != null:
		_disconnect_signal(_pawn.data.build_changed, _on_data_changed)
		_disconnect_signal(_pawn.data.realm_changed, _on_data_changed)

func _connect_signal(source: Signal, target: Callable) -> void:
	if not source.is_connected(target):
		source.connect(target)

func _disconnect_signal(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		source.disconnect(target)

func _on_spirit_changed(_changed_pawn: Pawn, _current: float, _max_value: float) -> void:
	refresh()

func _on_skill_cooldown_changed(_changed_pawn: Pawn, _skill_id: StringName, _remaining: float) -> void:
	refresh()

func _on_skill_cast(_changed_pawn: Pawn, _skill: ActiveSkillDefinition, _target: Pawn) -> void:
	refresh()

func _on_died(_changed_pawn: Pawn) -> void:
	refresh()

func _on_state_changed(_changed_pawn: Pawn, _new_state: int) -> void:
	refresh()

func _on_data_changed(_data: PawnData) -> void:
	refresh()

func _on_runtime_build_changed(_changed_pawn: Pawn) -> void:
	refresh()
