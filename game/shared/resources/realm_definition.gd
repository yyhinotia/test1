class_name RealmDefinition
extends Resource

## 境界静态配置：境界决定 Build 容量，不持有任何运行时数值。
## 属性加成、突破与修炼速度属于后续 Increment；本资源只回答“这个境界能装下多少功法/武器/技能”。
## Build 槽位类别常量定义在这里，使容量查询只有 `get_slot_capacity()` 一个来源。

const KIND_TECHNIQUE: StringName = &"technique"
const KIND_WEAPON: StringName = &"weapon"
const KIND_ACTIVE_SKILL: StringName = &"active_skill"
const KIND_PASSIVE_SKILL: StringName = &"passive_skill"
## 槽位类别的唯一顺序来源：功法 → 武器 → 主动 → 被动，校验与 UI 都按此顺序遍历。
const ALL_KINDS: Array[StringName] = [KIND_TECHNIQUE, KIND_WEAPON, KIND_ACTIVE_SKILL, KIND_PASSIVE_SKILL]

@export var id: StringName = &"realm"
@export var display_name: String = "境界"
## 境界顺序：炼气 1 → 筑基 2 → 金丹 3 → 元婴 4 → 化神 5；用于“境界不足”校验。
@export_range(1, 100, 1, "or_greater") var tier: int = 1
@export_range(0, 100, 1, "or_greater") var technique_slots: int = 1
## 主武器槽数量；MVP 假设一名修士同时只持一把主武器，且武器槽不随境界递增。
@export_range(0, 100, 1, "or_greater") var weapon_slots: int = 1
@export_range(0, 100, 1, "or_greater") var active_skill_slots: int = 2
@export_range(0, 100, 1, "or_greater") var passive_skill_slots: int = 1

## 下一个境界的显式资源引用；null 表示当前已到本阶段终点。
@export var next_realm: RealmDefinition
## 进入下一境界需要的修为；只有存在有效 next_realm 时才参与运行时进度计算。
@export_range(0.0, 1000000000.0, 0.1, "or_greater") var breakthrough_exp: float = 0.0

func is_configured() -> bool:
	return not String(id).strip_edges().is_empty()

## 是否配置了有效下一境界；资源未配置时即使引用存在也视为没有下一步。
func has_next_realm() -> bool:
	return next_realm != null and next_realm.is_configured()

## 返回可用的下一境界；终点或无效引用统一返回 null。
func get_next_realm() -> RealmDefinition:
	return next_realm if has_next_realm() else null

## 返回突破所需修为；无下一境界时恒为 0，避免 UI 显示伪进度。
func get_breakthrough_exp() -> float:
	if not has_next_realm():
		return 0.0
	return maxf(breakthrough_exp, 0.0)

## Build 容量的唯一来源：未知类别返回 0，避免调用方各自硬编码字段或默认值。
func get_slot_capacity(kind: StringName) -> int:
	match kind:
		KIND_TECHNIQUE:
			return maxi(technique_slots, 0)
		KIND_WEAPON:
			return maxi(weapon_slots, 0)
		KIND_ACTIVE_SKILL:
			return maxi(active_skill_slots, 0)
		KIND_PASSIVE_SKILL:
			return maxi(passive_skill_slots, 0)
		_:
			return 0