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
## 测试呈现（INC-TESTING-016）：与 Build 验收无关的正式 HUD 菜单，只隐藏、不删除节点。
## `EncounterPanel/Buttons` 是换敌入口；秘境 / 宗门面板在 Build 验收入口里没有作用。
## 刻意保留 `EncounterPanel/RestartButton`：Gate 0「同一遭遇可重复挑战」与人工轮 Round 2 都靠它。
const NON_BUILD_UI_PATHS: Array[String] = [
	"HUD/BottomLeftDock/EncounterPanel/Buttons",
	"HUD/BottomLeftDock/DungeonPanel",
	"HUD/BottomLeftDock/SectPanel",
]
## 测试自证（INC-TESTING-017）：跑错入口（如按 F5 跑 main.tscn）时，屏幕上必须有测试横幅。
## 名牌与配色都只挂在运行时实例上，不写进 .tscn，也不改 game/ 下的正式表现。
const BANNER_LAYER_NAME: String = "ScenarioBannerLayer"
const BANNER_NAME: String = "ScenarioBanner"
const BANNER_LABEL_NAME: String = "BannerLabel"
const NAMEPLATE_NAME: String = "ScenarioNameplate"
const PLAYER_TINT: Color = Color(0.55, 1.0, 0.72)
const ENEMY_TINTS: Array[Color] = [
	Color(1.0, 0.58, 0.52),
	Color(1.0, 0.85, 0.45),
	Color(0.72, 0.62, 1.0),
	Color(0.5, 0.9, 1.0),
]
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
## 测试呈现（INC-TESTING-016）：当前 6 个入口都只验证 Build，默认隐藏与 Build 无关的菜单面板。
## 只改可见性，不改玩法规则；需要完整 HUD 的非 Build 测试场景可在自己的 .tscn 里设为 false。
@export var hide_non_build_panels: bool = true
## 人工轮可控开局（INC-TESTING-015）：入口完成摆放后立即暂停，玩家按 Space 才开始实时战斗。
## 也可通过用户参数 `-- --pause-on-start` 开启，供人工轮命令行启动使用。
@export var pause_on_start: bool = false
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
## 测试横幅文本（INC-TESTING-017）：入口 id / 场景标题 / 遭遇 / 敌方名单 / 本局结果。
var _banner_label: Label
var _last_outcome_text: String = ""


func _ready() -> void:
	main = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	# 关掉默认秘境：测试入口只跑一个确定的遭遇，避免秘境房间链改变对照条件。
	# 这属于「测试专用参数」，因此只能出现在 tests/ 的入口脚本里，正式入口保持默认行为。
	var dungeon_run: DungeonRun = main.get_node("DungeonRun") as DungeonRun
	dungeon_run.default_dungeon = null
	add_child(main)
	await get_tree().process_frame
	if hide_non_build_panels:
		_hide_non_build_panels()
	session = main.get_node("EncounterSession") as EncounterSession
	if not session.encounter_started.is_connected(_on_encounter_started_markers):
		session.encounter_started.connect(_on_encounter_started_markers)
	if not session.encounter_finished.is_connected(_on_encounter_finished_banner):
		session.encounter_finished.connect(_on_encounter_finished_banner)
	if encounter != null:
		session.begin(encounter)
		await get_tree().process_frame
	_apply_preconditions()
	await get_tree().process_frame
	if select_player_on_start:
		# 复用主场景既有的选中路由（信息卡 / 技能栏 / Build 面板同步绑定）。
		main.call("_set_selected_pawn", session.get_player_pawn())
	_apply_window_title()
	_install_scenario_banner()
	_refresh_unit_markers()
	if record_combat_events:
		_start_round_recording()
	entry_ready = true
	print("SCENARIO_READY ", get_scenario_report())
	if pause_on_start or OS.get_cmdline_user_args().has("--pause-on-start"):
		main.call("_set_paused", true)
		print("SCENARIO_PAUSED")


## 测试入口只保留 Build 验收相关 UI：换敌按钮、秘境面板、宗门面板全部隐藏。
## 刻意不删除节点——`main.gd` 的 @onready 引用与既有集成测试仍按正式节点树工作。
func _hide_non_build_panels() -> void:
	for path: String in NON_BUILD_UI_PATHS:
		var node: CanvasItem = main.get_node_or_null(path) as CanvasItem
		if node == null:
			push_warning("测试入口未找到要隐藏的非 Build UI：%s" % path)
			continue
		node.visible = false


