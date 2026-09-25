extends GdUnitTestSuite

## 单元层（纯逻辑）：秘境遭遇定义（INC-WORLD-001）。
## 锁定「遭遇 = 玩家可读名称 + 一个正式敌人档案」这一数据契约，不加载场景、不实例化 Pawn。
## 这里断言的是引用关系（遭遇引用的敌人档案路径就是 INC-PAWNS-016 的正式档案），
## 不硬编码敌人数值——数值变更由 INC-PAWNS-016 的用例负责。

const ENCOUNTER_DIR: String = "res://game/world/data/encounters/"
const ENCOUNTER_FILES: Array[String] = [
	"encounter_trial_puppet.tres",
	"encounter_iron_guard.tres",
	"encounter_blood_blade.tres",
]

## 遭遇 → 期望的敌人档案路径（正式资源的唯一来源）。
const EXPECTED_ENEMY_PROFILE: Dictionary = {
	&"encounter_trial_puppet": "res://game/pawns/data/enemy_pawn.tres",
	&"encounter_iron_guard": "res://game/pawns/data/enemies/enemy_iron_guard.tres",
	&"encounter_blood_blade": "res://game/pawns/data/enemies/enemy_blood_blade.tres",
}


func _load_encounter(file_name: String) -> EncounterDefinition:
	return load(ENCOUNTER_DIR + file_name) as EncounterDefinition


func test_new_encounter_is_not_configured_and_has_no_enemy() -> void:
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &""

	assert_bool(encounter.is_configured()).is_false()
	assert_str(String(encounter.get_enemy_profile_id())).is_equal("")
	assert_str(encounter.get_enemy_display_name()).is_equal("")
	assert_str(encounter.get_threat_tag_label()).is_equal("基线")


func test_missing_enemy_profile_is_not_configured() -> void:
	var encounter: EncounterDefinition = EncounterDefinition.new()
	encounter.id = &"encounter_without_enemy"
	encounter.display_name = "空遭遇"
	encounter.enemy_profile = null

	assert_bool(encounter.is_configured()).is_false()
	assert_str(String(encounter.get_enemy_profile_id())).is_equal("")


func test_encounter_resources_are_configured_and_unique() -> void:
	var ids: Array = []
	var enemy_ids: Array = []
	for file_name: String in ENCOUNTER_FILES:
		var encounter: EncounterDefinition = _load_encounter(file_name)
		assert_object(encounter).is_not_null()
		assert_bool(encounter.is_configured()).is_true()
		assert_bool(encounter.display_name.strip_edges().is_empty()).is_false()
		assert_bool(encounter.description.strip_edges().is_empty()).is_false()
		ids.append(encounter.id)
		enemy_ids.append(encounter.get_enemy_profile_id())

	# 遭遇 id 与对手 id 都必须互不相同，否则玩家无法区分自己选了哪一场。
	assert_int(ids.size()).is_equal(ENCOUNTER_FILES.size())
	assert_int(_unique_count(ids)).is_equal(ENCOUNTER_FILES.size())
	assert_int(_unique_count(enemy_ids)).is_equal(ENCOUNTER_FILES.size())


func test_encounters_reference_the_official_enemy_profiles() -> void:
	for file_name: String in ENCOUNTER_FILES:
		var encounter: EncounterDefinition = _load_encounter(file_name)
		assert_bool(EXPECTED_ENEMY_PROFILE.has(encounter.id)).is_true()
		assert_str(encounter.enemy_profile.resource_path).is_equal(EXPECTED_ENEMY_PROFILE[encounter.id])
		# 遭遇只是引用，不允许成为敌人数值的第二份来源。
		var shared_profile: PawnData = load(EXPECTED_ENEMY_PROFILE[encounter.id]) as PawnData
		assert_object(encounter.enemy_profile).is_same(shared_profile)
		assert_str(encounter.get_enemy_display_name()).is_equal(shared_profile.display_name)


func test_threat_tags_cover_baseline_endurance_and_burst() -> void:
	var labels: Array = []
	for file_name: String in ENCOUNTER_FILES:
		var encounter: EncounterDefinition = _load_encounter(file_name)
		labels.append(encounter.get_threat_tag_label())

	assert_array(labels).contains_exactly(["基线", "长线", "爆发"])


func test_two_encounter_instances_do_not_share_fields() -> void:
	var first: EncounterDefinition = EncounterDefinition.new()
	var second: EncounterDefinition = EncounterDefinition.new()
	first.display_name = "改动过的遭遇"
	first.threat_tag = EncounterDefinition.ThreatTag.BURST

	assert_str(second.display_name).is_equal("遭遇")
	assert_int(second.threat_tag).is_equal(EncounterDefinition.ThreatTag.BASELINE)


func _unique_count(values: Array) -> int:
	var unique: Array = []
	for value: Variant in values:
		if not unique.has(value):
			unique.append(value)
	return unique.size()
