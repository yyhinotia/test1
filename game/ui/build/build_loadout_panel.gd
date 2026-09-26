class_name BuildLoadoutPanel
extends VBoxContainer

## Build 装配面板：A/B 快速预设（INC-UI-018）+ 8 技能池自选组合（INC-UI-021）。
##
## 面板只做三件事：
##   1. 用 Pawn 的只读 API 说明「哪些预设 / 技能现在能不能装」；
##   2. 把玩家的点击翻译成 `Pawn.set_active_skill_loadout()` 调用；
##   3. 保留待选集合这一纯 UI 暂存区，只有显式「应用」才写回 Pawn。
## 面板不复制掌握 / 容量 / 互斥规则，也不在任何时机自动切换：
## 首通解锁技能只会让对应行从「未解锁」变成可选，是否真的重构 Build 必须由玩家点击。

## 每次预设切换尝试（含被拒绝）都广播一次，供人工实验记录与自动化证据复核。
signal build_switch_attempted(pawn: Pawn, preset_id: StringName, success: bool, reason: String)
## 每次「应用自定义 Build」尝试（含被拒绝）都广播一次；点选 / 取消只改待选，不触发该信号。
signal custom_loadout_applied(pawn: Pawn, skills: Array[ActiveSkillDefinition], success: bool, reason: String)

const PRESET_A_ID: StringName = &"build_a"
const PRESET_B_ID: StringName = &"build_b"
const STATUS_NO_PAWN: String = "未绑定单位"
const STATUS_READY: String = "选择一套 Build 后生效"
const REASON_NONE: String = ""
const REASON_NO_PAWN: String = "no_pawn"
const REASON_SWITCH_LOCKED: String = "switch_locked"
const REASON_PRESET_LOCKED: String = "preset_locked"
const REASON_LOADOUT_REJECTED: String = "loadout_rejected"
const REASON_CAPACITY_FULL: String = "capacity_full"
const REASON_SKILL_LOCKED: String = "skill_locked"
const REASON_EMPTY_SELECTION: String = "empty_selection"
const CUSTOM_TITLE: String = "自定义 Build"

## 两套固定快速预设（production 取值在 main.tscn 接线）：A = 御剑斩 + 护体真气，B = 御剑斩 + 定身术。
## 面板只认识数组内容、不认识具体技能 id；可用性一律由 Pawn 的只读 API 推导。
@export var preset_a: Array[ActiveSkillDefinition] = []
@export var preset_b: Array[ActiveSkillDefinition] = []
## 自定义 Build 的完整技能池（production 取值在 main.tscn 接线）。
## 面板不硬编码任何 res:// 技能路径；未解锁条目仍显示，但不可点选。
@export var available_skills: Array[ActiveSkillDefinition] = []

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
## 自定义 Build 的待选集合：纯 UI 暂存，只有 apply_custom_loadout() 才写回 Pawn。
var _pending_skills: Array[ActiveSkillDefinition] = []
## skill_key -> { title: Label, marker: Label, button: Button }
var _skill_rows: Dictionary = {}
var _custom_hint_label: Label
var _apply_button: Button


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


## 注入自定义 Build 的完整技能池；允许在入树前调用，此时只记住数据，_ready 再落成控件。
func set_available_skills(skills: Array[ActiveSkillDefinition]) -> void:
	available_skills = skills.duplicate()
	_prune_pending()
	if _rows != null:
		_build_rows()
		refresh()


func get_available_skills() -> Array[ActiveSkillDefinition]:
	return available_skills.duplicate()


func get_pending_skills() -> Array[ActiveSkillDefinition]:
	return _pending_skills.duplicate()


func get_skill_button(skill: ActiveSkillDefinition) -> Button:
	var row: Dictionary = _skill_rows.get(_skill_key(skill), {})
	return row.get("button") as Button


func get_skill_marker_text(skill: ActiveSkillDefinition) -> String:
	var row: Dictionary = _skill_rows.get(_skill_key(skill), {})
	var marker: Label = row.get("marker") as Label
	return marker.text if marker != null else ""


