class_name DungeonDefinition
extends Resource

## 秘境静态定义（INC-WORLD-003）：一个有序房间链 + 终局 Boss。
## 运行时（DungeonRun）与 UI 只读本定义，不硬编码房间数、奖励或 Boss 位置。

@export var id: StringName = &"dungeon"
@export var display_name: String = "秘境"
@export_multiline var description: String = ""
@export var rooms: Array[DungeonRoom] = []


## 秘境可直接进入：id / 名称非空、房间数 >= 1，且每个房间都已配置完成。
func is_configured() -> bool:
	if String(id).strip_edges().is_empty():
		return false
	if display_name.strip_edges().is_empty():
		return false
	if rooms.is_empty():
		return false
	for room: DungeonRoom in rooms:
		if room == null or not room.is_configured():
			return false
	return true


func get_room_count() -> int:
	return rooms.size()


## 越界安全读取：调用方用 null 判断该层不存在，不做隐式 clamp。
func get_room(index: int) -> DungeonRoom:
	if index < 0 or index >= rooms.size():
		return null
	return rooms[index]


func has_boss() -> bool:
	return get_boss_index() >= 0


## Boss 房索引；没有 Boss 返回 -1。房间链的合法性（恰好一个 Boss 且在末尾）由测试与配置约束。
func get_boss_index() -> int:
	for index: int in rooms.size():
		var room: DungeonRoom = rooms[index]
		if room != null and room.is_boss:
			return index
	return -1


## 越界奖励按 0 处理，避免运行时把非法层数变成收益。
func get_room_reward(index: int) -> int:
	var room: DungeonRoom = get_room(index)
	if room == null:
		return 0
	return room.get_reward()


## 全房间奖励之和，用于显示「最多能拿多少」。
func get_max_reward() -> int:
	var total: int = 0
	for index: int in rooms.size():
		total += get_room_reward(index)
	return total
