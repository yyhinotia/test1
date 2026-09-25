extends GdUnitTestSuite

## 玩法层：真实 main.tscn 上的宗门接线与秘境收益闭环（INC-CORE-010）。
##
## 待回答的问题：秘境打完后，灵石是否真的进入宗门，玩家能否用这笔钱升级设施、
## 打坐变强，并且换房间重建玩家单位时宗门状态不会被重置？本文件只通过真实主场景
## 与面板按钮驱动，宗门规则仍由 SectState 持有，测试不复制花费 / 产出公式。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"

const SECT_STATE_PATH: String = "SectState"
const SECT_PANEL_PATH: String = "HUD/BottomLeftDock/SectPanel"
const DUNGEON_RUN_PATH: String = "DungeonRun"
const DUNGEON_PANEL_PATH: String = "HUD/BottomLeftDock/DungeonPanel"
const SESSION_PATH: String = "EncounterSession"


## 安全护栏：真实主场景会改全局暂停状态，任何用例后都必须恢复。
func after_test() -> void:
    if get_tree() != null:
        get_tree().paused = false


func _spawn_main() -> Node2D:
    var scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
    var main: Node2D = scene.instantiate() as Node2D
    auto_free(main)
    add_child(main)
    return main


func _state(main: Node2D) -> SectState:
    return main.get_node(SECT_STATE_PATH) as SectState


func _sect_panel(main: Node2D) -> SectPanel:
    return main.get_node(SECT_PANEL_PATH) as SectPanel


func _run(main: Node2D) -> DungeonRun:
    return main.get_node(DUNGEON_RUN_PATH) as DungeonRun


func _dungeon_panel(main: Node2D) -> DungeonPanel:
    return main.get_node(DUNGEON_PANEL_PATH) as DungeonPanel


func _session(main: Node2D) -> EncounterSession:
    return main.get_node(SESSION_PATH) as EncounterSession


func _load_dungeon() -> DungeonDefinition:
    return load(DUNGEON_PATH) as DungeonDefinition


func _lethal_damage(pawn: Pawn) -> float:
    return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 用真实死亡路径清空当前房间，不直接改 DungeonRun 状态。
func _clear_current_room(main: Node2D) -> void:
    var enemy: Pawn = _session(main).get_enemy_pawn()
    enemy.take_damage(_lethal_damage(enemy))


func _press_dungeon(main: Node2D, button_name: String) -> bool:
    var button: Button = _dungeon_panel(main).get_node_or_null(NodePath(button_name)) as Button
    if button == null:
        return false
    button.pressed.emit()
    return true


func _press_sect(main: Node2D, path: String) -> bool:
    var button: Button = _sect_panel(main).get_node_or_null(NodePath(path)) as Button
    if button == null:
        return false
    button.pressed.emit()
    return true


func test_boot_binds_sect_state_panel_and_technique_catalog() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()

    var state: SectState = _state(main)
    var panel: SectPanel = _sect_panel(main)
    var session: EncounterSession = _session(main)

    assert_object(state).is_not_null()
    assert_bool(panel.is_bound()).is_true()
    assert_int(panel.get_facility_count()).is_equal(6)
    assert_int(panel.get_learnable_technique_count()).is_equal(3)
    assert_object(state.get_cultivator()).is_same(session.get_player_pawn())
    assert_int(state.get_spirit_stones()).is_zero()
    assert_str(panel.get_spirit_stones_text()).is_equal("灵石：0")


func test_retreat_deposits_earned_reward_once_and_panel_matches_inventory() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var run: DungeonRun = _run(main)
    var state: SectState = _state(main)
    var panel: SectPanel = _sect_panel(main)
    var dungeon: DungeonDefinition = _load_dungeon()

    _clear_current_room(main)
    await await_idle_frame()
    var room_reward: int = dungeon.get_room_reward(0)
    assert_int(run.get_earned_spirit_stones()).is_equal(room_reward)
    # 收益只在 run_finished 入账；清空房间只是累计，还不是终局。
    assert_int(state.get_spirit_stones()).is_zero()

    assert_bool(_press_dungeon(main, "RetreatButton")).is_true()
    await await_idle_frame()
    assert_int(run.get_state()).is_equal(DungeonRun.State.RETREATED)
    assert_int(state.get_spirit_stones()).is_equal(room_reward)
    assert_str(panel.get_spirit_stones_text()).contains(str(room_reward))

    # 重复广播同一局终局不得重复入账。
    run.run_finished.emit(run.get_active_dungeon(), run.get_state(), run.get_earned_spirit_stones())
    assert_int(state.get_spirit_stones()).is_equal(room_reward)


func test_advancing_rebinds_new_cultivator_without_resetting_sect_state() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var run: DungeonRun = _run(main)
    var state: SectState = _state(main)
    var session: EncounterSession = _session(main)

    var old_player: Pawn = session.get_player_pawn()
    var old_player_id: int = old_player.get_instance_id()
    assert_object(state.get_cultivator()).is_same(old_player)

    _clear_current_room(main)
    await await_idle_frame()
    # 测试提供足够的灵石作为前置，只验证升级结果与换房间后的状态保留。
    state.deposit_spirit_stones(100)
    assert_bool(state.upgrade_facility(SectState.FACILITY_SPIRIT_FIELD)).is_true()
    var stones_after_upgrade: int = state.get_spirit_stones()
    var field_level: int = state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)

    assert_bool(_press_dungeon(main, "AdvanceButton")).is_true()
    await await_idle_frame()
    var new_player: Pawn = session.get_player_pawn()
    assert_bool(new_player.get_instance_id() == old_player_id).is_false()
    assert_object(state.get_cultivator()).is_same(new_player)
    assert_int(state.get_spirit_stones()).is_equal(stones_after_upgrade)
    assert_int(state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)).is_equal(field_level)
    assert_int(run.get_depth()).is_equal(2)


