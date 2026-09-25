class_name SkillBar
extends HBoxContainer

## 动态技能栏：槽位数量由 Pawn 当前境界的主动技能容量决定，已配置技能由 SkillSlot 渲染。
## SkillBar 只转发点击请求，不执行施法、不扣除灵力、不推进冷却。

signal skill_requested(skill: ActiveSkillDefinition)

const SLOT_SCENE_PATH: String = "res://game/ui/skill_slot.tscn"
const MAX_SLOTS: int = 6

var _pawn: Pawn
var _slots: Array[SkillSlot] = []

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(0.0, SkillSlot.SLOT_SIZE)
	visible = false

func bind_pawn(pawn: Pawn) -> void:
	if _pawn == pawn and pawn != null:
		refresh()
		return
	_disconnect_pawn_signals()
	_pawn = pawn
	_connect_pawn_signals()
	refresh()

func unbind() -> void:
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

## 只读刷新：境界容量与技能列表决定槽位；冷却、灵力与死亡状态由每个 SkillSlot 自行读取。
func refresh() -> void:
	if _pawn == null or not is_instance_valid(_pawn) or _pawn.data == null:
		_clear_slots()
		visible = false
		return
	visible = true
	var capacity: int = 0
	var realm: RealmDefinition = _pawn.get_realm()
	if realm != null:
		capacity = realm.get_slot_capacity(RealmDefinition.KIND_ACTIVE_SKILL)
	var skills: Array[ActiveSkillDefinition] = _pawn.data.get_active_skills()
	var count: int = clampi(maxi(capacity, skills.size()), 0, MAX_SLOTS)
	_ensure_slot_count(count)
	for index: int in count:
		var slot: SkillSlot = _slots[index]
		if index < skills.size():
			slot.bind_skill(_pawn, skills[index], str(index + 1))
		else:
			slot.show_empty(str(index + 1))

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
	skill_requested.emit(skill)

func _connect_pawn_signals() -> void:
	if _pawn == null:
		return
	_connect_signal(_pawn.spirit_changed, _on_spirit_changed)
	_connect_signal(_pawn.skill_cooldown_changed, _on_skill_cooldown_changed)
	_connect_signal(_pawn.skill_cast, _on_skill_cast)
	_connect_signal(_pawn.died, _on_died)
	_connect_signal(_pawn.state_changed, _on_state_changed)
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
