extends GdUnitTestSuite

## 单元层：Pawn 的运行时主动技能装配层（INC-PAWNS-021）。
## 「已掌握」与「已装配」是两份独立事实：解锁不等于装备，重配失败必须零副作用，
## 未重配单位必须保持旧行为（完全沿用 PawnData 预设）。


func _make_skill(id: StringName) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	skill.spirit_cost = 10.0
	skill.cooldown = 2.0
	return skill


func _make_realm(capacity: int) -> RealmDefinition:
	var realm: RealmDefinition = RealmDefinition.new()
	realm.id = &"loadout_test_realm"
	realm.display_name = "装配测试境界"
	realm.active_skill_slots = capacity
	return realm


func _make_data(realm: RealmDefinition, skills: Array[ActiveSkillDefinition]) -> PawnData:
	var data: PawnData = PawnData.new()
	data.id = &"loadout_test_pawn"
	data.realm = realm
	data.active_skill = skills[0] if not skills.is_empty() else null
	data.active_skills = skills
	return data


func _make_pawn(data: PawnData) -> Pawn:
	var pawn: Pawn = Pawn.new()
	pawn.data = data
	auto_free(pawn)
	return pawn


func _record_build_changes(pawn: Pawn) -> Array[Pawn]:
	var changes: Array[Pawn] = []
	pawn.build_changed.connect(func(changed: Pawn) -> void: changes.append(changed))
	return changes


func test_learn_active_skill_unlocks_without_auto_equipping() -> void:
	var preset: ActiveSkillDefinition = _make_skill(&"preset")
	var learned: ActiveSkillDefinition = _make_skill(&"binding")
	var preset_skills: Array[ActiveSkillDefinition] = [preset]
	var data: PawnData = _make_data(_make_realm(2), preset_skills)
	var pawn: Pawn = _make_pawn(data)
	var changes: Array[Pawn] = _record_build_changes(pawn)

	assert_bool(pawn.learn_active_skill(learned)).is_true()

	assert_array(pawn.get_known_active_skills() as Array).contains_exactly([preset, learned])
	assert_array(pawn.get_learned_active_skills() as Array).contains_exactly([learned])
	assert_bool(pawn.has_learned_active_skill(&"binding")).is_true()
	assert_bool(pawn.is_active_skill_known(learned)).is_true()
	assert_bool(pawn.is_active_skill_known(preset)).is_true()
	# 解锁不等于装备：未重配时生效列表仍然只有静态预设。
	assert_array(pawn.get_equipped_active_skills() as Array).contains_exactly([preset])
	assert_array(pawn.get_enabled_active_skills() as Array).contains_exactly([preset])
	assert_int(changes.size()).is_equal(1)
	# 静态资源不被改写。
	assert_int(data.active_skills.size()).is_equal(1)
	assert_object(data.active_skills[0]).is_same(preset)


func test_learn_active_skill_rejects_invalid_and_duplicate_skills() -> void:
	var preset: ActiveSkillDefinition = _make_skill(&"preset")
	var binding: ActiveSkillDefinition = _make_skill(&"binding")
	var twin: ActiveSkillDefinition = _make_skill(&"binding")
	var unconfigured: ActiveSkillDefinition = _make_skill(&"")
	var preset_skills: Array[ActiveSkillDefinition] = [preset]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(2), preset_skills))
	var changes: Array[Pawn] = _record_build_changes(pawn)

	assert_bool(pawn.learn_active_skill(null)).is_false()
	assert_bool(pawn.learn_active_skill(unconfigured)).is_false()
	assert_bool(pawn.learn_active_skill(binding)).is_true()
	# 同一实例、同 id 的不同实例与已在静态预设中的技能都必须被拒绝。
	assert_bool(pawn.learn_active_skill(binding)).is_false()
	assert_bool(pawn.learn_active_skill(twin)).is_false()
	assert_bool(pawn.learn_active_skill(preset)).is_false()
	assert_int(changes.size()).is_equal(1)
	assert_array(pawn.get_known_active_skills() as Array).contains_exactly([preset, binding])


func test_unconfigured_pawn_keeps_preset_projection_and_known_list() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"preset_a")
	var second: ActiveSkillDefinition = _make_skill(&"preset_b")
	var preset_skills: Array[ActiveSkillDefinition] = [first, second]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(2), preset_skills))
	var changes: Array[Pawn] = _record_build_changes(pawn)

	assert_array(pawn.get_known_active_skills() as Array).contains_exactly([first, second])
	assert_array(pawn.get_equipped_active_skills() as Array).contains_exactly([first, second])
	assert_array(pawn.get_enabled_active_skills() as Array).contains_exactly([first, second])
	assert_array(pawn.get_build_loadout().active_skills as Array).contains_exactly([first, second])
	assert_int(changes.size()).is_zero()


