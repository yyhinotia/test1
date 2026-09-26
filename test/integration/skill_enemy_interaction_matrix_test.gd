extends GdUnitTestSuite

## 集成层：Skill x Enemy 交互矩阵（INC-TESTING-019）。
##
## 待回答的问题：技能池变大之后，「不同敌人让不同技能的价值发生变化」是否有客观证据。
## 做法：同一初始状态（同一玩家档案、同一敌人、同一起手位置）下，只替换 Build 里的一个技能，
## 用固定 1/60 时间步手工驱动真实控制器与 Pawn，记录终局、耗时、剩余有效生命、灵力消耗与机制事件。
## 本文件不复制伤害、护盾、控制、召唤与 AOE 公式：数值与事件全部来自正式 `EncounterSession`、
## `Pawn`、`SkillEffectResolver` 与 `CombatEventLog`；「玩家是否愿意重构 Build」只能由人工回答。
##
## 口径与噪声（实测记录）：
## - 固定步进 + 固定策略没有随机源：同一进程内同一配置重复运行逐位相同（噪声 0.000s / 0.000 点）。
## - 跨进程重跑会整体滑动（原因见 `test/README.md` 的已知陷阱：手工步进下 `move_and_slide()` 的位移
##   由引擎物理步给出）。因此本用例只断言方向与相对阈值，不把绝对值写成契约；跨进程抖动区间
##   记录在 `agent-plan/testing.md` 的测试证据里。
##
## 唯一的人为策略假设（对所有 Build 一视同仁）：
## - 触发式技能只在触发时出手：控制技能留给危险窗口，吸血留到受伤；
## - 因此这两类技能各自留一份灵力，避免「该用的时候没灵可交」。
##   策略若不这么做，控制与吸血就会在满血 / 无窗口时被提前交掉，价值差异也就无从观察。
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"

const SWORD_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BINDING_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"
const DASH_PATH: String = "res://game/pawns/data/skills/player_dash_skill.tres"
const AOE_PATH: String = "res://game/pawns/data/skills/player_sword_aoe_skill.tres"
const LIFESTEAL_PATH: String = "res://game/pawns/data/skills/player_lifesteal_skill.tres"
const REJUVENATION_PATH: String = "res://game/pawns/data/skills/player_rejuvenation_skill.tres"
const BREAKING_SLASH_PATH: String = "res://game/pawns/data/skills/player_breaking_slash.tres"

const ROOM_MELEE_PATH: String = "res://game/world/data/encounters/problem_room_01_melee.tres"
const ROOM_RANGED_PATH: String = "res://game/world/data/encounters/problem_room_02_ranged.tres"
const ROOM_CHARGE_PATH: String = "res://game/world/data/encounters/problem_room_03_charge.tres"
const ROOM_SUMMON_PATH: String = "res://game/world/data/encounters/problem_room_04_summon.tres"
const ROOM_IRON_PATH: String = "res://game/world/data/encounters/problem_room_05_iron.tres"
const ROOM_BURST_PATH: String = "res://game/world/data/encounters/problem_room_06_burst.tres"
const ROOM_BOSS_PATH: String = "res://game/world/data/encounters/encounter_dungeon_boss.tres"

const DELTA: float = 1.0 / 60.0
const MAX_STEPS: int = 3600
const APPROX: float = 0.001
const MIN_TIME_GAP_RATIO: float = 0.10
const MIN_EFFECTIVE_HEALTH_GAP: float = 5.0
## 危险窗口场景里的接近距离：定身术 cast_range 120 的 90%，留出浮点余量。
const INTERRUPT_APPROACH_RANGE: float = 108.0
## 窗口开启后再推进的观察时间：窗口时长 2s + 1s 结算余量。
const WINDOW_SETTLE_SECONDS: float = 3.0


func _load_skill(path: String) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = load(path) as ActiveSkillDefinition
	assert_object(skill).is_not_null()
	return skill


## 玩家档案只换主动技能列表：气血 / 护盾 / 灵力 / 攻防全部沿用正式档案，保证对照只差一个技能。
func _make_player_data(skills: Array[ActiveSkillDefinition]) -> PawnData:
	var source: PawnData = load(PLAYER_DATA_PATH) as PawnData
	assert_object(source).is_not_null()
	var data: PawnData = source.duplicate(true) as PawnData
	data.active_skills = skills
	return data


func _spawn_session(skills: Array[ActiveSkillDefinition]) -> EncounterSession:
	var container: Node2D = Node2D.new()
	container.name = EncounterSession.PAWNS_CONTAINER_NAME
	auto_free(container)
	add_child(container)

	var session: EncounterSession = EncounterSession.new()
	session.name = "EncounterSession"
	session.pawns_container = container
	session.player_data = _make_player_data(skills)
	auto_free(session)
	add_child(session)
	return session


## 关掉引擎物理帧，改为手工固定步进：危险窗口、召唤排程与冷却的时间原点才可重复。
func _freeze_units(session: EncounterSession) -> void:
	session.set_physics_process(false)
	for unit: Pawn in session.get_player_units() + session.get_enemy_units():
		if unit == null or not is_instance_valid(unit):
			continue
		unit.set_physics_process(false)
		var controller: PawnController = unit.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


## 一帧手工推进：控制器 → 会话（危险窗口 / 召唤 / 事件时钟）→ 敌方 AI 与物理 → 玩家物理。
func _step_world(session: EncounterSession, player: Pawn, controller: PlayerController) -> void:
	_freeze_units(session)
	controller.update_controller(DELTA)
	session._physics_process(DELTA)
	for enemy: Pawn in session.get_enemy_units().duplicate():
		if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
			continue
		var ai: AIController = enemy.get_controller() as AIController
		if ai != null:
			ai.update_controller(DELTA)
		enemy._physics_process(DELTA)
	player.set_physics_process(false)
	player._physics_process(DELTA)


