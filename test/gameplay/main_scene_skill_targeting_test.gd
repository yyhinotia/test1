extends GdUnitTestSuite

## 玩法层：主场景目标选择闭环（INC-CORE-006）。
## 用真实 main.tscn、SkillBar、Pawn 目标规则和 PlayerController 命令，不复制敌我判断。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const ORDER_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/OrderLabel"
const INFO_PANEL_PATH: String = "HUD/BottomLeftDock/PawnInfoPanel"
const SELECTED_LABEL_PATH: String = "HUD/HudMargin/HudPanel/HudContent/SelectedLabel"
const BUILD_PANEL_PATH: String = "HUD/BuildLoadoutPanel"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const GUARD_SKILL_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const ALLY_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const APPROX: float = 0.001
const DELTA: float = 1.0 / 60.0


func _spawn_main() -> Node2D:
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node2D = scene.instantiate()
	auto_free(main)
	add_child(main)
	return main


func _spawn_main_with_player_data(data: PawnData) -> Node2D:
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node2D = scene.instantiate()
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	player.data = data
	auto_free(main)
	add_child(main)
	return main


func _duplicate_player_data(first: ActiveSkillDefinition, second: ActiveSkillDefinition = null) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	var skills: Array[ActiveSkillDefinition] = []
	if first != null:
		skills.append(first)
	if second != null:
		skills.append(second)
	data.active_skill = first
	data.active_skills = skills
	data.max_spirit = 100.0
	data.initial_spirit_ratio = 1.0
	return data


func _make_ally_skill() -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = &"test_ally_bless"
	skill.display_name = "友方灵息"
	skill.target_type = ActiveSkillDefinition.SkillTargetType.ALLY
	skill.effect_type = ActiveSkillDefinition.SkillEffectType.HEAL
	skill.effect_value = 20.0
	skill.spirit_cost = 10.0
	skill.cooldown = 1.0
	skill.cast_range = 200.0
	return skill


## 本套件只验证输入路由，关闭控制器物理帧，避免敌人 AI 在断言之间改变位置/资源。
func _isolate_controllers(main: Node2D) -> void:
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	(player.get_controller() as PawnController).set_physics_process(false)
	(enemy.get_controller() as PawnController).set_physics_process(false)


func after_test() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _screen_position(main: Node2D, world_position: Vector2) -> Vector2:
	return main.get_canvas_transform() * world_position


