extends SceneTree

## 生成最小 Build A/B 切换面板的真实窗口布局与交互证据（不能用 --headless）。
## 运行方式：
##   godot --path . --script res://test/tools/capture_build_loadout_panel_evidence.gd
## 截图与文本报告保存到 res://.mcp/godot-runtime/screenshots/（该目录在 .gitignore 中，不入库）。
##
## 为什么必须用真实窗口：--headless 的 dummy 窗口固定为 64x64（见 AGENTS.md §10），
## CanvasLayer 下的控件会按 64x64 视口解析锚点，布局结论完全失真。
##
## 覆盖内容（AGENTS.md §5.4 要求同时验证 16:9 / 16:10 / 窄屏）：
##   1. 三档窗口下 Build 面板是否越出逻辑视口，是否与顶部 HUD / 暂停标签 / 左下 Dock 重叠；
##   2. 面板行文案、按钮尺寸、状态文案在三档分辨率下是否完整可见；
##   3. 战斗中锁定 → 战斗结束后解锁（主场景接线，不是面板自己判断）；
##   4. 首通奖励解锁 Build B 之后，真实鼠标点击按钮才产生装配切换；
##   5. 切换后 SkillBar 同帧跟随，且面板非交互背景不拦截鼠标（悬停命中不是面板本体）。
##
## 因为 Windows 版 Godot 是 GUI 子系统程序，PowerShell 不会回收它的 stdout，
## 所以本脚本除了 print() 之外，还会把同样的证据行写入报告文件。

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"
const BUILD_TEST_1V1_PATH: String = "res://game/world/data/encounters/build_test_1v1.tres"
const OUTPUT_DIR: String = "res://.mcp/godot-runtime/screenshots"
const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/build_loadout_panel_evidence_report.txt"

## AGENTS.md §5.4：新增 UI 必须同时验证 16:9、16:10 和窄屏（800x720 → 逻辑视口 1152x1036）。
const WINDOW_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1152, 720),
	Vector2i(800, 720),
]

const PANEL_PATH: String = "HUD/BuildLoadoutPanel"
const DOCK_PATH: String = "HUD/BottomLeftDock"
const HUD_MARGIN_PATH: String = "HUD/HudMargin"
const PAUSE_LABEL_PATH: String = "HUD/PauseStateLabel"
const SKILL_BAR_PATH: String = "HUD/BottomLeftDock/SkillBar"
## 信息卡 / SkillBar 是本 Increment 的量测主体；遭遇 / 秘境 / 宗门面板由真实流程按状态切换，
## 同时可见会把 Dock 最小宽度撑到 1248 > 1152 逻辑视口（既有 HUD 布局债务），
## 因此与 capture_pawn_info_panel_evidence.gd / capture_sect_panel_evidence.gd 一致，量测前先隔离它们。
const ISOLATED_SIBLING_PANELS: Array[String] = ["EncounterPanel", "DungeonPanel", "SectPanel"]
const APPROX: float = 0.5

var _main: Node2D
var _session: EncounterSession
var _panel: BuildLoadoutPanel
var _bar: SkillBar
var _report_lines: Array[String] = []
var _failures: Array[String] = []


func _initialize() -> void:
	_main = (load(MAIN_SCENE_PATH) as PackedScene).instantiate() as Node2D
	root.add_child(_main)
	for _i: int in 6:
		await process_frame
	_session = _main.get_node("EncounterSession") as EncounterSession
	_panel = _main.get_node(PANEL_PATH) as BuildLoadoutPanel
	_bar = _main.get_node(SKILL_BAR_PATH) as SkillBar
	_hide_sibling_panels()

	await _check_combat_lock_release()
	await _sweep_resolutions()
	await _check_first_clear_unlock_and_click()
	await _check_background_passthrough()

	_write_report()
	print("CAPTURE_DONE FAILURES=", _failures.size())
	quit(1 if not _failures.is_empty() else 0)


## 隐藏非主体面板，让 Dock 只包含信息卡与 SkillBar，量测结果只反映本 Increment 的改动。
func _hide_sibling_panels() -> void:
	for child_name: String in ISOLATED_SIBLING_PANELS:
		var sibling: Control = _main.get_node_or_null(DOCK_PATH + "/" + child_name) as Control
		if sibling != null:
			sibling.visible = false


## 主场景接线：开局战斗进行中面板必须锁定，敌方全灭结算后自动解锁。
func _check_combat_lock_release() -> void:
	_report("COMBAT_LOCKED_AT_START=%s" % _panel.is_switch_locked())
	if not _panel.is_switch_locked():
		_fail("开局战斗进行中时 Build 切换应处于锁定态")
	_wipe_enemies()
	for _i: int in 5:
		await process_frame
	_report("AFTER_CLEAR_STATE=%s SWITCH_LOCKED=%s" % [_session.get_state(), _panel.is_switch_locked()])
	if _panel.is_switch_locked():
		_fail("战斗结束后主场景应解锁 Build 切换")
	# 选中玩家单位：面板与信息卡 / SkillBar 一样以「选中的单位」为展示对象。
	_main.call("_set_selected_pawn", _session.get_player_pawn())
	for _i: int in 3:
		await process_frame
	

