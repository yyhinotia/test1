class_name EncounterPanel
extends VBoxContainer

## 遭遇选择面板（INC-UI-014）：只呈现「可以进入哪些秘境遭遇」，不实例化单位、不推进战斗状态。
## 与 SkillBar 同构——UI 只发信号，流程编排由主场景转交 EncounterSession（沿用在 INC-UI-012 确立的边界）。

## 点击某个遭遇：只表示「玩家想进入它」，是否真的开局由上层决定。
signal encounter_selected(encounter: EncounterDefinition)
## 点击重新挑战：面板不判断能否重开，交给 EncounterSession。
signal restart_requested()

## MVP 阶段遭遇数量上限：按钮区用固定高度容器承载，避免把 Dock 布局撑破。
const MAX_ENCOUNTERS: int = 6
const EMPTY_STATUS: String = "未选择遭遇"

@export var encounters: Array[EncounterDefinition] = []

@onready var _title_label: Label = $TitleLabel
@onready var _buttons_container: VBoxContainer = $Buttons
@onready var _status_label: Label = $StatusLabel
@onready var _restart_button: Button = $RestartButton

var _buttons: Array[Button] = []
var _running: bool = false
## 外部锁（INC-CORE-009）：秘境进行中由主场景锁住「重新挑战」，与运行态互不影响。
var _restart_locked: bool = false
var _active_encounter: EncounterDefinition
## set_status 可能在入树前被调用，先记住文本，_ready 时再落到 Label。
var _status_text: String = EMPTY_STATUS


func _ready() -> void:
	if not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
	_rebuild_buttons()
	_status_label.text = _status_text
	_refresh_title()
	_apply_interaction_states()


func is_running() -> bool:
	return _running


func get_active_encounter() -> EncounterDefinition:
	return _active_encounter


func get_status_text() -> String:
	return _status_text


func get_encounter_count() -> int:
	return _buttons.size()


func get_encounter_buttons() -> Array[Button]:
	return _buttons.duplicate()


## 运行态只影响交互可用性，不改变任何战斗数值。
func set_running(value: bool) -> void:
	_running = value
	_apply_interaction_states()


func set_status(text: String) -> void:
	_status_text = text
	if _status_label != null:
		_status_label.text = text


## 秘境进行中锁住「重新挑战」：单场重开会白送一次满状态，破坏跨房间的损耗累积。
## 与 set_running 正交——单场遭遇模式下仍保留「战斗中可以重开」的既有语义。
func set_restart_locked(value: bool) -> void:
	_restart_locked = value
	_apply_interaction_states()


func set_active_encounter(encounter: EncounterDefinition) -> void:
	_active_encounter = encounter
	_refresh_title()
	_apply_interaction_states()


## 按 encounters 重建按钮：文案取 display_name，未配置/空槽位不生成按钮。
## 宁可少一个入口，也不给玩家一个点了没反应的按钮。
func _rebuild_buttons() -> void:
	for child: Node in _buttons_container.get_children():
		_buttons_container.remove_child(child)
		child.queue_free()
	_buttons.clear()
	var limit: int = mini(encounters.size(), MAX_ENCOUNTERS)
	for index: int in limit:
		var encounter: EncounterDefinition = encounters[index]
		if encounter == null or not encounter.is_configured():
			continue
		var button: Button = Button.new()
		button.name = "Encounter%d" % (index + 1)
		button.text = encounter.display_name
		button.pressed.connect(_on_encounter_button_pressed.bind(encounter))
		_buttons_container.add_child(button)
		_buttons.append(button)


## 点击只发信号：面板不认识 EncounterSession，也不写任何战斗状态。
## 运行中即使被程序化触发也不转发，保证「战斗进行中禁止再次进入」这条语义不依赖按钮禁用。
func _on_encounter_button_pressed(encounter: EncounterDefinition) -> void:
	if _running:
		return
	if encounter == null or not encounter.is_configured():
		return
	encounter_selected.emit(encounter)


func _on_restart_pressed() -> void:
	# 外部锁由主场景决定（秘境进行中）；被锁定后即使程序化触发也不转发。
	if _restart_locked:
		return
	restart_requested.emit()


## 运行中：遭遇按钮不可用（禁止中途换敌），重新挑战可用。
## 空闲：遭遇按钮可用；重新挑战只有在「已经有一场遭遇」时才有意义，因此没开局时保持禁用。
func _apply_interaction_states() -> void:
	for button: Button in _buttons:
		if is_instance_valid(button):
			button.disabled = _running
	if is_instance_valid(_restart_button):
		_restart_button.disabled = _restart_locked or _active_encounter == null


func _refresh_title() -> void:
	if _title_label == null:
		return
	if _active_encounter == null:
		_title_label.text = "秘境遭遇"
	else:
		_title_label.text = "当前遭遇：%s" % _active_encounter.display_name
