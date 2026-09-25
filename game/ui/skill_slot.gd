class_name SkillSlot
extends Control

## 固定 64x64 的单个技能格：只读取状态模型并发出点击请求，不修改 Pawn、灵力或冷却。
## 视觉职责只覆盖格子本身；队列、快捷键与目标路由由 SkillBar/Main 负责。

signal cast_requested(skill: ActiveSkillDefinition)

## 交互状态与「可施放状态」分离：`SkillSlotState` 回答“现在能不能放”，
## 本枚举回答“玩家当前选中/正在瞄准哪个格子”，两者不得互相冒充。
enum InteractionState {
	NORMAL,
	SELECTED,
	TARGETING,
}

const INTERACTION_NORMAL: StringName = &"NORMAL"
const INTERACTION_SELECTED: StringName = &"SELECTED"
const INTERACTION_TARGETING: StringName = &"TARGETING"

const SLOT_SIZE: float = 64.0
const EMPTY_ICON_TEXT: String = "—"
const COLOR_BG_EMPTY: Color = Color(0.05, 0.06, 0.08, 0.92)
const COLOR_BG_READY: Color = Color(0.11, 0.16, 0.20, 0.98)
const COLOR_BG_COOLDOWN: Color = Color(0.09, 0.11, 0.14, 0.98)
const COLOR_BG_NO_RESOURCE: Color = Color(0.22, 0.10, 0.08, 0.98)
const COLOR_BG_DISABLED: Color = Color(0.10, 0.10, 0.10, 0.98)
const COLOR_COST_NORMAL: Color = Color(0.78, 0.86, 1.0, 1.0)
const COLOR_COST_EMPHASIS: Color = Color(1.0, 0.42, 0.25, 1.0)

@onready var background: ColorRect = $Background
@onready var icon_label: Label = $Icon
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownLabel
@onready var cost_label: Label = $CostLabel
@onready var hotkey_label: Label = $HotkeyLabel
@onready var state_highlight: Panel = $StateHighlight
@onready var targeting_highlight: Panel = $TargetingHighlight

var _pawn: Pawn
var _skill: ActiveSkillDefinition
var _hotkey_text: String = ""
var _interaction_state: int = InteractionState.NORMAL
var _snapshot: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_snapshot(_empty_snapshot())

## 绑定/刷新只读取模型；同一个技能格可以随 Pawn 切换重复绑定。
func bind_skill(pawn: Pawn, skill: ActiveSkillDefinition, hotkey_text: String = "") -> void:
	_pawn = pawn
	_skill = skill
	_hotkey_text = hotkey_text
	refresh()

func unbind() -> void:
	show_empty("")

## 空槽仍保留快捷键编号；快捷栏用它在容量未满时维持稳定布局。
func show_empty(hotkey_text: String = "") -> void:
	_pawn = null
	_skill = null
	_hotkey_text = hotkey_text
	_interaction_state = InteractionState.NORMAL
	_snapshot = _empty_snapshot()
	_apply_snapshot(_snapshot)

func set_hotkey(hotkey_text: String) -> void:
	_hotkey_text = hotkey_text
	_apply_snapshot(_snapshot)

## 兼容入口：SELECTED / NORMAL 的旧语义，等价于 set_interaction_state()。
func set_selected(value: bool) -> void:
	set_interaction_state(InteractionState.SELECTED if value else InteractionState.NORMAL)

func is_selected() -> bool:
	return _interaction_state == InteractionState.SELECTED

## 交互状态只改变格子自身的表现，不读取也不修改 Pawn 的资源、冷却或控制器命令。
func set_interaction_state(state: int) -> void:
	if state != InteractionState.NORMAL and state != InteractionState.SELECTED and state != InteractionState.TARGETING:
		state = InteractionState.NORMAL
	if _interaction_state == state:
		_apply_interaction_state()
		return
	_interaction_state = state
	_apply_interaction_state()

func get_interaction_state() -> int:
	return _interaction_state

func get_interaction_state_name() -> StringName:
	match _interaction_state:
		InteractionState.SELECTED:
			return INTERACTION_SELECTED
		InteractionState.TARGETING:
			return INTERACTION_TARGETING
		_:
			return INTERACTION_NORMAL

