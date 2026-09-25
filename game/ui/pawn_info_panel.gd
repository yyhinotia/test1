class_name PawnInfoPanel
extends Control

## Pawn 信息卡：只读展示选中单位的身份、资源状态、核心属性与 Build 摘要。
## 绑定期间只通过 Pawn / PawnData 的既有信号刷新，不做每帧轮询；
## 本组件不修改任何业务数值，也不把 UI 引用写进 Pawn 或 PawnData（禁止 `pawn.hp_label` 这类耦合）。

signal pawn_bound(pawn: Pawn)
signal pawn_unbound(pawn: Pawn)
signal refreshed(snapshot: Dictionary)

const HEALTH_RESOURCE_ID: StringName = HealthComponent.HEALTH_RESOURCE_ID
const SHIELD_RESOURCE_ID: StringName = HealthComponent.SHIELD_RESOURCE_ID
const SPIRIT_RESOURCE_ID: StringName = Pawn.SPIRIT_RESOURCE_ID

@onready var name_label: Label = $Margin/Panel/Content/HeaderSection/NameLabel
@onready var identity_label: Label = $Margin/Panel/Content/HeaderSection/IdentityLabel
@onready var vital_section: VBoxContainer = $Margin/Panel/Content/VitalSection
@onready var health_row: HBoxContainer = $Margin/Panel/Content/VitalSection/HealthRow
@onready var health_label: Label = $Margin/Panel/Content/VitalSection/HealthRow/ValueLabel
@onready var health_bar: ResourceBar = $Margin/Panel/Content/VitalSection/HealthRow/ResourceBar
@onready var shield_row: HBoxContainer = $Margin/Panel/Content/VitalSection/ShieldRow
@onready var shield_label: Label = $Margin/Panel/Content/VitalSection/ShieldRow/ValueLabel
@onready var shield_bar: ResourceBar = $Margin/Panel/Content/VitalSection/ShieldRow/ResourceBar
@onready var spirit_row: HBoxContainer = $Margin/Panel/Content/VitalSection/SpiritRow
@onready var spirit_label: Label = $Margin/Panel/Content/VitalSection/SpiritRow/ValueLabel
@onready var spirit_bar: ResourceBar = $Margin/Panel/Content/VitalSection/SpiritRow/ResourceBar
@onready var attribute_section: VBoxContainer = $Margin/Panel/Content/AttributeSection
@onready var attribute_label: Label = $Margin/Panel/Content/AttributeSection/AttributeLabel
@onready var build_section: VBoxContainer = $Margin/Panel/Content/BuildSection
@onready var build_label: Label = $Margin/Panel/Content/BuildSection/BuildLabel
@onready var cultivation_section: VBoxContainer = $Margin/Panel/Content/CultivationSection
@onready var cultivation_label: Label = $Margin/Panel/Content/CultivationSection/CultivationLabel
@onready var cultivation_progress: ProgressBar = $Margin/Panel/Content/CultivationSection/CultivationProgress

var _pawn: Pawn
var _compact: bool = false
var _snapshot: Dictionary = {}

func _ready() -> void:
	visible = false
	_clear_display()
	_update_section_visibility()

## 绑定单位：重复绑定同一单位只刷新，不重复连接信号；绑定新单位前先解除旧绑定。
func bind_pawn(pawn: Pawn) -> void:
	if pawn == null:
		unbind()
		return
	if pawn == _pawn and is_instance_valid(_pawn):
		refresh()
		return
	unbind()
	_pawn = pawn
	_connect_pawn_signals()
	visible = true
	refresh()
	pawn_bound.emit(_pawn)

## 解除绑定：断开全部 Pawn / PawnData 信号并解绑资源条，之后旧单位的变化不再影响面板。
func unbind() -> void:
	if _pawn == null:
		visible = false
		_clear_display()
		return
	var unbound_pawn: Pawn = _pawn
	_disconnect_pawn_signals()
	_release_resource_bars()
	_pawn = null
	_snapshot = {}
	_clear_display()
	visible = false
	pawn_unbound.emit(unbound_pawn)

