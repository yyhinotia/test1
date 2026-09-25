extends GdUnitTestSuite

## 集成层：危险窗口调度、CombatEvent 接线与 1vN 终局判定（INC-COMBAT-009）。
## 只消费正式 PawnData / EncounterDefinition 与 EncounterSession，不在测试里复制伤害公式。

const DANGER_SKILL_PATH: String = "res://game/pawns/data/skills/enemy_boss_cleave.tres"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"

const APPROX: float = 0.001


func _spawn_session(player_data: PawnData) -> EncounterSession:
	var container: Node2D = Node2D.new()
	container.name = EncounterSession.PAWNS_CONTAINER_NAME
	auto_free(container)
	add_child(container)

	var session: EncounterSession = EncounterSession.new()
	session.name = "EncounterSession"
	session.pawns_container = container
	session.player_data = player_data
	session.player_spawn_position = Vector2(500.0, 300.0)
	session.enemy_spawn_position = Vector2(500.0, 350.0)
	auto_free(session)
	add_child(session)
	return session


func _make_player_data(with_binding: bool, max_health: float = 500.0, max_shield: float = 100.0) -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = &"build_test_player"
	data.display_name = "验证修士"
	data.faction = &"player"
	data.max_health = max_health
	data.max_shield = max_shield
	data.max_spirit = 200.0
	data.attack = 20.0
	data.defense = 0.0
	data.move_speed = 0.0
	data.attack_range = 76.0
	data.attack_interval = 0.8
	if with_binding:
		var skills: Array[ActiveSkillDefinition] = []
		skills.append(load(BINDING_SKILL_PATH) as ActiveSkillDefinition)
		data.active_skills = skills
	return data


func _make_boss_data() -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = &"build_test_boss"
	data.display_name = "验证 Boss"
	data.faction = &"enemy"
	data.max_health = 900.0
	data.max_shield = 0.0
	data.max_spirit = 0.0
	data.attack = 20.0
	data.defense = 0.0
	data.move_speed = 0.0
	data.attack_range = 72.0
	data.attack_interval = 1.8
	data.dangerous_skill = load(DANGER_SKILL_PATH) as ActiveSkillDefinition
	data.danger_window_interval = 8.0
	data.danger_window_duration = 2.0
	return data


func _make_dummy_enemy_data() -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = &"build_test_dummy"
	data.display_name = "验证副敌"
	data.faction = &"enemy"
	data.max_health = 120.0
	data.max_shield = 0.0
	data.attack = 10.0
	data.defense = 0.0
	data.move_speed = 0.0
	data.attack_range = 72.0
	data.attack_interval = 1.5
	return data


func _make_encounter(members: Array[PawnData]) -> EncounterDefinition:
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"build_test_encounter"
	encounter.display_name = "Build 验证遭遇"
	encounter.player_count = 1
	if members.size() == 1:
		encounter.enemy_profile = members[0]
	else:
		var squad: SquadDefinition = SquadDefinition.new()
		squad.id = &"build_test_enemy_squad"
		squad.display_name = "验证敌人队伍"
		squad.members = members
		encounter.enemy_squad = squad
	return encounter


func _isolate(session: EncounterSession) -> void:
	session.set_physics_process(false)
	for unit: Pawn in session.get_player_units() + session.get_enemy_units():
		unit.set_physics_process(false)
		var controller: PawnController = unit.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


func test_danger_window_opens_on_fixed_interval_and_hits_without_control() -> void:
	var player_data: PawnData = _make_player_data(false, 500.0, 0.0)
	var session: EncounterSession = _spawn_session(player_data)
	var encounter: EncounterDefinition = _make_encounter([_make_boss_data()])
	assert_bool(session.begin(encounter)).is_true()
	_isolate(session)

	var player: Pawn = session.get_player_pawn()
	var log: CombatEventLog = session.get_combat_event_log()
	assert_bool(log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED)).is_false()

	session._physics_process(7.9)
	assert_bool(log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED)).is_false()
	session._physics_process(0.2)
	assert_bool(log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED)).is_true()

	var health_before: float = player.current_health
	session._physics_process(2.1)

	assert_float(player.current_health).is_less(health_before)
	assert_bool(log.has_event_type(CombatEvent.SKILL_HIT)).is_true()
	assert_bool(log.has_event_type(CombatEvent.SKILL_CANCELLED)).is_false()
	assert_int(log.count_events_of_type(CombatEvent.DANGER_WINDOW_OPENED)).is_equal(1)
	assert_int(log.count_events_of_type(CombatEvent.SKILL_HIT)).is_equal(1)
	await await_idle_frame()


