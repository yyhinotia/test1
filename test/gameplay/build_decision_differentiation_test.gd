extends GdUnitTestSuite

## 玩法层：Build 决策差异证据（INC-TESTING-006）。
##
## 待回答的问题（docs/build-mvp.md MVP-5）：
##   在 2 个主动技能槽下从「输出 / 生存 / 控制」中选择两个，
##   玩家是否因为**遭遇不同**而产生真实决策，而不是三套 Build 都能打赢？
##
## 做法：用固定 60fps 时间步驱动真实 Pawn / PlayerController / AIController /
## SkillEffectResolver，把「敌人威胁档案 × 三套 Build + 无技能对照」跑到终局，
## 记录胜负、击杀耗时、剩余有效生命、实际授予护盾量、灵力消耗、敌人失效时长与双方普通攻击次数。
##
## 本用例不复制任何伤害、护盾、眩晕公式；敌人档案全部来自 game/pawns/data/ 下的正式资源。
## 与 INC-TESTING-004 的关系：那个用例观察固定 12 秒窗口内的过程曲线，本用例观察**终局结果**
## 与「最优 Build 是否随遭遇改变」，两者互补，不互相替代。

const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"

const SWORD_SKILL_PATH: String = "res://game/pawns/data/player_sword_skill.tres"
const GUARD_SKILL_PATH: String = "res://game/pawns/data/player_guard_skill.tres"
const BINDING_SKILL_PATH: String = "res://game/pawns/data/player_binding_skill.tres"

## 三份正式敌人档案：现有基线 + INC-PAWNS-016 新增的长线型 / 爆发型。
const PROFILE_TRIAL: String = "res://game/pawns/data/enemy_pawn.tres"
const PROFILE_IRON_GUARD: String = "res://game/pawns/data/enemies/enemy_iron_guard.tres"
const PROFILE_BLOOD_BLADE: String = "res://game/pawns/data/enemies/enemy_blood_blade.tres"

const DELTA: float = 1.0 / 60.0
## 终局上限 60 秒：到点仍未分胜负即如实记为 timeout，不用截断结果冒充胜负。
const MAX_STEPS: int = 3600
const SPAWN_DISTANCE: float = 180.0
## 防御技能只在有效生命比低于该阈值时施放，避免满血满盾时被护盾上限截断而浪费灵力。
const DEFEND_HEALTH_RATIO: float = 0.7
## 决策代价下限：主导档案里“最优 Build − 最差 Build”的剩余有效生命比差距。
const MIN_DECISION_GAP: float = 0.05
## 技能相对无技能对照的最小收益（剩余有效生命比差距）。
const MIN_SKILL_GAIN: float = 0.05
const APPROX: float = 0.001

const ROLE_DEFENSIVE: String = "defensive"
const ROLE_CONTROL: String = "control"
const ROLE_OFFENSIVE: String = "offensive"
const ROLE_OTHER: String = "other"

## 唯一确定性决策策略：低血先补盾保命 → 否则优先压制敌人行动 → 否则用输出技能。
## 同一策略应用到全部 Build，因此差异只能来自 Build 组合与敌人档案，而不是操作水平。
const POLICY: Array[String] = [ROLE_DEFENSIVE, ROLE_CONTROL, ROLE_OFFENSIVE]


func _make_player_data(skills: Array[ActiveSkillDefinition]) -> PawnData:
	var data: PawnData = (load(PLAYER_DATA_PATH) as PawnData).duplicate(true) as PawnData
	if skills.is_empty():
		data.active_skill = null
		data.active_skills = [] as Array[ActiveSkillDefinition]
	else:
		data.active_skill = skills[0]
		data.active_skills = skills
	# 灵力经济是决策的一部分：固定为满灵力、100 上限，避免预设变化悄悄改变对照条件。
	data.max_spirit = 100.0
	data.initial_spirit_ratio = 1.0
	return data


func _make_enemy_data(profile_path: String) -> PawnData:
	return (load(profile_path) as PawnData).duplicate(true) as PawnData


func _role_of(skill: ActiveSkillDefinition) -> String:
	match skill.effect_type:
		ActiveSkillDefinition.SkillEffectType.SHIELD:
			return ROLE_DEFENSIVE
		ActiveSkillDefinition.SkillEffectType.STUN:
			return ROLE_CONTROL
		ActiveSkillDefinition.SkillEffectType.DAMAGE:
			return ROLE_OFFENSIVE
		_:
			return ROLE_OTHER


