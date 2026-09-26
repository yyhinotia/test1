extends GdUnitTestSuite

## 集成层：最小 Build A/B 切换面板（INC-UI-018）。
##
## 面板是 Gate C（主动 Build 重构）唯一的可见操作面，因此测试必须钉死三件事：
##   1. 解锁只让 Build B 变成「可切换」，绝不自动装配；
##   2. 只有玩家点击才产生 `Pawn.set_active_skill_loadout()`，失败时零副作用且原因可复核；
##   3. 切换成功后 SkillBar 与「当前 Build」标记在同一帧跟随，事实源始终是 Pawn。

const PANEL_SCENE_PATH: String = "res://game/ui/build/build_loadout_panel.tscn"
const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_SKILL_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"
const DASH_SKILL_PATH: String = "res://game/pawns/data/skills/player_dash_skill.tres"
const SWORD_AOE_SKILL_PATH: String = "res://game/pawns/data/skills/player_sword_aoe_skill.tres"
const LIFESTEAL_SKILL_PATH: String = "res://game/pawns/data/skills/player_lifesteal_skill.tres"
const REJUVENATION_SKILL_PATH: String = "res://game/pawns/data/skills/player_rejuvenation_skill.tres"
const BREAKING_SLASH_PATH: String = "res://game/pawns/data/skills/player_breaking_slash.tres"
const BAR_SCENE_PATH: String = "res://game/ui/skill_bar.tscn"


func _skill(skill_path: String) -> ActiveSkillDefinition:
	return load(skill_path) as ActiveSkillDefinition


func _skill_ids(skills: Array[ActiveSkillDefinition]) -> Array:
	var ids: Array = []
	for skill: ActiveSkillDefinition in skills:
		ids.append(String(skill.id) if skill != null else "<null>")
	return ids


## 玩家数据副本 + 指定静态预设：测试只改副本，不动 production 资源。
func _spawn_pawn(preset: Array[ActiveSkillDefinition]) -> Pawn:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	data.active_skill = preset[0] if not preset.is_empty() else null
	data.active_skills = preset
	var scene: PackedScene = load(PLAYER_PAWN_SCENE_PATH) as PackedScene
	var pawn: Pawn = scene.instantiate() as Pawn
	pawn.data = data
	auto_free(pawn)
	add_child(pawn)
	return pawn


func _spawn_panel(preset_a: Array[ActiveSkillDefinition], preset_b: Array[ActiveSkillDefinition], pool: Array[ActiveSkillDefinition] = []) -> BuildLoadoutPanel:
	var scene: PackedScene = load(PANEL_SCENE_PATH) as PackedScene
	var panel: BuildLoadoutPanel = scene.instantiate() as BuildLoadoutPanel
	# 预设在入树前赋值：按钮在 _ready() 里生成，之后只由 refresh() 改文案与可用性。
	panel.preset_a = preset_a
	panel.preset_b = preset_b
	# 自定义技能池同样在入树前赋值：_ready() 里一次性生成行，运行期只由 refresh() 改可用性。
	panel.available_skills = pool
	auto_free(panel)
	add_child(panel)
	return panel


func _spawn_bar() -> SkillBar:
	var scene: PackedScene = load(BAR_SCENE_PATH) as PackedScene
	var bar: SkillBar = scene.instantiate() as SkillBar
	auto_free(bar)
	add_child(bar)
	return bar


