class_name EncounterSession
extends Node

## 秘境遭遇会话（INC-WORLD-002）：把「按遭遇定义组织一场对局」的职责集中在一个节点里。
##
## 主场景不再自己持有写死的单位，也不复制敌我规则与胜负判定：
## 会话负责清场、按 PawnData 档案实例化单位、绑定控制器、判定终局并广播结果；
## 上层（Main / UI / 测试）只通过信号与 getter 取引用，不直接操作容器里的节点。

## 起局广播：上层必须在此刷新缓存的单位与控制器引用（旧单位已经退场）。
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
## 单位节点名固定，保证 Pawns/PlayerPawn 与 Pawns/EnemyPawn 两条路径始终指向当前对局。
const PLAYER_NODE_NAME: String = "PlayerPawn"
const ENEMY_NODE_NAME: String = "EnemyPawn"

## 单位容器。主场景在 .tscn 里指向 Pawns；测试可自行挂载一个容器。
@export var pawns_container: Node2D
## 玩家数据源。场景里已有玩家单位时以其数据为准（允许上层在入树前覆盖），
## 否则用本导出值，最后回落到正式玩家档案。
@export var player_data: PawnData
## 开机默认对局：保持「进入场景即可开打」的既有行为，把「默认打谁」留在世界层数据里。
@export var initial_encounter: EncounterDefinition
@export var player_spawn_position: Vector2 = Vector2(870.0, 410.0)
@export var enemy_spawn_position: Vector2 = Vector2(300.0, 250.0)

var _state: int = State.IDLE
var _encounter: EncounterDefinition
var _player: Pawn
var _enemy: Pawn
## 本会话创建的单位。退场只动自己创建的单位与两个固定名的场景默认单位，
## 不清理容器里其它单位（例如测试临时加入的友军）。
var _owned_units: Array[Pawn] = []


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


func get_player_pawn() -> Pawn:
	return _player


func get_enemy_pawn() -> Pawn:
	return _enemy


## 单位容器：优先用导出引用，否则在父节点下按 PAWNS_CONTAINER_NAME 查找。
func resolve_pawns_container() -> Node2D:
	if pawns_container != null and is_instance_valid(pawns_container):
		return pawns_container
	var parent: Node = get_parent()
	if parent == null:
		return null
	pawns_container = parent.get_node_or_null(NodePath(PAWNS_CONTAINER_NAME)) as Node2D
	return pawns_container


## 按遭遇定义起局：旧单位退场 → 新建玩家 / 敌人 → 绑定控制器 → 状态置 RUNNING。
## 任何一步不满足都返回 false，且不留下半场对局。
func begin(encounter: EncounterDefinition) -> bool:
	if encounter == null or not encounter.is_configured():
		return false
	var container: Node2D = resolve_pawns_container()
	if container == null:
		return false
	var resolved_player_data: PawnData = _resolve_player_data(container)
	if resolved_player_data == null:
		return false

	_retire_units()
	var player: Pawn = _spawn_unit(
		container, PLAYER_SCENE_PATH, PLAYER_NODE_NAME, resolved_player_data, player_spawn_position
	)
	var enemy: Pawn = _spawn_unit(
		container, ENEMY_SCENE_PATH, ENEMY_NODE_NAME, encounter.enemy_profile, enemy_spawn_position
	)
	if player == null or enemy == null:
		_retire_units()
		_state = State.IDLE
		_encounter = null
		return false

	_player = player
	_enemy = enemy
	_encounter = encounter
	_bind_controllers()
	_connect_death_signals()
	_state = State.RUNNING
	encounter_started.emit(_encounter, _player, _enemy)
	return true


## 重新挑战当前遭遇；没有当前遭遇时返回 false，不隐式开局。
func restart() -> bool:
	if _encounter == null:
		return false
	return begin(_encounter)


## 开机默认对局入口：由主场景在接线完成后调用。
func start_initial_encounter() -> bool:
	return begin(initial_encounter)


## 玩家数据源优先级：本会话上一场的单位 → 容器里既有玩家单位 → 导出数据源 → 正式档案。
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


## 控制器绑定是会话职责：玩家接 PlayerController，敌人接 AIController 并以玩家为目标。
func _bind_controllers() -> void:
	var player_controller: PlayerController = _player.get_controller() as PlayerController
	if player_controller != null:
		player_controller.bind(_player)
	var ai_controller: AIController = _enemy.get_controller() as AIController
	if ai_controller != null:
		ai_controller.bind(_enemy)
		ai_controller.set_target(_player)


func _connect_death_signals() -> void:
	if not _player.died.is_connected(_on_unit_died):
		_player.died.connect(_on_unit_died)
	if not _enemy.died.is_connected(_on_unit_died):
		_enemy.died.connect(_on_unit_died)


## 终局判定：只在 RUNNING 状态结算一次，之后重复死亡信号一律忽略。
func _on_unit_died(pawn: Pawn) -> void:
	if _state != State.RUNNING:
		return
	if pawn == _enemy:
		_state = State.PLAYER_WIN
	elif pawn == _player:
		_state = State.ENEMY_WIN
	else:
		return
	encounter_finished.emit(_encounter, _state)
