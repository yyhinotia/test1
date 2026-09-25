extends SceneTree

## 生成 Pawn 信息卡（PawnInfoPanel）的布局证据（需要真实渲染，不能用 --headless）。
## 运行方式：
##   godot --path . --script res://test/tools/capture_pawn_info_panel_evidence.gd
## 截图与文本报告保存到 res://.mcp/godot-runtime/screenshots/（该目录在 .gitignore 中，不入库）。
##
## 为什么必须用真实窗口：--headless 的 dummy 窗口固定为 64x64（见 AGENTS.md §10），
## CanvasLayer 下的控件会按 64x64 视口解析锚点，布局结论完全失真。
##
## 覆盖内容（AGENTS.md §5.4 要求同时验证 16:9 / 16:10 / 窄屏）：
##   1. 三档窗口下信息卡是否越出逻辑视口、是否与顶部 HUD、右上暂停状态标签重叠；
##   2. 战斗中（精简）与暂停（完整）两种模式的矩形与文本可见性；
##   3. 暂停遮罩是否仍绘制在信息卡之上。
##
## 因为 Windows 版 Godot 是 GUI 子系统程序，PowerShell 不会回收它的 stdout，
## 所以本脚本除了 print() 之外，还会把同样的证据行写入报告文件。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const OUTPUT_DIR: String = "res://.mcp/godot-runtime/screenshots"
const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/pawn_info_panel_evidence_report.txt"

## AGENTS.md §5.4：新增 UI 必须同时验证 16:9、16:10 和窄屏（800x720 → 逻辑视口 1152x1036）。
const WINDOW_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1152, 720),
	Vector2i(800, 720),
]

const PANEL_PATH: String = "HUD/PawnInfoPanel"
const HUD_MARGIN_PATH: String = "HUD/HudMargin"
const PAUSE_LABEL_PATH: String = "HUD/PauseStateLabel"
const PAUSE_OVERLAY_PATH: String = "HUD/PauseOverlay"
const CONTENT_PATH: String = "Margin/Panel/Content"
const NAME_LABEL_PATH: String = "Margin/Panel/Content/HeaderSection/NameLabel"
const VITAL_SECTION_PATH: String = "Margin/Panel/Content/VitalSection"
const ATTRIBUTE_SECTION_PATH: String = "Margin/Panel/Content/AttributeSection"
const BUILD_SECTION_PATH: String = "Margin/Panel/Content/BuildSection"
const BUILD_LABEL_PATH: String = "Margin/Panel/Content/BuildSection/BuildLabel"
const CULTIVATION_SECTION_PATH: String = "Margin/Panel/Content/CultivationSection"
const CULTIVATION_LABEL_PATH: String = "Margin/Panel/Content/CultivationSection/CultivationLabel"
const CULTIVATION_PROGRESS_PATH: String = "Margin/Panel/Content/CultivationSection/CultivationProgress"

var _main: Node2D
var _panel: PawnInfoPanel
var _player: Pawn
var _report_lines: Array[String] = []
var _failures: Array[String] = []


func _initialize() -> void:
	_main = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	root.add_child(_main)
	for _i: int in 6:
		await process_frame

	_player = _main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = _main.get_node("Pawns/EnemyPawn")
	# 把敌人移出战场，避免 AI 在取证期间改变玩家数值。
	enemy.global_position = Vector2(-4000.0, -4000.0)
	_panel = _main.get_node(PANEL_PATH) as PawnInfoPanel
	_main.call("_set_selected_pawn", _player)
	for _i: int in 3:
		await process_frame

	await _sweep_resolutions()
	await _check_pause_overlay()

	_write_report()
	print("CAPTURE_DONE FAILURES=", _failures.size())
	quit(1 if not _failures.is_empty() else 0)


