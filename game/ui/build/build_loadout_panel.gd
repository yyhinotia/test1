class_name BuildLoadoutPanel
extends VBoxContainer

## 最小 Build A/B 切换面板（INC-UI-018）。
##
## 这是 Gate C（主动 Build 重构）唯一可见的操作面，面板只做两件事：
##   1. 用 Pawn 的只读 API 说明「两套固定预设现在能不能装」；
##   2. 把玩家的点击翻译成一次 `Pawn.set_active_skill_loadout()` 调用。
## 面板不复制掌握 / 容量 / 互斥规则，也不在任何时机自动切换：
## 首通解锁定身术只会把 Build B 从「未解锁」变成「可切换」，是否真的换 Build 必须由玩家点击。

## 每次切换尝试（含被拒绝）都广播一次，供人工实验记录与自动化证据复核。
signal build_switch_attempted(pawn: Pawn, preset_id: StringName, success: bool, reason: String)

const PRESET_A_ID: StringName = &"build_a"
const PRESET_B_ID: StringName = &"build_b"
const STATUS_NO_PAWN: String = "未绑定单位"
const STATUS_READY: String = "选择一套 Build 后生效"
const REASON_NONE: String = ""
const REASON_NO_PAWN: String = "no_pawn"
const REASON_SWITCH_LOCKED: String = "switch_locked"
const REASON_PRESET_LOCKED: String = "preset_locked"
const REASON_LOADOUT_REJECTED: String = "loadout_rejected"

## 两套固定预设（production 取值在 main.tscn 接线）：A = 御剑斩 + 护体真气，B = 御剑斩 + 定身术。
## 面板只认识数组内容、不认识具体技能 id；可用性一律由 Pawn 的只读 API 推导。
@export var preset_a: Array[ActiveSkillDefinition] = []
@export var preset_b: Array[ActiveSkillDefinition] = []

@onready var _rows: VBoxContainer = $Rows
@onready var _status_label: Label = $StatusLabel

var _pawn: Pawn
## 外部锁（与 EncounterPanel.set_restart_locked 同构）：由主场景按遭遇状态设置。
var _switch_locked: bool = false
var _status_text: String = STATUS_NO_PAWN
var _last_reason: String = REASON_NONE
var _last_preset_id: StringName = &""
## preset_id -> { title: Label, marker: Label, button: Button }
var _row_nodes: Dictionary = {}


func _ready() -> void:
	_build_rows()
	refresh()


## 稳定顺序的预设 id 列表：UI 行顺序、测试与证据脚本都以它为准。
func get_preset_ids() -> Array[StringName]:
	var ids: Array[StringName] = [PRESET_A_ID, PRESET_B_ID]
	return ids


func get_preset_skills(preset_id: StringName) -> Array[ActiveSkillDefinition]:
	return _preset_skills(preset_id).duplicate()


func get_preset_label(preset_id: StringName) -> String:
	return "Build A" if preset_id == PRESET_A_ID else "Build B"


func get_preset_button(preset_id: StringName) -> Button:
	var row: Dictionary = _row_nodes.get(preset_id, {})
	return row.get("button") as Button


func get_preset_marker_text(preset_id: StringName) -> String:
	var row: Dictionary = _row_nodes.get(preset_id, {})
	var marker: Label = row.get("marker") as Label
	return marker.text if marker != null else ""


func get_preset_title_text(preset_id: StringName) -> String:
	var row: Dictionary = _row_nodes.get(preset_id, {})
	var title: Label = row.get("title") as Label
	return title.text if title != null else ""


func get_status_text() -> String:
	return _status_text


func get_last_reason() -> String:
	return _last_reason


func get_last_preset_id() -> StringName:
	return _last_preset_id


func get_bound_pawn() -> Pawn:
	return _pawn


func is_switch_locked() -> bool:
	return _switch_locked


## 预设可切换 = 预设非空且每个技能都已掌握。掌握事实只能来自 Pawn，UI 不缓存、不硬编码。
func is_preset_available(preset_id: StringName) -> bool:
	if _pawn == null or not is_instance_valid(_pawn):
		return false
	var skills: Array[ActiveSkillDefinition] = _preset_skills(preset_id)
	return not skills.is_empty() and _missing_skill_names(skills).is_empty()


