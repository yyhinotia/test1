extends GdUnitTestSuite

## 集成层：宗门运行时（INC-SECT-002）。
##
## 用例在真实 `Pawn` 场景 + 六份正式设施资源上运行：不做任何数值伪造，
## 只通过 `SectState` 的对外契约（库存 getter、等级、原因、信号、快照）观察行为，
## 因此「秘境收益入账 → 升级扣费 → 打坐涨修为 → 灵田收草」这条链路是真实链路。

const APPROX: float = 0.001
const FACILITY_DIR: String = "res://game/sect/data/facilities"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"
const FACILITY_IDS: Array[String] = [
	"cave_dwelling",
	"spirit_array",
	"spirit_field",
	"alchemy_room",
	"forge_room",
	"scripture_pavilion",
]


func _load_facilities() -> Array[SectFacilityDefinition]:
	var result: Array[SectFacilityDefinition] = []
	for facility_id: String in FACILITY_IDS:
		var facility: SectFacilityDefinition = load("%s/%s.tres" % [FACILITY_DIR, facility_id])
		result.append(facility)
	return result


func _spawn_state() -> SectState:
	var state: SectState = SectState.new()
	state.name = "SectState"
	state.facilities = _load_facilities()
	auto_free(state)
	add_child(state)
	return state


func _spawn_player() -> Pawn:
	var scene: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	pawn.data = load(PLAYER_DATA_PATH) as PawnData
	auto_free(pawn)
	add_child(pawn)
	return pawn


## 宗门灵石的唯一外部来源是秘境收益；这里的「一轮」直接取正式秘境数据的满额值。
func _dungeon_max_reward() -> int:
	var dungeon: DungeonDefinition = load(DUNGEON_PATH) as DungeonDefinition
	return dungeon.get_max_reward()


func test_deposit_accepts_only_positive_amounts() -> void:
	var state: SectState = _spawn_state()
	var deposits: Array = []
	state.spirit_stones_changed.connect(func(_state: SectState, current: int) -> void:
		deposits.append(current)
	)

	assert_int(state.deposit_spirit_stones(0)).is_zero()
	assert_int(state.deposit_spirit_stones(-25)).is_zero()
	assert_int(state.get_spirit_stones()).is_zero()
	assert_array(deposits).is_empty()

	assert_int(state.deposit_spirit_stones(_dungeon_max_reward())).is_equal(_dungeon_max_reward())
	assert_int(state.get_spirit_stones()).is_equal(_dungeon_max_reward())
	assert_array(deposits).has_size(1)
	assert_int(int(deposits[0])).is_equal(_dungeon_max_reward())


func test_facilities_start_at_level_one_and_unknown_ids_stay_zero() -> void:
	var state: SectState = _spawn_state()

	for facility_id: String in FACILITY_IDS:
		assert_int(state.get_facility_level(StringName(facility_id))).is_equal(
			SectState.INITIAL_FACILITY_LEVEL
		)
		assert_int(state.get_upgrade_cost(StringName(facility_id))).is_greater(0)

	assert_int(state.get_facility_level(&"nonexistent_facility")).is_zero()
	assert_int(state.get_upgrade_cost(&"nonexistent_facility")).is_equal(
		SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE
	)
	assert_str(String(state.get_upgrade_block_reason(&"nonexistent_facility"))).is_equal(
		String(SectState.REASON_UNKNOWN_FACILITY)
	)


func test_upgrade_consumes_spirit_stones_and_reports_new_level() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.bind_cultivator(pawn)
	state.deposit_spirit_stones(_dungeon_max_reward())

	var events: Array = []
	state.facility_upgraded.connect(
		func(_state: SectState, facility_id: StringName, new_level: int) -> void:
			events.append({"id": facility_id, "level": new_level})
	)

	var cost: int = state.get_upgrade_cost(&"spirit_array")
	var before: int = state.get_spirit_stones()
	assert_int(cost).is_greater(0)
	assert_bool(state.can_upgrade_facility(&"spirit_array")).is_true()

	assert_bool(state.upgrade_facility(&"spirit_array")).is_true()
	assert_int(state.get_spirit_stones()).is_equal(before - cost)
	assert_int(state.get_facility_level(&"spirit_array")).is_equal(2)
	assert_array(events).has_size(1)
	assert_str(String(events[0]["id"])).is_equal("spirit_array")
	assert_int(int(events[0]["level"])).is_equal(2)


func test_upgrade_without_enough_spirit_stones_changes_nothing() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.bind_cultivator(pawn)
	state.deposit_spirit_stones(1)

	assert_str(String(state.get_upgrade_block_reason(&"forge_room"))).is_equal(
		String(SectState.REASON_NOT_ENOUGH_SPIRIT_STONES)
	)
	assert_bool(state.can_upgrade_facility(&"forge_room")).is_false()
	assert_bool(state.upgrade_facility(&"forge_room")).is_false()
	assert_int(state.get_spirit_stones()).is_equal(1)
	assert_int(state.get_facility_level(&"forge_room")).is_equal(1)


func test_upgrade_stops_at_max_level() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.bind_cultivator(pawn)
	state.deposit_spirit_stones(_dungeon_max_reward() * 10)

	var facility: SectFacilityDefinition = state.get_facility(&"spirit_field")
	assert_object(facility).is_not_null()
	for _level: int in range(SectState.INITIAL_FACILITY_LEVEL, facility.max_level):
		assert_bool(state.upgrade_facility(&"spirit_field")).is_true()

	assert_int(state.get_facility_level(&"spirit_field")).is_equal(facility.max_level)
	assert_str(String(state.get_upgrade_block_reason(&"spirit_field"))).is_equal(
		String(SectState.REASON_MAX_LEVEL)
	)
	assert_bool(state.upgrade_facility(&"spirit_field")).is_false()
	assert_int(state.get_upgrade_cost(&"spirit_field")).is_equal(
		SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE
	)


