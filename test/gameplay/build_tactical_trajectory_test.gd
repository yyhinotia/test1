extends GdUnitTestSuite

## 玩法层：三种两槽 Build 的固定时间步过程差异（INC-TESTING-004）。
## 三种组合使用同一敌人、同一起点、同一“先槽位 0 后槽位 1”操作策略；
## 本测试只记录真实控制器/资源池产生的过程指标，不把平衡公式写进测试。

const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_SKILL_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/player_binding_skill.tres"

const DELTA: float = 1.0 / 60.0
const TOTAL_STEPS: int = 720
const SAMPLE_EVERY: int = 60
const APPROX: float = 0.001


func _make_player_data(first: ActiveSkillDefinition, second: ActiveSkillDefinition) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = first
	var skills: Array[ActiveSkillDefinition] = [first, second]
	data.active_skills = skills
	data.max_spirit = 100.0
	data.initial_spirit_ratio = 1.0
	return data


func _make_enemy_data() -> PawnData:
	var data: PawnData = (load(ENEMY_DATA_PATH) as PawnData).duplicate(true) as PawnData
	# 拉长敌人生命，避免 12 秒内死亡掩盖“输出/控制/生存”的过程差异。
	data.max_health = 600.0
	data.max_shield = 0.0
	return data


func _spawn_build(first: ActiveSkillDefinition, second: ActiveSkillDefinition) -> Dictionary:
	var player_scene: PackedScene = load(PLAYER_SCENE_PATH)
	var enemy_scene: PackedScene = load(ENEMY_SCENE_PATH)
	var player: Pawn = player_scene.instantiate() as Pawn
	var enemy: Pawn = enemy_scene.instantiate() as Pawn
	player.data = _make_player_data(first, second)
	enemy.data = _make_enemy_data()
	auto_free(player)
	auto_free(enemy)
	add_child(player)
	add_child(enemy)

	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(180.0, 0.0)
	player.set_physics_process(false)
	enemy.set_physics_process(false)

	var player_controller: PlayerController = player.get_controller() as PlayerController
	var ai_controller: AIController = enemy.get_controller() as AIController
	player_controller.bind(player)
	player_controller.set_physics_process(false)
	ai_controller.bind(enemy)
	ai_controller.set_physics_process(false)
	ai_controller.activation_delay = 0.0
	ai_controller.set_target(player)

	# 三种 Build 都从“空护盾、满生命”开始，否则护体真气在满盾时没有可观察增量。
	player.take_damage(player.data.max_shield + player.data.defense)

	return {
		"player": player,
		"enemy": enemy,
		"player_controller": player_controller,
		"ai_controller": ai_controller,
	}


func _count_id(values: Array[StringName], id: StringName) -> int:
	var count: int = 0
	for value: StringName in values:
		if value == id:
			count += 1
	return count


func _skill_target(skill: ActiveSkillDefinition, player: Pawn, enemy: Pawn) -> Pawn:
	if skill.target_type == ActiveSkillDefinition.SkillTargetType.SELF:
		return player
	return enemy


func _tick(
		player: Pawn,
		enemy: Pawn,
		player_controller: PlayerController,
		ai_controller: AIController
	) -> void:
	player_controller.update_controller(DELTA)
	ai_controller.update_controller(DELTA)
	player._physics_process(DELTA)
	enemy._physics_process(DELTA)


