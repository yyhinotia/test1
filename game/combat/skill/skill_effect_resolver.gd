class_name SkillEffectResolver
extends RefCounted

## 最小 Skill Effect System（`INC-COMBAT-006`）。
##
## 职责：把一次主动技能的结算收敛成唯一顺序——
##   目标与条件校验 → 灵力原子扣除 → 按 `effect_type` 应用效果 → 记录冷却并广播。
## 任一步失败都必须在产生副作用之前返回，禁止出现“扣了灵力却没生效”或“生效了却没进冷却”的半结算。
##
## 边界（第一版）：
## - 只支持单效果技能，不实现 Effect 数组、Buff/Debuff 容器、堆叠、免疫、抗性与持续伤害。
## - 效果只通过 Pawn 的受控业务接口修改资源与状态，Resolver 不直接写资源池字段，
##   也不复制防御结算、护盾上限、死亡规则等既有业务。
## - 已知限制：`Pawn` 与本 Resolver 互相引用，GDScript 4 在签名上标注双方类型会触发脚本循环依赖编译失败，
##   因此施法者与目标参数不加 `Pawn` 静态类型；调用契约由 `Pawn.cast_skill()` 单点保证。
static func resolve(caster, skill: ActiveSkillDefinition, target) -> bool:
	if caster == null or skill == null or target == null:
		return false
	if not is_supported(skill):
		return false
	if not caster.can_cast_skill(skill, target):
		return false

	# 灵力是唯一可能造成部分结算的资源，必须在效果生效前原子扣除。
	var cost: float = skill.get_normalized_spirit_cost()
	if cost > 0.0 and not caster.try_spend_spirit(cost):
		return false

	apply_effect(caster, skill, target)
	caster.commit_skill_cast(skill, target)
	return true


## 第一版只承认四种效果类型；未知类型必须在扣灵力前被拒绝。
static func is_supported(skill: ActiveSkillDefinition) -> bool:
	if skill == null:
		return false
	var effect: int = skill.effect_type
	return (
		effect == ActiveSkillDefinition.SkillEffectType.DAMAGE
		or effect == ActiveSkillDefinition.SkillEffectType.HEAL
		or effect == ActiveSkillDefinition.SkillEffectType.SHIELD
		or effect == ActiveSkillDefinition.SkillEffectType.STUN
	)


## 按效果类型分派；调用前必须已完成目标校验与灵力扣除。
static func apply_effect(caster, skill: ActiveSkillDefinition, target) -> void:
	match skill.effect_type:
		ActiveSkillDefinition.SkillEffectType.DAMAGE:
			target.take_damage(get_damage_amount(caster, skill))
		ActiveSkillDefinition.SkillEffectType.HEAL:
			target.restore_health(skill.get_normalized_effect_value())
		ActiveSkillDefinition.SkillEffectType.SHIELD:
			target.grant_shield(skill.get_normalized_effect_value())
		ActiveSkillDefinition.SkillEffectType.STUN:
			target.apply_stun(skill.get_normalized_effect_duration())
		_:
			pass


## 伤害沿用旧公式：施法者攻击力 × 效果倍率，至少 1 点；
## 防御减免、先护盾后生命的顺序仍由 `Pawn.take_damage()` 负责。
static func get_damage_amount(caster, skill: ActiveSkillDefinition) -> float:
	if caster == null or caster.data == null or skill == null:
		return 0.0
	return maxf(1.0, caster.data.attack * skill.get_normalized_effect_value())
