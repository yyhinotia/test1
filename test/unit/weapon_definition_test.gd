extends GdUnitTestSuite

## 单元层（纯逻辑）：武器定义、五行 / 类型标签与两份武器数据。
## 标签是显示层契约，数据资源只存 StringName 标识；本套件锁定“标识 → 中文标签”的唯一映射。

const WEAPON_DIR: String = "res://game/inventory/data/weapons/"
const UNKNOWN_ELEMENT: String = WeaponDefinition.UNKNOWN_ELEMENT_TEXT
const UNKNOWN_TYPE: String = WeaponDefinition.UNKNOWN_TYPE_TEXT


func _weapon(file_name: String) -> WeaponDefinition:
	return load(WEAPON_DIR + file_name) as WeaponDefinition


func test_new_weapon_uses_documented_defaults() -> void:
	var weapon: WeaponDefinition = WeaponDefinition.new()

	assert_str(String(weapon.id)).is_equal("weapon")
	assert_str(weapon.display_name).is_equal("武器")
	assert_str(String(weapon.weapon_type)).is_equal("sword")
	assert_str(String(weapon.element)).is_empty()
	assert_int(weapon.required_realm_tier).is_equal(1)
	assert_bool(weapon.is_configured()).is_true()

	# 默认武器没有配置五行：has_element() 为假，标签回退到占位文案而不是空串。
	assert_bool(weapon.has_element()).is_false()
	assert_str(weapon.get_element_label()).is_equal(UNKNOWN_ELEMENT)
	assert_str(weapon.get_type_label()).is_equal("剑")

	weapon.id = &"   "
	assert_bool(weapon.is_configured()).is_false()


func test_all_elements_have_chinese_labels() -> void:
	var labels: Array[String] = []
	for element: StringName in WeaponDefinition.ALL_ELEMENTS:
		labels.append(WeaponDefinition.element_label(element))

	assert_int(WeaponDefinition.ALL_ELEMENTS.size()).is_equal(5)
	assert_array(labels as Array).contains_exactly(["金", "木", "水", "火", "土"])

	# 未知与空标识都不允许返回空串，否则 UI 会出现空白标签。
	assert_str(WeaponDefinition.element_label(&"plasma")).is_equal(UNKNOWN_ELEMENT)
	assert_str(WeaponDefinition.element_label(&"")).is_equal(UNKNOWN_ELEMENT)


func test_type_labels_fall_back_for_unknown_values() -> void:
	assert_str(WeaponDefinition.type_label(WeaponDefinition.TYPE_SWORD)).is_equal("剑")
	assert_str(WeaponDefinition.type_label(WeaponDefinition.TYPE_ARTIFACT)).is_equal("法器")
	assert_str(WeaponDefinition.type_label(WeaponDefinition.TYPE_BLADE)).is_equal("刀")
	assert_str(WeaponDefinition.type_label(&"axe")).is_equal("axe")
	assert_str(WeaponDefinition.type_label(&"  ")).is_equal(UNKNOWN_TYPE)


func test_weapon_presets_match_design_data() -> void:
	var qingfeng: WeaponDefinition = _weapon("qingfeng_sword.tres")
	assert_object(qingfeng).is_not_null()
	assert_str(String(qingfeng.id)).is_equal("qingfeng_sword")
	assert_str(qingfeng.display_name).is_equal("青锋剑")
	assert_str(qingfeng.get_type_label()).is_equal("剑")
	assert_bool(qingfeng.has_element()).is_true()
	assert_str(qingfeng.get_element_label()).is_equal("金")
	assert_int(qingfeng.required_realm_tier).is_equal(1)

	var chiyan: WeaponDefinition = _weapon("chiyan_sword.tres")
	assert_object(chiyan).is_not_null()
	assert_str(String(chiyan.id)).is_equal("chiyan_sword")
	assert_str(chiyan.display_name).is_equal("赤炎剑")
	assert_str(chiyan.get_type_label()).is_equal("法器")
	assert_str(chiyan.get_element_label()).is_equal("火")
	assert_int(chiyan.required_realm_tier).is_equal(1)


func test_two_weapon_instances_do_not_share_values() -> void:
	var first: WeaponDefinition = WeaponDefinition.new()
	var second: WeaponDefinition = WeaponDefinition.new()

	first.display_name = "改动过的武器"
	first.element = WeaponDefinition.ELEMENT_FIRE

	assert_str(second.display_name).is_equal("武器")
	assert_str(String(second.element)).is_empty()