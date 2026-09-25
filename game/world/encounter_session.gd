class_name EncounterSession
extends Node

## 秘境遭遇会话（INC-WORLD-002；INC-PAWNS-020 扩展为多人队伍）。
##
## 主场景不再自己持有写死的单位，也不复制敌我规则与胜负判定：
## 会话负责清场、按遭遇定义与队伍档案实例化单位、绑定控制器、判定终局并广播结果；
## 上层（Main / UI / 测试）只通过信号与 getter 取引用，不直接操作容器里的节点。
##
## 多人边界：本 Increment 只把「一支队伍」变成真实单位集合与按成员 id 的快照。
## INC-COMBAT-009 已接线「敌方全灭才胜利、玩家单位全部死亡即失败」与轻量 CombatEvent；
## AI 目标重选仍保持既有实现，玩家多选与命令路由属于 INC-CORE-012。

## 起局广播：上层必须在此刷新缓存的单位与控制器引用（旧单位已经退场）。
## 多人对局下 player / enemy 是各自队伍的主单位，完整队伍用 get_player_units() / get_enemy_units()。
signal encounter_started(encounter: EncounterDefinition, player: Pawn, enemy: Pawn)
## 终局广播：一场对局只会广播一次；重复死亡信号被忽略。
signal encounter_finished(encounter: EncounterDefinition, outcome: int)

enum State {
	IDLE,
	RUNNING,
	PLAYER_WIN,
	ENEMY_WIN,
}

const PLAYER_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"
const DEFAULT_PLAYER_DATA_PATH: String = "res://game/pawns/data/player_pawn.tres"
## 单位容器名：未显式指定 pawns_container 时，在父节点下按此名查找。
const PAWNS_CONTAINER_NAME: String = "Pawns"
## 主单位节点名固定，保证 Pawns/PlayerPawn 与 Pawns/EnemyPawn 两条路径始终指向当前对局的主单位。
const PLAYER_NODE_NAME: String = "PlayerPawn"
const ENEMY_NODE_NAME: String = "EnemyPawn"
## 第 2 名成员起的节点名（1 基序号后缀，与上阵序号一致）：PlayerPawn_2 … PlayerPawn_4。
const PLAYER_UNIT_NAME_FORMAT: String = "PlayerPawn_%d"
const ENEMY_UNIT_NAME_FORMAT: String = "EnemyPawn_%d"

## 单位容器。主场景在 .tscn 里指向 Pawns；测试可自行挂载一个容器。
@export var pawns_container: Node2D
## 玩家数据源。场景里已有玩家单位时以其数据为准（允许上层在入树前覆盖），
## 否则用本导出值，最后回落到正式玩家档案。
@export var player_data: PawnData
## 可选玩家队伍档案：配置完成时按遭遇要求的上阵人数取前 N 人。
## 第 0 位是主角槽位，由 `_resolve_player_data()` 的运行时档案填充，保证运行时进度与测试注入不被队伍资源吞掉。
@export var player_squad: SquadDefinition
## 开机默认对局：保持「进入场景即可开打」的既有行为，把「默认打谁」留在世界层数据里。
@export var initial_encounter: EncounterDefinition
@export var player_spawn_position: Vector2 = Vector2(870.0, 410.0)
@export var enemy_spawn_position: Vector2 = Vector2(300.0, 250.0)

var _state: int = State.IDLE
var _encounter: EncounterDefinition
## 主玩家 / 主敌人：旧 API 与既有调用方的代理，始终指向各自队伍的第 0 位。
var _player: Pawn
var _enemy: Pawn
## 本场对局的完整队伍（有序）。`_player` / `_enemy` 分别是两份数组的第 0 位。
var _player_units: Array[Pawn] = []
var _enemy_units: Array[Pawn] = []
## 本会话创建的单位。退场只动自己创建的单位与两个固定名的场景默认单位，
## 不清理容器里其它单位（例如测试临时加入的友军）。
var _owned_units: Array[Pawn] = []
## 本场轻量战斗事件记录；每局 begin_with_state() 时重置，不跨局污染（INC-COMBAT-009）。
var _combat_event_log: CombatEventLog = CombatEventLog.new()
## 危险窗口调度器（每个配置了 dangerous_skill 的敌人一个）；RefCounted，不进入场景树。
var _danger_schedulers: Array[DangerWindowScheduler] = []