func _alive_enemies(session: EncounterSession) -> Array[Pawn]:
	var result: Array[Pawn] = []
	for unit: Pawn in session.get_enemy_units():
		if unit != null and is_instance_valid(unit) and unit.is_alive():
			result.append(unit)
	return result


func _first_alive_enemy(session: EncounterSession) -> Pawn:
	var enemies: Array[Pawn] = _alive_enemies(session)
	return enemies[0] if not enemies.is_empty() else null


## 危险窗口的施放者：问题型敌人里唯一配置了 `dangerous_skill` 的单位。
func _first_dangerous_enemy(session: EncounterSession) -> Pawn:
	for enemy: Pawn in _alive_enemies(session):
		if enemy.data != null and enemy.data.dangerous_skill != null:
			return enemy
	return null


## 有效生命：护盾与生命都是承伤资源，比较 Build 的生存价值时必须一起看。
func _effective_health(pawn: Pawn) -> float:
	return pawn.current_health + pawn.current_shield


func _candidate(
		skill: ActiveSkillDefinition,
		player: Pawn,
		target: Pawn,
		reserves: Array[ActiveSkillDefinition] = []
) -> Dictionary:
	if skill == null or player == null or target == null:
		return {}
	if not is_instance_valid(target) or not target.is_alive():
		return {}
	if not _may_spend_spirit(player, skill, reserves):
		return {}
	var cast_target: Pawn = player if skill.target_type == ActiveSkillDefinition.SkillTargetType.SELF else target
	if not player.can_cast_skill(skill, cast_target):
		return {}
	return {"skill": skill, "target": cast_target}


## 触发式技能的机会成本：控制要等危险窗口、吸血要等人受伤，两者都不能被别的技能提前花掉灵力。
func _may_spend_spirit(
		player: Pawn,
		skill: ActiveSkillDefinition,
		reserves: Array[ActiveSkillDefinition]
) -> bool:
	if player == null or skill == null or reserves.is_empty():
		return true
	var needed: float = 0.0
	for reserved: ActiveSkillDefinition in reserves:
		if reserved == null or reserved.id == skill.id:
			continue
		if not player.is_skill_ready(reserved):
			continue
		needed += reserved.get_normalized_spirit_cost()
	if needed <= 0.0:
		return true
	return player.current_spirit - skill.get_normalized_spirit_cost() >= needed


## 危险窗口是否开启：与敌人警示色（`Pawn.set_danger_highlight`）同源，取值来自 EncounterSession
## 持有的窗口调度器；仓库现有公开 API 没有暴露它，因此沿用本套件既有的手工驱动方式直接查调度器。
func _is_danger_window_open(session: EncounterSession, caster: Pawn) -> bool:
	if session == null or caster == null:
		return false
	for scheduler: DangerWindowScheduler in session._danger_schedulers:
		if scheduler != null and scheduler.get_caster() == caster:
			return scheduler.is_window_open()
	return false

## 危险窗口剩余时间：与 `_is_danger_window_open` 同源；未开启时返回 0，供「窗口快结算时再上盾」取景。
func _danger_window_remaining(session: EncounterSession, caster: Pawn) -> float:
	if session == null or caster == null:
		return 0.0
	for scheduler: DangerWindowScheduler in session._danger_schedulers:
		if scheduler != null and scheduler.get_caster() == caster:
			return scheduler.get_window_remaining()
	return 0.0


## 兜底只考虑进攻技能：回复 / 护盾 / 吸血 / 控制各有自己的触发条件，不在「没别的可用」时被随手交掉。
func _is_offensive(skill: ActiveSkillDefinition) -> bool:
	if skill == null:
		return false
	return (
		skill.effect_type == ActiveSkillDefinition.SkillEffectType.DAMAGE
		or skill.effect_type == ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE
		or skill.effect_type == ActiveSkillDefinition.SkillEffectType.DASH
	)

