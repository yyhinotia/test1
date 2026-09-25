extends GdUnitTestSuite

## 单元层（纯逻辑）：队伍静态契约（INC-PAWNS-020）。
##
## 锁定「一支队伍 = id + 有序成员档案 + 可选显式站位」这一数据契约：
## 队伍资源只读、校验结果可解释、站位不足时由运行时生成安全默认阵型，
## 且任何非法配置都必须在 is_configured() 处被拒绝，而不是留到运行时崩溃。

const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"


func _member(member_id: StringName, display_name: String = "成员") -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = member_id
	data.display_name = display_name
	return data


func _squad(member_ids: Array) -> SquadDefinition:
	var squad: SquadDefinition = SquadDefinition.new()
	squad.id = &"test_squad"
	squad.display_name = "测试队伍"
	var members: Array[PawnData] = []
	for member_id: Variant in member_ids:
		members.append(_member(StringName(member_id)))
	squad.members = members
	return squad


func test_empty_squad_is_not_configured_with_reason() -> void:
	var squad: SquadDefinition = SquadDefinition.new()

	assert_bool(squad.is_configured()).is_false()
	assert_int(squad.get_member_count()).is_zero()
	assert_bool(squad.get_configuration_errors().has("成员不能为空")).is_true()


func test_configured_squad_accepts_one_to_four_unique_members() -> void:
	for count: int in range(1, SquadDefinition.MAX_MEMBERS + 1):
		var ids: Array = []
		for index: int in range(count):
			ids.append("member_%d" % index)
		var squad: SquadDefinition = _squad(ids)

		assert_bool(squad.is_configured()).is_true()
		assert_int(squad.get_member_count()).is_equal(count)
		assert_int(squad.get_member_ids().size()).is_equal(count)
		assert_array(squad.get_configuration_errors()).is_empty()


func test_duplicate_member_ids_are_rejected() -> void:
	var squad: SquadDefinition = _squad(["dup", "dup"])

	assert_bool(squad.is_configured()).is_false()
	assert_bool(squad.get_configuration_errors().has("成员 id 重复：dup")).is_true()


func test_member_with_empty_id_is_rejected() -> void:
	var squad: SquadDefinition = _squad(["ok", &""])

	assert_bool(squad.is_configured()).is_false()
	assert_bool(squad.get_configuration_errors().has("第 1 位成员缺少 id")).is_true()


func test_null_member_profile_is_rejected() -> void:
	var squad: SquadDefinition = SquadDefinition.new()
	squad.id = &"null_member_squad"
	var members: Array[PawnData] = []
	members.append(null)
	squad.members = members

	assert_bool(squad.is_configured()).is_false()
	assert_bool(squad.get_configuration_errors().has("第 0 位成员档案为空")).is_true()


func test_more_than_four_members_is_rejected() -> void:
	var ids: Array = []
	for index: int in range(SquadDefinition.MAX_MEMBERS + 1):
		ids.append("member_%d" % index)
	var squad: SquadDefinition = _squad(ids)

	assert_bool(squad.is_configured()).is_false()
	assert_bool(squad.get_configuration_errors().has("成员数量不能超过 4")).is_true()


func test_explicit_spawn_offsets_must_match_member_count() -> void:
	var squad: SquadDefinition = _squad(["alpha", "beta"])
	var offsets: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.0, 64.0)]
	squad.default_spawn_offsets = offsets

	assert_bool(squad.is_configured()).is_true()
	assert_int(squad.get_spawn_offsets().size()).is_equal(2)

	var mismatched: Array[Vector2] = [Vector2(0.0, 0.0)]
	squad.default_spawn_offsets = mismatched

	assert_bool(squad.is_configured()).is_false()
	assert_bool(squad.get_configuration_errors().has("默认站位数量与成员数量不一致")).is_true()


func test_missing_spawn_offsets_generate_a_non_overlapping_formation() -> void:
	var squad: SquadDefinition = _squad(["alpha", "beta", "gamma", "delta"])

	assert_array(squad.default_spawn_offsets).is_empty()
	var offsets: Array[Vector2] = squad.get_spawn_offsets()

	assert_int(offsets.size()).is_equal(4)
	assert_float(offsets[0].x).is_zero()
	assert_float(offsets[0].y).is_zero()
	# 默认阵型必须互不重叠，否则 4 个单位会叠在同一个点上。
	assert_int(_unique_count(offsets)).is_equal(4)


func test_default_offsets_are_pure_and_handle_edge_counts() -> void:
	assert_array(SquadDefinition.build_default_offsets(0)).is_empty()
	assert_array(SquadDefinition.build_default_offsets(-3)).is_empty()
	assert_int(SquadDefinition.build_default_offsets(1).size()).is_equal(1)
	assert_int(SquadDefinition.build_default_offsets(SquadDefinition.MAX_MEMBERS).size()).is_equal(4)


func test_member_lookup_and_slice_preserve_order() -> void:
	var squad: SquadDefinition = _squad(["alpha", "beta", "gamma"])

	assert_str(String(squad.get_member_by_id(&"beta").id)).is_equal("beta")
	assert_object(squad.get_member_by_id(&"missing")).is_null()
	assert_bool(squad.has_member_id(&"gamma")).is_true()
	assert_bool(squad.has_member_id(&"")).is_false()

	var slice: Array[PawnData] = squad.get_member_slice(2)
	assert_int(slice.size()).is_equal(2)
	assert_str(String(slice[0].id)).is_equal("alpha")
	assert_str(String(slice[1].id)).is_equal("beta")
	assert_int(squad.get_member_slice(99).size()).is_equal(3)
	assert_array(squad.get_member_slice(0)).is_empty()


func test_two_squad_instances_do_not_share_fields() -> void:
	var first: SquadDefinition = SquadDefinition.new()
	var second: SquadDefinition = SquadDefinition.new()
	first.display_name = "改动过的队伍"
	var members: Array[PawnData] = [_member(&"solo")]
	first.members = members

	assert_str(second.display_name).is_equal("队伍")
	assert_array(second.members).is_empty()
	assert_array(second.default_spawn_offsets).is_empty()


func test_official_player_profile_can_be_a_squad_member() -> void:
	var player_data: PawnData = load(PLAYER_DATA_PATH) as PawnData
	var squad: SquadDefinition = _squad([])
	var members: Array[PawnData] = [player_data]
	squad.members = members

	assert_object(player_data).is_not_null()
	assert_bool(squad.is_configured()).is_true()
	assert_object(squad.get_member_by_id(player_data.id)).is_same(player_data)


func _unique_count(values: Array) -> int:
	var unique: Array = []
	for value: Variant in values:
		if not unique.has(value):
			unique.append(value)
	return unique.size()
