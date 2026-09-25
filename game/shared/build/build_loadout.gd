class_name BuildLoadout
extends Resource

## 一次 Build 的只读汇总：境界 + 已装备功法 / 武器 / 主动技能 / 被动技能。
## 本类只承载数据，不做校验、不装备、不卸载、不修改任何运行时数值；校验交给 BuildValidator。

@export var realm: RealmDefinition
@export var techniques: Array[TechniqueDefinition] = []
@export var weapons: Array[WeaponDefinition] = []
@export var active_skills: Array[ActiveSkillDefinition] = []
@export var passives: Array[PassiveSkillDefinition] = []

## 容量查询统一走境界：没有境界时容量视为 0，避免出现“无境界却可无限装备”的隐式规则。
func get_capacity(kind: StringName) -> int:
	if realm == null:
		return 0
	return realm.get_slot_capacity(kind)

## 已占用槽位数：只统计非空条目，空条目由校验器单独报“未配置”。
func get_used_slots(kind: StringName) -> int:
	var used: int = 0
	for entry: Variant in get_entries(kind):
		if entry != null:
			used += 1
	return used

## 主武器：MVP 只有一把主武器，返回首个非空条目；没有装备时返回 null。
func get_weapon() -> WeaponDefinition:
	for entry: WeaponDefinition in weapons:
		if entry != null:
			return entry
	return null

## 按槽位类别取条目列表；未知类别返回空数组，调用方不需要自己 match 字段。
func get_entries(kind: StringName) -> Array:
	match kind:
		RealmDefinition.KIND_TECHNIQUE:
			return techniques
		RealmDefinition.KIND_WEAPON:
			return weapons
		RealmDefinition.KIND_ACTIVE_SKILL:
			return active_skills
		RealmDefinition.KIND_PASSIVE_SKILL:
			return passives
		_:
			return []