func _run_build(
		build_id: String,
		first: ActiveSkillDefinition,
		second: ActiveSkillDefinition
	) -> Dictionary:
	var context: Dictionary = _spawn_build(first, second)
	var player: Pawn = context["player"] as Pawn
	var enemy: Pawn = context["enemy"] as Pawn
	var player_controller: PlayerController = context["player_controller"] as PlayerController
	var ai_controller: AIController = context["ai_controller"] as AIController

	var cast_ids: Array[StringName] = []
	var player_attack_targets: Array[StringName] = []
	var enemy_attack_targets: Array[StringName] = []
	player.skill_cast.connect(func(_pawn: Pawn, skill: ActiveSkillDefinition, _target: Pawn) -> void:
		cast_ids.append(skill.id)
	)
	player.attack_performed.connect(func(target: Pawn) -> void:
		player_attack_targets.append(target.data.display_name)
	)
	enemy.attack_performed.connect(func(target: Pawn) -> void:
		enemy_attack_targets.append(target.data.display_name)
	)

	var initial_spirit: float = player.current_spirit
	var initial_enemy_effective: float = enemy.current_shield + enemy.current_health
	var player_effective_curve: Array[float] = []
	var player_shield_curve: Array[float] = []
	var enemy_effective_curve: Array[float] = []
	var sample_steps: Array[int] = []
	var stun_steps: int = 0
	var max_player_shield: float = 0.0
	var max_player_effective: float = 0.0
	var min_player_effective: float = INF

	for step: int in TOTAL_STEPS:
		# 相同操作策略：先尝试槽位 0；该技能完成一次结算后，再尝试槽位 1。
		if _count_id(cast_ids, first.id) == 0:
			player_controller.order_skill_instance(first, _skill_target(first, player, enemy))
		elif _count_id(cast_ids, second.id) == 0:
			player_controller.order_skill_instance(second, _skill_target(second, player, enemy))

		_tick(player, enemy, player_controller, ai_controller)

		var player_effective: float = player.current_shield + player.current_health
		var enemy_effective: float = enemy.current_shield + enemy.current_health
		var player_shield: float = player.current_shield
		max_player_shield = maxf(max_player_shield, player_shield)
		max_player_effective = maxf(max_player_effective, player_effective)
		min_player_effective = minf(min_player_effective, player_effective)
		if enemy.is_stunned():
			stun_steps += 1

		if step % SAMPLE_EVERY == SAMPLE_EVERY - 1:
			sample_steps.append(step + 1)
			player_effective_curve.append(player_effective)
			player_shield_curve.append(player_shield)
			enemy_effective_curve.append(enemy_effective)

	var player_effective_end: float = player.current_shield + player.current_health
	var enemy_effective_end: float = enemy.current_shield + enemy.current_health
	return {
		"build_id": build_id,
		"first_id": first.id,
		"second_id": second.id,
		"skill_cast_count": cast_ids.size(),
		"first_cast_count": _count_id(cast_ids, first.id),
		"second_cast_count": _count_id(cast_ids, second.id),
		"player_attack_count": player_attack_targets.size(),
		"enemy_attack_count": enemy_attack_targets.size(),
		"spirit_spent": initial_spirit - player.current_spirit,
		"max_player_shield": max_player_shield,
		"max_player_effective": max_player_effective,
		"min_player_effective": min_player_effective,
		"player_effective_end": player_effective_end,
		"damage_dealt": initial_enemy_effective - enemy_effective_end,
		"enemy_stun_seconds": float(stun_steps) * DELTA,
		"sample_steps": sample_steps,
		"player_effective_curve": player_effective_curve,
		"player_shield_curve": player_shield_curve,
		"enemy_effective_curve": enemy_effective_curve,
	}


