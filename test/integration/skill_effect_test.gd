extends GdUnitTestSuite

## 集成层：最小 Skill Effect System（`INC-COMBAT-006`）。
## 覆盖七种效果、上限截断、失败无副作用，以及眩晕的行为封锁与到期恢复。
## 全部使用真实 Pawn 场景与真实资源池，不直接改写 HP / 护盾 / 灵力内部字段。

const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const APPROX: float = 0.001


func _make_skill(
		id: StringName,
		target_type: ActiveSkillDefinition.SkillTargetType,
		effect_type: ActiveSkillDefinition.SkillEffectType,
		effect_value: float,
		effect_duration: float = 0.0,
		cost: float = 0.0,
		cooldown: float = 1.0,
		cast_range: float = 120.0
	) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.target_type = target_type
	skill.effect_type = effect_type
	skill.effect_value = effect_value
	skill.effect_duration = effect_duration
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	skill.damage_multiplier = 1.0
	return skill


func _make_data(base_path: String, skill: ActiveSkillDefinition, max_spirit: float = 100.0) -> PawnData:
	var data: PawnData = (load(base_path) as PawnData).duplicate(true) as PawnData
	data.active_skill = skill
	var skills: Array[ActiveSkillDefinition] = []
	if skill != null:
		skills.append(skill)
	data.active_skills = skills
	data.max_spirit = max_spirit
	data.initial_spirit_ratio = 1.0
	return data


func _spawn(scene_path: String, data: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data != null:
		pawn.data = data
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _total_effective_health(pawn: Pawn) -> float:
	return pawn.current_shield + pawn.current_health


## DAMAGE：新 effect_value 必须真正决定伤害，并继续走“先护盾、后生命”的既有路由。
func test_damage_effect_uses_effect_value_and_keeps_routing() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_slash",
		ActiveSkillDefinition.SkillTargetType.ENEMY,
		ActiveSkillDefinition.SkillEffectType.DAMAGE,
		2.0,
		0.0,
		25.0,
		2.5
	)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, skill))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)

	var cast_ids: Array[StringName] = []
	player.skill_cast.connect(func(_pawn: Pawn, cast_skill: ActiveSkillDefinition, _target: Pawn) -> void:
		cast_ids.append(cast_skill.id)
	)
	var expected_effective_damage: float = maxf(1.0, player.data.attack * 2.0 - enemy.data.defense)
	var shield_before: float = enemy.current_shield
	var health_before: float = enemy.current_health

	assert_bool(player.cast_skill(skill, enemy)).is_true()

	# 20 点护盾先被击穿，剩余伤害才进入生命。
	assert_float(enemy.current_shield).is_zero()
	assert_float(enemy.current_health).is_equal_approx(
		health_before - (expected_effective_damage - shield_before), APPROX
	)
	assert_float(player.current_spirit).is_equal_approx(75.0, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(2.5, APPROX)
	assert_array(cast_ids).contains_exactly([&"effect_slash"])


## HEAL：按上限截断，满血施法仍是成功结算但没有治疗量。
func test_heal_effect_truncates_at_max_health() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_heal",
		ActiveSkillDefinition.SkillTargetType.SELF,
		ActiveSkillDefinition.SkillEffectType.HEAL,
		30.0,
		0.0,
		10.0,
		1.0
	)
	# 治疗只验证生命池：把护盾上限设为 0，避免满护盾吸收伤害干扰断言。
	var heal_data: PawnData = _make_data(PLAYER_DATA_PATH, skill)
	heal_data.max_shield = 0.0
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, heal_data)
	var max_health: float = player.data.max_health

	player.take_damage(player.data.defense + 50.0)
	assert_float(player.current_health).is_equal_approx(70.0, APPROX)

	var healed: Array[float] = []
	var health_before: float = player.current_health
	assert_bool(player.cast_skill(skill, player)).is_true()
	healed.append(player.current_health - health_before)

	var spirit_before: float = player.current_spirit
	player.take_damage(player.data.defense + 25.0)
	player._physics_process(1.1)
	health_before = player.current_health
	assert_bool(player.cast_skill(skill, player)).is_true()
	healed.append(player.current_health - health_before)

	# 105 / 120：第三次治疗被上限截断，只剩 15 点有效治疗量。
	player._physics_process(1.1)
	health_before = player.current_health
	assert_bool(player.cast_skill(skill, player)).is_true()
	healed.append(player.current_health - health_before)
	assert_array(healed).contains_exactly([30.0, 30.0, 15.0])

	# 满血施法依然成功结算，但治疗量为 0。
	player._physics_process(1.1)
	assert_bool(player.cast_skill(skill, player)).is_true()
	assert_float(player.current_health).is_equal_approx(max_health, APPROX)
	assert_float(spirit_before - player.current_spirit).is_equal_approx(30.0, APPROX)


