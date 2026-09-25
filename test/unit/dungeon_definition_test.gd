extends GdUnitTestSuite

## 单元层：秘境房间链定义（INC-WORLD-003）。
##
## 锁定「一个秘境 = 有序房间链 + 终局 Boss」的数据契约：
## 房间 / 秘境资源只读，越界安全，奖励随深度递增，Boss 恰好在最后一间，
## 且所有敌人都来自 game/pawns/data/ 的正式档案而不是在房间里复制数值。

const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"
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
