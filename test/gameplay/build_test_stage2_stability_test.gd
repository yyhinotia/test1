extends GdUnitTestSuite

## 玩法层：Stage 2（1v1 / 1v2 / 1v3）运行时终局收敛与重开清洁证据（INC-TESTING-013）。
##
## 回答的问题（INC-CROSS-019 §27「技术」退出条件）：
##   1v1 / 1v2 / 1v3 能否稳定运行？同一遭遇能否重复挑战？
##
## 做法：用正式 `EncounterSession` 与真实 `Pawn` / `PlayerController` / `AIController`，
## 在固定 60fps 时间步下把三份 Build 验证遭遇跑到终局（`PLAYER_WIN` / `ENEMY_WIN`），
## 并在终局后重开同一遭遇核对清洁度。本用例不复制任何伤害 / 护盾 / 眩晕 / 胜负公式，
## 也不判断平衡与「好不好玩」——那属于 `INC-TESTING-011` 的人工轮。

const ENCOUNTER_1V1_PATH: String = "res://game/world/data/encounters/build_test_1v1.tres"
const ENCOUNTER_1V2_PATH: String = "res://game/world/data/encounters/build_test_1v2.tres"
const ENCOUNTER_1V3_PATH: String = "res://game/world/data/encounters/build_test_1v3.tres"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"

## Stage 2 阵容口径：1v1 单人、1v2 两人、1v3 三人（INC-WORLD-007）。
const STAGE_2_ENCOUNTERS: Array[Dictionary] = [
	{"label": "1v1", "path": ENCOUNTER_1V1_PATH, "enemies": 1},
	{"label": "1v2", "path": ENCOUNTER_1V2_PATH, "enemies": 2},
	{"label": "1v3", "path": ENCOUNTER_1V3_PATH, "enemies": 3},
]

const DELTA: float = 1.0 / 60.0
## 终局上限 60 秒，与既有集成 / 玩法层同一口径；到点未分胜负即判失败，不用截断结果冒充胜负。
const MAX_STEPS: int = 3600
const APPROX: float = 0.001


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


## 关掉引擎物理帧，改为手工固定步进：终局时刻与事件时钟才可重复。
func _isolate(session: EncounterSession) -> void:
	session.set_physics_process(false)
	for unit: Pawn in session.get_player_units() + session.get_enemy_units():
		unit.set_physics_process(false)
		var controller: PawnController = unit.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


## 把一局跑到终局：玩家通过真实控制器下攻击命令，主目标死亡后改打下一个存活敌人。
## 返回实际观察到的过程事实（步数 / 秒数 / 换目标次数 / 剩余敌人），不返回任何结论。
func _run_to_terminal(session: EncounterSession) -> Dictionary:
	var player: Pawn = session.get_player_pawn()
	var player_controller: PlayerController = player.get_controller() as PlayerController
	var enemies: Array[Pawn] = session.get_enemy_units()
	var current_target: Pawn = null
	var retargets: int = 0
	var steps: int = 0
	while steps < MAX_STEPS and session.get_state() == EncounterSession.State.RUNNING:
		steps += 1
		# 1vN 的「先杀谁」入口：只通过生产控制器下令，目标死亡后重新下令到下一个存活敌人。
		var target: Pawn = _first_alive(enemies)
		if target == null:
			break
		if target != current_target:
			player_controller.order_attack(target)
			current_target = target
			retargets += 1
		player_controller.update_controller(DELTA)
		for enemy: Pawn in enemies:
			var ai: AIController = _alive_controller(enemy)
			if ai != null:
				ai.update_controller(DELTA)
		# 事件时钟与危险窗口挂在会话自己的物理帧上，手工步进也必须推进它。
		session._physics_process(DELTA)
		player._physics_process(DELTA)
		for enemy: Pawn in enemies:
			if _is_alive(enemy):
				enemy._physics_process(DELTA)
	return {
		"state": session.get_state(),
		"steps": steps,
		"seconds": steps * DELTA,
		"retargets": retargets,
		"enemies_alive": _alive_count(enemies),
	}


func _is_alive(pawn: Pawn) -> bool:
	return pawn != null and is_instance_valid(pawn) and pawn.is_alive()


func _first_alive(units: Array[Pawn]) -> Pawn:
	for unit: Pawn in units:
		if _is_alive(unit):
			return unit
	return null


func _alive_count(units: Array[Pawn]) -> int:
	var count: int = 0
	for unit: Pawn in units:
		if _is_alive(unit):
			count += 1
	return count


func _alive_controller(pawn: Pawn) -> AIController:
	if not _is_alive(pawn):
		return null
	return pawn.get_controller() as AIController