func is_bound() -> bool:
	return _pawn != null and is_instance_valid(_pawn)

func get_bound_pawn() -> Pawn:
	return _pawn

## 当前渲染快照的副本；测试与调试用，调用方修改副本不会影响面板状态。
func get_snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

## 精简模式（战斗中）：只保留身份与资源状态；完整模式（暂停/非战斗）：追加属性与 Build。
func set_compact(value: bool) -> void:
	_compact = value
	_update_section_visibility()

func is_compact() -> bool:
	return _compact

## 立即重算快照并刷新文本；信号回调与测试都走这一条路径，避免多套刷新入口。
func refresh() -> void:
	if not is_bound():
		_snapshot = {}
		_clear_display()
		refreshed.emit(_snapshot)
		return
	_snapshot = PawnInfoModel.build_snapshot(_pawn.data, _read_runtime_values())
	_render(_snapshot)
	refreshed.emit(_snapshot)

## 运行时数值只从 Pawn 的只读代理与资源池读取，绝不回写。
## 容量与校验结论来自 Pawn 的 Build 汇总接口，UI 不重复实现规则。
func _read_runtime_values() -> Dictionary:
	var runtime: Dictionary = {
		PawnInfoModel.HEALTH_KEY: _read_pool_values(HEALTH_RESOURCE_ID),
		PawnInfoModel.SHIELD_KEY: _read_pool_values(SHIELD_RESOURCE_ID),
		PawnInfoModel.SPIRIT_KEY: _read_pool_values(SPIRIT_RESOURCE_ID),
	}
	var loadout: BuildLoadout = _pawn.get_build_loadout()
	runtime["technique_used"] = loadout.get_used_slots(RealmDefinition.KIND_TECHNIQUE)
	runtime["technique_max"] = loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)
	runtime["weapon_used"] = loadout.get_used_slots(RealmDefinition.KIND_WEAPON)
	runtime["weapon_max"] = loadout.get_capacity(RealmDefinition.KIND_WEAPON)
	runtime["active_skill_used"] = loadout.get_used_slots(RealmDefinition.KIND_ACTIVE_SKILL)
	runtime["active_skill_max"] = loadout.get_capacity(RealmDefinition.KIND_ACTIVE_SKILL)
	runtime["passive_skill_used"] = loadout.get_used_slots(RealmDefinition.KIND_PASSIVE_SKILL)
	runtime["passive_skill_max"] = loadout.get_capacity(RealmDefinition.KIND_PASSIVE_SKILL)
	runtime["build_error_summary"] = _pawn.get_build_validation().get_summary()
	runtime["cultivation"] = _pawn.get_cultivation_snapshot()
	return runtime

## 单个资源池的只读数值；无池或上限为 0 时返回 null，表示该资源不存在。
func _read_pool_values(resource_id: StringName) -> Variant:
	if not is_bound():
		return null
	var pool: ResourcePoolComponent = _pawn.get_resource_pool(resource_id)
	if pool == null or pool.max_value <= 0.0:
		return null
	return {"current": pool.current_value, "max": pool.max_value}

func _render(snapshot: Dictionary) -> void:
	var identity_lines: Array[String] = PawnInfoModel.identity_lines(snapshot)
	if identity_lines.size() >= 4:
		name_label.text = identity_lines[0]
		identity_label.text = _join_lines(identity_lines, 1)
	attribute_label.text = PawnInfoModel.attribute_line(snapshot)
	build_label.text = _join_lines(PawnInfoModel.build_lines(snapshot), 0)
	cultivation_label.text = PawnInfoModel.cultivation_line(snapshot)
	cultivation_progress.value = PawnInfoModel.cultivation_ratio(snapshot)
	_render_vital(HEALTH_RESOURCE_ID, PawnInfoModel.HEALTH_KEY, health_row, health_label, health_bar)
	_render_vital(SHIELD_RESOURCE_ID, PawnInfoModel.SHIELD_KEY, shield_row, shield_label, shield_bar)
	_render_vital(SPIRIT_RESOURCE_ID, PawnInfoModel.SPIRIT_KEY, spirit_row, spirit_label, spirit_bar)
	_update_section_visibility()

