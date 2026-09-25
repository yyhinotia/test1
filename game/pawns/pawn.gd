class_name Pawn
extends CharacterBody2D

signal health_changed(pawn: Pawn, current_health: float, max_health: float)
signal shield_changed(pawn: Pawn, current_shield: float, max_shield: float)
signal spirit_changed(pawn: Pawn, current_spirit: float, max_spirit: float)
signal cultivation_changed(pawn: Pawn, current_exp: float, required_exp: float)
signal cultivation_ready(pawn: Pawn)
signal realm_changed(pawn: Pawn, previous_realm: RealmDefinition, current_realm: RealmDefinition)
signal state_changed(pawn: Pawn, new_state: int)
signal attack_performed(target: Pawn)
signal skill_cast(pawn: Pawn, skill: ActiveSkillDefinition, target: Pawn)
signal skill_cooldown_changed(pawn: Pawn, skill_id: StringName, remaining: float)
signal died(pawn: Pawn)
signal stun_changed(pawn: Pawn, remaining: float, active: bool)
## Build 变更广播：运行时领悟功法或强化武器后由 Pawn 自己发出，不冒充 PawnData 的通知。
signal build_changed(pawn: Pawn)

enum State {
	IDLE,
	MOVING,
	ATTACKING,
	DEAD,
}

## 目标高亮是纯表现层：合法目标才显示，非法目标不显示“可确认”状态。
const TARGET_HIGHLIGHT_LEGAL_COLOR: Color = Color(0.35, 0.95, 1.0, 1.0)
## 危险窗口高亮：只改变视觉染色，不改变碰撞、仇恨或伤害规则。
const DANGER_HIGHLIGHT_COLOR: Color = Color(1.0, 0.5, 0.35, 1.0)

const SPIRIT_RESOURCE_ID: StringName = &"spirit"
const SPIRIT_DISPLAY_NAME: String = "灵力"
const SPIRIT_POOL_NAME: StringName = &"Spirit"

## 主动技能容量无界哨兵：无有效境界的原生单位不参与 Build 容量截断。
const ACTIVE_SKILL_CAPACITY_UNBOUNDED: int = -1

## 武器强化（运行时覆盖层）：每级提供的攻击加成与强化等级上限。
## 这两个常量只服务本代修士的运行时状态，不写回 `PawnData` 或 `WeaponDefinition`。
const FORGE_ATTACK_BONUS_PER_LEVEL: float = 6.0
const MAX_FORGE_LEVEL: int = 3

@export var data: PawnData

@onready var visual: Sprite2D = $Visual/Sprite2D
@onready var collision_shape: CollisionShape2D = $Collision/CollisionShape2D
@onready var resources: ResourceSetComponent = $Resources
@onready var health_pool: ResourcePoolComponent = $Resources/Health
@onready var shield_pool: ResourcePoolComponent = $Resources/Shield
@onready var health: HealthComponent = $HealthComponent
@onready var cultivation_progress: CultivationProgressComponent = $CultivationProgress
@onready var status_bars: PawnStatusBars = $HealthBarAnchor/StatusBars
@onready var selection_indicator: CanvasItem = $SelectionIndicator
@onready var target_indicator: Line2D = $TargetIndicator
@onready var controller: PawnController = $Controller

## 灵力池只在 `max_spirit > 0` 时创建，因此没有灵力配置的单位这里为 null。
var spirit_pool: ResourcePoolComponent

## 运行时生命数值由 `Resources/Health` 资源池唯一持有，`Pawn.health` 只是兼容门面；
## 这里只保留只读代理，让 HUD、测试等既有调用方继续用 `pawn.current_health` 读取。
var current_health: float:
	get:
		return (health.current_health if health != null else 0.0)

var current_shield: float:
	get:
		return (health.current_shield if health != null else 0.0)

## 灵力由 `Resources/Spirit` 资源池持有；没有配置灵力的单位恒为 0。
var current_spirit: float:
	get:
		return (spirit_pool.current_value if spirit_pool != null else 0.0)

var max_spirit: float:
	get:
		return (spirit_pool.max_value if spirit_pool != null else 0.0)

var _state: int = State.IDLE
var _attack_cooldown: float = 0.0
var _attack_state_remaining: float = 0.0
var _visual_tween: Tween
var _selected: bool = false
var _target_highlight_visible: bool = false
var _skill_cooldowns: Dictionary = {}

## 眩晕只封锁行动：持续期间不能移动、普通攻击或施放技能，不修改生命与其它资源。
var _stun_remaining: float = 0.0

