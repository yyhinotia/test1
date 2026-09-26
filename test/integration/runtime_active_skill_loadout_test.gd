extends GdUnitTestSuite

## 集成层：运行时主动技能装配（INC-PAWNS-021）在真实场景中的读模型统一。
## 覆盖 SkillBar 跟随重配、PlayerController 只接受已装配技能、PawnInfoPanel 与装配结果一致；
## 三者都必须以 Pawn 的运行时装配为唯一事实源，不得各自直读 `PawnData.active_skills`。

const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const BAR_SCENE_PATH: String = "res://game/ui/skill_bar.tscn"
const PANEL_SCENE_PATH: String = "res://game/ui/pawn_info_panel.tscn"


func _make_skill(skill_id: StringName, cast_range: float = 90.0) -> ActiveSkillDefinition:
	var skill: ActiveSkillDefinition = ActiveSkillDefinition.new()
	skill.id = skill_id
	skill.display_name = String(skill_id)
	skill.spirit_cost = 10.0
	skill.cooldown = 1.0
	skill.cast_range = cast_range
	skill.damage_multiplier = 1.0
	skill.target_type = ActiveSkillDefinition.SkillTargetType.ENEMY
	return skill


func _make_player_data(first: ActiveSkillDefinition, second: ActiveSkillDefinition) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = first
	var skills: Array[ActiveSkillDefinition] = [first]
	if second != null:
		skills.append(second)
	data.active_skills = skills
	data.max_spirit = 100.0
	data.initial_spirit_ratio = 1.0
	return data


func _spawn_pawn(scene_path: String, data_override: PawnData = null) -> Pawn:
	var scene: PackedScene = load(scene_path) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	if data_override != null:
		pawn.data = data_override
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _spawn_bar() -> SkillBar:
	var scene: PackedScene = load(BAR_SCENE_PATH) as PackedScene
	var bar: SkillBar = scene.instantiate() as SkillBar
	auto_free(bar)
	add_child(bar)
	return bar


func _spawn_panel() -> PawnInfoPanel:
	var scene: PackedScene = load(PANEL_SCENE_PATH) as PackedScene
	var panel: PawnInfoPanel = scene.instantiate() as PawnInfoPanel
	auto_free(panel)
	add_child(panel)
	return panel


func _snapshot_skill_names(panel: PawnInfoPanel) -> Array:
	var snapshot: Dictionary = panel.get_snapshot()
	var build: Dictionary = snapshot.get("build", {})
	var slot: Dictionary = build.get("active_skill", {})
	return slot.get("names", [])


func test_skill_bar_rebuilds_slots_from_runtime_loadout() -> void:
	var sword: ActiveSkillDefinition = _make_skill(&"sword_strike")
	var guard: ActiveSkillDefinition = _make_skill(&"guard")
	var binding: ActiveSkillDefinition = _make_skill(&"binding")
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(sword, guard))
	var bar: SkillBar = _spawn_bar()
	await await_idle_frame()
	bar.bind_pawn(pawn)

	var initial: Array[SkillSlot] = bar.get_slots()
	assert_int(initial.size()).is_equal(2)
	assert_object(initial[0].get_skill()).is_same(sword)
	assert_object(initial[1].get_skill()).is_same(guard)

	assert_bool(pawn.learn_active_skill(binding)).is_true()
	var target: Array[ActiveSkillDefinition] = [sword, binding]
	assert_bool(pawn.set_active_skill_loadout(target)).is_true()

	# 重配只广播 Pawn.build_changed；技能栏必须据此立刻重建槽位而不是继续显示静态预设。
	var refreshed: Array[SkillSlot] = bar.get_slots()
	assert_object(refreshed[0].get_skill()).is_same(sword)
	assert_object(refreshed[1].get_skill()).is_same(binding)


func test_player_controller_accepts_equipped_learned_skill() -> void:
	var sword: ActiveSkillDefinition = _make_skill(&"sword_strike")
	var binding: ActiveSkillDefinition = _make_skill(&"binding")
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(sword, null))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(40.0, 0.0)
	await await_idle_frame()
	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)
	controller.set_physics_process(false)

	assert_bool(player.learn_active_skill(binding)).is_true()
	# 已掌握但未装配的技能必须被拒绝：解锁不等于装备。
	assert_bool(controller.order_skill_instance(binding, enemy)).is_false()

	var target: Array[ActiveSkillDefinition] = [binding]
	assert_bool(player.set_active_skill_loadout(target)).is_true()
	assert_bool(controller.order_skill_instance(binding, enemy)).is_true()
	assert_str(controller.get_order_description()).contains("binding")


