class_name PawnData
extends Resource

## Static configuration for a Pawn. Runtime values live on the runtime scene resource pools
## (`Pawn/Resources/Health`、`Pawn/Resources/Shield`、可选的 `Pawn/Resources/Spirit`)，never on this Resource.
##
## 视图契约：静态数据变更时由修改方调用 `notify_*_changed()` 通知观察者（例如 Pawn 信息卡）。
## 这些信号只做变更通知，不承载也不存储运行时数值——生命/护盾/灵力的变更由 Pawn 的资源池信号负责。

## 问题标签（INC-COMBAT-011）：敌人提出的战斗问题，与玩家技能价值轴一一对应。
## NONE 表示该单位不是问题源（例如召唤物），不参与问题型遭遇编排。
enum ProblemTag {
	NONE,
	SUSTAINED_MELEE,
	RANGED_PRESSURE,
	BURST_PRESSURE,
	HIGH_DEFENSE,
	CHARGE_INTERRUPT,
	SUMMON_REINFORCEMENT,
}
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
## 危险技能窗口（INC-COMBAT-009）：敌人周期性蓄力、无法被普通手段阻止的技能。
## 该字段独立于 active_skills，不会进入普通技能栏，也不会被 AIController 当作普通技能施放。
@export var dangerous_skill: ActiveSkillDefinition
@export_range(0.0, 1000.0, 0.1, "or_greater") var danger_window_interval: float = 0.0
@export_range(0.0, 100.0, 0.1, "or_greater") var danger_window_duration: float = 0.0
## 敌人提出的战斗问题（数据可见，供遭遇编排与自动化断言使用）；NONE 表示不承担问题型角色。
@export var problem_tag: ProblemTag = ProblemTag.NONE
## 召唤增援契约（INC-COMBAT-011）：summon_minion 非空、间隔为正且数量上限为正时，
## EncounterSession 按固定节奏生成增援；增援计入敌方队伍，因此胜利仍要求敌方全灭。
@export var summon_minion: PawnData
@export_range(0.0, 1000.0, 0.1, "or_greater") var summon_initial_delay: float = 0.0
@export_range(0.0, 1000.0, 0.1, "or_greater") var summon_interval: float = 0.0
@export_range(0, 20, 1, "or_greater") var summon_max_count: int = 0

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

## 是否配置了完整的危险窗口：技能有效且窗口间隔 / 时长都为正数。
func has_danger_window() -> bool:
	return (
		dangerous_skill != null
		and dangerous_skill.is_configured()
		and danger_window_interval > 0.0
		and danger_window_duration > 0.0
	)


## 返回当前生效的有序主动技能列表。
## 新列表非空时不再读取旧字段；同一 id 只返回一次，避免新旧字段同时配置造成重复槽位。


## 是否配置了可用的召唤增援契约：问题标签、增援档案、间隔与数量上限缺一不可。
func can_summon() -> bool:
	return (
		problem_tag == ProblemTag.SUMMON_REINFORCEMENT
		and summon_minion != null
		and summon_interval > 0.0
		and summon_max_count > 0
	)


## 问题标签的中文短标签（静态版）：供秘境房间 / 遭遇等非 Pawn 数据复用同一份文案表，
## 避免「敌人侧」与「编排侧」各写一份映射后漂移（INC-WORLD-008）。
static func get_problem_tag_label_for(tag: int) -> String:
	match tag:
		ProblemTag.SUSTAINED_MELEE:
			return "近战持续压力"
		ProblemTag.RANGED_PRESSURE:
			return "远程压制"
		ProblemTag.BURST_PRESSURE:
			return "高爆发"
		ProblemTag.HIGH_DEFENSE:
			return "高防御"
		ProblemTag.CHARGE_INTERRUPT:
			return "蓄力可打断"
		ProblemTag.SUMMON_REINFORCEMENT:
			return "召唤增援"
		_:
			return ""


## 该问题对应的玩家技能价值轴（静态版，与六类技能效果一一对应）；未知 / NONE 返回 &"none"。
static func get_skill_value_axis_for(tag: int) -> StringName:
	match tag:
		ProblemTag.SUSTAINED_MELEE:
			return &"single_target_damage"
		ProblemTag.RANGED_PRESSURE:
			return &"dash"
		ProblemTag.BURST_PRESSURE:
			return &"defense"
		ProblemTag.HIGH_DEFENSE:
			return &"lifesteal"
		ProblemTag.CHARGE_INTERRUPT:
			return &"control"
		ProblemTag.SUMMON_REINFORCEMENT:
			return &"area_damage"
		_:
			return &"none"


## 问题标签的中文短标签，供遭遇面板与日志使用；NONE 返回空串。
func get_problem_tag_label() -> String:
	return get_problem_tag_label_for(problem_tag)


## 该单位提出的问题对应的玩家技能价值轴；NONE 返回 &"none"。
func get_skill_value_axis() -> StringName:
	return get_skill_value_axis_for(problem_tag)


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