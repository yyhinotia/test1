extends GdUnitTestSuite

## 单元层：秘境房间链定义（INC-WORLD-003）。
##
## 锁定「一个秘境 = 有序房间链 + 终局 Boss」的数据契约：
## 房间 / 秘境资源只读，越界安全，奖励随深度递增，Boss 恰好在最后一间，
## 且所有敌人都来自 game/pawns/data/ 的正式档案而不是在房间里复制数值。

const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"
const PROBLEM_DUNGEON_PATH: String = "res://game/world/data/dungeons/problem_dungeon.tres"
const TRIAL_ENCOUNTER_PATH: String = "res://game/world/data/encounters/encounter_trial_puppet.tres"
const ENEMY_DATA_PREFIX: String = "res://game/pawns/data/"
const EXPECTED_ENEMY_IDS := [
	"enemy_001",
	"enemy_001",
	"enemy_iron_guard",
	"enemy_blood_blade",
	"enemy_iron_guard",
	"enemy_dungeon_boss",
]


func _load_dungeon() -> DungeonDefinition:
	return load(DUNGEON_PATH) as DungeonDefinition


func test_unconfigured_and_empty_room_lists_are_rejected() -> void:
	assert_bool(DungeonDefinition.new().is_configured()).is_false()

	var empty: DungeonDefinition = DungeonDefinition.new()
	empty.id = &"empty_dungeon"
	empty.display_name = "空秘境"
	assert_bool(empty.is_configured()).is_false()

	var sparse_rooms: Array[DungeonRoom] = []
	sparse_rooms.append(null)
	var sparse: DungeonDefinition = DungeonDefinition.new()
	sparse.id = &"sparse_dungeon"
	sparse.display_name = "缺房秘境"
	sparse.rooms = sparse_rooms
	assert_bool(sparse.is_configured()).is_false()

	var negative_room: DungeonRoom = DungeonRoom.new()
	negative_room.display_name = "负奖励房"
	negative_room.encounter = load(TRIAL_ENCOUNTER_PATH) as EncounterDefinition
	negative_room.reward_spirit_stones = -1
	assert_bool(negative_room.is_configured()).is_false()
	# 非法奖励读取时按 0 处理，不让调用方拿到负数收益。
	assert_int(negative_room.get_reward()).is_zero()

	var bad_rooms: Array[DungeonRoom] = []
	bad_rooms.append(negative_room)
	var bad: DungeonDefinition = DungeonDefinition.new()
	bad.id = &"bad_dungeon"
	bad.display_name = "坏房秘境"
	bad.rooms = bad_rooms
	assert_bool(bad.is_configured()).is_false()


func test_out_of_range_reads_are_safe() -> void:
	var dungeon: DungeonDefinition = _load_dungeon()

	assert_object(dungeon.get_room(-1)).is_null()
	assert_object(dungeon.get_room(dungeon.get_room_count())).is_null()
	assert_object(dungeon.get_room(999)).is_null()
	assert_int(dungeon.get_room_reward(-1)).is_zero()
	assert_int(dungeon.get_room_reward(999)).is_zero()


func test_trial_dungeon_has_six_rooms_with_single_final_boss() -> void:
	var dungeon: DungeonDefinition = _load_dungeon()

	assert_object(dungeon).is_not_null()
	assert_bool(dungeon.is_configured()).is_true()
	assert_str(String(dungeon.id)).is_equal("trial_dungeon")
	assert_str(dungeon.display_name).is_equal("试炼秘境")
	assert_int(dungeon.get_room_count()).is_equal(6)

	var boss_count: int = 0
	for index: int in dungeon.get_room_count():
		var room: DungeonRoom = dungeon.get_room(index)
		assert_object(room).is_not_null()
		if room.is_boss:
			boss_count += 1
	assert_int(boss_count).is_equal(1)
	assert_bool(dungeon.has_boss()).is_true()
	assert_int(dungeon.get_boss_index()).is_equal(dungeon.get_room_count() - 1)

	var boss_room: DungeonRoom = dungeon.get_room(dungeon.get_boss_index())
	assert_object(boss_room).is_not_null()
	assert_bool(boss_room.is_boss).is_true()
	assert_str(String(boss_room.encounter.enemy_profile.id)).is_equal("enemy_dungeon_boss")


