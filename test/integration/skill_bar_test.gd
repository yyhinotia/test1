extends GdUnitTestSuite

## 集成层：SkillBar 的容量驱动槽位、空槽快捷键、信号转发与只读刷新。
## 槽位数量只由 RealmDefinition 的主动技能容量决定，不为任何境界创建专用 UI 分支。

const BAR_SCENE_PATH: String = "res://game/ui/skill_bar.tscn"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const QI_REFINING_REALM_PATH: String = "res://game/cultivation/data/realms/qi_refining.tres"
const APPROX: float = 0.001


func _spawn_bar() -> SkillBar:
	var scene: PackedScene = load(BAR_SCENE_PATH)
	var bar: SkillBar = scene.instantiate() as SkillBar
	auto_free(bar)
	add_child(bar)
	return bar


func _spawn_pawn(data_override: PawnData) -> Pawn:
	var scene: PackedScene = load(PLAYER_PAWN_SCENE_PATH)
	var pawn: Pawn = scene.instantiate() as Pawn
	pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _make_skill(index: int, cost: float = 10.0, cooldown: float = 2.0) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = StringName("skill_%d" % index)
	skill.display_name = "技能%d" % index
	skill.spirit_cost = cost
	skill.cooldown = cooldown
	skill.cast_range = 110.0
	skill.damage_multiplier = 1.0
	return skill


func _make_data_for_capacity(capacity: int, skill_count: int) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	var realm: RealmDefinition = (load(QI_REFINING_REALM_PATH) as RealmDefinition).duplicate(true) as RealmDefinition
	realm.active_skill_slots = capacity
	data.realm = realm
	data.max_spirit = 100.0
	data.initial_spirit_ratio = 1.0
	data.active_skill = null
	var skills: Array[ActiveSkillDefinition] = []
	for index: int in range(skill_count):
		skills.append(_make_skill(index + 1))
	data.active_skills = skills
	return data


func test_capacity_drives_two_to_six_slots_and_empty_slots_keep_hotkeys() -> void:
	for capacity: int in range(2, 7):
		var bar: SkillBar = _spawn_bar()
		var pawn: Pawn = _spawn_pawn(_make_data_for_capacity(capacity, 1))
		await await_idle_frame()
		bar.bind_pawn(pawn)

		assert_int(bar.get_slot_count()).is_equal(capacity)
		var slots: Array[SkillSlot] = bar.get_slots()
		for index: int in capacity:
			var slot: SkillSlot = slots[index]
			assert_str((slot.get_node("HotkeyLabel") as Label).text).is_equal(str(index + 1))
			if index == 0:
				assert_bool(slot.has_skill()).is_true()
			else:
				assert_bool(slot.has_skill()).is_false()
				assert_str(String(slot.get_snapshot()["state_name"])).is_equal("EMPTY")
		bar.unbind()


func test_configured_skills_are_bound_in_order() -> void:
	var bar: SkillBar = _spawn_bar()
	var pawn: Pawn = _spawn_pawn(_make_data_for_capacity(3, 3))
	await await_idle_frame()
	bar.bind_pawn(pawn)

	var slots: Array[SkillSlot] = bar.get_slots()
	for index: int in 3:
		var expected: ActiveSkillDefinition = pawn.data.get_active_skills()[index]
		assert_object(slots[index].get_skill()).is_same(expected)
		assert_str((slots[index].get_node("Icon") as Label).text).is_equal("技")


## 点击槽位的路由（INC-UI-012 起）：需要目标的技能进入 TARGETING，SELF 技能才直接转发施法请求。
func test_slot_click_is_routed_to_targeting_or_direct_request() -> void:
	var bar: SkillBar = _spawn_bar()
	var pawn: Pawn = _spawn_pawn(_make_data_for_capacity(2, 2))
	await await_idle_frame()
	bar.bind_pawn(pawn)

	var requests: Array[ActiveSkillDefinition] = []
	var targeting: Array[ActiveSkillDefinition] = []
	bar.skill_requested.connect(func(skill: ActiveSkillDefinition) -> void: requests.append(skill))
	bar.targeting_started.connect(func(skill: ActiveSkillDefinition) -> void: targeting.append(skill))

	var enemy_skill: ActiveSkillDefinition = pawn.data.get_active_skills()[0]
	var self_skill: ActiveSkillDefinition = pawn.data.get_active_skills()[1]
	self_skill.target_type = ActiveSkillDefinition.SkillTargetType.SELF

	# 默认 ENEMY 技能：只进入目标选择，不直接请求施法。
	bar.get_slots()[0].cast_requested.emit(enemy_skill)
	assert_int(requests.size()).is_zero()
	assert_int(targeting.size()).is_equal(1)
	assert_object(targeting[0]).is_same(enemy_skill)
	assert_bool(bar.is_targeting()).is_true()

	# SELF 技能：跳过目标选择，直接请求施法。
	bar.get_slots()[1].cast_requested.emit(self_skill)
	assert_int(requests.size()).is_equal(1)
	assert_object(requests[0]).is_same(self_skill)
	assert_bool(bar.is_targeting()).is_false()


func test_spirit_change_refreshes_slot_to_no_resource() -> void:
	var bar: SkillBar = _spawn_bar()
	var pawn: Pawn = _spawn_pawn(_make_data_for_capacity(2, 1))
	await await_idle_frame()
	bar.bind_pawn(pawn)

	var slot: SkillSlot = bar.get_slots()[0]
	assert_str(String(slot.get_snapshot()["state_name"])).is_equal("READY")
	pawn.try_spend_spirit(pawn.current_spirit)
	assert_str(String(slot.get_snapshot()["state_name"])).is_equal("NO_RESOURCE")


func test_unbind_clears_slots_and_hides_bar() -> void:
	var bar: SkillBar = _spawn_bar()
	var pawn: Pawn = _spawn_pawn(_make_data_for_capacity(4, 2))
	await await_idle_frame()
	bar.bind_pawn(pawn)
	assert_int(bar.get_slot_count()).is_equal(4)

	bar.unbind()
	assert_int(bar.get_slot_count()).is_zero()
	assert_bool(bar.visible).is_false()
	assert_object(bar.get_bound_pawn()).is_null()
