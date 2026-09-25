extends GdUnitTestSuite

## 单元层（纯逻辑）：境界定义与 Build 容量表。
## 这里锁定“境界决定 Build 容量”这一静态契约，不加载场景、不实例化 Pawn。
## 容量数值必须与 `docs/project_summary.md` §4.1 的表格一致。

const REALM_DIR: String = "res://game/cultivation/data/realms/"
const REALM_FILES: Array[String] = [
	"qi_refining.tres",
	"foundation_establishment.tres",
	"golden_core.tres",
	"nascent_soul.tres",
	"spirit_transformation.tres",
]
## 设计文档 §4.1：境界 id → [功法容量, 武器容量, 主动技能容量, 被动技能容量]
## 武器容量不随境界递增（设计文档的突破预览只扩容功法/主动/被动），五个境界统一为 1。
const EXPECTED_CAPACITY: Dictionary = {
	&"qi_refining": [1, 1, 2, 1],
	&"foundation_establishment": [2, 1, 3, 2],
	&"golden_core": [3, 1, 4, 3],
	&"nascent_soul": [4, 1, 5, 4],
	&"spirit_transformation": [5, 1, 6, 5],
}


func _load_realm(file_name: String) -> RealmDefinition:
	return load(REALM_DIR + file_name) as RealmDefinition


func test_new_realm_definition_uses_documented_defaults() -> void:
	var realm: RealmDefinition = RealmDefinition.new()

	assert_str(String(realm.id)).is_equal("realm")
	assert_str(realm.display_name).is_equal("境界")
	assert_int(realm.tier).is_equal(1)
	assert_bool(realm.is_configured()).is_true()
	assert_int(realm.get_slot_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_int(realm.get_slot_capacity(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_int(realm.get_slot_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(2)
	assert_int(realm.get_slot_capacity(RealmDefinition.KIND_PASSIVE_SKILL)).is_equal(1)
	assert_array(RealmDefinition.ALL_KINDS as Array).contains_exactly([
		RealmDefinition.KIND_TECHNIQUE,
		RealmDefinition.KIND_WEAPON,
		RealmDefinition.KIND_ACTIVE_SKILL,
		RealmDefinition.KIND_PASSIVE_SKILL,
	])


func test_blank_id_is_not_configured_and_unknown_kind_has_no_capacity() -> void:
	var realm: RealmDefinition = RealmDefinition.new()
	realm.id = &"   "

	assert_bool(realm.is_configured()).is_false()
	# “weapon”自 INC-CULT-004 起是已知类别，未知类别改用未登记标识验证返回 0。
	assert_int(realm.get_slot_capacity(&"trinket")).is_zero()
	assert_int(realm.get_slot_capacity(&"")).is_zero()


func test_realm_data_matches_design_capacity_table() -> void:
	for file_name: String in REALM_FILES:
		var realm: RealmDefinition = _load_realm(file_name)
		assert_object(realm).is_not_null()
		assert_bool(realm.is_configured()).is_true()
		assert_bool(EXPECTED_CAPACITY.has(realm.id)).is_true()

		var expected: Array = EXPECTED_CAPACITY[realm.id]
		assert_int(realm.get_slot_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(expected[0])
		assert_int(realm.get_slot_capacity(RealmDefinition.KIND_WEAPON)).is_equal(expected[1])
		assert_int(realm.get_slot_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(expected[2])
		assert_int(realm.get_slot_capacity(RealmDefinition.KIND_PASSIVE_SKILL)).is_equal(expected[3])
		assert_array([
			realm.technique_slots,
			realm.weapon_slots,
			realm.active_skill_slots,
			realm.passive_skill_slots,
		] as Array).contains_exactly(expected)

## 武器槽是“固定 1 把主武器”的 MVP 假设：不随境界递增，避免出现某境界武器槽为 0 的空档。
func test_weapon_slots_stay_flat_across_realms() -> void:
	for file_name: String in REALM_FILES:
		var realm: RealmDefinition = _load_realm(file_name)
		assert_int(realm.weapon_slots).is_equal(1)
		assert_int(realm.get_slot_capacity(RealmDefinition.KIND_WEAPON)).is_equal(1)


func test_realm_tiers_are_unique_and_monotonic() -> void:
	var tiers: Array = []
	var names: Array = []
	for file_name: String in REALM_FILES:
		var realm: RealmDefinition = _load_realm(file_name)
		tiers.append(realm.tier)
		names.append(realm.display_name)

	assert_array(tiers).contains_exactly([1, 2, 3, 4, 5])
	assert_array(names).contains_exactly(["炼气", "筑基", "金丹", "元婴", "化神"])


func test_two_realm_instances_do_not_share_capacity() -> void:
	var first: RealmDefinition = RealmDefinition.new()
	var second: RealmDefinition = RealmDefinition.new()

	first.technique_slots = 9
	first.display_name = "改动过的境界"

	assert_int(second.technique_slots).is_equal(1)
	assert_str(second.display_name).is_equal("境界")

func test_new_realm_definition_has_no_next_realm_or_breakthrough_exp() -> void:
	var realm: RealmDefinition = RealmDefinition.new()

	assert_bool(realm.has_next_realm()).is_false()
	assert_object(realm.get_next_realm()).is_null()
	assert_float(realm.get_breakthrough_exp()).is_zero()


func test_realm_resources_form_ordered_progression_chain() -> void:
	var expected_next: Dictionary = {
		&"qi_refining": &"foundation_establishment",
		&"foundation_establishment": &"golden_core",
		&"golden_core": &"nascent_soul",
		&"nascent_soul": &"spirit_transformation",
		&"spirit_transformation": &"",
	}
	for file_name: String in REALM_FILES:
		var realm: RealmDefinition = _load_realm(file_name)
		var next_realm: RealmDefinition = realm.get_next_realm()
		var expected_id: StringName = expected_next[realm.id]
		if expected_id == &"":
			assert_bool(realm.has_next_realm()).is_false()
			assert_object(next_realm).is_null()
			assert_float(realm.get_breakthrough_exp()).is_zero()
		else:
			assert_bool(realm.has_next_realm()).is_true()
			assert_object(next_realm).is_not_null()
			assert_str(String(next_realm.id)).is_equal(String(expected_id))
			assert_int(next_realm.tier).is_equal(realm.tier + 1)
			assert_float(realm.get_breakthrough_exp()).is_equal_approx(100.0, 0.0001)


func test_breakthrough_exp_is_non_negative_and_requires_next_realm() -> void:
	var terminal: RealmDefinition = RealmDefinition.new()
	terminal.breakthrough_exp = -10.0
	assert_float(terminal.get_breakthrough_exp()).is_zero()

	var next_realm: RealmDefinition = RealmDefinition.new()
	next_realm.id = &"next_realm"
	var realm: RealmDefinition = RealmDefinition.new()
	realm.next_realm = next_realm
	realm.breakthrough_exp = -10.0
	assert_float(realm.get_breakthrough_exp()).is_zero()

	var invalid_next: RealmDefinition = RealmDefinition.new()
	invalid_next.id = &"   "
	realm.next_realm = invalid_next
	assert_bool(realm.has_next_realm()).is_false()
	assert_object(realm.get_next_realm()).is_null()
	assert_float(realm.get_breakthrough_exp()).is_zero()