func _send_key(main: Node2D, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	main.call("_unhandled_input", event)


func _send_mouse_button(main: Node2D, button: MouseButton, screen_position: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = screen_position
	main.call("_unhandled_input", event)


func _send_mouse_motion(main: Node2D, screen_position: Vector2) -> void:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = screen_position
	main.call("_unhandled_input", event)


func _begin_enemy_targeting(main: Node2D, player: Pawn, bar: SkillBar) -> ActiveSkillDefinition:
	main.call("_set_selected_pawn", player)
	_send_key(main, KEY_1)
	assert_bool(bar.is_targeting()).is_true()
	var skill: ActiveSkillDefinition = bar.get_targeting_skill()
	assert_object(skill).is_not_null()
	assert_int(skill.target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ENEMY)
	return skill


## 合法左键只确认一次：生成技能命令并退出 TARGETING，不在确认时提前扣灵力/CD/伤害。
func test_valid_left_click_confirms_target_and_exits_targeting_once() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	var enemy_screen_position: Vector2 = _screen_position(main, enemy.global_position)

	var skill: ActiveSkillDefinition = _begin_enemy_targeting(main, player, bar)
	var spirit_before: float = player.current_spirit
	var effective_health_before: float = enemy.current_shield + enemy.current_health

	_send_mouse_button(main, MOUSE_BUTTON_LEFT, enemy_screen_position)

	assert_bool(bar.is_targeting()).is_false()
	assert_bool(order_label.text.contains("施放技能")).is_true()
	assert_bool(order_label.text.contains(skill.display_name)).is_true()
	assert_bool(order_label.text.contains(enemy.data.display_name)).is_true()
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()
	assert_float(enemy.current_shield + enemy.current_health).is_equal_approx(effective_health_before, APPROX)

	# 再次左键已不再处于 TARGETING，只能走普通选中；控制器技能命令不得被二次改写。
	var controller: PlayerController = player.get_controller() as PlayerController
	var description_after_confirm: String = controller.get_order_description()
	_send_mouse_button(main, MOUSE_BUTTON_LEFT, enemy_screen_position)
	assert_str(controller.get_order_description()).is_equal(description_after_confirm)
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()


## 非法 Pawn/空白点击必须保持 TARGETING，且不生成任何移动/攻击/技能命令。
func test_illegal_pawn_and_empty_clicks_keep_targeting_without_side_effects() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	var skill: ActiveSkillDefinition = _begin_enemy_targeting(main, player, bar)
	var spirit_before: float = player.current_spirit
	var order_before: String = order_label.text

	# ENEMY 技能点击自己：目标规则判非法，不确认、不选中、不移动。
	_send_mouse_button(main, MOUSE_BUTTON_LEFT, _screen_position(main, player.global_position))
	assert_bool(bar.is_targeting()).is_true()
	assert_str(order_label.text).is_equal(order_before)
	assert_bool(player.is_target_highlight_visible()).is_false()

	# 空白地同样不能穿透成移动命令。
	_send_mouse_button(main, MOUSE_BUTTON_LEFT, Vector2(-4000.0, -4000.0))
	assert_bool(bar.is_targeting()).is_true()
	assert_str(order_label.text).is_equal(order_before)
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()


## 左键点己方单位：进入选中态并绑定玩家专属面板（技能栏 / Build 面板跟随玩家单位）。
func test_left_click_friendly_pawn_selects_player() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var info_panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)

	_send_mouse_button(main, MOUSE_BUTTON_LEFT, _screen_position(main, player.global_position))

	assert_bool(player.selection_indicator.visible).is_true()
	assert_object(info_panel.get_bound_pawn()).is_same(player)
	assert_object(bar.get_bound_pawn()).is_same(player)


## 左键点空白地：已选中玩家单位时下达移动命令，移动入口不再依赖右键（INC-CORE-013）。
func test_left_click_ground_orders_move_for_selected_player() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	main.call("_set_selected_pawn", player)

	_send_mouse_button(main, MOUSE_BUTTON_LEFT, Vector2(250.0, 250.0))

	assert_bool(order_label.text.contains("移动到")).is_true()
	assert_object(bar.get_bound_pawn()).is_same(player)


## 左键点敌方单位：选中该敌方、绑定敌方信息 UI，且不产生攻击 / 移动 / 技能命令（INC-UI-019）。
func test_left_click_enemy_selects_it_and_binds_enemy_info_ui() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var info_panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)
	var build_panel: BuildLoadoutPanel = main.get_node(BUILD_PANEL_PATH)
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	var selected_label: Label = main.get_node(SELECTED_LABEL_PATH)
	enemy.global_position = player.global_position + Vector2(300.0, 0.0)
	main.call("_set_selected_pawn", player)
	var controller: PlayerController = player.get_controller() as PlayerController
	var order_before: String = controller.get_order_description()

	_send_mouse_button(main, MOUSE_BUTTON_LEFT, _screen_position(main, enemy.global_position))

	# 选中敌方：信息卡跟随敌方，玩家专属面板全部解绑并隐藏。
	assert_bool(enemy.selection_indicator.visible).is_true()
	assert_bool(player.selection_indicator.visible).is_false()
	assert_object(info_panel.get_bound_pawn()).is_same(enemy)
	assert_bool(info_panel.visible).is_true()
	assert_object(bar.get_bound_pawn()).is_null()
	assert_bool(bar.visible).is_false()
	assert_object(build_panel.get_bound_pawn()).is_null()

	# HUD 选中行改为敌方事实，指令行不再借用玩家指令。
	assert_bool(selected_label.text.contains(enemy.data.display_name)).is_true()
	assert_bool(selected_label.text.contains("阵营：enemy")).is_true()
	assert_str(order_label.text).is_equal("指令：-")

	# 只看信息：不得顺手下达攻击 / 移动命令，也不得扣灵力或改写玩家指令。
	assert_str(controller.get_order_description()).is_equal(order_before)
	assert_float(player.current_spirit).is_equal_approx(player.data.max_spirit, APPROX)


## 右键：TARGETING 期间只取消瞄准；非 TARGETING 时不再移动，只保留对敌方下达普通攻击。
func test_right_click_cancels_targeting_and_never_orders_move() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	_begin_enemy_targeting(main, player, bar)
	var order_before: String = order_label.text

	_send_mouse_button(main, MOUSE_BUTTON_RIGHT, Vector2(250.0, 250.0))
	assert_bool(bar.is_targeting()).is_false()
	assert_str(order_label.text).is_equal(order_before)

	# 移动入口在 INC-CORE-013 中整体搬到左键：右键点地面必须保持零命令。
	_send_mouse_button(main, MOUSE_BUTTON_RIGHT, Vector2(250.0, 250.0))
	assert_bool(order_label.text.contains("移动到")).is_false()
	assert_str(order_label.text).is_equal(order_before)