## 固定策略：同一套决策应用到全部 Build，差异只能来自技能集合与敌人的问题。
## 顺序即「先解决谁的问题」：窗口打断 -> 补护盾 -> 回血 -> 吸血 -> 贴近 -> 清召唤 -> 条件爆发 -> 常规输出。
## 控制技能只换「取消危险窗口」，因此必须等窗口真的开启才交；这与玩家据警示色决定是否打断是同一条判断。
func _pick_skill(
		skills: Array[ActiveSkillDefinition],
		player: Pawn,
		target: Pawn,
		session: EncounterSession
) -> Dictionary:
	var window_enemy: Pawn = _first_dangerous_enemy(session)
	var control_skill: ActiveSkillDefinition = null
	var sustain_skill: ActiveSkillDefinition = null
	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type == ActiveSkillDefinition.SkillEffectType.STUN:
			control_skill = skill
		elif skill.effect_type == ActiveSkillDefinition.SkillEffectType.LIFESTEAL:
			sustain_skill = skill
	var reserves: Array[ActiveSkillDefinition] = []
	if window_enemy != null and control_skill != null:
		reserves.append(control_skill)
	if sustain_skill != null:
		reserves.append(sustain_skill)

	if control_skill != null and window_enemy != null:
		if not window_enemy.is_stunned() and _is_danger_window_open(session, window_enemy):
			var interrupt: Dictionary = _candidate(control_skill, player, window_enemy, reserves)
			if not interrupt.is_empty():
				return interrupt

	# 条件爆发轴的起手：带「受控加成」的技能只有目标处于控制状态才吃到倍率。
	# 若 Build 同时带了控制技能，控制就不只用来打断危险窗口，也要用来起手连招；
	# 否则这条价值轴在固定策略下永远不会被兑现，矩阵也就测不到它。
	var combo_skill: ActiveSkillDefinition = null
	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type == ActiveSkillDefinition.SkillEffectType.DAMAGE and skill.has_controlled_bonus():
			combo_skill = skill
	if combo_skill != null and control_skill != null and target != null:
		if not target.is_stunned() and player.is_skill_ready(combo_skill):
			var setup_reserves: Array[ActiveSkillDefinition] = [combo_skill]
			var setup: Dictionary = _candidate(control_skill, player, target, setup_reserves)
			if not setup.is_empty():
				return setup

	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type != ActiveSkillDefinition.SkillEffectType.SHIELD:
			continue
		if _effective_health(player) >= player.data.max_health + player.data.max_shield * 0.6:
			continue
		var shield_choice: Dictionary = _candidate(skill, player, player, reserves)
		if not shield_choice.is_empty():
			return shield_choice

	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type != ActiveSkillDefinition.SkillEffectType.HEAL:
			continue
		if player.current_health >= player.data.max_health * 0.7:
			continue
		var heal_choice: Dictionary = _candidate(skill, player, player, reserves)
		if not heal_choice.is_empty():
			return heal_choice

	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type != ActiveSkillDefinition.SkillEffectType.LIFESTEAL:
			continue
		if player.current_health >= player.data.max_health * 0.9:
			continue
		var drain_choice: Dictionary = _candidate(skill, player, target, reserves)
		if not drain_choice.is_empty():
			return drain_choice

	if target != null and player.global_position.distance_to(target.global_position) > player.data.attack_range:
		for skill: ActiveSkillDefinition in skills:
			if skill.effect_type != ActiveSkillDefinition.SkillEffectType.DASH:
				continue
			var dash_choice: Dictionary = _candidate(skill, player, target, reserves)
			if not dash_choice.is_empty():
				return dash_choice

	if _alive_enemies(session).size() >= 2:
		for skill: ActiveSkillDefinition in skills:
			if skill.effect_type != ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE:
				continue
			var aoe_choice: Dictionary = _candidate(skill, player, target, reserves)
			if not aoe_choice.is_empty():
				return aoe_choice

	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type != ActiveSkillDefinition.SkillEffectType.DAMAGE:
			continue
		if not skill.has_controlled_bonus() or target == null or not target.is_stunned():
			continue
		var combo_choice: Dictionary = _candidate(skill, player, target, reserves)
		if not combo_choice.is_empty():
			return combo_choice

	for skill: ActiveSkillDefinition in skills:
		if skill.effect_type != ActiveSkillDefinition.SkillEffectType.DAMAGE:
			continue
		var damage_choice: Dictionary = _candidate(skill, player, target, reserves)
		if not damage_choice.is_empty():
			return damage_choice

	for skill: ActiveSkillDefinition in skills:
		if not _is_offensive(skill):
			continue
		var fallback: Dictionary = _candidate(skill, player, target, reserves)
		if not fallback.is_empty():
			return fallback
	return {}


## 每名敌人当前的有效生命：用于判断「一次技能结算到底打到了几个单位」。
func _enemy_effective_map(session: EncounterSession) -> Dictionary:
	var result: Dictionary = {}
	for enemy: Pawn in session.get_enemy_units():
		if enemy == null or not is_instance_valid(enemy):
			continue
		result[String(enemy.name)] = _effective_health(enemy)
	return result


## 快照对比：有效生命真的下降的单位数，就是这一次结算打到了几个目标。
func _count_damaged_units(before: Dictionary, after: Dictionary) -> int:
	var count: int = 0
	for key: Variant in before.keys():
		if not after.has(key):
			continue
		if float(after[key]) < float(before[key]) - APPROX:
			count += 1
	return count


func _skill_ids(skills: Array[ActiveSkillDefinition]) -> Array[String]:
	var result: Array[String] = []
	for skill: ActiveSkillDefinition in skills:
		result.append(String(skill.id))
	return result


func _outcome_label(state: int) -> String:
	match state:
		EncounterSession.State.PLAYER_WIN:
			return "player_win"
		EncounterSession.State.ENEMY_WIN:
			return "enemy_win"
		EncounterSession.State.RUNNING:
			return "timeout"
		_:
			return "idle"