func get_custom_hint_text() -> String:
	return _custom_hint_label.text if _custom_hint_label != null else ""


func get_apply_button() -> Button:
	return _apply_button


## 自定义 Build 的待选上限：直接来自 Pawn 的容量投影；无 Pawn 为 0，无界哨兵原样返回。
func get_custom_capacity() -> int:
	if _pawn == null or not is_instance_valid(_pawn):
		return 0
	return _pawn.get_active_skill_capacity()


## 技能当前是否可点选：已配置、已绑定、Pawn 已掌握且未处于战斗锁定。
func is_skill_selectable(skill: ActiveSkillDefinition) -> bool:
	if _switch_locked or _pawn == null or not is_instance_valid(_pawn):
		return false
	if skill == null or not skill.is_configured():
		return false
	return _pawn.is_active_skill_known(skill)


## 绑定被展示的 Pawn：绑定只改变「看谁」，不改变任何装配。
## 待选集合初始化为当前装配（只读），让「取消一个再换一个」的重构流程自然成立。
func bind_pawn(pawn: Pawn) -> void:
	if _pawn == pawn and pawn != null:
		refresh()
		return
	_disconnect_pawn_signals()
	_pawn = pawn
	_connect_pawn_signals()
	_sync_pending_from_equipped()
	_set_status(STATUS_READY if pawn != null else STATUS_NO_PAWN, REASON_NONE)
	refresh()


func unbind() -> void:
	bind_pawn(null)


## 战斗中锁定（由主场景按遭遇状态设置）：切换与自定义选择都只允许发生在两轮战斗之间，
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


## 掌握 / 装配在别处变化（例如首通解锁技能）时刷新可用性；这里绝不自动装配，也不自动选入待选。
func _on_pawn_build_changed(_changed_pawn: Pawn) -> void:
	refresh()


## 只读刷新：标题、标记、按钮可用性全部由 Pawn 的当前状态推导，不改写任何数值。
func refresh() -> void:
	_refresh_presets()
	_refresh_custom()


func _refresh_presets() -> void:
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
		var selectable: bool = available and not current and not _switch_locked
		button.disabled = not selectable
		# 只有可操作按钮拦截鼠标；锁定 / 当前 / 未解锁态让战场点击穿透（INC-CROSS-020 左键操作模型）。
		button.mouse_filter = Control.MOUSE_FILTER_STOP if selectable else Control.MOUSE_FILTER_IGNORE
		button.text = "已装备" if current else "使用 %s" % get_preset_label(preset_id)
		button.tooltip_text = "%s：%s" % [get_preset_label(preset_id), _describe_skills(skills)]


func _refresh_custom() -> void:
	var capacity: int = get_custom_capacity()
	if _custom_hint_label != null:
		if _pawn == null or not is_instance_valid(_pawn):
			_custom_hint_label.text = "%s：未绑定单位" % CUSTOM_TITLE
		elif capacity < 0:
			_custom_hint_label.text = "%s：已选 %d 个（无容量上限）" % [CUSTOM_TITLE, _pending_skills.size()]
		else:
			_custom_hint_label.text = "%s：已选 %d / %d" % [CUSTOM_TITLE, _pending_skills.size(), capacity]
	for skill: ActiveSkillDefinition in available_skills:
		var row: Dictionary = _skill_rows.get(_skill_key(skill), {})
		if row.is_empty():
			continue
		var title: Label = row.get("title") as Label
		var marker: Label = row.get("marker") as Label
		var button: Button = row.get("button") as Button
		var known: bool = _pawn != null and is_instance_valid(_pawn) and skill != null and skill.is_configured() and _pawn.is_active_skill_known(skill)
		var selected: bool = _pending_has(skill)
		title.text = _skill_name(skill)
		if not known:
			marker.text = "未解锁"
		elif selected:
			marker.text = "已选"
		else:
			marker.text = "可选"
		button.text = "取消" if selected else "选择"
		var selectable: bool = is_skill_selectable(skill)
		button.disabled = not selectable
		button.mouse_filter = Control.MOUSE_FILTER_STOP if selectable else Control.MOUSE_FILTER_IGNORE
		button.tooltip_text = "%s（%s）" % [_skill_name(skill), marker.text]
	if _apply_button != null:
		var applicable: bool = _pawn != null and is_instance_valid(_pawn) and not _switch_locked and not _pending_skills.is_empty()
		if capacity >= 0 and _pending_skills.size() > capacity:
			applicable = false
		_apply_button.disabled = not applicable
		_apply_button.mouse_filter = Control.MOUSE_FILTER_STOP if applicable else Control.MOUSE_FILTER_IGNORE
		_apply_button.tooltip_text = "应用后经 Pawn 校验并写入当前主动技能装配"


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
	# 预设也是当前装配，待选自定义区同步呈现，避免自定义区显示过期选择。
	_sync_pending_from_equipped()
	_set_status("已切换到 %s：%s" % [get_preset_label(preset_id), _describe_skills(skills)], REASON_NONE)
	refresh()
	build_switch_attempted.emit(_pawn, preset_id, true, REASON_NONE)


