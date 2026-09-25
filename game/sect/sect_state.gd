class_name SectState
extends Node

## 宗门运行时（INC-SECT-002）：持有灵石 / 灵草 / 丹药库存与六座设施的等级，执行升级、
## 打坐修炼与灵田收获。所有静态数值（花费 / 产出 / 门槛）都来自 `SectFacilityDefinition`，
## 本模块不硬编码任何设施 id 的数值，只硬编码「哪些设施承担哪种职责」这一分类事实。
##
## 职责边界：
## - 灵石只能由外部通过 `deposit_spirit_stones()` 入账（秘境收益），宗门自己不产生灵石；
## - 修为写入走 `Pawn.gain_cultivation_exp()`，宗门不直接操作 `CultivationProgressComponent`；
## - 转化设施（藏经阁 / 炼器房 / 丹房）由 `INC-SECT-003` 在本类上扩展。

signal spirit_stones_changed(state: SectState, current: int)
signal spirit_herbs_changed(state: SectState, current: int)
signal pills_changed(state: SectState, current: int)
signal facility_upgraded(state: SectState, facility_id: StringName, new_level: int)
signal cultivation_gained(state: SectState, pawn: Pawn, amount: float)
signal herbs_harvested(state: SectState, facility_id: StringName, amount: int)
signal technique_learned(state: SectState, pawn: Pawn, technique: TechniqueDefinition)
signal weapon_strengthened(state: SectState, pawn: Pawn, level: int)
signal pill_refined(state: SectState, amount: int)
signal pill_used(state: SectState, pawn: Pawn, restored: float)

## 不可升级原因：空 StringName 表示可以升级；面板与测试共用同一套原因，不在 UI 里重新判断。
const REASON_NONE: StringName = &""
const REASON_UNKNOWN_FACILITY: StringName = &"unknown_facility"
const REASON_MAX_LEVEL: StringName = &"max_level"
const REASON_NOT_ENOUGH_SPIRIT_STONES: StringName = &"not_enough_spirit_stones"
const REASON_REALM_TOO_LOW: StringName = &"realm_too_low"

## 洞府对打坐效率的每级加成：multiplier = 1 + 洞府等级 × 本常量。
## 洞府的价值是「让聚灵阵更有效」，因此它自己不出产修为（`yield_per_level = 0`）。
const CAVE_DWELLING_BONUS_PER_LEVEL: float = 0.5

## 承担具体职责的设施 id：id 是数据与代码之间的唯一约定，数值仍全部来自设施定义。
const FACILITY_CAVE_DWELLING: StringName = &"cave_dwelling"
const FACILITY_SPIRIT_ARRAY: StringName = &"spirit_array"
const FACILITY_SPIRIT_FIELD: StringName = &"spirit_field"
const FACILITY_ALCHEMY_ROOM: StringName = &"alchemy_room"
const FACILITY_FORGE_ROOM: StringName = &"forge_room"
const FACILITY_SCRIPTURE_PAVILION: StringName = &"scripture_pavilion"

## 单颗丹药每级恢复的生命与灵力；实际恢复量再按各资源上限截断。
const PILL_RESTORE_PER_LEVEL: float = 15.0

## 设施初始等级：1 表示「已建成但未强化」，0 只可能来自未知 id。
const INITIAL_FACILITY_LEVEL: int = 1

## 六座设施静态定义；由主场景或测试注入，本模块不 load 任何资源路径。
@export var facilities: Array[SectFacilityDefinition] = []

var _spirit_stones: int = 0
var _spirit_herbs: int = 0
var _pills: int = 0
## 设施等级：StringName -> int。只保存注入设施的等级，未知 id 不写入。
var _levels: Dictionary = {}
## 本代修士：升级门槛与修为写入都通过它读取，宗门不复制境界数值。
var _cultivator: Pawn


func _ready() -> void:
	initialize_facilities()


## 幂等初始化：为每座注入设施建立初始等级，已有等级不会被重置。
func initialize_facilities() -> void:
	for facility: SectFacilityDefinition in facilities:
		if facility == null or not facility.is_configured():
			continue
		if not _levels.has(facility.id):
			_levels[facility.id] = INITIAL_FACILITY_LEVEL


## 绑定本代修士：换遭遇后主场景会把引用刷新到新单位，宗门库存与等级不随之重置。
func bind_cultivator(pawn: Pawn) -> void:
	_cultivator = pawn


func get_cultivator() -> Pawn:
	return _cultivator


## 本代修士的境界 tier；未绑定修士或单位无修炼体系时返回 0，使境界门槛判定失败。
func get_cultivator_realm_tier() -> int:
	if _cultivator == null or not is_instance_valid(_cultivator):
		return 0
	var realm: RealmDefinition = _cultivator.get_realm()
	if realm == null or not realm.is_configured():
		return 0
	return realm.tier


func get_spirit_stones() -> int:
	return _spirit_stones