func test_three_two_skill_builds_produce_distinct_combat_process_trajectories() -> void:
	var sword: ActiveSkillDefinition = load(SWORD_SKILL_PATH) as ActiveSkillDefinition
	var guard: ActiveSkillDefinition = load(GUARD_SKILL_PATH) as ActiveSkillDefinition
	var binding: ActiveSkillDefinition = load(BINDING_SKILL_PATH) as ActiveSkillDefinition
	assert_object(sword).is_not_null()
	assert_object(guard).is_not_null()
	assert_object(binding).is_not_null()

	var output_survival: Dictionary = _run_build("output+survival", sword, guard)
	var output_control: Dictionary = _run_build("output+control", sword, binding)
	var survival_control: Dictionary = _run_build("survival+control", guard, binding)

	print("[INC-TESTING-004] output+survival=", output_survival)
	print("[INC-TESTING-004] output+control=", output_control)
	print("[INC-TESTING-004] survival+control=", survival_control)

	# 三套 Build 必须各自完成两个槽位的一次真实结算，而不是只发命令。
	for summary: Dictionary in [output_survival, output_control, survival_control]:
		assert_int(int(summary["skill_cast_count"])).is_equal(2)
		assert_int(int(summary["first_cast_count"])).is_equal(1)
		assert_int(int(summary["second_cast_count"])).is_equal(1)

	var os_max_shield: float = float(output_survival["max_player_shield"])
	var oc_max_shield: float = float(output_control["max_player_shield"])
	var sc_max_shield: float = float(survival_control["max_player_shield"])
	var os_stun: float = float(output_survival["enemy_stun_seconds"])
	var oc_stun: float = float(output_control["enemy_stun_seconds"])
	var sc_stun: float = float(survival_control["enemy_stun_seconds"])
	var os_min_effective: float = float(output_survival["min_player_effective"])
	var oc_min_effective: float = float(output_control["min_player_effective"])
	var sc_min_effective: float = float(survival_control["min_player_effective"])
	var os_damage: float = float(output_survival["damage_dealt"])
	var oc_damage: float = float(output_control["damage_dealt"])
	var sc_damage: float = float(survival_control["damage_dealt"])
	var os_spirit: float = float(output_survival["spirit_spent"])
	var oc_spirit: float = float(output_control["spirit_spent"])
	var sc_spirit: float = float(survival_control["spirit_spent"])

	# 三种签名：盾+无控制、无盾+控制、盾+控制；不是三个同质伤害技能。
	assert_bool(os_max_shield > 20.0).is_true()
	assert_bool(os_stun < 0.1).is_true()
	assert_bool(oc_max_shield < 0.1).is_true()
	assert_bool(oc_stun > 1.0).is_true()
	assert_bool(sc_max_shield > 20.0).is_true()
	assert_bool(sc_stun > 1.0).is_true()

	# 过程指标 1：有效生命/护盾曲线。护体真气提高生存下限。
	assert_bool(os_min_effective > oc_min_effective + 10.0).is_true()
	assert_bool(sc_min_effective > oc_min_effective + 10.0).is_true()
	assert_bool(os_min_effective > 0.0 and oc_min_effective > 0.0 and sc_min_effective > 0.0).is_true()

	# 过程指标 2：敌人失效时间。定身术改变敌人的行动时间轴。
	assert_bool(oc_stun > os_stun + 1.0).is_true()
	assert_bool(sc_stun > os_stun + 1.0).is_true()

	# 过程指标 3：资源消耗与敌人有效生命变化，输出技能带来更高伤害压力。
	assert_float(os_spirit).is_equal_approx(55.0, APPROX)
	assert_float(oc_spirit).is_equal_approx(60.0, APPROX)
	assert_float(sc_spirit).is_equal_approx(65.0, APPROX)
	assert_bool(os_damage > sc_damage + 20.0).is_true()
	assert_bool(oc_damage > sc_damage + 20.0).is_true()

	# “输出+生存”在生存指标上优于“输出+控制”，“输出+控制”在控制指标上优于前者；
	# 说明它们提供的是可权衡的战术工具，而不是只换一个更优解。
	assert_bool(os_min_effective > oc_min_effective).is_true()
	assert_bool(oc_stun > os_stun).is_true()

	# 曲线必须有实际差异，不能只比较最终结果。
	var os_curve: Array = output_survival["player_effective_curve"]
	var oc_curve: Array = output_control["player_effective_curve"]
	var sc_curve: Array = survival_control["player_effective_curve"]
	assert_int(os_curve.size()).is_equal(12)
	assert_int(oc_curve.size()).is_equal(12)
	assert_int(sc_curve.size()).is_equal(12)
	assert_bool(os_curve[1] != oc_curve[1] or os_curve[5] != oc_curve[5]).is_true()
	assert_bool(os_curve[1] != sc_curve[1] or os_curve[5] != sc_curve[5]).is_true()
