class_name TechniqueDefinition
extends Resource

## 功法静态配置：回答“这个功法属于哪个流派、需要什么境界、和谁互斥”。
## 功法本身不授予技能、不结算属性；授予与解锁属于后续 Increment，本资源只作为 Build 校验的输入。

@export var id: StringName = &"technique"
@export var display_name: String = "功法"
## 修炼流派标识（剑 / 雷 / 体 / 阵 / 魂），供后续流派联动使用；当前不参与校验。
@export var school: StringName = &"sword"
@export var description: String = ""
## 修习所需的最低境界 tier；1 表示炼气期即可修习。
@export_range(1, 100, 1, "or_greater") var required_realm_tier: int = 1
## 互斥标签：任意两个功法共享同一标签即不可同时装备（如剑修与体修共用 sword_body_conflict）。
@export var conflict_tags: Array[StringName] = []

func is_configured() -> bool:
	return not String(id).strip_edges().is_empty()

## 返回与另一功法的首个共享互斥标签；没有冲突时返回空 StringName，调用方可直接做布尔判断。
func get_shared_conflict_tag(other: TechniqueDefinition) -> StringName:
	if other == null:
		return &""
	for tag: StringName in conflict_tags:
		if other.conflict_tags.has(tag):
			return tag
	return &""