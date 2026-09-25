extends GdUnitTestSuite

## 集成层：EncounterSession 的多人队伍契约（INC-PAWNS-020）。
##
## 只验证「队伍数据契约 → 真实单位 → 按成员 id 的快照」这条链路：
## 2 / 3 / 4 人队伍按成员顺序创建真实 Pawn、旧单单位 API 仍指向主单位、
## 队友阵亡不提前终局（团队胜负属于 INC-COMBAT-009），
## 队伍快照按成员 id 写回而不是按数组下标互相覆盖。

const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const PLAYER_DATA_ID: StringName = &"player_001"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const TECHNIQUE_PATH: String = "res://game/cultivation/data/techniques/sword_cultivation.tres"
const APPROX: float = 0.001

var _container_seq: int = 0


func _member(member_id: StringName, health: float = 120.0) -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = member_id
	data.display_name = String(member_id)
	data.max_health = health
	data.max_shield = 20.0
	return data


func _squad(member_ids: Array, squad_id: StringName = &"test_party") -> SquadDefinition:
	var squad: SquadDefinition = SquadDefinition.new()
	squad.id = squad_id
	squad.display_name = "测试队伍"
	var members: Array[PawnData] = []
	for member_id: Variant in member_ids:
		members.append(_member(StringName(member_id)))
	squad.members = members
	return squad


func _enemy_encounter(count: int) -> EncounterDefinition:
	var ids: Array = []
	for index: int in range(count):
		ids.append("enemy_%d" % (index + 1))
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"squad_encounter"
	encounter.display_name = "队伍遭遇"
	encounter.enemy_squad = _squad(ids, &"enemy_party")
	return encounter


## 会话只依赖一个单位容器：每个用例造一个独立容器，避免多场对局抢占同一批固定节点名。
func _spawn_session(player_squad: SquadDefinition) -> EncounterSession:
	_container_seq += 1
	var container: Node2D = Node2D.new()
	container.name = "%s%d" % [EncounterSession.PAWNS_CONTAINER_NAME, _container_seq]
	auto_free(container)
	add_child(container)

	var session: EncounterSession = EncounterSession.new()
	session.name = "EncounterSession"
	session.pawns_container = container
	session.player_data = load(PLAYER_DATA_PATH) as PawnData
	session.player_squad = player_squad
	auto_free(session)
	add_child(session)
	return session


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 2 / 3 / 4 人队伍都能按成员顺序创建真实单位，人数与命名都可独立断言。
func test_two_three_and_four_member_squads_spawn_in_order() -> void:
	for player_count: int in [2, 3, 4]:
		var session: EncounterSession = _spawn_session(_squad(["hero", "guard", "controller", "swordsman"]))
		assert_bool(session.begin(_enemy_encounter(player_count))).is_true()

		assert_int(session.get_player_unit_count()).is_equal(player_count)
		assert_int(session.get_enemy_unit_count()).is_equal(player_count)

		var players: Array[Pawn] = session.get_player_units()
		# 第 0 位是主角槽位：运行时玩家档案覆盖队伍静态档案，主角身份不因队伍资源改变。
		assert_str(String(players[0].data.id)).is_equal(String(PLAYER_DATA_ID))
		assert_str(String(players[1].data.id)).is_equal("guard")
		assert_str(String(players[0].name)).is_equal(EncounterSession.PLAYER_NODE_NAME)
		assert_str(String(players[1].name)).is_equal("PlayerPawn_2")
		if player_count >= 3:
			assert_str(String(players[2].data.id)).is_equal("controller")
			assert_str(String(players[2].name)).is_equal("PlayerPawn_3")
		if player_count == 4:
			assert_str(String(players[3].data.id)).is_equal("swordsman")
			assert_str(String(players[3].name)).is_equal("PlayerPawn_4")

		var enemies: Array[Pawn] = session.get_enemy_units()
		assert_str(String(enemies[0].data.id)).is_equal("enemy_1")
		assert_str(String(enemies[0].name)).is_equal(EncounterSession.ENEMY_NODE_NAME)
		assert_str(String(enemies[1].name)).is_equal("EnemyPawn_2")

		var container: Node2D = session.resolve_pawns_container()
		assert_int(container.get_child_count()).is_equal(player_count * 2)
		await await_idle_frame()