## 一场完整对局：真实 EncounterSession + 真实控制器 + 固定步进 + 固定策略。
## 返回的只有客观量：终局、耗时、剩余有效生命、灵力消耗、机制事件计数。
func _run_match(encounter_path: String, skills: Array[ActiveSkillDefinition]) -> Dictionary:
	var encounter: EncounterDefinition = load(encounter_path) as EncounterDefinition
	var session: EncounterSession = _spawn_session(skills)
	assert_object(encounter).is_not_null()
	assert_bool(session.begin(encounter)).is_true()
	_freeze_units(session)

	var player: Pawn = session.get_player_pawn()
	var controller: PlayerController = player.get_controller() as PlayerController
	var enabled: Array[ActiveSkillDefinition] = player.get_enabled_active_skills()
	var log: CombatEventLog = session.get_combat_event_log()
	var initial_health: float = player.current_health
	var initial_spirit: float = player.current_spirit
	var previous_shield: float = player.current_shield
	var last_observed_health: float = player.current_health
	var max_shield_absorbed: float = 0.0
	var health_restored: float = 0.0
	var shield_granted: float = 0.0
	var max_aoe_targets: int = 0
	var max_alive_enemies: int = session.get_enemy_units().size()
	var control_steps: int = 0
	var skill_casts: Dictionary = {}
	var window_distances: Array[String] = []
	var windows_seen: int = 0
	var steps: int = 0

	while steps < MAX_STEPS and session.get_state() == EncounterSession.State.RUNNING:
		var target: Pawn = _first_alive_enemy(session)
		if target == null:
			break

		var before_effective: Dictionary = _enemy_effective_map(session)
		var choice: Dictionary = _pick_skill(enabled, player, target, session)
		if not choice.is_empty():
			var chosen: ActiveSkillDefinition = choice["skill"]
			var cast_target: Pawn = choice["target"]
			# 施法前后取快照：回复与护盾即使在同一步里被打掉，也仍然算「确实发生过」。
			var health_before_cast: float = player.current_health
			var shield_before_cast: float = player.current_shield
			if player.cast_skill(chosen, cast_target):
				health_restored += maxf(player.current_health - health_before_cast, 0.0)
				shield_granted += maxf(player.current_shield - shield_before_cast, 0.0)
				last_observed_health = player.current_health
				if chosen.effect_type == ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE:
					var after_effective: Dictionary = _enemy_effective_map(session)
					max_aoe_targets = maxi(
						max_aoe_targets, _count_damaged_units(before_effective, after_effective)
					)
				var skill_id: String = String(chosen.id)
				skill_casts[skill_id] = int(skill_casts.get(skill_id, 0)) + 1

		controller.order_attack(target)
		_step_world(session, player, controller)

		# 本帧生命净增即为实际回复量（未超过上限、且没有被同帧伤害抵消的部分）。
		if player.current_health > last_observed_health + APPROX:
			health_restored += player.current_health - last_observed_health
		last_observed_health = player.current_health

		if player.current_shield < previous_shield:
			max_shield_absorbed = maxf(max_shield_absorbed, previous_shield - player.current_shield)
		previous_shield = player.current_shield

		for enemy: Pawn in _alive_enemies(session):
			if enemy.is_stunned():
				control_steps += 1
				break

		var opened_now: int = log.count_events_of_type(CombatEvent.DANGER_WINDOW_OPENED)
		if opened_now > windows_seen:
			var wielder: Pawn = _first_dangerous_enemy(session)
			if wielder != null:
				window_distances.append("%.2fs dist %.0f" % [
					float(steps + 1) * DELTA,
					player.global_position.distance_to(wielder.global_position),
				])
			windows_seen = opened_now

		max_alive_enemies = maxi(max_alive_enemies, _alive_enemies(session).size())
		steps += 1

	return {
		"encounter": String(encounter.id),
		"build": _skill_ids(skills),
		"outcome": _outcome_label(session.get_state()),
		"steps": steps,
		"elapsed_seconds": float(steps) * DELTA,
		"health_lost": maxf(initial_health - player.current_health, 0.0),
		"effective_remaining": _effective_health(player),
		"effective_ratio": _effective_health(player) / (player.data.max_health + player.data.max_shield),
		"spirit_spent": initial_spirit - player.current_spirit,
		"max_shield_absorbed": max_shield_absorbed,
		"shield_granted": shield_granted,
		"health_restored": health_restored,
		"control_seconds": float(control_steps) * DELTA,
		"aoe_multi_hit_max": max_aoe_targets,
		"max_alive_enemies": max_alive_enemies,
		"summon_count": log.count_events_of_type(CombatEvent.SUMMONED),
		"danger_window_opened": log.count_events_of_type(CombatEvent.DANGER_WINDOW_OPENED),
		"danger_window_cancelled": log.has_event_type(CombatEvent.SKILL_CANCELLED),
		"danger_window_hit": log.has_event_type(CombatEvent.SKILL_HIT),
		"danger_window_blocked": log.has_event_type(CombatEvent.SKILL_BLOCKED),
		"skill_casts": skill_casts,
		"timeline": _event_timeline(log),
		"window_distances": window_distances,
	}

