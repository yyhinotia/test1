class_name PawnResourceSnapshot
extends RefCounted

## 跨房间资源快照（INC-WORLD-004）。
##
## 只记录「资源 id → 当前值」，不关心生命 / 护盾 / 灵力的业务语义，
## 也不持有 Pawn 引用；capture / apply 对空单位与缺失资源池一律安全降级。
## 具体资源有哪些由 Pawn.get_resource_ids() 决定，快照不硬编码任何资源 id。

var _values: Dictionary = {}


## 采集一个单位的全部资源池当前值；空单位返回空快照。
static func capture(pawn: Pawn) -> PawnResourceSnapshot:
	var snapshot: PawnResourceSnapshot = PawnResourceSnapshot.new()
	if pawn == null or not is_instance_valid(pawn):
		return snapshot
	for key: Variant in pawn.get_resource_ids():
		var resource_id: StringName = StringName(key)
		var pool: ResourcePoolComponent = pawn.get_resource_pool(resource_id)
		if pool == null:
			continue
		snapshot._values[resource_id] = pool.current_value
	return snapshot


## 把快照写回目标单位；目标缺少同名资源池时跳过该项，不报错也不代建资源。
func apply_to(pawn: Pawn) -> void:
	if pawn == null or not is_instance_valid(pawn):
		return
	for key: Variant in _values.keys():
		var resource_id: StringName = StringName(key)
		var pool: ResourcePoolComponent = pawn.get_resource_pool(resource_id)
		if pool == null:
			continue
		pool.set_value(float(_values[key]), &"dungeon_carry")


func get_value(resource_id: StringName, fallback: float = 0.0) -> float:
	if not _values.has(resource_id):
		return fallback
	return float(_values[resource_id])


func has_value(resource_id: StringName) -> bool:
	return _values.has(resource_id)


func get_resource_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: Variant in _values.keys():
		ids.append(StringName(key))
	return ids


func get_value_count() -> int:
	return _values.size()


func is_empty() -> bool:
	return _values.is_empty()
