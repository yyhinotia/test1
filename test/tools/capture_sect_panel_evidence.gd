extends SceneTree

## 宗门面板真实窗口布局取证（INC-UI-016）。
## 运行：
##   godot --path . --script res://test/tools/capture_sect_panel_evidence.gd
## 输出到 .mcp/godot-runtime/screenshots/（已忽略，不入库）。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const SECT_PANEL_SCENE_PATH: String = "res://game/ui/sect_panel.tscn"
const FACILITY_DIR: String = "res://game/sect/data/facilities"
const TECHNIQUE_DIR: String = "res://game/cultivation/data/techniques"
const OUTPUT_DIR: String = "res://.mcp/godot-runtime/screenshots"
const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/sect_panel_evidence_report.txt"

const WINDOW_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1152, 720),
	Vector2i(800, 720),
]
const FACILITY_IDS: Array[String] = [
	"cave_dwelling",
	"spirit_array",
	"spirit_field",
	"alchemy_room",
	"forge_room",
	"scripture_pavilion",
]
const DOCK_PATH: String = "HUD/BottomLeftDock"
const EXISTING_CHILD_NAMES: Array[String] = [
	"PawnInfoPanel",
	"SkillBar",
	"EncounterPanel",
	"DungeonPanel",
]

var _main: Node2D
var _dock: Control
var _panel: SectPanel
var _report_lines: Array[String] = []
var _failures: Array[String] = []


func _initialize() -> void:
	_main = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	root.add_child(_main)
	for _i: int in 6:
		await process_frame

	var enemy: Pawn = _main.get_node("Pawns/EnemyPawn") as Pawn
	enemy.global_position = Vector2(-4000.0, -4000.0)
	var player: Pawn = _main.get_node("Pawns/PlayerPawn") as Pawn

	var state: SectState = SectState.new()
	state.name = "EvidenceSectState"
	state.facilities = _load_facilities()
	_main.add_child(state)
	state.bind_cultivator(player)
	state.deposit_spirit_stones(500)
	state.harvest_spirit_field()
	state.harvest_spirit_field()
	state.refine_pill()

	_dock = _main.get_node(DOCK_PATH) as Control
	_panel = (load(SECT_PANEL_SCENE_PATH) as PackedScene).instantiate() as SectPanel
	_panel.name = "SectPanel"
	_dock.add_child(_panel)
	_panel.bind_state(state)
	_panel.set_learnable_techniques(_load_techniques())
	await _wait_frames(6)

	for window_size: Vector2i in WINDOW_RESOLUTIONS:
		await _measure_resolution(window_size)

	_write_report()
	print("SECT_PANEL_CAPTURE_DONE FAILURES=", _failures.size())
	quit(1 if not _failures.is_empty() else 0)


func _load_facilities() -> Array[SectFacilityDefinition]:
	var result: Array[SectFacilityDefinition] = []
	for facility_id: String in FACILITY_IDS:
		result.append(load("%s/%s.tres" % [FACILITY_DIR, facility_id]) as SectFacilityDefinition)
	return result


func _load_techniques() -> Array[TechniqueDefinition]:
	return [
		load("%s/sword_cultivation.tres" % TECHNIQUE_DIR) as TechniqueDefinition,
		load("%s/body_cultivation.tres" % TECHNIQUE_DIR) as TechniqueDefinition,
	]


func _measure_resolution(window_size: Vector2i) -> void:
	var applied: bool = await _apply_window_size(window_size)
	_report("RESOLUTION=%s APPLIED=%s VIEWPORT=%s" % [window_size, applied, root.get_visible_rect()])
	if not applied:
		_fail("%s：窗口尺寸未生效" % window_size)

	var viewport_rect: Rect2 = root.get_visible_rect()
	var dock_rect: Rect2 = _dock.get_global_rect()
	var panel_rect: Rect2 = _panel.get_global_rect()
	var panel_inside: bool = viewport_rect.encloses(panel_rect)
	var dock_inside: bool = viewport_rect.encloses(dock_rect)
	_report("RESOLUTION=%s DOCK=%s PANEL=%s PANEL_INSIDE=%s DOCK_INSIDE=%s" % [
		window_size, dock_rect, panel_rect, panel_inside, dock_inside,
	])
	if not panel_inside:
		_fail("%s：SectPanel 越出视口 panel=%s viewport=%s" % [window_size, panel_rect, viewport_rect])
	if not dock_inside:
		_fail("%s：BottomLeftDock 越出视口 dock=%s viewport=%s" % [window_size, dock_rect, viewport_rect])

	for child_name: String in EXISTING_CHILD_NAMES:
		var sibling: Control = _dock.get_node_or_null(child_name) as Control
		if sibling == null:
			continue
		var sibling_rect: Rect2 = sibling.get_global_rect()
		var overlap: bool = panel_rect.intersects(sibling_rect)
		_report("RESOLUTION=%s SIBLING=%s RECT=%s OVERLAP=%s" % [
			window_size, child_name, sibling_rect, overlap,
		])
		if overlap:
			_fail("%s：SectPanel 与 %s 重叠 panel=%s sibling=%s" % [
				window_size, child_name, panel_rect, sibling_rect,
			])

	_check_text_bounds(window_size)
	_capture("sect_panel_%dx%d.png" % [window_size.x, window_size.y])


func _check_text_bounds(window_size: Vector2i) -> void:
	var panel_rect: Rect2 = _panel.get_global_rect()
	var overflow: Array[String] = []
	for label: Label in _find_labels(_panel):
		var label_rect: Rect2 = label.get_global_rect()
		if not panel_rect.grow(1.0).encloses(label_rect):
			overflow.append("%s=%s" % [label.name, label_rect])
	_report("RESOLUTION=%s TEXT_OVERFLOW=%s" % [window_size, overflow])
	if not overflow.is_empty():
		_fail("%s：文本越出面板 %s" % [window_size, overflow])


func _find_labels(node: Node) -> Array[Label]:
	var result: Array[Label] = []
	for child: Node in node.get_children():
		if child is Label:
			result.append(child as Label)
		result.append_array(_find_labels(child))
	return result


func _apply_window_size(size: Vector2i) -> bool:
	for _attempt: int in 20:
		DisplayServer.window_set_size(size)
		await _wait_frames(5)
		if DisplayServer.window_get_size() == size:
			await _wait_frames(4)
			return true
	return false


func _wait_frames(count: int) -> void:
	for _i: int in count:
		await process_frame


func _report(line: String) -> void:
	print(line)
	_report_lines.append(line)


func _fail(message: String) -> void:
	_failures.append(message)
	_report("FAILED: %s" % message)


func _write_report() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		print("REPORT_WRITE_FAILED ", FileAccess.get_open_error())
		return
	file.store_line("sect_panel_evidence_report %s (local time)" % Time.get_datetime_string_from_system(false, true))
	file.store_line("GODOT=%s" % Engine.get_version_info().get("string", "unknown"))
	for line: String in _report_lines:
		file.store_line(line)
	file.store_line("FAILURES=%d" % _failures.size())
	file.close()
	print("REPORT_WRITTEN ", REPORT_PATH)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = "%s/%s" % [OUTPUT_DIR, shot_name]
	var err: int = image.save_png(path)
	print("CAPTURE ", path, " err=", err, " size=", image.get_size())
