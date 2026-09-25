class_name SquadDefinition
extends Resource

## 队伍静态契约（INC-PAWNS-020）。
##
## 只描述「一支队伍由哪些成员档案组成、默认怎么站位」，不持有运行时生命、冷却、境界或 Build；
## 运行时单位由 EncounterSession 按本资源实例化，跨房间 / 跨对局的进度延续由队伍快照负责。
## 成员身份一律用 PawnData.id 表达：快照与进度写回都以 id 为键，禁止用数组下标互相覆盖。

## 成员或站位发生变更后由修改方显式调用；不在 @export setter 中触发，避免编辑器导入时产生信号副作用。
signal members_changed(squad: SquadDefinition)

## 阶段上限：Vertical Slice 的 4v4。超过上限视为未配置，避免内容侧悄悄扩大规模。
const MAX_MEMBERS: int = 4
## 未显式配置站位时，运行时按此间距生成安全默认阵型（不写回资源）。
const DEFAULT_OFFSET_SPACING: Vector2 = Vector2(56.0, 64.0)

@export var id: StringName = &"squad"
@export var display_name: String = "队伍"
## 有序成员档案；顺序即上阵顺序。玩家队伍约定第 0 位是主角槽位（由 EncounterSession 用运行时玩家档案填充）。
@export var members: Array[PawnData] = []
## 可选默认站位偏移；为空时由 get_spawn_offsets() 生成，非空时必须与成员数量一致。
@export var default_spawn_offsets: Array[Vector2] = []


func notify_members_changed() -> void:
	members_changed.emit(self)


## 队伍是否可直接使用：id 非空、成员数量在 1..MAX_MEMBERS、成员档案齐备且 id 唯一、
## 显式站位数量与成员数量一致。任何一条不满足都返回 false。
func is_configured() -> bool:
	return get_configuration_errors().is_empty()


## 未通过校验的原因列表；空数组表示 is_configured() 为 true。
## 返回可读文案而不是只返回 bool，是为了让内容侧与测试能看到「为什么这支队伍不可用」。
func get_configuration_errors() -> Array[String]:
	var errors: Array[String] = []
	if String(id).strip_edges().is_empty():
		errors.append("id 不能为空")
	if members.is_empty():
		errors.append("成员不能为空")
	elif members.size() > MAX_MEMBERS:
		errors.append("成员数量不能超过 %d" % MAX_MEMBERS)
	var seen_ids: Array[StringName] = []
	for index: int in range(members.size()):
		var member: PawnData = members[index]
		if member == null:
			errors.append("第 %d 位成员档案为空" % index)
			continue
		var member_id: StringName = member.id
		if String(member_id).strip_edges().is_empty():
			errors.append("第 %d 位成员缺少 id" % index)
			continue
		if seen_ids.has(member_id):
			errors.append("成员 id 重复：%s" % String(member_id))
			continue
		seen_ids.append(member_id)
	if not default_spawn_offsets.is_empty() and default_spawn_offsets.size() != members.size():
		errors.append("默认站位数量与成员数量不一致")
	return errors


func get_member_count() -> int:
	return members.size()


## 有序成员 id；成员为空档案时用空 StringName 占位，保持「顺序即上阵顺序」。
func get_member_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for member: PawnData in members:
		ids.append(member.id if member != null else &"")
	return ids


## 按成员 id 取档案；未命中返回 null。
func get_member_by_id(member_id: StringName) -> PawnData:
	for member: PawnData in members:
		if member != null and member.id == member_id:
			return member
	return null


func has_member_id(member_id: StringName) -> bool:
	return get_member_by_id(member_id) != null


## 上阵站位：显式配置优先，否则按成员数量生成安全默认阵型。
## 有成员时返回值长度始终等于成员数量；成员为空时返回空数组。
func get_spawn_offsets() -> Array[Vector2]:
	if not default_spawn_offsets.is_empty():
		return default_spawn_offsets.duplicate()
	return build_default_offsets(members.size())


## 按成员数量生成默认阵型：第 0 位在原点，其余成员「左右交替、逐排后移」。
## 纯函数，不读写资源字段，便于测试与复用。
static func build_default_offsets(count: int) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	if count <= 0:
		return offsets
	offsets.append(Vector2.ZERO)
	for index: int in range(1, count):
		var rank: int = int(ceil(float(index) / 2.0))
		var side: float = -1.0 if index % 2 == 1 else 1.0
		offsets.append(
			Vector2(DEFAULT_OFFSET_SPACING.x * side * float(rank), DEFAULT_OFFSET_SPACING.y * float(rank))
		)
	return offsets


## 取前 count 个成员（不足则返回全部）；用于按敌人数派生玩家上阵人数。
func get_member_slice(count: int) -> Array[PawnData]:
	var result: Array[PawnData] = []
	var limit: int = mini(maxi(count, 0), members.size())
	for index: int in range(limit):
		result.append(members[index])
	return result