## 运行时 Build 覆盖层（INC-PAWNS-018）：宗门参悟得到的新功法与炼器房强化等级。
## 这两份状态只属于本代修士的运行时，绝不写回 `PawnData` / `WeaponDefinition` 静态资源。
var _learned_techniques: Array[TechniqueDefinition] = []
var _forge_level: int = 0

## 运行时主动技能覆盖层（INC-PAWNS-021）：已掌握与已装配是两份独立的运行时事实。
## 「已掌握」= 静态预设 + 运行时解锁；「已装配」= 本代修士当前实际生效的技能列表。
## 两者都只属于本代修士的运行时状态，绝不写回 `PawnData`；没有显式重配时读模型完全沿用静态预设。
var _learned_active_skills: Array[ActiveSkillDefinition] = []
var _equipped_active_skills: Array[ActiveSkillDefinition] = []
var _has_equipped_active_skills: bool = false

var state: int:
	get:
		return _state

func _ready() -> void:
	# 资源池必须先注册并绑定到兼容门面，之后的数值只有一个数据源。
	_register_resource_pools()
	_setup_cultivation_progress()
	# 目标高亮是纯表现节点：出生时必须隐藏，避免继承场景残留可见状态。
	set_target_highlight(false)

	if data == null:
		push_error("Pawn requires a PawnData resource: %s" % get_path())
		# 保持配置错误时的旧行为：没有 PawnData 的单位视为生命为 0（已死亡），
		# 而不是把组件默认上限当成存活单位。
		health.configure(0.0, 0.0)
		_bind_status_bars()
		return

	# 资源池是运行时唯一数据源，Pawn 直接监听池事件，避免兼容门面成为生命周期单点。
	_connect_resource_pool_signals()
	# 静默初始化：出生时不触发资源条显示。
	health.configure(data.max_health, data.max_shield)
	# 必须在资源池配置完成后绑定，ResourceBar 才能读到正确的当前值与上限。
	_bind_status_bars()

	visual.modulate = data.display_color
	set_selected(false)
	_set_state(State.IDLE)

## 注册本单位的资源池，并把 HealthComponent 绑定为它们的兼容门面。
func _register_resource_pools() -> void:
	if resources == null or health_pool == null or shield_pool == null:
		push_error("Pawn 缺少 Resources/Health|Shield 资源池节点：%s" % get_path())
		return

	resources.register_pool(HealthComponent.HEALTH_RESOURCE_ID, health_pool)
	resources.register_pool(HealthComponent.SHIELD_RESOURCE_ID, shield_pool)
	health.bind_pools(health_pool, shield_pool)
	_setup_spirit_pool()

## 直接订阅真实资源池的事件，使生命周期和状态条不再依赖兼容门面的转发。
## 配置阶段不会发出 value_changed，因此出生时不会误触发死亡或显示。
func _connect_resource_pool_signals() -> void:
	health_pool.value_changed.connect(_on_health_pool_value_changed)
	health_pool.depleted.connect(_on_health_pool_depleted)
	shield_pool.value_changed.connect(_on_shield_pool_value_changed)
	if spirit_pool != null and not spirit_pool.value_changed.is_connected(_on_spirit_pool_value_changed):
		spirit_pool.value_changed.connect(_on_spirit_pool_value_changed)

## 把已配置的资源池绑定到 PawnStatusBars；UI 只读，不复制资源数值。
func _bind_status_bars() -> void:
	if status_bars == null:
		push_error("Pawn 缺少 HealthBarAnchor/StatusBars 节点：%s" % get_path())
		return
	status_bars.bind_pool(HealthComponent.HEALTH_RESOURCE_ID, health_pool)
	status_bars.bind_pool(HealthComponent.SHIELD_RESOURCE_ID, shield_pool)
	if spirit_pool != null:
		status_bars.bind_pool(SPIRIT_RESOURCE_ID, spirit_pool)

## 按稳定资源 ID 只读查询资源池（供 UI、技能与测试使用）。
func get_resource_pool(resource_id: StringName) -> ResourcePoolComponent:
	if resources == null:
		return null
	return resources.get_pool(resource_id)

func get_resource_ids() -> Array[StringName]:
	var empty_ids: Array[StringName] = []
	if resources == null:
		return empty_ids
	return resources.get_resource_ids()

## 本单位的运行时境界；没有配置修炼体系时返回 null，由调用方决定显示策略。
## 运行时真相由 CultivationProgressComponent 持有；突破后这里随组件推进，绝不改写 PawnData.realm。
func get_realm() -> RealmDefinition:
	if cultivation_progress != null and cultivation_progress.is_configured():
		return cultivation_progress.get_realm()
	return get_base_realm()

## 静态档案定义的起始境界；用于恢复校验与“突破前基线”查询。
func get_base_realm() -> RealmDefinition:
	if data == null:
		return null
	return data.realm