## 旧单敌人遭遇不受多人扩展影响：仍然是 1v1，路径与命名保持原样。
func test_legacy_single_enemy_encounter_stays_one_vs_one() -> void:
	var session: EncounterSession = _spawn_session(_squad(["hero", "guard"]))
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"legacy_encounter"
	encounter.display_name = "旧遭遇"
	encounter.enemy_profile = load(ENEMY_DATA_PATH) as PawnData

	assert_bool(session.begin(encounter)).is_true()

	assert_int(session.get_player_unit_count()).is_equal(1)
	assert_int(session.get_enemy_unit_count()).is_equal(1)
	assert_str(String(session.get_player_pawn().name)).is_equal(EncounterSession.PLAYER_NODE_NAME)
	assert_str(String(session.get_enemy_pawn().name)).is_equal(EncounterSession.ENEMY_NODE_NAME)
	assert_int(session.resolve_pawns_container().get_child_count()).is_equal(2)
	await await_idle_frame()


## 主单位代理与按 id 查找：旧调用方拿到的仍是各自队伍的第 0 位。
func test_primary_accessors_and_id_lookup() -> void:
	var session: EncounterSession = _spawn_session(_squad(["hero", "guard", "controller"]))
	assert_bool(session.begin(_enemy_encounter(3))).is_true()

	assert_object(session.get_player_pawn()).is_same(session.get_player_units()[0])
	assert_object(session.get_enemy_pawn()).is_same(session.get_enemy_units()[0])
	assert_object(session.get_player_unit_by_id(PLAYER_DATA_ID)).is_same(session.get_player_pawn())
	assert_str(String(session.get_player_unit_by_id(&"guard").data.id)).is_equal("guard")
	assert_object(session.get_player_unit_by_id(&"missing")).is_null()
	assert_object(session.get_player_unit_by_id(&"")).is_null()
	assert_str(String(session.get_enemy_unit_by_id(&"enemy_2").data.id)).is_equal("enemy_2")
	await await_idle_frame()


## 队友与副敌人阵亡不提前终局：团队胜负留给 INC-COMBAT-009。
func test_teammate_death_does_not_end_the_encounter() -> void:
	var session: EncounterSession = _spawn_session(_squad(["hero", "guard", "controller", "swordsman"]))
	var finished: Array = []
	session.encounter_finished.connect(func(_encounter: EncounterDefinition, outcome: int) -> void:
		finished.append(outcome)
	)
	assert_bool(session.begin(_enemy_encounter(4))).is_true()

	var guard: Pawn = session.get_player_unit_by_id(&"guard")
	var side_enemy: Pawn = session.get_enemy_unit_by_id(&"enemy_3")
	guard.take_damage(_lethal_damage(guard))
	side_enemy.take_damage(_lethal_damage(side_enemy))

	assert_bool(guard.is_dead()).is_true()
	assert_bool(side_enemy.is_dead()).is_true()
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_array(finished).is_empty()
	# 队友阵亡不改变队伍规模：死亡单位仍留在集合里，供 UI 表达「阵亡但未消失」。
	assert_int(session.get_player_unit_count()).is_equal(4)
	await await_idle_frame()


## 主玩家阵亡仍然立即失败（既有语义不变）。
func test_primary_player_death_still_loses_the_encounter() -> void:
	var session: EncounterSession = _spawn_session(_squad(["hero", "guard"]))
	var finished: Array = []
	session.encounter_finished.connect(func(_encounter: EncounterDefinition, outcome: int) -> void:
		finished.append(outcome)
	)
	assert_bool(session.begin(_enemy_encounter(2))).is_true()

	var primary: Pawn = session.get_player_pawn()
	primary.take_damage(_lethal_damage(primary))

	assert_int(session.get_state()).is_equal(EncounterSession.State.ENEMY_WIN)
	assert_array(finished).contains_exactly([EncounterSession.State.ENEMY_WIN])
	# 队伍里仍有存活队友：失败只由主角阵亡决定，而不是队伍被清空。
	assert_bool(session.get_player_unit_by_id(&"guard").is_alive()).is_true()
	assert_bool(session.get_enemy_pawn().is_alive()).is_true()
	await await_idle_frame()