## 两套固定预设必须按 id 可查、按 display_name 呈现，且初始就把 Build A 标成「当前」。
func test_panel_lists_two_fixed_presets_and_marks_current_build() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding])
	panel.bind_pawn(pawn)

	assert_array(panel.get_preset_ids()).contains_exactly([
		BuildLoadoutPanel.PRESET_A_ID, BuildLoadoutPanel.PRESET_B_ID,
	])
	assert_array(_skill_ids(panel.get_preset_skills(BuildLoadoutPanel.PRESET_A_ID))).contains_exactly([
		"sword_strike", "guard_true_qi",
	])
	assert_array(_skill_ids(panel.get_preset_skills(BuildLoadoutPanel.PRESET_B_ID))).contains_exactly([
		"sword_strike", "binding_spell",
	])
	assert_str(panel.get_preset_title_text(BuildLoadoutPanel.PRESET_A_ID)).is_equal("Build A：御剑斩 + 护体真气")
	assert_str(panel.get_preset_title_text(BuildLoadoutPanel.PRESET_B_ID)).is_equal("Build B：御剑斩 + 定身术")
	assert_str(String(panel.get_active_preset_id())).is_equal(String(BuildLoadoutPanel.PRESET_A_ID))
	assert_str(panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_A_ID)).is_equal("当前 Build")
	assert_str(panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)).is_equal("未解锁：定身术")
	assert_bool(panel.get_preset_button(BuildLoadoutPanel.PRESET_A_ID).disabled).is_true()
	assert_bool(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).disabled).is_true()
	assert_bool(panel.is_preset_available(BuildLoadoutPanel.PRESET_A_ID)).is_true()
	assert_bool(panel.is_preset_available(BuildLoadoutPanel.PRESET_B_ID)).is_false()


## 定身术未解锁时 Build B 是锁定态：即使程序化触发也不得改变装配，且必须留下可复核原因。
func test_locked_preset_cannot_be_switched_before_unlock() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding])
	panel.bind_pawn(pawn)
	var attempts: Array = []
	panel.build_switch_attempted.connect(func(_p: Pawn, preset_id: StringName, success: bool, reason: String) -> void:
		attempts.append({"id": String(preset_id), "success": success, "reason": reason})
	)

	panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).pressed.emit()

	assert_int(attempts.size()).is_equal(1)
	assert_bool(attempts[0].get("success", true)).is_false()
	assert_str(attempts[0].get("reason", "")).is_equal(BuildLoadoutPanel.REASON_PRESET_LOCKED)
	assert_str(panel.get_last_reason()).is_equal(BuildLoadoutPanel.REASON_PRESET_LOCKED)
	assert_str(panel.get_status_text()).contains("未解锁")
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_false()


## 解锁定身术只改变「可切换」状态；真正换 Build 必须由玩家点击（本项目 Gate C 的核心约束）。
func test_unlock_makes_preset_available_but_switch_needs_player_click() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding])
	panel.bind_pawn(pawn)

	assert_bool(pawn.learn_active_skill(binding)).is_true()

	# 解锁后：可切换、按钮可用，但装配与信息面板读数完全没变（禁止自动切换）。
	assert_bool(panel.is_preset_available(BuildLoadoutPanel.PRESET_B_ID)).is_true()
	assert_str(panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)).is_equal("可切换")
	assert_bool(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).disabled).is_false()
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_false()
	assert_str(String(panel.get_active_preset_id())).is_equal(String(BuildLoadoutPanel.PRESET_A_ID))

	panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).pressed.emit()

	# 玩家点击之后：装配换到 B，标记与状态同步，A 重新可用。
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "binding_spell"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_true()
	assert_str(String(panel.get_active_preset_id())).is_equal(String(BuildLoadoutPanel.PRESET_B_ID))
	assert_str(panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)).is_equal("当前 Build")
	assert_str(panel.get_status_text()).contains("已切换到 Build B")
	assert_bool(panel.get_preset_button(BuildLoadoutPanel.PRESET_A_ID).disabled).is_false()
	# 静态预设（PawnData.active_skills）不得被面板改写：装配只存在于 Pawn 的运行时投影里。
	assert_array(_skill_ids(pawn.data.active_skills as Array[ActiveSkillDefinition])).contains_exactly([
		"sword_strike", "guard_true_qi",
	])


