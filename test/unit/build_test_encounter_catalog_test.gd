extends GdUnitTestSuite

## 单元层（纯数据）：1v1 / 1v2 / 1v3 Build 验证遭遇目录（INC-WORLD-007）。
## 只断言数据契约与引用关系，不实例化 Pawn、不加载场景：
## 人数、阵营、敌人 id 唯一性、首通奖励数量，以及 Stage 3 的「同一个 Boss」对照。

const ENCOUNTER_1V1_PATH: String = "res://game/world/data/encounters/build_test_1v1.tres"
const ENCOUNTER_1V2_PATH: String = "res://game/world/data/encounters/build_test_1v2.tres"
const ENCOUNTER_1V3_PATH: String = "res://game/world/data/encounters/build_test_1v3.tres"

const BINDING_SKILL_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"

const EXPECTED_ENCOUNTER_IDS: Array[StringName] = [&"build_test_1v1", &"build_test_1v2", &"build_test_1v3"]
const EXPECTED_ENEMY_COUNTS: Array[int] = [1, 2, 3]


func _load_encounter(path: String) -> EncounterDefinition:
	return load(path) as EncounterDefinition


func _all_encounters() -> Array[EncounterDefinition]:
	var result: Array[EncounterDefinition] = []
	result.append(_load_encounter(ENCOUNTER_1V1_PATH))
	result.append(_load_encounter(ENCOUNTER_1V2_PATH))
	result.append(_load_encounter(ENCOUNTER_1V3_PATH))
	return result


## 三份遭遇的玩家数恒为 1、敌人数依次 1 / 2 / 3，且站位数量与敌人数一致。
func test_encounters_declare_one_player_and_one_to_three_enemies() -> void:
	var encounters: Array[EncounterDefinition] = _all_encounters()
	assert_int(encounters.size()).is_equal(EXPECTED_ENCOUNTER_IDS.size())
	for index: int in encounters.size():
		var encounter: EncounterDefinition = encounters[index]
		assert_object(encounter).is_not_null()
		assert_bool(encounter.is_configured()).is_true()
		assert_str(String(encounter.id)).is_equal(String(EXPECTED_ENCOUNTER_IDS[index]))
		assert_bool(encounter.display_name.strip_edges().is_empty()).is_false()
		# 玩家侧始终只有 1 个 Pawn：Stage 1~3 不引入队友变量。
		assert_int(encounter.player_count).is_equal(1)
		assert_int(encounter.get_requested_player_count()).is_equal(1)
		assert_int(encounter.get_enemy_count()).is_equal(EXPECTED_ENEMY_COUNTS[index])
		assert_int(encounter.get_enemy_spawn_offsets().size()).is_equal(EXPECTED_ENEMY_COUNTS[index])


## 敌人都是敌方阵营的可配置档案，且同一场遭遇内的成员 id 互不重复。
func test_enemy_members_are_distinct_enemy_faction_profiles() -> void:
	for encounter: EncounterDefinition in _all_encounters():
		var member_ids: Array = []
		for member: PawnData in encounter.get_enemy_members():
			assert_object(member).is_not_null()
			assert_str(String(member.faction)).is_equal("enemy")
			assert_bool(String(member.id).strip_edges().is_empty()).is_false()
			member_ids.append(String(member.id))
		assert_int(_unique_count(member_ids)).is_equal(member_ids.size())


## 奖励只挂在一场遭遇上、只有一个技能：不叠加灵石 / 装备 / 强化 / 随机掉落。
func test_only_the_1v1_encounter_carries_the_first_clear_reward() -> void:
	var reward_owners: Array = []
	for encounter: EncounterDefinition in _all_encounters():
		if encounter.has_first_clear_reward():
			reward_owners.append(String(encounter.id))
			assert_str(encounter.first_clear_skill_reward.resource_path).is_equal(BINDING_SKILL_PATH)
	assert_array(reward_owners).contains_exactly(["build_test_1v1"])

	var reward: ActiveSkillDefinition = _load_encounter(ENCOUNTER_1V1_PATH).first_clear_skill_reward
	assert_object(reward).is_not_null()
	assert_str(String(reward.id)).is_equal("binding_spell")
	assert_bool(reward.is_configured()).is_true()


## Stage 3 的对照前提：1v3 复用 1v2 的两名角色，并把 1v1 的同一个 Boss 放在最后。
func test_1v3_reuses_the_1v1_boss_and_the_1v2_pair() -> void:
	var boss_members: Array[PawnData] = _load_encounter(ENCOUNTER_1V1_PATH).get_enemy_members()
	assert_int(boss_members.size()).is_equal(1)
	var boss: PawnData = boss_members[0]
	assert_bool(boss.has_danger_window()).is_true()

	var pair_members: Array[PawnData] = _load_encounter(ENCOUNTER_1V2_PATH).get_enemy_members()
	var triple_members: Array[PawnData] = _load_encounter(ENCOUNTER_1V3_PATH).get_enemy_members()
	assert_int(pair_members.size()).is_equal(2)
	assert_int(triple_members.size()).is_equal(3)
	assert_object(triple_members[0]).is_same(pair_members[0])
	assert_object(triple_members[1]).is_same(pair_members[1])
	# 同一份资源实例：Stage 3 的「同一个 Boss」对照不允许用复制体冒充。
	assert_object(triple_members[2]).is_same(boss)


## 1v2 的近战 / 远程必须是两种行为角色，否则「先杀谁」不构成真实决策。
func test_1v2_pairs_a_melee_threat_with_a_long_range_threat() -> void:
	var members: Array[PawnData] = _load_encounter(ENCOUNTER_1V2_PATH).get_enemy_members()
	assert_int(members.size()).is_equal(2)
	var ranges: Array = []
	for member: PawnData in members:
		ranges.append(member.attack_range)
	ranges.sort()
	assert_float(float(ranges[0])).is_greater(0.0)
	assert_float(float(ranges[1])).is_greater(float(ranges[0]) * 2.0)


func _unique_count(values: Array) -> int:
	var unique: Array = []
	for value: Variant in values:
		if not unique.has(value):
			unique.append(value)
	return unique.size()