func test_all_seven_panel_actions_route_to_sect_state() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var state: SectState = _state(main)
    var panel: SectPanel = _sect_panel(main)
    var player: Pawn = _session(main).get_player_pawn()

    # 测试注入资源，确保七个动作都具备可执行前置；动作本身仍走面板 → main.gd → SectState。
    state.deposit_spirit_stones(2000)
    var field_button: Button = panel.get_upgrade_button(SectState.FACILITY_SPIRIT_FIELD)
    assert_object(field_button).is_not_null()
    assert_bool(field_button.disabled).is_false()
    field_button.pressed.emit()
    assert_int(state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)).is_equal(2)

    var exp_before: float = float(player.get_cultivation_snapshot().get("current_exp", 0.0))
    assert_bool(_press_sect(main, "CultivateButton")).is_true()
    var exp_after: float = float(player.get_cultivation_snapshot().get("current_exp", 0.0))
    assert_float(exp_after).is_greater(exp_before)

    assert_bool(_press_sect(main, "HarvestButton")).is_true()
    assert_int(state.get_spirit_herbs()).is_greater(0)
    assert_bool(_press_sect(main, "RefinePillButton")).is_true()
    assert_int(state.get_pills()).is_greater(0)

    player.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID).decrease(20.0, &"sect_test")
    player.get_resource_pool(Pawn.SPIRIT_RESOURCE_ID).decrease(20.0, &"sect_test")
    var health_before: float = player.current_health
    var spirit_before: float = player.current_spirit
    assert_bool(_press_sect(main, "UsePillButton")).is_true()
    assert_float(player.current_health).is_greater(health_before)
    assert_float(player.current_spirit).is_greater(spirit_before)

    var forge_before: int = player.get_forge_level()
    var attack_before: float = player.get_attack_power()
    assert_bool(_press_sect(main, "StrengthenButton")).is_true()
    assert_int(player.get_forge_level()).is_equal(forge_before + 1)
    assert_float(player.get_attack_power()).is_greater(attack_before)

    var learn_button: Button = panel.get_node("LearnRow/LearnButton") as Button
    var learn_option: OptionButton = panel.get_node("LearnRow/LearnOption") as OptionButton
    assert_object(learn_button).is_not_null()
    assert_object(learn_option).is_not_null()
    learn_option.select(1)
    learn_button.pressed.emit()
    assert_bool(player.has_learned_technique(&"body_cultivation")).is_true()


func test_earned_reward_upgrades_facility_and_cultivation_on_real_main_scene() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var run: DungeonRun = _run(main)
    var state: SectState = _state(main)
    var panel: SectPanel = _sect_panel(main)
    var dungeon: DungeonDefinition = _load_dungeon()

    # 清空三间房，收益足够支付灵田从 1 级升到 2 级；再以「见好就收」走唯一终局入账。
    _clear_current_room(main)
    await await_idle_frame()
    assert_bool(_press_dungeon(main, "AdvanceButton")).is_true()
    await await_idle_frame()
    _clear_current_room(main)
    await await_idle_frame()
    assert_bool(_press_dungeon(main, "AdvanceButton")).is_true()
    await await_idle_frame()
    _clear_current_room(main)
    await await_idle_frame()
    var earned: int = dungeon.get_room_reward(0) + dungeon.get_room_reward(1) + dungeon.get_room_reward(2)
    assert_int(run.get_earned_spirit_stones()).is_equal(earned)
    assert_bool(_press_dungeon(main, "RetreatButton")).is_true()
    await await_idle_frame()
    assert_int(state.get_spirit_stones()).is_equal(earned)

    # 清到第 3 间后玩家单位已重建；重新取真实单位，避免持有已释放引用。
    var player: Pawn = _session(main).get_player_pawn()
    var field_button: Button = panel.get_upgrade_button(SectState.FACILITY_SPIRIT_FIELD)
    assert_bool(field_button.disabled).is_false()
    field_button.pressed.emit()
    assert_int(state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)).is_equal(2)

    var exp_before: float = float(player.get_cultivation_snapshot().get("current_exp", 0.0))
    assert_bool(_press_sect(main, "CultivateButton")).is_true()
    var exp_after: float = float(player.get_cultivation_snapshot().get("current_exp", 0.0))
    assert_float(exp_after).is_greater(exp_before)


func test_defeat_deposits_zero_and_panels_agree() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var run: DungeonRun = _run(main)
    var state: SectState = _state(main)
    var panel: SectPanel = _sect_panel(main)
    var dungeon_panel: DungeonPanel = _dungeon_panel(main)
    var player: Pawn = _session(main).get_player_pawn()

    player.take_damage(_lethal_damage(player))
    await await_idle_frame()

    assert_int(run.get_state()).is_equal(DungeonRun.State.DEFEATED)
    assert_int(run.get_earned_spirit_stones()).is_zero()
    assert_int(state.get_spirit_stones()).is_zero()
    assert_str(panel.get_spirit_stones_text()).contains("0")
    assert_str(dungeon_panel.get_status_text()).contains("0")