func _reject(preset_id: StringName, reason: String, message: String) -> void:
	_last_preset_id = preset_id
	_set_status(message, reason)
	# 失败后重新以 Pawn 为事实源刷新，让面板读数与真实装配一致（零副作用的可见证据）。
	refresh()
	build_switch_attempted.emit(_pawn, preset_id, false, reason)


## 点选 / 取消只修改待选集合，不触碰 Pawn；容量与掌握事实仍来自 Pawn。
func _on_skill_pressed(skill: ActiveSkillDefinition) -> void:
	if _pawn == null or not is_instance_valid(_pawn):
		_set_status("选择失败：未绑定单位", REASON_NO_PAWN)
		refresh()
		return
	if _switch_locked:
		_set_status("选择失败：战斗中不可重构 Build", REASON_SWITCH_LOCKED)
		refresh()
		return
	if skill == null or not skill.is_configured() or not _pawn.is_active_skill_known(skill):
		_set_status("选择失败：%s 未解锁" % _skill_name(skill), REASON_SKILL_LOCKED)
		refresh()
		return
	if _pending_has(skill):
		_pending_remove(skill)
		_set_status("已取消：%s" % _skill_name(skill), REASON_NONE)
		refresh()
		return
	var capacity: int = get_custom_capacity()
	if capacity >= 0 and _pending_skills.size() >= capacity:
		_set_status("选择失败：已选满 %d 个，先取消一个再选" % capacity, REASON_CAPACITY_FULL)
		refresh()
		return
	_pending_skills.append(skill)
	_set_status("已选择：%s（点「应用自定义 Build」生效）" % _skill_name(skill), REASON_NONE)
	refresh()


## 显式应用：唯一一次写回 Pawn 的入口；返回值供 UI / 测试使用，同时广播结果信号。
func apply_custom_loadout() -> bool:
	if _pawn == null or not is_instance_valid(_pawn):
		_reject_custom(REASON_NO_PAWN, "应用失败：未绑定单位")
		return false
	if _switch_locked:
		_reject_custom(REASON_SWITCH_LOCKED, "应用失败：战斗中不可重构 Build，请在下一场战斗前再试")
		return false
	if _pending_skills.is_empty():
		_reject_custom(REASON_EMPTY_SELECTION, "应用失败：至少选择一个已解锁技能")
		return false
	var capacity: int = get_custom_capacity()
	if capacity >= 0 and _pending_skills.size() > capacity:
		_reject_custom(REASON_CAPACITY_FULL, "应用失败：已选 %d 个，超过当前境界容量 %d" % [_pending_skills.size(), capacity])
		return false
	var missing: Array[String] = _missing_skill_names(_pending_skills)
	if not missing.is_empty():
		_reject_custom(REASON_SKILL_LOCKED, "应用失败：未解锁 %s" % ", ".join(missing))
		return false
	var skills: Array[ActiveSkillDefinition] = _pending_skills.duplicate()
	# 唯一状态变更出口：一律经 Pawn 裁决，UI 不复制容量与互斥规则。
	if not _pawn.set_active_skill_loadout(skills):
		_reject_custom(REASON_LOADOUT_REJECTED, "应用失败：Build 未生效（超出当前境界容量或被 Build 校验拒绝）")
		return false
	_set_status("已应用自定义 Build：%s" % _describe_skills(skills), REASON_NONE)
	custom_loadout_applied.emit(_pawn, skills, true, REASON_NONE)
	refresh()
	return true


