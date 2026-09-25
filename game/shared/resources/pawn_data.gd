class_name PawnData
extends Resource

## Static configuration for a Pawn. Runtime values live on the runtime scene resource pools
## (`Pawn/Resources/Health`、`Pawn/Resources/Shield`、可选的 `Pawn/Resources/Spirit`)，never on this Resource.
##
## 视图契约：静态数据变更时由修改方调用 `notify_*_changed()` 通知观察者（例如 Pawn 信息卡）。
## 这些信号只做变更通知，不承载也不存储运行时数值——生命/护盾/灵力的变更由 Pawn 的资源池信号负责。
signal identity_changed(data: PawnData)
signal attributes_changed(data: PawnData)
signal realm_changed(data: PawnData)
signal build_changed(data: PawnData)

@export var id: StringName = &"pawn_000"
@export var display_name: String = "Pawn"
@export var faction: StringName = &"neutral"
## 小境界显示名（例如“三层”）；空字符串表示未设定，由 UI 决定占位文案。
@export var sub_realm: String = ""
## 灵根显示名（例如“金灵根”）；空表示未设定。
@export var spirit_root: StringName = &""
@export var max_health: float = 100.0
@export var max_shield: float = 0.0
## 灵力（技能蓝条）上限；默认 0 表示该单位没有灵力资源，也不会创建灵力池与灵力条。
@export_range(0.0, 1000000.0, 0.1, "or_greater") var max_spirit: float = 0.0
## 出生时灵力的初始比例（0..1）；灵力池只在 max_spirit > 0 时创建。
@export_range(0.0, 1.0, 0.001) var initial_spirit_ratio: float = 1.0
## 旧版单主动技能字段：保留用于兼容既有预设与调用方；新配置应优先填写 `active_skills`。
@export var active_skill: ActiveSkillDefinition
## 有序主动技能列表；非空时它是唯一权威来源，空列表才回退到旧的 `active_skill`。
@export var active_skills: Array[ActiveSkillDefinition] = []
## 可选的主武器配置；null 表示该单位没有武器，Build 校验与信息卡按“无武器”处理。
@export var weapon: WeaponDefinition
## 可选的境界配置；null 表示该单位没有修炼体系（例如傀儡），Build 校验会返回 missing_realm。
@export var realm: RealmDefinition
## 出生时的修为初始值；运行时进度由 Pawn/CultivationProgress 持有，此字段只表达预设起始点。
@export_range(0.0, 1000000000.0, 0.1, "or_greater") var initial_cultivation_exp: float = 0.0
## 已装备功法；只在 `realm` 有效时参与 Build 容量与冲突校验。
@export var techniques: Array[TechniqueDefinition] = []
@export var attack: float = 10.0
@export var defense: float = 0.0
@export var move_speed: float = 100.0
@export var attack_range: float = 48.0
@export var attack_interval: float = 1.0
@export var display_color: Color = Color(0.85, 0.85, 0.85, 1.0)

## 以下通知方法由数据修改方在值变更后显式调用；不在 @export setter 中触发，
## 避免编辑器导入/检查资源时产生信号副作用。
func notify_identity_changed() -> void:
	identity_changed.emit(self)

func notify_attributes_changed() -> void:
	attributes_changed.emit(self)

func notify_realm_changed() -> void:
	realm_changed.emit(self)

func notify_build_changed() -> void:
	build_changed.emit(self)

## 返回当前生效的有序主动技能列表。
## 新列表非空时不再读取旧字段；同一 id 只返回一次，避免新旧字段同时配置造成重复槽位。
func get_active_skills() -> Array[ActiveSkillDefinition]:
	var result: Array[ActiveSkillDefinition] = []
	var source: Array[ActiveSkillDefinition] = []
	if not active_skills.is_empty():
		source = active_skills
	elif active_skill != null:
		source.append(active_skill)

	var seen_ids: Array[StringName] = []
	for skill: ActiveSkillDefinition in source:
		if skill == null or not skill.is_configured():
			continue
		if seen_ids.has(skill.id):
			continue
		seen_ids.append(skill.id)
		result.append(skill)
	return result

## 第一个主动技能：Q 和旧调用方的兼容入口；没有有效技能时返回 null。
func get_primary_active_skill() -> ActiveSkillDefinition:
	var skills: Array[ActiveSkillDefinition] = get_active_skills()
	return skills[0] if not skills.is_empty() else null