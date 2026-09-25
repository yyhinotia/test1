extends GdUnitTestSuite

## 单元层（纯逻辑）：功法 / 被动定义与 Build 容量冲突校验。
## 这里锁定规则本身，不加载场景、不实例化 Pawn；Pawn 汇总与 HUD 展示由集成层和玩法层覆盖。
## 错误码是稳定契约，中文文案只用于 HUD，因此两处都断言。

const REALM_DIR: String = "res://game/cultivation/data/realms/"
const TECHNIQUE_DIR: String = "res://game/cultivation/data/techniques/"
const PLAYER_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const WEAPON_DIR: String = "res://game/inventory/data/weapons/"


func _realm(file_name: String) -> RealmDefinition:
	return load(REALM_DIR + file_name) as RealmDefinition


func _technique(file_name: String) -> TechniqueDefinition:
	return load(TECHNIQUE_DIR + file_name) as TechniqueDefinition


func _weapon(file_name: String) -> WeaponDefinition:
	return load(WEAPON_DIR + file_name) as WeaponDefinition


func _make_loadout(realm: RealmDefinition) -> BuildLoadout:
	var loadout: BuildLoadout = BuildLoadout.new()
	loadout.realm = realm
	return loadout


func _make_technique(
		id: StringName,
		display_name: String,
		tier: int = 1,
		tags: Array[StringName] = []
	) -> TechniqueDefinition:
	var technique: TechniqueDefinition = TechniqueDefinition.new()
	technique.id = id
	technique.display_name = display_name
	technique.required_realm_tier = tier
	technique.conflict_tags = tags
	return technique


func _make_weapon(id: StringName, tier: int = 1) -> WeaponDefinition:
	var weapon: WeaponDefinition = WeaponDefinition.new()
	weapon.id = id
	weapon.display_name = String(id)
	weapon.required_realm_tier = tier
	return weapon


func _make_active(id: StringName) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = id
	skill.display_name = String(id)
	return skill


func _make_passive(id: StringName, tier: int = 1) -> PassiveSkillDefinition:
	var passive: PassiveSkillDefinition = PassiveSkillDefinition.new()
	passive.id = id
	passive.display_name = String(id)
	passive.required_realm_tier = tier
	return passive


func test_new_definitions_use_documented_defaults() -> void:
	var technique: TechniqueDefinition = TechniqueDefinition.new()
	assert_str(String(technique.id)).is_equal("technique")
	assert_str(technique.display_name).is_equal("功法")
	assert_str(String(technique.school)).is_equal("sword")
	assert_int(technique.required_realm_tier).is_equal(1)
	assert_int(technique.conflict_tags.size()).is_zero()
	assert_bool(technique.is_configured()).is_true()

	var passive: PassiveSkillDefinition = PassiveSkillDefinition.new()
	assert_str(String(passive.id)).is_equal("passive")
	assert_str(passive.display_name).is_equal("被动")
	assert_int(passive.required_realm_tier).is_equal(1)
	assert_bool(passive.is_configured()).is_true()

	technique.id = &"   "
	passive.id = &""
	assert_bool(technique.is_configured()).is_false()
	assert_bool(passive.is_configured()).is_false()


func test_technique_presets_match_design_table() -> void:
	var sword: TechniqueDefinition = _technique("sword_cultivation.tres")
	var thunder: TechniqueDefinition = _technique("thunder_cultivation.tres")
	var body: TechniqueDefinition = _technique("body_cultivation.tres")
	assert_object(sword).is_not_null()
	assert_object(thunder).is_not_null()
	assert_object(body).is_not_null()

	assert_str(String(sword.id)).is_equal("sword_cultivation")
	assert_str(sword.display_name).is_equal("剑修")
	assert_str(String(sword.school)).is_equal("sword")
	assert_int(sword.required_realm_tier).is_equal(1)

	assert_str(String(thunder.id)).is_equal("thunder_cultivation")
	assert_str(thunder.display_name).is_equal("雷修")
	assert_int(thunder.required_realm_tier).is_equal(2)
	assert_int(thunder.conflict_tags.size()).is_zero()

	assert_str(String(body.id)).is_equal("body_cultivation")
	assert_int(body.required_realm_tier).is_equal(1)
	assert_array(sword.conflict_tags as Array).contains_exactly([&"sword_body_conflict"])
	assert_array(body.conflict_tags as Array).contains_exactly([&"sword_body_conflict"])


