extends GdUnitTestSuite

## 单元层（纯逻辑）：PawnInfoModel 的快照派生与文案兜底。
## 本层不实例化节点、不加载场景，只验证“静态数据 + 运行时字典 → 快照与文案”这一层契约。

const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"
const UNKNOWN: String = "—"
const APPROX: float = 0.0001


func _player_data() -> PawnData:
	return load(PLAYER_DATA_PATH) as PawnData


func _enemy_data() -> PawnData:
	return load(ENEMY_DATA_PATH) as PawnData


## 没有 PawnData 时不允许崩溃，也不允许编造数值，必须走占位文案。
func test_snapshot_without_data_uses_placeholders() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(null)
	var identity: Dictionary = snapshot["identity"]

	assert_str(String(identity["name"])).is_equal(UNKNOWN)
	assert_str(String(identity["realm"])).is_equal(UNKNOWN)
	assert_str(String(identity["sub_realm"])).is_equal(UNKNOWN)
	assert_str(String(identity["spirit_root"])).is_equal(UNKNOWN)
	assert_bool(identity["has_realm"]).is_false()
	assert_str(String(identity["build_tag"])).is_equal(PawnInfoModel.NO_BUILD_TAG)

	var build_lines: Array[String] = PawnInfoModel.build_lines(snapshot)
	assert_int(build_lines.size()).is_equal(1)
	assert_str(build_lines[0]).is_equal(PawnInfoModel.BUILD_UNAVAILABLE_TEXT)


## 玩家预设：身份四行、Build 标签与三层资源行都来自真实数据。
func test_player_preset_snapshot_and_lines() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		PawnInfoModel.HEALTH_KEY: {"current": 96.0, "max": 120.0},
		PawnInfoModel.SHIELD_KEY: {"current": 0.0, "max": 40.0},
		PawnInfoModel.SPIRIT_KEY: {"current": 70.0, "max": 100.0},
	})
	var identity: Dictionary = snapshot["identity"]
	assert_str(String(identity["name"])).is_equal("测试修士")
	assert_str(String(identity["realm"])).is_equal("炼气")
	assert_str(String(identity["sub_realm"])).is_equal("三层")
	assert_str(String(identity["spirit_root"])).is_equal("金灵根")
	assert_bool(identity["has_realm"]).is_true()
	assert_str(String(identity["build_tag"])).is_equal("剑修 · 御剑斩")

	var lines: Array[String] = PawnInfoModel.identity_lines(snapshot)
	assert_int(lines.size()).is_equal(4)
	assert_str(lines[0]).is_equal("测试修士")
	assert_str(lines[1]).is_equal("炼气 · 三层")
	assert_str(lines[2]).is_equal("灵根：金灵根")
	assert_str(lines[3]).is_equal("流派：剑修 · 御剑斩")

	assert_str(PawnInfoModel.vital_line(snapshot, PawnInfoModel.HEALTH_KEY)).is_equal("气血  96 / 120")
	assert_str(PawnInfoModel.vital_line(snapshot, PawnInfoModel.SHIELD_KEY)).is_equal("护体  0 / 40")
	assert_str(PawnInfoModel.vital_line(snapshot, PawnInfoModel.SPIRIT_KEY)).is_equal("灵力  70 / 100")


## 敌人预设：没有境界与灵根，灵力上限为 0，因此灵力行必须消失，Build 区只给“不适用”。
func test_enemy_preset_hides_realm_and_spirit() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(_enemy_data(), {
		PawnInfoModel.HEALTH_KEY: {"current": 180.0, "max": 180.0},
		PawnInfoModel.SHIELD_KEY: {"current": 20.0, "max": 20.0},
		PawnInfoModel.SPIRIT_KEY: {"current": 0.0, "max": 0.0},
	})
	var identity: Dictionary = snapshot["identity"]
	assert_bool(identity["has_realm"]).is_false()
	assert_str(String(identity["realm"])).is_equal(UNKNOWN)
	assert_str(String(identity["sub_realm"])).is_equal(UNKNOWN)
	assert_str(String(identity["spirit_root"])).is_equal(UNKNOWN)
	assert_str(String(identity["build_tag"])).is_equal(PawnInfoModel.NO_BUILD_TAG)
	assert_str(PawnInfoModel.vital_line(snapshot, PawnInfoModel.SPIRIT_KEY)).is_empty()
	assert_str(PawnInfoModel.vital_line(snapshot, PawnInfoModel.HEALTH_KEY)).is_equal("气血  180 / 180")

	var build_lines: Array[String] = PawnInfoModel.build_lines(snapshot)
	assert_int(build_lines.size()).is_equal(1)
	assert_str(build_lines[0]).is_equal(PawnInfoModel.BUILD_UNAVAILABLE_TEXT)