## 只读 Build 汇总：境界 + 功法 + 主武器 + 当前生效的主动技能装配（被动尚无数据来源，保持为空）。
## 主动技能读的是运行时装配结果：没有显式重配时等于静态预设，重配后立即反映新 Build；
## 运行时可用列表请使用 get_enabled_active_skills()，它按容量投影并已去重。
## 每次调用返回新实例，调用方可以自由修改结果而不影响 PawnData 预设。
func get_build_loadout() -> BuildLoadout:
	var loadout: BuildLoadout = BuildLoadout.new()
	if data == null:
		return loadout
	loadout.realm = get_realm()
	# 功法 = 静态预设（保持原顺序）+ 运行时领悟（按领悟顺序追加）。
	# 运行时覆盖层只改变本单位的读模型，不改写 `PawnData.techniques`。
	loadout.techniques.assign(data.techniques)
	for technique: TechniqueDefinition in _learned_techniques:
		loadout.techniques.append(technique)
	if data.weapon != null:
		loadout.weapons.append(data.weapon)
	# 主动技能统一走运行时装配读模型，禁止调用方再直接消费 PawnData.active_skills。
	loadout.active_skills.assign(_validator_active_skills())
	return loadout

## Build 校验结果：只做规则判定，不装备、不卸载、不修改任何资源池或冷却。
func get_build_validation() -> BuildValidationResult:
	return BuildValidator.validate(get_build_loadout())

## 运行时领悟功法（INC-PAWNS-018）：去重（含静态预设）、忽略无效资源，成功返回 true 并广播 `build_changed`。
## 本方法只追加运行时列表，`PawnData.techniques` 与 `TechniqueDefinition` 资源在任何情况下都不被改写。
func learn_technique(technique: TechniqueDefinition) -> bool:
	if technique == null or not technique.is_configured():
		return false
	if has_technique(technique.id):
		return false
	_learned_techniques.append(technique)
	build_changed.emit(self)
	return true


## 运行时领悟的功法列表（不含静态预设）；返回副本，调用方不能就地改写内部状态。
func get_learned_techniques() -> Array[TechniqueDefinition]:
	return _learned_techniques.duplicate()


## 是否在运行时领悟过该 id；静态预设不算「领悟」，因此参悟同一功法不会重复入列。
func has_learned_technique(technique_id: StringName) -> bool:
	for technique: TechniqueDefinition in _learned_techniques:
		if technique.id == technique_id:
			return true
	return false


## 当前 Build 是否已包含该功法：静态预设 + 运行时领悟合并判定，供「参悟前查重」使用。
func has_technique(technique_id: StringName) -> bool:
	if has_learned_technique(technique_id):
		return true
	if data == null:
		return false
	for technique: TechniqueDefinition in data.techniques:
		if technique != null and technique.id == technique_id:
			return true
	return false


## 是否配置了可用主武器：Build 读模型与武器强化都以它为唯一前置。
func has_weapon() -> bool:
	return data != null and data.weapon != null and data.weapon.is_configured()


## 当前主武器强化等级；未强化与没有主武器都返回 0。
func get_forge_level() -> int:
	return _forge_level


## 是否可以继续强化：有主武器且未达 `MAX_FORGE_LEVEL`。
func can_strengthen_weapon() -> bool:
	return has_weapon() and _forge_level < MAX_FORGE_LEVEL


## 强化主武器：每级提供 `FORGE_ATTACK_BONUS_PER_LEVEL` 攻击，返回强化后的等级并广播 `build_changed`。
## 没有主武器时返回 0 且不改变任何状态；已达上限时返回当前等级且不再增长。
func strengthen_weapon() -> int:
	if not has_weapon():
		return 0
	if _forge_level >= MAX_FORGE_LEVEL:
		return _forge_level
	_forge_level += 1
	build_changed.emit(self)
	return _forge_level


## 攻击数值的唯一出口：基础攻击 + 强化等级加成。`try_attack()` 通过它结算伤害，
## 因此「炼器房强化」在真实伤害路径上生效，而不是只改显示。
func get_attack_power() -> float:
	if data == null:
		return 0.0
	return data.attack + float(_forge_level) * FORGE_ATTACK_BONUS_PER_LEVEL

## 已掌握主动技能：静态预设在前，运行时解锁按解锁顺序追加；同一 id 只保留首次出现。
## 这是「这个修士会什么」的唯一读模型，技能输入与技能栏只允许查它，不得直接读 PawnData。
func get_known_active_skills() -> Array[ActiveSkillDefinition]:
	var result: Array[ActiveSkillDefinition] = []
	var seen_ids: Dictionary = {}
	if data != null:
		for skill: ActiveSkillDefinition in data.get_active_skills():
			_append_known_active_skill(result, seen_ids, skill)
	for skill: ActiveSkillDefinition in _learned_active_skills:
		_append_known_active_skill(result, seen_ids, skill)
	return result


