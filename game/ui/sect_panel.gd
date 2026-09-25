class_name SectPanel
extends VBoxContainer

## 宗门面板（INC-UI-016）：只呈现 SectState 快照并把玩家意图变成信号。
## 面板不持有库存、不扣资源、不判断能不能升级；唯一规则来源仍是 SectState。

signal upgrade_requested(facility_id: StringName)
signal cultivate_requested()
signal harvest_requested()
signal learn_requested(technique_id: StringName)
signal strengthen_requested()
signal refine_pill_requested()
signal use_pill_requested()

const EMPTY_STATUS: String = "宗门未接入"
const EMPTY_VALUE: String = "-"
const REASON_LABELS: Dictionary = {
	SectState.REASON_NONE: "可升级",
	SectState.REASON_UNKNOWN_FACILITY: "设施不存在",
	SectState.REASON_MAX_LEVEL: "已满级",
	SectState.REASON_NOT_ENOUGH_SPIRIT_STONES: "灵石不足",
	SectState.REASON_REALM_TOO_LOW: "境界不足",
}

@onready var _title_label: Label = $TitleLabel
@onready var _spirit_stones_label: Label = $SpiritStonesLabel
@onready var _spirit_herbs_label: Label = $SpiritHerbsLabel
@onready var _pills_label: Label = $PillsLabel
@onready var _facilities_container: VBoxContainer = $Facilities
@onready var _cultivate_button: Button = $CultivateButton
@onready var _harvest_button: Button = $HarvestButton
@onready var _learn_option: OptionButton = $LearnRow/LearnOption
@onready var _learn_button: Button = $LearnRow/LearnButton
@onready var _strengthen_button: Button = $StrengthenButton
@onready var _refine_pill_button: Button = $RefinePillButton
@onready var _use_pill_button: Button = $UsePillButton
@onready var _status_label: Label = $StatusLabel

var _state: SectState
var _status_text: String = EMPTY_STATUS
var _upgrade_buttons: Dictionary = {}
var _upgrade_reasons: Dictionary = {}
var _learnable_techniques: Array[TechniqueDefinition] = []


func _ready() -> void:
	_connect_buttons()
	_rebuild_facility_rows()
	_rebuild_learn_options()
	_refresh_all()


## 绑定宗门状态；null 只清空展示，不影响面板已缓存的玩家意图信号。
func bind_state(state: SectState) -> void:
	if _state == state:
		return
	_disconnect_state()
	_state = state
	_connect_state()
	_refresh_all()


func is_bound() -> bool:
	return _state != null and is_instance_valid(_state)


func get_status_text() -> String:
	return _status_text


func get_spirit_stones_text() -> String:
	return _spirit_stones_label.text if _spirit_stones_label != null else EMPTY_VALUE


func get_spirit_herbs_text() -> String:
	return _spirit_herbs_label.text if _spirit_herbs_label != null else EMPTY_VALUE


func get_pills_text() -> String:
	return _pills_label.text if _pills_label != null else EMPTY_VALUE


func get_facility_count() -> int:
	return _upgrade_buttons.size()


func get_upgrade_button(facility_id: StringName) -> Button:
	return _upgrade_buttons.get(facility_id) as Button


func get_upgrade_reason_text(facility_id: StringName) -> String:
	return String(_upgrade_reasons.get(facility_id, ""))


func set_status(text: String) -> void:
	_status_text = text
	if _status_label != null:
		_status_label.text = text


## 设置藏经阁可参悟候选：面板只展示名称，点击后把 id 交回上层。
func set_learnable_techniques(techniques: Array[TechniqueDefinition]) -> void:
	_learnable_techniques.clear()
	var seen_ids: Array[StringName] = []
	for technique: TechniqueDefinition in techniques:
		if technique == null or not technique.is_configured():
			continue
		if seen_ids.has(technique.id):
			continue
		seen_ids.append(technique.id)
		_learnable_techniques.append(technique)
	_rebuild_learn_options()
	_refresh_action_buttons()


func get_learnable_technique_count() -> int:
	return _learnable_techniques.size()