## 攻速由攻击间隔派生；没有间隔数据时不允许除零。
func test_attack_speed_derives_from_interval() -> void:
	assert_float(PawnInfoModel.get_attack_speed(0.8)).is_equal_approx(1.25, APPROX)
	assert_float(PawnInfoModel.get_attack_speed(2.0)).is_equal_approx(0.5, APPROX)
	assert_float(PawnInfoModel.get_attack_speed(0.0)).is_zero()
	assert_float(PawnInfoModel.get_attack_speed(-1.0)).is_zero()


## 属性行只显示当前有真实数据来源的属性，不出现法强/暴击这类尚无数据的字段。
func test_attribute_line_uses_existing_fields_only() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data())
	assert_str(PawnInfoModel.attribute_line(snapshot)).is_equal("攻击 28   防御 5   攻速 1.25   移速 145")


## Build 区的 used / max 来自调用方传入的真实容量，名称来自真实功法 / 武器 / 技能。
func test_build_lines_report_capacity_and_names() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		"technique_used": 1,
		"technique_max": 1,
		"weapon_used": 1,
		"weapon_max": 1,
		"active_skill_used": 1,
		"active_skill_max": 2,
		"passive_skill_used": 0,
		"passive_skill_max": 1,
	})
	var lines: Array[String] = PawnInfoModel.build_lines(snapshot)
	assert_int(lines.size()).is_equal(4)
	assert_str(lines[0]).is_equal("功法  1 / 1    剑修")
	assert_str(lines[1]).is_equal("武器  1 / 1    青锋剑（剑 · 金）")
	assert_str(lines[2]).is_equal("主动  1 / 2    御剑斩")
	assert_str(lines[3]).is_equal("被动  0 / 1    —")


## 校验存在错误时只追加首条原因；完整错误列表仍由 BuildValidationResult 提供。
func test_build_error_summary_is_appended() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		"technique_used": 1,
		"technique_max": 1,
		"build_error_summary": "功法「剑修」与「体修」不能同时装备",
	})
	var lines: Array[String] = PawnInfoModel.build_lines(snapshot)
	assert_int(lines.size()).is_equal(5)
	assert_str(lines[4]).is_equal("校验：功法「剑修」与「体修」不能同时装备")


## 武器标签取“类型 · 五行”；缺失或未知五行只显示类型，不给缺数据的条目补假属性。
func test_weapon_tag_omits_missing_or_unknown_element() -> void:
	var realm: RealmDefinition = load("res://game/cultivation/data/realms/qi_refining.tres") as RealmDefinition
	var weapon: WeaponDefinition = WeaponDefinition.new()
	weapon.id = &"test_weapon"
	weapon.display_name = "测试剑"
	weapon.weapon_type = WeaponDefinition.TYPE_SWORD

	var data: PawnData = PawnData.new()
	data.display_name = "测试修士"
	data.realm = realm
	data.weapon = weapon

	var runtime: Dictionary = {"weapon_used": 1, "weapon_max": 1}
	var no_element: Array[String] = PawnInfoModel.build_lines(PawnInfoModel.build_snapshot(data, runtime))
	assert_str(no_element[1]).is_equal("武器  1 / 1    测试剑（剑）")

	weapon.element = &"plasma"
	var unknown_element: Array[String] = PawnInfoModel.build_lines(PawnInfoModel.build_snapshot(data, runtime))
	assert_str(unknown_element[1]).is_equal("武器  1 / 1    测试剑（剑）")

	weapon.weapon_type = WeaponDefinition.TYPE_ARTIFACT
	weapon.element = WeaponDefinition.ELEMENT_FIRE
	var full_tag: Array[String] = PawnInfoModel.build_lines(PawnInfoModel.build_snapshot(data, runtime))
	assert_str(full_tag[1]).is_equal("武器  1 / 1    测试剑（法器 · 火）")