func test_rewards_increase_with_depth_and_boss_is_highest() -> void:
	var dungeon: DungeonDefinition = _load_dungeon()
	var previous: int = -1
	var expected_total: int = 0

	for index: int in dungeon.get_room_count():
		var reward: int = dungeon.get_room_reward(index)
		assert_int(reward).is_greater_equal(previous)
		previous = reward
		expected_total += reward

	assert_int(dungeon.get_room_reward(dungeon.get_room_count() - 1)).is_greater(
		dungeon.get_room_reward(0)
	)
	assert_int(dungeon.get_max_reward()).is_equal(expected_total)


func test_room_threat_order_matches_formal_enemy_profiles() -> void:
	var dungeon: DungeonDefinition = _load_dungeon()

	assert_int(dungeon.get_room_count()).is_equal(EXPECTED_ENEMY_IDS.size())
	for index: int in dungeon.get_room_count():
		var room: DungeonRoom = dungeon.get_room(index)
		assert_object(room).is_not_null()
		assert_object(room.encounter).is_not_null()
		assert_str(String(room.encounter.enemy_profile.id)).is_equal(EXPECTED_ENEMY_IDS[index])


func test_every_room_references_formal_enemy_profile_in_pawns_data() -> void:
	var dungeon: DungeonDefinition = _load_dungeon()

	for index: int in dungeon.get_room_count():
		var room: DungeonRoom = dungeon.get_room(index)
		assert_object(room).is_not_null()
		assert_bool(room.encounter != null and room.encounter.is_configured()).is_true()
		var profile: PawnData = room.encounter.enemy_profile
		assert_object(profile).is_not_null()
		assert_str(profile.resource_path).starts_with(ENEMY_DATA_PREFIX)
		assert_str(room.get_enemy_display_name()).is_equal(profile.display_name)

func _load_problem_dungeon() -> DungeonDefinition:
	return load(PROBLEM_DUNGEON_PATH) as DungeonDefinition


## 问题房间数据契约（INC-WORLD-008）：10~15 间、Boss 收尾、每间「声明 = 事实」、六类问题全覆盖。
func test_problem_dungeon_has_twelve_configured_problem_rooms_with_final_boss() -> void:
	var dungeon: DungeonDefinition = _load_problem_dungeon()

	assert_object(dungeon).is_not_null()
	assert_bool(dungeon.is_configured()).is_true()
	assert_str(String(dungeon.id)).is_equal("problem_dungeon")
	assert_str(dungeon.display_name).is_equal("问心秘境")
	assert_int(dungeon.get_room_count()).is_equal(12)

	var boss_count: int = 0
	var covered_tags: Array[int] = []
	for index: int in dungeon.get_room_count():
		var room: DungeonRoom = dungeon.get_room(index)
		assert_object(room).is_not_null()
		assert_bool(room.is_problem_configured()).is_true()
		assert_bool(room.has_declared_problems()).is_true()
		assert_bool(room.matches_encounter_problems()).is_true()
		for tag: int in room.get_problem_tags():
			if not covered_tags.has(tag):
				covered_tags.append(tag)
		if room.is_boss:
			boss_count += 1
	covered_tags.sort()
	assert_int(boss_count).is_equal(1)
	assert_int(dungeon.get_boss_index()).is_equal(dungeon.get_room_count() - 1)
	# 六类问题都必须真实出现在房间链里，而不是只在枚举里存在。
	assert_array(covered_tags).contains_exactly([1, 2, 3, 4, 5, 6])


func test_problem_dungeon_rewards_are_monotonic_and_boss_is_highest() -> void:
	var dungeon: DungeonDefinition = _load_problem_dungeon()
	var previous: int = -1
	var expected_total: int = 0

	for index: int in dungeon.get_room_count():
		var reward: int = dungeon.get_room_reward(index)
		assert_int(reward).is_greater_equal(previous)
		previous = reward
		expected_total += reward
	assert_int(dungeon.get_room_reward(dungeon.get_room_count() - 1)).is_greater(
		dungeon.get_room_reward(0)
	)
	assert_int(dungeon.get_max_reward()).is_equal(expected_total)


