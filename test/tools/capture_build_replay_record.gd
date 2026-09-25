extends SceneTree

## 生成 Build Replay 实验记录（INC-TESTING-011）。
## 运行方式：
##   godot --path . --script res://test/tools/capture_build_replay_record.gd
## 产出：build_replay_record.json / build_replay_record.md，落 res://.mcp/godot-runtime/screenshots/（不入库）。
##
## 记录分两半，边界不可混：
##   ① 机制事实（本脚本自动填充）：Round 1 / Round 2 的 CombatEvent 序列、危险技能结算方式、
##      承伤合计与战斗时长，以及首通奖励与 Build 切换的面板裁决结果；
##   ② 人工部分（必须由玩家填写）：Q1~Q4 原话、Gate A~E 结论与归档标签。
## 本脚本只填 ①，不得代填 ②，也不得输出任何玩法结论；
## 判据来源：docs/build-gameplay-validation.md §6（事件序列）/ §8（Gate）/ §9（Failure）。
##
## 脚本化 Replay 与真实人工 Replay 的关系：Round 1 / Round 2 的客观判据可以用脚本复现（本脚本），
## 但「玩家是否主动重构 Build、为什么」只能由人工轮回答——两者结果冲突时以人工轮为准并记入已知问题。

const OUTPUT_DIR: String = "res://.mcp/godot-runtime/screenshots"
const JSON_PATH: String = OUTPUT_DIR + "/build_replay_record.json"
const MARKDOWN_PATH: String = OUTPUT_DIR + "/build_replay_record.md"
## 人工字段的统一占位：任何自动步骤都不得把它替换成结论。
const PENDING: String = "待人工"

var _main: Node2D
var _record: Dictionary = {}
var _failures: Array[String] = []


func _initialize() -> void:
	_main = BuildReplayDriver.instantiate_main_without_dungeon(root)
	for _i: int in 3:
		await process_frame
	_record = await BuildReplayDriver.run_scripted_replay(_main)
	_check_mechanical_facts()
	_ensure_output_dir()
	_write_json()
	_write_markdown()
	_print_summary()
	print("BUILD_REPLAY_CAPTURE_DONE FAILURES=", _failures.size())
	_main.free()
	quit(1 if not _failures.is_empty() else 0)


## 机制事实自检：这些事实不成立时记录无效（Gate 0），必须报错而不是写一份好看的记录。
func _check_mechanical_facts() -> void:
	var round_one: Dictionary = _round(BuildReplayDriver.ROUND_1_LABEL)
	var round_two: Dictionary = _round(BuildReplayDriver.ROUND_2_LABEL)
	var first_clear: Dictionary = _record.get("first_clear", {}) as Dictionary
	var build_switch: Dictionary = _record.get("build_switch", {}) as Dictionary
	if not (round_one.get("danger_window_opened", false) as bool):
		_fail("Round 1 危险窗口未打开")
	if String(round_one.get("dangerous_skill_resolution", "")) != "hit":
		_fail("Round 1 无控制时应被危险技能命中")
	if not (round_two.get("danger_window_opened", false) as bool):
		_fail("Round 2 危险窗口未打开")
	if String(round_two.get("dangerous_skill_resolution", "")) != "cancelled_by_stun":
		_fail("Round 2 定身应取消危险技能并阻止伤害结算")
	if not (build_switch.get("accepted", false) as bool):
		_fail("Build B 未能通过面板切换：%s" % String(build_switch.get("reason", "")))
	if (first_clear.get("auto_equipped_by_reward", true) as bool):
		_fail("首通奖励不得自动装配技能")
	if not ((first_clear.get("known_after", []) as Array).has("binding_spell")):
		_fail("首通应把定身术标记为已掌握")


func _round(label: String) -> Dictionary:
	return _record.get(label, {}) as Dictionary