## 右键点敌方仍保留普通攻击命令：本次只收窄「移动」，不收回 INC-COMBAT-001 的攻击能力。
func test_right_click_enemy_keeps_attack_order() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	enemy.global_position = player.global_position + Vector2(300.0, 0.0)
	main.call("_set_selected_pawn", player)

	_send_mouse_button(main, MOUSE_BUTTON_RIGHT, _screen_position(main, enemy.global_position))

	assert_bool(order_label.text.contains("攻击")).is_true()
	assert_bool(order_label.text.contains(enemy.data.display_name)).is_true()


## Escape 由 InputMap 提供并取消 TARGETING，所有高亮同步清理。
func test_escape_action_cancels_and_clears_highlight() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	enemy.global_position = player.global_position + Vector2(200.0, 0.0)
	_begin_enemy_targeting(main, player, bar)
	_send_mouse_motion(main, _screen_position(main, enemy.global_position))
	assert_bool(enemy.is_target_highlight_visible()).is_true()

	assert_bool(InputMap.has_action("cancel_targeting")).is_true()
	var has_escape: bool = false
	for event: InputEvent in InputMap.action_get_events("cancel_targeting"):
		var key_event: InputEventKey = event as InputEventKey
		if key_event != null and key_event.keycode == KEY_ESCAPE:
			has_escape = true
	assert_bool(has_escape).is_true()

	_send_key(main, KEY_ESCAPE)
	assert_bool(bar.is_targeting()).is_false()
	assert_bool(enemy.is_target_highlight_visible()).is_false()


## 悬停只给合法目标高亮；移到非法 Pawn 后立即清除，合法性来自 Pawn.is_valid_skill_target()。
func test_hover_highlight_follows_pawn_target_legality() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	enemy.global_position = player.global_position + Vector2(200.0, 0.0)
	_begin_enemy_targeting(main, player, bar)

	_send_mouse_motion(main, _screen_position(main, enemy.global_position))
	assert_bool(enemy.is_target_highlight_visible()).is_true()

	_send_mouse_motion(main, _screen_position(main, player.global_position))
	assert_bool(enemy.is_target_highlight_visible()).is_false()
	assert_bool(player.is_target_highlight_visible()).is_false()

	_send_mouse_motion(main, _screen_position(main, enemy.global_position))
	assert_bool(enemy.is_target_highlight_visible()).is_true()
	_send_key(main, KEY_ESCAPE)
	assert_bool(enemy.is_target_highlight_visible()).is_false()


## 暂停/恢复只冻结时间，不清除目标选择；恢复后仍可确认，且暂停期间不等待帧。
func test_targeting_survives_pause_resume_and_can_confirm_after_resume() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)
	enemy.global_position = player.global_position + Vector2(400.0, 0.0)
	var enemy_screen_position: Vector2 = _screen_position(main, enemy.global_position)
	var skill: ActiveSkillDefinition = _begin_enemy_targeting(main, player, bar)

	main.call("_set_paused", true)
	assert_bool(get_tree().paused).is_true()
	assert_bool(bar.is_targeting()).is_true()
	assert_object(bar.get_targeting_skill()).is_same(skill)

	main.call("_set_paused", false)
	assert_bool(get_tree().paused).is_false()
	_send_mouse_button(main, MOUSE_BUTTON_LEFT, enemy_screen_position)
	assert_bool(bar.is_targeting()).is_false()
	assert_bool(order_label.text.contains(skill.display_name)).is_true()


## 高亮目标死亡时立即自动取消，保留零灵力/CD/伤害副作用。
func test_highlighted_target_death_auto_cancels_targeting() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	enemy.global_position = player.global_position + Vector2(200.0, 0.0)
	var skill: ActiveSkillDefinition = _begin_enemy_targeting(main, player, bar)
	_send_mouse_motion(main, _screen_position(main, enemy.global_position))
	assert_bool(enemy.is_target_highlight_visible()).is_true()
	var spirit_before: float = player.current_spirit

	enemy.take_damage(enemy.data.defense + enemy.data.max_shield + enemy.data.max_health + 50.0)

	assert_bool(enemy.is_dead()).is_true()
	assert_bool(bar.is_targeting()).is_false()
	assert_bool(enemy.is_target_highlight_visible()).is_false()
	assert_float(player.current_spirit).is_equal_approx(spirit_before, APPROX)
	assert_float(player.get_skill_cooldown_remaining(skill.id)).is_zero()


