extends GdUnitTestSuite

## 集成层：EncounterSession 的起局 / 换敌 / 结算契约（INC-WORLD-002）。
##
## 用例只消费遭遇定义与正式 PawnData 档案，不复制任何伤害、护盾或胜负公式：
## 敌人数据来自 game/world/data/encounters/ 指向的三份正式档案，
## 终局一律用「固定时间步驱动真实控制器与 Pawn」产生，而不是手写胜负。

const TRIAL_ENCOUNTER_PATH: String = "res://game/world/data/encounters/encounter_trial_puppet.tres"
const IRON_GUARD_ENCOUNTER_PATH: String = "res://game/world/data/encounters/encounter_iron_guard.tres"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"

const APPROX: float = 0.001
const DELTA: float = 1.0 / 60.0
## 终局上限 60 秒，与 gameplay 层同一口径；到点未分胜负即视为未结算，不伪造结果。
const MAX_STEPS: int = 3600


## 会话只依赖一个单位容器：这里造一个与主场景同名的 Pawns，避免本用例依赖 main.tscn。
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


func _load_encounter(path: String) -> EncounterDefinition:
	return load(path) as EncounterDefinition


## 关掉引擎物理帧，改为手工固定步进，保证结算路径可重复。
func _isolate(session: EncounterSession) -> void:
	for pawn: Pawn in [session.get_player_pawn(), session.get_enemy_pawn()]:
		pawn.set_physics_process(false)
		var controller: PawnController = pawn.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


## 用真实控制器与 Pawn 推进到一方死亡；返回结算后的会话状态。
func _run_until_settled(session: EncounterSession) -> int:
	var player: Pawn = session.get_player_pawn()
	var enemy: Pawn = session.get_enemy_pawn()
	var player_controller: PlayerController = player.get_controller() as PlayerController
	var ai_controller: AIController = enemy.get_controller() as AIController
	player_controller.order_attack(enemy)
	for _step: int in MAX_STEPS:
		player_controller.update_controller(DELTA)
		ai_controller.update_controller(DELTA)
		player._physics_process(DELTA)
		enemy._physics_process(DELTA)
		if session.get_state() != EncounterSession.State.RUNNING:
			break
	return session.get_state()


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


func test_begin_spawns_player_and_enemy_from_encounter_definition() -> void:
	var session: EncounterSession = _spawn_session()
	var encounter: EncounterDefinition = _load_encounter(TRIAL_ENCOUNTER_PATH)

	assert_bool(session.begin(encounter)).is_true()

	var container: Node2D = session.resolve_pawns_container()
	assert_int(container.get_child_count()).is_equal(2)
	assert_object(session.get_player_pawn()).is_not_null()
	assert_object(session.get_enemy_pawn()).is_not_null()
	assert_str(String(session.get_player_pawn().name)).is_equal(EncounterSession.PLAYER_NODE_NAME)
	assert_str(String(session.get_enemy_pawn().name)).is_equal(EncounterSession.ENEMY_NODE_NAME)
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_object(session.get_active_encounter()).is_same(encounter)
	# 敌人档案必须真的来自遭遇定义，而不是场景自带的默认数据。
	assert_str(String(session.get_enemy_pawn().data.id)).is_equal(String(encounter.enemy_profile.id))


func test_started_signal_carries_units_and_binds_controllers() -> void:
	var session: EncounterSession = _spawn_session()
	var sightings: Array = []
	session.encounter_started.connect(func(_encounter: EncounterDefinition, player: Pawn, enemy: Pawn) -> void:
		sightings.append([player, enemy])
	)

	assert_bool(session.begin(_load_encounter(TRIAL_ENCOUNTER_PATH))).is_true()

	assert_int(sightings.size()).is_equal(1)
	var player: Pawn = session.get_player_pawn()
	var enemy: Pawn = session.get_enemy_pawn()
	assert_object(sightings[0][0]).is_same(player)
	assert_object(sightings[0][1]).is_same(enemy)
	# 控制器绑定是会话职责：玩家接 PlayerController，敌人接 AIController。
	assert_bool(player.get_controller() is PlayerController).is_true()
	assert_bool(enemy.get_controller() is AIController).is_true()
	assert_object((player.get_controller() as PlayerController).pawn).is_same(player)
	assert_object((enemy.get_controller() as AIController).pawn).is_same(enemy)