## 危险窗口取舍场景：先走近到技能射程内，然后只等窗口、不主动输出。
## 与 `_run_match` 的区别是「留手」：只有把控制技能留到窗口开启那一刻，才看得清窗口是被取消还是真的结算。
## 返回的是第一个危险窗口的机制事实，不做通关比较。
func _run_first_danger_window(
		encounter_path: String,
		skills: Array[ActiveSkillDefinition],
		use_control: bool,
		use_shield: bool = false
) -> Dictionary:
	var encounter: EncounterDefinition = load(encounter_path) as EncounterDefinition
	var session: EncounterSession = _spawn_session(skills)
	assert_object(encounter).is_not_null()
	assert_bool(session.begin(encounter)).is_true()
	_freeze_units(session)

	var player: Pawn = session.get_player_pawn()
	var controller: PlayerController = player.get_controller() as PlayerController
	var log: CombatEventLog = session.get_combat_event_log()
	var control_skill: ActiveSkillDefinition = null
	var shield_skill: ActiveSkillDefinition = null
	for skill: ActiveSkillDefinition in player.get_enabled_active_skills():
		if skill.effect_type == ActiveSkillDefinition.SkillEffectType.STUN:
			control_skill = skill
		elif skill.effect_type == ActiveSkillDefinition.SkillEffectType.SHIELD:
			shield_skill = skill
	var steps: int = 0
	var cast_done: bool = false
	var shield_cast: bool = false

	while steps < MAX_STEPS and session.get_state() == EncounterSession.State.RUNNING:
		var window_enemy: Pawn = _first_dangerous_enemy(session)
		if window_enemy == null:
			break
		if not log.has_event_type(CombatEvent.DANGER_WINDOW_OPENED):
			# 阶段一 / 二：先贴近到射程内，再原地等窗口；全程不施放任何技能，灵力留给控制技能。
			if player.global_position.distance_to(window_enemy.global_position) > INTERRUPT_APPROACH_RANGE:
				controller.order_move(window_enemy.global_position)
			else:
				controller.clear_orders()
			_step_world(session, player, controller)
			steps += 1
			continue
		if use_control and not cast_done:
			cast_done = true
			if control_skill == null or not player.cast_skill(control_skill, window_enemy):
				break
		elif use_shield and not cast_done:
			# 护盾路线：等到窗口即将结算的那一帧才上盾，让「盾挡住伤害」与「仍然被硬直」落在同一次结算里，
			# 避免盾在窗口期被普攻磨掉后把这条路线测成「没上盾」。
			if _danger_window_remaining(session, window_enemy) <= DELTA * 2.0:
				cast_done = true
				if shield_skill != null and player.cast_skill(shield_skill, player):
					shield_cast = true
		# 窗口开启后只观察：取消 / 命中 / 挡下都由正式事件日志给出。
		_step_world(session, player, controller)
		steps += 1
		if float(steps) * DELTA > WINDOW_SETTLE_SECONDS and log.has_event_type(CombatEvent.SKILL_CANCELLED):
			break
		if log.has_event_type(CombatEvent.SKILL_HIT) or log.has_event_type(CombatEvent.SKILL_BLOCKED):
			break

	var remaining: Pawn = _first_dangerous_enemy(session)
	# 追加硬直只认追加效果自己的 id：玩家主动施放定身术同样会记录 skill_stunned（那一条不属于危险技能的代价）。
	var followup_skill: ActiveSkillDefinition = null
	if remaining != null and remaining.data != null and remaining.data.dangerous_skill != null:
		followup_skill = remaining.data.dangerous_skill.get_followup_skill()
	var followup_id: String = String(followup_skill.id) if followup_skill != null else ""
	var followup_stunned: int = 0
	var followup_skill_id: String = ""
	for event: CombatEvent in log.get_events():
		if event.event_type != CombatEvent.SKILL_STUNNED:
			continue
		if followup_id.is_empty() or String(event.skill_id) != followup_id:
			continue
		followup_stunned += 1
		if followup_skill_id.is_empty():
			followup_skill_id = String(event.skill_id)
	return {
		"encounter": String(encounter.id),
		"build": _skill_ids(skills),
		"use_control": use_control,
		"use_shield": use_shield,
		"danger_window_opened": log.count_events_of_type(CombatEvent.DANGER_WINDOW_OPENED),
		"control_cast": cast_done and use_control,
		"shield_cast": shield_cast,
		"enemy_stunned": remaining != null and remaining.is_stunned(),
		"cancelled": log.has_event_type(CombatEvent.SKILL_CANCELLED),
		"hit": log.has_event_type(CombatEvent.SKILL_HIT),
		"blocked": log.has_event_type(CombatEvent.SKILL_BLOCKED),
		"player_stunned": player.is_stunned(),
		"player_stun_seconds": player.get_stun_remaining(),
		"followup_stunned_events": followup_stunned,
		"followup_skill_id": followup_skill_id,
		"stunned_event_count": log.count_events_of_type(CombatEvent.SKILL_STUNNED),
		"player_effective": _effective_health(player),
		"steps": steps,
	}


## 全部参与矩阵的 Build：每个 Build 都是「御剑斩 + 另一个技能」，任意两个之间只差一个技能。
func _builds() -> Dictionary:
	var sword: ActiveSkillDefinition = _load_skill(SWORD_PATH)
	var guard: ActiveSkillDefinition = _load_skill(GUARD_PATH)
	var binding: ActiveSkillDefinition = _load_skill(BINDING_PATH)
	var dash: ActiveSkillDefinition = _load_skill(DASH_PATH)
	var aoe: ActiveSkillDefinition = _load_skill(AOE_PATH)
	var lifesteal: ActiveSkillDefinition = _load_skill(LIFESTEAL_PATH)
	var rejuvenation: ActiveSkillDefinition = _load_skill(REJUVENATION_PATH)
	var breaking: ActiveSkillDefinition = _load_skill(BREAKING_SLASH_PATH)

	var sword_guard: Array[ActiveSkillDefinition] = [sword, guard]
	var sword_binding: Array[ActiveSkillDefinition] = [sword, binding]
	var sword_dash: Array[ActiveSkillDefinition] = [sword, dash]
	var sword_aoe: Array[ActiveSkillDefinition] = [sword, aoe]
	var sword_lifesteal: Array[ActiveSkillDefinition] = [sword, lifesteal]
	var sword_rejuvenation: Array[ActiveSkillDefinition] = [sword, rejuvenation]
	var binding_breaking: Array[ActiveSkillDefinition] = [binding, breaking]
	return {
		"sword+guard": sword_guard,
		"sword+binding": sword_binding,
		"sword+dash": sword_dash,
		"sword+aoe": sword_aoe,
		"sword+lifesteal": sword_lifesteal,
		"sword+rejuvenation": sword_rejuvenation,
		"binding+breaking": binding_breaking,
	}


func _match_key(room_path: String, build_id: String) -> String:
	return "%s|%s" % [room_path.get_file().get_basename(), build_id]


## 六类问题型敌人的对照表：每个房间给出两个只差一个技能的 Build，`axis` 写这一格想看的问题。
func _cases() -> Array[Dictionary]:
	return [
		{"room": ROOM_MELEE_PATH, "axis": "近战持续压力", "build_a": "sword+aoe", "build_b": "sword+guard"},
		{"room": ROOM_RANGED_PATH, "axis": "远程压制", "build_a": "sword+dash", "build_b": "sword+guard"},
		{"room": ROOM_CHARGE_PATH, "axis": "蓄力可打断", "build_a": "sword+binding", "build_b": "sword+guard"},
		{"room": ROOM_SUMMON_PATH, "axis": "召唤增援", "build_a": "sword+aoe", "build_b": "sword+guard"},
		{"room": ROOM_IRON_PATH, "axis": "高防高血", "build_a": "sword+lifesteal", "build_b": "sword+guard"},
		{"room": ROOM_BURST_PATH, "axis": "高爆发", "build_a": "sword+binding", "build_b": "sword+guard"},
	]