## 队伍资源快照按成员 id 写回：即使两支队伍的成员顺序对调也不会错配。
func test_squad_state_snapshot_matches_by_member_id_not_index() -> void:
	var first_session: EncounterSession = _spawn_session(_squad(["hero", "alpha", "beta"], &"party_a"))
	assert_bool(first_session.begin(_enemy_encounter(3))).is_true()

	var alpha: Pawn = first_session.get_player_unit_by_id(&"alpha")
	assert_object(alpha).is_not_null()
	alpha.take_damage(50.0)
	var damaged_health: float = alpha.current_health
	assert_bool(damaged_health < alpha.data.max_health).is_true()

	var snapshot: SquadResourceSnapshot = first_session.capture_squad_state()
	assert_int(snapshot.get_member_count()).is_equal(3)
	assert_bool(snapshot.has_member(&"alpha")).is_true()

	# 第二支队伍把 alpha / beta 的顺序对调：只有按 id 匹配才能把损耗写回正确的人。
	var second_session: EncounterSession = _spawn_session(_squad(["hero", "beta", "alpha"], &"party_b"))
	assert_bool(second_session.begin(_enemy_encounter(3))).is_true()
	var second_alpha: Pawn = second_session.get_player_unit_by_id(&"alpha")
	var second_beta: Pawn = second_session.get_player_unit_by_id(&"beta")
	assert_float(second_alpha.current_health).is_equal_approx(second_alpha.data.max_health, APPROX)

	var applied: int = second_session.apply_squad_state(snapshot)

	assert_int(applied).is_equal(3)
	assert_float(second_alpha.current_health).is_equal_approx(damaged_health, APPROX)
	assert_float(second_beta.current_health).is_equal_approx(second_beta.data.max_health, APPROX)
	await await_idle_frame()


## 缺失成员安全跳过：目标队伍没有的 id 不会写进任何单位，也不会按下标顶替。
func test_squad_state_snapshot_skips_missing_members() -> void:
	var first_session: EncounterSession = _spawn_session(_squad(["hero", "alpha"]))
	assert_bool(first_session.begin(_enemy_encounter(2))).is_true()
	var snapshot: SquadResourceSnapshot = first_session.capture_squad_state()

	var other_session: EncounterSession = _spawn_session(_squad(["hero", "omega"]))
	assert_bool(other_session.begin(_enemy_encounter(2))).is_true()
	var omega: Pawn = other_session.get_player_unit_by_id(&"omega")

	var applied: int = other_session.apply_squad_state(snapshot)

	# 只有主角 id 相同：命中的写回 1 个，omega 保持满状态。
	assert_int(applied).is_equal(1)
	assert_float(omega.current_health).is_equal_approx(omega.data.max_health, APPROX)
	await await_idle_frame()


## 队伍运行时进度同样按成员 id 写回：领悟功法只落到同一成员身上。
func test_squad_progress_snapshot_restores_learned_techniques_by_member_id() -> void:
	var session: EncounterSession = _spawn_session(_squad(["hero", "alpha", "beta"]))
	assert_bool(session.begin(_enemy_encounter(3))).is_true()

	var technique: TechniqueDefinition = load(TECHNIQUE_PATH) as TechniqueDefinition
	assert_object(technique).is_not_null()
	var alpha: Pawn = session.get_player_unit_by_id(&"alpha")
	assert_bool(alpha.learn_technique(technique)).is_true()

	var progress: SquadProgressSnapshot = session.capture_squad_progress()
	assert_int(progress.get_member_count()).is_equal(3)
	assert_bool(progress.has_member(&"alpha")).is_true()

	assert_bool(session.restart()).is_true()
	assert_bool(session.get_player_unit_by_id(&"alpha").has_learned_technique(technique.id)).is_false()

	assert_int(session.apply_squad_progress(progress)).is_equal(3)
	assert_bool(session.get_player_unit_by_id(&"alpha").has_learned_technique(technique.id)).is_true()
	assert_bool(session.get_player_unit_by_id(&"beta").has_learned_technique(technique.id)).is_false()
	await await_idle_frame()
