extends SceneTree

## tests/ 场景入口体检（INC-TESTING-012）：一次性加载全部入口，核对前置条件与「可重复打开」。
## 运行方式：
##   godot --path . --script res://test/tools/verify_scenario_entries.gd
## 报告写入 res://.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt（该目录不入库）。
##
## 这里只检查「入口能不能把游戏摆到声明的状态」，不做任何玩法结论：
## 每个入口加载两次，第二次用于证明重复打开不重复解锁技能、不残留上一局的活动单位。

const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt"

## 敌方名单（INC-TESTING-017）：三档遭遇必须能靠运行时名单区分，而不是只靠人数。
const EXPECTED_ENTRIES: Array[Dictionary] = [
	{"scene": "res://tests/scenario_build_test_1v1.tscn", "id": "build_test_1v1", "encounter": "build_test_1v1", "enemies": 1, "enemy_names": ["镇狱影傀"], "binding": false},
	{"scene": "res://tests/scenario_build_test_1v2.tscn", "id": "build_test_1v2", "encounter": "build_test_1v2", "enemies": 2, "enemy_names": ["赤拳战修", "灵弓修者"], "binding": true},
	{"scene": "res://tests/scenario_build_test_1v3.tscn", "id": "build_test_1v3", "encounter": "build_test_1v3", "enemies": 3, "enemy_names": ["赤拳战修", "灵弓修者", "镇狱影傀"], "binding": true},
	{"scene": "res://tests/scenario_build_loadout_switch.tscn", "id": "build_loadout_switch", "encounter": "build_test_1v1", "enemies": 1, "enemy_names": ["镇狱影傀"], "binding": true},
	{"scene": "res://tests/scenario_first_clear_reward.tscn", "id": "first_clear_reward", "encounter": "build_test_1v1", "enemies": 1, "enemy_names": ["镇狱影傀"], "binding": false},
	{"scene": "res://tests/scenario_build_replay.tscn", "id": "build_replay", "encounter": "build_test_1v1", "enemies": 1, "enemy_names": ["镇狱影傀"], "binding": false},
]

## 测试呈现（INC-TESTING-016）：入口必须隐藏的非 Build 菜单，以及必须保留的 Build 验收 UI。
const HIDDEN_IN_BUILD_ENTRY: Array[String] = [
	"HUD/BottomLeftDock/EncounterPanel/Buttons",
	"HUD/BottomLeftDock/DungeonPanel",
	"HUD/BottomLeftDock/SectPanel",
]
const VISIBLE_IN_BUILD_ENTRY: Array[String] = [
	"HUD/BuildLoadoutPanel",
	"HUD/BottomLeftDock/SkillBar",
	"HUD/BottomLeftDock/PawnInfoPanel",
	"HUD/BottomLeftDock/EncounterPanel/RestartButton",
]

## 测试自证（INC-TESTING-017）：跑错入口（F5 = main.tscn）时看不到横幅，因此横幅本身就是「跑对了」的凭证。
const BANNER_LABEL_PATH: String = "ScenarioBannerLayer/ScenarioBanner/BannerLabel"
const NAMEPLATE_NAME: String = "ScenarioNameplate"
const ENEMY_PLATE_PREFIX: String = "敌 · "
const PLAYER_PLATE_PREFIX: String = "玩家 · "

var _report_lines: Array[String] = []
var _failures: Array[String] = []


func _initialize() -> void:
	for expected: Dictionary in EXPECTED_ENTRIES:
		await _check_entry(expected)
	_write_report()
	print("SCENARIO_ENTRY_CHECK_DONE FAILURES=", _failures.size())
	quit(1 if not _failures.is_empty() else 0)


