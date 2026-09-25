extends GdUnitTestSuite

## 集成层：PawnInfoPanel 的绑定生命周期 —— 绑定真实 Pawn、信号驱动刷新、解绑后不再接收旧单位信号。
## 使用真实面板场景 + 真实 Pawn 场景与预设；本层不检查视觉布局（由 headless 套件与运行态证据覆盖）。

const PANEL_SCENE_PATH: String = "res://game/ui/pawn_info_panel.tscn"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const ATTRIBUTE_SECTION_PATH: String = "Margin/Panel/Content/AttributeSection"
const BUILD_SECTION_PATH: String = "Margin/Panel/Content/BuildSection"
const CULTIVATION_SECTION_PATH: String = "Margin/Panel/Content/CultivationSection"
const CULTIVATION_LABEL_PATH: String = "Margin/Panel/Content/CultivationSection/CultivationLabel"
const CULTIVATION_PROGRESS_PATH: String = "Margin/Panel/Content/CultivationSection/CultivationProgress"
const BREAKTHROUGH_PREVIEW_PATH: String = "Margin/Panel/Content/CultivationSection/BreakthroughRow/BreakthroughPreviewLabel"
const BREAKTHROUGH_BUTTON_PATH: String = "Margin/Panel/Content/CultivationSection/BreakthroughRow/BreakthroughButton"
const VITAL_SECTION_PATH: String = "Margin/Panel/Content/VitalSection"
const SPIRIT_ROW_PATH: String = "Margin/Panel/Content/VitalSection/SpiritRow"
const HEALTH_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/HealthRow/ValueLabel"
const SHIELD_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/ShieldRow/ValueLabel"
const NAME_LABEL_PATH: String = "Margin/Panel/Content/HeaderSection/NameLabel"
const APPROX: float = 0.001


func _spawn_panel() -> PawnInfoPanel:
	var scene: PackedScene = load(PANEL_SCENE_PATH)
	var panel: PawnInfoPanel = scene.instantiate() as PawnInfoPanel
	auto_free(panel)
	add_child(panel)
	return panel


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path)
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func test_panel_binds_real_pawn_and_renders_identity() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()

	var bind_events: Array[Pawn] = []
	panel.pawn_bound.connect(func(bound: Pawn) -> void: bind_events.append(bound))

	assert_bool(panel.is_bound()).is_false()
	assert_bool(panel.visible).is_false()

	panel.bind_pawn(pawn)

	assert_bool(panel.is_bound()).is_true()
	assert_bool(panel.visible).is_true()
	assert_object(panel.get_bound_pawn()).is_same(pawn)
	assert_int(bind_events.size()).is_equal(1)

	var name_label: Label = panel.get_node(NAME_LABEL_PATH)
	assert_str(name_label.text).is_equal("测试修士")
	var snapshot: Dictionary = panel.get_snapshot()
	var identity: Dictionary = snapshot["identity"]
	assert_str(String(identity["realm"])).is_equal("炼气")
	assert_str(String(identity["build_tag"])).is_equal("剑修 · 御剑斩")
	var build_label: Label = panel.get_node("Margin/Panel/Content/BuildSection/BuildLabel")
	assert_bool(build_label.text.contains("功法  1 / 1")).is_true()
	assert_bool(build_label.text.contains("武器  1 / 1")).is_true()
	assert_bool(build_label.text.contains("青锋剑（剑 · 金）")).is_true()


func test_vitals_follow_real_pool_values() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(pawn)

	var health_label: Label = panel.get_node(HEALTH_LABEL_PATH)
	var shield_label: Label = panel.get_node(SHIELD_LABEL_PATH)
	assert_str(health_label.text).is_equal("气血  120 / 120")
	assert_str(shield_label.text).is_equal("护体  40 / 40")

	# 既有伤害路由先扣护体：10 点有效伤害只改变护体行，生命行保持满值。
	pawn.take_damage(pawn.data.defense + 10.0)
	assert_str(shield_label.text).is_equal("护体  30 / 40")
	assert_str(health_label.text).is_equal("气血  120 / 120")

	# 再打出 60 点有效伤害：30 点打空剩余护体，30 点进入生命。
	pawn.take_damage(pawn.data.defense + 60.0)
	assert_str(shield_label.text).is_equal("护体  0 / 40")
	assert_str(health_label.text).is_equal("气血  90 / 120")
	var snapshot: Dictionary = panel.get_snapshot()
	assert_float(float(snapshot["vitals"]["health"]["current"])).is_equal_approx(90.0, APPROX)

	pawn.try_spend_spirit(30.0)
	var spirit_row: HBoxContainer = panel.get_node(SPIRIT_ROW_PATH)
	var spirit_label: Label = spirit_row.get_node("ValueLabel")
	assert_str(spirit_label.text).is_equal("灵力  70 / 100")


