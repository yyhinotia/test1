extends GdUnitTestSuite

## 集成层：DungeonRun 房间推进 / 收益结算 / 资源延续契约（INC-WORLD-004）。
##
## 用例在真实的 EncounterSession 上运行：只有「敌人 / 玩家死亡」这一条真实终局路径，
## 不做任何胜负伪造。秘境数据来自 game/world/data/dungeons/ 正式资源，用例不复制奖励数值。

const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const PAWNS_CONTAINER_NAME: String = "Pawns"


func _spawn_run() -> DungeonRun:
	var container: Node2D = Node2D.new()
	container.name = PAWNS_CONTAINER_NAME
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


func _load_dungeon() -> DungeonDefinition:
	return load(DUNGEON_PATH) as DungeonDefinition


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 用真实死亡路径清空当前房间：调用 EncounterSession 的死亡结算，不直接改 DungeonRun 状态。
func _clear_current_room(run: DungeonRun) -> void:
	var enemy: Pawn = run.encounter_session.get_enemy_pawn()
	enemy.take_damage(_lethal_damage(enemy))


func _damage_player(run: DungeonRun, health_loss: float, shield_loss: float, spirit_loss: float) -> void:
	var player: Pawn = run.encounter_session.get_player_pawn()
	player.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID).decrease(health_loss, &"test")
	player.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID).decrease(shield_loss, &"test")
	player.get_resource_pool(Pawn.SPIRIT_RESOURCE_ID).decrease(spirit_loss, &"test")


## 记录三个对外信号的到达顺序与参数；返回共享的数组引用（字典 / 数组在 lambda 中按引用捕获）。
func _record(run: DungeonRun) -> Array:
	var log: Array = []
	run.run_started.connect(func(_dungeon: DungeonDefinition, room_index: int) -> void:
		log.append({"type": "started", "room_index": room_index})
	)
	run.room_cleared.connect(func(_dungeon: DungeonDefinition, room_index: int, reward: int, total: int) -> void:
		log.append({"type": "cleared", "room_index": room_index, "reward": reward, "total": total})
	)
	run.run_finished.connect(func(_dungeon: DungeonDefinition, outcome: int, earned: int) -> void:
		log.append({"type": "finished", "outcome": outcome, "earned": earned})
	)
	return log


func _count(log: Array, event_type: String) -> int:
	var total: int = 0
	for entry: Dictionary in log:
		if entry["type"] == event_type:
			total += 1
	return total


func _first(log: Array, event_type: String) -> Dictionary:
	for entry: Dictionary in log:
		if entry["type"] == event_type:
			return entry
	return {}


func test_start_requires_configured_dungeon_and_begins_first_room_at_full_resources() -> void:
	var run: DungeonRun = _spawn_run()

	assert_bool(run.start(null)).is_false()
	assert_bool(run.start(DungeonDefinition.new())).is_false()
	assert_int(run.get_state()).is_equal(DungeonRun.State.IDLE)

	var dungeon: DungeonDefinition = _load_dungeon()
	assert_bool(run.start(dungeon)).is_true()

	var session: EncounterSession = run.encounter_session
	var player: Pawn = session.get_player_pawn()
	var first_room: DungeonRoom = dungeon.get_room(0)
	assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
	assert_bool(run.is_active()).is_true()
	assert_bool(run.is_finished()).is_false()
	assert_bool(run.is_awaiting_decision()).is_false()
	assert_int(run.get_room_index()).is_zero()
	assert_int(run.get_depth()).is_equal(1)
	assert_int(run.get_room_count()).is_equal(dungeon.get_room_count())
	assert_int(run.get_earned_spirit_stones()).is_zero()
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_str(String(session.get_enemy_pawn().data.id)).is_equal(
		String(first_room.encounter.enemy_profile.id)
	)
	# 第一间必须满状态：跨房间延续不影响开局。
	assert_float(player.current_health).is_equal(player.data.max_health)
	assert_float(player.current_shield).is_equal(player.data.max_shield)
	assert_float(player.current_spirit).is_equal(player.max_spirit)