func _connect_buttons() -> void:
	if not _cultivate_button.pressed.is_connected(_on_cultivate_pressed):
		_cultivate_button.pressed.connect(_on_cultivate_pressed)
	if not _harvest_button.pressed.is_connected(_on_harvest_pressed):
		_harvest_button.pressed.connect(_on_harvest_pressed)
	if not _learn_button.pressed.is_connected(_on_learn_pressed):
		_learn_button.pressed.connect(_on_learn_pressed)
	if not _strengthen_button.pressed.is_connected(_on_strengthen_pressed):
		_strengthen_button.pressed.connect(_on_strengthen_pressed)
	if not _refine_pill_button.pressed.is_connected(_on_refine_pill_pressed):
		_refine_pill_button.pressed.connect(_on_refine_pill_pressed)
	if not _use_pill_button.pressed.is_connected(_on_use_pill_pressed):
		_use_pill_button.pressed.connect(_on_use_pill_pressed)


func _connect_state() -> void:
	if not is_bound():
		return
	if not _state.spirit_stones_changed.is_connected(_on_state_changed):
		_state.spirit_stones_changed.connect(_on_state_changed)
	if not _state.spirit_herbs_changed.is_connected(_on_state_changed):
		_state.spirit_herbs_changed.connect(_on_state_changed)
	if not _state.pills_changed.is_connected(_on_state_changed):
		_state.pills_changed.connect(_on_state_changed)
	if not _state.facility_upgraded.is_connected(_on_state_changed):
		_state.facility_upgraded.connect(_on_state_changed)
	if not _state.cultivation_gained.is_connected(_on_state_changed):
		_state.cultivation_gained.connect(_on_state_changed)
	if not _state.herbs_harvested.is_connected(_on_state_changed):
		_state.herbs_harvested.connect(_on_state_changed)
	if not _state.technique_learned.is_connected(_on_state_changed):
		_state.technique_learned.connect(_on_state_changed)
	if not _state.weapon_strengthened.is_connected(_on_state_changed):
		_state.weapon_strengthened.connect(_on_state_changed)
	if not _state.pill_refined.is_connected(_on_state_changed):
		_state.pill_refined.connect(_on_state_changed)
	if not _state.pill_used.is_connected(_on_state_changed):
		_state.pill_used.connect(_on_state_changed)


func _disconnect_state() -> void:
	if _state == null or not is_instance_valid(_state):
		return
	for signal_name: StringName in [
		&"spirit_stones_changed",
		&"spirit_herbs_changed",
		&"pills_changed",
		&"facility_upgraded",
		&"cultivation_gained",
		&"herbs_harvested",
		&"technique_learned",
		&"weapon_strengthened",
		&"pill_refined",
		&"pill_used",
	]:
		if _state.is_connected(signal_name, _on_state_changed):
			_state.disconnect(signal_name, _on_state_changed)


