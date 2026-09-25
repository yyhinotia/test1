extends GdUnitTestSuite

## 集成层：召唤型敌人的增援契约（INC-COMBAT-011）。
##
## 只消费正式 PawnData 档案与 EncounterSession 公开路径：
## 增援是否生成、是否计入敌方队伍、是否影响终局，全部用固定时间步驱动真实会话得出。

const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const SUMMONER_PATH: String = "res://game/pawns/data/enemies/enemy_summoner.tres"
const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const AOE_SKILL_PATH: String = "res://game/pawns/data/skills/player_sword_aoe_skill.tres"
const MINION_ID: StringName = &"enemy_summon_minion"

const DELTA: float = 1.0 / 60.0
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
	auto_free(session)
	add_child(session)
	return session


func _build_encounter() -> EncounterDefinition:
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"test_summoner_reinforcement"
	encounter.display_name = "召唤型测试遭遇"
	encounter.enemy_profile = load(SUMMONER_PATH) as PawnData
	return encounter


## 关掉引擎物理帧，改为手工固定步进；召唤调度与危险窗口都挂在会话的 _physics_process 上。
func _isolate(session: EncounterSession) -> void:
	session.set_physics_process(false)
	for unit: Pawn in session.get_player_units() + session.get_enemy_units():
		unit.set_physics_process(false)
		var controller: PawnController = unit.get_controller() as PawnController
		if controller != null:
			controller.set_physics_process(false)


func _advance(session: EncounterSession, seconds: float) -> void:
	var remaining: float = seconds
	while remaining > 0.0:
		var step: float = minf(DELTA, remaining)
		session._physics_process(step)
		remaining -= step


func _lethal_damage(pawn: Pawn) -> float:
	return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


func _minion_count(session: EncounterSession) -> int:
	var count: int = 0
	for unit: Pawn in session.get_enemy_units():
		if unit != null and is_instance_valid(unit) and unit.data != null and unit.data.id == MINION_ID:
			count += 1
	return count


func test_summoner_spawns_reinforcement_on_fixed_schedule() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_build_encounter())).is_true()
	_isolate(session)
	var enemies_before: int = session.get_enemy_units().size()

	_advance(session, 1.1)

	var enemies_after: int = session.get_enemy_units().size()
	assert_int(enemies_after).is_equal(enemies_before + 1)
	assert_int(_minion_count(session)).is_equal(1)
	var minion: Pawn = session.get_enemy_units()[enemies_after - 1]
	assert_str(String(minion.data.id)).is_equal("enemy_summon_minion")
	# 增援是真正接入战斗的单位：AI 已绑定同一玩家目标，而不是装饰物。
	assert_bool(minion.get_controller() is AIController).is_true()
	assert_object((minion.get_controller() as AIController).pawn).is_same(minion)
	assert_bool(session.get_combat_event_log().has_event_type(CombatEvent.SUMMONED)).is_true()


func test_reinforcement_is_required_for_victory() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_build_encounter())).is_true()
	_isolate(session)
	_advance(session, 1.1)
	assert_int(session.get_enemy_units().size()).is_equal(2)

	var summoner: Pawn = session.get_enemy_pawn()
	summoner.take_damage(_lethal_damage(summoner))
	# 召唤者已死但增援仍活着：终局不得提前判胜。
	assert_int(session.get_state()).is_equal(EncounterSession.State.RUNNING)

	var reinforcement: Pawn = session.get_enemy_units()[1]
	reinforcement.take_damage(_lethal_damage(reinforcement))
	assert_int(session.get_state()).is_equal(EncounterSession.State.PLAYER_WIN)


func test_summon_schedule_stops_after_summoner_death() -> void:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_build_encounter())).is_true()
	_isolate(session)
	_advance(session, 1.1)
	var summoner: Pawn = session.get_enemy_pawn()
	summoner.take_damage(_lethal_damage(summoner))
	var count_after_death: int = session.get_enemy_units().size()

	_advance(session, 10.0)

	assert_int(session.get_enemy_units().size()).is_equal(count_after_death)


## 同一召唤型遭遇、同一初始站位，只替换一个技能：范围剑气命中聚集增援的总伤害必须显著高于单体输出。
func test_area_damage_outvalues_single_target_against_clustered_reinforcements() -> void:
	var aoe: Dictionary = _measure_single_cast(AOE_SKILL_PATH, 3)
	var single: Dictionary = _measure_single_cast(SWORD_SKILL_PATH, 3)

	assert_int(aoe["enemies"] as int).is_equal(4)
	assert_int(single["enemies"] as int).is_equal(4)
	assert_bool((aoe["hits"] as int) >= 4).is_true()
	assert_int(single["hits"] as int).is_equal(1)
	assert_bool((aoe["damage"] as float) > (single["damage"] as float) * 2.0).is_true()


## 在召唤型战斗中施放一次技能，记录总伤害与命中单位数；两次对照使用完全相同的摆放。
func _measure_single_cast(skill_path: String, reinforcement_count: int) -> Dictionary:
	var session: EncounterSession = _spawn_session()
	assert_bool(session.begin(_build_encounter())).is_true()
	_isolate(session)
	# 召唤节奏为 1.0s 首次、之后每 3.0s 一个；推进到刚好生成目标数量的增援。
	_advance(session, 1.0 + 3.0 * float(reinforcement_count - 1) + 0.1)

	var player: Pawn = session.get_player_pawn()
	var skill: ActiveSkillDefinition = load(skill_path) as ActiveSkillDefinition
	assert_object(skill).is_not_null()
	if not player.is_active_skill_known(skill):
		assert_bool(player.learn_active_skill(skill)).is_true()
	var sword: ActiveSkillDefinition = load(SWORD_SKILL_PATH) as ActiveSkillDefinition
	var loadout: Array[ActiveSkillDefinition] = [skill]
	if skill != sword:
		loadout.append(sword)
	assert_bool(player.set_active_skill_loadout(loadout)).is_true()

	var summoner: Pawn = session.get_enemy_pawn()
	assert_object(summoner).is_not_null()
	# 只做固定摆放：两次对照都站在同一施法距离内，差异只来自技能本身。
	player.global_position = summoner.global_position + Vector2(80.0, 0.0)

	var before: Dictionary = {}
	var total_before: float = 0.0
	for enemy: Pawn in session.get_enemy_units():
		var key: int = enemy.get_instance_id()
		var value: float = enemy.current_health + enemy.current_shield
		before[key] = value
		total_before += value

	assert_bool(player.can_cast_skill(skill, summoner)).is_true()
	assert_bool(player.cast_skill(skill, summoner)).is_true()

	var total_after: float = 0.0
	var hits: int = 0
	for enemy: Pawn in session.get_enemy_units():
		var key: int = enemy.get_instance_id()
		var value: float = enemy.current_health + enemy.current_shield
		total_after += value
		if before.has(key) and value < (before[key] as float) - APPROX:
			hits += 1

	return {
		"damage": total_before - total_after,
		"hits": hits,
		"enemies": session.get_enemy_units().size(),
	}