func test_set_active_skill_loadout_switches_projection_and_loadout() -> void:
	var sword: ActiveSkillDefinition = _make_skill(&"sword_strike")
	var guard: ActiveSkillDefinition = _make_skill(&"guard")
	var binding: ActiveSkillDefinition = _make_skill(&"binding")
	var preset_skills: Array[ActiveSkillDefinition] = [sword, guard]
	var data: PawnData = _make_data(_make_realm(2), preset_skills)
	var pawn: Pawn = _make_pawn(data)
	assert_bool(pawn.learn_active_skill(binding)).is_true()
	var changes: Array[Pawn] = _record_build_changes(pawn)

	var target: Array[ActiveSkillDefinition] = [sword, binding]
	assert_bool(pawn.set_active_skill_loadout(target)).is_true()

	assert_array(pawn.get_equipped_active_skills() as Array).contains_exactly([sword, binding])
	assert_array(pawn.get_enabled_active_skills() as Array).contains_exactly([sword, binding])
	assert_array(pawn.get_build_loadout().active_skills as Array).contains_exactly([sword, binding])
	assert_int(pawn.get_active_skill_slot_index(binding)).is_equal(1)
	assert_bool(pawn.is_active_skill_enabled(guard)).is_false()
	assert_int(changes.size()).is_equal(1)
	# 已掌握集合不受装配影响；静态档案仍保持原状。
	assert_array(pawn.get_known_active_skills() as Array).contains_exactly([sword, guard, binding])
	assert_int(data.active_skills.size()).is_equal(2)
	assert_object(data.active_skills[0]).is_same(sword)


func test_set_active_skill_loadout_rejects_unknown_skill_with_zero_side_effects() -> void:
	var preset: ActiveSkillDefinition = _make_skill(&"preset")
	var learned: ActiveSkillDefinition = _make_skill(&"binding")
	var unknown: ActiveSkillDefinition = _make_skill(&"never_learned")
	var preset_skills: Array[ActiveSkillDefinition] = [preset]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(2), preset_skills))
	assert_bool(pawn.learn_active_skill(learned)).is_true()
	var changes: Array[Pawn] = _record_build_changes(pawn)

	var target: Array[ActiveSkillDefinition] = [unknown]
	assert_bool(pawn.set_active_skill_loadout(target)).is_false()

	assert_array(pawn.get_equipped_active_skills() as Array).contains_exactly([preset])
	assert_array(pawn.get_enabled_active_skills() as Array).contains_exactly([preset])
	assert_int(changes.size()).is_zero()


func test_set_active_skill_loadout_rejects_over_capacity_and_duplicate_entries() -> void:
	var first: ActiveSkillDefinition = _make_skill(&"first")
	var second: ActiveSkillDefinition = _make_skill(&"second")
	var third: ActiveSkillDefinition = _make_skill(&"third")
	var preset_skills: Array[ActiveSkillDefinition] = [first, second]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(2), preset_skills))
	assert_bool(pawn.learn_active_skill(third)).is_true()
	var changes: Array[Pawn] = _record_build_changes(pawn)

	var over_capacity: Array[ActiveSkillDefinition] = [first, second, third]
	assert_bool(pawn.set_active_skill_loadout(over_capacity)).is_false()
	var duplicated: Array[ActiveSkillDefinition] = [first, first]
	assert_bool(pawn.set_active_skill_loadout(duplicated)).is_false()

	assert_array(pawn.get_equipped_active_skills() as Array).contains_exactly([first, second])
	assert_int(changes.size()).is_zero()


func test_explicit_empty_loadout_differs_from_never_configured() -> void:
	var preset: ActiveSkillDefinition = _make_skill(&"preset")
	var preset_skills: Array[ActiveSkillDefinition] = [preset]
	var pawn: Pawn = _make_pawn(_make_data(_make_realm(0), preset_skills))
	var empty: Array[ActiveSkillDefinition] = []

	assert_bool(pawn.set_active_skill_loadout(empty)).is_true()
	assert_array(pawn.get_equipped_active_skills() as Array).is_empty()
	assert_array(pawn.get_enabled_active_skills() as Array).is_empty()
	# 显式清空后不得回退静态预设；容量 0 时任何非空装配都必须被拒绝。
	var attempt: Array[ActiveSkillDefinition] = [preset]
	assert_bool(pawn.set_active_skill_loadout(attempt)).is_false()
	assert_array(pawn.get_equipped_active_skills() as Array).is_empty()
	assert_array(pawn.get_known_active_skills() as Array).contains_exactly([preset])