## 结算状态的唯一文案来源：上层只做转发，不在 UI 里重新解释结算结果。
static func get_outcome_label(outcome: int) -> String:
	match outcome:
		State.RUNNING:
			return "进行中"
		State.PLAYER_WIN:
			return "胜利"
		State.ENEMY_WIN:
			return "失败"
		_:
			return "未开始"


func get_state() -> int:
	return _state


func is_running() -> bool:
	return _state == State.RUNNING


func get_active_encounter() -> EncounterDefinition:
	return _encounter


## 主玩家单位（玩家队伍第 0 位）；未开局时返回 null。
func get_player_pawn() -> Pawn:
	return _player


## 主敌人单位（敌方队伍第 0 位）；未开局时返回 null。
func get_enemy_pawn() -> Pawn:
	return _enemy


## 本场对局的完整玩家队伍（有序副本）。调用方不得据此持有跨对局引用。
func get_player_units() -> Array[Pawn]:
	return _player_units.duplicate()


## 本场对局的完整敌方队伍（有序副本）。
func get_enemy_units() -> Array[Pawn]:
	return _enemy_units.duplicate()


func get_player_unit_count() -> int:
	return _player_units.size()


func get_enemy_unit_count() -> int:
	return _enemy_units.size()


## 按成员 id（PawnData.id）取玩家队伍成员；未命中返回 null。
func get_player_unit_by_id(member_id: StringName) -> Pawn:
	return _find_unit_by_id(_player_units, member_id)


## 按成员 id（PawnData.id）取敌方队伍成员；未命中返回 null。
func get_enemy_unit_by_id(member_id: StringName) -> Pawn:
	return _find_unit_by_id(_enemy_units, member_id)


## 单位容器：优先用导出引用，否则在父节点下按 PAWNS_CONTAINER_NAME 查找。
func resolve_pawns_container() -> Node2D:
	if pawns_container != null and is_instance_valid(pawns_container):
		return pawns_container
	var parent: Node = get_parent()
	if parent == null:
		return null
	pawns_container = parent.get_node_or_null(NodePath(PAWNS_CONTAINER_NAME)) as Node2D
	return pawns_container


## 按遭遇定义起局（INC-WORLD-002 语义保持不变）：等价于 begin_with_state(encounter, null)。
func begin(encounter: EncounterDefinition) -> bool:
	return begin_with_state(encounter, null)