## 当前生效的预设 id：两套都不是当前装配时返回空 StringName（例如装配被别的入口改过）。
func get_active_preset_id() -> StringName:
	for preset_id: StringName in get_preset_ids():
		if is_preset_current(preset_id):
			return preset_id
	return &""


## 是否就是当前装配：按 id 逐位比较，顺序不同视为不同 Build。
func is_preset_current(preset_id: StringName) -> bool:
	if _pawn == null or not is_instance_valid(_pawn):
		return false
	return _matches_equipped(_preset_skills(preset_id))


## 绑定被展示的 Pawn：绑定只改变「看谁」，不改变任何装配。
func bind_pawn(pawn: Pawn) -> void:
	if _pawn == pawn and pawn != null:
		refresh()
		return
	_disconnect_pawn_signals()
	_pawn = pawn
	_connect_pawn_signals()
	_set_status(STATUS_READY if pawn != null else STATUS_NO_PAWN, REASON_NONE)
	refresh()


func unbind() -> void:
	bind_pawn(null)


## 战斗中锁定（由主场景按遭遇状态设置）：切换只允许发生在两轮战斗之间，
## 否则「主动重构 → 再战」的实验时序会被中途换 Build 污染。
func set_switch_locked(value: bool) -> void:
	if _switch_locked == value:
		return
	_switch_locked = value
	refresh()


func _connect_pawn_signals() -> void:
	if _pawn == null or not is_instance_valid(_pawn):
		return
	if not _pawn.build_changed.is_connected(_on_pawn_build_changed):
		_pawn.build_changed.connect(_on_pawn_build_changed)


func _disconnect_pawn_signals() -> void:
	if _pawn == null or not is_instance_valid(_pawn):
		return
	if _pawn.build_changed.is_connected(_on_pawn_build_changed):
		_pawn.build_changed.disconnect(_on_pawn_build_changed)


## 掌握 / 装配在别处变化（例如首通解锁定身术）时刷新可用性；这里绝不自动装配。
func _on_pawn_build_changed(_changed_pawn: Pawn) -> void:
	refresh()


## 只读刷新：标题、标记、按钮可用性全部由 Pawn 的当前状态推导，不改写任何数值。
func refresh() -> void:
	for preset_id: StringName in get_preset_ids():
		var row: Dictionary = _row_nodes.get(preset_id, {})
		if row.is_empty():
			continue
		var skills: Array[ActiveSkillDefinition] = _preset_skills(preset_id)
		var title: Label = row.get("title") as Label
		var marker: Label = row.get("marker") as Label
		var button: Button = row.get("button") as Button
		var missing: Array[String] = _missing_skill_names(skills)
		var available: bool = not skills.is_empty() and missing.is_empty() and _pawn != null and is_instance_valid(_pawn)
		var current: bool = available and _matches_equipped(skills)
		title.text = "%s：%s" % [get_preset_label(preset_id), _describe_skills(skills)]
		if current:
			marker.text = "当前 Build"
		elif not available:
			marker.text = _unavailable_text(missing)
		elif _switch_locked:
			marker.text = "战斗中不可切换"
		else:
			marker.text = "可切换"
		button.disabled = not available or current or _switch_locked
		button.text = "已装备" if current else "使用 %s" % get_preset_label(preset_id)
		button.tooltip_text = "%s：%s" % [get_preset_label(preset_id), _describe_skills(skills)]


## 点击只有一条状态变更出口：`Pawn.set_active_skill_loadout()`。
## 任何失败都保持调用前状态、写入可复核原因并广播，绝不静默吞掉。
func _on_preset_pressed(preset_id: StringName) -> void:
	var skills: Array[ActiveSkillDefinition] = _preset_skills(preset_id)
	if _pawn == null or not is_instance_valid(_pawn):
		_reject(preset_id, REASON_NO_PAWN, "切换失败：未绑定单位")
		return
	if _switch_locked:
		_reject(preset_id, REASON_SWITCH_LOCKED, "切换失败：战斗中不可切换 Build，请在下一场战斗前再换")
		return
	var missing: Array[String] = _missing_skill_names(skills)
	if skills.is_empty() or not missing.is_empty():
		_reject(preset_id, REASON_PRESET_LOCKED, "切换失败：%s 未解锁（需要 %s）" % [get_preset_label(preset_id), ", ".join(missing)])
		return
	# 唯一状态变更出口：一律经 Pawn 裁决，UI 不复制容量与互斥规则。
	if not _pawn.set_active_skill_loadout(skills):
		_reject(preset_id, REASON_LOADOUT_REJECTED, "切换失败：%s 未生效（超出当前境界主动技能容量或被 Build 校验拒绝）" % get_preset_label(preset_id))
		return
	_last_preset_id = preset_id
	_set_status("已切换到 %s：%s" % [get_preset_label(preset_id), _describe_skills(skills)], REASON_NONE)
	refresh()
	build_switch_attempted.emit(_pawn, preset_id, true, REASON_NONE)


