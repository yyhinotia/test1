class_name BuildReplayDriver
extends RefCounted

## Build Replay 实验驱动器（INC-TESTING-011）。
##
## 职责边界：只驱动真实 `main.tscn` 并把观察到的事实读出来，不产生任何玩法结论。
## 流程：关掉默认秘境 → 让正式 1v1 遭遇开局 → 按固定 60fps 时间步推进危险窗口 →
## 通过生产面板按钮切换 Build → 同一遭遇再战。
## 本文件不复制伤害 / 奖励 / 眩晕 / 容量规则，数值与事件一律从公开 API 与 CombatEventLog 读取；
## 「玩家是否愿意重构 Build」这类判断只能由人工给出，驱动器不得代答。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const REPLAY_ENCOUNTER_PATH: String = "res://game/world/data/encounters/build_test_1v1.tres"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"

const SESSION_PATH: String = "EncounterSession"
const DUNGEON_RUN_PATH: String = "DungeonRun"
const BUILD_PANEL_PATH: String = "HUD/BuildLoadoutPanel"
const SKILL_BAR_PATH: String = "HUD/BottomLeftDock/SkillBar"

const DELTA: float = 1.0 / 60.0
## 危险窗口在 8.0s 打开、2.0s 后结算；多推进 0.1s 避免落在帧边界上（与既有集成用例同口径）。
const DANGER_WINDOW_AT: float = 8.1
const DANGER_RESOLVE_AFTER: float = 2.1
## 定身施放后推进一小段时间，让调度器把危险窗口判为取消（取消事件由调度器发出）。
const STUN_SETTLE: float = 0.1
## 走位上限（物理帧数）：两轮都必须先把玩家走到技能可施放的距离，否则 Round 2 的定身会被射程拒绝。
## 直接传送单位会伪造对照条件，因此这里驱动真实 PlayerController 走过去（跨物理帧驱动，
## 因为 `move_and_slide()` 的位移由引擎物理步给出，同一帧内手工连调不会累积出真实速度）。
const APPROACH_MAX_FRAMES: int = 300
## 走到施法距离的这个比例内即可，避免正好卡在边界上。
const CAST_RANGE_RATIO: float = 0.8
const APPROX: float = 0.001

const ROUND_1_LABEL: String = "round_1_build_a"
const ROUND_2_LABEL: String = "round_2_build_b"


## 实例化正式主场景并关掉默认秘境。调用方负责释放（GdUnit4 用 auto_free，SceneTree 脚本用 free）。
## 顺序必须在入树前关掉：`DungeonRun._ready()` 会按 `default_dungeon` 起局，入树后再关就晚了。
## 与 `tests/scenario_entry.gd` 的处理一致，正式入口的默认行为不受影响。
static func instantiate_main_without_dungeon(parent: Node) -> Node2D:
	var scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	var main: Node2D = scene.instantiate() as Node2D
	close_default_dungeon(main)
	parent.add_child(main)
	return main


## 关掉开机默认秘境：Replay 实验只跑一个确定的 1v1 遭遇，避免房间链改变对照条件。
## 这属于测试 / 取证专用摆放，正式入口的默认行为不变。
static func close_default_dungeon(main: Node2D) -> void:
	var dungeon_run: DungeonRun = main.get_node_or_null(DUNGEON_RUN_PATH) as DungeonRun
	if dungeon_run != null:
		dungeon_run.default_dungeon = null


static func get_session(main: Node2D) -> EncounterSession:
	return main.get_node(SESSION_PATH) as EncounterSession


static func get_build_panel(main: Node2D) -> BuildLoadoutPanel:
	return main.get_node(BUILD_PANEL_PATH) as BuildLoadoutPanel


static func get_skill_bar(main: Node2D) -> SkillBar:
	return main.get_node(SKILL_BAR_PATH) as SkillBar


static func load_replay_encounter() -> EncounterDefinition:
	return load(REPLAY_ENCOUNTER_PATH) as EncounterDefinition


## 关掉引擎物理帧，改为手工固定步进：危险窗口与事件时间戳才可重复。
static func isolate(session: EncounterSession) -> void:
	session.set_physics_process(false)
	for unit: Pawn in session.get_player_units() + session.get_enemy_units():
		unit.set_physics_process(false)
		var controller: PawnController = unit.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