func test_player_controller_rejects_never_learned_skill() -> void:
	var sword: ActiveSkillDefinition = _make_skill(&"sword_strike")
	var forged: ActiveSkillDefinition = _make_skill(&"forged_twin")
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(sword, null))
	var enemy: Pawn = _spawn_pawn(ENEMY_PAWN_SCENE_PATH)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(40.0, 0.0)
	await await_idle_frame()
	var controller: PlayerController = player.get_controller() as PlayerController
	controller.bind(player)
	controller.set_physics_process(false)

	# 从未掌握、也从未装配的技能不能被任何输入入口绕过。
	assert_bool(controller.order_skill_instance(forged, enemy)).is_false()
	var target: Array[ActiveSkillDefinition] = [forged]
	assert_bool(player.set_active_skill_loadout(target)).is_false()
	assert_bool(controller.order_skill_instance(sword, enemy)).is_true()


func test_pawn_info_panel_follows_runtime_loadout() -> void:
	var sword: ActiveSkillDefinition = _make_skill(&"sword_strike")
	var guard: ActiveSkillDefinition = _make_skill(&"guard")
	var binding: ActiveSkillDefinition = _make_skill(&"binding")
	var pawn: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH, _make_player_data(sword, guard))
	var panel: PawnInfoPanel = _spawn_panel()
	await await_idle_frame()
	panel.bind_pawn(pawn)
	assert_array(_snapshot_skill_names(panel)).contains_exactly(["sword_strike", "guard"])

	assert_bool(pawn.learn_active_skill(binding)).is_true()
	var target: Array[ActiveSkillDefinition] = [sword, binding]
	assert_bool(pawn.set_active_skill_loadout(target)).is_true()

	# 信息卡与技能栏必须读同一份运行时装配结果，而不是继续读 PawnData.active_skills。
	assert_array(_snapshot_skill_names(panel)).contains_exactly(["sword_strike", "binding"])


## 技能池扩容（INC-PAWNS-023）：新技能可学习、可装配，但境界容量仍把装配卡在 2 槽。
func test_pool_skills_can_be_learned_and_equipped_within_two_slots() -> void:
	var breaking_slash: ActiveSkillDefinition = load(
		"res://game/pawns/data/skills/player_breaking_slash.tres"
	) as ActiveSkillDefinition
	var rejuvenation: ActiveSkillDefinition = load(
		"res://game/pawns/data/skills/player_rejuvenation_skill.tres"
	) as ActiveSkillDefinition
	var player: Pawn = _spawn_pawn(PLAYER_PAWN_SCENE_PATH)
	await await_idle_frame()

	# 技能池从 6 扩到 8 不改变境界容量：炼气期仍是 2 槽。
	assert_int(player.get_active_skill_capacity()).is_equal(2)
	assert_bool(player.learn_active_skill(breaking_slash)).is_true()
	assert_bool(player.learn_active_skill(rejuvenation)).is_true()
	var loadout: Array[ActiveSkillDefinition] = [breaking_slash, rejuvenation]
	assert_bool(player.set_active_skill_loadout(loadout)).is_true()
	assert_bool(player.is_active_skill_enabled(breaking_slash)).is_true()
	assert_bool(player.is_active_skill_enabled(rejuvenation)).is_true()

	# 超过容量的装配必须整体失败，并保持调用前的装配完全不变。
	var overflow: ActiveSkillDefinition = _make_skill(&"overflow_probe")
	assert_bool(player.learn_active_skill(overflow)).is_true()
	var overflowing: Array[ActiveSkillDefinition] = [breaking_slash, rejuvenation, overflow]
	assert_bool(player.set_active_skill_loadout(overflowing)).is_false()
	assert_bool(player.is_active_skill_enabled(breaking_slash)).is_true()
	assert_bool(player.is_active_skill_enabled(rejuvenation)).is_true()
	assert_bool(player.is_active_skill_enabled(overflow)).is_false()