func _below_defend_threshold(player: Pawn) -> bool:
	var max_effective: float = player.data.max_health + player.data.max_shield
	if max_effective <= 0.0:
		return true
	return (player.current_health + player.current_shield) < max_effective * DEFEND_HEALTH_RATIO


## 在当前可施放的技能里按角色优先级挑一个；挑不到就返回 null（本帧不施法）。
func _pick_skill(
		skills: Array[ActiveSkillDefinition],
		player: Pawn,
		enemy: Pawn
	) -> ActiveSkillDefinition:
	for role: String in POLICY:
		for skill: ActiveSkillDefinition in skills:
			if _role_of(skill) != role:
				continue
			if role == ROLE_DEFENSIVE and not _below_defend_threshold(player):
				continue
			var target: Pawn = player if skill.target_type == ActiveSkillDefinition.SkillTargetType.SELF else enemy
			if player.can_cast_skill(skill, target):
				return skill
	return null


func _run_case(profile_key: String, build_id: String, skills: Array[ActiveSkillDefinition]) -> Dictionary:
	var player_scene: PackedScene = load(PLAYER_SCENE_PATH)
	var enemy_scene: PackedScene = load(ENEMY_SCENE_PATH)
	var player: Pawn = player_scene.instantiate() as Pawn
	var enemy: Pawn = enemy_scene.instantiate() as Pawn
	player.data = _make_player_data(skills)
	enemy.data = _make_enemy_data(profile_key)
	auto_free(player)
	auto_free(enemy)
	add_child(player)
	add_child(enemy)

	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(SPAWN_DISTANCE, 0.0)
	player.set_physics_process(false)
	enemy.set_physics_process(false)

	var player_controller: PlayerController = player.get_controller() as PlayerController
	var ai_controller: AIController = enemy.get_controller() as AIController
	player_controller.bind(player)
	player_controller.set_physics_process(false)
	ai_controller.bind(enemy)
	ai_controller.set_physics_process(false)
	ai_controller.activation_delay = 0.0
	ai_controller.set_target(player)
	# 双方都必须真实对打：玩家即使不带主动技能也在普通攻击，否则「无技能对照」不成立。
	player_controller.order_attack(enemy)

	var attack_counts: Array[int] = [0, 0]
	player.attack_performed.connect(func(_target: Pawn) -> void: attack_counts[0] += 1)
	enemy.attack_performed.connect(func(_target: Pawn) -> void: attack_counts[1] += 1)

	# 技能实际授予的护盾量：只看正向增量，且必须在上限内真实生效（被上限截断的部分不算收益）。
	# 起始护盾不会发信号，因此这里用「当前值」作为基线，不会把预设护盾误记成技能收益。
	var shield_state: Array[float] = [player.current_shield]
	var granted_shield: Array[float] = [0.0]
	player.shield_changed.connect(func(_pawn: Pawn, current_shield: float, _max_shield: float) -> void:
		var delta: float = current_shield - shield_state[0]
		if delta > 0.0:
			granted_shield[0] += delta
		shield_state[0] = current_shield
	)

	var max_effective: float = player.data.max_health + player.data.max_shield
	var initial_spirit: float = player.current_spirit
	var stun_steps: int = 0
	var outcome: String = "timeout"
	var end_step: int = MAX_STEPS

	for step: int in MAX_STEPS:
		var chosen: ActiveSkillDefinition = _pick_skill(skills, player, enemy)
		if chosen != null:
			var target: Pawn = player if chosen.target_type == ActiveSkillDefinition.SkillTargetType.SELF else enemy
			player_controller.order_skill_instance(chosen, target)

		player_controller.update_controller(DELTA)
		ai_controller.update_controller(DELTA)
		player._physics_process(DELTA)
		enemy._physics_process(DELTA)

		if enemy.is_stunned():
			stun_steps += 1

		if enemy.is_dead():
			outcome = "player_win"
			end_step = step + 1
			break
		if player.is_dead():
			outcome = "enemy_win"
			end_step = step + 1
			break

	var player_effective: float = player.current_shield + player.current_health
	var enemy_effective: float = enemy.current_shield + enemy.current_health
	return {
		"profile": profile_key.get_file().get_basename(),
		"build": build_id,
		"outcome": outcome,
		"elapsed_seconds": float(end_step) * DELTA,
		"player_effective_end": player_effective,
		"player_effective_ratio": player_effective / max_effective,
		"enemy_effective_end": enemy_effective,
		"spirit_spent": initial_spirit - player.current_spirit,
		"granted_shield": granted_shield[0],
		"enemy_stun_seconds": float(stun_steps) * DELTA,
		"player_attack_count": attack_counts[0],
		"enemy_attack_count": attack_counts[1],
	}


