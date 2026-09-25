class_name DungeonRun
extends Node

## 秘境运行时（INC-WORLD-004）：把「一次秘境」串成房间链并持有本局收益。
##
## 职责边界：
## - EncounterSession 只判定单间对局胜负；
## - DungeonRun 只决定「还有没有下一间」「是否等待玩家抉择」「收益如何结算」；
## - 主场景 / UI 只通过信号与 getter 读取状态，不复制推进规则。
##
## 状态机：IDLE → RUNNING（当前房间对局中）→ AWAITING_DECISION（已清空非 Boss 房间）
##   → RUNNING → … → CLEARED | DEFEATED | RETREATED

## 每次进入一间房都广播一次（含第一间）；room_index 从 0 起。
signal run_started(dungeon: DungeonDefinition, room_index: int)
## 清空一间房：reward 为本间奖励，total 为本局累计收益。
signal room_cleared(dungeon: DungeonDefinition, room_index: int, reward: int, total: int)
## 本局唯一一次终局广播；earned_spirit_stones 为最终结算（DEFEATED 时为 0）。
signal run_finished(dungeon: DungeonDefinition, outcome: int, earned_spirit_stones: int)

enum State {
	IDLE,
	RUNNING,
	AWAITING_DECISION,
	CLEARED,
	DEFEATED,
	RETREATED,
}

## 单间对局的唯一执行者；由主场景 / 测试注入。
@export var encounter_session: EncounterSession
## 开机默认秘境；由主场景在初始化时读取，main.gd 不硬编码资源路径。
@export var default_dungeon: DungeonDefinition

var _state: int = State.IDLE
var _dungeon: DungeonDefinition
var _room_index: int = -1
var _earned_spirit_stones: int = 0
var _finished_emitted: bool = false


## 结算状态的唯一文案来源：主场景与面板只做转发，不重新解释结局。
static func get_outcome_label(outcome: int) -> String:
	match outcome:
		State.RUNNING:
			return "深入中"
		State.AWAITING_DECISION:
			return "等待抉择"
		State.CLEARED:
			return "已通关"
		State.DEFEATED:
			return "已阵亡"
		State.RETREATED:
			return "已撤退"
		_:
			return "未开始"


func _ready() -> void:
	_bind_encounter_session()


## 开始一次秘境：第 1 间必须满状态起局。进行中的秘境不会被静默替换。
func start(dungeon: DungeonDefinition) -> bool:
	if dungeon == null or not dungeon.is_configured():
		return false
	if is_active():
		return false
	if not _bind_encounter_session():
		return false

	_dungeon = dungeon
	_room_index = 0
	_earned_spirit_stones = 0
	_finished_emitted = false
	# 先置 RUNNING 再开局：会话的 encounter_started 同步回调里，主场景能据此识别
	# 这是「秘境中的一间」，从而锁住单场遭遇入口。
	_state = State.RUNNING
	if not _begin_room(null):
		_reset()
		return false
	run_started.emit(_dungeon, _room_index)
	return true


## 按 default_dungeon 开始一次秘境；未配置默认秘境时返回 false，不隐式创建数据。
func start_default_dungeon() -> bool:
	return start(default_dungeon)


## 继续深入：先采集当前玩家剩余资源，再按同一份 PawnData 进入下一间。
func advance() -> bool:
	if _state != State.AWAITING_DECISION or not _is_ready():
		return false
	var next_index: int = _room_index + 1
	if next_index >= _dungeon.get_room_count():
		return false

	var carried_state: PawnResourceSnapshot = encounter_session.capture_player_state()
	var previous_index: int = _room_index
	_room_index = next_index
	_state = State.RUNNING
	if not _begin_room(carried_state):
		_room_index = previous_index
		_state = State.AWAITING_DECISION
		return false
	run_started.emit(_dungeon, _room_index)
	return true


## 见好就收：保留已累积收益并结束本局，不再创建对局。
func retreat() -> bool:
	if _state != State.AWAITING_DECISION or not _is_ready():
		return false
	_state = State.RETREATED
	_emit_finished()
	return true


func get_state() -> int:
	return _state


func get_active_dungeon() -> DungeonDefinition:
	return _dungeon


func get_room_index() -> int:
	return _room_index


## 1 起的当前层数；未开始或层数非法时返回 0。
func get_depth() -> int:
	if not _is_ready():
		return 0
	return _room_index + 1


func get_room_count() -> int:
	if _dungeon == null:
		return 0
	return _dungeon.get_room_count()


func get_current_room() -> DungeonRoom:
	if not _is_ready():
		return null
	return _dungeon.get_room(_room_index)


func get_earned_spirit_stones() -> int:
	return _earned_spirit_stones


func is_awaiting_decision() -> bool:
	return _state == State.AWAITING_DECISION


## 秘境尚未结束（对局中或等待抉择）：主场景据此锁住单场遭遇入口。
func is_active() -> bool:
	return _state == State.RUNNING or _state == State.AWAITING_DECISION


func is_finished() -> bool:
	return _state == State.CLEARED or _state == State.DEFEATED or _state == State.RETREATED


## 与 EncounterSession 的终局信号接线；重复调用安全。
func _bind_encounter_session() -> bool:
	if encounter_session == null or not is_instance_valid(encounter_session):
		return false
	if not encounter_session.encounter_finished.is_connected(_on_encounter_finished):
		encounter_session.encounter_finished.connect(_on_encounter_finished)
	return true


func _is_ready() -> bool:
	if _dungeon == null or not _dungeon.is_configured():
		return false
	if _room_index < 0 or _room_index >= _dungeon.get_room_count():
		return false
	return encounter_session != null and is_instance_valid(encounter_session)


## 只负责按当前层开局；推进规则（还有没有下一间）不在这里。
func _begin_room(carried_state: PawnResourceSnapshot) -> bool:
	if not _is_ready():
		return false
	var room: DungeonRoom = _dungeon.get_room(_room_index)
	if room == null or not room.is_configured():
		return false
	return encounter_session.begin_with_state(room.encounter, carried_state)


## 单间结算：只有当前房间的胜负才被接受，迟到 / 外部遭遇的信号一律忽略。
func _on_encounter_finished(encounter: EncounterDefinition, outcome: int) -> void:
	if _state != State.RUNNING or not _is_ready():
		return
	var room: DungeonRoom = _dungeon.get_room(_room_index)
	if room == null or room.encounter != encounter:
		return

	if outcome == EncounterSession.State.ENEMY_WIN:
		# 贪的代价：战败让本局已经累积的收益全部落空。
		_state = State.DEFEATED
		_earned_spirit_stones = 0
		_emit_finished()
		return
	if outcome != EncounterSession.State.PLAYER_WIN:
		return

	var reward: int = _dungeon.get_room_reward(_room_index)
	_earned_spirit_stones += reward
	var is_final_room: bool = _room_index >= _dungeon.get_room_count() - 1
	# 先落状态再广播：room_cleared 的订阅者（面板）读到的 awaiting decision 才是本帧事实。
	_state = State.CLEARED if is_final_room else State.AWAITING_DECISION
	room_cleared.emit(_dungeon, _room_index, reward, _earned_spirit_stones)
	if is_final_room:
		_emit_finished()


func _emit_finished() -> void:
	if _finished_emitted:
		return
	_finished_emitted = true
	run_finished.emit(_dungeon, _state, _earned_spirit_stones)


func _reset() -> void:
	_state = State.IDLE
	_dungeon = null
	_room_index = -1
	_earned_spirit_stones = 0
	_finished_emitted = false