## 施法者死亡时取消选择、解绑信息卡/技能栏，并清除目标高亮与命令路径。
func test_player_death_cancels_targeting_and_unbinds_hud() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var info_panel: PawnInfoPanel = main.get_node(INFO_PANEL_PATH)
	enemy.global_position = player.global_position + Vector2(200.0, 0.0)
	_begin_enemy_targeting(main, player, bar)
	_send_mouse_motion(main, _screen_position(main, enemy.global_position))
	assert_bool(enemy.is_target_highlight_visible()).is_true()

	player.take_damage(player.data.defense + player.data.max_shield + player.data.max_health + 50.0)

	assert_bool(player.is_dead()).is_true()
	assert_bool(bar.is_targeting()).is_false()
	assert_bool(bar.visible).is_false()
	assert_bool(info_panel.is_bound()).is_false()
	assert_bool(enemy.is_target_highlight_visible()).is_false()


## Build/技能列表失效时，SkillBar 刷新必须自动取消旧 TARGETING。
func test_skill_invalidation_auto_cancels_targeting() -> void:
	var main: Node2D = _spawn_main()
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var data: PawnData = (player.data as PawnData).duplicate(true) as PawnData
	player.data = data
	_begin_enemy_targeting(main, player, bar)

	var empty_skills: Array[ActiveSkillDefinition] = []
	data.active_skills = empty_skills
	data.active_skill = null
	data.notify_build_changed()

	assert_bool(bar.is_targeting()).is_false()


## SELF 技能跳过 TARGETING，直接进入既有控制器命令且不要求点击目标。
func test_self_skill_directly_requests_without_targeting() -> void:
	var guard: ActiveSkillDefinition = load(GUARD_SKILL_PATH) as ActiveSkillDefinition
	var main: Node2D = _spawn_main_with_player_data(_duplicate_player_data(guard))
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var controller: PlayerController = player.get_controller() as PlayerController
	main.call("_set_selected_pawn", player)
	var spirit_before: float = player.current_spirit

	_send_key(main, KEY_1)

	assert_bool(bar.is_targeting()).is_false()
	assert_str(controller.get_order_description()).contains(guard.display_name)
	controller.update_controller(DELTA)
	assert_float(spirit_before - player.current_spirit).is_equal_approx(guard.spirit_cost, APPROX)
	assert_float(player.get_skill_cooldown_remaining(guard.id)).is_equal_approx(guard.cooldown, APPROX)


## ALLY 技能先进入 TARGETING，点击同阵营 Pawn 后交给控制器；目标合法性来自 Pawn 而非 Main。
func test_ally_skill_confirms_on_friendly_pawn() -> void:
	var ally_skill: ActiveSkillDefinition = _make_ally_skill()
	var main: Node2D = _spawn_main_with_player_data(_duplicate_player_data(ally_skill))
	_isolate_controllers(main)
	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var bar: SkillBar = main.get_node("HUD/BottomLeftDock/SkillBar")
	var order_label: Label = main.get_node(ORDER_LABEL_PATH)

	var ally_scene: PackedScene = load(ALLY_PAWN_SCENE_PATH)
	var ally: Pawn = ally_scene.instantiate() as Pawn
	var ally_data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	ally_data.faction = &"player"
	ally_data.active_skill = null
	var ally_skills: Array[ActiveSkillDefinition] = []
	ally_data.active_skills = ally_skills
	ally.data = ally_data
	auto_free(ally)
	main.get_node("Pawns").add_child(ally)
	ally.global_position = player.global_position + Vector2(160.0, 0.0)
	(ally.get_controller() as PawnController).set_physics_process(false)

	main.call("_set_selected_pawn", player)
	_send_key(main, KEY_1)
	assert_bool(bar.is_targeting()).is_true()
	assert_int(bar.get_targeting_skill().target_type).is_equal(ActiveSkillDefinition.SkillTargetType.ALLY)

	_send_mouse_button(main, MOUSE_BUTTON_LEFT, _screen_position(main, ally.global_position))

	assert_bool(bar.is_targeting()).is_false()
	assert_bool(order_label.text.contains(ally_skill.display_name)).is_true()
	assert_bool(order_label.text.contains(ally.data.display_name)).is_true()
	assert_float(player.current_spirit).is_equal_approx(player.data.max_spirit, APPROX)
