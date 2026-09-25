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
## 人工轮事件记录的默认落点（`.mcp/` 不入库，需要重跑入口才能重建）。
const DEFAULT_RECORD_PATH: String = "res://.mcp/godot-runtime/screenshots/human_replay_events.md"

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
## 人工轮取证（INC-TESTING-014）：开启后，每局结算把只读的 CombatEvent 事实追加到记录文件。
## 记录器只看事实、不下结论——Q1~Q4 原话与 Gate / Failure 结论仍然只能由人给出。
@export var record_combat_events: bool = false
## 记录文件路径：默认落在不入库的 `.mcp/`；自动化自检必须改成独立路径，避免污染人工记录。
@export var record_path: String = DEFAULT_RECORD_PATH

## 正式入口场景实例：测试入口只创建它，不修改它的资源。
var main: Node2D
var session: EncounterSession
## 本入口实际跑起来的遭遇 id（未开局时为空）。
var active_encounter_id: StringName = &""
## 人工轮取证状态：只有真正结算过的局才写文件（未打完的会话不产生记录）。
var _record_enabled: bool = false
var _record_round_index: int = 0
var _record_header_pending: bool = false
## 入口异步摆放完成的只读标记：自动化自检必须等它为 true 后才能推进战斗，
## 否则会在记录器挂载前结算，第一局不会落盘。
var entry_ready: bool = false


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
	if record_combat_events:
		_start_round_recording()
	entry_ready = true
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

## 开始人工轮取证：先只挂信号，第一局真正结算时才写文件。
func _start_round_recording() -> void:
	if session == null:
		return
	_record_enabled = true
	_record_round_index = 0
	_record_header_pending = true
	if not session.encounter_finished.is_connected(_on_round_finished_record):
		session.encounter_finished.connect(_on_round_finished_record)


## 每局结算追加一段只读事实：局号 / 遭遇 / 结算结果 / 时钟 / 装配 / 完整事件行。
## 不判定 Gate、不解释玩家行为——那些是玩家原话与人工结论的事。
func _on_round_finished_record(encounter: EncounterDefinition, outcome: int) -> void:
	if not _record_enabled:
		return
	_record_round_index += 1
	var player: Pawn = session.get_player_pawn()
	var log: CombatEventLog = session.get_combat_event_log()
	var known_text: String = "<无>"
	var equipped_text: String = "<无>"
	var resources_text: String = "<无>"
	if player != null:
		known_text = _join_skill_ids(player.get_known_active_skills())
		equipped_text = _join_skill_ids(player.get_equipped_active_skills())
		resources_text = "生命 %.1f / 护盾 %.1f" % [player.current_health, player.current_shield]
	var encounter_id: String = String(encounter.id) if encounter != null else "<none>"
	var scene_file: String = get_scene_file_path().get_file()
	var lines: Array[String] = []
	if _record_header_pending:
		_record_header_pending = false
		lines.append("")
		lines.append("# %s 人工轮事件记录 · %s" % [scene_file, Time.get_datetime_string_from_system(false)])
		lines.append("")
		lines.append("> 本文件由 `tests/%s` 在每局结算时追加，只记录机制事实；Q1~Q4 原话与 Gate 结论必须由玩家填写。" % scene_file)
		lines.append("")
	lines.append("## 第 %d 局 · %s · %s" % [
		_record_round_index,
		encounter_id,
		EncounterSession.get_outcome_label(outcome),
	])
	lines.append("")
	lines.append("- 事件时钟：%.2fs" % log.get_clock())
	lines.append("- 事件数量：%d" % log.get_event_count())
	lines.append("- 玩家剩余：%s" % resources_text)
	lines.append("- 已掌握技能：%s" % known_text)
	lines.append("- 已装配技能：%s" % equipped_text)
	lines.append("")
	lines.append("```text")
	for line: String in log.describe():
		lines.append(line)
	lines.append("```")
	lines.append("")
	_append_record_lines(lines)
	print("HUMAN_ROUND %d %s %s events=%d" % [
		_record_round_index,
		encounter_id,
		EncounterSession.get_outcome_label(outcome),
		log.get_event_count(),
	])


func _join_skill_ids(skills: Array[ActiveSkillDefinition]) -> String:
	var text: String = ""
	for skill: ActiveSkillDefinition in skills:
		if not text.is_empty():
			text += ", "
		text += String(skill.id) if skill != null else "<null>"
	return text if not text.is_empty() else "<无>"


func _ensure_record_dir() -> void:
	var directory: String = ProjectSettings.globalize_path(record_path.get_base_dir())
	if not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)


## 追加写：文件不存在时新建，存在时续写，人工轮的多局记录不会互相覆盖。
func _append_record_lines(lines: Array[String]) -> void:
	_ensure_record_dir()
	var file: FileAccess = FileAccess.open(record_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(record_path, FileAccess.WRITE)
	if file == null:
		push_warning("人工轮记录文件打开失败：%s" % record_path)
		return
	file.seek_end()
	for line: String in lines:
		file.store_line(line)
	file.close()