## 谁在这一格更优：先比剩余有效生命，再比耗时，再比灵力消耗；完全一致记「打平」。
## 只做客观排序，不解释玩家该不该这么配。
func _better_build(a: Dictionary, b: Dictionary) -> String:
	var a_effective: float = float(a["effective_remaining"])
	var b_effective: float = float(b["effective_remaining"])
	if absf(a_effective - b_effective) > APPROX:
		return "A" if a_effective > b_effective else "B"
	var a_time: float = float(a["elapsed_seconds"])
	var b_time: float = float(b["elapsed_seconds"])
	if absf(a_time - b_time) > APPROX:
		return "A" if a_time < b_time else "B"
	var a_spirit: float = float(a["spirit_spent"])
	var b_spirit: float = float(b["spirit_spent"])
	if absf(a_spirit - b_spirit) > APPROX:
		return "A" if a_spirit < b_spirit else "B"
	return "打平"


## 差异是否超出噪声带：剩余有效生命差 >= 5 点，或耗时相对差 >= 10% 即算超出。
## 阈值取自同配置重复运行的实际抖动（同进程 0.000；跨进程只有整体滑动）。
func _exceeds_noise(a: Dictionary, b: Dictionary) -> bool:
	var a_time: float = float(a["elapsed_seconds"])
	var b_time: float = float(b["elapsed_seconds"])
	var time_gap: float = absf(a_time - b_time)
	var larger_time: float = maxf(a_time, b_time)
	var health_gap: float = absf(
		float(a["effective_remaining"]) - float(b["effective_remaining"])
	)
	if health_gap >= MIN_EFFECTIVE_HEALTH_GAP:
		return true
	if larger_time <= 0.0:
		return false
	return time_gap / larger_time >= MIN_TIME_GAP_RATIO

## 关键事件时间线（INC-TESTING-023）：只保留危险窗口相关事件，供人工复核「窗口是否真的兑现」。
func _event_timeline(log: CombatEventLog) -> Array[String]:
	var lines: Array[String] = []
	for event: CombatEvent in log.get_events():
		var is_danger_skill: bool = String(event.skill_id) == "charge_bolt"
		var is_key: bool = (
			event.event_type == CombatEvent.DANGER_WINDOW_OPENED
			or event.event_type == CombatEvent.SKILL_CANCELLED
			or event.event_type == CombatEvent.SKILL_STUNNED
			or event.event_type == CombatEvent.UNIT_DIED
			or (is_danger_skill and event.event_type != CombatEvent.SKILL_STUNNED)
		)
		if is_key:
			lines.append("%.2f %s %s->%s %s" % [
				event.timestamp,
				String(event.event_type),
				String(event.actor_id),
				String(event.target_id),
				String(event.skill_id),
			])
	return lines


## 一行客观量摘要：终局 / 耗时 / 剩余有效生命 / 灵力消耗，供打印与人工复核。
func _summary(result: Dictionary) -> String:
	return "%s %.2fs 余命 %.1f 灵力 %.0f" % [
		String(result["outcome"]),
		float(result["elapsed_seconds"]),
		float(result["effective_remaining"]),
		float(result["spirit_spent"]),
	]


## 矩阵主用例：六类问题房间 × 两个「只差一个技能」的 Build。
## 每个 Build 各跑一遍，并对同一配置重复一遍以证明同进程内可复现；差异是否超出噪声由 `_exceeds_noise` 判定。
func test_problem_room_matrix_records_skill_value_changes() -> void:
	var builds: Dictionary = _builds()
	var cases: Array[Dictionary] = _cases()
	var rows: Dictionary = {}
	var noise_beating_gaps: Array[String] = []
	var dominated_cells: Array[String] = []
	var trade_off_cells: Array[String] = []
	var winning_builds: Array[String] = []

	for case_data: Dictionary in cases:
		var room: String = case_data["room"]
		var axis: String = case_data["axis"]
		var build_a: String = case_data["build_a"]
		var build_b: String = case_data["build_b"]
		var room_key: String = room.get_file().get_basename()
		var a: Dictionary = _run_match(room, builds[build_a])
		var b: Dictionary = _run_match(room, builds[build_b])
		var a_repeat: Dictionary = _run_match(room, builds[build_a])

		# 同进程内固定步进 + 固定策略没有随机源：同一配置重复运行必须逐位相同，否则这一格不构成对照。
		assert_float(float(a["elapsed_seconds"])).is_equal_approx(float(a_repeat["elapsed_seconds"]), APPROX)
		assert_float(float(a["effective_remaining"])).is_equal_approx(float(a_repeat["effective_remaining"]), APPROX)
		assert_float(float(a["spirit_spent"])).is_equal_approx(float(a_repeat["spirit_spent"]), APPROX)

		# 每一格都必须真的跑起来并记录客观量：终局不是 idle，耗时与剩余有效生命都有记录。
		assert_str(String(a["outcome"])).is_not_equal("idle")
		assert_float(float(a["elapsed_seconds"])).is_greater(0.0)
		assert_float(float(a["effective_remaining"])).is_greater_equal(0.0)

		rows[_match_key(room, build_a)] = a
		rows[_match_key(room, build_b)] = b

		var better: String = _better_build(a, b)
		var exceeds: bool = _exceeds_noise(a, b)
		var better_build: String = build_a if better == "A" else build_b
		var dominated: bool = _dominates(a, b) or _dominates(b, a)
		print("[INC-TESTING-019] %s / %s：%s=%s vs %s=%s → 更优=%s，超出噪声=%s，被支配=%s" % [
			room_key, axis, build_a, _summary(a), build_b, _summary(b), better, str(exceeds), str(dominated),
		])
		if dominated:
			dominated_cells.append("%s(%s) → %s" % [room_key, axis, better])
		else:
			trade_off_cells.append("%s(%s)" % [room_key, axis])
		if not exceeds or better == "打平":
			continue
		noise_beating_gaps.append("%s(%s) → %s" % [room_key, axis, better])
		winning_builds.append(better_build)

	assert_int(rows.size()).is_equal(cases.size() * 2)

	# 断言 1「换技能能改变客观量」：至少两格出现超出噪声带、且不是打平的差异。
	assert_int(noise_beating_gaps.size()).is_greater_equal(2)

	# 断言 2「不同敌人给不同技能定价」：至少两格的最优 Build 不是同一个。
	# 若所有格子都由同一个 Build 胜出，就说明当前仍是「一套最优解」，而不是按问题配装。
	assert_int(_distinct(winning_builds).size()).is_greater_equal(2)

	# 断言 3「取舍真实存在」：至少两格的三个客观量互有胜负（没有任何一方被严格支配）。
	# 只被支配的格子说明这一格的问题没有形成取舍，必须靠问题差异化解决而不是调数值。
	assert_int(trade_off_cells.size()).is_greater_equal(2)

	print("[INC-TESTING-019] 超出噪声的格子：%s" % str(noise_beating_gaps))
	print("[INC-TESTING-019] 各格最优 Build：%s → %s" % [
		str(winning_builds), str(_distinct(winning_builds)),
	])
	print("[INC-TESTING-019] 互有胜负的格子：%s" % str(trade_off_cells))
	print("[INC-TESTING-019] 被严格支配的格子：%s" % str(dominated_cells))