## 资源行整行显隐由“该资源是否存在”决定：无池的单位不显示对应行，也不占布局空间。
func _render_vital(resource_id: StringName, key: String, row: HBoxContainer, value_label: Label, bar: ResourceBar) -> void:
	var line: String = PawnInfoModel.vital_line(_snapshot, key)
	var has_resource: bool = not line.is_empty()
	row.visible = has_resource
	value_label.text = line
	if has_resource and is_bound():
		bar.bind_pool(_pawn.get_resource_pool(resource_id))
	else:
		bar.unbind_pool()

func _update_section_visibility() -> void:
	attribute_section.visible = not _compact
	build_section.visible = not _compact
	cultivation_section.visible = not _compact and not cultivation_label.text.is_empty()
	vital_section.visible = true

func _clear_display() -> void:
	if name_label == null:
		return
	name_label.text = ""
	identity_label.text = ""
	attribute_label.text = ""
	build_label.text = ""
	cultivation_label.text = ""
	cultivation_progress.value = 0.0
	cultivation_section.visible = false
	health_label.text = ""
	shield_label.text = ""
	spirit_label.text = ""
	for row: HBoxContainer in [health_row, shield_row, spirit_row]:
		row.visible = false
	_release_resource_bars()

func _release_resource_bars() -> void:
	if health_bar == null:
		return
	health_bar.unbind_pool()
	shield_bar.unbind_pool()
	spirit_bar.unbind_pool()

func _connect_pawn_signals() -> void:
	_connect_signal(_pawn.health_changed, _on_vital_changed)
	_connect_signal(_pawn.shield_changed, _on_vital_changed)
	_connect_signal(_pawn.spirit_changed, _on_vital_changed)
	_connect_signal(_pawn.cultivation_changed, _on_cultivation_changed)
	_connect_signal(_pawn.state_changed, _on_state_changed)
	_connect_signal(_pawn.died, _on_died)
	if _pawn.data != null:
		_connect_signal(_pawn.data.identity_changed, _on_data_changed)
		_connect_signal(_pawn.data.attributes_changed, _on_data_changed)
		_connect_signal(_pawn.data.realm_changed, _on_data_changed)
		_connect_signal(_pawn.data.build_changed, _on_data_changed)

func _disconnect_pawn_signals() -> void:
	if not is_instance_valid(_pawn):
		return
	_disconnect_signal(_pawn.health_changed, _on_vital_changed)
	_disconnect_signal(_pawn.shield_changed, _on_vital_changed)
	_disconnect_signal(_pawn.spirit_changed, _on_vital_changed)
	_disconnect_signal(_pawn.cultivation_changed, _on_cultivation_changed)
	_disconnect_signal(_pawn.state_changed, _on_state_changed)
	_disconnect_signal(_pawn.died, _on_died)
	if _pawn.data != null:
		_disconnect_signal(_pawn.data.identity_changed, _on_data_changed)
		_disconnect_signal(_pawn.data.attributes_changed, _on_data_changed)
		_disconnect_signal(_pawn.data.realm_changed, _on_data_changed)
		_disconnect_signal(_pawn.data.build_changed, _on_data_changed)

func _connect_signal(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		return
	source.connect(target)

func _disconnect_signal(source: Signal, target: Callable) -> void:
	if source.is_connected(target):
		source.disconnect(target)

func _on_vital_changed(_changed_pawn: Pawn, _current_value: float, _max_value: float) -> void:
	refresh()

func _on_cultivation_changed(_changed_pawn: Pawn, _current_exp: float, _required_exp: float) -> void:
	refresh()

func _on_state_changed(_changed_pawn: Pawn, _new_state: int) -> void:
	refresh()

func _on_died(_changed_pawn: Pawn) -> void:
	refresh()

func _on_data_changed(_data: PawnData) -> void:
	refresh()

func _join_lines(lines: Array[String], from_index: int) -> String:
	var parts: Array[String] = []
	for index: int in range(from_index, lines.size()):
		parts.append(lines[index])
	return "\n".join(PackedStringArray(parts))
