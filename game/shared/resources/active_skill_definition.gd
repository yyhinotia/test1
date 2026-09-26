class_name ActiveSkillDefinition
extends Resource

## 主动技能的静态配置。当前冷却等运行时状态由施法者 Pawn 持有。
## 本资源只回答“这个技能需要什么条件、作用于哪类目标、产生哪类效果”，不直接修改生命、灵力或 UI。

enum SkillTargetType {
	SELF,
	ALLY,
	ENEMY,
}

enum SkillEffectType {
	DAMAGE,
	HEAL,
	SHIELD,
	STUN,
	## 位移：沿目标方向贴近（INC-COMBAT-010）。
	DASH,
	## 范围伤害：以主目标为中心打击半径内的敌对单位（INC-COMBAT-010）。
	AOE_DAMAGE,
	## 吸血：造成伤害后按比例回复施法者（INC-COMBAT-010）。
	LIFESTEAL,
}

@export var id: StringName = &"skill"
@export var display_name: String = "技能"
@export_multiline var description: String = ""
@export_range(0.0, 1000000.0, 0.1, "or_greater") var spirit_cost: float = 0.0
@export_range(0.0, 1000000.0, 0.01, "or_greater") var cooldown: float = 1.0
## 施法距离；小于等于 0 时回退到施法者的普通攻击距离。SELF 技能不会使用该距离。
@export_range(0.0, 1000000.0, 1.0, "or_greater") var cast_range: float = 0.0
## 旧版伤害倍率字段：DAMAGE 技能未配置 effect_value 时作为兼容回退。
@export_range(0.0, 100.0, 0.01, "or_greater") var damage_multiplier: float = 1.0
## 目标类型与效果类型是技能数据契约的一部分；旧资源未填写时默认为敌方伤害。
@export var target_type: SkillTargetType = SkillTargetType.ENEMY
@export var effect_type: SkillEffectType = SkillEffectType.DAMAGE
## 效果强度：DAMAGE 为攻击倍率，HEAL/SHIELD 为点数；STUN 可留 0，持续时间由 effect_duration 描述。
@export_range(0.0, 1000000.0, 0.01, "or_greater") var effect_value: float = 0.0
## 效果持续时间；0 表示瞬时效果。
@export_range(0.0, 1000000.0, 0.01, "or_greater") var effect_duration: float = 0.0
## 范围效果半径（像素）；只在 AOE_DAMAGE 生效，0 表示只命中主目标。
@export_range(0.0, 1000000.0, 1.0, "or_greater") var aoe_radius: float = 0.0
## 吸血比例（0~1）：LIFESTEAL 用它把「实际造成的伤害」换算成施法者回复量。
@export_range(0.0, 1.0, 0.01) var lifesteal_ratio: float = 0.5
## 条件伤害倍率：DAMAGE 技能在目标处于控制状态（定身 / 眩晕）时叠加的额外倍率（INC-COMBAT-012）。
## 默认 1.0 表示没有条件加成；归一化不会低于 1.0，避免「条件」反而削弱伤害。
@export_range(0.0, 100.0, 0.01, "or_greater") var controlled_bonus_multiplier: float = 1.0
## 追加效果（INC-COMBAT-013）：主效果结算完成后按同一套效果词汇再结算一段，
## 只用于描述「无法用护盾买断」的代价（例：聚煞一击落地后的硬直）。
## 默认 null 表示没有追加效果，此时技能行为与 `INC-COMBAT-009` 完全一致。
## 追加效果不是独立技能：它不进 `PawnData.active_skills`，不走灵力与冷却，也不由 AI 主动施放。
@export var followup_skill: ActiveSkillDefinition

func is_configured() -> bool:
	return not String(id).strip_edges().is_empty()

func get_effective_cast_range(fallback_range: float) -> float:
	if target_type == SkillTargetType.SELF:
		return 0.0
	if cast_range > 0.0:
		return cast_range
	return maxf(fallback_range, 0.0)

func get_normalized_spirit_cost() -> float:
	return maxf(spirit_cost, 0.0)

func get_normalized_cooldown() -> float:
	return maxf(cooldown, 0.0)

func get_normalized_damage_multiplier() -> float:
	return maxf(damage_multiplier, 0.0)

## DAMAGE 优先使用新 effect_value；未填写时兼容旧 damage_multiplier。
## 非 DAMAGE 效果不会回退到旧伤害字段。
func get_normalized_effect_value() -> float:
	var value: float = maxf(effect_value, 0.0)
	if effect_type == SkillEffectType.DAMAGE and value <= 0.0:
		return get_normalized_damage_multiplier()
	return value

func get_normalized_effect_duration() -> float:
	return maxf(effect_duration, 0.0)

func get_normalized_aoe_radius() -> float:
	return maxf(aoe_radius, 0.0)

func get_normalized_lifesteal_ratio() -> float:
	return clampf(lifesteal_ratio, 0.0, 1.0)

func get_normalized_controlled_bonus_multiplier() -> float:
	return maxf(controlled_bonus_multiplier, 1.0)


## 条件加成是否真实存在：只在倍率严格大于 1 时为真，供结算与测试区分「无条件技能」。
func has_controlled_bonus() -> bool:
	return get_normalized_controlled_bonus_multiplier() > 1.0


## 追加效果是否真实存在：id 为空的资源按未配置处理，避免半配置数据产生空结算。
func has_followup_skill() -> bool:
	return followup_skill != null and followup_skill.is_configured()


func get_followup_skill() -> ActiveSkillDefinition:
	return followup_skill if has_followup_skill() else null


func is_self_targeted() -> bool:
	return target_type == SkillTargetType.SELF