## SHIELD：按护盾上限截断；没有护盾上限的单位施法成功但不产生护盾。
func test_shield_effect_truncates_at_max_shield() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_guard",
		ActiveSkillDefinition.SkillTargetType.SELF,
		ActiveSkillDefinition.SkillEffectType.SHIELD,
		30.0,
		0.0,
		15.0,
		1.0
	)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, skill))
	# 护盾池出生即满值：先打空，才能观察“增加护盾”与上限截断。
	player.take_damage(player.data.max_shield + player.data.defense)
	assert_float(player.current_shield).is_zero()
	assert_float(player.current_health).is_equal_approx(player.data.max_health, APPROX)

	assert_bool(player.cast_skill(skill, player)).is_true()
	assert_float(player.current_shield).is_equal_approx(30.0, APPROX)

	player._physics_process(1.1)
	assert_bool(player.cast_skill(skill, player)).is_true()
	assert_float(player.current_shield).is_equal_approx(player.data.max_shield, APPROX)

	player._physics_process(1.1)
	assert_bool(player.cast_skill(skill, player)).is_true()
	assert_float(player.current_shield).is_equal_approx(player.data.max_shield, APPROX)

	var no_shield_data: PawnData = _make_data(PLAYER_DATA_PATH, skill)
	no_shield_data.max_shield = 0.0
	var no_shield_pawn: Pawn = _spawn(PLAYER_SCENE_PATH, no_shield_data)
	assert_bool(no_shield_pawn.cast_skill(skill, no_shield_pawn)).is_true()
	assert_float(no_shield_pawn.current_shield).is_zero()


## STUN：只封锁行动，不产生伤害；持续时间由物理帧推进并发出状态信号。
func test_stun_effect_blocks_actions_and_recovers() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_bind",
		ActiveSkillDefinition.SkillTargetType.ENEMY,
		ActiveSkillDefinition.SkillEffectType.STUN,
		0.0,
		0.5,
		20.0,
		3.0
	)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, skill))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(90.0, 0.0)

	var stun_events: Array[String] = []
	enemy.stun_changed.connect(func(_pawn: Pawn, remaining: float, active: bool) -> void:
		stun_events.append("%s|%.2f" % ["on" if active else "off", remaining])
	)
	var enemy_total_before: float = _total_effective_health(enemy)

	assert_bool(player.cast_skill(skill, enemy)).is_true()
	assert_bool(enemy.is_stunned()).is_true()
	assert_float(enemy.get_stun_remaining()).is_equal_approx(0.5, APPROX)
	assert_bool(enemy.can_move()).is_false()
	assert_bool(enemy.can_attack()).is_false()
	assert_bool(enemy.can_cast_skill(skill, player)).is_false()
	assert_float(enemy.velocity.x).is_zero()
	assert_float(enemy.velocity.y).is_zero()
	# 眩晕只影响行动：不扣血、不致死。
	assert_float(_total_effective_health(enemy)).is_equal_approx(enemy_total_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(3.0, APPROX)

	enemy._physics_process(0.25)
	assert_bool(enemy.is_stunned()).is_true()
	assert_float(enemy.get_stun_remaining()).is_equal_approx(0.25, APPROX)

	enemy._physics_process(0.3)
	assert_bool(enemy.is_stunned()).is_false()
	assert_float(enemy.get_stun_remaining()).is_zero()
	assert_bool(enemy.can_move()).is_true()
	assert_array(stun_events).contains_exactly(["on|0.50", "off|0.00"])

	# 重复施加取较长剩余时间，不做叠加。
	enemy.apply_stun(2.0)
	enemy.apply_stun(1.0)
	assert_float(enemy.get_stun_remaining()).is_equal_approx(2.0, APPROX)


## 失败路径：灵力不足时四种效果都不得出现任何部分结算。
func test_failed_cast_is_complete_no_op_for_every_effect() -> void:
	var enemy_skill: ActiveSkillDefinition = _make_skill(
		&"effect_bind",
		ActiveSkillDefinition.SkillTargetType.ENEMY,
		ActiveSkillDefinition.SkillEffectType.STUN,
		0.0,
		2.0,
		50.0,
		3.0
	)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, enemy_skill, 20.0))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)

	var stun_events: Array[String] = []
	enemy.stun_changed.connect(func(_pawn: Pawn, _remaining: float, active: bool) -> void:
		stun_events.append("on" if active else "off")
	)
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)

	assert_bool(player.can_cast_skill(enemy_skill, enemy)).is_false()
	assert_bool(player.cast_skill(enemy_skill, enemy)).is_false()

	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(enemy_skill.id)).is_zero()
	assert_bool(enemy.is_stunned()).is_false()
	assert_float(_total_effective_health(enemy)).is_equal_approx(enemy_total_before, APPROX)
	assert_array(stun_events).is_empty()


