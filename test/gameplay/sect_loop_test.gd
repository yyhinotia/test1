extends GdUnitTestSuite

## 玩法层：真实 main.tscn 上的宗门闭环证据（INC-TESTING-009）。
##
## 待回答的问题：玩家清理秘境拿到灵石后，是否真的能把收益转成设施等级、修为、
## 灵草 / 丹药与武器强化，并在重新开始秘境后继续带着这些成长再战？本文件只通过
## 真实主场景与面板按钮驱动，数值与奖励从正式资源读取，不复制宗门公式。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
## 宗门闭环用例显式使用单敌人试炼秘境：默认秘境是问题秘境（INC-CORE-014），多敌人房间不属于本用例范围。
const TRIAL_DUNGEON_PATH: String = "res://game/world/data/dungeons/trial_dungeon.tres"

const SECT_STATE_PATH: String = "SectState"
const SECT_PANEL_PATH: String = "HUD/BottomLeftDock/SectPanel"
const DUNGEON_RUN_PATH: String = "DungeonRun"
const DUNGEON_PANEL_PATH: String = "HUD/BottomLeftDock/DungeonPanel"
const SESSION_PATH: String = "EncounterSession"
const APPROX: float = 0.001


## 安全护栏：真实主场景会改全局暂停状态，任何用例后都必须恢复。
func after_test() -> void:
    if get_tree() != null:
        get_tree().paused = false


func _spawn_main() -> Node2D:
    var scene: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
    var main: Node2D = scene.instantiate() as Node2D
    # 宗门闭环用例显式选择单敌人试炼秘境：默认入口已是问题秘境（INC-CORE-014），
    # 而 DungeonRun.start() 拒绝替换进行中的秘境，因此在入树前替换 default_dungeon。
    (main.get_node(DUNGEON_RUN_PATH) as DungeonRun).default_dungeon = load(TRIAL_DUNGEON_PATH) as DungeonDefinition
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


func _lethal_damage(pawn: Pawn) -> float:
    return pawn.data.defense + pawn.data.max_health + pawn.data.max_shield + 50.0


## 用真实死亡路径清空当前房间，不直接改 DungeonRun 状态。
func _clear_current_room(main: Node2D) -> void:
    var enemy: Pawn = _session(main).get_enemy_pawn()
    enemy.take_damage(_lethal_damage(enemy))


## 通过真实结算按钮清空连续房间；最后停在目标房间，不替测试决定后续动作。
func _clear_and_advance(main: Node2D, room_count: int) -> void:
    for index: int in room_count:
        _clear_current_room(main)
        await await_idle_frame()
        if index < room_count - 1:
            assert_bool(_press_dungeon(main, "AdvanceButton")).is_true()
            await await_idle_frame()


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


func _total_pool(pawn: Pawn) -> float:
    return pawn.current_health + pawn.current_shield


## 执行一次真实攻击并返回目标（生命 + 护盾）总损失；不直接调用 take_damage 伪造伤害。
func _measure_attack(player: Pawn, enemy: Pawn) -> float:
    assert_bool(player.can_attack()).is_true()
    var before: float = _total_pool(enemy)
    assert_bool(player.try_attack(enemy)).is_true()
    return before - _total_pool(enemy)


func _cultivation_exp(pawn: Pawn) -> float:
    return float(pawn.get_cultivation_snapshot().get("current_exp", 0.0))