## 被 Pawn 拒绝（超出境界容量）时必须零副作用、原因可复核，并允许玩家修正后重试。
func test_rejected_switch_keeps_state_and_reports_reason() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	# 三技能预设：技能全部已掌握，但炼气期主动技能容量只有 2，因此必然被 Pawn 拒绝。
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, guard, binding])
	panel.bind_pawn(pawn)
	assert_bool(pawn.learn_active_skill(binding)).is_true()
	assert_int(pawn.get_active_skill_capacity()).is_equal(2)
	assert_bool(panel.is_preset_available(BuildLoadoutPanel.PRESET_B_ID)).is_true()

	panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).pressed.emit()

	assert_str(panel.get_last_reason()).is_equal(BuildLoadoutPanel.REASON_LOADOUT_REJECTED)
	assert_str(panel.get_status_text()).contains("切换失败")
	assert_str(panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)).is_equal("可切换")
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_false()
	assert_str(String(panel.get_active_preset_id())).is_equal(String(BuildLoadoutPanel.PRESET_A_ID))


## 战斗中锁定（主场景设置）：锁定期间点击无效，解锁后同一按钮立刻可用。
func test_switch_lock_blocks_click_until_unlocked() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding])
	panel.bind_pawn(pawn)
	assert_bool(pawn.learn_active_skill(binding)).is_true()

	panel.set_switch_locked(true)
	assert_bool(panel.is_switch_locked()).is_true()
	assert_bool(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).disabled).is_true()
	assert_str(panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)).is_equal("战斗中不可切换")
	panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).pressed.emit()
	assert_str(panel.get_last_reason()).is_equal(BuildLoadoutPanel.REASON_SWITCH_LOCKED)
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])

	panel.set_switch_locked(false)
	assert_bool(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).disabled).is_false()
	panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).pressed.emit()
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "binding_spell"])


## 技能栏必须通过 Pawn.build_changed 在同一帧跟随新装配（不等待下一帧、不重新绑定）。
func test_skill_bar_follows_new_build_in_the_same_frame() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding])
	var bar: SkillBar = _spawn_bar()
	await await_idle_frame()
	bar.bind_pawn(pawn)
	panel.bind_pawn(pawn)
	assert_int(bar.get_slot_count()).is_equal(2)

	assert_bool(pawn.learn_active_skill(binding)).is_true()
	panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).pressed.emit()

	# 刻意不 await：切换必须在同一帧把技能栏重建为 [御剑斩, 定身术]。
	var slots: Array[SkillSlot] = bar.get_slots()
	assert_int(slots.size()).is_equal(2)
	assert_str(String((slots[0].get_skill() as ActiveSkillDefinition).id)).is_equal("sword_strike")
	assert_str(String((slots[1].get_skill() as ActiveSkillDefinition).id)).is_equal("binding_spell")


## 解绑（未选中单位）时面板回到只读空态，不能留下可点击的残留入口。
func test_unbind_disables_switching_and_returns_to_empty_state() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding])
	panel.bind_pawn(pawn)

	panel.unbind()

	assert_object(panel.get_bound_pawn()).is_null()
	assert_str(panel.get_status_text()).is_equal(BuildLoadoutPanel.STATUS_NO_PAWN)
	for preset_id: StringName in panel.get_preset_ids():
		assert_bool(panel.get_preset_button(preset_id).disabled).is_true()
		assert_str(panel.get_preset_marker_text(preset_id)).is_equal("未绑定单位")


