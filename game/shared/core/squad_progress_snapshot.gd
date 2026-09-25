class_name SquadProgressSnapshot
extends RefCounted

## 队伍运行时进度快照（INC-PAWNS-020）。
##
## 记录「成员 id → 运行时进度」（强化等级 / 领悟功法 / 运行时境界 / 境界内修为），
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
	}


## 把一个进度写回目标单位：先恢复运行时境界，再写入该境界内修为；
## 强化沿用 Pawn 的封顶规则逐级应用，功法依赖 Pawn 自身去重。空进度安全降级。
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