## 未装备武器时武器行仍显示真实上限，名称留占位，不允许凭空造出武器名。
func test_weapon_slot_without_weapon_shows_capacity_only() -> void:
	var data: PawnData = PawnData.new()
	data.realm = load("res://game/cultivation/data/realms/qi_refining.tres") as RealmDefinition
	var lines: Array[String] = PawnInfoModel.build_lines(PawnInfoModel.build_snapshot(data, {"weapon_used": 0, "weapon_max": 1}))
	assert_str(lines[1]).is_equal("武器  0 / 1    —")


## 运行时数值缺失时整行为空；超出上限时按上限截断，不允许显示负值。
func test_vitals_fall_back_and_clamp() -> void:
	var empty_snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data())
	assert_str(PawnInfoModel.vital_line(empty_snapshot, PawnInfoModel.HEALTH_KEY)).is_empty()

	var clamped: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		PawnInfoModel.HEALTH_KEY: {"current": 999.0, "max": 120.0},
		PawnInfoModel.SHIELD_KEY: {"current": -5.0, "max": 40.0},
	})
	assert_str(PawnInfoModel.vital_line(clamped, PawnInfoModel.HEALTH_KEY)).is_equal("气血  120 / 120")
	assert_str(PawnInfoModel.vital_line(clamped, PawnInfoModel.SHIELD_KEY)).is_equal("护体  0 / 40")


## 读模型是只读的：构建快照不得回写 PawnData。
func test_snapshot_does_not_modify_static_data() -> void:
	var data: PawnData = _player_data()
	PawnInfoModel.build_snapshot(data, {PawnInfoModel.HEALTH_KEY: {"current": 1.0, "max": 120.0}})

	assert_str(data.display_name).is_equal("测试修士")
	assert_float(data.max_health).is_equal(120.0)
	assert_str(data.sub_realm).is_equal("三层")
	assert_int(data.techniques.size()).is_equal(1)


## 修为区：有下一境界时给出百分比、当前/所需与下一境界，达到阈值追加可突破提示。
func test_cultivation_line_reports_progress_and_ready_state() -> void:
	var snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		"cultivation": {
			"realm_name": "炼气",
			"next_realm_name": "筑基",
			"current_exp": 72.0,
			"required_exp": 100.0,
			"has_next_realm": true,
			"ready": false,
		},
	})
	assert_str(PawnInfoModel.cultivation_line(snapshot)).is_equal("修为  72%  72 / 100  → 筑基")
	assert_float(PawnInfoModel.cultivation_ratio(snapshot)).is_equal_approx(0.72, APPROX)

	var ready_snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		"cultivation": {
			"realm_name": "炼气",
			"next_realm_name": "筑基",
			"current_exp": 100.0,
			"required_exp": 100.0,
			"has_next_realm": true,
			"ready": true,
		},
	})
	assert_str(PawnInfoModel.cultivation_line(ready_snapshot)).is_equal("修为  100%  100 / 100  → 筑基  （可突破）")
	assert_float(PawnInfoModel.cultivation_ratio(ready_snapshot)).is_equal_approx(1.0, APPROX)


## 终点境界与缺失修为数据：终点显示最高境界，缺失数据隐藏整段且进度为 0。
func test_cultivation_line_handles_terminal_and_missing_data() -> void:
	var terminal_snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data(), {
		"cultivation": {
			"realm_name": "化神",
			"next_realm_name": "",
			"current_exp": 0.0,
			"required_exp": 0.0,
			"has_next_realm": false,
			"ready": false,
		},
	})
	assert_str(PawnInfoModel.cultivation_line(terminal_snapshot)).is_equal(PawnInfoModel.CULTIVATION_MAX_REALM_TEXT)
	assert_float(PawnInfoModel.cultivation_ratio(terminal_snapshot)).is_zero()

	var missing_snapshot: Dictionary = PawnInfoModel.build_snapshot(_player_data())
	assert_str(PawnInfoModel.cultivation_line(missing_snapshot)).is_empty()
	assert_float(PawnInfoModel.cultivation_ratio(missing_snapshot)).is_zero()