func get_spirit_herbs() -> int:
	return _spirit_herbs


func get_pills() -> int:
	return _pills


## 秘境收益入账：只接受正数，返回实际入账量；0 / 负数不产生任何变化与信号。
func deposit_spirit_stones(amount: int) -> int:
	if amount <= 0:
		return 0
	_spirit_stones += amount
	spirit_stones_changed.emit(self, _spirit_stones)
	return amount


## 按 id 取设施定义；不存在返回 null，调用方不需要自己遍历数组。
func get_facility(facility_id: StringName) -> SectFacilityDefinition:
	for facility: SectFacilityDefinition in facilities:
		if facility != null and facility.id == facility_id:
			return facility
	return null


## 设施等级：未知 id 返回 0（未建成），不会隐式创建等级。
func get_facility_level(facility_id: StringName) -> int:
	if not _levels.has(facility_id):
		return 0
	return maxi(int(_levels[facility_id]), 0)


## 下次升级花费；设施不存在或已满级返回 `SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE`。
func get_upgrade_cost(facility_id: StringName) -> int:
	var facility: SectFacilityDefinition = get_facility(facility_id)
	if facility == null:
		return SectFacilityDefinition.UPGRADE_COST_UNAVAILABLE
	return facility.get_upgrade_cost(get_facility_level(facility_id))


## 不可升级原因：设施存在 + 未满级 + 灵石足够 + 境界达标，四者都满足才是 `REASON_NONE`。
func get_upgrade_block_reason(facility_id: StringName) -> StringName:
	var facility: SectFacilityDefinition = get_facility(facility_id)
	if facility == null:
		return REASON_UNKNOWN_FACILITY
	var level: int = get_facility_level(facility_id)
	if not facility.can_upgrade(level):
		return REASON_MAX_LEVEL
	if _spirit_stones < facility.get_upgrade_cost(level):
		return REASON_NOT_ENOUGH_SPIRIT_STONES
	if get_cultivator_realm_tier() < facility.required_realm_tier:
		return REASON_REALM_TOO_LOW
	return REASON_NONE


func can_upgrade_facility(facility_id: StringName) -> bool:
	return get_upgrade_block_reason(facility_id) == REASON_NONE


## 升级设施：成功时扣灵石、等级 +1 并广播；任何一条校验不通过都返回 false 且不扣灵石。
func upgrade_facility(facility_id: StringName) -> bool:
	if not can_upgrade_facility(facility_id):
		return false
	var facility: SectFacilityDefinition = get_facility(facility_id)
	var level: int = get_facility_level(facility_id)
	var cost: int = facility.get_upgrade_cost(level)
	_spirit_stones -= cost
	_levels[facility_id] = level + 1
	spirit_stones_changed.emit(self, _spirit_stones)
	facility_upgraded.emit(self, facility_id, level + 1)
	return true


## 打坐修炼：修为 = 聚灵阵产出 ×（1 + 洞府等级 × 0.5），返回实际写入的修为。
## 未绑定修士 / 无聚灵阵产出 / 已达当前境界瓶颈时返回 0，且不产生任何副作用。
func cultivate() -> float:
	if _cultivator == null or not is_instance_valid(_cultivator):
		return 0.0
	var array_facility: SectFacilityDefinition = get_facility(FACILITY_SPIRIT_ARRAY)
	if array_facility == null:
		return 0.0
	var base_yield: int = array_facility.get_yield(get_facility_level(FACILITY_SPIRIT_ARRAY))
	if base_yield <= 0:
		return 0.0

	var cave_level: int = get_facility_level(FACILITY_CAVE_DWELLING)
	var amount: float = float(base_yield) * (1.0 + float(cave_level) * CAVE_DWELLING_BONUS_PER_LEVEL)
	var gained: float = _cultivator.gain_cultivation_exp(amount, &"sect_cultivation")
	if gained > 0.0:
		cultivation_gained.emit(self, _cultivator, gained)
	return gained


## 灵田收获：把「灵田等级 × 每级产出」加入灵草库存，返回实际入库量。
func harvest_spirit_field() -> int:
	var facility: SectFacilityDefinition = get_facility(FACILITY_SPIRIT_FIELD)
	if facility == null:
		return 0
	var amount: int = facility.get_yield(get_facility_level(FACILITY_SPIRIT_FIELD))
	if amount <= 0:
		return 0
	_spirit_herbs += amount
	spirit_herbs_changed.emit(self, _spirit_herbs)
	herbs_harvested.emit(self, FACILITY_SPIRIT_FIELD, amount)
	return amount