func _fail(message: String) -> void:
	_failures.append(message)
	print("REPLAY_FAILURE ", message)


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_json() -> void:
	var payload: Dictionary = _record.duplicate(true)
	payload["captured_at"] = Time.get_datetime_string_from_system(false)
	payload["godot_version"] = Engine.get_version_info().get("string", "")
	payload["human_section"] = {
		"Q1_most_annoying_problem": PENDING,
		"Q2_why_switch_or_not": PENDING,
		"Q3_what_changed_in_round_two": PENDING,
		"Q4_would_replay_without_new_ability": PENDING,
		"ReplayIntent": PENDING,
		"BuildChange": PENDING,
		"Reason": PENDING,
		"PerceivedImpact": PENDING,
		"gate_0": PENDING,
		"gate_a": PENDING,
		"gate_b": PENDING,
		"gate_c": PENDING,
		"gate_d": PENDING,
		"gate_e": PENDING,
	}
	var file: FileAccess = FileAccess.open(JSON_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload, "  "))
	file.close()



func _write_markdown() -> void:
	var lines: Array[String] = []
	lines.append("# build_replay_record — Build Replay 实验记录")
	lines.append("")
	lines.append("> Increment：`INC-TESTING-011`（父：`INC-CROSS-019`）")
	lines.append("> 判据来源：`docs/build-gameplay-validation.md` §6（事件序列）/ §8（Gate）/ §9（Failure）")
	lines.append("> 采集时间：%s　Godot：%s" % [
		Time.get_datetime_string_from_system(false),
		String(Engine.get_version_info().get("string", "")),
	])
	lines.append("> 记录分两半：① 机制事实（本脚本自动填充）② 人工部分（玩家填写，脚本不得代填）")
	lines.append("")
	lines.append("## 1. 机制事实（自动填充）")
	lines.append("")
	_append_round_section(lines, "Round 1 — Build A（不干预）", BuildReplayDriver.ROUND_1_LABEL)
	_append_round_section(lines, "Round 2 — Build B（定身打断）", BuildReplayDriver.ROUND_2_LABEL)
	_append_first_clear_section(lines)
	_append_switch_section(lines)
	_append_comparison_section(lines)
	lines.append("## 2. 人工部分（" + PENDING + "，禁止脚本代填）")
	lines.append("")
	lines.append("### 2.1 实验步骤（按顺序执行，不要跳过）")
	lines.append("")
	lines.append("1. 用 Build A（御剑斩 + 护体真气）打完 1v1，感受危险窗口。")
	lines.append("2. 首通拿到定身术（只有这一个奖励，没有灵石 / 装备 / 强化）。")
	lines.append("3. 自己决定要不要换 Build——系统不会替你换，也不会提示你换。")
	lines.append("4. 用当前 Build 重打同一个 1v1。")
	lines.append("")
	lines.append("可用入口：`tests/scenario_build_replay.tscn`（`& $env:GODOT_BIN --path . res://tests/scenario_build_replay.tscn`）")
	lines.append("")
	lines.append("### 2.2 三问（Q1~Q3 为硬门，Q4 非门控；逐字保留玩家原话）")
	lines.append("")
	lines.append("| 问题 | 玩家原话 |")
	lines.append("|---|---|")
	lines.append("| Q1 第一轮战斗中，你觉得最麻烦的问题是什么？ | " + PENDING + " |")
	lines.append("| Q2 拿到定身术后，你为什么选择 / 不选择换 Build？ | " + PENDING + " |")
	lines.append("| Q3 第二次战斗和第一次相比，你具体改变了什么？ | " + PENDING + " |")
	lines.append("| Q4（非门控）如果这次没有拿到新能力，你还会主动再打一轮吗？ | " + PENDING + " |")
	lines.append("")
	lines.append("### 2.3 归档标签（只做归档，不能替代原话）")
	lines.append("")
	lines.append("| 标签 | 取值 |")
	lines.append("|---|---|")
	lines.append("| ReplayIntent（yes / no） | " + PENDING + " |")
	lines.append("| BuildChange（none / A→B / other） | " + PENDING + " |")
	lines.append("| Reason（tactical / numerical / curiosity / completion / other） | " + PENDING + " |")
	lines.append("| PerceivedImpact（none / low / medium / high） | " + PENDING + " |")
	lines.append("")
	lines.append("### 2.4 Gate 结论（Gate 0 → A / B → C / D / E 顺序不可颠倒）")
	lines.append("")
	lines.append("| Gate | 通过条件 | 结论 |")
	lines.append("|---|---|---|")
	lines.append("| Gate 0 | 技术成立：本轮 §1 机制事实全部成立（未成立则人工结论无效） | " + PENDING + " |")
	lines.append("| Gate A | 玩家能描述第一轮的具体战斗问题（不是「挺难的」） | " + PENDING + " |")
	lines.append("| Gate B | 玩家能理解定身术与第一轮问题的关联 | " + PENDING + " |")
	lines.append("| Gate C | 玩家在没有强制要求的情况下主动选择 Build B | " + PENDING + " |")
	lines.append("| Gate D | 第二轮主动用定身解决第一轮的问题（原话 + 事件佐证 `skill_cancelled`） | " + PENDING + " |")
	lines.append("| Gate E | 玩家能解释为什么这样改 Build | " + PENDING + " |")
	lines.append("")
	lines.append("Failure 1~5 是否命中（命中即禁止继续扩 Build 系统，必须回到战斗核心）：" + PENDING)
	lines.append("")
	lines.append("## 3. 采集元信息")
	lines.append("")
	lines.append("- 脚本：`test/tools/capture_build_replay_record.gd`（驱动层 `test/tools/build_replay_driver.gd`）")
	lines.append("- 记录文件：`.mcp/godot-runtime/screenshots/build_replay_record.json` / `.md`（`.mcp/` 不入库，需重跑脚本再生成）")
	lines.append("- 机制层自检失败项：%s" % ("无" if _failures.is_empty() else ", ".join(_failures)))
	lines.append("")
	var file: FileAccess = FileAccess.open(MARKDOWN_PATH, FileAccess.WRITE)
	file.store_string("\n".join(lines))
	file.close()