## 静态数据变更也要驱动刷新：PawnData 的视图信号用于此路径。
func test_static_data_notification_refreshes_identity() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, data)
	await await_idle_frame()
	panel.bind_pawn(pawn)

	# GDScript 的 lambda 按值捕获标量，刷新次数用数组累计。
	var refresh_events: Array[Dictionary] = []
	panel.refreshed.connect(func(snapshot: Dictionary) -> void: refresh_events.append(snapshot))
	var name_label: Label = panel.get_node(NAME_LABEL_PATH)
	assert_str(name_label.text).is_equal("测试修士")

	data.display_name = "被改名的修士"
	data.notify_identity_changed()

	assert_int(refresh_events.size()).is_equal(1)
	assert_str(name_label.text).is_equal("被改名的修士")


func test_unbind_clears_display_and_disconnects_signals() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(pawn)

	var unbound_events: Array[Pawn] = []
	panel.pawn_unbound.connect(func(unbound: Pawn) -> void: unbound_events.append(unbound))
	var refresh_events: Array[Dictionary] = []
	panel.refreshed.connect(func(snapshot: Dictionary) -> void: refresh_events.append(snapshot))

	panel.unbind()

	assert_bool(panel.is_bound()).is_false()
	assert_bool(panel.visible).is_false()
	assert_int(unbound_events.size()).is_equal(1)
	assert_object(panel.get_bound_pawn()).is_null()
	var name_label: Label = panel.get_node(NAME_LABEL_PATH)
	assert_str(name_label.text).is_empty()

	pawn.take_damage(pawn.data.defense + 10.0)
	assert_int(refresh_events.size()).is_zero()


## 切换绑定必须走“先解绑再绑定”：旧单位后续变化不得污染新单位的快照。
func test_rebinding_switches_source_pawn() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(player)
	panel.bind_pawn(enemy)

	assert_object(panel.get_bound_pawn()).is_same(enemy)
	var snapshot: Dictionary = panel.get_snapshot()
	assert_str(String(snapshot["identity"]["name"])).is_equal("试炼傀儡")
	assert_str(String(snapshot["identity"]["faction"])).is_equal("enemy")
	assert_bool(bool(snapshot["identity"]["has_realm"])).is_false()

	var enemy_health_before: String = (panel.get_node(HEALTH_LABEL_PATH) as Label).text
	player.take_damage(player.data.defense + 20.0)
	assert_str((panel.get_node(HEALTH_LABEL_PATH) as Label).text).is_equal(enemy_health_before)

	# 有效伤害 30 先被护体 20 全部吸收，剩余 10 落入气血：180 - 10 = 170。
	enemy.take_damage(enemy.data.defense + 30.0)
	assert_str((panel.get_node(SHIELD_LABEL_PATH) as Label).text).is_equal("护体  0 / 20")
	assert_str((panel.get_node(HEALTH_LABEL_PATH) as Label).text).is_equal("气血  170 / 180")


## 无灵力单位不显示灵力行；无境界单位的 Build 区只给“不适用”，修为区完全隐藏。
func test_enemy_pawn_hides_spirit_row_and_build_capacity() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(enemy)

	var spirit_row: HBoxContainer = panel.get_node(SPIRIT_ROW_PATH)
	assert_bool(spirit_row.visible).is_false()
	var build_label: Label = panel.get_node("Margin/Panel/Content/BuildSection/BuildLabel")
	assert_str(build_label.text).is_equal(PawnInfoModel.BUILD_UNAVAILABLE_TEXT)
	assert_bool((panel.get_node(CULTIVATION_SECTION_PATH) as VBoxContainer).visible).is_false()
	assert_str((panel.get_node(CULTIVATION_LABEL_PATH) as Label).text).is_empty()