## 已装配主动技能（生效投影的事实源）：显式重配过时返回装配结果，
## 否则完全沿用静态预设的「去重 + 过滤后」列表（与 INC-PAWNS-021 之前的投影行为逐字一致）。
func get_equipped_active_skills() -> Array[ActiveSkillDefinition]:
	if _has_equipped_active_skills:
		return _equipped_active_skills.duplicate()
	var preset: Array[ActiveSkillDefinition] = []
	if data != null:
		preset.assign(data.get_active_skills())
	return preset


## 校验读模型：未显式重配时保留静态预设的原始条目（含重复与未配置项），
## 让 BuildValidator 仍能报 `duplicate_entry` / `unconfigured_entry`；重配后返回已校验的唯一装配。
func _validator_active_skills() -> Array[ActiveSkillDefinition]:
	if _has_equipped_active_skills:
		return _equipped_active_skills.duplicate()
	var raw: Array[ActiveSkillDefinition] = []
	if data == null:
		return raw
	if not data.active_skills.is_empty():
		raw.assign(data.active_skills)
	elif data.active_skill != null:
		raw.append(data.active_skill)
	return raw


## 是否已掌握该技能实例：采用实例身份比较，与 PlayerController / SkillBar 的历史判定一致。
func is_active_skill_known(skill: ActiveSkillDefinition) -> bool:
	if skill == null:
		return false
	for known: ActiveSkillDefinition in get_known_active_skills():
		if known == skill:
			return true
	return false


## 运行时解锁主动技能（INC-PAWNS-021）：按 id 去重（含静态预设），成功返回 true 并广播 build_changed。
## 本方法只让技能进入「已掌握」，不自动装配；是否装备由 set_active_skill_loadout() 显式裁决。
func learn_active_skill(skill: ActiveSkillDefinition) -> bool:
	if skill == null or not skill.is_configured():
		return false
	for known: ActiveSkillDefinition in get_known_active_skills():
		if known == skill:
			return false
		if known.is_configured() and known.id == skill.id:
			return false
	_learned_active_skills.append(skill)
	build_changed.emit(self)
	return true


## 运行时已解锁的主动技能列表（不含静态预设）；返回副本，调用方不能就地改写内部状态。
func get_learned_active_skills() -> Array[ActiveSkillDefinition]:
	return _learned_active_skills.duplicate()


## 是否在运行时解锁过该 id；静态预设不算「解锁」，因此重复解锁同一技能会被拒绝。
func has_learned_active_skill(skill_id: StringName) -> bool:
	for skill: ActiveSkillDefinition in _learned_active_skills:
		if skill != null and skill.id == skill_id:
			return true
	return false


## Build 重配的唯一出口：只接受已掌握、唯一且不超过当前境界主动技能容量的技能。
## 任一校验失败都保持调用前状态完全不变（零副作用）；传入空数组是合法的「显式清空装配」，
## 它与「从未重配」不同：清空后 get_enabled_active_skills() 返回空列表而不是回退静态预设。
func set_active_skill_loadout(skills: Array[ActiveSkillDefinition]) -> bool:
	var capacity: int = get_active_skill_capacity()
	if capacity >= 0 and skills.size() > capacity:
		return false
	var validated: Array[ActiveSkillDefinition] = []
	var seen_ids: Dictionary = {}
	for skill: ActiveSkillDefinition in skills:
		if skill == null or not skill.is_configured():
			return false
		if not is_active_skill_known(skill):
			return false
		if seen_ids.has(skill.id):
			return false
		seen_ids[skill.id] = true
		validated.append(skill)
	_equipped_active_skills = validated
	_has_equipped_active_skills = true
	build_changed.emit(self)
	return true


## 已掌握列表的内部追加：空条目忽略；有 id 的条目按 id 去重；无 id 的条目保留但不参与去重。
func _append_known_active_skill(target: Array[ActiveSkillDefinition], seen_ids: Dictionary, skill: ActiveSkillDefinition) -> void:
	if skill == null:
		return
	var skill_id: StringName = skill.id if skill.is_configured() else &""
	if skill_id != &"":
		if seen_ids.has(skill_id):
			return
		seen_ids[skill_id] = true
	target.append(skill)


