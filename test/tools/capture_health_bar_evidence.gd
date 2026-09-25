extends SceneTree

## 生成血条显示策略的视觉证据（需要真实渲染，不能用 --headless）。
## 运行方式：
##   godot --path . --script res://test/tools/capture_health_bar_evidence.gd
## 截图与文本报告保存到 res://.mcp/godot-runtime/screenshots/（该目录在 .gitignore 中，不入库）。
##
## 覆盖内容：
##   1. 16:9（默认 1152x648）下的显示/隐藏/暂停时序截图与运行态计时；
##   2. AGENTS.md §5.4 要求的多分辨率布局实测：16:9、16:10、窄屏（800x720）。
##
## 因为 Windows 版 Godot 是 GUI 子系统程序，PowerShell 不会回收它的 stdout，
## 所以本脚本除了 print() 之外，还会把同样的证据行写入健康检查报告文件。

const OUTPUT_DIR: String = "res://.mcp/godot-runtime/screenshots"
const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/health_bar_evidence_report.txt"

## AGENTS.md §5.4：新增 UI 必须同时验证 16:9、16:10 和窄屏表现。
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1152, 720),
	Vector2i(800, 720),
]

var _main: Node2D
var _player: Pawn
var _enemy: Pawn
var _report_lines: Array[String] = []

func _initialize() -> void:
	var main_scene: PackedScene = load("res://game/main/main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)
	_player = _main.get_node("Pawns/PlayerPawn")
	_enemy = _main.get_node("Pawns/EnemyPawn")

	for _i: int in 10:
		await process_frame
	await _capture("health_bar_01_idle")

	_player.take_damage(_player.data.defense + 45.0)
	for _i: int in 2:
		await process_frame
	await _capture("health_bar_02_player_hit")

	_enemy.take_damage(_enemy.data.defense + 30.0)
	for _i: int in 2:
		await process_frame
	await _capture("health_bar_03_both_hit")

	# 把敌人移开，避免它在后续计时验证中继续攻击玩家
	_enemy.global_position = Vector2(-2000.0, -2000.0)
	var hide_started: int = Time.get_ticks_msec()
	while (_bars_visible()) and Time.get_ticks_msec() - hide_started < 6000:
		await process_frame
	var hide_elapsed: int = Time.get_ticks_msec() - hide_started
	await _capture("health_bar_04_hidden_after_delay")

	_main.call("_set_paused", true)
	_player.take_damage(_player.data.defense + 20.0)
	for _i: int in 2:
		await process_frame
	await _capture("health_bar_05_paused_still_visible")
	var paused_snapshot: bool = _player.health_bar.visible

	_main.call("_set_paused", false)
	var resume_started: int = Time.get_ticks_msec()
	while _player.health_bar.visible and Time.get_ticks_msec() - resume_started < 6000:
		await process_frame
	await _capture("health_bar_06_hidden_after_resume")

	_report("HIDE_ELAPSED_MS=%d" % hide_elapsed)
	_report("PAUSED_BAR_VISIBLE=%s" % str(paused_snapshot))
	_report("RESUME_HIDE_ELAPSED_MS=%d" % (Time.get_ticks_msec() - resume_started))

	await _sweep_resolutions()

	_write_report()
	print("CAPTURE_DONE")
	quit(0)

## 多分辨率布局实测：读取逻辑视口、血条全局矩形与 Pawn 位置，确认血条始终居中于 Pawn 头顶且在视口内。
func _sweep_resolutions() -> void:
	for size: Vector2i in RESOLUTIONS:
		var applied: bool = await _apply_window_size(size)
		if not applied:
			_report("RESIZE_FAILED target=%s actual=%s" % [size, DisplayServer.window_get_size()])

		# 让血条可见并刷新到最新数值，便于读取与截图。
		_player.take_damage(_player.data.defense + 1.0)
		for _i: int in 2:
			await process_frame

		var window_size: Vector2i = DisplayServer.window_get_size()
		var viewport_rect: Rect2 = root.get_visible_rect()
		var bar_rect: Rect2 = _player.health_bar.get_global_rect()
		var pawn_position: Vector2 = _player.global_position
		var bar_center: Vector2 = bar_rect.get_center()
		var centered: bool = absf(bar_center.x - pawn_position.x) <= 0.5
		var above_head: bool = bar_rect.end.y <= pawn_position.y
		var inside_viewport: bool = viewport_rect.encloses(bar_rect)
		_report(
			"RES %dx%d WINDOW=%s RESIZE_OK=%s DPI_SCALE=%.2f VIEWPORT=%s BAR_RECT=%s BAR_CENTER=%s PAWN=%s CENTERED=%s ABOVE_HEAD=%s INSIDE_VIEWPORT=%s BAR_VISIBLE=%s" % [
				size.x, size.y, window_size, applied, DisplayServer.screen_get_scale(), viewport_rect, bar_rect, bar_center, pawn_position,
				centered, above_head, inside_viewport, _player.health_bar.visible,
			]
		)
		await _capture("health_bar_res_%dx%d" % [size.x, size.y])

		_player.health_bar.hide_now()
		for _i: int in 1:
			await process_frame

## 申请窗口尺寸并等待其真正生效；Windows 下偶发丢帧/被合成器合并，因此带重试。
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

func _bars_visible() -> bool:
	return _player.health_bar.visible or _enemy.health_bar.visible

## 同时打印并登记一行证据；Windows GUI 子系统的 Godot 收不回 stdout，因此报告文件才是权威证据。
func _report(line: String) -> void:
	print(line)
	_report_lines.append(line)

func _write_report() -> void:
	var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		print("REPORT_WRITE_FAILED ", FileAccess.get_open_error())
		return
	file.store_line("health_bar_evidence_report %s (local time)" % Time.get_datetime_string_from_system(false, true))
	for line: String in _report_lines:
		file.store_line(line)
	file.close()
	print("REPORT_WRITTEN ", REPORT_PATH)

func _capture(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = "%s/%s.png" % [OUTPUT_DIR, shot_name]
	var err: int = image.save_png(path)
	print("CAPTURE ", path, " err=", err, " size=", image.get_size(), " player_bar=", _player.health_bar.visible, " enemy_bar=", _enemy.health_bar.visible)