func _append_round_section(lines: Array[String], title: String, label: String) -> void:
	var round_record: Dictionary = _round(label)
	lines.append("### " + title)
	lines.append("")
	lines.append("| 项目 | 值 |")
	lines.append("|---|---|")
	lines.append("| 遭遇 | %s |" % String(_record.get("encounter", "<none>")))
	lines.append("| 危险窗口打开 | %s |" % str(round_record.get("danger_window_opened", false)))
	lines.append("| 危险技能结算 | %s |" % String(round_record.get("dangerous_skill_resolution", "")))
	lines.append("| 危险窗口应对序列 | %s |" % _sequence_text(round_record.get("danger_window_sequence", []) as Array))
	lines.append("| 完整事件序列 | %s |" % _sequence_text(round_record.get("event_sequence", []) as Array))
	lines.append("| 承伤合计（生命 / 护盾） | %s / %s |" % [
		str(round_record.get("damage_taken", {}).get("health", 0.0)),
		str(round_record.get("damage_taken", {}).get("shield", 0.0)),
	])
	lines.append("| 战斗时长（事件时钟） | %.2fs |" % (round_record.get("duration_seconds", 0.0) as float))
	lines.append("| 本回合装配 | %s |" % _sequence_text(round_record.get("equipped_active_skills", []) as Array))
	lines.append("| 本回合技能栏 | %s |" % _sequence_text(round_record.get("skill_bar", []) as Array))
	lines.append("| 定身施放 / 命中后敌人处于定身 | %s / %s |" % [
		str(round_record.get("binding_cast", false)),
		str(round_record.get("enemy_stunned_after_cast", false)),
	])
	lines.append("")


func _append_first_clear_section(lines: Array[String]) -> void:
	var first_clear: Dictionary = _record.get("first_clear", {}) as Dictionary
	lines.append("### 首通奖励（只解锁，不装配）")
	lines.append("")
	lines.append("| 项目 | 值 |")
	lines.append("|---|---|")
	lines.append("| 结算结果 | %s (%s) |" % [String(first_clear.get("outcome_label", "")), str(first_clear.get("outcome", -1))])
	lines.append("| 已掌握（首通前 → 后） | %s → %s |" % [
		_list_text(first_clear.get("known_before", []) as Array),
		_list_text(first_clear.get("known_after", []) as Array),
	])
	lines.append("| 已装配（首通前 → 后） | %s → %s |" % [
		_list_text(first_clear.get("equipped_before", []) as Array),
		_list_text(first_clear.get("equipped_after_first_clear", []) as Array),
	])
	lines.append("| 是否被奖励自动装配 | %s |" % str(first_clear.get("auto_equipped_by_reward", false)))
	lines.append("")


