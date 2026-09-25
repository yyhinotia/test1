class_name SummonScheduler
extends RefCounted

## 召唤增援调度（INC-COMBAT-011）。
##
## 职责：按敌人静态数据中的 summon_* 字段推进固定节奏，到点后只广播「请求生成增援」，
## 不实例化节点、不复制 Pawn 规则；生成、控制器绑定与终局判定由 EncounterSession 负责。
## 与危险窗口调度器同一模式：不进入场景树，由会话按物理帧推进。

signal summon_requested(summoner: Pawn, minion_data: PawnData)

var _summoner: Pawn
var _minion_data: PawnData
var _initial_delay: float = 0.0
var _interval: float = 0.0
var _max_count: int = 0
var _spawned: int = 0
var _elapsed: float = 0.0


func _init(p_summoner: Pawn = null, p_minion_data: PawnData = null) -> void:
	_summoner = p_summoner
	_minion_data = p_minion_data
	if p_summoner != null and p_summoner.data != null:
		_initial_delay = maxf(p_summoner.data.summon_initial_delay, 0.0)
		_interval = maxf(p_summoner.data.summon_interval, 0.0)
		_max_count = maxi(p_summoner.data.summon_max_count, 0)


func is_configured() -> bool:
	return (
		_summoner != null
		and _summoner.data != null
		and _summoner.data.can_summon()
		and _minion_data != null
		and String(_minion_data.id).strip_edges() != ""
		and _minion_data.faction == &"enemy"
	)


func get_summoner() -> Pawn:
	return _summoner


func get_spawned_count() -> int:
	return _spawned


func is_exhausted() -> bool:
	return _spawned >= _max_count


## 推进计时：第一次用 initial_delay，之后用 interval；每次 advance 最多生成一个，避免大步长一次性刷满。
## 施法者死亡或数量达到上限后不再产生请求；已生成的增援不受影响。
func advance(delta: float) -> void:
	if delta <= 0.0 or not is_finite(delta) or not is_configured():
		return
	if _summoner.is_dead() or is_exhausted():
		return

	_elapsed += delta
	var wait_time: float = _initial_delay if _spawned == 0 else _interval
	if _elapsed < wait_time:
		return

	_elapsed -= wait_time
	_spawned += 1
	summon_requested.emit(_summoner, _minion_data)