## 三档分辨率：面板自身、两行按钮、状态文案都必须在视口内，且不与既有 HUD 主体重叠。
func _sweep_resolutions() -> void:
	for window_size: Vector2i in WINDOW_RESOLUTIONS:
		var applied: bool = await _apply_window_size(window_size)
		for _i: int in 4:
			await process_frame
		var viewport: Rect2 = root.get_visible_rect()
		var panel_rect: Rect2 = _panel.get_global_rect()
		var dock_rect: Rect2 = (_main.get_node(DOCK_PATH) as Control).get_global_rect()
		var hud_rect: Rect2 = (_main.get_node(HUD_MARGIN_PATH) as Control).get_global_rect()
		var pause_rect: Rect2 = (_main.get_node(PAUSE_LABEL_PATH) as Control).get_global_rect()
		var buttons: Array[Button] = [
			_panel.get_preset_button(BuildLoadoutPanel.PRESET_A_ID),
			_panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID),
		]
		var buttons_inside: bool = true
		for button: Button in buttons:
			if not panel_rect.encloses(button.get_global_rect()):
				buttons_inside = false
		var dock_overlap: bool = panel_rect.intersects(dock_rect)
		var hud_overlap: bool = panel_rect.intersects(hud_rect)
		var pause_overlap: bool = panel_rect.intersects(pause_rect)
		_report("RESOLUTION=%s APPLIED=%s VIEWPORT=%s PANEL=%s DOCK=%s BUTTONS_INSIDE=%s PANEL_INSIDE=%s DOCK_OVERLAP=%s HUD_OVERLAP=%s PAUSE_OVERLAP=%s" % [
			window_size, applied, viewport, panel_rect, dock_rect, buttons_inside, viewport.encloses(panel_rect),
			dock_overlap, hud_overlap, pause_overlap,
		])
		_report("RESOLUTION=%s TITLE_A=%s MARKER_A=%s TITLE_B=%s MARKER_B=%s STATUS=%s BUTTON_SIZES=%s" % [
			window_size,
			_panel.get_preset_title_text(BuildLoadoutPanel.PRESET_A_ID),
			_panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_A_ID),
			_panel.get_preset_title_text(BuildLoadoutPanel.PRESET_B_ID),
			_panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID),
			_panel.get_status_text(),
			[buttons[0].size, buttons[1].size],
		])
		if not applied:
			_fail("%s：窗口尺寸未能生效" % window_size)
		if not viewport.encloses(panel_rect):
			_fail("%s：Build 面板越出逻辑视口 PANEL=%s VIEWPORT=%s" % [window_size, panel_rect, viewport])
		if not buttons_inside:
			_fail("%s：切换按钮未完整落在面板矩形内" % window_size)
		if dock_overlap:
			_fail("%s：Build 面板与左下 Dock 重叠 PANEL=%s DOCK=%s" % [window_size, panel_rect, dock_rect])
		if hud_overlap:
			_fail("%s：Build 面板与顶部 HUD 重叠 PANEL=%s HUD=%s" % [window_size, panel_rect, hud_rect])
		if pause_overlap:
			_fail("%s：Build 面板与暂停状态标签重叠 PANEL=%s PAUSE=%s" % [window_size, panel_rect, pause_rect])
		if _panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID) != "未解锁：定身术":
			_fail("%s：定身术未解锁时 Build B 应显示未解锁，实际 %s" % [window_size, _panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)])
		if buttons[1].disabled != true:
			_fail("%s：定身术未解锁时 Build B 按钮应禁用" % window_size)
		await _capture("build_loadout_panel_locked_%dx%d" % [window_size.x, window_size.y])