func is_targeting() -> bool:
	return _interaction_state == InteractionState.TARGETING

## 选中框与瞄准框分离：瞄准必须能被一眼区分，且只在技能格内部绘制。
func _apply_interaction_state() -> void:
	var configured: bool = has_skill()
	if state_highlight != null:
		state_highlight.visible = configured and _interaction_state == InteractionState.SELECTED
	if targeting_highlight != null:
		targeting_highlight.visible = configured and _interaction_state == InteractionState.TARGETING

func has_skill() -> bool:
	return _skill != null and _skill.is_configured()

func get_skill() -> ActiveSkillDefinition:
	return _skill

func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

func refresh() -> void:
	if _skill == null:
		_snapshot = _empty_snapshot()
	else:
		_snapshot = SkillSlotState.for_pawn(_pawn, _skill)
	_apply_snapshot(_snapshot)

func _apply_snapshot(snapshot: Dictionary) -> void:
	if background == null:
		return
	var state_name: StringName = StringName(snapshot.get("state_name", SkillSlotState.STATE_EMPTY))
	var configured: bool = _skill != null and _skill.is_configured()
	var ratio: float = clampf(float(snapshot.get("cooldown_ratio", 0.0)), 0.0, 1.0)
	var remaining: float = maxf(float(snapshot.get("cooldown_remaining", 0.0)), 0.0)
	var cost: float = float(snapshot.get("cost", 0.0))

	background.color = _background_color_for(state_name)
	hotkey_label.text = _hotkey_text
	hotkey_label.visible = not _hotkey_text.is_empty()
	icon_label.text = _icon_text(snapshot)
	cost_label.text = ("%d" % int(round(cost))) if configured else ""
	cost_label.visible = configured
	cooldown_label.text = ("%.1f" % remaining) if state_name == SkillSlotState.STATE_COOLDOWN and remaining > 0.0 else ""
	cooldown_label.visible = not cooldown_label.text.is_empty()
	cooldown_overlay.visible = state_name == SkillSlotState.STATE_COOLDOWN and ratio > 0.0
	cooldown_overlay.offset_bottom = SLOT_SIZE * ratio
	_apply_interaction_state()
	_apply_state_tint(state_name)
	cost_label.add_theme_color_override(
		"font_color",
		COLOR_COST_EMPHASIS if state_name == SkillSlotState.STATE_NO_RESOURCE else COLOR_COST_NORMAL
	)

func _apply_state_tint(state_name: StringName) -> void:
	match state_name:
		SkillSlotState.STATE_NO_RESOURCE:
			modulate = Color(0.78, 0.78, 0.78, 1.0)
		SkillSlotState.STATE_DISABLED:
			modulate = Color(0.48, 0.48, 0.48, 1.0)
		_:
			modulate = Color.WHITE

func _background_color_for(state_name: StringName) -> Color:
	match state_name:
		SkillSlotState.STATE_READY:
			return COLOR_BG_READY
		SkillSlotState.STATE_COOLDOWN:
			return COLOR_BG_COOLDOWN
		SkillSlotState.STATE_NO_RESOURCE:
			return COLOR_BG_NO_RESOURCE
		SkillSlotState.STATE_DISABLED:
			return COLOR_BG_DISABLED
		_:
			return COLOR_BG_EMPTY

func _icon_text(snapshot: Dictionary) -> String:
	if _skill == null or not _skill.is_configured():
		return EMPTY_ICON_TEXT
	var display_name: String = String(snapshot.get("display_name", _skill.display_name)).strip_edges()
	if display_name.is_empty():
		return EMPTY_ICON_TEXT
	return display_name.substr(0, 1)

func _empty_snapshot() -> Dictionary:
	return {
		"state": SkillSlotState.State.EMPTY,
		"state_name": SkillSlotState.STATE_EMPTY,
		"skill_id": &"",
		"display_name": "",
		"cost": 0.0,
		"current_spirit": 0.0,
		"cooldown_remaining": 0.0,
		"cooldown_total": 0.0,
		"cooldown_ratio": 0.0,
		"can_cast": false,
		"reason": "",
	}

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if not has_skill():
		return
	cast_requested.emit(_skill)
	accept_event()