func _reject_custom(reason: String, message: String) -> void:
	_set_status(message, reason)
	var skills: Array[ActiveSkillDefinition] = _pending_skills.duplicate()
	custom_loadout_applied.emit(_pawn, skills, false, reason)
	refresh()


func _build_rows() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_row_nodes.clear()
	_skill_rows.clear()
	_custom_hint_label = null
	_apply_button = null
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
	_build_custom_rows()


## 自定义区：标题 / 容量提示 / 每技能一行 / 显式应用按钮；全部按注入顺序生成。
func _build_custom_rows() -> void:
	var header: Label = Label.new()
	header.name = "CustomHeader"
	header.add_theme_font_size_override("font_size", 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.text = CUSTOM_TITLE
	_rows.add_child(header)
	_custom_hint_label = Label.new()
	_custom_hint_label.name = "CustomHint"
	_custom_hint_label.add_theme_font_size_override("font_size", 12)
	_custom_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_custom_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(_custom_hint_label)
	for skill: ActiveSkillDefinition in available_skills:
		var key: String = _skill_key(skill)
		if key.is_empty() or _skill_rows.has(key):
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "SkillRow_%s" % (String(skill.id) if skill != null and skill.is_configured() else "unconfigured")
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		var title: Label = Label.new()
		title.name = "Title"
		title.add_theme_font_size_override("font_size", 13)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var marker: Label = Label.new()
		marker.name = "Marker"
		marker.add_theme_font_size_override("font_size", 12)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var button: Button = Button.new()
		button.name = "SelectButton"
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_skill_pressed.bind(skill))
		row.add_child(title)
		row.add_child(marker)
		row.add_child(button)
		_rows.add_child(row)
		_skill_rows[key] = {"title": title, "marker": marker, "button": button}
	_apply_button = Button.new()
	_apply_button.name = "ApplyCustomButton"
	_apply_button.add_theme_font_size_override("font_size", 13)
	_apply_button.text = "应用自定义 Build"
	_apply_button.pressed.connect(apply_custom_loadout)
	_rows.add_child(_apply_button)


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


func _available_has(skill: ActiveSkillDefinition) -> bool:
	var key: String = _skill_key(skill)
	if key.is_empty():
		return false
	for candidate: ActiveSkillDefinition in available_skills:
		if _skill_key(candidate) == key:
			return true
	return false


func _pending_has(skill: ActiveSkillDefinition) -> bool:
	var key: String = _skill_key(skill)
	if key.is_empty():
		return false
	for candidate: ActiveSkillDefinition in _pending_skills:
		if _skill_key(candidate) == key:
			return true
	return false


func _pending_remove(skill: ActiveSkillDefinition) -> void:
	var key: String = _skill_key(skill)
	for index in range(_pending_skills.size() - 1, -1, -1):
		if _skill_key(_pending_skills[index]) == key:
			_pending_skills.remove_at(index)


## 待选集合只保留仍在注入技能池中的条目，避免换池后残留不可见选择。
func _prune_pending() -> void:
	for index in range(_pending_skills.size() - 1, -1, -1):
		if not _available_has(_pending_skills[index]):
			_pending_skills.remove_at(index)


## 绑定 Pawn 时以待选集合呈现当前装配；只读，不写回 Pawn，不自动加入新解锁技能。
func _sync_pending_from_equipped() -> void:
	_pending_skills.clear()
	if _pawn == null or not is_instance_valid(_pawn):
		return
	for skill: ActiveSkillDefinition in _pawn.get_equipped_active_skills():
		if _available_has(skill) and not _pending_has(skill):
			_pending_skills.append(skill)


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