func _append_switch_section(lines: Array[String]) -> void:
	var build_switch: Dictionary = _record.get("build_switch", {}) as Dictionary
	lines.append("### Build 切换（生产面板裁决，脚本不代玩家决定）")
	lines.append("")
	lines.append("| 项目 | 值 |")
	lines.append("|---|---|")
	lines.append("| 切换前是否锁定 | %s |" % str(build_switch.get("switch_locked_before", false)))
	lines.append("| 切换前 Build B 是否可切换 | %s |" % str(build_switch.get("available_before", false)))
	lines.append("| 面板是否接受 | %s |" % str(build_switch.get("accepted", false)))
	lines.append("| 面板给出的原因 | %s |" % String(build_switch.get("reason", "")))
	lines.append("| 切换后装配 | %s |" % _sequence_text(build_switch.get("equipped_after", []) as Array))
	lines.append("| 切换后技能栏 | %s |" % _sequence_text(_record.get("skill_bar_after_switch", []) as Array))
	lines.append("")


func _append_comparison_section(lines: Array[String]) -> void:
	var comparison: Dictionary = _record.get("objective_comparison", {}) as Dictionary
	lines.append("### 客观对照（Failure 4 判据：两轮应对序列相同即命中）")
	lines.append("")
	lines.append("| 项目 | Round 1 | Round 2 |")
	lines.append("|---|---|---|")
	lines.append("| 危险技能结算 | %s | %s |" % [
		String(comparison.get("round_1_resolution", "")),
		String(comparison.get("round_2_resolution", "")),
	])
	lines.append("| 应对序列 | %s | %s |" % [
		_sequence_text(comparison.get("round_1_window_sequence", []) as Array),
		_sequence_text(comparison.get("round_2_window_sequence", []) as Array),
	])
	lines.append("")
	lines.append("- 两轮序列是否相同：%s" % str(comparison.get("same_window_sequence", true)))
	lines.append("- Failure 4 是否命中（自动判据）：%s" % str(comparison.get("failure_4_triggered", true)))
	lines.append("- 注意：第二轮不要求更快或更少掉血，只要求采用了不同的解决方案；时长与承伤优劣不得写成通过条件。")
	lines.append("")


## 技能列表用逗号分隔，避免和「前 → 后」的箭头语义混在一起。
func _list_text(values: Array) -> String:
	var parts2: Array[String] = []
	for value: Variant in values:
		parts2.append(String(value))
	return ", ".join(parts2) if not parts2.is_empty() else "<空>"


func _sequence_text(values: Array) -> String:
	var parts: Array[String] = []
	for value: Variant in values:
		parts.append(String(value))
	return " → ".join(parts) if not parts.is_empty() else "<空>"


func _print_summary() -> void:
	var round_one: Dictionary = _round(BuildReplayDriver.ROUND_1_LABEL)
	var round_two: Dictionary = _round(BuildReplayDriver.ROUND_2_LABEL)
	print("ROUND_1 resolution=", round_one.get("dangerous_skill_resolution", "?"),
		" sequence=", _sequence_text(round_one.get("danger_window_sequence", []) as Array),
		" damage=", round_one.get("damage_taken", {}),
		" seconds=", round_one.get("duration_seconds", 0.0))
	print("ROUND_2 resolution=", round_two.get("dangerous_skill_resolution", "?"),
		" sequence=", _sequence_text(round_two.get("danger_window_sequence", []) as Array),
		" damage=", round_two.get("damage_taken", {}),
		" seconds=", round_two.get("duration_seconds", 0.0))
	print("FIRST_CLEAR ", _record.get("first_clear", {}))
	print("BUILD_SWITCH ", _record.get("build_switch", {}))
	print("OBJECTIVE ", _record.get("objective_comparison", {}))
	print("REPORT_WRITTEN ", MARKDOWN_PATH)