func test_conflict_tag_lookup_is_symmetric_and_safe() -> void:
	var sword: TechniqueDefinition = _technique("sword_cultivation.tres")
	var thunder: TechniqueDefinition = _technique("thunder_cultivation.tres")
	var body: TechniqueDefinition = _technique("body_cultivation.tres")

	assert_str(String(sword.get_shared_conflict_tag(body))).is_equal("sword_body_conflict")
	assert_str(String(body.get_shared_conflict_tag(sword))).is_equal("sword_body_conflict")
	assert_str(String(sword.get_shared_conflict_tag(thunder))).is_empty()
	assert_str(String(thunder.get_shared_conflict_tag(sword))).is_empty()
	assert_str(String(sword.get_shared_conflict_tag(null))).is_empty()


func test_valid_player_build_passes_all_rules() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	loadout.techniques.append(_technique("sword_cultivation.tres"))
	loadout.active_skills.append(load(PLAYER_SKILL_PATH) as ActiveSkillDefinition)

	var result: BuildValidationResult = BuildValidator.validate(loadout)

	assert_bool(result.has_errors()).is_false()
	assert_bool(result.is_valid()).is_true()
	assert_int(result.get_errors().size()).is_zero()
	assert_str(result.get_summary()).is_empty()
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_ACTIVE_SKILL)).is_equal(2)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_PASSIVE_SKILL)).is_equal(1)


## 武器与其他类别共用同一套判定：容量、境界门槛与未配置条目都要报同一批错误码。
func test_weapon_slot_uses_the_same_rules() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	loadout.weapons.append(_weapon("qingfeng_sword.tres"))

	var valid: BuildValidationResult = BuildValidator.validate(loadout)
	assert_bool(valid.is_valid()).is_true()
	assert_int(loadout.get_used_slots(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_int(loadout.get_capacity(RealmDefinition.KIND_WEAPON)).is_equal(1)
	assert_str(String(loadout.get_weapon().id)).is_equal("qingfeng_sword")

	# 容量为 1：追加第二把武器必须报容量超限，且 kind 归属武器。
	loadout.weapons.append(_make_weapon(&"extra_weapon"))
	var over: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(over.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_OVER_CAPACITY])
	assert_str(String(over.get_errors()[0]["kind"])).is_equal("weapon")
	assert_str(over.get_summary()).is_equal("武器超出容量：2 / 1")

	# 境界门槛：炼气期不能装备需要元婴（tier 4）的武器。
	var low_tier: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	low_tier.weapons.append(_make_weapon(&"nascent_blade", 4))
	var too_low: BuildValidationResult = BuildValidator.validate(low_tier)
	assert_array(too_low.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_REALM_TOO_LOW])
	assert_str(String(too_low.get_errors()[0]["kind"])).is_equal("weapon")
	assert_bool(too_low.get_summary().contains("nascent_blade")).is_true()

	# 未配置条目沿用同一错误码，避免武器走一套独立规则。
	var unconfigured: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	unconfigured.weapons.append(_make_weapon(&"   "))
	var blank: BuildValidationResult = BuildValidator.validate(unconfigured)
	assert_array(blank.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_UNCONFIGURED_ENTRY])
	assert_str(String(blank.get_errors()[0]["kind"])).is_equal("weapon")


func test_missing_realm_reports_single_error() -> void:
	var loadout: BuildLoadout = BuildLoadout.new()
	loadout.techniques.append(_technique("sword_cultivation.tres"))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_MISSING_REALM])
	assert_str(String(result.get_errors()[0]["kind"])).is_equal("realm")
	assert_str(String(result.get_errors()[0]["entry_id"])).is_empty()
	assert_str(result.get_summary()).is_equal("未配置境界，无法计算 Build 容量")

	# 缺少境界时容量视为 0，且不把“装不下”当成第二条错误，避免掩盖真正原因。
	assert_int(loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_zero()
	assert_int(result.get_errors().size()).is_equal(1)
	assert_bool(BuildValidator.validate(null).is_valid()).is_false()


func test_over_capacity_reports_used_and_capacity() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	loadout.techniques.append(_technique("sword_cultivation.tres"))
	loadout.techniques.append(_make_technique(&"extra_technique", "外功"))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_OVER_CAPACITY])
	assert_str(String(result.get_errors()[0]["kind"])).is_equal("technique")
	assert_str(result.get_summary()).is_equal("功法超出容量：2 / 1")


