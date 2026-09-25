extends Node2D

## 场景化测试入口的实现（INC-TESTING-012）。
##
## `tests/*.tscn` 只用导出参数描述「要验证哪个场景」，实现只有这一份：
## 准备正式主场景（`main.tscn`）→ 关掉默认秘境 → 让指定遭遇开局 → 按需预置前置条件 → 把窗口标题改成入口名。
## 本目录只负责「把游戏摆到一个可观察的状态」，不含任何战斗、奖励或 Build 规则；
## 规则仍在 `game/` 下，断言仍在 `test/` 下（职责边界见 `tests/README.md`）。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/skills/player_binding_skill.tres"
const BUILD_PANEL_PATH: String = "HUD/BuildLoadoutPanel"

## 入口标识（同时出现在窗口标题与场景报告里，便于人工验收时确认自己跑的是哪个入口）。
@export var scenario_id: StringName = &""
@export var scenario_title: String = ""
@export var scenario_instructions: String = ""
## 本入口要把游戏摆到哪个遭遇：留空表示沿用正式入口的开局遭遇。
@export var encounter: EncounterDefinition
## 前置条件：先把定身术标记为已解锁（等价于已经完成过 1v1 首通）。
@export var pre_learn_binding_spell: bool = false
## 前置条件：直接把玩家装配成 production Build B（对照入口用；正式玩法仍禁止自动切换）。
@export var pre_equip_build_b: bool = false
## 起局后是否选中玩家单位：信息卡 / 技能栏 / Build 面板都以选中单位为展示对象。
@export var select_player_on_start: bool = true

## 正式入口场景实例：测试入口只创建它，不修改它的资源。
var main: Node2D
var session: EncounterSession
## 本入口实际跑起来的遭遇 id（未开局时为空）。
var active_encounter_id: StringName = &""


func _ready() -> void:
	main = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	# 关掉默认秘境：测试入口只跑一个确定的遭遇，避免秘境房间链改变对照条件。
	# 这属于「测试专用参数」，因此只能出现在 tests/ 的入口脚本里，正式入口保持默认行为。
	var dungeon_run: DungeonRun = main.get_node("DungeonRun") as DungeonRun
	dungeon_run.default_dungeon = null
	add_child(main)
	await get_tree().process_frame
	session = main.get_node("EncounterSession") as EncounterSession
	if encounter != null:
		session.begin(encounter)
		await get_tree().process_frame
	_apply_preconditions()
	await get_tree().process_frame
	if select_player_on_start:
		# 复用主场景既有的选中路由（信息卡 / 技能栏 / Build 面板同步绑定）。
		main.call("_set_selected_pawn", session.get_player_pawn())
	_apply_window_title()
	print("SCENARIO_READY ", get_scenario_report())


## 前置条件只动 Pawn 的运行时投影（掌握 / 装配），不改 `PawnData` 与任何数值。
func _apply_preconditions() -> void:
	var player: Pawn = session.get_player_pawn()
	if player == null:
		return
	if pre_learn_binding_spell:
		player.learn_active_skill(load(BINDING_SKILL_PATH) as ActiveSkillDefinition)
	if pre_equip_build_b:
		# 预设内容取自 production 面板，避免测试入口复制一份 Build 定义。
		var panel: BuildLoadoutPanel = main.get_node_or_null(BUILD_PANEL_PATH) as BuildLoadoutPanel
		if panel != null:
			player.set_active_skill_loadout(panel.get_preset_skills(BuildLoadoutPanel.PRESET_B_ID))


func _apply_window_title() -> void:
	var window: Window = get_window()
	if window == null:
		return
	window.title = "test1 · tests/%s · %s" % [String(scenario_id), scenario_title]


## 场景报告：人工验收与自动化校验都读它，避免两边各自解析节点树。
func get_scenario_report() -> Dictionary:
	var player: Pawn = session.get_player_pawn() if session != null else null
	var active: EncounterDefinition = session.get_active_encounter() if session != null else null
	return {
		"id": String(scenario_id),
		"title": scenario_title,
		"instructions": scenario_instructions,
		"encounter": String(active.id) if active != null else "<none>",
		"state": session.get_state() if session != null else -1,
		"player_count": session.get_player_units().size() if session != null else 0,
		"enemy_count": session.get_enemy_units().size() if session != null else 0,
		"learned_active_skills": _skill_ids(player.get_known_active_skills()) if player != null else [],
		"equipped_active_skills": _skill_ids(player.get_equipped_active_skills()) if player != null else [],
	}


func _skill_ids(skills: Array[ActiveSkillDefinition]) -> Array:
	var ids: Array = []
	for skill: ActiveSkillDefinition in skills:
		ids.append(String(skill.id) if skill != null else "<null>")
	return ids
