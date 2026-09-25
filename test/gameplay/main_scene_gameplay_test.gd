extends GdUnitTestSuite

## 玩法/场景层：在真实主场景上跑通“选中 → 受伤 → HUD 与头顶资源条同步 → 死亡”。
## 本层验证的是玩家实际看到的整链路结果，允许跨场景、HUD、资源池与战斗逻辑。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const SELECTED_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/SelectedLabel"
const ORDER_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/OrderLabel"
const SKILL_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/SkillLabel"
const BUILD_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/BuildLabel"
const INFO_PANEL_PATH: String = "HUD/PawnInfoPanel"

## 面板内部节点路径（相对 PawnInfoPanel 根节点）。
const INFO_PANEL_SHIELD_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/ShieldRow/ValueLabel"
const INFO_PANEL_HEALTH_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/HealthRow/ValueLabel"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const APPROX: float = 0.001


func _spawn_main() -> Node2D:
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node2D = scene.instantiate()
	auto_free(main)
	add_child(main)
	return main


## 安全护栏：任何用例触碰暂停后，都必须恢复 SceneTree，否则后续用例会被冻结。
func after_test() -> void:
	if get_tree() != null:
		get_tree().paused = false


## 把敌人移到视口外，避免 AI 在断言期间改变玩家数值，保证用例可重复。
func _park_enemy(main: Node2D) -> Pawn:
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	enemy.global_position = Vector2(-4000.0, -4000.0)
	return enemy


func test_main_scene_boots_with_two_pawns_and_hud() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	assert_object(player).is_not_null()
	assert_object(enemy).is_not_null()
	assert_bool(player.is_alive()).is_true()
	assert_bool(enemy.is_alive()).is_true()

	var selected_label: Label = main.get_node(SELECTED_LABEL_PATH)
	assert_object(selected_label).is_not_null()


func test_selected_pawn_hud_tracks_shield_damage() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var selected_label: Label = main.get_node(SELECTED_LABEL_PATH)
	main.call("_set_selected_pawn", player)
	await await_idle_frame()
	var before: String = selected_label.text
	assert_bool(before.is_empty()).is_false()

	player.take_damage(player.data.defense + 10.0)
	await await_idle_frame()

	var after: String = selected_label.text
	assert_bool(after == before).is_false()
	var expected_shield: float = player.data.max_shield - 10.0
	assert_bool(after.contains("%.0f" % expected_shield)).is_true()
	assert_float(player.current_shield).is_equal_approx(expected_shield, APPROX)


## 显示策略（INC-CROSS-002 已验收）：整组资源条初始隐藏，生命状态变化时显示。
## 单个条的 visible 表示“有有效资源池、参与布局”，整组显隐由 PawnStatusBars.visible 决定。
func test_health_bars_start_hidden_and_reveal_on_damage() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var bars: PawnStatusBars = player.status_bars
	assert_object(bars).is_not_null()
	assert_bool(bars.visible).is_false()

	var health_bar: ResourceBar = bars.get_bar(HealthComponent.HEALTH_RESOURCE_ID)
	assert_object(health_bar).is_not_null()
	assert_bool(health_bar.visible).is_true()

	player.take_damage(player.data.defense + 10.0)
	await await_idle_frame()

	assert_bool(bars.visible).is_true()


func test_lethal_damage_marks_pawn_dead_in_scene() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var lethal: float = player.data.defense + player.data.max_health + player.data.max_shield + 50.0
	player.take_damage(lethal)
	await await_idle_frame()

	assert_bool(player.is_dead()).is_true()
	assert_float(player.current_health).is_zero()
	assert_int(player.collision_layer).is_zero()
	assert_bool(player.is_alive()).is_false()


## 暂停契约：开关必须同步置位 SceneTree.paused 并切换暂停覆盖层。
## 本用例刻意不在暂停状态下等待时间流逝——那会阻塞测试运行器自身的调度；
## “暂停期间 Pawn 位置完全不变”由运行态冒烟证据覆盖（INC-CORE-001 已验收结论）。
func test_pause_toggles_tree_state_and_overlay() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var overlay: Control = main.get_node("HUD/PauseOverlay")
	var pause_label: Label = main.get_node("HUD/PauseStateLabel")
	assert_bool(overlay.visible).is_false()
	assert_bool(get_tree().paused).is_false()

	main.call("_set_paused", true)
	assert_bool(get_tree().paused).is_true()
	assert_bool(overlay.visible).is_true()
	assert_str(pause_label.text).is_equal("游戏已暂停")

	main.call("_set_paused", false)
	assert_bool(get_tree().paused).is_false()
	assert_bool(overlay.visible).is_false()
	assert_str(pause_label.text).is_equal("实时运行中")