## 当前 Build 的主动技能容量：无境界或无效境界返回 -1 表示无约束；
## 有效境界返回 RealmDefinition 的主动技能槽容量，容量 0 是有效结果而不是“未配置”。
func get_active_skill_capacity() -> int:
	var realm: RealmDefinition = get_realm()
	if realm == null or not realm.is_configured():
		return ACTIVE_SKILL_CAPACITY_UNBOUNDED
	return realm.get_slot_capacity(RealmDefinition.KIND_ACTIVE_SKILL)


## 当前 Build 实际可用的主动技能只读投影：按当前装配顺序返回前 N 个有效技能。
## 无境界单位返回全部已装配技能；完整列表仍由 get_build_loadout() 提供给 BuildValidator 报 over_capacity。
func get_enabled_active_skills() -> Array[ActiveSkillDefinition]:
	var result: Array[ActiveSkillDefinition] = []
	var skills: Array[ActiveSkillDefinition] = get_equipped_active_skills()
	if skills.is_empty():
		return result
	var capacity: int = get_active_skill_capacity()
	if capacity < 0:
		result.assign(skills)
		return result
	var limit: int = mini(capacity, skills.size())
	for index: int in limit:
		result.append(skills[index])
	return result


## 启用技能在容量投影中的稳定索引；超容量、未知、未配置或空技能统一返回 -1。
## 采用实例身份比较，与 PlayerController._is_known_skill() 一致，避免用同 id 的伪资源绕过 Build。
func get_active_skill_slot_index(skill: ActiveSkillDefinition) -> int:
	if skill == null or not skill.is_configured():
		return -1
	var enabled: Array[ActiveSkillDefinition] = get_enabled_active_skills()
	for index: int in enabled.size():
		if enabled[index] == skill:
			return index
	return -1


## UI、PlayerController、AIController 与 Pawn.can_cast_skill() 共用的容量事实查询。
func is_active_skill_enabled(skill: ActiveSkillDefinition) -> bool:
	return get_active_skill_slot_index(skill) >= 0

## 突破入口：只委托修为组件的唯一裁决；Pawn 不复制阈值、不直接改写境界。
func try_breakthrough() -> bool:
	if cultivation_progress == null:
		return false
	return cultivation_progress.advance_realm()

## 恢复运行时境界：只接受从静态起始境界沿 next_realm 可达、且不低于当前境界的资源。
## 这是会话延续 / 测试恢复入口，不绕过境界链；恢复后容量读模型立即反映目标境界。
func restore_realm(realm: RealmDefinition, initial_exp: float = 0.0) -> bool:
	if cultivation_progress == null or realm == null or not realm.is_configured():
		return false
	if not _is_realm_reachable(realm):
		return false
	var current_realm: RealmDefinition = get_realm()
	if current_realm != null:
		if realm.tier < current_realm.tier:
			return false
		var adjacent_realm: RealmDefinition = current_realm.get_next_realm()
		if realm != current_realm and realm != adjacent_realm:
			return false

	var changed: bool = current_realm != realm
	var previous_realm: RealmDefinition = current_realm
	cultivation_progress.configure(realm, initial_exp)
	if changed:
		realm_changed.emit(self, previous_realm, realm)
		build_changed.emit(self)
	return true

## 可达性只沿静态 next_realm 链判断，拒绝越级 / 无关资源；循环上限防止损坏资源形成死循环。
func _is_realm_reachable(target: RealmDefinition) -> bool:
	var cursor: RealmDefinition = get_base_realm()
	var visited: int = 0
	while cursor != null and visited < 100:
		if cursor == target:
			return true
		cursor = cursor.get_next_realm()
		visited += 1
	return false

## 修为运行时接口：组件是唯一状态源，Pawn 只暴露只读查询与受控增加入口。
func get_cultivation_progress() -> CultivationProgressComponent:
	return cultivation_progress

func get_cultivation_snapshot() -> Dictionary:
	if cultivation_progress == null:
		return {
			"realm": null,
			"realm_id": &"",
			"realm_name": "",
			"next_realm": null,
			"next_realm_id": &"",
			"next_realm_name": "",
			"current_exp": 0.0,
			"required_exp": 0.0,
			"ratio": 0.0,
			"has_next_realm": false,
			"ready": false,
		}
	return cultivation_progress.get_snapshot()

func gain_cultivation_exp(amount: float, source: StringName = &"cultivation_gain") -> float:
	if cultivation_progress == null:
		return 0.0
	return cultivation_progress.increase(amount, source)

func set_cultivation_exp(value: float, source: StringName = &"set") -> float:
	if cultivation_progress == null:
		return 0.0
	return cultivation_progress.set_current_exp(value, source)

func get_next_realm() -> RealmDefinition:
	if cultivation_progress == null:
		return null
	return cultivation_progress.get_next_realm()