## 修为变化应通过 Pawn 信号刷新信息卡；达到阈值后同一行追加“可突破”。
func test_cultivation_progress_refreshes_panel() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(pawn)

	var cultivation_section: VBoxContainer = panel.get_node(CULTIVATION_SECTION_PATH)
	var cultivation_label: Label = panel.get_node(CULTIVATION_LABEL_PATH)
	var cultivation_progress: ProgressBar = panel.get_node(CULTIVATION_PROGRESS_PATH)
	assert_bool(cultivation_section.visible).is_true()
	assert_str(cultivation_label.text).is_equal("修为  0%  0 / 100  → 筑基")
	assert_float(cultivation_progress.value).is_zero()

	var refresh_events: Array[Dictionary] = []
	panel.refreshed.connect(func(snapshot: Dictionary) -> void: refresh_events.append(snapshot))
	assert_float(pawn.gain_cultivation_exp(40.0)).is_equal_approx(40.0, APPROX)
	assert_int(refresh_events.size()).is_equal(1)
	assert_str(cultivation_label.text).is_equal("修为  40%  40 / 100  → 筑基")
	assert_float(cultivation_progress.value).is_equal_approx(0.4, APPROX)

	pawn.gain_cultivation_exp(60.0)
	assert_str(cultivation_label.text).is_equal("修为  100%  100 / 100  → 筑基  （可突破）")
	assert_float(cultivation_progress.value).is_equal_approx(1.0, APPROX)


func test_compact_mode_hides_attribute_and_build_sections() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(pawn)

	var attribute_section: VBoxContainer = panel.get_node(ATTRIBUTE_SECTION_PATH)
	var build_section: VBoxContainer = panel.get_node(BUILD_SECTION_PATH)
	var cultivation_section: VBoxContainer = panel.get_node(CULTIVATION_SECTION_PATH)
	assert_bool(panel.is_compact()).is_false()
	assert_bool(attribute_section.visible).is_true()
	assert_bool(build_section.visible).is_true()
	assert_bool(cultivation_section.visible).is_true()

	panel.set_compact(true)
	assert_bool(panel.is_compact()).is_true()
	assert_bool(attribute_section.visible).is_false()
	assert_bool(build_section.visible).is_false()
	assert_bool(cultivation_section.visible).is_false()
	var vital_section: VBoxContainer = panel.get_node(VITAL_SECTION_PATH)
	assert_bool(vital_section.visible).is_true()

	panel.set_compact(false)
	assert_bool(attribute_section.visible).is_true()
	assert_bool(build_section.visible).is_true()
	assert_bool(cultivation_section.visible).is_true()


func test_binding_null_pawn_unbinds() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(pawn)
	assert_bool(panel.is_bound()).is_true()

	panel.bind_pawn(null)
	assert_bool(panel.is_bound()).is_false()
	assert_bool(panel.visible).is_false()

## INC-UI-017：按钮只表达意图；未就绪点击不发出请求，就绪后发出一次，真正推进仍由 Pawn 裁决。
func test_breakthrough_button_and_capacity_preview() -> void:
	var panel: PawnInfoPanel = _spawn_panel()
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()
	panel.bind_pawn(pawn)

	var preview_label: Label = panel.get_node(BREAKTHROUGH_PREVIEW_PATH)
	var breakthrough_button: Button = panel.get_node(BREAKTHROUGH_BUTTON_PATH)
	var requests: Array[Pawn] = []
	panel.breakthrough_requested.connect(func(requested: Pawn) -> void: requests.append(requested))

	assert_bool(breakthrough_button.disabled).is_true()
	assert_str(preview_label.text).is_equal("突破后容量：功法 2 / 武器 1 / 主动 3 / 被动 2")
	breakthrough_button.pressed.emit()
	assert_int(requests.size()).is_zero()

	assert_float(pawn.gain_cultivation_exp(100.0)).is_equal_approx(100.0, APPROX)
	assert_bool(pawn.is_ready_for_breakthrough()).is_true()
	assert_bool(breakthrough_button.disabled).is_false()
	breakthrough_button.pressed.emit()
	assert_int(requests.size()).is_equal(1)
	assert_object(requests[0]).is_same(pawn)

	assert_bool(pawn.try_breakthrough()).is_true()
	var snapshot: Dictionary = panel.get_snapshot()
	assert_str(String(snapshot["identity"]["realm"])).is_equal("筑基")
	var build_label: Label = panel.get_node("Margin/Panel/Content/BuildSection/BuildLabel")
	assert_bool(build_label.text.contains("功法  1 / 2")).is_true()
	assert_bool(build_label.text.contains("武器  1 / 1")).is_true()
	assert_bool(build_label.text.contains("主动  2 / 3")).is_true()
	assert_bool(build_label.text.contains("被动  0 / 2")).is_true()
	assert_str(preview_label.text).is_equal("突破后容量：功法 3 / 武器 1 / 主动 4 / 被动 3")
	assert_bool(breakthrough_button.disabled).is_true()