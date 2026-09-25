extends GdUnitTestSuite

## 单元层：宗门设施静态定义（INC-SECT-001）。
##
## 锁定「设施定义只回答静态规则」这一契约：升级花费随等级线性递增、满级与非法等级返回不可用哨兵、
## 产出随等级增长且负值截断、类别标签覆盖全部类别并回退占位，
## 并断言六份正式设施数据的真实字段与 id 唯一性（按 resource_path 加载，不复制数值）。

const FACILITY_DIR: String = "res://game/sect/data/facilities"
const EXPECTED_FACILITY_IDS: Array[String] = [
	"cave_dwelling",
	"spirit_array",
	"spirit_field",
	"alchemy_room",
	"forge_room",
	"scripture_pavilion",
]


func _load_facility(facility_id: String) -> SectFacilityDefinition:
	return load("%s/%s.tres" % [FACILITY_DIR, facility_id]) as SectFacilityDefinition


func test_unconfigured_facility_is_rejected() -> void:
	# 默认值遵循既有 Definition 约定：字段带占位值，因此新建实例是「已配置」；
	# 只有显式清空 id 或显示名才算未配置。
	var blank_id: SectFacilityDefinition = SectFacilityDefinition.new()
	assert_bool(blank_id.is_configured()).is_true()
	blank_id.id = &""
	assert_bool(blank_id.is_configured()).is_false()

	var blank_name: SectFacilityDefinition = SectFacilityDefinition.new()
	blank_name.display_name = "   "
	assert_bool(blank_name.is_configured()).is_false()

	blank_name.display_name = "洞府"
	assert_bool(blank_name.is_configured()).is_true()


func test_upgrade_cost_grows_linearly_and_stops_at_max_level() -> void:
	var facility: SectFacilityDefinition = SectFacilityDefinition.new()
	facility.id = &"test_facility"
	facility.base_upgrade_cost = 30
	facility.upgrade_cost_growth = 20
	facility.max_level = 3

	assert_int(facility.get_upgrade_cost(-1)).is_equal(SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE)
	assert_int(facility.get_upgrade_cost(0)).is_equal(30)
	assert_int(facility.get_upgrade_cost(1)).is_equal(50)
	assert_int(facility.get_upgrade_cost(2)).is_equal(70)
	assert_int(facility.get_upgrade_cost(3)).is_equal(SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE)
	assert_int(facility.get_upgrade_cost(99)).is_equal(SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE)

	assert_bool(facility.can_upgrade(-1)).is_false()
	assert_bool(facility.can_upgrade(0)).is_true()
	assert_bool(facility.can_upgrade(2)).is_true()
	assert_bool(facility.can_upgrade(3)).is_false()


func test_negative_costs_and_yields_are_clamped_to_zero() -> void:
	var facility: SectFacilityDefinition = SectFacilityDefinition.new()
	facility.id = &"clamped_facility"
	facility.base_upgrade_cost = -50
	facility.upgrade_cost_growth = -10
	facility.max_level = 2
	facility.yield_per_level = -3

	assert_int(facility.get_upgrade_cost(0)).is_zero()
	assert_int(facility.get_upgrade_cost(1)).is_zero()
	assert_int(facility.get_yield(-5)).is_zero()
	assert_int(facility.get_yield(0)).is_zero()
	assert_int(facility.get_yield(4)).is_zero()


func test_yield_scales_with_level() -> void:
	var facility: SectFacilityDefinition = SectFacilityDefinition.new()
	facility.id = &"yielding_facility"
	facility.yield_per_level = 8

	assert_int(facility.get_yield(-1)).is_zero()
	assert_int(facility.get_yield(0)).is_zero()
	assert_int(facility.get_yield(1)).is_equal(8)
	assert_int(facility.get_yield(3)).is_equal(24)


