class_name ResourceSetComponent
extends Node

## 按稳定资源 ID 查找多个 ResourcePoolComponent。
## 此组件只负责注册与查找，不解释任何资源业务规则。

var _pools: Dictionary = {}

var pool_count: int:
	get:
		return _pools.size()

func register_pool(resource_id: StringName, pool: ResourcePoolComponent) -> bool:
	if resource_id == &"" or pool == null or not is_instance_valid(pool) or _pools.has(resource_id):
		return false
	_pools[resource_id] = pool
	return true

func unregister_pool(resource_id: StringName) -> bool:
	if not _pools.has(resource_id):
		return false
	_pools.erase(resource_id)
	return true

func has_pool(resource_id: StringName) -> bool:
	return _pools.has(resource_id)

func get_pool(resource_id: StringName) -> ResourcePoolComponent:
	var pool: Variant = _pools.get(resource_id)
	return pool as ResourcePoolComponent

func get_resource_ids() -> Array[StringName]:
	var resource_ids: Array[StringName] = []
	for resource_id: Variant in _pools.keys():
		resource_ids.append(StringName(resource_id))
	resource_ids.sort_custom(_sort_resource_ids)
	return resource_ids

func _sort_resource_ids(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