## 按遭遇定义起局：旧单位退场 → 新建双方队伍 → 绑定控制器 → 写回跨房间资源 → 状态置 RUNNING。
## state 为 null 时与 begin() 完全等价；非 null 时在新单位 _ready() 初始化资源池之后写回主玩家单位，
## 使「继续深入」携带上一间的损耗。任何一步不满足都返回 false，且不留下半场对局。
func begin_with_state(encounter: EncounterDefinition, state: PawnResourceSnapshot) -> bool:
	if encounter == null or not encounter.is_configured():
		return false
	var container: Node2D = resolve_pawns_container()
	if container == null:
		return false
	var resolved_player_data: PawnData = _resolve_player_data(container)
	if resolved_player_data == null:
		return false

	# 运行时进度必须在退场前采集：旧单位一旦退场，覆盖层与修为随节点一起释放。
	var carried_progress: Dictionary = _capture_player_progress()
	_retire_units()

	var player_members: Array[PawnData] = _resolve_player_members(encounter, resolved_player_data)
	var enemy_members: Array[PawnData] = encounter.get_enemy_members()
	var players: Array[Pawn] = _spawn_units(
		container,
		PLAYER_SCENE_PATH,
		PLAYER_NODE_NAME,
		PLAYER_UNIT_NAME_FORMAT,
		player_members,
		player_spawn_position,
		_resolve_player_offsets(player_members)
	)
	var enemies: Array[Pawn] = _spawn_units(
		container,
		ENEMY_SCENE_PATH,
		ENEMY_NODE_NAME,
		ENEMY_UNIT_NAME_FORMAT,
		enemy_members,
		enemy_spawn_position,
		encounter.get_enemy_spawn_offsets()
	)
	if players.is_empty() or enemies.is_empty():
		_retire_units()
		_state = State.IDLE
		_encounter = null
		return false
	if players.size() != player_members.size() or enemies.size() != enemy_members.size():
		# 有成员实例化失败：整场作废，不留下人数不齐的对局。
		_retire_units()
		_state = State.IDLE
		_encounter = null
		return false

	_player_units = players
	_enemy_units = enemies
	_player = players[0]
	_enemy = enemies[0]
	_encounter = encounter
	_bind_controllers()
	_connect_combat_signals()
	_setup_combat_events()
	if state != null:
		# 必须在入树且 _ready() 初始化资源池之后写回，否则会被档案初始值覆盖。
		# 单人资源快照只作用于主玩家单位；队伍级资源延续由 SquadResourceSnapshot 负责（INC-WORLD-007 接线）。
		state.apply_to(_player)
		if not _player.is_alive():
			# 快照本身已是死亡状态：拒绝开出一场无法正常结算的对局。
			_retire_units()
			_state = State.IDLE
			_encounter = null
			return false
	# 运行时进度与资源快照分开：资源是否延续由 state 决定，本代修士的 Build / 修为始终延续。
	# 队友使用固定档案、不进入长期养成，因此进度只写回主角槽位。
	_apply_player_progress(_player, carried_progress)
	_state = State.RUNNING
	encounter_started.emit(_encounter, _player, _enemy)
	return true


## 采集当前主玩家单位的全部资源池，供 DungeonRun 跨房间延续（INC-WORLD-004）。
func capture_player_state() -> PawnResourceSnapshot:
	return PawnResourceSnapshot.capture(_player)


## 采集当前玩家队伍的完整资源快照（按成员 id），供后续队伍级跨房间延续使用。
func capture_squad_state() -> SquadResourceSnapshot:
	return SquadResourceSnapshot.capture(_player_units)


## 把队伍资源快照按成员 id 写回；缺成员跳过，返回成功写回的成员数量。
func apply_squad_state(snapshot: SquadResourceSnapshot) -> int:
	if snapshot == null:
		return 0
	return snapshot.apply_to(_player_units)


## 采集当前玩家队伍的运行时进度（按成员 id）。
func capture_squad_progress() -> SquadProgressSnapshot:
	return SquadProgressSnapshot.capture(_player_units)


## 把队伍运行时进度按成员 id 写回；缺成员跳过，返回成功写回的成员数量。
func apply_squad_progress(snapshot: SquadProgressSnapshot) -> int:
	if snapshot == null:
		return 0
	return snapshot.apply_to(_player_units)


## 采集主玩家单位的运行时进度（INC-WORLD-005 / INC-WORLD-006）：
## 强化等级、运行时领悟功法、当前运行时境界与境界内修为。
## 与 `capture_player_state()` 的资源快照分开：资源快照由调用方决定是否延续，
## 运行时进度属于同一代修士的身份，换房与重新开局都必须延续；空单位返回空字典。
func _capture_player_progress() -> Dictionary:
	return SquadProgressSnapshot.capture_progress(_player)


## 写回主玩家单位的运行时进度。实现委托给 SquadProgressSnapshot，保证队伍路径与单人路径只有一份规则。
func _apply_player_progress(player: Pawn, progress: Dictionary) -> void:
	SquadProgressSnapshot.apply_progress(player, progress)


## 重新挑战当前遭遇；没有当前遭遇时返回 false，不隐式开局。
func restart() -> bool:
	if _encounter == null:
		return false
	return begin(_encounter)


