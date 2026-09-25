extends SceneTree

## 自建 headless 验证：选中 HUD 按 Pawn 是否配置灵力决定显示灵力行。
## 运行方式：
##   godot --headless --path . --script res://test/headless/hud_spirit_display_test.gd

const MAIN_SCENE_PATH: String = "res://game/main/main.tscn"

var _failures: Array[String] = []
var _check_count: int = 0

func _initialize() -> void:
	await process_frame
	var scene: PackedScene = load(MAIN_SCENE_PATH)
	var main: Node2D = scene.instantiate()
	root.add_child(main)
	await process_frame

	var player: Pawn = main.get_node("Pawns/PlayerPawn")
	var enemy: Pawn = main.get_node("Pawns/EnemyPawn")
	var selected_label: Label = main.get_node("HUD/HudMargin/HudPanel/HudContent/SelectedLabel")

	main.call("_set_selected_pawn", player)
	_check("灵力：100 / 100" in selected_label.text, "选中玩家时应显示满灵力行，实际 %s" % selected_label.text)
	_check("HP：120 / 120" in selected_label.text, "灵力显示不得改变生命行")
	_check("护盾：40 / 40" in selected_label.text, "灵力显示不得改变护盾行")

	_check(player.try_spend_spirit(30.0), "玩家应能消耗灵力")
	_check("灵力：70 / 100" in selected_label.text, "灵力变化后选中 HUD 应立即刷新，实际 %s" % selected_label.text)

	main.call("_set_selected_pawn", enemy)
	_check("灵力：" not in selected_label.text, "未配置灵力的敌人不应显示灵力行，实际 %s" % selected_label.text)
	_check("HP：180 / 180" in selected_label.text, "敌人仍应显示自身生命行")

	main.call("_set_selected_pawn", null)
	_check(selected_label.text == "未选中单位", "取消选中后应恢复未选中文本")
	_report()

func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)

func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("HUD_SPIRIT_DISPLAY_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)
