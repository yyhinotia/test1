class_name DungeonRoom
extends Resource

## 秘境单间房的静态定义（INC-WORLD-003）。
##
## 房间只回答「这一间打谁、清空后给多少灵石、它是不是终局 Boss」，
## 不持有运行时状态、不负责推进、不做胜负判定。

@export var display_name: String = "房间"
## 本间的遭遇定义；遭遇再引用正式敌人档案，房间层不复制敌人数值。
@export var encounter: EncounterDefinition
## 清空本间后累加的灵石奖励；MVP 阶段只有一种可累加货币。
@export var reward_spirit_stones: int = 0
## 是否为秘境终局房；一个合法秘境恰好有一个 Boss 房并在最后一间。
@export var is_boss: bool = false
## 本房间显式声明考查的战斗问题，取值为 `PawnData.ProblemTag`（INC-WORLD-008）。
## 空数组表示该房间不参与问题编排（旧秘境保持原行为）；非空时必须与敌人阵容实际提出的问题一致，
## 由 `matches_encounter_problems()` 与测试共同保证「声明即事实」，而不是只写在描述文案里。
@export var problem_tags: Array[int] = []


## 房间可直接进入：名称 / 遭遇 / 非负奖励三者齐备。
func is_configured() -> bool:
	if display_name.strip_edges().is_empty():
		return false
	if encounter == null or not encounter.is_configured():
		return false
	return reward_spirit_stones >= 0


## 对手展示名；未配置遭遇时返回空串，由 UI 决定占位文案。
func get_enemy_display_name() -> String:
	if encounter == null:
		return ""
	return encounter.get_enemy_display_name()


## 奖励的安全读取：负值按 0 处理，避免调用方拿到非法收益。
func get_reward() -> int:
	return maxi(reward_spirit_stones, 0)


## 是否显式声明了本房间考查的问题型；空声明表示该房间不参与问题编排。
func has_declared_problems() -> bool:
	return not get_problem_tags().is_empty()


## 声明的问题型：过滤 NONE 与越界值、去重、升序，返回值可直接参与集合比较。
func get_problem_tags() -> Array[int]:
	var result: Array[int] = []
	for value: int in problem_tags:
		if value <= PawnData.ProblemTag.NONE or value > PawnData.ProblemTag.SUMMON_REINFORCEMENT:
			continue
		if not result.has(value):
			result.append(value)
	result.sort()
	return result


## 敌人阵容实际提出的问题型：成员 `problem_tag` 的并集（过滤 NONE / 越界值），去重后升序。
## 这是「事实」的一侧，与 `get_problem_tags()` 的「声明」一侧共同支持一致性校验。
func get_encounter_problem_tags() -> Array[int]:
	var result: Array[int] = []
	if encounter == null:
		return result
	for member: PawnData in encounter.get_enemy_members():
		if member == null:
			continue
		var value: int = member.problem_tag
		if value <= PawnData.ProblemTag.NONE or value > PawnData.ProblemTag.SUMMON_REINFORCEMENT:
			continue
		if not result.has(value):
			result.append(value)
	result.sort()
	return result


## 「声明 = 事实」的唯一判据：两侧集合逐项相等。两边都已排序，因此顺序不影响结论。
func matches_encounter_problems() -> bool:
	return get_problem_tags() == get_encounter_problem_tags()


## 本房间的问题型是否已成为可断言的数据契约：声明非空且与敌人阵容一致。
func is_problem_configured() -> bool:
	return has_declared_problems() and matches_encounter_problems()


## 本房间问题的中文标签；未声明时返回空数组。文案复用 `PawnData` 的静态映射，不在此复制第二份表。
func get_problem_labels() -> Array[String]:
	var labels: Array[String] = []
	for value: int in get_problem_tags():
		labels.append(PawnData.get_problem_tag_label_for(value))
	return labels


## 本房间要求的玩家技能价值轴（由问题型映射）；未声明时返回空数组。
func get_required_value_axes() -> Array[StringName]:
	var axes: Array[StringName] = []
	for value: int in get_problem_tags():
		axes.append(PawnData.get_skill_value_axis_for(value))
	return axes