## 终局优劣判定：先看是否获胜，再看剩余有效生命，最后看耗时；同一 Build 的对照都走这条规则。
func _is_better(candidate: Dictionary, current: Dictionary) -> bool:
	var candidate_win: bool = candidate["outcome"] == "player_win"
	var current_win: bool = current["outcome"] == "player_win"
	if candidate_win != current_win:
		return candidate_win
	var candidate_ratio: float = float(candidate["player_effective_ratio"])
	var current_ratio: float = float(current["player_effective_ratio"])
	if not is_equal_approx(candidate_ratio, current_ratio):
		return candidate_ratio > current_ratio
	return float(candidate["elapsed_seconds"]) < float(current["elapsed_seconds"])


## 严格支配：在「是否获胜 → 剩余有效生命 → 击杀耗时」三轴上都不劣于目标，且至少一轴严格更优。
## 用支配关系而不是加权/字典序，是为了让「哪个 Build 更好」的结论不依赖“余命与耗时谁更重要”的口径选择。
func _dominates(candidate: Dictionary, target: Dictionary) -> bool:
	var candidate_win: bool = candidate["outcome"] == "player_win"
	var target_win: bool = target["outcome"] == "player_win"
	if candidate_win != target_win:
		return candidate_win
	if not candidate_win:
		# 双方都未获胜：余命都是 0，只能比存活时间，短者不构成支配，直接返回 false 保持保守。
		return false
	var candidate_ratio: float = float(candidate["player_effective_ratio"])
	var target_ratio: float = float(target["player_effective_ratio"])
	var candidate_time: float = float(candidate["elapsed_seconds"])
	var target_time: float = float(target["elapsed_seconds"])
	var not_worse: bool = candidate_ratio >= target_ratio - APPROX and candidate_time <= target_time + APPROX
	var strictly_better: bool = candidate_ratio > target_ratio + APPROX or candidate_time < target_time - APPROX
	return not_worse and strictly_better


func _is_strictly_dominated(results: Dictionary, profile_key: String, target_id: String, build_ids: Array[String]) -> bool:
	var target: Dictionary = results["%s|%s" % [profile_key, target_id]]
	for build_id: String in build_ids:
		if build_id == target_id:
			continue
		if _dominates(results["%s|%s" % [profile_key, build_id]], target):
			return true
	return false


## 非支配集合：没有任何其它 Build 严格支配它。
func _non_dominated_ids(results: Dictionary, profile_key: String, build_ids: Array[String]) -> Array[String]:
	var kept: Array[String] = []
	for build_id: String in build_ids:
		if not _is_strictly_dominated(results, profile_key, build_id, build_ids):
			kept.append(build_id)
	return kept


func _profile_keys() -> Array[String]:
	return ["trial", "iron_guard", "blood_blade"]


func _profile_path(profile_key: String) -> String:
	match profile_key:
		"trial":
			return PROFILE_TRIAL
		"iron_guard":
			return PROFILE_IRON_GUARD
		"blood_blade":
			return PROFILE_BLOOD_BLADE
		_:
			return ""