func _reject(preset_id: StringName, reason: String, message: String) -> void:
	_last_preset_id = preset_id
	_set_status(message, reason)
	# 失败后重新以 Pawn 为事实源刷新，让面板读数与真实装配一致（零副作用的可见证据）。
	refresh()
	build_switch_attempted.emit(_pawn, preset_id, false, reason)


func _build_rows() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_row_nodes.clear()
	for preset_id: StringName in get_preset_ids():
		var row: VBoxContainer = VBoxContainer.new()
		row.name = String(preset_id)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 2)
		var title: Label = Label.new()
		title.name = "Title"
		title.add_theme_font_size_override("font_size", 14)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(title)
		var action_row: HBoxContainer = HBoxContainer.new()
		action_row.name = "ActionRow"
		action_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_row.add_theme_constant_override("separation", 6)
		var marker: Label = Label.new()
		marker.name = "Marker"
		marker.add_theme_font_size_override("font_size", 12)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button: Button = Button.new()
		button.name = "UseButton"
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_on_preset_pressed.bind(preset_id))
		action_row.add_child(marker)
		action_row.add_child(button)
		row.add_child(action_row)
		_rows.add_child(row)
		_row_nodes[preset_id] = {"title": title, "marker": marker, "button": button}


func _preset_skills(preset_id: StringName) -> Array[ActiveSkillDefinition]:
	if preset_id == PRESET_A_ID:
		return preset_a
	if preset_id == PRESET_B_ID:
		return preset_b
	var empty: Array[ActiveSkillDefinition] = []
	return empty


## 缺失技能名（按预设顺序）：未配置条目记为「未配置技能」，未掌握条目取 display_name。
func _missing_skill_names(skills: Array[ActiveSkillDefinition]) -> Array[String]:
	var missing: Array[String] = []
	for skill: ActiveSkillDefinition in skills:
		if skill == null or not skill.is_configured():
			missing.append(_skill_name(skill))
			continue
		if _pawn == null or not is_instance_valid(_pawn) or not _pawn.is_active_skill_known(skill):
			missing.append(skill.display_name)
	return missing


func _skill_name(skill: ActiveSkillDefinition) -> String:
	if skill == null or not skill.is_configured():
		return "未配置技能"
	return skill.display_name


func _describe_skills(skills: Array[ActiveSkillDefinition]) -> String:
	if skills.is_empty():
		return "未配置"
	var names: PackedStringArray = PackedStringArray()
	for skill: ActiveSkillDefinition in skills:
		names.append(_skill_name(skill))
	return " + ".join(names)


func _matches_equipped(skills: Array[ActiveSkillDefinition]) -> bool:
	if skills.is_empty():
		return false
	var equipped: Array[ActiveSkillDefinition] = _pawn.get_equipped_active_skills()
	if equipped.size() != skills.size():
		return false
	for index: int in skills.size():
		if _skill_key(equipped[index]) != _skill_key(skills[index]):
			return false
	return true


## 技能身份：已配置用 id，未配置用实例 id，避免同 id 的伪资源被当作同一技能。
func _skill_key(skill: ActiveSkillDefinition) -> String:
	if skill == null:
		return ""
	if skill.is_configured():
		return String(skill.id)
	return "instance:%d" % skill.get_instance_id()


func _unavailable_text(missing: Array[String]) -> String:
	if _pawn == null or not is_instance_valid(_pawn):
		return "未绑定单位"
	if missing.is_empty():
		return "未配置"
	return "未解锁：%s" % ", ".join(missing)


func _set_status(text: String, reason: String) -> void:
	_status_text = text
	_last_reason = reason
	if _status_label != null:
		_status_label.text = text
