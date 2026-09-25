extends GdUnitTestSuite

## 单元层：Pawn 的主动技能容量投影只依赖 PawnData / RealmDefinition，不实例化场景节点。
## 覆盖容量 0 / 1 / 2 / 4、重复技能、超容量与无境界兼容；完整 Build 列表仍供 Validator 诊断。


func _make_skill(id: StringName) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	return skill


func _make_realm(capacity: int) -> RealmDefinition:
	var realm: RealmDefinition = RealmDefinition.new()
	realm.id = &"test_realm"
	realm.display_name = "测试境界"
	realm.active_skill_slots = capacity
	return realm


func _make_data(realm: RealmDefinition, skills: Array[ActiveSkillDefinition]) -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = &"test_pawn"
	data.realm = realm
	data.active_skill = skills[0] if not skills.is_empty() else null
	data.active_skills = skills
	return data


func _make_pawn(data: PawnData) -> Pawn:
	var pawn: Pawn = Pawn.new()
	pawn.data = data
	auto_free(pawn)
	return pawn


func test_capacity_zero_disables_all_skills_but_keeps_full_loadout() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"first")
	var second: ActiveSkillDefinition = _make_skill(&"second")
	var skills: Array[ActiveSkillDefinition] = [first, second]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(0), skills))

	assert_int(pawn.get_active_skill_capacity()).is_zero()
	assert_array(pawn.get_enabled_active_skills() as Array).is_empty()
	assert_int(pawn.get_active_skill_slot_index(first)).is_equal(-1)
	assert_bool(pawn.is_active_skill_enabled(first)).is_false()
	assert_int(pawn.get_build_loadout().get_used_slots(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(2)
	assert_int(pawn.get_build_loadout().get_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_zero()
	assert_array(pawn.get_build_validation().get_error_codes() as Array).contains_exactly([
		BuildValidationResult.CODE_OVER_CAPACITY,
	])


func test_capacity_projection_returns_ordered_prefix_for_0_1_2_4() -> void:
	var skills: Array[ActiveSkillDefinition] = [
		_make_skill(&"skill_a"),
		_make_skill(&"skill_b"),
		_make_skill(&"skill_c"),
		_make_skill(&"skill_d"),
	]
	for capacity: int in [0, 1, 2, 4]:
		var pawn: Pawn = _make_pawn(_make_data(_make_realm(capacity), skills))
		var enabled: Array[ActiveSkillDefinition] = pawn.get_enabled_active_skills()
		var expected_count: int = mini(capacity, skills.size())
		assert_int(enabled.size()).is_equal(expected_count)
		for index: int in expected_count:
			assert_object(enabled[index]).is_same(skills[index])
			assert_int(pawn.get_active_skill_slot_index(skills[index])).is_equal(index)
		for index: int in range(expected_count, skills.size()):
			assert_int(pawn.get_active_skill_slot_index(skills[index])).is_equal(-1)


func test_duplicates_are_deduplicated_in_projection_but_not_validator_source() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"duplicate")
	var second: ActiveSkillDefinition = _make_skill(&"second")
	var skills: Array[ActiveSkillDefinition] = [first, first, second]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(1), skills))

	assert_array(pawn.get_enabled_active_skills() as Array).contains_exactly([first])
	assert_int(pawn.get_build_loadout().get_used_slots(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(3)
	var codes: Array[StringName] = pawn.get_build_validation().get_error_codes()
	assert_bool(codes.has(BuildValidationResult.CODE_DUPLICATE_ENTRY)).is_true()
	assert_bool(codes.has(BuildValidationResult.CODE_OVER_CAPACITY)).is_true()


func test_no_realm_uses_unbounded_capacity_and_keeps_native_skills() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"native_a")
	var second: ActiveSkillDefinition = _make_skill(&"native_b")
	var third: ActiveSkillDefinition = _make_skill(&"native_c")
	var skills: Array[ActiveSkillDefinition] = [first, second, third]
	var pawn: Pawn = _make_pawn(_make_data(null, skills))

	assert_int(pawn.get_active_skill_capacity()).is_equal(Pawn.ACTIVE_SKILL_CAPACITY_UNBOUNDED)
	assert_int(pawn.get_enabled_active_skills().size()).is_equal(3)
	for index: int in skills.size():
		assert_object(pawn.get_enabled_active_skills()[index]).is_same(skills[index])
		assert_int(pawn.get_active_skill_slot_index(skills[index])).is_equal(index)
	assert_array(pawn.get_build_validation().get_error_codes() as Array).contains_exactly([
		BuildValidationResult.CODE_MISSING_REALM,
	])


func test_projection_queries_do_not_mutate_or_share_data_source() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"readonly_a")
	var second: ActiveSkillDefinition = _make_skill(&"readonly_b")
	var skills: Array[ActiveSkillDefinition] = [first, second]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(2), skills))
	var enabled: Array[ActiveSkillDefinition] = pawn.get_enabled_active_skills()
	enabled.clear()

	assert_int(pawn.data.active_skills.size()).is_equal(2)
	assert_int(pawn.get_enabled_active_skills().size()).is_equal(2)
	assert_int(pawn.get_active_skill_capacity()).is_equal(2)