## 三档窗口逐一验证：战斗中精简态与暂停完整态都要不越界、不压 HUD、内容不溢出。
func _sweep_resolutions() -> void:
	for size: Vector2i in WINDOW_RESOLUTIONS:
		var applied: bool = await _apply_window_size(size)
		if not applied:
			_fail("RESIZE_FAILED target=%s actual=%s" % [size, DisplayServer.window_get_size()])

		_main.call("_set_paused", false)
		for _i: int in 2:
			await process_frame
		await _measure("COMBAT", size)
		await _capture("pawn_info_panel_%dx%d_combat" % [size.x, size.y])

		_main.call("_set_paused", true)
		for _i: int in 3:
			await process_frame
		await _measure("PAUSED", size)
		await _capture("pawn_info_panel_%dx%d_paused" % [size.x, size.y])
		_main.call("_set_paused", false)
		for _i: int in 2:
			await process_frame


## 单一模式的矩形与文本实测：几何关系用矩形相交判断，文本用节点真实 text 判断。
func _measure(mode: String, window_size: Vector2i) -> void:
	var viewport_rect: Rect2 = root.get_visible_rect()
	var panel_rect: Rect2 = _panel.get_global_rect()
	var hud_rect: Rect2 = (_main.get_node(HUD_MARGIN_PATH) as Control).get_global_rect()
	var pause_label_rect: Rect2 = (_main.get_node(PAUSE_LABEL_PATH) as Control).get_global_rect()
	var content_rect: Rect2 = (_panel.get_node(CONTENT_PATH) as Control).get_global_rect()
	var name_label: Label = _panel.get_node(NAME_LABEL_PATH)
	var hud_overlap: bool = panel_rect.intersects(hud_rect)
	var pause_label_overlap: bool = panel_rect.intersects(pause_label_rect)
	var inside_viewport: bool = viewport_rect.encloses(panel_rect)
	var content_fits: bool = panel_rect.encloses(content_rect)
	var attribute_visible: bool = (_panel.get_node(ATTRIBUTE_SECTION_PATH) as Control).is_visible_in_tree()
	var build_visible: bool = (_panel.get_node(BUILD_SECTION_PATH) as Control).is_visible_in_tree()
	var build_label: Label = _panel.get_node(BUILD_LABEL_PATH)
	var vital_visible: bool = (_panel.get_node(VITAL_SECTION_PATH) as Control).is_visible_in_tree()
	var cultivation_visible: bool = (_panel.get_node(CULTIVATION_SECTION_PATH) as Control).is_visible_in_tree()
	var cultivation_label: Label = _panel.get_node(CULTIVATION_LABEL_PATH)

	_report("MODE=%s WINDOW=%s VIEWPORT=%s PANEL=%s HUD=%s PAUSE_LABEL=%s" % [
		mode, window_size, viewport_rect, panel_rect, hud_rect, pause_label_rect,
	])
	_report("MODE=%s BOUNDS_INSIDE_VIEWPORT=%s HUD_OVERLAP=%s PAUSE_LABEL_OVERLAP=%s CONTENT_FITS=%s" % [
		mode, inside_viewport, hud_overlap, pause_label_overlap, content_fits,
	])
	_report("MODE=%s NAME=%s VITAL_VISIBLE=%s ATTRIBUTE_VISIBLE=%s BUILD_VISIBLE=%s CULTIVATION_VISIBLE=%s CULTIVATION=%s COMPACT=%s" % [
		mode, name_label.text, vital_visible, attribute_visible, build_visible, cultivation_visible, cultivation_label.text, _panel.is_compact(),
	])
	_report("MODE=%s BUILD=%s" % [mode, build_label.text.replace("\n", " | ")])

	if not inside_viewport:
		_fail("%s %s：信息卡越出逻辑视口 %s" % [mode, window_size, panel_rect])
	if hud_overlap:
		_fail("%s %s：信息卡与顶部 HUD 重叠 HudMargin=%s" % [mode, window_size, hud_rect])
	if pause_label_overlap:
		_fail("%s %s：信息卡与暂停状态标签重叠 PauseStateLabel=%s" % [mode, window_size, pause_label_rect])
	if not content_fits:
		_fail("%s %s：内容溢出面板 content=%s panel=%s" % [mode, window_size, content_rect, panel_rect])
	if not vital_visible:
		_fail("%s %s：资源区必须始终可见" % [mode, window_size])
	if name_label.text.is_empty():
		_fail("%s %s：身份区姓名不得为空" % [mode, window_size])

	var expect_full: bool = mode == "PAUSED"
	if _panel.is_compact() == expect_full:
		_fail("%s %s：精简态与暂停态判定错误 COMPACT=%s" % [mode, window_size, _panel.is_compact()])
	if expect_full and not (build_label.text.contains("功法") and build_label.text.contains("武器") and build_label.text.contains("被动")):
		_fail("%s %s：完整模式 Build 区应显示四类槽位，实际 %s" % [mode, window_size, build_label.text.replace("\n", " | ")])
	if attribute_visible != expect_full or build_visible != expect_full:
		_fail("%s %s：属性区/ Build 区显隐与模式不匹配 ATTRIBUTE=%s BUILD=%s" % [
			mode, window_size, attribute_visible, build_visible,
		])
	if cultivation_visible != expect_full:
		_fail("%s %s：修为区显隐与模式不匹配 CULTIVATION_VISIBLE=%s" % [
			mode, window_size, cultivation_visible,
		])
	if expect_full and cultivation_label.text.is_empty():
		_fail("%s %s：完整模式修为文案不得为空" % [mode, window_size])