## 统一刷新入口：信号签名各不相同，额外参数被忽略，面板只重新读一次快照。
func _on_state_changed(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
	_refresh_all()


func _refresh_all() -> void:
	_refresh_inventory()
	_rebuild_facility_rows()
	_refresh_action_buttons()
	if _status_label != null:
		_status_label.text = _status_text


func _refresh_inventory() -> void:
	if _spirit_stones_label == null:
		return
	if not is_bound():
		_title_label.text = "宗门"
		_spirit_stones_label.text = "灵石：%s" % EMPTY_VALUE
		_spirit_herbs_label.text = "灵草：%s" % EMPTY_VALUE
		_pills_label.text = "丹药：%s" % EMPTY_VALUE
		return
	var snapshot: Dictionary = _state.get_snapshot()
	_spirit_stones_label.text = "灵石：%d" % int(snapshot.get("spirit_stones", 0))
	_spirit_herbs_label.text = "灵草：%d" % int(snapshot.get("spirit_herbs", 0))
	_pills_label.text = "丹药：%d" % int(snapshot.get("pills", 0))


func _rebuild_facility_rows() -> void:
	if _facilities_container == null:
		return
	for child: Node in _facilities_container.get_children():
		_facilities_container.remove_child(child)
		child.free()
	_upgrade_buttons.clear()
	_upgrade_reasons.clear()
	if not is_bound():
		_add_placeholder("设施：未接入")
		return
	var snapshot: Dictionary = _state.get_snapshot()
	var entries: Array = snapshot.get("facilities", [])
	if entries.is_empty():
		_add_placeholder("设施：无")
		return
	for entry_value: Variant in entries:
		var entry: Dictionary = entry_value
		var facility_id: StringName = StringName(entry.get("id", &""))
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "FacilityRow_%s" % String(facility_id)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 4)

		var name_label: Label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = "%s Lv.%d/%d" % [
			String(entry.get("display_name", "设施")),
			int(entry.get("level", 0)),
			int(entry.get("max_level", 0)),
		]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 12)

		var reason_text: String = _reason_text(entry)
		var cost: int = int(entry.get("upgrade_cost", SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE))
		var cost_text: String = "满级" if cost < 0 else "%d 灵石" % cost
		var info_label: Label = Label.new()
		info_label.name = "InfoLabel"
		info_label.text = "%s · %s" % [cost_text, reason_text]
		info_label.custom_minimum_size = Vector2(118, 0)
		info_label.add_theme_font_size_override("font_size", 12)
		info_label.clip_text = true
		info_label.tooltip_text = info_label.text

		var upgrade_button: Button = Button.new()
		upgrade_button.name = "UpgradeButton"
		upgrade_button.text = "升级"
		upgrade_button.custom_minimum_size = Vector2(48, 0)
		upgrade_button.disabled = not bool(entry.get("can_upgrade", false))
		upgrade_button.tooltip_text = reason_text
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(facility_id))

		row.add_child(name_label)
		row.add_child(info_label)
		row.add_child(upgrade_button)
		_facilities_container.add_child(row)
		_upgrade_buttons[facility_id] = upgrade_button
		_upgrade_reasons[facility_id] = reason_text


func _add_placeholder(text: String) -> void:
	var label: Label = Label.new()
	label.name = "Placeholder"
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_facilities_container.add_child(label)


func _reason_text(entry: Dictionary) -> String:
	var reason: StringName = StringName(entry.get("block_reason", SectState.REASON_NONE))
	return String(REASON_LABELS.get(reason, "不可升级"))


func _rebuild_learn_options() -> void:
	if _learn_option == null:
		return
	_learn_option.clear()
	for technique: TechniqueDefinition in _learnable_techniques:
		_learn_option.add_item(technique.display_name)
		_learn_option.set_item_metadata(_learn_option.item_count - 1, technique.id)
	if _learn_option.item_count > 0:
		_learn_option.select(0)


func _refresh_action_buttons() -> void:
	var bound: bool = is_bound()
	if _cultivate_button != null:
		_cultivate_button.disabled = not bound
	if _harvest_button != null:
		_harvest_button.disabled = not bound
	if _strengthen_button != null:
		_strengthen_button.disabled = not bound
	if _refine_pill_button != null:
		_refine_pill_button.disabled = not bound
	if _use_pill_button != null:
		_use_pill_button.disabled = not bound or int(_state.get_pills()) <= 0
	if _learn_option != null:
		_learn_option.disabled = not bound or _learn_option.item_count <= 0
	if _learn_button != null:
		_learn_button.disabled = not bound or _learn_option.item_count <= 0


func _on_upgrade_pressed(facility_id: StringName) -> void:
	if not is_bound():
		return
	var button: Button = get_upgrade_button(facility_id)
	if button == null or button.disabled:
		return
	upgrade_requested.emit(facility_id)


func _on_cultivate_pressed() -> void:
	if is_bound():
		cultivate_requested.emit()


func _on_harvest_pressed() -> void:
	if is_bound():
		harvest_requested.emit()


func _on_learn_pressed() -> void:
	if not is_bound():
		return
	if _learn_option == null or _learn_option.item_count <= 0:
		return
	var metadata: Variant = _learn_option.get_item_metadata(_learn_option.selected)
	if metadata == null:
		return
	learn_requested.emit(StringName(metadata))


func _on_strengthen_pressed() -> void:
	if is_bound():
		strengthen_requested.emit()


func _on_refine_pill_pressed() -> void:
	if is_bound():
		refine_pill_requested.emit()


func _on_use_pill_pressed() -> void:
	if is_bound() and _state.get_pills() > 0:
		use_pill_requested.emit()