## 反向对照（验收标准 3）：同为「单体伤害」的两个技能互换时，差异只能记成数值高低，不能记成新的价值轴。
## 数据前提：御剑斩 1.8×（无附加条件）与破军斩 1.4× + 受控 2.4× 同属 DAMAGE / ENEMY，差别只在倍率与附加条件。
func test_numeric_damage_upgrade_is_not_a_build_axis_change() -> void:
	var sword: ActiveSkillDefinition = _load_skill(SWORD_PATH)
	var breaking: ActiveSkillDefinition = _load_skill(BREAKING_SLASH_PATH)
	assert_int(sword.effect_type).is_equal(breaking.effect_type)
	assert_int(sword.target_type).is_equal(breaking.target_type)
	assert_float(sword.controlled_bonus_multiplier).is_equal_approx(1.0, APPROX)
	assert_bool(breaking.has_controlled_bonus()).is_true()
	assert_bool(breaking.effect_value < sword.effect_value).is_true()

	# 没有控制搭档时：低倍率 + 条件倍率的一方不能凭「换技能」拿到更好的客观量。
	var solo_sword: Array[ActiveSkillDefinition] = [sword]
	var solo_breaking: Array[ActiveSkillDefinition] = [breaking]
	var sword_solo: Dictionary = _run_match(ROOM_MELEE_PATH, solo_sword)
	var breaking_solo: Dictionary = _run_match(ROOM_MELEE_PATH, solo_breaking)
	print("[INC-TESTING-019] 数值对照（无控制）：御剑斩=%s vs 破军斩=%s" % [
		_summary(sword_solo), _summary(breaking_solo),
	])
	assert_str(_better_build(sword_solo, breaking_solo)).is_equal("A")

	# 补上控制搭档后，同一对技能的价值排序必须反转：差异来自「受控加成」这个条件轴，而不是倍率数字本身。
	var binding: ActiveSkillDefinition = _load_skill(BINDING_PATH)
	var pair_sword: Array[ActiveSkillDefinition] = [sword, binding]
	var pair_breaking: Array[ActiveSkillDefinition] = [breaking, binding]
	var sword_paired: Dictionary = _run_match(ROOM_CHARGE_PATH, pair_sword)
	var breaking_paired: Dictionary = _run_match(ROOM_CHARGE_PATH, pair_breaking)
	print("[INC-TESTING-019] 数值对照（有控制）：御剑斩=%s vs 破军斩=%s" % [
		_summary(sword_paired), _summary(breaking_paired),
	])
	assert_str(_better_build(sword_paired, breaking_paired)).is_equal("B")


## 危险窗口用例：只有控制技能能取消窗口；不带控制时窗口照常结算（命中或挡下）。
func test_danger_window_is_only_cancelled_by_control_skill() -> void:
	var builds: Dictionary = _builds()
	var with_control: Dictionary = _run_first_danger_window(ROOM_CHARGE_PATH, builds["sword+binding"], true)
	var without_control: Dictionary = _run_first_danger_window(ROOM_CHARGE_PATH, builds["sword+guard"], false)
	print("[INC-TESTING-019] 危险窗口（定身）=%s" % str(with_control))
	print("[INC-TESTING-019] 危险窗口（无控制）=%s" % str(without_control))

	# 两条路径都必须真的等到窗口开启，否则这一格什么都没测到。
	assert_int(int(with_control["danger_window_opened"])).is_greater_equal(1)
	assert_int(int(without_control["danger_window_opened"])).is_greater_equal(1)

	# 有控制：定身真的落地，窗口被取消，且没有命中 / 挡下。
	assert_bool(bool(with_control["control_cast"])).is_true()
	assert_bool(bool(with_control["cancelled"])).is_true()
	assert_bool(bool(with_control["hit"])).is_false()
	assert_bool(bool(with_control["blocked"])).is_false()

	# 无控制：窗口照常结算，没有任何一次取消。
	assert_bool(bool(without_control["cancelled"])).is_false()
	assert_bool(bool(without_control["hit"]) or bool(without_control["blocked"])).is_true()