## 开机默认对局入口：由主场景在接线完成后调用。
func start_initial_encounter() -> bool:
	return begin(initial_encounter)


## 玩家数据源优先级：本会话上一场的主单位 → 容器里既有玩家单位 → 导出数据源 → 正式档案。
## 保留「既有单位数据优先」是为了让上层（含测试）能在入树前覆盖玩家配置而不被换局丢掉。
func _resolve_player_data(container: Node2D) -> PawnData:
	if _player != null and is_instance_valid(_player) and _player.data != null:
		return _player.data
	var existing: Pawn = container.get_node_or_null(NodePath(PLAYER_NODE_NAME)) as Pawn
	if existing != null and existing.data != null:
		return existing.data
	if player_data != null:
		return player_data
	return load(DEFAULT_PLAYER_DATA_PATH) as PawnData


## 玩家上阵成员：没有可用队伍档案时保持旧行为（单主角）；有队伍时按遭遇要求的人数取前 N 人，
## 并把第 0 位替换为运行时解析出的玩家档案（主角身份与运行时进度不因队伍资源而改变）。
func _resolve_player_members(encounter: EncounterDefinition, resolved_player_data: PawnData) -> Array[PawnData]:
	var members: Array[PawnData] = []
	if player_squad == null or not player_squad.is_configured():
		if resolved_player_data != null:
			members.append(resolved_player_data)
		return members
	members = player_squad.get_member_slice(encounter.get_requested_player_count())
	if members.is_empty():
		return members
	if resolved_player_data != null:
		members[0] = resolved_player_data
	return members


## 玩家站位：队伍显式站位的对应前缀优先，否则按实际上阵人数生成安全默认阵型。
func _resolve_player_offsets(members: Array[PawnData]) -> Array[Vector2]:
	if members.is_empty():
		return []
	if player_squad != null and player_squad.is_configured():
		var squad_offsets: Array[Vector2] = player_squad.get_spawn_offsets()
		if squad_offsets.size() >= members.size():
			return squad_offsets.slice(0, members.size())
	return SquadDefinition.build_default_offsets(members.size())


## 按成员档案实例化一支队伍：data 必须在入树前赋值，Pawn._ready() 才会按新档案建池。
## 第 0 位沿用主单位节点名（保持 Pawns/PlayerPawn 等既有路径），其余成员用 1 基序号后缀。
func _spawn_units(
		container: Node2D,
		scene_path: String,
		primary_name: String,
		name_format: String,
		members: Array[PawnData],
		base_position: Vector2,
		offsets: Array[Vector2]
	) -> Array[Pawn]:
	var units: Array[Pawn] = []
	for index: int in range(members.size()):
		var unit_data: PawnData = members[index]
		if unit_data == null:
			continue
		var node_name: String = primary_name if index == 0 else name_format % (index + 1)
		var unit: Pawn = _spawn_unit(
			container, scene_path, node_name, unit_data, base_position + _offset_at(offsets, index)
		)
		if unit == null:
			continue
		units.append(unit)
	return units


## 实例化单个单位：data 必须在入树前赋值，Pawn._ready() 才会按新档案建池。
func _spawn_unit(
		container: Node2D,
		scene_path: String,
		node_name: String,
		unit_data: PawnData,
		spawn_position: Vector2
	) -> Pawn:
	if unit_data == null:
		return null
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return null
	var unit: Pawn = scene.instantiate() as Pawn
	if unit == null:
		return null
	unit.name = node_name
	unit.data = unit_data
	container.add_child(unit)
	unit.global_position = spawn_position
	_owned_units.append(unit)
	return unit


## 站位取值：下标越界时回落到原点，绝不隐式扩展数组。
static func _offset_at(offsets: Array[Vector2], index: int) -> Vector2:
	if index >= 0 and index < offsets.size():
		return offsets[index]
	return Vector2.ZERO


