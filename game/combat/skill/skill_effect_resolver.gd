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
		or effect == ActiveSkillDefinition.SkillEffectType.DASH
		or effect == ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE
		or effect == ActiveSkillDefinition.SkillEffectType.LIFESTEAL
	)


## 按效果类型分派；调用前必须已完成目标校验与灵力扣除。
static func apply_effect(caster, skill: ActiveSkillDefinition, target) -> void:
	match skill.effect_type:
		ActiveSkillDefinition.SkillEffectType.DAMAGE:
			target.take_damage(get_damage_amount(caster, skill, target))
		ActiveSkillDefinition.SkillEffectType.HEAL:
			target.restore_health(skill.get_normalized_effect_value())
		ActiveSkillDefinition.SkillEffectType.SHIELD:
			target.grant_shield(skill.get_normalized_effect_value())
		ActiveSkillDefinition.SkillEffectType.STUN:
			target.apply_stun(skill.get_normalized_effect_duration())
		ActiveSkillDefinition.SkillEffectType.DASH:
			apply_dash(caster, skill, target)
		ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE:
			apply_aoe_damage(caster, skill, target)
		ActiveSkillDefinition.SkillEffectType.LIFESTEAL:
			apply_lifesteal(caster, skill, target)
		_:
			pass


## 伤害沿用旧公式：施法者攻击力 × 效果倍率，至少 1 点；
## 目标处于控制状态且技能配置了 `controlled_bonus_multiplier` 时按额外倍率结算（INC-COMBAT-012）；
## 防御减免、先护盾后生命的顺序仍由 `Pawn.take_damage()` 负责。
static func get_damage_amount(caster, skill: ActiveSkillDefinition, target = null) -> float:
	if caster == null or caster.data == null or skill == null:
		return 0.0
	var multiplier: float = skill.get_normalized_effect_value()
	# 条件伤害：只有目标确实处于控制状态时才叠加额外倍率，未受控目标走原公式。
	if target != null and is_instance_valid(target) and target.is_stunned():
		multiplier *= skill.get_normalized_controlled_bonus_multiplier()
	return maxf(1.0, caster.data.attack * multiplier)

## DASH：先求落点再位移，位移失败时不产生任何伤害（避免「没到却打到了」）。
static func apply_dash(caster, skill: ActiveSkillDefinition, target) -> void:
	if caster == null or skill == null or target == null:
		return
	var destination: Vector2 = get_dash_destination(caster, skill, target)
	if not caster.dash_to(destination):
		return
	if skill.get_normalized_effect_value() > 0.0:
		target.take_damage(get_damage_amount(caster, skill))


## 落点：停在目标外侧约一个普通攻击距离处，保证位移后仍可继续普攻，且不越过目标。
static func get_dash_destination(caster, skill: ActiveSkillDefinition, target) -> Vector2:
	var origin: Vector2 = caster.global_position
	if target == null or not is_instance_valid(target):
		return origin
	var to_target: Vector2 = target.global_position - origin
	if to_target.length_squared() <= 0.0001:
		return origin
	var stop_distance: float = maxf(minf(caster.data.attack_range * 0.9, to_target.length() * 0.9), 1.0)
	return target.global_position - to_target.normalized() * stop_distance


## AOE_DAMAGE：以主目标为中心取半径内的敌对单位，每个单位恰好结算一次伤害。
## 半径内的单位集合由 Pawn.get_hostile_units_around() 提供，Resolver 不自行遍历场景树。
static func apply_aoe_damage(caster, skill: ActiveSkillDefinition, target) -> void:
	if caster == null or skill == null or target == null:
		return
	var amount: float = get_damage_amount(caster, skill)
	var center: Vector2 = target.global_position
	var units: Array = caster.get_hostile_units_around(center, skill.get_normalized_aoe_radius())
	var target_was_hit: bool = false
	for unit: Variant in units:
		if unit == null or not is_instance_valid(unit) or not unit.is_alive():
			continue
		if unit == target:
			target_was_hit = true
		unit.take_damage(amount)
	# 半径 <= 0 或目标恰好不在集合里时，主目标仍必须命中一次。
	if not target_was_hit and is_instance_valid(target) and target.is_alive():
		target.take_damage(amount)


## LIFESTEAL：伤害仍走既有「先护盾后生命」路由，回复量按实际打掉的护盾 + 生命计算，
## 因此被完全挡下的攻击不会凭空回血，回复量也不可能超过实际造成的伤害。
static func apply_lifesteal(caster, skill: ActiveSkillDefinition, target) -> void:
	if caster == null or skill == null or target == null:
		return
	var shield_before: float = target.current_shield
	var health_before: float = target.current_health
	target.take_damage(get_damage_amount(caster, skill))
	var dealt: float = (
		maxf(shield_before - target.current_shield, 0.0)
		+ maxf(health_before - target.current_health, 0.0)
	)
	if dealt <= 0.0:
		return
	caster.restore_health(dealt * skill.get_normalized_lifesteal_ratio())