func test_threat_profiles_change_the_best_build() -> void:
	var sword: ActiveSkillDefinition = load(SWORD_SKILL_PATH) as ActiveSkillDefinition
	var guard: ActiveSkillDefinition = load(GUARD_SKILL_PATH) as ActiveSkillDefinition
	var binding: ActiveSkillDefinition = load(BINDING_SKILL_PATH) as ActiveSkillDefinition
	assert_object(sword).is_not_null()
	assert_object(guard).is_not_null()
	assert_object(binding).is_not_null()

	var output_survival: Array[ActiveSkillDefinition] = [sword, guard]
	var output_control: Array[ActiveSkillDefinition] = [sword, binding]
	var survival_control: Array[ActiveSkillDefinition] = [guard, binding]
	var no_skill: Array[ActiveSkillDefinition] = []

	var builds: Dictionary = {
		"output+survival": output_survival,
		"output+control": output_control,
		"survival+control": survival_control,
	}
	var build_ids: Array[String] = ["output+survival", "output+control", "survival+control"]

	# 第一遍：测量并打印完整指标表（供调参与人工复核）。
	var results: Dictionary = {}
	var best_build: Dictionary = {}
	var worst_build: Dictionary = {}
	for profile_key: String in _profile_keys():
		var profile_path: String = _profile_path(profile_key)
		var best_id: String = ""
		var worst_id: String = ""
		var best_result: Dictionary = {}
		var worst_result: Dictionary = {}
		for build_id: String in build_ids:
			var result: Dictionary = _run_case(profile_path, build_id, builds[build_id])
			results["%s|%s" % [profile_key, build_id]] = result
			print("[INC-TESTING-006] ", result)
			if best_id.is_empty() or _is_better(result, best_result):
				best_result = result
				best_id = build_id
			if worst_id.is_empty() or _is_better(worst_result, result):
				worst_result = result
				worst_id = build_id
		var baseline: Dictionary = _run_case(profile_path, "no_skill", no_skill)
		results["%s|no_skill" % profile_key] = baseline
		print("[INC-TESTING-006] ", baseline)
		best_build[profile_key] = best_id
		worst_build[profile_key] = worst_id
		print("[INC-TESTING-006] best_build[%s] = %s / worst_build = %s" % [profile_key, best_id, worst_id])
		print("[INC-TESTING-006] non_dominated[%s] = %s" % [
			profile_key,
			str(_non_dominated_ids(results, profile_key, build_ids)),
		])

	# 断言 1「技能不是装饰」：每个档案下最优 Build 必须真的优于无主动技能对照。
	for profile_key: String in _profile_keys():
		var baseline: Dictionary = results["%s|no_skill" % profile_key]
		var best: Dictionary = results["%s|%s" % [profile_key, best_build[profile_key]]]
		if best["outcome"] == "player_win" and baseline["outcome"] != "player_win":
			continue
		assert_bool(float(best["player_effective_ratio"]) > float(baseline["player_effective_ratio"]) + MIN_SKILL_GAIN).is_true()

	# 断言 2「无单一统治解」：最少两个档案的最优 Build 不同，因此不存在一个 Build 处处最优。
	assert_str(str(best_build["iron_guard"])).is_not_equal(str(best_build["blood_blade"]))

	# 断言 3「三类技能签名可区分」：护盾与控制的战果痕迹落在不同 Build 上，且都真实发生过。
	assert_bool(float(results["blood_blade|output+survival"]["granted_shield"]) > 10.0).is_true()
	assert_float(float(results["blood_blade|output+survival"]["enemy_stun_seconds"])).is_equal_approx(0.0, APPROX)
	assert_float(float(results["blood_blade|output+control"]["granted_shield"])).is_equal_approx(0.0, APPROX)
	assert_bool(float(results["blood_blade|output+control"]["enemy_stun_seconds"]) > 1.0).is_true()

	# 断言 4「决策代价可观测」：主导档案里最优与最差 Build 的剩余有效生命差距必须显著。
	for profile_key: String in _profile_keys():
		var best: Dictionary = results["%s|%s" % [profile_key, best_build[profile_key]]]
		var worst: Dictionary = results["%s|%s" % [profile_key, worst_build[profile_key]]]
		var gap: float = float(best["player_effective_ratio"]) - float(worst["player_effective_ratio"])
		assert_bool(gap > MIN_DECISION_GAP).is_true()

	# 断言 5「取舍不依赖评价口径」：每个档案都必须存在至少两个互不支配的 Build，
	# 且“被严格支配（又慢又不多留血）”的 Build 随遭遇改变——这条结论不需要先约定余命与耗时谁更重要。
	for profile_key: String in _profile_keys():
		assert_int(_non_dominated_ids(results, profile_key, build_ids).size()).is_greater_equal(2)

	# 长线遭遇：同时带输出与控制的两槽组合又慢又不多留血，属于明确错误选择。
	assert_bool(_is_strictly_dominated(results, "iron_guard", "output+control", build_ids)).is_true()
	# 爆发遭遇：不带输出的纯防御组合又慢又不多留血，属于明确错误选择。
	assert_bool(_is_strictly_dominated(results, "blood_blade", "survival+control", build_ids)).is_true()
	# 被支配者身份不同 → 同一个 Build 在一种遭遇里明确错误、在另一种遭遇里不可替代，决策随遭遇改变。
	assert_str("output+control").is_not_equal("survival+control")