## 追加代价用例（INC-TESTING-023）：危险窗口落地后，护盾能吸收伤害，却买不断紧随其后的硬直。
## 三条路径对比：定身打断（窗口取消）/ 有盾硬吃（盾放出来后再结算）/ 无盾硬吃。全部取自正式事件日志。
func test_danger_window_followup_penalty_survives_shield() -> void:
	var builds: Dictionary = _builds()
	var interrupted: Dictionary = _run_first_danger_window(ROOM_CHARGE_PATH, builds["sword+binding"], true)
	var shielded: Dictionary = _run_first_danger_window(ROOM_CHARGE_PATH, builds["sword+guard"], false, true)
	var exposed: Dictionary = _run_first_danger_window(ROOM_CHARGE_PATH, builds["sword+guard"], false)
	print("[INC-TESTING-023] 追加代价（定身打断）=%s" % str(interrupted))
	print("[INC-TESTING-023] 追加代价（有盾硬吃）=%s" % str(shielded))
	print("[INC-TESTING-023] 追加代价（无盾硬吃）=%s" % str(exposed))

	# 三条路径都必须真的等到窗口开启，否则这一格什么都没测到。
	assert_int(int(interrupted["danger_window_opened"])).is_greater_equal(1)
	assert_int(int(shielded["danger_window_opened"])).is_greater_equal(1)
	assert_int(int(exposed["danger_window_opened"])).is_greater_equal(1)

	# 打断：窗口取消、没有命中 / 挡下，玩家一次都不进入硬直，追加硬直一次都没有落地。
	# （玩家自己施放的定身术会记一条 skill_stunned，因此这里断言的是「追加效果 id」的计数，不是总数。）
	assert_bool(bool(interrupted["cancelled"])).is_true()
	assert_bool(bool(interrupted["hit"]) or bool(interrupted["blocked"])).is_false()
	assert_int(int(interrupted["followup_stunned_events"])).is_zero()
	assert_str(String(interrupted["followup_skill_id"])).is_equal("")
	assert_int(int(interrupted["stunned_event_count"])).is_greater_equal(1)
	assert_bool(bool(interrupted["player_stunned"])).is_false()
	assert_float(float(interrupted["player_stun_seconds"])).is_equal_approx(0.0, APPROX)

	# 硬吃（有盾 / 无盾）：主效果照常结算，追加硬直一定落地，事件带的是追加效果自己的 id。
	for eaten: Dictionary in [shielded, exposed]:
		assert_bool(bool(eaten["hit"]) or bool(eaten["blocked"])).is_true()
		assert_int(int(eaten["followup_stunned_events"])).is_greater_equal(1)
		assert_str(String(eaten["followup_skill_id"])).is_equal("charge_hardstop")
		assert_bool(bool(eaten["player_stunned"])).is_true()
		assert_float(float(eaten["player_stun_seconds"])).is_greater(0.0)

	# 有盾那一条必须真的把盾放出来并挡下这次伤害，否则它证明的不是「盾挡不住」，而是「没上盾」。
	assert_bool(bool(shielded["shield_cast"])).is_true()
	assert_bool(bool(shielded["blocked"])).is_true()
	assert_bool(bool(shielded["hit"])).is_false()


## 重新定价用例（INC-TESTING-023）：room 03 的答案必须从「护体真气硬吃」变回「定身打断」。
## 前提是危险窗口在这场对局里真的落地；若窗口从未出现，这一格比较的只是两个没有问题的房间。
func test_charge_room_prices_interrupt_above_shield() -> void:
	var builds: Dictionary = _builds()
	var interrupt: Dictionary = _run_match(ROOM_CHARGE_PATH, builds["sword+binding"])
	var shield: Dictionary = _run_match(ROOM_CHARGE_PATH, builds["sword+guard"])
	print("[INC-TESTING-023] room 03 重新定价：sword+binding=%s（窗口 %d / 取消 %s） vs sword+guard=%s（窗口 %d / 命中 %s / 挡下 %s）" % [
		_summary(interrupt),
		int(interrupt["danger_window_opened"]),
		str(interrupt["danger_window_cancelled"]),
		_summary(shield),
		int(shield["danger_window_opened"]),
		str(shield["danger_window_hit"]),
		str(shield["danger_window_blocked"]),
	])
	print("[INC-TESTING-023] 时间线（binding）=%s" % str(interrupt["timeline"]))
	print("[INC-TESTING-023] 时间线（guard）=%s" % str(shield["timeline"]))
	print("[INC-TESTING-023] 窗口开启距离（binding）=%s" % str(interrupt["window_distances"]))
	print("[INC-TESTING-023] 窗口开启距离（guard）=%s" % str(shield["window_distances"]))

	# 前提：这一格必须真的出现过危险窗口。
	assert_int(int(interrupt["danger_window_opened"]) + int(shield["danger_window_opened"])).is_greater_equal(1)

	# 主断言：只差一个技能时，打断型 Build 更优，且差异超出既有噪声带。
	assert_str(_better_build(interrupt, shield)).is_equal("A")
	assert_bool(_exceeds_noise(interrupt, shield)).is_true()

	# 负面对照：不带打断也必须能通关——问题变难，但没有变成「不带定身术就过不去」。
	assert_str(String(shield["outcome"])).is_equal("player_win")


## 严格支配：一方在「剩余有效生命更高 / 耗时更短 / 灵力消耗更少」三项上都不差，且至少一项好出噪声带。
## 任一项更差即算「互有胜负」——这类格子才是真正的取舍。
func _dominates(a: Dictionary, b: Dictionary) -> bool:
	var health_ok: bool = float(a["effective_remaining"]) >= float(b["effective_remaining"]) - APPROX
	var time_ok: bool = float(a["elapsed_seconds"]) <= float(b["elapsed_seconds"]) + APPROX
	var spirit_ok: bool = float(a["spirit_spent"]) <= float(b["spirit_spent"]) + APPROX
	if not (health_ok and time_ok and spirit_ok):
		return false
	return _exceeds_noise(a, b)


## 去重且保持首次出现顺序：用于判断「最优 Build 是否随敌人改变」。
func _distinct(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		if not result.has(value):
			result.append(value)
	return result