func is_ready_for_breakthrough() -> bool:
	return cultivation_progress != null and cultivation_progress.is_ready_for_breakthrough()


## 在场景就绪时静默配置修为组件；配置阶段不触发 UI 刷新或“可突破”信号。
func _setup_cultivation_progress() -> void:
	if cultivation_progress == null:
		push_error("Pawn 缺少 CultivationProgress 节点：%s" % get_path())
		return
	if not cultivation_progress.progress_changed.is_connected(_on_cultivation_progress_changed):
		cultivation_progress.progress_changed.connect(_on_cultivation_progress_changed)
	if not cultivation_progress.became_ready.is_connected(_on_cultivation_became_ready):
		cultivation_progress.became_ready.connect(_on_cultivation_became_ready)
	if not cultivation_progress.realm_advanced.is_connected(_on_cultivation_realm_advanced):
		cultivation_progress.realm_advanced.connect(_on_cultivation_realm_advanced)
	var initial_exp: float = data.initial_cultivation_exp if data != null else 0.0
	cultivation_progress.configure(get_base_realm(), initial_exp)


func _on_cultivation_progress_changed(
		_component: CultivationProgressComponent,
		current_exp: float,
		required_exp: float,
		_delta: float,
		_source: StringName
	) -> void:
	cultivation_changed.emit(self, current_exp, required_exp)


func _on_cultivation_became_ready(_component: CultivationProgressComponent) -> void:
	cultivation_ready.emit(self)


func _on_cultivation_realm_advanced(
		_component: CultivationProgressComponent,
		previous_realm: RealmDefinition,
		current_realm: RealmDefinition
	) -> void:
	realm_changed.emit(self, previous_realm, current_realm)
	build_changed.emit(self)


## 灵力池只在 PawnData 配置了正上限时创建；默认 max_spirit = 0 的单位不创建池、也不显示灵力条。
func _setup_spirit_pool() -> void:
	if data == null or resources == null or data.max_spirit <= 0.0:
		return

	spirit_pool = ResourcePoolComponent.new()
	spirit_pool.name = SPIRIT_POOL_NAME
	resources.add_child(spirit_pool)
	resources.register_pool(SPIRIT_RESOURCE_ID, spirit_pool)
	spirit_pool.configure(_make_spirit_definition())
	spirit_pool.value_changed.connect(_on_spirit_pool_value_changed)

func _make_spirit_definition() -> ResourcePoolDefinition:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()
	definition.resource_id = SPIRIT_RESOURCE_ID
	definition.display_name = SPIRIT_DISPLAY_NAME
	definition.max_value = data.max_spirit
	definition.initial_ratio = clampf(data.initial_spirit_ratio, 0.0, 1.0)
	return definition

func _physics_process(delta: float) -> void:
	if is_dead():
		return
	_advance_skill_cooldowns(delta)
	_advance_stun(delta)

	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if _attack_state_remaining > 0.0:
		_attack_state_remaining = maxf(_attack_state_remaining - delta, 0.0)
		if _attack_state_remaining <= 0.0 and _state == State.ATTACKING:
			_set_state(State.IDLE)

func get_controller() -> PawnController:
	return controller

func is_alive() -> bool:
	return _state != State.DEAD and current_health > 0.0

func is_dead() -> bool:
	return not is_alive()

func can_move() -> bool:
	return is_alive() and not is_stunned()

func can_attack() -> bool:
	return is_alive() and not is_stunned() and _attack_cooldown <= 0.0

func move_towards(target_position: Vector2) -> void:
	if not can_move():
		stop_moving()
		return

	var direction: Vector2 = target_position - global_position
	if direction.length_squared() <= 4.0:
		stop_moving()
		return

	velocity = direction.normalized() * data.move_speed
	_attack_state_remaining = 0.0
	_set_state(State.MOVING)
	move_and_slide()

func stop_moving() -> void:
	velocity = Vector2.ZERO
	if _state == State.MOVING:
		_set_state(State.IDLE)

func try_attack(target: Pawn) -> bool:
	if not can_attack() or target == null or not target.is_alive():
		return false

	if global_position.distance_to(target.global_position) > data.attack_range:
		return false

	_attack_cooldown = data.attack_interval
	_attack_state_remaining = minf(0.18, data.attack_interval * 0.5)
	_set_state(State.ATTACKING)
	target.take_damage(get_attack_power())
	attack_performed.emit(target)
	_play_attack_pulse()
	return true

## 伤害入口：先按 `data.defense` 结算，再把剩余伤害交给 HealthComponent 兼容门面。
## 门面负责“先护盾、后生命”的路由，数值真实落在 `Resources/Health` 与 `Resources/Shield` 资源池。
func take_damage(raw_attack: float) -> void:
	if is_dead():
		return

	var remaining_damage: float = maxf(1.0, raw_attack - data.defense)
	health.apply_damage(remaining_damage)

