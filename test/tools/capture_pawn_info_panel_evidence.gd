extends SceneTree

## 生成左下角 HUD（信息卡 + SkillBar）的真实窗口布局证据（不能用 --headless）。
## 运行方式：
##   godot --path . --script res://test/tools/capture_pawn_info_panel_evidence.gd
## 截图与文本报告保存到 res://.mcp/godot-runtime/screenshots/（该目录在 .gitignore 中，不入库）。
##
## 为什么必须用真实窗口：--headless 的 dummy 窗口固定为 64x64（见 AGENTS.md §10），
## CanvasLayer 下的控件会按 64x64 视口解析锚点，布局结论完全失真。
##
## 覆盖内容（AGENTS.md §5.4 要求同时验证 16:9 / 16:10 / 窄屏）：
##   1. 三档窗口下 Dock、信息卡、SkillBar 是否越出逻辑视口；
##   2. 信息卡与 SkillBar 互不重叠，且都不与顶部 HUD、右上暂停状态标签重叠；
##   3. 战斗中（精简）与暂停（完整）两种模式的矩形与文本可见性；
##   4. 暂停遮罩是否仍绘制在 Dock 之后；
##   5. 境界主动技能容量 2/3/4/5/6 是否自动生成对应数量的 SkillSlot。
##
## 因为 Windows 版 Godot 是 GUI 子系统程序，PowerShell 不会回收它的 stdout，
## 所以本脚本除了 print() 之外，还会把同样的证据行写入报告文件。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const QI_REFINING_REALM_PATH: String = "res://game/cultivation/data/realms/qi_refining.tres"
const OUTPUT_DIR: String = "res://.mcp/godot-runtime/screenshots"
const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/pawn_info_panel_evidence_report.txt"

## AGENTS.md §5.4：新增 UI 必须同时验证 16:9、16:10 和窄屏（800x720 → 逻辑视口 1152x1036）。
const WINDOW_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1152, 720),
	Vector2i(800, 720),
]

const DOCK_PATH: String = "HUD/BottomLeftDock"
const PANEL_PATH: String = "HUD/BottomLeftDock/PawnInfoPanel"
const SKILL_BAR_PATH: String = "HUD/BottomLeftDock/SkillBar"
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
const APPROX: float = 0.5

var _main: Node2D
var _dock: HBoxContainer
var _panel: PawnInfoPanel
var _skill_bar: SkillBar
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
	_dock = _main.get_node(DOCK_PATH) as HBoxContainer
	_panel = _main.get_node(PANEL_PATH) as PawnInfoPanel
	_skill_bar = _main.get_node(SKILL_BAR_PATH) as SkillBar
	_main.call("_set_selected_pawn", _player)
	for _i: int in 4:
		await process_frame

	await _sweep_capacities()
	await _sweep_resolutions()
	await _check_pause_overlay()

	_write_report()
	print("CAPTURE_DONE FAILURES=", _failures.size())
	quit(1 if not _failures.is_empty() else 0)