## 面板的非交互背景必须让战场点击穿透，只有按钮才拦截鼠标事件。
func test_non_interactive_background_lets_battlefield_clicks_through() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding], [sword, guard, binding])
	panel.bind_pawn(pawn)

	assert_int(panel.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int((panel.get_node("Rows") as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int((panel.get_node("StatusLabel") as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	# INC-UI-021：不可操作按钮（未解锁 / 当前 Build / 战斗中）必须让战场点击穿透，
	# 只有真正可点的按钮才拦截鼠标，避免增高的 Build 面板挡住左键操作。
	assert_int(panel.get_preset_button(BuildLoadoutPanel.PRESET_A_ID).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int(panel.get_skill_button(binding).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

	assert_bool(pawn.learn_active_skill(binding)).is_true()
	assert_int(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_int(panel.get_skill_button(binding).mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)

	panel.set_switch_locked(true)
	assert_int(panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int(panel.get_skill_button(binding).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_int(panel.get_apply_button().mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


## 主场景接线：production 两套预设来自 main.tscn，开局战斗进行中即处于锁定态。
func test_main_scene_wires_production_presets_and_locks_during_combat() -> void:
	var main: Node2D = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	auto_free(main)
	add_child(main)
	await await_idle_frame()
	var panel: BuildLoadoutPanel = main.get_node_or_null("HUD/BuildLoadoutPanel") as BuildLoadoutPanel

	assert_object(panel).is_not_null()
	assert_array(_skill_ids(panel.get_preset_skills(BuildLoadoutPanel.PRESET_A_ID))).contains_exactly([
		"sword_strike", "guard_true_qi",
	])
	assert_array(_skill_ids(panel.get_preset_skills(BuildLoadoutPanel.PRESET_B_ID))).contains_exactly([
		"sword_strike", "binding_spell",
	])
	assert_bool(panel.is_switch_locked()).is_true()

## INC-TESTING-021：自定义 Build 编辑器把完整技能池按「已解锁 / 未解锁」呈现，
## 待选上限直接来自 Pawn 的境界容量，解锁不会自动进入待选或装配。
func test_custom_build_lists_full_pool_and_locks_unlearned_skills() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var dash: ActiveSkillDefinition = _skill(DASH_SKILL_PATH)
	var aoe: ActiveSkillDefinition = _skill(SWORD_AOE_SKILL_PATH)
	var lifesteal: ActiveSkillDefinition = _skill(LIFESTEAL_SKILL_PATH)
	var rejuvenation: ActiveSkillDefinition = _skill(REJUVENATION_SKILL_PATH)
	var breaking: ActiveSkillDefinition = _skill(BREAKING_SLASH_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel(
		[sword, guard], [sword, binding],
		[sword, guard, binding, dash, aoe, lifesteal, rejuvenation, breaking])
	panel.bind_pawn(pawn)

	assert_array(_skill_ids(panel.get_available_skills())).contains_exactly([
		"sword_strike", "guard_true_qi", "binding_spell", "dash_step",
		"sword_aoe", "blood_drain", "rejuvenation", "breaking_slash",
	])
	assert_int(panel.get_custom_capacity()).is_equal(2)
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_str(panel.get_skill_marker_text(sword)).is_equal("已选")
	assert_str(panel.get_skill_marker_text(guard)).is_equal("已选")
	assert_str(panel.get_skill_marker_text(binding)).is_equal("未解锁")
	assert_bool(panel.get_skill_button(binding).disabled).is_true()
	assert_bool(panel.get_skill_button(dash).disabled).is_true()
	assert_str(panel.get_custom_hint_text()).contains("已选 2 / 2")


## 容量满时新增点选必须被拒绝（原因可复核、待选与装配零副作用），取消一个后才允许换入新技能。
func test_capacity_full_rejects_extra_selection_without_mutation() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding], [sword, guard, binding])
	panel.bind_pawn(pawn)
	assert_bool(pawn.learn_active_skill(binding)).is_true()

	panel.get_skill_button(binding).pressed.emit()

	assert_str(panel.get_last_reason()).is_equal(BuildLoadoutPanel.REASON_CAPACITY_FULL)
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_false()

	panel.get_skill_button(guard).pressed.emit()
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["sword_strike"])
	panel.get_skill_button(binding).pressed.emit()
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["sword_strike", "binding_spell"])
	assert_bool(panel.apply_custom_loadout()).is_true()
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "binding_spell"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_true()


## 非 A/B 预设组合（护体真气 + 回春术）必须能通过自定义编辑器真实装配，证明 Build 表达不再被预设锁死。
func test_custom_build_applies_non_preset_combination() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var rejuvenation: ActiveSkillDefinition = _skill(REJUVENATION_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding], [sword, guard, binding, rejuvenation])
	panel.bind_pawn(pawn)
	assert_bool(pawn.learn_active_skill(rejuvenation)).is_true()
	var results: Array = []
	panel.custom_loadout_applied.connect(func(_p: Pawn, skills: Array[ActiveSkillDefinition], success: bool, reason: String) -> void:
		results.append({"ids": _skill_ids(skills), "success": success, "reason": reason})
	)

	# 取消御剑斩，换入回春术：待选 = [护体真气, 回春术]，既不是 Build A 也不是 Build B。
	panel.get_skill_button(sword).pressed.emit()
	panel.get_skill_button(rejuvenation).pressed.emit()
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["guard_true_qi", "rejuvenation"])

	assert_bool(panel.apply_custom_loadout()).is_true()

	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["guard_true_qi", "rejuvenation"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_true()
	assert_str(String(panel.get_active_preset_id())).is_equal("")
	assert_int(results.size()).is_equal(1)
	assert_bool(results[0].get("success", false)).is_true()
	assert_str(results[0].get("reason", "?")).is_equal(BuildLoadoutPanel.REASON_NONE)
	assert_array(results[0].get("ids", []) as Array).contains_exactly(["guard_true_qi", "rejuvenation"])


## 解锁新技能只让对应行变成可选：不自动进入待选、不自动装配（沿用 INC-WORLD-007 口径）。
func test_unlocking_skill_does_not_auto_select_or_equip() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding], [sword, guard, binding])
	panel.bind_pawn(pawn)

	assert_bool(pawn.learn_active_skill(binding)).is_true()

	assert_str(panel.get_skill_marker_text(binding)).is_equal("可选")
	assert_bool(panel.get_skill_button(binding).disabled).is_false()
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(pawn.has_explicit_active_skill_loadout()).is_false()


## 战斗中锁定：自定义点选与应用都必须零副作用；解除锁定后同一路径立即可用。
func test_switch_lock_blocks_custom_selection_and_apply() -> void:
	var sword: ActiveSkillDefinition = _skill(SWORD_SKILL_PATH)
	var guard: ActiveSkillDefinition = _skill(GUARD_SKILL_PATH)
	var binding: ActiveSkillDefinition = _skill(BINDING_SKILL_PATH)
	var pawn: Pawn = _spawn_pawn([sword, guard])
	var panel: BuildLoadoutPanel = _spawn_panel([sword, guard], [sword, binding], [sword, guard, binding])
	panel.bind_pawn(pawn)
	assert_bool(pawn.learn_active_skill(binding)).is_true()

	panel.set_switch_locked(true)
	panel.get_skill_button(guard).pressed.emit()
	assert_str(panel.get_last_reason()).is_equal(BuildLoadoutPanel.REASON_SWITCH_LOCKED)
	assert_array(_skill_ids(panel.get_pending_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(panel.apply_custom_loadout()).is_false()
	assert_str(panel.get_last_reason()).is_equal(BuildLoadoutPanel.REASON_SWITCH_LOCKED)
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "guard_true_qi"])
	assert_bool(panel.get_apply_button().disabled).is_true()

	panel.set_switch_locked(false)
	panel.get_skill_button(guard).pressed.emit()
	panel.get_skill_button(binding).pressed.emit()
	assert_bool(panel.apply_custom_loadout()).is_true()
	assert_array(_skill_ids(pawn.get_equipped_active_skills())).contains_exactly(["sword_strike", "binding_spell"])


## 生产入口（INC-CORE-015）：main.tscn 必须把 8 个玩家技能全部接进自定义技能池，
## 不能只接 A/B 预设用到的 3 个技能。
func test_main_scene_wires_full_eight_skill_pool() -> void:
	var main: Node2D = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	auto_free(main)
	add_child(main)
	await await_idle_frame()
	var panel: BuildLoadoutPanel = main.get_node_or_null("HUD/BuildLoadoutPanel") as BuildLoadoutPanel

	assert_object(panel).is_not_null()
	assert_array(_skill_ids(panel.get_available_skills())).contains_exactly([
		"sword_strike", "guard_true_qi", "binding_spell", "dash_step",
		"sword_aoe", "blood_drain", "rejuvenation", "breaking_slash",
	])
	assert_bool(panel.is_switch_locked()).is_true()