## 按成员 id 在给定队伍里查找单位；空 id 一律视为未命中。
static func _find_unit_by_id(units: Array[Pawn], member_id: StringName) -> Pawn:
	if member_id == &"":
		return null
	for unit: Pawn in units:
		if unit == null or not is_instance_valid(unit) or unit.data == null:
			continue
		if unit.data.id == member_id:
			return unit
	return null


## 旧单位退场：先从容器移除再 queue_free。
## 先移除是必须的——否则新建的同名单位会被 Godot 改名，Pawns/PlayerPawn 等既有路径会指向正在销毁的旧单位。
func _retire_units() -> void:
	var retired: Array[Pawn] = []
	for unit: Pawn in _owned_units:
		if is_instance_valid(unit):
			retired.append(unit)
	_owned_units.clear()
	var container: Node2D = resolve_pawns_container()
	if container != null:
		for node_name: String in [PLAYER_NODE_NAME, ENEMY_NODE_NAME]:
			var existing: Pawn = container.get_node_or_null(NodePath(node_name)) as Pawn
			if existing != null and not retired.has(existing):
				retired.append(existing)
	for unit: Pawn in retired:
		var parent: Node = unit.get_parent()
		if parent != null:
			parent.remove_child(unit)
		# 退场单位先寄存在会话下再销毁：既不占用 Pawns 容器里的固定路径，
		# 又不会变成脱离场景树的孤儿节点（脱离树的节点在测试里会被判定为泄漏，
		# 而且在同一帧内仍被 HUD / 技能栏引用，必须保持有效直到引用被刷新）。
		unit.set_physics_process(false)
		unit.set_process(false)
		add_child(unit)
		unit.queue_free()
	_player = null
	_enemy = null
	_player_units.clear()
	_enemy_units.clear()


## 控制器绑定是会话职责：玩家队伍接 PlayerController，敌方队伍接 AIController。
## 目标选择属于 INC-COMBAT-009：本 Increment 保持「每名敌人以主玩家单位为目标」的既有行为。
func _bind_controllers() -> void:
	for unit: Pawn in _player_units:
		var player_controller: PlayerController = unit.get_controller() as PlayerController
		if player_controller != null:
			player_controller.bind(unit)
	for unit: Pawn in _enemy_units:
		var ai_controller: AIController = unit.get_controller() as AIController
		if ai_controller != null:
			ai_controller.bind(unit)
			ai_controller.set_target(_player)


func _connect_combat_signals() -> void:
	for unit: Pawn in _player_units + _enemy_units:
		if not unit.died.is_connected(_on_unit_died):
			unit.died.connect(_on_unit_died)
		if not unit.skill_cast.is_connected(_on_pawn_skill_cast):
			unit.skill_cast.connect(_on_pawn_skill_cast)


## 每局开局清空事件记录，并为每个拥有危险窗口的敌人创建独立调度器。
## 调度器只由本会话持有并按物理帧推进；旧调度器随数组清空自然释放。
func _setup_combat_events() -> void:
	_combat_event_log.reset()
	_danger_schedulers.clear()
	for enemy: Pawn in _enemy_units:
		if enemy == null or not is_instance_valid(enemy) or enemy.data == null:
			continue
		if not enemy.data.has_danger_window():
			continue
		var scheduler: DangerWindowScheduler = DangerWindowScheduler.new(enemy, _player)
		scheduler.danger_window_opened.connect(_on_danger_window_opened)
		scheduler.danger_window_cancelled_by_stun.connect(_on_danger_window_cancelled_by_stun)
		scheduler.dangerous_skill_released.connect(_on_dangerous_skill_released)
		_danger_schedulers.append(scheduler)


## 事件与危险窗口只在对局 RUNNING 时推进；暂停由场景树的 process_mode 统一冻结。
func _physics_process(delta: float) -> void:
	if _state != State.RUNNING:
		return
	_combat_event_log.advance(delta)
	for scheduler: DangerWindowScheduler in _danger_schedulers:
		if scheduler != null:
			scheduler.advance(delta)


