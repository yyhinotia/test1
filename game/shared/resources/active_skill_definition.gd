class_name ActiveSkillDefinition
extends Resource

## 主动技能的静态配置。当前冷却等运行时状态由施法者 Pawn 持有。
## 本资源只回答“这个技能需要什么条件、造成多少倍率伤害”，不直接修改生命、灵力或 UI。

@export var id: StringName = &"skill"
@export var display_name: String = "技能"
@export_range(0.0, 1000000.0, 0.1, "or_greater") var spirit_cost: float = 0.0
@export_range(0.0, 1000000.0, 0.01, "or_greater") var cooldown: float = 1.0
## 施法距离；小于等于 0 时回退到施法者的普通攻击距离。
@export_range(0.0, 1000000.0, 1.0, "or_greater") var cast_range: float = 0.0
@export_range(0.0, 100.0, 0.01, "or_greater") var damage_multiplier: float = 1.0

func is_configured() -> bool:
	return not String(id).strip_edges().is_empty()

func get_effective_cast_range(fallback_range: float) -> float:
	if cast_range > 0.0:
		return cast_range
	return maxf(fallback_range, 0.0)

func get_normalized_spirit_cost() -> float:
	return maxf(spirit_cost, 0.0)

func get_normalized_cooldown() -> float:
	return maxf(cooldown, 0.0)

func get_normalized_damage_multiplier() -> float:
	return maxf(damage_multiplier, 0.0)