## 构造一次真实按键事件并交给主场景输入入口，验证 InputMap 到命令的路由。
func _press_key(main: Node2D, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	main.call("_unhandled_input", event)


func test_cast_skill_action_is_mapped_to_q() -> void:
	assert_bool(InputMap.has_action("cast_skill")).is_true()
	var has_q_key: bool = false
	for event: InputEvent in InputMap.action_get_events("cast_skill"):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null and key_event.keycode == KEY_Q:
			has_q_key = true
	assert_bool(has_q_key).is_true()


## 未选中玩家、选中但没有有效敌方目标时，Q 键不得扣灵力、进冷却或伪造技能指令。
func test_cast_skill_without_selection_or_target_is_no_op() -> void:
	var main: Node2D = _spawn_main()
	var enemy: Pawn = _park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	var skill: ActiveSkillDefinition = player.data.active_skill
	assert_object(skill).is_not_null()
	var spirit_before: float = player.current_spirit
	var enemy_total_before: float = enemy.current_shield + enemy.current_health

	_press_key(main, KEY_Q)
	await await_idle_frame()
	assert_str(order_label.text).is_equal("指令：-")

	main.call("_set_selected_pawn", player)
	await await_idle_frame()
	_press_key(main, KEY_Q)
	await await_idle_frame()

	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_bool(order_label.text.contains("施放技能")).is_false()
	assert_float(enemy.current_shield + enemy.current_health).is_equal_approx(enemy_total_before, APPROX)


## 选中玩家并对敌人下达攻击命令后，Q 键把普通攻击目标升级为一次技能命令，HUD 立即反映。
func test_cast_skill_forwards_valid_enemy_target() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	# 目标放在技能距离之外，确保本用例只验证命令记录，不立即施放并扣灵力。
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	var spirit_before: float = player.current_spirit

	main.call("_set_selected_pawn", player)
	main.call("_handle_command", main.get_canvas_transform() * enemy.global_position)
	await await_idle_frame()
	assert_str(order_label.text).is_equal("指令：攻击 %s" % enemy.data.display_name)

	_press_key(main, KEY_Q)
	await await_idle_frame()

	assert_bool(order_label.text.contains("施放技能")).is_true()
	assert_bool(order_label.text.contains(player.data.active_skill.display_name)).is_true()
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)


## HUD 技能行初始态：未选中单位显示占位文案，选中玩家后显示技能名、Q 键位、消耗与可用状态。
func test_skill_label_initial_and_available_state() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var skill_label: Label = main.get_node(SKILL_LABEL_PATH)
	assert_str(skill_label.text).is_equal("技能：-")

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var skill: ActiveSkillDefinition = player.data.active_skill
	assert_object(skill).is_not_null()
	main.call("_set_selected_pawn", player)
	await await_idle_frame()

	assert_bool(skill_label.text.contains("技能：[Q]")).is_true()
	assert_bool(skill_label.text.contains(skill.display_name)).is_true()
	assert_bool(skill_label.text.contains("消耗 %.0f" % skill.spirit_cost)).is_true()
	assert_bool(skill_label.text.contains("可用")).is_true()


## 施法成功后 skill_cast / skill_cooldown_changed 必须让 HUD 立即显示剩余冷却。
func test_skill_label_shows_cooldown_after_cast() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	enemy.global_position = player.global_position + Vector2(40.0, 0.0)
	var skill: ActiveSkillDefinition = player.data.active_skill
	var skill_label: Label = main.get_node(SKILL_LABEL_PATH)
	main.call("_set_selected_pawn", player)
	await await_idle_frame()
	assert_bool(skill_label.text.contains("可用")).is_true()

	assert_bool(player.cast_skill(skill, enemy)).is_true()
	await await_idle_frame()

	# 等待帧会让 Pawn._physics_process 推进冷却，因此只要求冷却处于 (0, skill.cooldown] 区间。
	var remaining: float = player.get_skill_cooldown_remaining(skill.id)
	assert_bool(remaining > 0.0 and remaining <= skill.cooldown).is_true()
	assert_bool(skill_label.text.contains("冷却中")).is_true()
	assert_bool(skill_label.text.contains("可用")).is_false()