## 境界容量是槽位数量唯一来源：构造 2~6 容量，确认 SkillBar 自动排列 64px 方形槽位。
func _sweep_capacities() -> void:
	var original_realm: RealmDefinition = _player.get_realm()
	for capacity: int in range(2, 7):
		var realm: RealmDefinition = (load(QI_REFINING_REALM_PATH) as RealmDefinition).duplicate(true) as RealmDefinition
		realm.active_skill_slots = capacity
		_player.data.realm = realm
		_skill_bar.bind_pawn(_player)
		for _i: int in 3:
			await process_frame
		var slots: Array[SkillSlot] = _skill_bar.get_slots()
		var slots_ok: bool = slots.size() == capacity
		var size_ok: bool = true
		if not slots.is_empty():
			size_ok = absf(slots[0].size.x - SkillSlot.SLOT_SIZE) <= APPROX and absf(slots[0].size.y - SkillSlot.SLOT_SIZE) <= APPROX
		var bar_rect: Rect2 = _skill_bar.get_global_rect()
		var inside: bool = root.get_visible_rect().encloses(bar_rect)
		_report("CAPACITY=%d SLOTS=%d SLOT_SIZE=%s BAR=%s INSIDE=%s" % [
			capacity, slots.size(), (slots[0].size if not slots.is_empty() else Vector2.ZERO), bar_rect, inside,
		])
		if not slots_ok:
			_fail("境界容量 %d：SkillBar 槽位数应为 %d，实际 %d" % [capacity, capacity, slots.size()])
		if not size_ok:
			_fail("境界容量 %d：SkillSlot 应固定为 64x64" % capacity)
		if not inside:
			_fail("境界容量 %d：SkillBar 越出逻辑视口 %s" % [capacity, bar_rect])

	_player.data.realm = original_realm
	_skill_bar.bind_pawn(_player)
	for _i: int in 2:
		await process_frame


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
	var dock_rect: Rect2 = _dock.get_global_rect()
	var panel_rect: Rect2 = _panel.get_global_rect()
	var bar_rect: Rect2 = _skill_bar.get_global_rect()
	var hud_rect: Rect2 = (_main.get_node(HUD_MARGIN_PATH) as Control).get_global_rect()
	var pause_label_rect: Rect2 = (_main.get_node(PAUSE_LABEL_PATH) as Control).get_global_rect()
	var content_rect: Rect2 = (_panel.get_node(CONTENT_PATH) as Control).get_global_rect()
	var name_label: Label = _panel.get_node(NAME_LABEL_PATH)
	var dock_inside: bool = viewport_rect.encloses(dock_rect)
	var panel_inside: bool = viewport_rect.encloses(panel_rect)
	var bar_inside: bool = viewport_rect.encloses(bar_rect)
	var panel_bar_overlap: bool = panel_rect.intersects(bar_rect)
	var panel_hud_overlap: bool = panel_rect.intersects(hud_rect)
	var bar_hud_overlap: bool = bar_rect.intersects(hud_rect)
	var panel_pause_overlap: bool = panel_rect.intersects(pause_label_rect)
	var bar_pause_overlap: bool = bar_rect.intersects(pause_label_rect)
	var content_fits: bool = panel_rect.encloses(content_rect)
	var bottom_aligned: bool = absf(panel_rect.end.y - bar_rect.end.y) <= APPROX
	var panel_left_of_bar: bool = panel_rect.position.x <= bar_rect.position.x
	var attribute_visible: bool = (_panel.get_node(ATTRIBUTE_SECTION_PATH) as Control).is_visible_in_tree()
	var build_visible: bool = (_panel.get_node(BUILD_SECTION_PATH) as Control).is_visible_in_tree()
	var build_label: Label = _panel.get_node(BUILD_LABEL_PATH)
	var vital_visible: bool = (_panel.get_node(VITAL_SECTION_PATH) as Control).is_visible_in_tree()
	var cultivation_visible: bool = (_panel.get_node(CULTIVATION_SECTION_PATH) as Control).is_visible_in_tree()
	var cultivation_label: Label = _panel.get_node(CULTIVATION_LABEL_PATH)

	_report("MODE=%s WINDOW=%s VIEWPORT=%s DOCK=%s PANEL=%s BAR=%s HUD=%s PAUSE_LABEL=%s" % [
		mode, window_size, viewport_rect, dock_rect, panel_rect, bar_rect, hud_rect, pause_label_rect,
	])
	_report("MODE=%s DOCK_INSIDE=%s PANEL_INSIDE=%s BAR_INSIDE=%s PANEL_BAR_OVERLAP=%s PANEL_HUD_OVERLAP=%s BAR_HUD_OVERLAP=%s PANEL_PAUSE_OVERLAP=%s BAR_PAUSE_OVERLAP=%s CONTENT_FITS=%s BOTTOM_ALIGNED=%s PANEL_LEFT_OF_BAR=%s SLOTS=%d" % [
		mode, dock_inside, panel_inside, bar_inside, panel_bar_overlap,
		panel_hud_overlap, bar_hud_overlap, panel_pause_overlap, bar_pause_overlap,
		content_fits, bottom_aligned, panel_left_of_bar, _skill_bar.get_slot_count(),
	])
	_report("MODE=%s NAME=%s VITAL_VISIBLE=%s ATTRIBUTE_VISIBLE=%s BUILD_VISIBLE=%s CULTIVATION_VISIBLE=%s CULTIVATION=%s COMPACT=%s" % [
		mode, name_label.text, vital_visible, attribute_visible, build_visible, cultivation_visible, cultivation_label.text, _panel.is_compact(),
	])
	_report("MODE=%s BUILD=%s" % [mode, build_label.text.replace("
", " | ")])

	if not dock_inside or not panel_inside or not bar_inside:
		_fail("%s %s：Dock/信息卡/技能栏越出逻辑视口 dock=%s panel=%s bar=%s" % [
			mode, window_size, dock_rect, panel_rect, bar_rect,
		])
	if panel_bar_overlap:
		_fail("%s %s：信息卡与技能栏重叠 panel=%s bar=%s" % [mode, window_size, panel_rect, bar_rect])
	if panel_hud_overlap or bar_hud_overlap:
		_fail("%s %s：左下 Dock 与顶部 HUD 重叠 hud=%s" % [mode, window_size, hud_rect])
	if panel_pause_overlap or bar_pause_overlap:
		_fail("%s %s：左下 Dock 与暂停状态标签重叠 pause=%s" % [mode, window_size, pause_label_rect])
	if not content_fits:
		_fail("%s %s：内容溢出面板 content=%s panel=%s" % [mode, window_size, content_rect, panel_rect])
	if not bottom_aligned:
		_fail("%s %s：技能栏应与信息卡底部对齐 panel_bottom=%s bar_bottom=%s" % [
			mode, window_size, panel_rect.end.y, bar_rect.end.y,
		])
	if not panel_left_of_bar:
		_fail("%s %s：信息卡应位于技能栏左侧 panel_x=%s bar_x=%s" % [
			mode, window_size, panel_rect.position.x, bar_rect.position.x,
		])
	if not vital_visible:
		_fail("%s %s：资源区必须始终可见" % [mode, window_size])
	if name_label.text.is_empty():
		_fail("%s %s：身份区姓名不得为空" % [mode, window_size])

	var expect_full: bool = mode == "PAUSED"
	if _panel.is_compact() == expect_full:
		_fail("%s %s：精简态与暂停态判定错误 COMPACT=%s" % [mode, window_size, _panel.is_compact()])
	if expect_full and not (build_label.text.contains("功法") and build_label.text.contains("武器") and build_label.text.contains("被动")):
		_fail("%s %s：完整模式 Build 区应显示四类槽位，实际 %s" % [mode, window_size, build_label.text.replace("
", " | ")])
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


## 暂停遮罩必须仍绘制在 Dock 之上，否则暂停时信息卡或技能栏会盖住遮罩。
func _check_pause_overlay() -> void:
	_main.call("_set_paused", true)
	for _i: int in 3:
		await process_frame
	var overlay: Control = _main.get_node(PAUSE_OVERLAY_PATH)
	var above: bool = overlay.get_index() > _dock.get_index()
	_report("PAUSE_OVERLAY_VISIBLE=%s DRAWN_ABOVE_DOCK=%s" % [overlay.visible, above])
	if not overlay.visible:
		_fail("暂停时遮罩应可见")
	if not above:
		_fail("暂停遮罩必须排在 Dock 之后绘制（当前 dock_index=%s overlay_index=%s）" % [
			_dock.get_index(), overlay.get_index(),
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
