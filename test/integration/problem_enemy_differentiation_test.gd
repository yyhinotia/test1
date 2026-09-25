extends GdUnitTestSuite

## 集成层：问题型敌人的客观差异（INC-COMBAT-011）。
##
## 同一套 Build、同一初始状态，只替换敌人档案，用固定时间步驱动真实控制器与 Pawn，
## 证明「不同敌人让不同技能的价值发生变化」：高防御拉长单体输出轴，高爆发逼出防御技能的吸收上限。
## 本用例只记录客观量，不评价玩家是否「喜欢」某个 Build。

const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_SKILL_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BURST_PATH: String = "res://game/pawns/data/enemies/enemy_blood_blade.tres"
const ENDURANCE_PATH: String = "res://game/pawns/data/enemies/enemy_iron_guard.tres"

const DELTA: float = 1.0 / 60.0
const MAX_STEPS: int = 3600


func _spawn_session() -> EncounterSession:
	var container: Node2D = Node2D.new()
	container.name = EncounterSession.PAWNS_CONTAINER_NAME
	auto_free(container)
	add_child(container)

	var session: EncounterSession = EncounterSession.new()
	session.name = "EncounterSession"
	session.pawns_container = container
	session.player_data = load(PLAYER_DATA_PATH) as PawnData
	auto_free(session)
	add_child(session)
	return session


func _build_encounter(profile_path: String) -> EncounterDefinition:
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"test_problem_differentiation"
	encounter.display_name = "问题型对照遭遇"
	encounter.enemy_profile = load(profile_path) as PawnData
	return encounter


func _isolate(session: EncounterSession) -> void:
	session.set_physics_process(false)
	for unit: Pawn in session.get_player_units() + session.get_enemy_units():
		unit.set_physics_process(false)
		var controller: PawnController = unit.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


func _primary_enemy(session: EncounterSession) -> Pawn:
	var primary: Pawn = session.get_enemy_pawn()
	if primary != null and is_instance_valid(primary) and primary.is_alive():
		return primary
	for unit: Pawn in session.get_enemy_units():
		if unit != null and is_instance_valid(unit) and unit.is_alive():
			return unit
	return null


## 同一套策略打一整个遭遇：护盾低于一半时补护体真气，御剑斩就绪且进入射程时施放，否则普攻追击。
## 记录通关步数、生命损失与「单次攻击最多被护盾吸收多少」——前两者是输出 / 生存轴，后者是防御技能价值。
func _run_encounter(profile_path: String) -> Dictionary:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_build_encounter(profile_path))).is_true()
	_isolate(session)

	var player: Pawn = session.get_player_pawn()
	var controller: PlayerController = player.get_controller() as PlayerController
	var sword: ActiveSkillDefinition = load(SWORD_SKILL_PATH) as ActiveSkillDefinition
	var guard: ActiveSkillDefinition = load(GUARD_SKILL_PATH) as ActiveSkillDefinition
	var initial_health: float = player.current_health
	var previous_shield: float = player.current_shield
	var max_shield_absorbed: float = 0.0
	var steps: int = 0

	while steps < MAX_STEPS and session.get_state() == EncounterSession.State.RUNNING:
		var target: Pawn = _primary_enemy(session)
		if target == null:
			break
		if player.can_cast_skill(guard, player) and player.current_shield < player.data.max_shield * 0.5:
			player.cast_skill(guard, player)
		elif player.can_cast_skill(sword, target):
			player.cast_skill(sword, target)

		controller.order_attack(target)
		controller.update_controller(DELTA)
		for enemy: Pawn in session.get_enemy_units():
			if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
				continue
			var ai_controller: AIController = enemy.get_controller() as AIController
			if ai_controller != null:
				ai_controller.update_controller(DELTA)
			enemy._physics_process(DELTA)
		player._physics_process(DELTA)

		if player.current_shield < previous_shield:
			max_shield_absorbed = maxf(max_shield_absorbed, previous_shield - player.current_shield)
		previous_shield = player.current_shield
		steps += 1

	return {
		"steps": steps,
		"outcome": session.get_state(),
		"health_lost": initial_health - player.current_health,
		"max_shield_absorbed": max_shield_absorbed,
	}


func test_high_defense_stretches_damage_axis_while_burst_forces_defense_value() -> void:
	var burst: Dictionary = _run_encounter(BURST_PATH)
	var endurance: Dictionary = _run_encounter(ENDURANCE_PATH)

	# 两种问题型都必须被真实推进到终局，而不是超时退出。
	assert_int(burst["steps"] as int).is_less(MAX_STEPS)
	assert_int(endurance["steps"] as int).is_less(MAX_STEPS)
	assert_bool((burst["outcome"] as int) != EncounterSession.State.RUNNING).is_true()
	assert_bool((endurance["outcome"] as int) != EncounterSession.State.RUNNING).is_true()

	# 高防御 / 高有效生命拉长同一套单体输出，证明「输出轴」被敌人问题重新定价。
	assert_bool((endurance["steps"] as int) > (burst["steps"] as int)).is_true()
	# 高爆发把护盾的单次吸收上限顶满，证明「防御轴」在另一种问题上才有价值。
	assert_bool((burst["max_shield_absorbed"] as float) > (endurance["max_shield_absorbed"] as float)).is_true()