## DASH（INC-COMBAT-010）：位移到目标外侧的普攻距离内，且不越过目标。
## effect_value = 0 时位移不附带伤害，避免「位移技能顺手打人」的隐性规则。
func test_dash_effect_moves_caster_into_attack_range_without_damage() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_dash",
		ActiveSkillDefinition.SkillTargetType.ENEMY,
		ActiveSkillDefinition.SkillEffectType.DASH,
		0.0,
		0.0,
		20.0,
		6.0,
		200.0
	)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, skill))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(180.0, 0.0)
	var enemy_total_before: float = _total_effective_health(enemy)
	var distance_before: float = player.global_position.distance_to(enemy.global_position)

	assert_bool(player.cast_skill(skill, enemy)).is_true()

	var distance_after: float = player.global_position.distance_to(enemy.global_position)
	assert_bool(distance_after < distance_before).is_true()
	assert_bool(distance_after <= player.data.attack_range).is_true()
	assert_bool(distance_after > 1.0).is_true()
	# 仍然停在目标外侧，没有穿过目标。
	assert_bool(player.global_position.x < enemy.global_position.x).is_true()
	assert_float(_total_effective_health(enemy)).is_equal_approx(enemy_total_before, APPROX)
	assert_float(player.current_spirit).is_equal_approx(80.0, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(6.0, APPROX)


## AOE_DAMAGE（INC-COMBAT-010）：半径内的敌对单位各命中一次，半径外与友方不受影响。
func test_aoe_damage_hits_each_hostile_in_radius_once() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_aoe",
		ActiveSkillDefinition.SkillTargetType.ENEMY,
		ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE,
		1.0,
		0.0,
		40.0,
		7.0,
		100.0
	)
	skill.aoe_radius = 100.0
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, skill))
	var center_enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	var near_enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	var far_enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	var ally: Pawn = _spawn(PLAYER_SCENE_PATH)
	player.global_position = Vector2.ZERO
	center_enemy.global_position = Vector2(80.0, 0.0)
	near_enemy.global_position = Vector2(140.0, 0.0)
	far_enemy.global_position = Vector2(500.0, 0.0)
	ally.global_position = Vector2(60.0, 0.0)
	var center_before: float = _total_effective_health(center_enemy)
	var near_before: float = _total_effective_health(near_enemy)
	var far_before: float = _total_effective_health(far_enemy)
	var ally_before: float = _total_effective_health(ally)
	var expected_damage: float = maxf(1.0, player.data.attack * 1.0 - center_enemy.data.defense)

	assert_bool(player.cast_skill(skill, center_enemy)).is_true()

	# 主目标与半径内同伴各吃一次，半径外与友方零影响。
	assert_float(_total_effective_health(center_enemy)).is_equal_approx(center_before - expected_damage, APPROX)
	assert_float(_total_effective_health(near_enemy)).is_equal_approx(near_before - expected_damage, APPROX)
	assert_float(_total_effective_health(far_enemy)).is_equal_approx(far_before, APPROX)
	assert_float(_total_effective_health(ally)).is_equal_approx(ally_before, APPROX)


## LIFESTEAL（INC-COMBAT-010）：回复量按「实际打掉的护盾 + 生命」计算，而不是按标称伤害。
func test_lifesteal_effect_heals_caster_by_actual_damage() -> void:
	var skill: ActiveSkillDefinition = _make_skill(
		&"effect_drain",
		ActiveSkillDefinition.SkillTargetType.ENEMY,
		ActiveSkillDefinition.SkillEffectType.LIFESTEAL,
		1.0,
		0.0,
		30.0,
		6.0,
		120.0
	)
	skill.lifesteal_ratio = 0.5
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_data(PLAYER_DATA_PATH, skill))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(80.0, 0.0)
	# 先制造受伤缺口，确保回复不会被生命上限截断（截断行为另由 HEAL 用例覆盖）。
	player.take_damage(60.0)
	var player_health_before: float = player.current_health
	var enemy_total_before: float = _total_effective_health(enemy)

	assert_bool(player.cast_skill(skill, enemy)).is_true()

	var dealt: float = enemy_total_before - _total_effective_health(enemy)
	assert_bool(dealt > 0.0).is_true()
	assert_float(player.current_health).is_equal_approx(player_health_before + dealt * 0.5, APPROX)
	assert_float(player.current_spirit).is_equal_approx(70.0, APPROX)
