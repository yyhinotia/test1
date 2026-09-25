extends GdUnitTestSuite

## 单元层（纯逻辑）：PawnData 静态配置的默认值与预设数值。
## 本层不加载场景、不实例化节点，只锁定“静态数据”这一层的契约。

const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ENEMY_DATA_PATH: String = "res://game/pawns/data/enemy_pawn.tres"


func test_new_pawn_data_uses_documented_defaults() -> void:
	var data: PawnData = PawnData.new()

	assert_str(String(data.id)).is_equal("pawn_000")
	assert_str(data.display_name).is_equal("Pawn")
	assert_str(String(data.faction)).is_equal("neutral")
	assert_str(data.sub_realm).is_equal("")
	assert_str(String(data.spirit_root)).is_equal("")
	assert_float(data.max_health).is_equal(100.0)
	assert_float(data.max_shield).is_zero()
	assert_float(data.max_spirit).is_zero()
	assert_float(data.initial_spirit_ratio).is_equal(1.0)
	assert_float(data.initial_cultivation_exp).is_zero()
	assert_float(data.attack).is_equal(10.0)
	assert_float(data.defense).is_zero()
	assert_float(data.move_speed).is_equal(100.0)
	assert_float(data.attack_range).is_equal(48.0)
	assert_float(data.attack_interval).is_equal(1.0)
	assert_that(data.display_color).is_equal(Color(0.85, 0.85, 0.85, 1.0))


## 默认单位默认没有护盾与灵力：这是“不显示护盾条/灵力条”的前提条件。
func test_default_unit_has_no_shield_and_no_spirit() -> void:
	var data: PawnData = PawnData.new()

	assert_float(data.max_shield).is_zero()
	assert_float(data.max_spirit).is_zero()
	assert_float(data.initial_spirit_ratio).is_equal(1.0)
	assert_float(data.initial_cultivation_exp).is_zero()


## Resource 默认值共享是 Godot 的经典陷阱：两个实例必须互不影响。
func test_two_instances_do_not_share_values() -> void:
	var first: PawnData = PawnData.new()
	var second: PawnData = PawnData.new()

	first.max_health = 500.0
	first.max_spirit = 42.0
	first.display_name = "改动过的"
	first.sub_realm = "三层"
	first.spirit_root = &"金灵根"
	first.initial_cultivation_exp = 42.0

	assert_str(second.sub_realm).is_equal("")
	assert_str(String(second.spirit_root)).is_equal("")
	assert_float(second.max_health).is_equal(100.0)
	assert_float(second.max_spirit).is_zero()
	assert_float(second.initial_cultivation_exp).is_zero()
	assert_str(second.display_name).is_equal("Pawn")


func test_player_preset_matches_accepted_baseline() -> void:
	var data: PawnData = load(PLAYER_DATA_PATH)

	assert_object(data).is_not_null()
	assert_str(String(data.id)).is_equal("player_001")
	assert_str(String(data.faction)).is_equal("player")
	assert_str(data.sub_realm).is_equal("三层")
	assert_str(String(data.spirit_root)).is_equal("金灵根")
	assert_float(data.max_health).is_equal(120.0)
	assert_float(data.max_shield).is_equal(40.0)
	assert_float(data.max_spirit).is_equal(100.0)
	assert_float(data.initial_spirit_ratio).is_equal(1.0)
	assert_float(data.initial_cultivation_exp).is_zero()
	assert_str(String(data.weapon.id)).is_equal("qingfeng_sword")
	assert_str(data.weapon.display_name).is_equal("青锋剑")
	assert_str(String(data.weapon.element)).is_equal("metal")
	assert_int(data.weapon.required_realm_tier).is_equal(1)
	assert_float(data.attack).is_equal(28.0)
	assert_float(data.defense).is_equal(5.0)
	assert_float(data.move_speed).is_equal(145.0)
	assert_float(data.attack_range).is_equal(76.0)
	assert_float(data.attack_interval).is_equal(0.8)


## 敌人预设不声明灵力：max_spirit 必须保持 0，从而不创建灵力池与灵力条。
func test_enemy_preset_declares_no_spirit() -> void:
	var data: PawnData = load(ENEMY_DATA_PATH)

	assert_object(data).is_not_null()
	assert_str(String(data.id)).is_equal("enemy_001")
	assert_str(String(data.faction)).is_equal("enemy")
	assert_float(data.max_health).is_equal(180.0)
	assert_float(data.max_shield).is_equal(20.0)
	assert_float(data.max_spirit).is_zero()
	assert_float(data.attack).is_equal(12.0)
	assert_float(data.defense).is_equal(3.0)

## 视图契约：四个通知方法与四个信号一一对应；无观察者时安全返回，有观察者时每个只发射一次。
func test_notify_methods_emit_matching_signal_once() -> void:
	var data: PawnData = PawnData.new()
	data.notify_identity_changed()
	data.notify_attributes_changed()
	data.notify_realm_changed()
	data.notify_build_changed()

	var events: Array[String] = []
	data.identity_changed.connect(func(_changed: PawnData) -> void: events.append("identity"))
	data.attributes_changed.connect(func(_changed: PawnData) -> void: events.append("attributes"))
	data.realm_changed.connect(func(_changed: PawnData) -> void: events.append("realm"))
	data.build_changed.connect(func(_changed: PawnData) -> void: events.append("build"))

	data.notify_identity_changed()
	data.notify_attributes_changed()
	data.notify_realm_changed()
	data.notify_build_changed()

	assert_int(events.size()).is_equal(4)
	assert_str(events[0]).is_equal("identity")
	assert_str(events[1]).is_equal("attributes")
	assert_str(events[2]).is_equal("realm")
	assert_str(events[3]).is_equal("build")