func test_upgrade_requires_cultivator_realm_tier() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.deposit_spirit_stones(_dungeon_max_reward() * 10)

	# 未绑定修士：境界视为 0，任何设施都不能升级。
	assert_str(String(state.get_upgrade_block_reason(&"cave_dwelling"))).is_equal(
		String(SectState.REASON_REALM_TOO_LOW)
	)
	assert_bool(state.upgrade_facility(&"cave_dwelling")).is_false()

	# 绑定炼气期修士后，六座 required_realm_tier = 1 的正式设施恢复可升级。
	state.bind_cultivator(pawn)
	assert_bool(state.can_upgrade_facility(&"cave_dwelling")).is_true()

	# 追加一座仅用于门槛断言的设施：炼气期修士（tier 1）不足以升级 tier 3 设施。
	var high_realm: SectFacilityDefinition = SectFacilityDefinition.new()
	high_realm.id = &"test_high_realm_facility"
	high_realm.display_name = "测试高境界设施"
	high_realm.required_realm_tier = 3
	high_realm.base_upgrade_cost = 10
	high_realm.max_level = 2
	state.facilities.append(high_realm)
	state.initialize_facilities()

	assert_str(String(state.get_upgrade_block_reason(&"test_high_realm_facility"))).is_equal(
		String(SectState.REASON_REALM_TOO_LOW)
	)
	assert_bool(state.upgrade_facility(&"test_high_realm_facility")).is_false()
	assert_int(state.get_facility_level(&"test_high_realm_facility")).is_equal(1)


func test_cultivate_scales_with_spirit_array_and_cave_dwelling() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.bind_cultivator(pawn)
	state.deposit_spirit_stones(_dungeon_max_reward() * 10)

	# 聚灵阵 1 级（8 修为）× 洞府 1 级加成（×1.5）= 12
	assert_float(state.cultivate()).is_equal_approx(12.0, APPROX)

	# 洞府升到 2 级后：×2.0 = 16
	assert_bool(state.upgrade_facility(&"cave_dwelling")).is_true()
	assert_float(state.cultivate()).is_equal_approx(16.0, APPROX)

	# 聚灵阵升到 2 级后：16 修为 × 2.0 = 32
	assert_bool(state.upgrade_facility(&"spirit_array")).is_true()
	assert_float(state.cultivate()).is_equal_approx(32.0, APPROX)


func test_cultivate_stops_at_breakthrough_threshold() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.bind_cultivator(pawn)

	var required_exp: float = float(pawn.get_cultivation_snapshot()["required_exp"])
	assert_float(required_exp).is_greater(0.0)

	var total: float = 0.0
	for _attempt: int in 30:
		total += state.cultivate()

	assert_float(total).is_equal_approx(required_exp, APPROX)
	assert_float(float(pawn.get_cultivation_snapshot()["current_exp"])).is_equal_approx(required_exp, APPROX)
	# 到达瓶颈后继续打坐不再产生修为（宗门不做突破，突破属于后续 Increment）。
	assert_float(state.cultivate()).is_equal_approx(0.0, APPROX)


func test_cultivate_requires_bound_cultivator() -> void:
	var state: SectState = _spawn_state()

	assert_float(state.cultivate()).is_equal_approx(0.0, APPROX)
	assert_int(state.get_cultivator_realm_tier()).is_zero()


func test_harvest_spirit_field_scales_with_level() -> void:
	var state: SectState = _spawn_state()
	var pawn: Pawn = _spawn_player()
	state.bind_cultivator(pawn)
	state.deposit_spirit_stones(_dungeon_max_reward())

	var harvests: Array = []
	state.herbs_harvested.connect(
		func(_state: SectState, facility_id: StringName, amount: int) -> void:
			harvests.append({"id": facility_id, "amount": amount})
	)

	assert_int(state.harvest_spirit_field()).is_equal(2)
	assert_int(state.get_spirit_herbs()).is_equal(2)
	assert_array(harvests).has_size(1)
	assert_int(int(harvests[0]["amount"])).is_equal(2)

	assert_bool(state.upgrade_facility(&"spirit_field")).is_true()
	assert_int(state.harvest_spirit_field()).is_equal(4)
	assert_int(state.get_spirit_herbs()).is_equal(6)
	assert_array(harvests).has_size(2)


func test_snapshot_is_a_read_only_copy() -> void:
	var state: SectState = _spawn_state()
	var snapshot: Dictionary = state.get_snapshot()

	assert_int(int(snapshot["spirit_stones"])).is_zero()
	assert_int(int(snapshot["spirit_herbs"])).is_zero()
	assert_int(int(snapshot["pills"])).is_zero()

	var entries: Array = snapshot["facilities"]
	assert_array(entries).has_size(FACILITY_IDS.size())
	var first: Dictionary = entries[0]
	assert_str(String(first["id"])).is_equal("cave_dwelling")
	assert_int(int(first["level"])).is_equal(SectState.INITIAL_FACILITY_LEVEL)
	assert_bool(bool(first["can_upgrade"])).is_false()

	# 修改返回值不得回流到宗门状态。
	entries.append({"id": &"fake_facility"})
	snapshot["spirit_stones"] = 999
	assert_int(state.get_snapshot()["facilities"].size()).is_equal(FACILITY_IDS.size())
	assert_int(state.get_spirit_stones()).is_zero()