func test_clearing_non_boss_room_accumulates_reward_and_awaits_decision() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_dungeon()
	var events: Array = _record(run)
	assert_bool(run.start(dungeon)).is_true()
	var first_reward: int = dungeon.get_room_reward(0)

	_clear_current_room(run)

	assert_int(run.get_state()).is_equal(DungeonRun.State.AWAITING_DECISION)
	assert_bool(run.is_awaiting_decision()).is_true()
	assert_bool(run.is_active()).is_true()
	assert_int(run.get_room_index()).is_zero()
	assert_int(run.get_depth()).is_equal(1)
	assert_int(run.get_earned_spirit_stones()).is_equal(first_reward)
	assert_int(_count(events, "cleared")).is_equal(1)
	var cleared: Dictionary = _first(events, "cleared")
	assert_int(cleared["room_index"]).is_zero()
	assert_int(cleared["reward"]).is_equal(first_reward)
	assert_int(cleared["total"]).is_equal(first_reward)


func test_advance_carries_damaged_resources_into_next_room() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_dungeon()
	assert_bool(run.start(dungeon)).is_true()

	var old_player: Pawn = run.encounter_session.get_player_pawn()
	_damage_player(run, 30.0, 40.0, 25.0)
	var carried_health: float = old_player.current_health
	var carried_shield: float = old_player.current_shield
	var carried_spirit: float = old_player.current_spirit
	assert_float(carried_health).is_less(old_player.data.max_health)
	assert_float(carried_spirit).is_less(old_player.max_spirit)

	_clear_current_room(run)
	assert_bool(run.advance()).is_true()

	var session: EncounterSession = run.encounter_session
	var new_player: Pawn = session.get_player_pawn()
	var second_room: DungeonRoom = dungeon.get_room(1)
	assert_object(new_player).is_not_same(old_player)
	assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
	assert_int(run.get_room_index()).is_equal(1)
	assert_int(run.get_depth()).is_equal(2)
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
	assert_str(String(session.get_enemy_pawn().data.id)).is_equal(
		String(second_room.encounter.enemy_profile.id)
	)
	# 风险真的累积：下一间沿用上一间剩下的生命 / 护盾 / 灵力，而不是满状态重置。
	assert_float(new_player.current_health).is_equal(carried_health)
	assert_float(new_player.current_shield).is_equal(carried_shield)
	assert_float(new_player.current_spirit).is_equal(carried_spirit)
	assert_float(new_player.current_health).is_less(new_player.data.max_health)
	assert_float(new_player.current_spirit).is_less(new_player.max_spirit)


func test_boss_clear_finishes_with_all_rewards_preserved() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_dungeon()
	var events: Array = _record(run)
	assert_bool(run.start(dungeon)).is_true()

	for index: int in dungeon.get_room_count():
		_clear_current_room(run)
		if index < dungeon.get_room_count() - 1:
			assert_int(run.get_state()).is_equal(DungeonRun.State.AWAITING_DECISION)
			assert_bool(run.advance()).is_true()

	assert_int(run.get_state()).is_equal(DungeonRun.State.CLEARED)
	assert_bool(run.is_finished()).is_true()
	assert_bool(run.is_active()).is_false()
	assert_int(run.get_earned_spirit_stones()).is_equal(dungeon.get_max_reward())
	assert_int(_count(events, "finished")).is_equal(1)
	var finished: Dictionary = _first(events, "finished")
	assert_int(finished["outcome"]).is_equal(DungeonRun.State.CLEARED)
	assert_int(finished["earned"]).is_equal(dungeon.get_max_reward())
	# 终局之后不得再推进或撤退。
	assert_bool(run.advance()).is_false()
	assert_bool(run.retreat()).is_false()
	assert_int(run.get_state()).is_equal(DungeonRun.State.CLEARED)


func test_defeat_zeroes_accumulated_rewards() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_dungeon()
	var events: Array = _record(run)
	assert_bool(run.start(dungeon)).is_true()

	_clear_current_room(run)
	var accumulated: int = run.get_earned_spirit_stones()
	assert_int(accumulated).is_greater(0)
	assert_bool(run.advance()).is_true()

	var player: Pawn = run.encounter_session.get_player_pawn()
	player.take_damage(_lethal_damage(player))

	assert_int(run.get_state()).is_equal(DungeonRun.State.DEFEATED)
	assert_bool(run.is_finished()).is_true()
	assert_int(run.get_earned_spirit_stones()).is_zero()
	assert_int(_count(events, "finished")).is_equal(1)
	var finished: Dictionary = _first(events, "finished")
	assert_int(finished["outcome"]).is_equal(DungeonRun.State.DEFEATED)
	assert_int(finished["earned"]).is_zero()