## 首通奖励解锁 → 真实鼠标点击 → 装配 / 技能栏 / 面板标记同步变化。
func _check_first_clear_unlock_and_click() -> void:
	var applied: bool = await _apply_window_size(WINDOW_RESOLUTIONS[0])
	if not applied:
		_fail("首通验证：窗口尺寸未能回到 %s" % WINDOW_RESOLUTIONS[0])
	assert_true_or_fail(_session.begin(load(BUILD_TEST_1V1_PATH) as EncounterDefinition), "试剑·1v1 应能开局")
	for _i: int in 5:
		await process_frame
	_report("IN_COMBAT_SWITCH_LOCKED=%s B_MARKER=%s" % [_panel.is_switch_locked(), _panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID)])
	if not _panel.is_switch_locked():
		_fail("战斗中应保持 Build 切换锁定")
	_wipe_enemies()
	for _i: int in 5:
		await process_frame
	var player: Pawn = _session.get_player_pawn()
	_report("AFTER_1V1_STATE=%s LEARNED_BINDING=%s SWITCH_LOCKED=%s B_MARKER=%s" % [
		_session.get_state(), player.has_learned_active_skill(&"binding_spell"), _panel.is_switch_locked(),
		_panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID),
	])
	if not player.has_learned_active_skill(&"binding_spell"):
		_fail("试剑·1v1 首通应解锁定身术")
	if _panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID) != "可切换":
		_fail("解锁定身术后 Build B 应显示可切换，实际 %s" % _panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID))
	if _equipped_ids(player) != ["sword_strike", "guard_true_qi"]:
		_fail("首通奖励不得自动装配，实际 %s" % [_equipped_ids(player)])

	var button_b: Button = _panel.get_preset_button(BuildLoadoutPanel.PRESET_B_ID)
	var clicked: bool = await _click_control(button_b)
	for _i: int in 3:
		await process_frame
	var slots: Array[SkillSlot] = _bar.get_slots()
	var slot_ids: Array = []
	for slot: SkillSlot in slots:
		var skill: ActiveSkillDefinition = slot.get_skill()
		slot_ids.append(String(skill.id) if skill != null else "<null>")
	_report("CLICK_B=%s EQUIPPED=%s SLOT_IDS=%s ACTIVE_PRESET=%s MARKER_B=%s STATUS=%s" % [
		clicked, _equipped_ids(player), slot_ids, _panel.get_active_preset_id(),
		_panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID), _panel.get_status_text(),
	])
	if _equipped_ids(player) != ["sword_strike", "binding_spell"]:
		_fail("真实点击 Build B 后装配应为御剑斩 + 定身术，实际 %s" % [_equipped_ids(player)])
	if slot_ids != ["sword_strike", "binding_spell"]:
		_fail("切换后 SkillBar 应同帧跟随，实际 %s" % [slot_ids])
	if _panel.get_preset_marker_text(BuildLoadoutPanel.PRESET_B_ID) != "当前 Build":
		_fail("切换后面板应把 Build B 标记为当前 Build")
	await _capture("build_loadout_panel_switched_%dx%d" % [WINDOW_RESOLUTIONS[0].x, WINDOW_RESOLUTIONS[0].y])


## 非交互背景不拦截战场点击：面板空白处悬停不得命中面板本体或标签。
func _check_background_passthrough() -> void:
	var panel_rect: Rect2 = _panel.get_global_rect()
	# 面板内、按钮外的一点（面板左下角内侧 12px）
	var blank_point: Vector2 = Vector2(panel_rect.position.x + 24.0, panel_rect.end.y - 10.0)
	await _warp_mouse(blank_point)
	var hovered: Control = root.gui_get_hovered_control()
	var hovered_path: String = "null" if hovered == null else String(hovered.get_path())
	_report("PASSTHROUGH_POINT=%s HOVERED=%s PANEL_MOUSE_FILTER=%d" % [blank_point, hovered_path, _panel.mouse_filter])
	if hovered != null and (hovered == _panel or hovered.is_ancestor_of(_panel) or _panel.is_ancestor_of(hovered)):
		_fail("面板非交互背景拦截了鼠标：悬停命中 %s" % hovered_path)
	var button_center: Vector2 = _panel.get_preset_button(BuildLoadoutPanel.PRESET_A_ID).get_global_rect().get_center()
	await _warp_mouse(button_center)
	var button_hovered: Control = root.gui_get_hovered_control()
	_report("BUTTON_HOVER_POINT=%s HOVERED=%s" % [button_center, "null" if button_hovered == null else String(button_hovered.get_path())])
	if button_hovered == null:
		_fail("面板按钮应能被鼠标命中（当前悬停为空）")


func _wipe_enemies() -> void:
	for enemy: Pawn in _session.get_enemy_units():
		if is_instance_valid(enemy):
			enemy.take_damage(enemy.data.defense + enemy.data.max_health + enemy.data.max_shield + 50.0)


func _equipped_ids(pawn: Pawn) -> Array:
	var ids: Array = []
	for skill: ActiveSkillDefinition in pawn.get_equipped_active_skills():
		ids.append(String(skill.id) if skill != null else "<null>")
	return ids


## 真实鼠标点击：把光标移到控件中心并注入一次左键按下 / 抬起（不走任何信号捷径）。
func _click_control(control: Control) -> bool:
	var center: Vector2 = control.get_global_rect().get_center()
	await _warp_mouse(center)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = center
	Input.parse_input_event(press)
	await process_frame
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = center
	Input.parse_input_event(release)
	for _i: int in 3:
		await process_frame
	return true


func _warp_mouse(position: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	for _i: int in 2:
		await process_frame


func assert_true_or_fail(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


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
	file.store_line("build_loadout_panel_evidence_report %s (local time)" % Time.get_datetime_string_from_system(false, true))
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