## 灵力不足时 HUD 必须给出原因，而不是继续显示“可用”。
func test_skill_label_reports_insufficient_spirit() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var skill: ActiveSkillDefinition = player.data.active_skill
	var skill_label: Label = main.get_node(SKILL_LABEL_PATH)
	main.call("_set_selected_pawn", player)
	await await_idle_frame()

	assert_bool(player.try_spend_spirit(player.current_spirit - 5.0)).is_true()
	await await_idle_frame()

	assert_float(player.current_spirit).is_equal_approx(5.0, APPROX)
	assert_bool(skill_label.text.contains("灵力不足")).is_true()


## 没有主动技能的单位（正式场景中的试炼傀儡）必须显示稳定的“技能：无”，而不是残留上一单位状态。
func test_skill_label_shows_none_for_pawn_without_skill() -> void:
	var main: Node2D = _spawn_main()
	await await_idle_frame()

	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	assert_object(enemy.data.active_skill).is_null()
	var skill_label: Label = main.get_node(SKILL_LABEL_PATH)
	main.call("_set_selected_pawn", enemy)
	await await_idle_frame()

	assert_str(skill_label.text).is_equal("技能：无")

## HUD Build 行初始态：未选中单位显示占位文案，选中玩家后显示境界与各槽位占用 / 容量。
func test_build_label_initial_and_player_capacity_row() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var build_label: Label = main.get_node(BUILD_LABEL_PATH)
	assert_str(build_label.text).is_equal("Build：-")

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	main.call("_set_selected_pawn", player)
	await await_idle_frame()

	var realm: RealmDefinition = player.get_realm()
	assert_object(realm).is_not_null()
	assert_bool(build_label.text.contains("境界：%s" % realm.display_name)).is_true()
	assert_bool(build_label.text.contains("功法 1 / %d" % realm.technique_slots)).is_true()
	assert_bool(build_label.text.contains("主动 1 / %d" % realm.active_skill_slots)).is_true()
	assert_bool(build_label.text.contains("被动 0 / %d" % realm.passive_skill_slots)).is_true()
	# 玩家预设是合法 Build：不得出现错误摘要后缀。
	assert_bool(build_label.text.contains("Build：")).is_false()


## 没有修炼体系的单位（正式场景中的试炼傀儡）必须显示“境界：无”与“Build：不适用”。
func test_build_label_reports_not_applicable_without_realm() -> void:
	var main: Node2D = _spawn_main()
	var enemy: Pawn = _park_enemy(main)
	await await_idle_frame()

	assert_object(enemy.get_realm()).is_null()
	var build_label: Label = main.get_node(BUILD_LABEL_PATH)
	main.call("_set_selected_pawn", enemy)
	await await_idle_frame()

	assert_str(build_label.text).is_equal("境界：无    Build：不适用")


## Build 不合法时，同一行必须直接给出首条原因，而不是只说“不合法”。
func test_build_label_appends_first_validation_reason() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	var first: TechniqueDefinition = TechniqueDefinition.new()
	first.id = &"sword_like"
	first.display_name = "剑意"
	first.conflict_tags = [&"test_conflict_tag"]
	var second: TechniqueDefinition = TechniqueDefinition.new()
	second.id = &"body_like"
	second.display_name = "体魄"
	second.conflict_tags = [&"test_conflict_tag"]
	var techniques: Array[TechniqueDefinition] = [first, second]
	data.techniques.assign(techniques)
	player.data = data

	var build_label: Label = main.get_node(BUILD_LABEL_PATH)
	main.call("_set_selected_pawn", player)
	await await_idle_frame()

	assert_bool(build_label.text.contains("Build：")).is_true()
	assert_bool(build_label.text.contains("功法互斥")).is_true()
	assert_bool(build_label.text.contains("剑意")).is_true()
	assert_bool(build_label.text.contains("体魄")).is_true()