func test_retreat_preserves_rewards_and_starts_no_new_encounter() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_dungeon()
	var events: Array = _record(run)
	assert_bool(run.start(dungeon)).is_true()
	_clear_current_room(run)
	var accumulated: int = run.get_earned_spirit_stones()
	assert_int(accumulated).is_equal(dungeon.get_room_reward(0))

	var session: EncounterSession = run.encounter_session
	var current_encounter: EncounterDefinition = session.get_active_encounter()
	var current_player_id: int = session.get_player_pawn().get_instance_id()
	assert_bool(run.retreat()).is_true()

	assert_int(run.get_state()).is_equal(DungeonRun.State.RETREATED)
	assert_int(run.get_earned_spirit_stones()).is_equal(accumulated)
	assert_int(_count(events, "finished")).is_equal(1)
	# 撤退不创建新对局：当前会话与玩家单位保持不变。
	assert_object(session.get_active_encounter()).is_same(current_encounter)
	assert_int(session.get_player_pawn().get_instance_id()).is_equal(current_player_id)
	assert_bool(run.advance()).is_false()
	assert_bool(run.retreat()).is_false()
	assert_int(run.get_state()).is_equal(DungeonRun.State.RETREATED)


func test_illegal_transitions_do_not_change_state() -> void:
	var run: DungeonRun = _spawn_run()
	var events: Array = _record(run)
	assert_int(run.get_state()).is_equal(DungeonRun.State.IDLE)
	assert_bool(run.advance()).is_false()
	assert_bool(run.retreat()).is_false()
	assert_int(run.get_state()).is_equal(DungeonRun.State.IDLE)
	assert_int(_count(events, "finished")).is_zero()

	var dungeon: DungeonDefinition = _load_dungeon()
	assert_bool(run.start(dungeon)).is_true()
	var player_id: int = run.encounter_session.get_player_pawn().get_instance_id()
	# RUNNING 状态不能直接推进或撤退：必须先清空当前房间。
	assert_bool(run.advance()).is_false()
	assert_bool(run.retreat()).is_false()
	assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
	assert_int(run.encounter_session.get_player_pawn().get_instance_id()).is_equal(player_id)
	assert_int(run.get_earned_spirit_stones()).is_zero()


func test_duplicate_settlement_does_not_double_count() -> void:
	var run: DungeonRun = _spawn_run()
	var dungeon: DungeonDefinition = _load_dungeon()
	var events: Array = _record(run)
	assert_bool(run.start(dungeon)).is_true()

	_clear_current_room(run)
	var total_after_clear: int = run.get_earned_spirit_stones()
	# 迟到的重复死亡 / 终局信号不得二次结算。
	var enemy: Pawn = run.encounter_session.get_enemy_pawn()
	enemy.died.emit(enemy)
	run.encounter_session.encounter_finished.emit(
		run.encounter_session.get_active_encounter(), EncounterSession.State.PLAYER_WIN
	)

	assert_int(run.get_earned_spirit_stones()).is_equal(total_after_clear)
	assert_int(_count(events, "cleared")).is_equal(1)
	assert_int(run.get_state()).is_equal(DungeonRun.State.AWAITING_DECISION)


func test_resource_snapshot_degrades_safely() -> void:
	var empty: PawnResourceSnapshot = PawnResourceSnapshot.capture(null)
	assert_bool(empty.is_empty()).is_true()
	assert_int(empty.get_value_count()).is_zero()
	assert_float(empty.get_value(&"health", -1.0)).is_equal(-1.0)
	empty.apply_to(null)

	var run: DungeonRun = _spawn_run()
	assert_bool(run.start(_load_dungeon())).is_true()
	var player: Pawn = run.encounter_session.get_player_pawn()
	var snapshot: PawnResourceSnapshot = PawnResourceSnapshot.capture(player)
	assert_bool(snapshot.is_empty()).is_false()
	assert_int(snapshot.get_value_count()).is_equal(player.get_resource_ids().size())
	assert_float(snapshot.get_value(HealthComponent.HEALTH_RESOURCE_ID)).is_equal(player.current_health)
	assert_float(snapshot.get_value(Pawn.SPIRIT_RESOURCE_ID)).is_equal(player.current_spirit)
	snapshot.apply_to(null)