## 藏经阁参悟：把功法写入修士运行时列表，绝不改写 TechniqueDefinition / PawnData。
## 成功时扣灵石并广播；任一前置校验失败都返回 false 且零副作用。
func learn_technique_from_pavilion(technique: TechniqueDefinition) -> bool:
	if technique == null or not technique.is_configured():
		return false
	if _cultivator == null or not is_instance_valid(_cultivator):
		return false
	var pavilion: SectFacilityDefinition = get_facility(FACILITY_SCRIPTURE_PAVILION)
	if pavilion == null or get_facility_level(FACILITY_SCRIPTURE_PAVILION) < 1:
		return false
	if get_cultivator_realm_tier() < technique.required_realm_tier:
		return false
	if _cultivator.has_technique(technique.id):
		return false
	if _spirit_stones < pavilion.spirit_stone_cost:
		return false
	if not _cultivator.learn_technique(technique):
		return false
	_spirit_stones -= pavilion.spirit_stone_cost
	spirit_stones_changed.emit(self, _spirit_stones)
	technique_learned.emit(self, _cultivator, technique)
	return true


## 炼器房强化：灵石换取本代修士主武器的运行时强化等级 +1。
## 强化上限 = min(设施等级, Pawn.MAX_FORGE_LEVEL)；资源扣除与信号只在强化确实成功后发生。
func strengthen_weapon() -> bool:
	if _cultivator == null or not is_instance_valid(_cultivator):
		return false
	var forge_room: SectFacilityDefinition = get_facility(FACILITY_FORGE_ROOM)
	var forge_level: int = get_facility_level(FACILITY_FORGE_ROOM)
	if forge_room == null or forge_level < 1:
		return false
	if not _cultivator.has_weapon():
		return false
	var current_level: int = _cultivator.get_forge_level()
	if current_level >= mini(forge_level, Pawn.MAX_FORGE_LEVEL):
		return false
	if _spirit_stones < forge_room.spirit_stone_cost:
		return false
	if _cultivator.strengthen_weapon() != current_level + 1:
		return false
	_spirit_stones -= forge_room.spirit_stone_cost
	spirit_stones_changed.emit(self, _spirit_stones)
	weapon_strengthened.emit(self, _cultivator, current_level + 1)
	return true


## 丹房炼丹：扣灵草并增加丹药库存，返回本次产出数量；失败返回 0 且无副作用。
func refine_pill() -> int:
	var alchemy_room: SectFacilityDefinition = get_facility(FACILITY_ALCHEMY_ROOM)
	var alchemy_level: int = get_facility_level(FACILITY_ALCHEMY_ROOM)
	if alchemy_room == null or alchemy_level < 1:
		return 0
	if _spirit_herbs < alchemy_room.herb_cost:
		return 0
	var amount: int = alchemy_room.get_yield(alchemy_level)
	if amount <= 0:
		return 0
	_spirit_herbs -= alchemy_room.herb_cost
	_pills += amount
	spirit_herbs_changed.emit(self, _spirit_herbs)
	pills_changed.emit(self, _pills)
	pill_refined.emit(self, amount)
	return amount


## 服丹：消耗 1 颗丹药，按丹房等级等量恢复生命与灵力，返回两者实际恢复量之和。
## 未绑定修士 / 已死亡 / 无丹药时不消耗；已满的资源只贡献 0 到实际恢复量。
func use_pill() -> float:
	if _pills <= 0:
		return 0.0
	if _cultivator == null or not is_instance_valid(_cultivator) or not _cultivator.is_alive():
		return 0.0
	var alchemy_level: int = get_facility_level(FACILITY_ALCHEMY_ROOM)
	if alchemy_level < 1:
		return 0.0
	_pills -= 1
	pills_changed.emit(self, _pills)
	var restore_amount: float = float(alchemy_level) * PILL_RESTORE_PER_LEVEL
	var health_restored: float = _cultivator.restore_health(restore_amount)
	var spirit_restored: float = _cultivator.restore_spirit(restore_amount)
	var restored: float = health_restored + spirit_restored
	pill_used.emit(self, _cultivator, restored)
	return restored

## 只读快照：面板只渲染本方法的返回值，每次调用都返回新字典，外部修改不影响宗门状态。
func get_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	for facility: SectFacilityDefinition in facilities:
		if facility == null or not facility.is_configured():
			continue
		var level: int = get_facility_level(facility.id)
		entries.append({
			"id": facility.id,
			"display_name": facility.display_name,
			"kind": facility.kind,
			"kind_label": facility.get_kind_label(),
			"level": level,
			"max_level": facility.max_level,
			"upgrade_cost": facility.get_upgrade_cost(level),
			"can_upgrade": can_upgrade_facility(facility.id),
			"block_reason": get_upgrade_block_reason(facility.id),
			"yield_per_level": facility.yield_per_level,
			"spirit_stone_cost": facility.spirit_stone_cost,
			"herb_cost": facility.herb_cost,
			"required_realm_tier": facility.required_realm_tier,
		})
	return {
		"spirit_stones": _spirit_stones,
		"spirit_herbs": _spirit_herbs,
		"pills": _pills,
		"facilities": entries,
	}