## 按固定步长推进会话（危险窗口与事件时钟都挂在会话的 `_physics_process` 上）。
static func advance(session: EncounterSession, seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.0:
		var step: float = minf(DELTA, remaining)
		session._physics_process(step)
		remaining -= step



## 复用主场景既有的选中路由：信息卡 / 技能栏 / Build 面板都以选中单位为展示对象。
static func select_player(main: Node2D) -> void:
	var session: EncounterSession = get_session(main)
	if session != null:
		main.call("_set_selected_pawn", session.get_player_pawn())


## Round 1：Build A 打同一个 1v1 遭遇，危险窗口不做任何干预。
static func run_round_a(main: Node2D, encounter: EncounterDefinition) -> Dictionary:
	return await _run_round(main, encounter, ROUND_1_LABEL, false)


## Round 2：当前 Build（预期是 Build B）再打同一个遭遇，危险窗口用定身打断。
static func run_round_b(main: Node2D, encounter: EncounterDefinition) -> Dictionary:
	return await _run_round(main, encounter, ROUND_2_LABEL, true)


## 完整跑一次脚本化 Replay：Round 1 → 首通解锁 → 主动切换 Build B → Round 2。
## 返回的记录只含机制事实；人工三问原话与 Gate A~E 结论必须由玩家填写（见 capture_build_replay_record.gd）。
static func run_scripted_replay(main: Node2D) -> Dictionary:
	var session: EncounterSession = get_session(main)
	var encounter: EncounterDefinition = load_replay_encounter()
	close_default_dungeon(main)
	select_player(main)

	var record: Dictionary = {"encounter": String(encounter.id) if encounter != null else "<none>"}
	var round_one: Dictionary = await run_round_a(main, encounter)
	record[ROUND_1_LABEL] = round_one

	# 首通：走真实死亡路径（敌方全灭才判胜），奖励由 EncounterSession 结算。
	var player: Pawn = session.get_player_pawn()
	var known_before: Array[String] = skill_ids(player.get_known_active_skills())
	var equipped_before: Array[String] = skill_ids(player.get_equipped_active_skills())
	var outcome: int = defeat_all_enemies(session)
	record["first_clear"] = {
		"outcome": outcome,
		"outcome_label": EncounterSession.get_outcome_label(outcome),
		"known_before": known_before,
		"known_after": skill_ids(player.get_known_active_skills()),
		"equipped_before": equipped_before,
		"equipped_after_first_clear": skill_ids(player.get_equipped_active_skills()),
		"auto_equipped_by_reward": equipped_before != skill_ids(player.get_equipped_active_skills()),
	}

	# 主动重构：只通过生产面板按钮切换，驱动器不替玩家决定。
	record["build_switch"] = switch_to_build_b(main)
	record["skill_bar_after_switch"] = _skill_bar_ids(main)

	var round_two: Dictionary = await run_round_b(main, encounter)
	record[ROUND_2_LABEL] = round_two
	record["objective_comparison"] = _compare_rounds(round_one, round_two)
	return record


## 「用定身解决第一轮的问题」这件事只由事件序列与结算结果证明，不看自述。
static func _compare_rounds(round_one: Dictionary, round_two: Dictionary) -> Dictionary:
	var first_resolution: String = String(round_one.get("dangerous_skill_resolution", "unresolved"))
	var second_resolution: String = String(round_two.get("dangerous_skill_resolution", "unresolved"))
	var first_sequence: Array = round_one.get("danger_window_sequence", [])
	var second_sequence: Array = round_two.get("danger_window_sequence", [])
	var same_sequence: bool = first_sequence == second_sequence
	return {
		"round_1_resolution": first_resolution,
		"round_2_resolution": second_resolution,
		"round_1_window_sequence": first_sequence,
		"round_2_window_sequence": second_sequence,
		"same_window_sequence": same_sequence,
		# Failure 4 的客观判据：两轮应对序列相同（Round 2 没有出现 skill_cancelled）。
		"failure_4_triggered": same_sequence or second_resolution != "cancelled_by_stun",
	}


## 敌方全灭才判胜：逐单位走真实 `take_damage()`，不直接改会话状态。
static func defeat_all_enemies(session: EncounterSession) -> int:
	for enemy: Pawn in session.get_enemy_units():
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive():
			enemy.take_damage(_lethal_damage(enemy))
	return session.get_state()


## 唯一切换入口：按下生产面板的 Build B 按钮，并回报面板自己的裁决结果。
static func switch_to_build_b(main: Node2D) -> Dictionary:
	var panel: BuildLoadoutPanel = get_build_panel(main)
	var result: Dictionary = {"switch_locked_before": false, "attempts": [], "accepted": false, "reason": ""}
	if panel == null:
		result["reason"] = "panel_missing"
		return result
	result["switch_locked_before"] = panel.is_switch_locked()
	result["available_before"] = panel.is_preset_available(BuildLoadoutPanel.PRESET_B_ID)
	var attempts: Array[Dictionary] = []
	panel.build_switch_attempted.connect(
		func(_pawn: Pawn, preset_id: StringName, success: bool, reason: String) -> void:
			attempts.append({"preset_id": String(preset_id), "success": success, "reason": reason})
	)
	var button: Button = panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID)
	if button == null:
		result["reason"] = "button_missing"
		return result
	button.pressed.emit()
	result["attempts"] = attempts
	result["accepted"] = panel.get_active_preset_id() == BuildLoadoutPanel.PRESET_B_ID
	result["reason"] = panel.get_last_reason()
	result["switch_locked_after"] = panel.is_switch_locked()
	var player: Pawn = get_session(main).get_player_pawn()
	result["equipped_after"] = skill_ids(player.get_equipped_active_skills()) if player != null else []
	return result