func test_stun_cancels_danger_window_and_prevents_damage() -> void:
	var player_data: PawnData = _make_player_data(true)
	var session: EncounterSession = _spawn_session(player_data)
	var encounter: EncounterDefinition = _make_encounter([_make_boss_data()])
	assert_bool(session.begin(encounter)).is_true()
	_isolate(session)

	var player: Pawn = session.get_player_pawn()
	var boss: Pawn = session.get_enemy_pawn()
	var binding: ActiveSkillDefinition = load(BINDING_SKILL_PATH) as ActiveSkillDefinition
	var log: CombatEventLog = session.get_combat_event_log()

	session._physics_process(8.1)
	assert_bool(log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED)).is_true()

	var health_before: float = player.current_health
	var shield_before: float = player.current_shield
	assert_bool(player.cast_skill(binding, boss)).is_true()
	assert_bool(boss.is_stunned()).is_true()
	session._physics_process(0.1)

	assert_float(player.current_health).is_equal_approx(health_before, APPROX)
	assert_float(player.current_shield).is_equal_approx(shield_before, APPROX)
	assert_bool(log.has_event_type(CombatEvent.SKILL_STUNNED)).is_true()
	assert_bool(log.has_event_type(CombatEvent.SKILL_CANCELLED)).is_true()
	assert_bool(log.has_event_type(CombatEvent.SKILL_HIT)).is_false()
	assert_bool(log.has_event_type(CombatEvent.SKILL_BLOCKED)).is_false()

	var opened_index: int = log.get_index_of_event_type(CombatEvent.DANGER_WINDOW_OPENED)
	var cast_index: int = log.get_index_of_event_type(CombatEvent.SKILL_CAST)
	var stunned_index: int = log.get_index_of_event_type(CombatEvent.SKILL_STUNNED)
	var cancelled_index: int = log.get_index_of_event_type(CombatEvent.SKILL_CANCELLED)
	assert_bool(opened_index < cast_index).is_true()
	assert_bool(cast_index < stunned_index).is_true()
	assert_bool(stunned_index < cancelled_index).is_true()
	await await_idle_frame()


func test_enemy_wipe_is_required_for_player_win() -> void:
	var session: EncounterSession = _spawn_session(_make_player_data(false, 2000.0, 0.0))
	var encounter: EncounterDefinition = _make_encounter([_make_boss_data(), _make_dummy_enemy_data()])
	assert_bool(session.begin(encounter)).is_true()
	_isolate(session)

	var enemies: Array[Pawn] = session.get_enemy_units()
	assert_int(enemies.size()).is_equal(2)
	enemies[0].take_damage(_lethal_damage(enemies[0]))
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)

	enemies[1].take_damage(_lethal_damage(enemies[1]))
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_bool(session.get_combat_event_log().has_event_type(CombatEvent.COMBAT_END)).is_true()
	await await_idle_frame()


func test_player_death_still_ends_the_encounter_as_loss() -> void:
	var session: EncounterSession = _spawn_session(_make_player_data(false))
	var encounter: EncounterDefinition = _make_encounter([_make_boss_data()])
	assert_bool(session.begin(encounter)).is_true()
	_isolate(session)

	var player: Pawn = session.get_player_pawn()
	player.take_damage(_lethal_damage(player))

	assert_int(session.get_state()).is_equal(EncounterSession.State.ENEMY_WIN)
	assert_bool(session.get_combat_event_log().has_event_type(CombatEvent.COMBAT_END)).is_true()
	await await_idle_frame()


func test_restart_resets_event_log_and_schedulers() -> void:
	var session: EncounterSession = _spawn_session(_make_player_data(false, 500.0, 0.0))
	var encounter: EncounterDefinition = _make_encounter([_make_boss_data()])
	assert_bool(session.begin(encounter)).is_true()
	_isolate(session)

	session._physics_process(8.1)
	assert_int(session.get_combat_event_log().get_event_count()).is_greater(0)

	assert_bool(session.restart()).is_true()
	var restarted_log: CombatEventLog = session.get_combat_event_log()
	assert_int(restarted_log.get_event_count()).is_zero()
	assert_float(restarted_log.get_clock()).is_zero()
	assert_bool(restarted_log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED)).is_false()
	await await_idle_frame()
