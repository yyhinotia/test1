class_name SquadResourceSnapshot
extends RefCounted

## 队伍资源快照（INC-PAWNS-020）。
##
## 只记录「成员 id → 该成员的资源快照」，不持有 Pawn 引用、不依赖队伍顺序。
## 写回时按成员 id 匹配目标单位：目标队伍没有这个 id 就跳过，
## 绝不允许按数组下标把 A 的损耗写进 B。单人旧路径继续使用 PawnResourceSnapshot。

var _members: Dictionary = {}


## 采集一组单位的资源快照；空单位、无档案、id 为空的成员一律跳过。
static func capture(units: Array[Pawn]) -> SquadResourceSnapshot:
	var snapshot: SquadResourceSnapshot = SquadResourceSnapshot.new()
	for unit: Pawn in units:
		var member_id: StringName = member_id_of(unit)
		if member_id == &"":
			continue
		snapshot._members[member_id] = PawnResourceSnapshot.capture(unit)
	return snapshot


## 按成员 id 写回；返回成功写回的成员数量。缺失成员与空快照都安全跳过。
func apply_to(units: Array[Pawn]) -> int:
	var applied: int = 0
	for unit: Pawn in units:
		var member_id: StringName = member_id_of(unit)
		if member_id == &"" or not _members.has(member_id):
			continue
		var member_snapshot: PawnResourceSnapshot = get_member_snapshot(member_id)
		if member_snapshot == null:
			continue
		member_snapshot.apply_to(unit)
		applied += 1
	return applied


func has_member(member_id: StringName) -> bool:
	return _members.has(member_id)


func get_member_snapshot(member_id: StringName) -> PawnResourceSnapshot:
	return _members.get(member_id) as PawnResourceSnapshot


func get_member_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in _members.keys():
		ids.append(StringName(key))
	return ids


func get_member_count() -> int:
	return _members.size()


func is_empty() -> bool:
	return _members.is_empty()


## 单位身份：以 PawnData.id 为准；没有档案或 id 为空的单位不参与队伍快照。
static func member_id_of(unit: Pawn) -> StringName:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return &""
	return unit.data.id