func test_begin_swaps_enemy_and_retires_previous_unit() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_load_encounter(TRIAL_ENCOUNTER_PATH))).is_true()
	var old_enemy: Pawn = session.get_enemy_pawn()
	var container: Node2D = session.resolve_pawns_container()

	var iron_guard: EncounterDefinition = _load_encounter(IRON_GUARD_ENCOUNTER_PATH)
	assert_bool(session.begin(iron_guard)).is_true()
	var new_enemy: Pawn = session.get_enemy_pawn()

	assert_object(new_enemy).is_not_same(old_enemy)
	assert_bool(container.get_children().has(old_enemy)).is_false()
	# 退场单位寄存在会话下等待 queue_free：既不占用 Pawns 容器路径，也不会成为脱离场景树的孤儿节点。
	assert_bool(old_enemy.is_queued_for_deletion()).is_true()
	assert_object(old_enemy.get_parent()).is_same(session)
	# 容器里仍然只有当前对局的两个单位，且路径 Pawns/EnemyPawn 指向新敌人。
	assert_int(container.get_child_count()).is_equal(2)
	assert_object(container.get_node(EncounterSession.ENEMY_NODE_NAME)).is_same(new_enemy)
	assert_str(String(new_enemy.data.id)).is_equal(String(iron_guard.enemy_profile.id))
	# 退场单位走 queue_free，补一帧让场景树真正回收，避免残留孤儿节点污染后续用例。
	await await_idle_frame()


func test_player_data_survives_encounter_switch() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_load_encounter(TRIAL_ENCOUNTER_PATH))).is_true()
	var player_before: Pawn = session.get_player_pawn()
	var data_before: PawnData = player_before.data

	assert_bool(session.begin(_load_encounter(IRON_GUARD_ENCOUNTER_PATH))).is_true()

	var player_after: Pawn = session.get_player_pawn()
	assert_object(player_after).is_not_same(player_before)
	# 换敌不是换角色：玩家配置必须原样带过去，否则每次换遭遇都会丢 Build。
	assert_object(player_after.data).is_same(data_before)
	assert_bool(player_after.is_alive()).is_true()
	await await_idle_frame()


func test_finished_signal_is_emitted_once_per_encounter() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_load_encounter(TRIAL_ENCOUNTER_PATH))).is_true()
	var outcomes: Array = []
	session.encounter_finished.connect(func(_encounter: EncounterDefinition, outcome: int) -> void:
		outcomes.append(outcome)
	)
	var enemy: Pawn = session.get_enemy_pawn()

	enemy.take_damage(_lethal_damage(enemy))

	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)
	assert_int(outcomes.size()).is_equal(1)
	assert_int(int(outcomes[0])).is_equal(EncounterSession.State.PLAYER_WIN)
	# 重复的死亡信号不得二次结算。
	enemy.died.emit(enemy)
	assert_int(outcomes.size()).is_equal(1)
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)


func test_player_death_settles_as_enemy_win() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_load_encounter(TRIAL_ENCOUNTER_PATH))).is_true()
	var player: Pawn = session.get_player_pawn()

	player.take_damage(_lethal_damage(player))

	assert_int(session.get_state()).is_equal(EncounterSession.State.ENEMY_WIN)
	assert_bool(session.is_running()).is_false()


func test_expired_match_settles_through_real_controllers() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_load_encounter(TRIAL_ENCOUNTER_PATH))).is_true()
	_isolate(session)

	var outcome: int = _run_until_settled(session)

	# 只要求「真实推进能走到终局，且会话状态与结果一致」，不预设谁赢。
	assert_bool(outcome == EncounterSession.State.PLAYER_WIN or outcome == EncounterSession.State.ENEMY_WIN).is_true()
	assert_int(session.get_state()).is_equal(outcome)


func test_repeated_begin_leaves_no_stale_units() -> void:
	var session: EncounterSession = _spawn_session()
	var encounter: EncounterDefinition = _load_encounter(TRIAL_ENCOUNTER_PATH)
	assert_bool(session.begin(encounter)).is_true()
	assert_bool(session.begin(encounter)).is_true()
	await await_idle_frame()

	var container: Node2D = session.resolve_pawns_container()
	assert_int(container.get_child_count()).is_equal(2)
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_bool(session.get_player_pawn().is_alive()).is_true()
	assert_bool(session.get_enemy_pawn().is_alive()).is_true()


func test_restart_requires_active_encounter() -> void:
	var session: EncounterSession = _spawn_session()

	assert_bool(session.restart()).is_false()
	assert_int(session.get_state()).is_equal(EncounterSession.State.IDLE)


func test_restart_rebuilds_the_same_encounter() -> void:
	var session: EncounterSession = _spawn_session()
	var encounter: EncounterDefinition = _load_encounter(TRIAL_ENCOUNTER_PATH)
	assert_bool(session.begin(encounter)).is_true()
	var enemy_before: Pawn = session.get_enemy_pawn()

	assert_bool(session.restart()).is_true()

	assert_object(session.get_active_encounter()).is_same(encounter)
	assert_object(session.get_enemy_pawn()).is_not_same(enemy_before)
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	await await_idle_frame()


