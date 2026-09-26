extends GdUnitTestSuite

## 集成层：问题秘境房间链与 Build 差异（INC-WORLD-008）。
##
## 待回答的问题：秘境是否按「问题型」而非「数值递增」编排；首通奖励是否真的把
## 「遇到问题 → 获得技能 → 后续房间再次需要该技能」串起来；同一套 Build 面对
## 高防御 / 高爆发两类问题时，是否产生可复现的客观差异。

const PROBLEM_DUNGEON_PATH: String = "res://game/world/data/dungeons/problem_dungeon.tres"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_SKILL_PATH: String = "res://game/pawns/data/player_guard_skill.tres"

const DELTA: float = 1.0 / 60.0
const MAX_STEPS: int = 3600


func _spawn_run() -> DungeonRun:
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

	var run: DungeonRun = DungeonRun.new()
	run.name = "DungeonRun"
	run.encounter_session = session
	auto_free(run)
	add_child(run)
	return run


func _load_problem_dungeon() -> DungeonDefinition:
	return load(PROBLEM_DUNGEON_PATH) as DungeonDefinition


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 问题房间可能是多人队伍：必须清空全部敌人，不能只杀 primary。
func _clear_all_enemies(run: DungeonRun) -> void:
	for enemy: Pawn in run.encounter_session.get_enemy_units():
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
			continue
		enemy.take_damage(_lethal_damage(enemy))


func _advance_after_clear(run: DungeonRun) -> void:
	_clear_all_enemies(run)
	assert_int(run.get_state()).is_equal(DungeonRun.State.AWAITING_DECISION)
	assert_bool(run.advance()).is_true()


func _current_room(run: DungeonRun) -> DungeonRoom:
	return run.get_current_room()


func test_problem_dungeon_advances_through_distinct_problem_rooms() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_problem_dungeon()
	assert_bool(run.start(dungeon)).is_true()

	var first: DungeonRoom = _current_room(run)
	assert_array(first.get_problem_tags()).contains_exactly([1])
	assert_array(first.get_problem_labels()).contains_exactly(["近战持续压力"])

	_advance_after_clear(run)
	var second: DungeonRoom = _current_room(run)
	assert_array(second.get_problem_tags()).contains_exactly([2])
	assert_array(second.get_problem_labels()).contains_exactly(["远程压制"])

	_advance_after_clear(run)
	var third: DungeonRoom = _current_room(run)
	assert_array(third.get_problem_tags()).contains_exactly([2, 5])
	assert_array(third.get_problem_labels()).contains_exactly(["远程压制", "蓄力可打断"])
	assert_int(run.get_depth()).is_equal(3)


## 首通奖励链：前六间依次解锁六个非初始技能；每个技能都在后续房间的价值轴里被再次需要。
func test_problem_dungeon_first_clear_rewards_unlock_in_chain() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_problem_dungeon()
	assert_bool(run.start(dungeon)).is_true()

	var expected_rewards: Array[StringName] = [
		&"dash_step",
		&"binding_spell",
		&"sword_aoe",
		&"blood_drain",
		&"rejuvenation",
		&"breaking_slash",
	]
	for index: int in expected_rewards.size():
		var player: Pawn = run.encounter_session.get_player_pawn()
		assert_bool(player.has_learned_active_skill(expected_rewards[index])).is_false()
		_clear_all_enemies(run)
		assert_int(run.get_state()).is_equal(DungeonRun.State.AWAITING_DECISION)
		var cleared_player: Pawn = run.encounter_session.get_player_pawn()
		assert_bool(cleared_player.has_learned_active_skill(expected_rewards[index])).is_true()
		assert_bool(run.advance()).is_true()

	# 第六个奖励后进入第 7 间；后续房间不再发技能，只复用已解锁能力。
	assert_int(run.get_depth()).is_equal(7)
	var player_after_chain: Pawn = run.encounter_session.get_player_pawn()
	assert_int(player_after_chain.get_learned_active_skills().size()).is_equal(6)


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


## 同一套 Build（御剑斩 + 护体真气）打完整遭遇：固定策略只记录客观量，不评价流派。
func _run_encounter(encounter: EncounterDefinition) -> Dictionary:
	var session: EncounterSession = _spawn_session()
	assert_object(encounter).is_not_null()
	assert_bool(session.begin(encounter)).is_true()
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


## 高防御与高爆发来自同一份问题秘境资源；同一 Build 的耗时 / 护盾吸收差异必须可复现。
func test_same_build_reprices_high_defense_and_burst_problem_rooms() -> void:
	var dungeon: DungeonDefinition = _load_problem_dungeon()
	var endurance_room: DungeonRoom = dungeon.get_room(4)
	var burst_room: DungeonRoom = dungeon.get_room(5)
	assert_array(endurance_room.get_problem_tags()).contains_exactly([4])
	assert_array(burst_room.get_problem_tags()).contains_exactly([3])

	var endurance: Dictionary = _run_encounter(endurance_room.encounter)
	var burst: Dictionary = _run_encounter(burst_room.encounter)

	assert_int(endurance["steps"] as int).is_less(MAX_STEPS)
	assert_int(burst["steps"] as int).is_less(MAX_STEPS)
	assert_bool((endurance["outcome"] as int) != EncounterSession.State.RUNNING).is_true()
	assert_bool((burst["outcome"] as int) != EncounterSession.State.RUNNING).is_true()
	# 高防御拉长同一单体输出轴；高爆发把护盾的单次吸收顶得更满。
	assert_bool((endurance["steps"] as int) > (burst["steps"] as int)).is_true()
	assert_bool((burst["max_shield_absorbed"] as float) > (endurance["max_shield_absorbed"] as float)).is_true()
