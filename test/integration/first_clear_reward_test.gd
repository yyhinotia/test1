extends GdUnitTestSuite

## 集成层：首通奖励发放与 Build 跨局延续（INC-WORLD-007）。
## 用真实遭遇 / 玩家档案 / 技能资源跑通「首通解锁 → 玩家手动换 Build → 换遭遇仍生效」，
## 并锁死两条红线：奖励不自动装配、重复通关不重复发放。

const ENCOUNTER_1V1_PATH: String = "res://game/world/data/encounters/build_test_1v1.tres"
const ENCOUNTER_1V2_PATH: String = "res://game/world/data/encounters/build_test_1v2.tres"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"

const APPROX: float = 0.001


func _spawn_session() -> EncounterSession:
	var container: Node2D = Node2D.new()
	container.name = EncounterSession.PAWNS_CONTAINER_NAME
	auto_free(container)
	add_child(container)

	var session: EncounterSession = EncounterSession.new()
	session.name = "EncounterSession"
	session.pawns_container = container
	session.player_data = load(PLAYER_DATA_PATH) as PawnData
	session.player_spawn_position = Vector2(500.0, 300.0)
	session.enemy_spawn_position = Vector2(500.0, 380.0)
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


func _wipe_enemies(session: EncounterSession) -> void:
	for enemy: Pawn in session.get_enemy_units():
		enemy.take_damage(enemy.data.defense + enemy.data.max_health + enemy.data.max_shield + 50.0)


## 开一局真实遭遇并走到胜利结算（敌方全灭才判胜，INC-COMBAT-009 语义）。
func _begin_and_win(session: EncounterSession, encounter_path: String) -> void:
	assert_bool(session.begin(load(encounter_path) as EncounterDefinition)).is_true()
	_isolate(session)
	_wipe_enemies(session)
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)


func _equipped_ids(pawn: Pawn) -> Array:
	var ids: Array = []
	for skill: ActiveSkillDefinition in pawn.get_equipped_active_skills():
		ids.append(String(skill.id))
	return ids


## 首通只解锁、不自动装配：玩家必须自己把定身术放进 Build（Gate C）。
func test_first_clear_unlocks_the_reward_without_auto_equipping() -> void:
	var session: EncounterSession = _spawn_session()
	_begin_and_win(session, ENCOUNTER_1V1_PATH)
	var player: Pawn = session.get_player_pawn()

	assert_bool(player.has_learned_active_skill(&"binding_spell")).is_true()
	assert_bool(player.has_explicit_active_skill_loadout()).is_false()
	# 静态预设 Build A 原样保留：御剑斩 + 护体真气。
	assert_array(_equipped_ids(player)).contains_exactly(["sword_strike", "guard_true_qi"])
	await await_idle_frame()


## 没有配置首通奖励的遭遇不得顺手发技能：奖励来源必须唯一。
func test_encounters_without_a_reward_do_not_unlock_binding() -> void:
	var session: EncounterSession = _spawn_session()
	_begin_and_win(session, ENCOUNTER_1V2_PATH)
	var player: Pawn = session.get_player_pawn()

	assert_bool(player.has_learned_active_skill(&"binding_spell")).is_false()
	assert_array(player.get_learned_active_skills()).is_empty()
	await await_idle_frame()


## 重开同一遭遇：瞬时战斗状态清零，但已解锁技能延续且不会重复记账。
func test_repeated_clears_do_not_duplicate_the_reward() -> void:
	var session: EncounterSession = _spawn_session()
	_begin_and_win(session, ENCOUNTER_1V1_PATH)
	var first_clear_pawn: Pawn = session.get_player_pawn()
	# 先打穿护盾再伤到生命：本用例只验证「瞬时的资源损耗不进入新一局」这一条。
	first_clear_pawn.take_damage(first_clear_pawn.data.max_shield + 20.0)
	assert_float(first_clear_pawn.current_health).is_less(first_clear_pawn.data.max_health)

	assert_bool(session.restart()).is_true()
	_isolate(session)
	var restarted: Pawn = session.get_player_pawn()
	# 瞬时状态不残留：新单位满血、未处于定身中、事件记录为空。
	assert_float(restarted.current_health).is_equal_approx(restarted.data.max_health, APPROX)
	assert_bool(restarted.is_stunned()).is_false()
	assert_int(session.get_combat_event_log().get_event_count()).is_zero()
	# 养成进度延续，且只记一次解锁。
	assert_bool(restarted.has_learned_active_skill(&"binding_spell")).is_true()
	assert_int(restarted.get_learned_active_skills().size()).is_equal(1)

	_wipe_enemies(session)
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_int(restarted.get_learned_active_skills().size()).is_equal(1)
	await await_idle_frame()


## 玩家主动换 Build B 后，换遭遇起局仍保持「御剑斩 + 定身术」。
func test_player_build_choice_survives_restart_and_next_encounter() -> void:
	var session: EncounterSession = _spawn_session()
	_begin_and_win(session, ENCOUNTER_1V1_PATH)
	var player: Pawn = session.get_player_pawn()

	var build_b: Array[ActiveSkillDefinition] = []
	build_b.append(load(SWORD_SKILL_PATH) as ActiveSkillDefinition)
	build_b.append(load(BINDING_SKILL_PATH) as ActiveSkillDefinition)
	assert_bool(player.set_active_skill_loadout(build_b)).is_true()
	assert_bool(player.has_explicit_active_skill_loadout()).is_true()

	assert_bool(session.begin(load(ENCOUNTER_1V2_PATH) as EncounterDefinition)).is_true()
	_isolate(session)
	var carried: Pawn = session.get_player_pawn()
	assert_bool(carried.has_learned_active_skill(&"binding_spell")).is_true()
	assert_bool(carried.has_explicit_active_skill_loadout()).is_true()
	assert_array(_equipped_ids(carried)).contains_exactly(["sword_strike", "binding_spell"])
	await await_idle_frame()
