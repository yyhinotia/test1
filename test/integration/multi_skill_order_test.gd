extends GdUnitTestSuite

## 集成层：多主动技能列表 → PlayerController/AIController → Pawn.cast_skill() 的真实组合。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const APPROX: float = 0.001


func _make_skill(id: StringName, cost: float, cooldown: float, cast_range: float, multiplier: float) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	skill.damage_multiplier = multiplier
	return skill


func _make_player_data(first: ActiveSkillDefinition, second: ActiveSkillDefinition) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = first
	var skills: Array[ActiveSkillDefinition] = []
	skills.append(first)
	skills.append(second)
	data.active_skills = skills
	data.max_spirit = 100.0
	data.initial_spirit_ratio = 1.0
	return data


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _bind_controller(player: Pawn) -> PlayerController:
	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)
	controller.set_physics_process(false)
	return controller


func test_player_can_order_the_second_skill_instance() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"first", 10.0, 1.0, 90.0, 1.0)
	var second: ActiveSkillDefinition = _make_skill(&"second", 30.0, 4.0, 90.0, 2.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(first, second))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)
	var controller: PlayerController = _bind_controller(player)
	var spirit_before: float = player.current_spirit

	assert_bool(controller.order_skill_instance(second, enemy)).is_true()
	assert_bool(controller.get_order_description().contains("second")).is_true()
	controller.update_controller(0.016)

	assert_float(player.current_spirit).is_equal_approx(spirit_before - second.spirit_cost, APPROX)
	assert_float(player.get_skill_cooldown_remaining(first.id)).is_zero()
	assert_float(player.get_skill_cooldown_remaining(second.id)).is_equal_approx(second.cooldown, APPROX)


func test_legacy_order_skill_still_uses_first_configured_skill() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"first", 5.0, 1.0, 90.0, 1.0)
	var second: ActiveSkillDefinition = _make_skill(&"second", 15.0, 2.0, 90.0, 2.0)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(first, second))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(50.0, 0.0)
	var controller: PlayerController = _bind_controller(player)

	assert_bool(controller.order_skill(enemy)).is_true()
	assert_bool(controller.get_order_description().contains("first")).is_true()
	controller.update_controller(0.016)

	assert_float(player.get_skill_cooldown_remaining(first.id)).is_equal_approx(first.cooldown, APPROX)
	assert_float(player.get_skill_cooldown_remaining(second.id)).is_zero()


func test_ai_tries_later_skill_when_earlier_skill_is_out_of_range() -> void:
	var short_skill: ActiveSkillDefinition = _make_skill(&"short", 10.0, 1.0, 40.0, 1.0)
	var long_skill: ActiveSkillDefinition = _make_skill(&"long", 20.0, 3.0, 160.0, 1.5)
	var enemy_data: PawnData = (load(ENEMY_DATA_PATH) as PawnData).duplicate(true) as PawnData
	enemy_data.max_spirit = 100.0
	enemy_data.initial_spirit_ratio = 1.0
	enemy_data.active_skill = short_skill
	var ai_skills: Array[ActiveSkillDefinition] = []
	ai_skills.append(short_skill)
	ai_skills.append(long_skill)
	enemy_data.active_skills = ai_skills
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH, enemy_data)
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	enemy.global_position = Vector2.ZERO
	player.global_position = Vector2(100.0, 0.0)
	var ai: AIController = enemy.get_controller() as AIController
	ai.bind(enemy)
	ai.set_target(player)
	var spirit_before: float = enemy.current_spirit

	ai.update_controller(3.1)

	assert_float(enemy.current_spirit).is_equal_approx(spirit_before - long_skill.spirit_cost, APPROX)
	assert_float(enemy.get_skill_cooldown_remaining(short_skill.id)).is_zero()
	assert_float(enemy.get_skill_cooldown_remaining(long_skill.id)).is_equal_approx(long_skill.cooldown, APPROX)