static func _run_round(
		main: Node2D,
		encounter: EncounterDefinition,
		label: String,
		use_binding: bool
	) -> Dictionary:
	var session: EncounterSession = get_session(main)
	var record: Dictionary = {"label": label, "ok": false}
	if encounter == null:
		record["reason"] = "encounter_missing"
		return record
	# 每局 `begin()` 都会重置事件日志与危险窗口调度器，这是「不跨局污染」的机制前提。
	if not session.begin(encounter):
		record["reason"] = "begin_failed"
		return record
	isolate(session)

	var player: Pawn = session.get_player_pawn()
	var enemy: Pawn = session.get_enemy_pawn()
	var log: CombatEventLog = session.get_combat_event_log()
	# 两轮使用同一套走位编排：玩家用真实控制器走到技能可施放的距离后停手。
	# 走位期间**不推进会话**，否则危险窗口会在走位过程中提前打开，两轮对照就失去同一个时间原点。
	var approach_steps: int = await approach_target(session, player, enemy, APPROACH_MAX_FRAMES)
	var health_before: float = player.current_health
	var shield_before: float = player.current_shield
	# 时间原点：走位结束后从 0 计时，危险窗口固定在第 8.1 秒打开。
	advance(session, DANGER_WINDOW_AT)
	var opened: bool = log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED)
	var binding_cast: bool = false
	var stunned_after_cast: bool = false
	if use_binding:
		binding_cast = _cast_binding(player, session.get_enemy_pawn())
		stunned_after_cast = session.get_enemy_pawn().is_stunned()
		advance(session, STUN_SETTLE)
	# 继续推进到原结算时刻之外：若定身没有真正取消技能，这一段就会补上 `skill_hit`。
	advance(session, DANGER_RESOLVE_AFTER)

	record["ok"] = true
	record["danger_window_opened"] = opened
	record["binding_cast"] = binding_cast
	record["approach_frames"] = approach_steps
	record["player_to_enemy_distance"] = player.global_position.distance_to(enemy.global_position)
	record["enemy_stunned_after_cast"] = stunned_after_cast
	record["dangerous_skill_resolution"] = _dangerous_skill_resolution(log)
	record["danger_window_sequence"] = _danger_window_sequence(log)
	record["event_sequence"] = _strings(log.get_event_types())
	record["damage_taken"] = {
		"health": health_before - player.current_health,
		"shield": shield_before - player.current_shield,
	}
	record["duration_seconds"] = log.get_clock()
	record["known_active_skills"] = skill_ids(player.get_known_active_skills())
	record["equipped_active_skills"] = skill_ids(player.get_equipped_active_skills())
	record["skill_bar"] = _skill_bar_ids(main)
	return record


