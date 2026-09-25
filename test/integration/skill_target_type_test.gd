extends GdUnitTestSuite

## 集成层：技能目标类型必须同时约束 PlayerController 的目标解析与 Pawn 的最终施法校验。

const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"


func _make_skill(
		id: StringName,
		target_type: ActiveSkillDefinition.SkillTargetType,
		effect_type: ActiveSkillDefinition.SkillEffectType = ActiveSkillDefinition.SkillEffectType.DAMAGE,
		cost: float = 0.0,
		cast_range: float = 100.0
	) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.target_type = target_type
	skill.effect_type = effect_type
	skill.spirit_cost = cost
	skill.cooldown = 1.0
	skill.cast_range = cast_range
	skill.damage_multiplier = 0.0
	skill.effect_value = 0.0
	return skill


func _make_player_data(skill: ActiveSkillDefinition) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = skill
	var skills: Array[ActiveSkillDefinition] = []
	if skill != null:
		skills.append(skill)
	data.active_skills = skills
	return data


func _spawn(scene_path: String, data: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data != null:
		pawn.data = data
	auto_free(pawn)
	add_child(pawn)
	return pawn


func test_pawn_target_validation_depends_on_skill_target_type() -> void:
	var self_skill: ActiveSkillDefinition = _make_skill(&"self_guard", ActiveSkillDefinition.SkillTargetType.SELF, ActiveSkillDefinition.SkillEffectType.SHIELD)
	var ally_skill: ActiveSkillDefinition = _make_skill(&"ally_heal", ActiveSkillDefinition.SkillTargetType.ALLY, ActiveSkillDefinition.SkillEffectType.HEAL)
	var enemy_skill: ActiveSkillDefinition = _make_skill(&"enemy_strike", ActiveSkillDefinition.SkillTargetType.ENEMY)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_player_data(self_skill))
	var ally: Pawn = _spawn(PLAYER_SCENE_PATH, _make_player_data(null))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)

	assert_bool(player.is_valid_skill_target(self_skill, player)).is_true()
	assert_bool(player.is_valid_skill_target(self_skill, ally)).is_false()
	assert_bool(player.is_valid_skill_target(self_skill, enemy)).is_false()

	assert_bool(player.is_valid_skill_target(ally_skill, ally)).is_true()
	assert_bool(player.is_valid_skill_target(ally_skill, player)).is_false()
	assert_bool(player.is_valid_skill_target(ally_skill, enemy)).is_false()

	assert_bool(player.is_valid_skill_target(enemy_skill, enemy)).is_true()
	assert_bool(player.is_valid_skill_target(enemy_skill, player)).is_false()
	assert_bool(player.is_valid_skill_target(enemy_skill, ally)).is_false()


func test_player_controller_self_skill_resolves_caster_without_explicit_target() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"self_guard", ActiveSkillDefinition.SkillTargetType.SELF, ActiveSkillDefinition.SkillEffectType.SHIELD)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_player_data(skill))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(100.0, 0.0)
	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)

	assert_bool(controller.order_skill_instance(skill)).is_true()
	assert_bool(controller.get_order_description().contains("自身")).is_true()
	assert_bool(controller.order_skill_instance(skill, enemy)).is_false()


func test_player_controller_ally_requires_explicit_same_faction_target() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"ally_heal", ActiveSkillDefinition.SkillTargetType.ALLY, ActiveSkillDefinition.SkillEffectType.HEAL)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH, _make_player_data(skill))
	var ally: Pawn = _spawn(PLAYER_SCENE_PATH, _make_player_data(null))
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH)
	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)

	assert_bool(controller.order_skill_instance(skill)).is_false()
	assert_bool(controller.order_skill_instance(skill, enemy)).is_false()
	assert_bool(controller.order_skill_instance(skill, ally)).is_true()
	assert_bool(controller.get_order_description().contains(ally.data.display_name)).is_true()


func test_ai_supports_self_skill_without_retargeting_itself() -> void:
	var skill: ActiveSkillDefinition = _make_skill(&"self_guard", ActiveSkillDefinition.SkillTargetType.SELF, ActiveSkillDefinition.SkillEffectType.SHIELD)
	var enemy_data: PawnData = (load("res://game/pawns/data/enemy_pawn.tres") as PawnData).duplicate(true) as PawnData
	enemy_data.max_spirit = 60.0
	enemy_data.active_skill = skill
	var skills: Array[ActiveSkillDefinition] = [skill]
	enemy_data.active_skills = skills
	var enemy: Pawn = _spawn(ENEMY_SCENE_PATH, enemy_data)
	var player: Pawn = _spawn(PLAYER_SCENE_PATH)
	enemy.global_position = Vector2(100.0, 0.0)
	player.global_position = Vector2.ZERO
	var ai: AIController = enemy.get_controller() as AIController
	ai.bind(enemy)
	ai.set_target(player)
	var cast_ids: Array[StringName] = []
	enemy.skill_cast.connect(func(_pawn: Pawn, cast_skill: ActiveSkillDefinition, _target: Pawn) -> void:
		cast_ids.append(cast_skill.id)
	)

	ai.update_controller(3.1)

	assert_array(cast_ids).contains_exactly([&"self_guard"])