## 过程事实只打印，不参与断言；断言只看「是否收敛到终局」与「终局语义是否正确」。
func _report(prefix: String, label: String, facts: Dictionary) -> void:
	print("%s %s state=%s seconds=%.2f retargets=%d enemies_alive=%d" % [
		prefix,
		label,
		EncounterSession.get_outcome_label(int(facts["state"])),
		float(facts["seconds"]),
		int(facts["retargets"]),
		int(facts["enemies_alive"]),
	])


func _load_encounter(path: String) -> EncounterDefinition:
	return load(path) as EncounterDefinition


## §27 技术：1v1 / 1v2 / 1v3 都必须在真实运行时跑到终局，不得停在「进行中」。
func test_stage_2_encounters_run_to_a_terminal_state() -> void:
	for stage_case: Dictionary in STAGE_2_ENCOUNTERS:
		var label: String = String(stage_case["label"])
		var expected_enemies: int = int(stage_case["enemies"])
		var session: EncounterSession = _spawn_session()
		var encounter: EncounterDefinition = _load_encounter(String(stage_case["path"]))
		assert_object(encounter).is_not_null()
		assert_bool(session.begin(encounter)).is_true()
		# 阵容口径先核对，再谈稳定性：Stage 2 的玩家侧只有 1 个单位。
		assert_int(session.get_player_unit_count()).is_equal(1)
		assert_int(session.get_enemy_unit_count()).is_equal(expected_enemies)
		assert_int(session.resolve_pawns_container().get_child_count()).is_equal(expected_enemies + 1)

		_isolate(session)
		var facts: Dictionary = _run_to_terminal(session)
		_report("STAGE2_TERMINAL", label, facts)
		# 停在 RUNNING 说明 60 秒内没分出结果：这是稳定性缺陷，不是可接受的中间态。
		assert_bool(facts["state"] != EncounterSession.State.RUNNING).is_true()
		assert_bool(
			facts["state"] == EncounterSession.State.PLAYER_WIN
				or facts["state"] == EncounterSession.State.ENEMY_WIN
		).is_true()
		# 胜 = 敌方全灭（1vN 不得因主目标单独死亡提前判胜）；负 = 玩家单位死亡。
		if facts["state"] == EncounterSession.State.PLAYER_WIN:
			assert_int(int(facts["enemies_alive"])).is_zero()
		else:
			assert_bool(session.get_player_pawn().is_alive()).is_false()
		# 终局必须写进 CombatEvent：战斗事件记录在 1vN 下同样成立。
		assert_bool(session.get_combat_event_log().has_event_type(CombatEvent.COMBAT_END)).is_true()
		assert_bool(session.get_combat_event_log().has_event_type(CombatEvent.UNIT_DIED)).is_true()
		await await_idle_frame()


## §27 技术：同一遭遇可以重复挑战——重开清瞬时状态与残留单位，并能第二次跑到终局。
func test_stage_2_encounters_survive_a_restart() -> void:
	for stage_case: Dictionary in STAGE_2_ENCOUNTERS:
		var label: String = String(stage_case["label"])
		var expected_enemies: int = int(stage_case["enemies"])
		var session: EncounterSession = _spawn_session()
		assert_bool(session.begin(_load_encounter(String(stage_case["path"])))).is_true()
		_isolate(session)
		var container: Node2D = session.resolve_pawns_container()
		var old_player: Pawn = session.get_player_pawn()
		var old_enemies: Array[Pawn] = session.get_enemy_units()
		_run_to_terminal(session)

		assert_bool(session.restart()).is_true()
		_isolate(session)
		assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)
		assert_int(session.get_player_unit_count()).is_equal(1)
		assert_int(session.get_enemy_unit_count()).is_equal(expected_enemies)
		assert_int(container.get_child_count()).is_equal(expected_enemies + 1)
		# 瞬时状态不残留：新单位满血、未处于定身、事件记录为空。
		var restarted: Pawn = session.get_player_pawn()
		assert_object(restarted).is_not_same(old_player)
		assert_float(restarted.current_health).is_equal_approx(restarted.data.max_health, APPROX)
		assert_bool(restarted.is_stunned()).is_false()
		assert_int(session.get_combat_event_log().get_event_count()).is_zero()
		for unit: Pawn in old_enemies:
			assert_bool(container.get_children().has(unit)).is_false()

		# 重开后再打一局：同一遭遇必须能第二次跑到终局。
		var facts: Dictionary = _run_to_terminal(session)
		_report("STAGE2_RESTART", label, facts)
		assert_bool(facts["state"] != EncounterSession.State.RUNNING).is_true()
		await await_idle_frame()