## 灵力原子消耗：余额不足返回 false 且数值完全不变。
## 本方法只做资源扣除，不做冷却、目标、施法条件或技能效果校验（属于后续技能系统）。
func try_spend_spirit(amount: float) -> bool:
	if spirit_pool == null:
		return false
	return spirit_pool.try_spend(amount, &"spirit_spend")

## 灵力恢复：按上限截断，返回实际恢复量。基础池不自行再生，恢复时机由上层决定。
func restore_spirit(amount: float) -> float:
	if spirit_pool == null:
		return 0.0
	return spirit_pool.increase(amount, &"spirit_restore")

## 主动技能是否可以施放：所有条件必须先通过，失败路径不得产生任何副作用。
func can_cast_skill(skill: ActiveSkillDefinition, target: Pawn) -> bool:
	if skill == null or not skill.is_configured() or data == null:
		return false
	if not is_active_skill_enabled(skill):
		return false
	if not is_alive() or is_stunned():
		return false
	if not is_valid_skill_target(skill, target):
		return false
	if global_position.distance_to(target.global_position) > skill.get_effective_cast_range(data.attack_range):
		return false
	if not is_skill_ready(skill):
		return false
	var cost: float = skill.get_normalized_spirit_cost()
	if cost > 0.0 and (spirit_pool == null or spirit_pool.current_value < cost):
		return false
	return true

## 技能目标合法性：目标类型由技能定义唯一决定，控制器与 Pawn 最终裁决共用这一规则。
func is_valid_skill_target(skill: ActiveSkillDefinition, target: Pawn) -> bool:
	if skill == null or not skill.is_configured() or target == null or not is_instance_valid(target):
		return false
	if not target.is_alive():
		return false
	match skill.target_type:
		ActiveSkillDefinition.SkillTargetType.SELF:
			return target == self
		ActiveSkillDefinition.SkillTargetType.ALLY:
			return target != self and target.data != null and data != null and target.data.faction == data.faction
		ActiveSkillDefinition.SkillTargetType.ENEMY:
			return target.data != null and data != null and target.data.faction != data.faction
		_:
			return false

## 执行一次主动技能：本方法只做薄转发，结算顺序统一由 `SkillEffectResolver` 负责
## （目标与条件校验 → 灵力原子扣除 → 按 effect_type 应用效果 → 记录冷却并广播）。
func cast_skill(skill: ActiveSkillDefinition, target: Pawn) -> bool:
	return SkillEffectResolver.resolve(self, skill, target)


## 由 `SkillEffectResolver` 在效果生效后调用：记录冷却并广播技能结算信号。
func commit_skill_cast(skill: ActiveSkillDefinition, target: Pawn) -> void:
	var cooldown: float = skill.get_normalized_cooldown()
	if cooldown > 0.0:
		_skill_cooldowns[skill.id] = cooldown
		skill_cooldown_changed.emit(self, skill.id, cooldown)
	skill_cast.emit(self, skill, target)


## 治疗入口：经 HealthComponent 兼容门面增加生命（按上限截断，已归零单位不复活），返回实际恢复量。
func restore_health(amount: float) -> float:
	if health == null:
		return 0.0
	var before: float = current_health
	health.heal(amount)
	return maxf(current_health - before, 0.0)


## 护盾入口：按护盾上限截断，返回实际增加量；`max_shield <= 0` 时是空操作。
func grant_shield(amount: float) -> float:
	if health == null:
		return 0.0
	var before: float = current_shield
	health.grant_shield(amount)
	return maxf(current_shield - before, 0.0)


## 施加眩晕：立即停止移动并记录剩余时间；重复施加取较长剩余时间，不做叠加。
func apply_stun(duration: float) -> float:
	if not is_alive() or not is_finite(duration) or duration <= 0.0:
		return 0.0
	_stun_remaining = maxf(_stun_remaining, duration)
	stop_moving()
	stun_changed.emit(self, _stun_remaining, true)
	return _stun_remaining


func is_stunned() -> bool:
	return _stun_remaining > 0.0


func get_stun_remaining() -> float:
	return _stun_remaining


## 眩晕计时只由 `_physics_process` 推进；暂停时 Pawn 不处理物理帧，眩晕自然冻结。
func _advance_stun(delta: float) -> void:
	if delta <= 0.0 or _stun_remaining <= 0.0:
		return
	_stun_remaining = maxf(_stun_remaining - delta, 0.0)
	if _stun_remaining <= 0.0:
		stun_changed.emit(self, 0.0, false)