## 危险窗口的结算结果：三选一 + unresolved，「该次伤害是否结算」由这里给出唯一口径。
static func _dangerous_skill_resolution(log: CombatEventLog) -> String:
	if log.has_event_type(CombatEvent.SKILL_CANCELLED):
		return "cancelled_by_stun"
	if log.has_event_type(CombatEvent.SKILL_BLOCKED):
		return "blocked"
	if log.has_event_type(CombatEvent.SKILL_HIT):
		return "hit"
	return "unresolved"


## 危险窗口应对序列：从 `danger_window_opened` 起的事件类型，两轮对照只比这一段。
static func _danger_window_sequence(log: CombatEventLog) -> Array:
	var types: Array[StringName] = log.get_event_types()
	var start: int = log.get_index_of_event_type(CombatEvent.DANGER_WINDOW_OPENED)
	if start < 0:
		return []
	var sequence: Array = []
	for index: int in range(start, types.size()):
		sequence.append(String(types[index]))
	return sequence


static func _cast_binding(player: Pawn, enemy: Pawn) -> bool:
	if player == null or enemy == null or not is_instance_valid(enemy):
		return false
	var binding: ActiveSkillDefinition = load(BINDING_SKILL_PATH) as ActiveSkillDefinition
	return player.cast_skill(binding, enemy)


static func _strings(values: Array[StringName]) -> Array:
	var result: Array = []
	for value: StringName in values:
		result.append(String(value))
	return result


## 技能栏当前槽位内容：切换装配是否真的反映到 UI，由这里给出事实。
static func _skill_bar_ids(main: Node2D) -> Array:
	var bar: SkillBar = get_skill_bar(main)
	var ids: Array = []
	if bar == null:
		return ids
	for slot: SkillSlot in bar.get_slots():
		if slot != null and slot.has_skill():
			var skill: ActiveSkillDefinition = slot.get_skill()
			ids.append(String(skill.id) if skill != null else "<null>")
	return ids


static func skill_ids(skills: Array[ActiveSkillDefinition]) -> Array[String]:
	var ids: Array[String] = []
	for skill: ActiveSkillDefinition in skills:
		ids.append(String(skill.id) if skill != null else "<null>")
	return ids


static func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 用真实 PlayerController 走到技能可施放的距离内（两轮同一套编排），返回消耗的物理帧数。
## 走位期间不推进会话（会话物理仍然禁用），因此危险窗口的时间原点留在走位结束之后。
static func approach_target(
		session: EncounterSession,
		player: Pawn,
		 enemy: Pawn,
		max_frames: int
	) -> int:
	if player == null or enemy == null or not is_instance_valid(enemy):
		return 0
	var controller: PlayerController = player.get_controller() as PlayerController
	if controller == null:
		return 0
	controller.order_attack(enemy)
	# 只为走位恢复这两个节点的物理帧；会话与敌人 AI 保持关闭，避免走位期间出现额外事件。
	controller.set_physics_process(true)
	player.set_physics_process(true)
	var frames: int = 0
	var tree: SceneTree = player.get_tree()
	while frames < max_frames and tree != null and session.get_state() == EncounterSession.State.RUNNING:
		if _within_cast_range(player, enemy):
			break
		await tree.physics_frame
		frames += 1
	controller.set_physics_process(false)
	player.set_physics_process(false)
	# 停下就不再出招：两轮的可比条件是「站位与时机相同」，不是输出相同。
	player.stop_moving()
	return frames


## 是否已进入主动技能的施放距离（以定身术的 cast_range 为基准，留 20% 余量）。
static func _within_cast_range(player: Pawn, enemy: Pawn) -> bool:
	var binding: ActiveSkillDefinition = load(BINDING_SKILL_PATH) as ActiveSkillDefinition
	if binding == null or binding.cast_range <= 0.0:
		return true
	return player.global_position.distance_to(enemy.global_position) <= binding.cast_range * CAST_RANGE_RATIO