## 单个入口：加载 → 核对声明状态 → 释放 → 再加载一次核对重复性。
func _check_entry(expected: Dictionary) -> void:
	var scene_path: String = expected["scene"]
	var first: Node2D = await _spawn_entry(scene_path)
	if first == null:
		_fail("%s：入口无法实例化" % scene_path)
		return
	var report: Dictionary = first.call("get_scenario_report")
	_report("ENTRY=%s ID=%s ENCOUNTER=%s STATE=%s PLAYERS=%d ENEMIES=%d ENEMY_NAMES=%s LEARNED=%s EQUIPPED=%s WINDOW_TITLE=%s" % [
		scene_path, report.get("id", ""), report.get("encounter", ""), report.get("state", -1),
		report.get("player_count", 0), report.get("enemy_count", 0), report.get("enemy_names", []),
		report.get("learned_active_skills", []), report.get("equipped_active_skills", []), root.title,
	])
	if report.get("id", "") != expected["id"]:
		_fail("%s：scenario_id 应为 %s，实际 %s" % [scene_path, expected["id"], report.get("id", "")])
	if report.get("encounter", "") != expected["encounter"]:
		_fail("%s：遭遇应为 %s，实际 %s" % [scene_path, expected["encounter"], report.get("encounter", "")])
	if int(report.get("enemy_count", 0)) != int(expected["enemies"]):
		_fail("%s：敌人数应为 %d，实际 %s" % [scene_path, expected["enemies"], report.get("enemy_count", 0)])
	if int(report.get("player_count", 0)) != 1:
		_fail("%s：玩家单位应为 1，实际 %s" % [scene_path, report.get("player_count", 0)])
	if int(report.get("state", -1)) != EncounterSession.State.RUNNING:
		_fail("%s：开局状态应为 RUNNING" % scene_path)
	# 名单比对不看顺序：这里要证明的是「三档遭遇不是同一批人」，不是刷怪顺序。
	var actual_names: Array = report.get("enemy_names", [])
	if not _same_names(actual_names, expected["enemy_names"]):
		_fail("%s：敌方名单应为 %s，实际 %s" % [scene_path, expected["enemy_names"], actual_names])
	if actual_names.size() != int(report.get("enemy_count", 0)):
		_fail("%s：敌方名单 %s 与敌人数 %s 不一致" % [scene_path, actual_names, report.get("enemy_count", 0)])
	var learned: Array = report.get("learned_active_skills", [])
	var expects_binding: bool = bool(expected["binding"])
	if learned.has("binding_spell") != expects_binding:
		_fail("%s：定身术解锁状态应为 %s，实际 %s" % [scene_path, expects_binding, learned])
	if not String(root.title).contains(String(expected["id"])):
		_fail("%s：窗口标题应包含入口 id，实际 %s" % [scene_path, root.title])

	# 测试入口聚焦 Build（INC-TESTING-016）：非 Build 菜单必须隐藏，Build 验收 UI 必须保留。
	_check_build_focus(scene_path, first)
	_report("BUILD_FOCUS=%s HIDDEN=%d VISIBLE=%d" % [scene_path, HIDDEN_IN_BUILD_ENTRY.size(), VISIBLE_IN_BUILD_ENTRY.size()])

	# 测试自证（INC-TESTING-017）：横幅写明入口与遭遇，名牌逐一对上敌方名单。
	_check_self_identification(scene_path, first, expected)

	# 释放后不得残留：入口（含它创建的 Pawn）必须是主窗口唯一子节点。
	first.free()
	await process_frame
	if root.get_child_count() != 0:
		_fail("%s：释放后仍残留 %s 个节点" % [scene_path, root.get_child_count()])

	var second: Node2D = await _spawn_entry(scene_path)
	if second == null:
		_fail("%s：第二次加载失败" % scene_path)
		return
	var second_report: Dictionary = second.call("get_scenario_report")
	_report("REPEAT_ENTRY=%s ENEMIES=%s ENEMY_NAMES=%s LEARNED=%s PLATES=%d" % [
		scene_path, second_report.get("enemy_count", 0), second_report.get("enemy_names", []),
		second_report.get("learned_active_skills", []), _count_nameplates(second, ENEMY_PLATE_PREFIX),
	])
	if int(second_report.get("enemy_count", 0)) != int(expected["enemies"]):
		_fail("%s：重复打开后敌人数应不变" % scene_path)
	if not _same_names(second_report.get("enemy_names", []), expected["enemy_names"]):
		_fail("%s：重复打开后敌方名单应不变" % scene_path)
	# 重开会把整批 Pawn 换成新实例：名牌必须跟着重建，否则第二局就分不清敌我。
	if _count_nameplates(second, ENEMY_PLATE_PREFIX) != int(expected["enemies"]):
		_fail("%s：重复开局后敌方名牌数量应仍为 %d" % [scene_path, expected["enemies"]])
	# 静态预设（御剑斩 + 护体真气）本来就掌握；重复打开只允许出现同样的集合，
	# 也就是「定身术不会被重复解锁，也不会因为重开而丢失」。
	var expected_learned: Array = ["sword_strike", "guard_true_qi"]
	if expects_binding:
		expected_learned.append("binding_spell")
	var repeated_learned: Array = second_report.get("learned_active_skills", [])
	if repeated_learned != expected_learned:
		_fail("%s：重复打开后已掌握技能应为 %s，实际 %s" % [scene_path, expected_learned, repeated_learned])
	second.free()
	await process_frame