func is_skill_ready(skill: ActiveSkillDefinition) -> bool:
	if skill == null or not skill.is_configured():
		return false
	return get_skill_cooldown_remaining(skill.id) <= 0.0

func get_skill_cooldown_remaining(skill_id: StringName) -> float:
	if _skill_cooldowns.is_empty() or not _skill_cooldowns.has(skill_id):
		return 0.0
	return maxf(float(_skill_cooldowns[skill_id]), 0.0)

## 冷却只由 `_physics_process` 推进；暂停时 Pawn 不处理物理帧，冷却自然冻结。
func _advance_skill_cooldowns(delta: float) -> void:
	if delta <= 0.0 or _skill_cooldowns.is_empty():
		return
	for skill_id in _skill_cooldowns.keys():
		var remaining: float = float(_skill_cooldowns[skill_id])
		if remaining <= 0.0:
			continue
		var next_remaining: float = maxf(remaining - delta, 0.0)
		_skill_cooldowns[skill_id] = next_remaining
		if next_remaining <= 0.0:
			skill_cooldown_changed.emit(self, skill_id, 0.0)

## 生命状态变化的统一入口：让头顶资源条立即显示并重置整组隐藏计时。
## 数值本身仍由资源池持有，这里只触发表现层，不复制或回写任何资源数值。
func notify_health_state_changed() -> void:
	if status_bars == null:
		return
	status_bars.reveal()

func die() -> void:
	if _state == State.DEAD:
		return

	velocity = Vector2.ZERO
	set_selected(false)
	set_target_highlight(false)
	_set_state(State.DEAD)
	collision_shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	visual.modulate = Color(0.35, 0.35, 0.38, 0.72)
	notify_health_state_changed()
	died.emit(self)

func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	selection_indicator.visible = _selected


## 目标悬停高亮：`legal = false` 或单位已死亡时不显示，只有合法目标才给出可确认反馈。
## 该节点是 Pawn 自身子节点，绘制顺序低于头顶状态条与 HUD CanvasLayer（layer = 10），
## 因此不会覆盖生命条、选中框或暂停遮罩。
func set_target_highlight(value: bool, legal: bool = true) -> void:
	_target_highlight_visible = value and legal and is_alive()
	if target_indicator == null:
		return
	target_indicator.visible = _target_highlight_visible
	target_indicator.default_color = TARGET_HIGHLIGHT_LEGAL_COLOR


## 危险窗口表现：开启时染警示色，关闭时恢复该单位档案的显示色。
## 死亡单位直接忽略恢复，避免把 die() 设置的死亡配色改回存活配色。
func set_danger_highlight(active: bool) -> void:
	if is_dead() or visual == null:
		return
	if active:
		visual.modulate = DANGER_HIGHLIGHT_COLOR
		return
	if data != null:
		visual.modulate = data.display_color


func is_target_highlight_visible() -> bool:
	return _target_highlight_visible

func get_state_label() -> String:
	if is_stunned():
		return "眩晕"
	match _state:
		State.IDLE:
			return "待命"
		State.MOVING:
			return "移动"
		State.ATTACKING:
			return "攻击"
		State.DEAD:
			return "死亡"
		_:
			return "未知"

func _set_state(new_state: int) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(self, _state)

func _play_attack_pulse() -> void:
	if _visual_tween != null and _visual_tween.is_valid():
		_visual_tween.kill()
	visual.scale = Vector2(1.18, 1.18)
	_visual_tween = create_tween()
	_visual_tween.set_trans(Tween.TRANS_QUAD)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(visual, "scale", Vector2.ONE, 0.14)

## 以下转发保持 `INC-CROSS-001` 已验收的对外信号签名与发射顺序（先护盾、后生命）。
func _on_health_pool_value_changed(current_value: float, max_value: float, _delta: float, _source: StringName) -> void:
	health_changed.emit(self, current_value, max_value)
	notify_health_state_changed()

func _on_shield_pool_value_changed(current_value: float, max_value: float, _delta: float, _source: StringName) -> void:
	shield_changed.emit(self, current_value, max_value)
	notify_health_state_changed()

## 生命池归零边沿是死亡事实来源；无论变化来自 Pawn.take_damage() 还是直接操作资源池，都必须进入死亡流程。
func _on_health_pool_depleted(_pool: ResourcePoolComponent) -> void:
	die()

## 灵力变化只转发 `spirit_changed`：灵力归零不会让 Pawn 死亡，也不冒充生命状态变化。
func _on_spirit_pool_value_changed(current_value: float, max_value: float, _delta: float, _source: StringName) -> void:
	spirit_changed.emit(self, current_value, max_value)