## 暂停遮罩必须仍绘制在信息卡之上，否则暂停时信息卡会盖住遮罩。
func _check_pause_overlay() -> void:
	_main.call("_set_paused", true)
	for _i: int in 3:
		await process_frame
	var overlay: Control = _main.get_node(PAUSE_OVERLAY_PATH)
	var above: bool = overlay.get_index() > _panel.get_index()
	_report("PAUSE_OVERLAY_VISIBLE=%s DRAWN_ABOVE_PANEL=%s" % [overlay.visible, above])
	if not overlay.visible:
		_fail("暂停时遮罩应可见")
	if not above:
		_fail("暂停遮罩必须排在信息卡之后绘制（当前 panel_index=%s overlay_index=%s）" % [
			_panel.get_index(), overlay.get_index(),
		])
	_main.call("_set_paused", false)


## 申请窗口尺寸并等待其真正生效；Windows 下偶发被合成器合并，因此带重试。
func _apply_window_size(size: Vector2i) -> bool:
	for _attempt: int in 20:
		DisplayServer.window_set_size(size)
		for _i: int in 5:
			await process_frame
		if DisplayServer.window_get_size() == size:
			# 尺寸生效后，再等几帧让 stretch 布局与 CanvasLayer 重新计算。
			for _j: int in 4:
				await process_frame
			return true
	return false


## 同时打印并登记一行证据；Windows GUI 子系统的 Godot 收不回 stdout，因此报告文件才是权威证据。
func _report(line: String) -> void:
	print(line)
	_report_lines.append(line)


func _fail(message: String) -> void:
	_failures.append(message)
	_report("FAILED: %s" % message)


func _write_report() -> void:
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		print("REPORT_WRITE_FAILED ", FileAccess.get_open_error())
		return
	file.store_line("pawn_info_panel_evidence_report %s (local time)" % Time.get_datetime_string_from_system(false, true))
	file.store_line("GODOT=%s" % Engine.get_version_info().get("string", "unknown"))
	for line: String in _report_lines:
		file.store_line(line)
	file.store_line("FAILURES=%d" % _failures.size())
	file.close()
	print("REPORT_WRITTEN ", REPORT_PATH)


func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = "%s/%s.png" % [OUTPUT_DIR, shot_name]
	var err: int = image.save_png(path)
	print("CAPTURE ", path, " err=", err, " size=", image.get_size())