func test_begin_rejects_missing_or_unconfigured_encounter() -> void:
	var session: EncounterSession = _spawn_session()
	var container: Node2D = session.resolve_pawns_container()

	assert_bool(session.begin(null)).is_false()
	assert_bool(session.begin(EncounterDefinition.new())).is_false()

	assert_int(container.get_child_count()).is_zero()
	assert_int(session.get_state()).is_equal(EncounterSession.State.IDLE)
	assert_object(session.get_player_pawn()).is_null()
	assert_object(session.get_enemy_pawn()).is_null()


func test_outcome_labels_cover_every_state() -> void:
	assert_str(EncounterSession.get_outcome_label(EncounterSession.State.IDLE)).is_equal("未开始")
	assert_str(EncounterSession.get_outcome_label(EncounterSession.State.RUNNING)).is_equal("进行中")
	assert_str(EncounterSession.get_outcome_label(EncounterSession.State.PLAYER_WIN)).is_equal("胜利")
	assert_str(EncounterSession.get_outcome_label(EncounterSession.State.ENEMY_WIN)).is_equal("失败")

## INC-WORLD-005：同代修士的运行时 Build 与修为跨对局延续，资源快照语义不变。
func test_runtime_build_and_cultivation_survive_repeated_begin() -> void:
	var session: EncounterSession = _spawn_session()
	var encounter: EncounterDefinition = _load_encounter(TRIAL_ENCOUNTER_PATH)
	assert_bool(session.begin(encounter)).is_true()

	var player: Pawn = session.get_player_pawn()
	var data_before: PawnData = player.data
	var static_technique_count: int = data_before.techniques.size()
	var static_attack: float = data_before.attack
	assert_int(player.strengthen_weapon()).is_equal(1)
	var learned: TechniqueDefinition = TechniqueDefinition.new()
	learned.id = &"encounter_carry_technique"
	learned.display_name = "延续功法"
	assert_bool(player.learn_technique(learned)).is_true()
	assert_float(player.set_cultivation_exp(12.0, &"test_carry")).is_equal_approx(12.0, APPROX)

	assert_bool(session.begin(encounter)).is_true()
	var next_player: Pawn = session.get_player_pawn()

	assert_object(next_player).is_not_same(player)
	# 运行时进度延续：强化等级 / 领悟功法 / 修为跟着同一代修士走。
	assert_int(next_player.get_forge_level()).is_equal(1)
	assert_float(next_player.get_attack_power()).is_equal_approx(
		static_attack + Pawn.FORGE_ATTACK_BONUS_PER_LEVEL, APPROX
	)
	assert_bool(next_player.has_learned_technique(&"encounter_carry_technique")).is_true()
	assert_float(_cultivation_exp(next_player)).is_equal_approx(12.0, APPROX)
	# 静态档案零污染：延续只活在运行时覆盖层。
	assert_object(next_player.data).is_same(data_before)
	assert_int(data_before.techniques.size()).is_equal(static_technique_count)
	assert_float(data_before.attack).is_equal_approx(static_attack, APPROX)
	# 资源快照语义不变：state 为 null 的新一局仍按档案满状态起局。
	assert_float(next_player.current_health).is_equal_approx(data_before.max_health, APPROX)
	assert_float(next_player.current_shield).is_equal_approx(data_before.max_shield, APPROX)
	await await_idle_frame()


## INC-WORLD-005：延续写入按目标单位自身的突破阈值截断，不越过境界上限。
func test_carried_cultivation_is_clamped_by_target_realm() -> void:
	var session: EncounterSession = _spawn_session()
	var encounter: EncounterDefinition = _load_encounter(TRIAL_ENCOUNTER_PATH)
	assert_bool(session.begin(encounter)).is_true()
	var player: Pawn = session.get_player_pawn()
	var required: float = float(player.get_cultivation_snapshot().get("required_exp", 0.0))
	assert_float(required).is_greater(0.0)
	player.set_cultivation_exp(required + 500.0, &"test_clamp")
	assert_float(_cultivation_exp(player)).is_equal_approx(required, APPROX)

	assert_bool(session.restart()).is_true()
	var next_player: Pawn = session.get_player_pawn()

	assert_float(_cultivation_exp(next_player)).is_equal_approx(required, APPROX)
	await await_idle_frame()


func _cultivation_exp(pawn: Pawn) -> float:
	return float(pawn.get_cultivation_snapshot().get("current_exp", 0.0))