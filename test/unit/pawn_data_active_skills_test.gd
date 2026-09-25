extends GdUnitTestSuite

## 单元层：PawnData 多主动技能列表的顺序、去重与旧字段回退契约。

const APPROX: float = 0.001


func _make_skill(id: StringName, display_name: String, cost: float, cooldown: float, cast_range: float) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = display_name
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	skill.cast_range = cast_range
	return skill


func test_active_skills_uses_order_and_deduplicates_by_id() -> void:
	var data: PawnData = PawnData.new()
	var first: ActiveSkillDefinition = _make_skill(&"first", "第一式", 10.0, 1.0, 50.0)
	var second: ActiveSkillDefinition = _make_skill(&"second", "第二式", 20.0, 2.0, 80.0)
	var duplicate: ActiveSkillDefinition = _make_skill(&"first", "重复式", 99.0, 9.0, 999.0)
	data.active_skill = first
	var skills: Array[ActiveSkillDefinition] = []
	skills.append(first)
	skills.append(second)
	skills.append(duplicate)
	data.active_skills = skills

	var result: Array[ActiveSkillDefinition] = data.get_active_skills()
	assert_int(result.size()).is_equal(2)
	assert_object(result[0]).is_same(first)
	assert_object(result[1]).is_same(second)
	assert_object(data.get_primary_active_skill()).is_same(first)


func test_active_skills_falls_back_to_legacy_single_field() -> void:
	var data: PawnData = PawnData.new()
	var legacy: ActiveSkillDefinition = _make_skill(&"legacy", "旧式", 5.0, 0.5, 30.0)
	data.active_skill = legacy

	var result: Array[ActiveSkillDefinition] = data.get_active_skills()
	assert_int(result.size()).is_equal(1)
	assert_object(result[0]).is_same(legacy)
	assert_object(data.get_primary_active_skill()).is_same(legacy)


func test_active_skills_skips_null_and_unconfigured_entries() -> void:
	var data: PawnData = PawnData.new()
	var valid: ActiveSkillDefinition = _make_skill(&"valid", "有效", 0.0, 1.0, 40.0)
	var invalid: ActiveSkillDefinition = _make_skill(&"", "无效", 0.0, 1.0, 40.0)
	data.active_skill = valid
	var skills: Array[ActiveSkillDefinition] = []
	skills.append(null)
	skills.append(invalid)
	skills.append(valid)
	data.active_skills = skills

	var result: Array[ActiveSkillDefinition] = data.get_active_skills()
	assert_int(result.size()).is_equal(1)
	assert_object(result[0]).is_same(valid)