## 供测试与 INC-TESTING-011 取证使用；返回的是活日志对象，不复制到另一套记录系统。
func get_combat_event_log() -> CombatEventLog:
	return _combat_event_log


func _on_pawn_skill_cast(pawn: Pawn, skill: ActiveSkillDefinition, target: Pawn) -> void:
	var actor_id: StringName = _unit_id(pawn)
	var target_id: StringName = _unit_id(target)
	var skill_id: StringName = skill.id if skill != null else &""
	_combat_event_log.record(CombatEvent.SKILL_CAST, actor_id, target_id, skill_id)
	if skill != null and skill.effect_type == ActiveSkillDefinition.SkillEffectType.STUN:
		_combat_event_log.record(CombatEvent.SKILL_STUNNED, actor_id, target_id, skill_id)


func _on_danger_window_opened(caster: Pawn, skill: ActiveSkillDefinition, target: Pawn) -> void:
	var skill_id: StringName = skill.id if skill != null else &""
	_combat_event_log.record(
		CombatEvent.DANGER_WINDOW_OPENED, _unit_id(caster), _unit_id(target), skill_id
	)


func _on_danger_window_cancelled_by_stun(caster: Pawn, skill: ActiveSkillDefinition, target: Pawn) -> void:
	var skill_id: StringName = skill.id if skill != null else &""
	_combat_event_log.record(
		CombatEvent.SKILL_CANCELLED, _unit_id(caster), _unit_id(target), skill_id
	)


func _on_dangerous_skill_released(
		caster: Pawn,
		skill: ActiveSkillDefinition,
		target: Pawn,
		blocked: bool
	) -> void:
	var actor_id: StringName = _unit_id(caster)
	var target_id: StringName = _unit_id(target)
	var skill_id: StringName = skill.id if skill != null else &""
	_combat_event_log.record(CombatEvent.SKILL_CAST, actor_id, target_id, skill_id)
	var impact_event: StringName = CombatEvent.SKILL_BLOCKED if blocked else CombatEvent.SKILL_HIT
	_combat_event_log.record(impact_event, actor_id, target_id, skill_id)


## 终局判定：只在 RUNNING 状态结算一次，之后重复死亡信号一律忽略。
## INC-COMBAT-009 语义：主玩家死亡立即失败（1v1 / 1vN 的玩家侧只有 1 个单位）；
## 敌方单位全部死亡才胜利，副敌人在 1v2 / 1v3 中单独死亡不得提前终局。
func _on_unit_died(pawn: Pawn) -> void:
	if _state != State.RUNNING:
		return
	_combat_event_log.record(CombatEvent.UNIT_DIED, _unit_id(pawn))
	if pawn == _player or _all_units_dead(_player_units):
		_state = State.ENEMY_WIN
	elif _all_units_dead(_enemy_units):
		_state = State.PLAYER_WIN
		_grant_first_clear_reward()
	else:
		return
	_combat_event_log.record(CombatEvent.COMBAT_END, &"session")
	encounter_finished.emit(_encounter, _state)


## 首通奖励发放（INC-WORLD-007）：只在玩家获胜时按遭遇定义解锁技能。
## 「是否已发放」不额外记账——已掌握技能列表本身就是账本：重复通关时 learn_active_skill() 按 id 去重返回 false，
## 因此不会重复发放；解锁结果随运行时进度（SquadProgressSnapshot）跨局延续。
## 本方法只解锁，绝不自动装配 Build：Gate C 要求「解锁」与「装配」是玩家可见的两步。
func _grant_first_clear_reward() -> void:
	if _encounter == null or not _encounter.has_first_clear_reward():
		return
	if _player == null or not is_instance_valid(_player):
		return
	_player.learn_active_skill(_encounter.first_clear_skill_reward)


func _all_units_dead(units: Array[Pawn]) -> bool:
	if units.is_empty():
		return false
	for unit: Pawn in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive():
			return false
	return true


func _unit_id(unit: Pawn) -> StringName:
	if unit == null or not is_instance_valid(unit) or unit.data == null:
		return &""
	return unit.data.id
