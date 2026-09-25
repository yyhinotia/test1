extends GdUnitTestSuite

## 集成层：PlayerController 技能命令 → 接近 → Pawn.cast_skill() → 回退普通攻击。
## 使用真实 Pawn 场景与真实资源池，只通过公开命令 API 驱动，不直接改写灵力/冷却内部状态。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const APPROX: float = 0.001


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _make_skill(
		id: StringName,
		spirit_cost: float,
		cooldown: float,
		cast_range: float,
		damage_multiplier: float
	) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.spirit_cost = spirit_cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	skill.damage_multiplier = damage_multiplier
	return skill


func _make_player_data(skill: ActiveSkillDefinition, max_spirit: float = 100.0) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = skill
	data.max_spirit = max_spirit
	data.initial_spirit_ratio = 1.0
	return data


func _create_controller(player: Pawn) -> PlayerController:
	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)
	# 用例直接调用 update_controller()，关闭引擎物理帧驱动，避免同一命令被重复推进。
	controller.set_physics_process(false)
	return controller


func _total_effective_health(pawn: Pawn) -> float:
	return pawn.current_shield + pawn.current_health


func test_order_skill_requires_configured_skill_and_valid_enemy_target() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"sword", 25.0, 2.5, 120.0, 1.8)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var friendly: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	friendly.global_position = Vector2(60.0, 0.0)
	enemy.global_position = Vector2(50.0, 0.0)
	var controller: PlayerController = _create_controller(player)
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)

	controller.order_move(Vector2(200.0, 0.0))
	var move_description: String = controller.get_order_description()

	assert_bool(controller.order_skill(null)).is_false()
	assert_bool(controller.order_skill(player)).is_false()
	assert_bool(controller.order_skill(friendly)).is_false()
	enemy.take_damage(enemy.data.defense + enemy.data.max_shield + enemy.data.max_health + 50.0)
	assert_bool(enemy.is_dead()).is_true()
	assert_bool(controller.order_skill(enemy)).is_false()

	assert_str(controller.get_order_description()).is_equal(move_description)
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_float(_total_effective_health(player)).is_equal_approx(
		player.data.max_shield + player.data.max_health, APPROX
	)
	assert_bool(enemy_total_before > 0.0).is_true()

	# 无技能配置的 Pawn 不允许下达技能命令，且同样不产生副作用。
	var no_skill_data: PawnData = _make_player_data(null)
	var bare_player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, no_skill_data)
	var bare_enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	var bare_controller: PlayerController = _create_controller(bare_player)
	assert_bool(bare_controller.order_skill(bare_enemy)).is_false()
	assert_str(bare_controller.get_order_description()).is_equal("待命")


func test_order_skill_records_target_and_updates_description() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"御剑斩", 25.0, 2.5, 120.0, 1.8)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(200.0, 0.0)
	var controller: PlayerController = _create_controller(player)

	assert_bool(controller.order_skill(enemy)).is_true()
	var description: String = controller.get_order_description()
	assert_bool(description.contains("施放技能")).is_true()
	assert_bool(description.contains("御剑斩")).is_true()
	assert_bool(description.contains(enemy.data.display_name)).is_true()
	assert_float(player.current_spirit).is_equal_approx(player.data.max_spirit, APPROX)

	# 未显式传目标时沿用当前攻击目标：普通攻击命令先记录目标，技能命令即可复用。
	controller.clear_orders()
	controller.order_attack(enemy)
	assert_bool(controller.order_skill()).is_true()
	assert_bool(controller.get_order_description().contains("御剑斩")).is_true()


func test_out_of_range_target_is_approached_before_casting() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"ranged_strike", 25.0, 2.0, 60.0, 1.5)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(200.0, 0.0)
	var controller: PlayerController = _create_controller(player)
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)

	assert_bool(controller.order_skill(enemy)).is_true()
	controller.update_controller(0.1)

	assert_int(player.state).is_equal(Pawn.State.MOVING)
	assert_bool(player.velocity.x > 0.0).is_true()
	assert_bool(player.velocity.y == 0.0).is_true()
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_float(_total_effective_health(enemy)).is_equal_approx(enemy_total_before, APPROX)
	assert_bool(controller.get_order_description().contains("施放技能")).is_true()


func test_in_range_cast_spends_spirit_damages_and_keeps_attack_order() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"burst", 25.0, 2.5, 120.0, 1.8)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)
	var controller: PlayerController = _create_controller(player)
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)
	var expected_damage: float = maxf(1.0, player.data.attack * skill.damage_multiplier - enemy.data.defense)

	assert_bool(controller.order_skill(enemy)).is_true()
	controller.update_controller(0.1)

	assert_float(player.current_spirit).is_equal_approx(spirit_before - skill.spirit_cost, APPROX)
	assert_float(enemy_total_before - _total_effective_health(enemy)).is_equal_approx(expected_damage, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(skill.cooldown, APPROX)
	# 施法成功后技能命令清除，但普通攻击目标保留，控制权回到既有攻击流程。
	assert_str(controller.get_order_description()).is_equal("攻击 %s" % enemy.data.display_name)


func test_target_death_during_approach_cancels_skill_without_side_effects() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"execute", 25.0, 2.0, 60.0, 1.8)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(200.0, 0.0)
	var controller: PlayerController = _create_controller(player)
	var spirit_before: float = player.current_spirit

	assert_bool(controller.order_skill(enemy)).is_true()
	enemy.take_damage(enemy.data.defense + enemy.data.max_shield + enemy.data.max_health + 50.0)
	assert_bool(enemy.is_dead()).is_true()

	controller.update_controller(0.1)

	assert_bool(controller.get_order_description().contains("施放技能")).is_false()
	assert_str(controller.get_order_description()).is_equal("待命")
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()


func test_insufficient_spirit_falls_back_to_normal_attack() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"expensive", 30.0, 1.0, 100.0, 2.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill, 10.0))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)
	var controller: PlayerController = _create_controller(player)
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = _total_effective_health(enemy)

	assert_bool(controller.order_skill(enemy)).is_true()
	controller.update_controller(0.1)

	# 灵力不足：不扣灵力、不进冷却，技能命令清除并回退普通攻击目标。
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_str(controller.get_order_description()).is_equal("攻击 %s" % enemy.data.display_name)

	controller.update_controller(0.1)
	assert_float(enemy_total_before - _total_effective_health(enemy)).is_equal_approx(25.0, APPROX)


func test_cooldown_falls_back_to_normal_attack_without_double_spend() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"quick", 5.0, 2.0, 100.0, 0.1)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)
	var controller: PlayerController = _create_controller(player)
	var spirit_before: float = player.current_spirit

	assert_bool(controller.order_skill(enemy)).is_true()
	controller.update_controller(0.1)
	assert_float(player.current_spirit).is_equal_approx(spirit_before - skill.spirit_cost, APPROX)
	var spirit_after_first_cast: float = player.current_spirit

	assert_bool(controller.order_skill(enemy)).is_true()
	controller.update_controller(0.1)

	assert_float(player.current_spirit).is_equal_approx(spirit_after_first_cast, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_equal_approx(skill.cooldown, APPROX)
	assert_str(controller.get_order_description()).is_equal("攻击 %s" % enemy.data.display_name)