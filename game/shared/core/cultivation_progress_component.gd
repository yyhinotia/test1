class_name CultivationProgressComponent
extends Node

## 单个 Pawn 的运行时修为进度。
## 本组件只持有“当前修为 / 达到下一境界所需修为”这一对运行时数值；
## 境界链、下一境界和突破阈值全部从 RealmDefinition 读取，静态配置不写入本组件。
##
## 修为不是资源池：它没有生命/护盾那样的上限消耗语义，因此复用 ResourcePoolComponent
## 会把“达到阈值”与“归零”混为一谈。本组件保持独立边界，后续突破执行器再消费 became_ready。

signal progress_changed(component: CultivationProgressComponent, current_exp: float, required_exp: float, delta: float, source: StringName)
signal became_ready(component: CultivationProgressComponent)
signal realm_advanced(component: CultivationProgressComponent, previous_realm: RealmDefinition, new_realm: RealmDefinition)

var _realm: RealmDefinition
var _current_exp: float = 0.0
var _required_exp: float = 0.0
var _was_ready: bool = false


## 静默初始化：读取当前境界的下一境界与突破阈值，不发射进度信号。
## initial_exp 会被截断到 0..required_exp；终点境界或未配置境界一律得到 0/0。
func configure(realm: RealmDefinition, initial_exp: float = 0.0) -> void:
	_realm = realm
	_required_exp = realm.get_breakthrough_exp() if realm != null else 0.0
	if _required_exp > 0.0 and is_finite(initial_exp):
		_current_exp = clampf(initial_exp, 0.0, _required_exp)
	else:
		_current_exp = 0.0
	_was_ready = _is_ready_at(_current_exp)


## 增加修为；返回实际增加量。没有下一境界、非正数或非有限值均不产生变化。
func increase(amount: float, source: StringName = &"cultivation_gain") -> float:
	if not is_finite(amount) or amount <= 0.0:
		return 0.0
	return set_current_exp(_current_exp + amount, source)


## 设置当前修为；返回实际变化量。数值按突破阈值截断，达到阈值不会超过 required_exp。
func set_current_exp(value: float, source: StringName = &"set") -> float:
	if not is_finite(value) or _required_exp <= 0.0:
		return 0.0
	var next_value: float = clampf(value, 0.0, _required_exp)
	if is_equal_approx(next_value, _current_exp):
		return 0.0

	var previous_value: float = _current_exp
	var was_ready: bool = _was_ready
	_current_exp = next_value
	var delta: float = _current_exp - previous_value
	_was_ready = _is_ready_at(_current_exp)
	progress_changed.emit(self, _current_exp, _required_exp, delta, source)
	if not was_ready and _was_ready:
		became_ready.emit(self)
	return absf(delta)


## 突破执行：仅在 `became_ready` 条件成立时消费全部当前修为，推进到下一境界。
## 语义固定为“消耗而非结转”：新境界从 0 修为开始，避免与 set_current_exp 的阈值截断规则冲突。
## 成功时先广播 progress_changed（delta 为负的已消费修为），再广播一次 realm_advanced。
func advance_realm() -> bool:
	if not is_ready_for_breakthrough():
		return false
	var advanced_realm: RealmDefinition = get_next_realm()
	if advanced_realm == null:
		return false

	var previous_realm: RealmDefinition = _realm
	var consumed_exp: float = _current_exp
	_realm = advanced_realm
	_required_exp = _realm.get_breakthrough_exp()
	_current_exp = 0.0
	_was_ready = false

	progress_changed.emit(self, _current_exp, _required_exp, -consumed_exp, &"breakthrough")
	realm_advanced.emit(self, previous_realm, advanced_realm)
	return true

func get_realm() -> RealmDefinition:
	return _realm


func get_next_realm() -> RealmDefinition:
	return _realm.get_next_realm() if _realm != null else null


func get_current_exp() -> float:
	return _current_exp


func get_required_exp() -> float:
	return _required_exp


func get_ratio() -> float:
	if _required_exp <= 0.0:
		return 0.0
	return clampf(_current_exp / _required_exp, 0.0, 1.0)


func is_configured() -> bool:
	return _realm != null and _realm.is_configured()


func has_next_realm() -> bool:
	return is_configured() and _required_exp > 0.0 and get_next_realm() != null


func is_ready_for_breakthrough() -> bool:
	return has_next_realm() and _is_ready_at(_current_exp)


## 只读快照：UI 与测试通过它读取，不复制组件内部状态。
func get_snapshot() -> Dictionary:
	var next_realm: RealmDefinition = get_next_realm()
	return {
		"realm": _realm,
		"realm_id": _realm.id if _realm != null else &"",
		"realm_name": _realm.display_name if _realm != null else "",
		"next_realm": next_realm,
		"next_realm_id": next_realm.id if next_realm != null else &"",
		"next_realm_name": next_realm.display_name if next_realm != null else "",
		"current_exp": _current_exp,
		"required_exp": _required_exp,
		"ratio": get_ratio(),
		"has_next_realm": has_next_realm(),
		"ready": is_ready_for_breakthrough(),
	}


func _is_ready_at(value: float) -> bool:
	return _required_exp > 0.0 and value >= _required_exp