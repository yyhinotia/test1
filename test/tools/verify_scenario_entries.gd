extends SceneTree

## tests/ 场景入口体检（INC-TESTING-012）：一次性加载全部入口，核对前置条件与「可重复打开」。
## 运行方式：
##   godot --path . --script res://test/tools/verify_scenario_entries.gd
## 报告写入 res://.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt（该目录不入库）。
##
## 这里只检查「入口能不能把游戏摆到声明的状态」，不做任何玩法结论：
## 每个入口加载两次，第二次用于证明重复打开不重复解锁技能、不残留上一局的活动单位。

const REPORT_PATH: String = "res://.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt"

const EXPECTED_ENTRIES: Array[Dictionary] = [
		{"scene": "res://tests/scenario_build_test_1v1.tscn", "id": "build_test_1v1", "encounter": "build_test_1v1", "enemies": 1, "binding": false},
		{"scene": "res://tests/scenario_build_test_1v2.tscn", "id": "build_test_1v2", "encounter": "build_test_1v2", "enemies": 2, "binding": true},
		{"scene": "res://tests/scenario_build_test_1v3.tscn", "id": "build_test_1v3", "encounter": "build_test_1v3", "enemies": 3, "binding": true},
		{"scene": "res://tests/scenario_build_loadout_switch.tscn", "id": "build_loadout_switch", "encounter": "build_test_1v1", "enemies": 1, "binding": true},
		{"scene": "res://tests/scenario_first_clear_reward.tscn", "id": "first_clear_reward", "encounter": "build_test_1v1", "enemies": 1, "binding": false},
]

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
		_report("ENTRY=%s ID=%s ENCOUNTER=%s STATE=%s PLAYERS=%d ENEMIES=%d LEARNED=%s EQUIPPED=%s WINDOW_TITLE=%s" % [
				scene_path, report.get("id", ""), report.get("encounter", ""), report.get("state", -1),
				report.get("player_count", 0), report.get("enemy_count", 0),
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
		var learned: Array = report.get("learned_active_skills", [])
		var expects_binding: bool = bool(expected["binding"])
		if learned.has("binding_spell") != expects_binding:
				_fail("%s：定身术解锁状态应为 %s，实际 %s" % [scene_path, expects_binding, learned])
		if not String(root.title).contains(String(expected["id"])):
				_fail("%s：窗口标题应包含入口 id，实际 %s" % [scene_path, root.title])

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
		_report("REPEAT_ENTRY=%s ENEMIES=%s LEARNED=%s" % [
				scene_path, second_report.get("enemy_count", 0), second_report.get("learned_active_skills", []),
		])
		if int(second_report.get("enemy_count", 0)) != int(expected["enemies"]):
				_fail("%s：重复打开后敌人数应不变" % scene_path)
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