## 「遇到问题 → 获得技能 → 后续房间再次需要该技能」：至少 3 次因果，当前数据应形成 6 次。
func test_problem_dungeon_skill_reward_chain_feeds_later_rooms() -> void:
	var dungeon: DungeonDefinition = _load_problem_dungeon()
	var causal_links: int = 0
	for index: int in dungeon.get_room_count():
		var reward_room: DungeonRoom = dungeon.get_room(index)
		if reward_room == null or not reward_room.encounter.has_first_clear_reward():
			continue
		var axis: StringName = _skill_value_axis(reward_room.encounter.first_clear_skill_reward)
		assert_str(String(axis)).is_not_equal("none")
		var used_later: bool = false
		for later_index: int in range(index + 1, dungeon.get_room_count()):
			var later_room: DungeonRoom = dungeon.get_room(later_index)
			if later_room != null and later_room.get_required_value_axes().has(axis):
				used_later = true
				break
		assert_bool(used_later).is_true()
		if used_later:
			causal_links += 1
	assert_int(causal_links).is_greater_equal(3)


## 问题房间只引用正式敌人档案与首通技能，不引入随机掉落 / 装备 / 属性膨胀等第二变量。
func test_problem_rooms_use_formal_squads_and_have_no_extra_reward_sources() -> void:
	var dungeon: DungeonDefinition = _load_problem_dungeon()
	var reward_rooms: int = 0
	for index: int in dungeon.get_room_count():
		var room: DungeonRoom = dungeon.get_room(index)
		assert_object(room).is_not_null()
		assert_object(room.encounter).is_not_null()
		assert_int(room.encounter.get_requested_player_count()).is_equal(1)
		if room.is_boss:
			# 终局 Boss 仍使用单敌人档案；问题房间本体只允许队伍引用正式敌人。
			assert_object(room.encounter.enemy_profile).is_not_null()
		else:
			assert_bool(room.encounter.uses_enemy_squad()).is_true()
			assert_object(room.encounter.enemy_profile).is_null()
		for member: PawnData in room.encounter.get_enemy_members():
			assert_object(member).is_not_null()
			assert_str(member.resource_path).starts_with(ENEMY_DATA_PREFIX)
			assert_bool(member.problem_tag != PawnData.ProblemTag.NONE).is_true()
		if room.encounter.has_first_clear_reward():
			reward_rooms += 1
	# 只有前六间承担「遇到问题 → 获得技能」的解锁节奏，后六间只复用已解锁能力。
	assert_int(reward_rooms).is_equal(6)


## 问题标签读取必须过滤 NONE / 越界值并去重排序，行为与敌人侧映射解耦。
func test_problem_tags_are_normalized_and_filtered() -> void:
	var room: DungeonRoom = DungeonRoom.new()
	room.problem_tags = [0, 2, 2, 99, 1, 5]
	room.problem_tags.append(PawnData.ProblemTag.SUMMON_REINFORCEMENT)
	assert_array(room.get_problem_tags()).contains_exactly([1, 2, 5, 6])
	assert_array(room.get_problem_labels()).contains_exactly([
		"近战持续压力",
		"远程压制",
		"蓄力可打断",
		"召唤增援",
	])
	assert_array(room.get_required_value_axes()).contains_exactly([
		&"single_target_damage",
		&"dash",
		&"control",
		&"area_damage",
	])


## 奖励技能 → 玩家价值轴；与 `PawnData.get_skill_value_axis_for()` 的问题型映射保持同一套词汇。
func _skill_value_axis(skill: ActiveSkillDefinition) -> StringName:
	if skill == null:
		return &"none"
	match skill.effect_type:
		ActiveSkillDefinition.SkillEffectType.DAMAGE:
			return &"single_target_damage"
		ActiveSkillDefinition.SkillEffectType.SHIELD, ActiveSkillDefinition.SkillEffectType.HEAL:
			return &"defense"
		ActiveSkillDefinition.SkillEffectType.STUN:
			return &"control"
		ActiveSkillDefinition.SkillEffectType.DASH:
			return &"dash"
		ActiveSkillDefinition.SkillEffectType.AOE_DAMAGE:
			return &"area_damage"
		ActiveSkillDefinition.SkillEffectType.LIFESTEAL:
			return &"lifesteal"
		_:
			return &"none"