## 测试入口聚焦 Build（INC-TESTING-016）：只断言可见性，不评价布局与玩法。
func _check_build_focus(scene_path: String, entry: Node) -> void:
	var main: Node = entry.get_node_or_null("Main")
	if main == null:
		_fail("%s：找不到主场景节点 Main" % scene_path)
		return
	for path: String in HIDDEN_IN_BUILD_ENTRY:
		var hidden: CanvasItem = main.get_node_or_null(path) as CanvasItem
		if hidden == null:
			_fail("%s：缺少非 Build 菜单节点 %s" % [scene_path, path])
		elif hidden.visible:
			_fail("%s：非 Build 菜单 %s 应隐藏" % [scene_path, path])
	for path: String in VISIBLE_IN_BUILD_ENTRY:
		var shown: CanvasItem = main.get_node_or_null(path) as CanvasItem
		if shown == null:
			_fail("%s：缺少 Build 验收 UI %s" % [scene_path, path])
		elif not shown.visible:
			_fail("%s：Build 验收 UI %s 不应隐藏" % [scene_path, path])


## 测试自证（INC-TESTING-017）：横幅是「跑对了入口」的凭证，名牌是「哪一档遭遇」的凭证。
## 两者都是入口在运行时建的节点，因此必须用 owned=false 找（运行时节点没有 owner）。
func _check_self_identification(scene_path: String, entry: Node, expected: Dictionary) -> void:
	var banner: Label = entry.get_node_or_null(BANNER_LABEL_PATH) as Label
	var banner_text: String = "<none>"
	if banner == null:
		_fail("%s：缺少测试横幅 %s" % [scene_path, BANNER_LABEL_PATH])
	else:
		banner_text = banner.text.replace("\n", " | ")
		if not banner.text.contains(scene_path.get_file()):
			_fail("%s：横幅未写明入口文件 %s，实际 %s" % [scene_path, scene_path.get_file(), banner_text])
		if not banner.text.contains(String(expected["encounter"])):
			_fail("%s：横幅未写明遭遇 id %s，实际 %s" % [scene_path, expected["encounter"], banner_text])
		for enemy_name: String in expected["enemy_names"]:
			if not banner.text.contains(enemy_name):
				_fail("%s：横幅未列出敌方 %s，实际 %s" % [scene_path, enemy_name, banner_text])
	var enemy_plates: int = _count_nameplates(entry, ENEMY_PLATE_PREFIX)
	var player_plates: int = _count_nameplates(entry, PLAYER_PLATE_PREFIX)
	if enemy_plates != int(expected["enemies"]):
		_fail("%s：敌方名牌应为 %d 个，实际 %d" % [scene_path, expected["enemies"], enemy_plates])
	if player_plates != 1:
		_fail("%s：玩家名牌应为 1 个，实际 %d" % [scene_path, player_plates])
	_report("SELF_ID=%s BANNER=%s ENEMY_PLATES=%d PLAYER_PLATES=%d" % [
		scene_path, banner_text, enemy_plates, player_plates,
	])


func _count_nameplates(entry: Node, prefix: String) -> int:
	var count: int = 0
	for node: Node in entry.find_children(NAMEPLATE_NAME, "Label", true, false):
		var plate: Label = node as Label
		if plate != null and plate.text.begins_with(prefix):
			count += 1
	return count


## 名单比对不看顺序：1v3 的刷怪顺序不是本 Increment 的验收对象。
func _same_names(actual: Array, expected: Array) -> bool:
	var left: Array = actual.duplicate()
	var right: Array = expected.duplicate()
	left.sort()
	right.sort()
	return left == right


func _spawn_entry(scene_path: String) -> Node2D:
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return null
	var entry: Node2D = scene.instantiate() as Node2D
	if entry == null:
		return null
	root.add_child(entry)
	# 入口内部会实例化主场景并起一局遭遇，等它把状态摆完再读报告。
	for _i: int in 8:
		await process_frame
	return entry


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
	file.store_line("tests_scenario_entries_report %s (local time)" % Time.get_datetime_string_from_system(false, true))
	file.store_line("GODOT=%s" % Engine.get_version_info().get("string", "unknown"))
	for line: String in _report_lines:
		file.store_line(line)
	file.store_line("FAILURES=%d" % _failures.size())
	file.close()
	print("REPORT_WRITTEN ", REPORT_PATH)