## 测试横幅：把「跑的是哪个入口、敌方是谁」写在屏幕上。
## 位置固定在右下角 Build 面板正上方，只读且不接收鼠标，不遮挡 Build 面板。
func _install_scenario_banner() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = BANNER_LAYER_NAME
	layer.layer = 20
	add_child(layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = BANNER_NAME
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0
	panel.anchor_top = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -312.0
	panel.offset_top = -304.0
	panel.offset_right = -16.0
	panel.offset_bottom = -208.0
	layer.add_child(panel)
	_banner_label = Label.new()
	_banner_label.name = BANNER_LABEL_NAME
	_banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_label.add_theme_font_size_override("font_size", 13)
	panel.add_child(_banner_label)
	_update_banner_text()


func _update_banner_text() -> void:
	if _banner_label == null:
		return
	var names: Array[String] = _enemy_display_names()
	var active: EncounterDefinition = session.get_active_encounter() if session != null else null
	var encounter_text: String = "<未开局>"
	if active != null:
		encounter_text = "%s（%s） · 敌方 %d：%s" % [active.display_name, active.id, names.size(), _join_names(names)]
	var lines: Array[String] = [
		"[测试入口] tests/%s" % get_scene_file_path().get_file(),
		scenario_title,
		"遭遇：%s" % encounter_text,
	]
	if not _last_outcome_text.is_empty():
		lines.append(_last_outcome_text)
	_banner_label.text = "\n".join(lines)


func _on_encounter_started_markers(_encounter: EncounterDefinition, _player: Pawn, _enemy: Pawn) -> void:
	_last_outcome_text = ""
	_refresh_unit_markers()
	_update_banner_text()


func _on_encounter_finished_banner(_encounter: EncounterDefinition, outcome: int) -> void:
	_last_outcome_text = "本局结果：%s" % EncounterSession.get_outcome_label(outcome)
	_update_banner_text()


## 敌我标识：名牌 + 配色，让 1v1 / 1v2 / 1v3 在共用占位图下仍然可分。
## 必须在每次 `encounter_started` 后重建——重开会换掉整批 Pawn 实例。
func _refresh_unit_markers() -> void:
	if session == null:
		return
	var enemies: Array[Pawn] = session.get_enemy_units()
	for index: int in enemies.size():
		var enemy: Pawn = enemies[index]
		_apply_unit_marker(enemy, "敌 · %s" % enemy.data.display_name, ENEMY_TINTS[index % ENEMY_TINTS.size()])
	var player: Pawn = session.get_player_pawn()
	if player != null:
		_apply_unit_marker(player, "玩家 · %s" % player.data.display_name, PLAYER_TINT)


func _apply_unit_marker(pawn: Pawn, label_text: String, tint: Color) -> void:
	if pawn == null or not is_instance_valid(pawn):
		return
	var sprite: Sprite2D = pawn.get_node_or_null("Visual/Sprite2D") as Sprite2D
	if sprite != null:
		sprite.modulate = tint
	var plate: Label = pawn.get_node_or_null(NAMEPLATE_NAME) as Label
	if plate == null:
		plate = Label.new()
		plate.name = NAMEPLATE_NAME
		plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.position = Vector2(-80.0, -124.0)
		plate.custom_minimum_size = Vector2(160.0, 0.0)
		plate.size = Vector2(160.0, 22.0)
		plate.add_theme_font_size_override("font_size", 14)
		plate.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		plate.add_theme_constant_override("outline_size", 4)
		pawn.add_child(plate)
	plate.text = label_text
	plate.add_theme_color_override("font_color", tint)


func _enemy_display_names() -> Array[String]:
	var names: Array[String] = []
	if session == null:
		return names
	for enemy: Pawn in session.get_enemy_units():
		if enemy != null and enemy.data != null:
			names.append(enemy.data.display_name)
	return names


func _join_names(names: Array[String]) -> String:
	var text: String = ""
	for value: String in names:
		if not text.is_empty():
			text += " / "
		text += value
	return text if not text.is_empty() else "<无>"


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
		## 敌方名单（INC-TESTING-017）：自动化与人工都用它确认三档遭遇确实不同。
		"enemy_names": _enemy_display_names(),
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