func test_complete_sect_loop_makes_the_restarted_run_stronger() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var state: SectState = _state(main)
    var panel: SectPanel = _sect_panel(main)
    var run: DungeonRun = _run(main)
    var session: EncounterSession = _session(main)
    var dungeon: DungeonDefinition = load(TRIAL_DUNGEON_PATH) as DungeonDefinition

    # 连续清四间并撤退：本轮收益为 10 + 15 + 25 + 40，足够一次设施升级与一次武器强化。
    await _clear_and_advance(main, 4)
    var total_earned: int = 0
    for index: int in 4:
        total_earned += dungeon.get_room_reward(index)
    assert_int(run.get_depth()).is_equal(4)
    assert_int(run.get_earned_spirit_stones()).is_equal(total_earned)
    assert_int(state.get_spirit_stones()).is_zero()
    assert_bool(_press_dungeon(main, "RetreatButton")).is_true()
    await await_idle_frame()
    assert_int(state.get_spirit_stones()).is_equal(total_earned)

    # 把秘境收益转成宗门成长：设施升级、打坐修为、灵草 → 丹药 → 服丹恢复。
    var field_button: Button = panel.get_upgrade_button(SectState.FACILITY_SPIRIT_FIELD)
    assert_object(field_button).is_not_null()
    assert_bool(field_button.disabled).is_false()
    field_button.pressed.emit()
    assert_int(state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)).is_equal(2)

    var player: Pawn = session.get_player_pawn()
    var exp_before: float = _cultivation_exp(player)
    assert_bool(_press_sect(main, "CultivateButton")).is_true()
    var cultivated_exp: float = _cultivation_exp(player)
    assert_float(cultivated_exp).is_greater(exp_before)

    assert_bool(_press_sect(main, "HarvestButton")).is_true()
    assert_int(state.get_spirit_herbs()).is_greater(0)
    assert_bool(_press_sect(main, "RefinePillButton")).is_true()
    assert_int(state.get_pills()).is_greater(0)

    player.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID).decrease(30.0, &"sect_loop_test")
    player.get_resource_pool(Pawn.SPIRIT_RESOURCE_ID).decrease(30.0, &"sect_loop_test")
    var health_before: float = player.current_health
    var spirit_before: float = player.current_spirit
    assert_bool(_press_sect(main, "UsePillButton")).is_true()
    assert_float(player.current_health).is_greater(health_before)
    assert_float(player.current_spirit).is_greater(spirit_before)

    # 第一次重开：宗门库存 / 设施不重置，本代修士的修为也必须由会话延续。
    var field_level_before_restart: int = state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)
    var pills_before_restart: int = state.get_pills()
    var stones_before_restart: int = state.get_spirit_stones()
    var old_player_id: int = player.get_instance_id()
    assert_bool(_press_dungeon(main, "RestartButton")).is_true()
    await await_idle_frame()

    var restarted_player: Pawn = session.get_player_pawn()
    assert_bool(restarted_player.get_instance_id() == old_player_id).is_false()
    assert_int(run.get_state()).is_equal(DungeonRun.State.RUNNING)
    assert_int(run.get_depth()).is_equal(1)
    assert_float(_cultivation_exp(restarted_player)).is_equal(cultivated_exp)
    assert_int(state.get_facility_level(SectState.FACILITY_SPIRIT_FIELD)).is_equal(field_level_before_restart)
    assert_int(state.get_pills()).is_equal(pills_before_restart)
    assert_int(state.get_spirit_stones()).is_equal(stones_before_restart)

    # 在重开后的第一间房比较同一玩家单位的真实攻击：强化前 → 炼器房强化 → 强化后。
    var enemy: Pawn = session.get_enemy_pawn()
    assert_object(restarted_player).is_not_null()
    assert_object(enemy).is_not_null()
    restarted_player.global_position = Vector2.ZERO
    enemy.global_position = Vector2(32.0, 0.0)
    enemy.set_physics_process(false)
    enemy.set_process(false)
    var attack_before: float = restarted_player.get_attack_power()
    var basic_damage: float = _measure_attack(restarted_player, enemy)
    assert_float(basic_damage).is_greater(0.0)

    var strengthen_button: Button = panel.get_node("StrengthenButton") as Button
    assert_object(strengthen_button).is_not_null()
    assert_bool(strengthen_button.disabled).is_false()
    strengthen_button.pressed.emit()
    assert_int(restarted_player.get_forge_level()).is_equal(1)
    assert_float(restarted_player.get_attack_power()).is_greater(attack_before)

    await get_tree().create_timer(1.0).timeout
    enemy.get_resource_pool(HealthComponent.HEALTH_RESOURCE_ID).set_value(enemy.data.max_health)
    enemy.get_resource_pool(HealthComponent.SHIELD_RESOURCE_ID).set_value(enemy.data.max_shield)
    var forged_damage: float = _measure_attack(restarted_player, enemy)
    assert_float(forged_damage).is_greater(basic_damage)
    assert_float(forged_damage - basic_damage).is_equal_approx(
        Pawn.FORGE_ATTACK_BONUS_PER_LEVEL, APPROX
    )

    # 第二次收回一间的收益并重开：强化等级与修为仍然属于同一个修士身份。
    var restarted_player_id: int = restarted_player.get_instance_id()
    var forge_level_before_second_restart: int = restarted_player.get_forge_level()
    var exp_before_second_restart: float = _cultivation_exp(restarted_player)
    var stones_before_second_retreat: int = state.get_spirit_stones()
    _clear_current_room(main)
    await await_idle_frame()
    assert_bool(_press_dungeon(main, "RetreatButton")).is_true()
    await await_idle_frame()
    assert_int(state.get_spirit_stones()).is_equal(stones_before_second_retreat + dungeon.get_room_reward(0))

    assert_bool(_press_dungeon(main, "RestartButton")).is_true()
    await await_idle_frame()
    var next_run_player: Pawn = session.get_player_pawn()
    assert_bool(next_run_player.get_instance_id() == restarted_player_id).is_false()
    assert_int(next_run_player.get_forge_level()).is_equal(forge_level_before_second_restart)
    assert_float(_cultivation_exp(next_run_player)).is_equal(exp_before_second_restart)
    assert_float(next_run_player.get_attack_power()).is_greater(attack_before)
    assert_str(panel.get_spirit_stones_text()).contains(str(state.get_spirit_stones()))

func test_run_finished_is_deposited_once_and_defeat_deposits_zero() -> void:
    var main: Node2D = _spawn_main()
    await await_idle_frame()
    var run: DungeonRun = _run(main)
    var state: SectState = _state(main)
    var dungeon_panel: DungeonPanel = _dungeon_panel(main)
    var dungeon: DungeonDefinition = load(TRIAL_DUNGEON_PATH) as DungeonDefinition

    _clear_current_room(main)
    await await_idle_frame()
    var reward: int = dungeon.get_room_reward(0)
    assert_int(run.get_earned_spirit_stones()).is_equal(reward)
    assert_bool(_press_dungeon(main, "RetreatButton")).is_true()
    await await_idle_frame()
    assert_int(state.get_spirit_stones()).is_equal(reward)
    assert_str(dungeon_panel.get_status_text()).contains(str(reward))

    # 同一局终局即使重复广播，也只能入账一次。
    run.run_finished.emit(run.get_active_dungeon(), run.get_state(), run.get_earned_spirit_stones())
    assert_int(state.get_spirit_stones()).is_equal(reward)

    var defeated_main: Node2D = _spawn_main()
    await await_idle_frame()
    var defeated_state: SectState = _state(defeated_main)
    var defeated_panel: DungeonPanel = _dungeon_panel(defeated_main)
    var defeated_player: Pawn = _session(defeated_main).get_player_pawn()

    defeated_player.take_damage(_lethal_damage(defeated_player))
    await await_idle_frame()
    assert_int(_run(defeated_main).get_earned_spirit_stones()).is_zero()
    assert_int(defeated_state.get_spirit_stones()).is_zero()
    assert_str(defeated_panel.get_status_text()).contains("0")