func test_kind_labels_cover_every_kind_and_unknown_falls_back() -> void:
	var expected: Array[String] = ["洞府", "聚灵阵", "灵田", "丹房", "炼器房", "藏经阁"]
	assert_int(SectFacilityDefinition.ALL_KINDS.size()).is_equal(expected.size())

	for index: int in SectFacilityDefinition.ALL_KINDS.size():
		var kind_value: int = SectFacilityDefinition.ALL_KINDS[index]
		assert_str(SectFacilityDefinition.kind_label(kind_value)).is_equal(expected[index])
		assert_bool(SectFacilityDefinition.kind_label(kind_value + 100).is_empty()).is_false()
	assert_str(SectFacilityDefinition.kind_label(-1)).is_equal("未知设施")
	assert_str(SectFacilityDefinition.kind_label(999)).is_equal("未知设施")


func test_six_formal_facilities_are_configured_with_unique_ids_and_kinds() -> void:
	var seen_ids: Array[StringName] = []
	var seen_kinds: Array[int] = []

	for facility_id: String in EXPECTED_FACILITY_IDS:
		var facility: SectFacilityDefinition = _load_facility(facility_id)
		assert_object(facility).is_not_null()
		assert_bool(facility.is_configured()).is_true()
		assert_str(String(facility.id)).is_equal(facility_id)
		assert_bool(facility.display_name.strip_edges().is_empty()).is_false()
		assert_int(facility.max_level).is_greater_equal(1)
		assert_int(facility.base_upgrade_cost).is_greater(0)
		# 1 级是「已建成」，因此从 1 级升级到 2 级必须有明确花费。
		assert_int(facility.get_upgrade_cost(1)).is_greater(0)
		assert_int(facility.get_upgrade_cost(facility.max_level)).is_equal(
			SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE
		)
		assert_bool(seen_ids.has(facility.id)).is_false()
		assert_bool(seen_kinds.has(facility.kind)).is_false()
		seen_ids.append(facility.id)
		seen_kinds.append(facility.kind)

	assert_int(seen_ids.size()).is_equal(EXPECTED_FACILITY_IDS.size())
	assert_int(seen_kinds.size()).is_equal(SectFacilityDefinition.ALL_KINDS.size())


func test_formal_facility_kinds_provide_the_six_minimal_sect_outputs() -> void:
	var cave: SectFacilityDefinition = _load_facility("cave_dwelling")
	var array: SectFacilityDefinition = _load_facility("spirit_array")
	var field: SectFacilityDefinition = _load_facility("spirit_field")
	var alchemy: SectFacilityDefinition = _load_facility("alchemy_room")
	var forge: SectFacilityDefinition = _load_facility("forge_room")
	var pavilion: SectFacilityDefinition = _load_facility("scripture_pavilion")

	assert_int(cave.kind).is_equal(SectFacilityDefinition.FacilityKind.CAVE_DWELLING)
	assert_int(array.kind).is_equal(SectFacilityDefinition.FacilityKind.SPIRIT_ARRAY)
	assert_int(field.kind).is_equal(SectFacilityDefinition.FacilityKind.SPIRIT_FIELD)
	assert_int(alchemy.kind).is_equal(SectFacilityDefinition.FacilityKind.ALCHEMY_ROOM)
	assert_int(forge.kind).is_equal(SectFacilityDefinition.FacilityKind.FORGE_ROOM)
	assert_int(pavilion.kind).is_equal(SectFacilityDefinition.FacilityKind.SCRIPTURE_PAVILION)

	# 洞府本身不直接产修为（它是效率倍率），聚灵阵与灵田是产出设施。
	assert_int(cave.get_yield(3)).is_zero()
	assert_int(array.get_yield(1)).is_greater(0)
	assert_int(field.get_yield(1)).is_greater(0)
	# 丹房消耗灵草产丹药，炼器房与藏经阁消耗灵石。
	assert_int(alchemy.herb_cost).is_greater(0)
	assert_int(alchemy.get_yield(1)).is_greater(0)
	assert_int(forge.spirit_stone_cost).is_greater(0)
	assert_int(forge.get_yield(1)).is_equal(1)
	assert_int(pavilion.spirit_stone_cost).is_greater(0)
	assert_int(pavilion.get_yield(1)).is_equal(1)
