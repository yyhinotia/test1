class_name PassiveSkillDefinition
extends Resource

## 被动技能静态配置：只回答“这个被动需要什么境界才能装下”。
## 属性强化、条件触发与 Build 联动的实际结算属于后续 Increment，本资源不持有任何运行时数值。

@export var id: StringName = &"passive"
@export var display_name: String = "被动"
## 装备所需的最低境界 tier；1 表示炼气期即可装备。
@export_range(1, 100, 1, "or_greater") var required_realm_tier: int = 1

func is_configured() -> bool:
	return not String(id).strip_edges().is_empty()