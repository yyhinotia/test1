extends GdUnitTestSuite

## 单元层：SkillSlot 状态模型的纯逻辑边界；不实例化 Pawn，也不修改任何运行时状态。

const APPROX: float = 0.001


func _make_skill(cost: float, cooldown: float) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = &"test_skill"
	skill.display_name = "测试技能"
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	return skill


func test_empty_skill_returns_empty_state() -> void:
	var snapshot: Dictionary = SkillSlotState.evaluate(null, 0.0, 100.0, true)
	assert_str(String(snapshot["state_name"])).is_equal("EMPTY")
	assert_bool(snapshot["can_cast"]).is_false()
	assert_float(snapshot["cooldown_ratio"]).is_zero()


func test_cooldown_uses_true_remaining_ratio() -> void:
	var skill: ActiveSkillDefinition = _make_skill(20.0, 8.0)
	var snapshot: Dictionary = SkillSlotState.evaluate(skill, 4.0, 100.0, true)

	assert_str(String(snapshot["state_name"])).is_equal("COOLDOWN")
	assert_float(snapshot["cooldown_remaining"]).is_equal_approx(4.0, APPROX)
	assert_float(snapshot["cooldown_total"]).is_equal_approx(8.0, APPROX)
	assert_float(snapshot["cooldown_ratio"]).is_equal_approx(0.5, APPROX)
	assert_bool(snapshot["can_cast"]).is_false()


func test_full_cooldown_is_ratio_one_and_finished_is_zero() -> void:
	var skill: ActiveSkillDefinition = _make_skill(0.0, 4.0)
	var full: Dictionary = SkillSlotState.evaluate(skill, 4.0, 100.0, true)
	var finished: Dictionary = SkillSlotState.evaluate(skill, 0.0, 100.0, true)

	assert_float(full["cooldown_ratio"]).is_equal_approx(1.0, APPROX)
	assert_float(finished["cooldown_ratio"]).is_zero()
	assert_str(String(finished["state_name"])).is_equal("READY")


func test_no_resource_wins_even_when_cooldown_is_ready() -> void:
	var skill: ActiveSkillDefinition = _make_skill(30.0, 2.0)
	var snapshot: Dictionary = SkillSlotState.evaluate(skill, 0.0, 29.99, true)

	assert_str(String(snapshot["state_name"])).is_equal("NO_RESOURCE")
	assert_bool(snapshot["can_cast"]).is_false()
	assert_bool(String(snapshot["reason"]).contains("灵力不足")).is_true()

	var exact: Dictionary = SkillSlotState.evaluate(skill, 0.0, 30.0, true)
	assert_str(String(exact["state_name"])).is_equal("READY")


func test_dead_unit_and_invalid_definition_are_disabled() -> void:
	var skill: ActiveSkillDefinition = _make_skill(0.0, 1.0)
	var dead: Dictionary = SkillSlotState.evaluate(skill, 0.0, 100.0, false)
	skill.id = &""
	var invalid: Dictionary = SkillSlotState.evaluate(skill, 0.0, 100.0, true)

	assert_str(String(dead["state_name"])).is_equal("DISABLED")
	assert_str(String(invalid["state_name"])).is_equal("DISABLED")
	assert_bool(dead["can_cast"]).is_false()


func test_interaction_state_names_are_reserved_for_ui() -> void:
	assert_str(String(SkillSlotState.state_name(SkillSlotState.State.SELECTED))).is_equal("SELECTED")
	assert_str(String(SkillSlotState.state_name(SkillSlotState.State.TARGETING))).is_equal("TARGETING")
