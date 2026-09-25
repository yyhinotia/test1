class_name SquadProgressSnapshot
extends RefCounted

## 队伍运行时进度快照（INC-PAWNS-020）。
##
## 记录「成员 id → 运行时进度」（强化等级 / 领悟功法 / 运行时境界 / 境界内修为 / 已解锁与已装配的主动技能），
## 与资源快照分开：资源是否延续由调用方决定，运行时进度属于同一代修士的身份。
## 写回按成员 id 匹配，缺成员跳过，绝不按数组下标互相覆盖。

var _members: Dictionary = {}


static func capture(units: Array[Pawn]) -> SquadProgressSnapshot:
	var snapshot: SquadProgressSnapshot = SquadProgressSnapshot.new()
	for unit: Pawn in units:
		var member_id: StringName = SquadResourceSnapshot.member_id_of(unit)
		if member_id == &"":
			continue
		snapshot._members[member_id] = capture_progress(unit)
	return snapshot


## 按成员 id 写回；返回成功写回的成员数量。
func apply_to(units: Array[Pawn]) -> int:
	var applied: int = 0
	for unit: Pawn in units:
		var member_id: StringName = SquadResourceSnapshot.member_id_of(unit)
		if member_id == &"" or not _members.has(member_id):
			continue
		var progress: Variant = _members[member_id]
		if not (progress is Dictionary):
			continue
		apply_progress(unit, progress)
		applied += 1
	return applied


func has_member(member_id: StringName) -> bool:
	return _members.has(member_id)


func get_member_progress(member_id: StringName) -> Dictionary:
	var progress: Variant = _members.get(member_id)
	if progress is Dictionary:
		return progress as Dictionary
	return {}


func get_member_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in _members.keys():
		ids.append(StringName(key))
	return ids


func get_member_count() -> int:
	return _members.size()


func is_empty() -> bool:
	return _members.is_empty()


## 单个单位的运行时进度；空单位返回空字典。
## 这是进度采集的唯一实现，EncounterSession 的单人路径也委托到这里，避免两份规则漂移。
static func capture_progress(pawn: Pawn) -> Dictionary:
	if pawn == null or not is_instance_valid(pawn):
		return {}
	return {
		"forge_level": pawn.get_forge_level(),
		"techniques": pawn.get_learned_techniques(),
		"realm": pawn.get_realm(),
		"cultivation_exp": float(pawn.get_cultivation_snapshot().get("current_exp", 0.0)),
		# 主动技能的解锁与装配同样属于本代修士的身份（INC-WORLD-007）：
		# 换局 / 重开后必须延续，否则「拿到新技能 → 换 Build → 再战」在机制上不成立。
		"learned_active_skills": pawn.get_learned_active_skills(),
		"has_explicit_active_skill_loadout": pawn.has_explicit_active_skill_loadout(),
		"equipped_active_skills": pawn.get_equipped_active_skills(),
	}


## 把一个进度写回目标单位：先恢复运行时境界，再写入该境界内修为；
## 强化沿用 Pawn 的封顶规则逐级应用，功法 / 主动技能依赖 Pawn 自身去重；显式装配最后写回。空进度安全降级。
static func apply_progress(pawn: Pawn, progress: Dictionary) -> void:
	if pawn == null or not is_instance_valid(pawn) or progress.is_empty():
		return
	for _level: int in range(maxi(int(progress.get("forge_level", 0)), 0)):
		pawn.strengthen_weapon()
	var techniques: Variant = progress.get("techniques", [])
	if techniques is Array:
		for technique: Variant in techniques:
			if technique is TechniqueDefinition:
				pawn.learn_technique(technique)

	var cultivation_exp: float = float(progress.get("cultivation_exp", 0.0))
	var carried_realm: Variant = progress.get("realm")
	if carried_realm is RealmDefinition:
		# 境界恢复失败时保持新单位的静态起始境界；不要把一个境界的修为写进另一个境界。
		pawn.restore_realm(carried_realm as RealmDefinition, cultivation_exp)
	else:
		pawn.set_cultivation_exp(cultivation_exp, &"encounter_carry")

	# 主动技能解锁与装配写回（INC-WORLD-007）必须排在境界之后：
	# 装配裁决依赖当前境界的主动技能槽容量，先写装配会被静态起始境界的容量误判。
	var learned: Variant = progress.get("learned_active_skills", [])
	if learned is Array:
		for skill: Variant in learned:
			if skill is ActiveSkillDefinition:
				pawn.learn_active_skill(skill)

	if bool(progress.get("has_explicit_active_skill_loadout", false)):
		var equipped: Array[ActiveSkillDefinition] = []
		var equipped_raw: Variant = progress.get("equipped_active_skills", [])
		if equipped_raw is Array:
			for skill: Variant in equipped_raw:
				if skill is ActiveSkillDefinition:
					equipped.append(skill)
		# 写回失败（例如容量或已掌握校验不通过）时不伪造结果：保持新单位的静态预设，由调用方读取实际装配。
		pawn.set_active_skill_loadout(equipped)