## Build 行与其它 HUD 行共用同一套信号驱动刷新：灵力变化后容量占用必须保持不变。
func test_build_label_refreshes_with_resource_signals() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var build_label: Label = main.get_node(BUILD_LABEL_PATH)
	var selected_label: Label = main.get_node(SELECTED_LABEL_PATH)
	main.call("_set_selected_pawn", player)
	await await_idle_frame()
	var build_before: String = build_label.text
	assert_bool(build_before.contains("境界：")).is_true()

	# 扣除灵力触发 spirit_changed → 整块 HUD 重新计算；Build 行内容不受资源数值影响。
	assert_bool(player.try_spend_spirit(10.0)).is_true()
	await await_idle_frame()

	assert_str(build_label.text).is_equal(build_before)
	assert_bool(selected_label.text.contains("灵力：%.0f" % player.current_spirit)).is_true()

## 信息卡路由（INC-CORE-004）：选中玩家后信息卡绑定该单位并显示；取消选中后解绑并隐藏。
func test_info_panel_binds_on_select_and_hides_on_clear() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	assert_bool(panel.is_bound()).is_false()
	assert_bool(panel.visible).is_false()

	main.call("_set_selected_pawn", player)
	await await_idle_frame()

	assert_bool(panel.is_bound()).is_true()
	assert_object(panel.get_bound_pawn()).is_same(player)
	assert_bool(panel.visible).is_true()

	main.call("_set_selected_pawn", null)
	await await_idle_frame()

	assert_bool(panel.is_bound()).is_false()
	assert_bool(panel.visible).is_false()


## 暂停契约扩展到信息卡：暂停看完整信息，恢复运行回到战斗中精简短版。
func test_info_panel_compact_switches_with_pause() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)
	main.call("_set_selected_pawn", main.get_node("Pawns/PlayerPawn"))
	await await_idle_frame()

	main.call("_set_paused", true)
	assert_bool(panel.is_compact()).is_false()

	main.call("_set_paused", false)
	assert_bool(panel.is_compact()).is_true()


## 信息卡数值必须与 HUD 取自同一份真实资源池数据，受伤后立即同步刷新。
func test_info_panel_tracks_damage_like_hud() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	main.call("_set_selected_pawn", player)
	await await_idle_frame()

	var health_label: Label = panel.get_node(INFO_PANEL_HEALTH_LABEL_PATH)
	var shield_label: Label = panel.get_node(INFO_PANEL_SHIELD_LABEL_PATH)
	var health_before: String = health_label.text
	assert_str(health_before).is_equal("气血  %.0f / %.0f" % [player.current_health, player.data.max_health])

	# 第一次命中先消耗护体：护体行跟着变，气血行不动。
	player.take_damage(player.data.defense + 10.0)
	await await_idle_frame()

	assert_str(shield_label.text).is_equal("护体  %.0f / %.0f" % [player.current_shield, player.data.max_shield])
	assert_str(health_label.text).is_equal(health_before)

	# 第二次命中打穿护体余量：气血行同步刷新，且与资源池真实数值一致。
	player.take_damage(player.data.defense + player.data.max_shield + 30.0)
	await await_idle_frame()

	assert_bool(health_label.text == health_before).is_false()
	var snapshot: Dictionary = panel.get_snapshot()
	var health: Dictionary = snapshot["vitals"][PawnInfoModel.HEALTH_KEY]
	assert_float(float(health["current"])).is_equal_approx(player.current_health, APPROX)


## 选中单位阵亡后信息卡必须解绑并隐藏，不能留下已阵亡单位的残影。
func test_info_panel_unbinds_when_selected_pawn_dies() -> void:
	var main: Node2D = _spawn_main()
	_park_enemy(main)
	await await_idle_frame()

	var panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	main.call("_set_selected_pawn", player)
	await await_idle_frame()
	assert_bool(panel.is_bound()).is_true()

	player.take_damage(player.data.defense + player.data.max_shield + player.data.max_health + 10.0)
	await await_idle_frame()

	assert_bool(player.is_dead()).is_true()
	assert_bool(panel.is_bound()).is_false()
	assert_bool(panel.visible).is_false()