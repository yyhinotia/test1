class_name HealthComponent
extends Node

## Pawn 的生命/护盾运行时数据源（单一数据源）。
## 设计来源：`docs/血条ui需求.txt` 的“① HealthComponent”与规则 3：
## 触发反馈的是“生命状态变化”（HealthStateChanged），而不是“掉血”（DamageTaken）。
##
## 职责边界：
## - 只维护数值并发出变化信号；不计算伤害公式、不处理死亡表现、不接触 UI。
## - 护盾先于生命被扣除；生命归零时只发出一次 `depleted`。
## - `configure()` / `reset()` 属于初始化，静默生效（不触发 `health_state_changed`），
##   避免单位出生瞬间弹出头顶血条。

signal health_state_changed(component: HealthComponent)
signal health_changed(current_health: float, max_health: float)
signal shield_changed(current_shield: float, max_shield: float)
signal depleted(component: HealthComponent)

@export var max_health: float = 100.0
@export var max_shield: float = 0.0

var current_health: float = 0.0
var current_shield: float = 0.0

var _depleted: bool = false

func _ready() -> void:
	reset()

## 静默初始化：由 Pawn 在 `_ready()` 中用 PawnData 的静态配置调用。
func configure(new_max_health: float, new_max_shield: float) -> void:
	max_health = maxf(new_max_health, 0.0)
	max_shield = maxf(new_max_shield, 0.0)
	reset()

## 把运行时数值恢复到配置上限（初始化用，不发出变化信号）。
func reset() -> void:
	current_health = max_health
	current_shield = max_shield
	_depleted = max_health <= 0.0

func is_depleted() -> bool:
	return _depleted

func is_alive() -> bool:
	return not _depleted and current_health > 0.0

## 扣血：先消耗护盾，再消耗生命。`amount` 应已由调用方完成防御结算。
func apply_damage(amount: float) -> void:
	if _depleted or amount <= 0.0:
		return

	var remaining: float = amount
	if current_shield > 0.0:
		var absorbed: float = minf(current_shield, remaining)
		current_shield -= absorbed
		remaining -= absorbed
		shield_changed.emit(current_shield, max_shield)

	if remaining > 0.0:
		current_health = maxf(current_health - remaining, 0.0)
		health_changed.emit(current_health, max_health)

	_emit_state_changed()

## 治疗：按上限截断。已归零的单位不会被治疗（复活属于非范围）。
func heal(amount: float) -> void:
	if _depleted or amount <= 0.0:
		return

	var previous_health: float = current_health
	current_health = minf(current_health + amount, max_health)
	if is_equal_approx(previous_health, current_health):
		return

	health_changed.emit(current_health, max_health)
	_emit_state_changed()

## 增加护盾：按上限截断；`max_shield <= 0` 时是空操作。
func grant_shield(amount: float) -> void:
	if _depleted or amount <= 0.0:
		return

	var previous_shield: float = current_shield
	current_shield = minf(current_shield + amount, max_shield)
	if is_equal_approx(previous_shield, current_shield):
		return

	shield_changed.emit(current_shield, max_shield)
	_emit_state_changed()

func _emit_state_changed() -> void:
	health_state_changed.emit(self)
	if current_health <= 0.0 and not _depleted:
		_depleted = true
		depleted.emit(self)