func test_duplicate_entries_are_rejected() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("foundation_establishment.tres"))
	loadout.techniques.append(_technique("sword_cultivation.tres"))
	loadout.techniques.append(_technique("sword_cultivation.tres"))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_DUPLICATE_ENTRY])
	assert_str(String(result.get_errors()[0]["entry_id"])).is_equal("sword_cultivation")
	assert_bool(result.get_summary().contains("重复")).is_true()


func test_conflicting_techniques_are_rejected() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("foundation_establishment.tres"))
	loadout.techniques.append(_technique("sword_cultivation.tres"))
	loadout.techniques.append(_technique("body_cultivation.tres"))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_TECHNIQUE_CONFLICT])
	assert_str(String(result.get_errors()[0]["entry_id"])).is_equal("body_cultivation")
	assert_bool(result.get_summary().contains("剑修")).is_true()
	assert_bool(result.get_summary().contains("体修")).is_true()

	# 剑修 + 体修在筑基期容量内有位置，冲突是唯一原因：证明互斥判定不依赖容量。
	assert_int(loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE)).is_equal(2)


func test_realm_too_low_blocks_high_tier_technique() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	loadout.techniques.append(_technique("thunder_cultivation.tres"))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([BuildValidationResult.CODE_REALM_TOO_LOW])
	assert_str(String(result.get_errors()[0]["entry_id"])).is_equal("thunder_cultivation")
	assert_bool(result.get_summary().contains("筑基")).is_true()
	assert_bool(result.get_summary().contains("炼气")).is_true()

	# 同一功法放在筑基期 Build 中应当合法。
	var upgraded: BuildLoadout = _make_loadout(_realm("foundation_establishment.tres"))
	upgraded.techniques.append(_technique("thunder_cultivation.tres"))
	assert_bool(BuildValidator.validate(upgraded).is_valid()).is_true()


func test_unconfigured_and_empty_entries_are_reported() -> void:
	var loadout: BuildLoadout = _make_loadout(_realm("foundation_establishment.tres"))
	loadout.techniques.append(_make_technique(&"   ", "空功法"))
	loadout.active_skills.append(null)

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([
		BuildValidationResult.CODE_UNCONFIGURED_ENTRY,
		BuildValidationResult.CODE_UNCONFIGURED_ENTRY,
	])
	assert_str(String(result.get_errors()[0]["kind"])).is_equal("technique")
	assert_str(String(result.get_errors()[1]["kind"])).is_equal("active_skill")
	assert_str(String(result.get_errors()[1]["entry_id"])).is_empty()


func test_active_and_passive_capacity_are_checked_per_kind() -> void:
	# 炼气：主动 2 / 被动 1。
	var loadout: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	for index: int in 3:
		loadout.active_skills.append(_make_active(StringName("skill_%d" % index)))
	for index: int in 2:
		loadout.passives.append(_make_passive(StringName("passive_%d" % index)))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([
		BuildValidationResult.CODE_OVER_CAPACITY,
		BuildValidationResult.CODE_OVER_CAPACITY,
	])
	assert_str(String(result.get_errors()[0]["kind"])).is_equal("active_skill")
	assert_str(String(result.get_errors()[1]["kind"])).is_equal("passive_skill")
	assert_str(result.get_summary()).is_equal("主动技能超出容量：3 / 2")


func test_summary_returns_first_error_and_errors_are_read_only() -> void:
	# 炼气只装得下 1 个功法：剑修 + 体修同时触发互斥与超容量。
	var loadout: BuildLoadout = _make_loadout(_realm("qi_refining.tres"))
	loadout.techniques.append(_technique("sword_cultivation.tres"))
	loadout.techniques.append(_technique("body_cultivation.tres"))

	var result: BuildValidationResult = BuildValidator.validate(loadout)
	assert_array(result.get_error_codes() as Array).contains_exactly([
		BuildValidationResult.CODE_TECHNIQUE_CONFLICT,
		BuildValidationResult.CODE_OVER_CAPACITY,
	])
	assert_str(result.get_summary()).is_equal(String(result.get_errors()[0]["message"]))
	assert_bool(result.get_summary().contains("功法互斥")).is_true()

	var taken: Array[Dictionary] = result.get_errors()
	taken.clear()
	assert_int(result.get_errors().size()).is_equal(2)