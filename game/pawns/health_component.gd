class_name HealthComponent
extends Node

## 生命/护盾的兼容门面（compat facade，`INC-PAWNS-004` 起）。
##
## 设计来源：`docs/血条ui需求.txt` 的“① HealthComponent”与规则 3：
## 触发反馈的是“生命状态变化”（HealthStateChanged），而不是“掉血”（DamageTaken）。
##
## 单一数据源约定：
## - 运行时数值只存在于 `ResourcePoolComponent`：`Pawn/Resources/Health` 与 `Pawn/Resources/Shield`。
## - 本组件不再自持 current/max 字段；`current_health` / `max_health` 等属性都是资源池的只读代理。
## - 独立使用（没有绑定外部池）时，本组件会在自身节点下创建内部池，保持旧 API 与旧测试可用。
##
## 职责边界：
## - 只做“先护盾、后生命”的伤害路由与对外信号兼容；数值增减、上限截断与归零边沿由资源池负责。
## - 不接触 UI，不实现死亡表现，也不再承载灵力等非生命职责（灵力请直接使用 `ResourcePoolComponent`）。
## - `configure()` / `reset()` 属于初始化，静默生效（不触发 `health_state_changed`），
##   避免单位出生瞬间弹出头顶血条。

signal health_state_changed(component: HealthComponent)
signal health_changed(current_health: float, max_health: float)
signal shield_changed(current_shield: float, max_shield: float)
signal depleted(component: HealthComponent)

const HEALTH_RESOURCE_ID: StringName = &"health"
const SHIELD_RESOURCE_ID: StringName = &"shield"

const HEALTH_DISPLAY_NAME: String = "生命"
const SHIELD_DISPLAY_NAME: String = "护盾"

const INTERNAL_HEALTH_POOL_NAME: StringName = &"HealthPool"
const INTERNAL_SHIELD_POOL_NAME: StringName = &"ShieldPool"

var _health_pool: ResourcePoolComponent
var _shield_pool: ResourcePoolComponent
var _owns_pools: bool = false
var _depleted: bool = false
var _depleted_emitted: bool = false

var max_health: float:
	get:
		return _health_pool.max_value if _health_pool != null else 0.0

var max_shield: float:
	get:
		return _shield_pool.max_value if _shield_pool != null else 0.0

var current_health: float:
	get:
		return _health_pool.current_value if _health_pool != null else 0.0

var current_shield: float:
	get:
		return _shield_pool.current_value if _shield_pool != null else 0.0

func _ready() -> void:
	# 未绑定且未配置资源池时视为上限为 0 的归零状态（与迁移前 `_ready() → reset()` 一致）。
	_refresh_depleted_state()

func get_health_pool() -> ResourcePoolComponent:
	return _health_pool

func get_shield_pool() -> ResourcePoolComponent:
	return _shield_pool

## 是否使用外部（场景）资源池。`false` 表示本组件持有内部池（独立使用/测试路径）。
func is_using_external_pools() -> bool:
	return _health_pool != null and _shield_pool != null and not _owns_pools

## 绑定由场景提供的资源池。绑定后本组件只做路由与信号兼容，不再持有独立数值。
func bind_pools(health_pool: ResourcePoolComponent, shield_pool: ResourcePoolComponent) -> void:
	if health_pool == null or shield_pool == null:
		push_error("HealthComponent.bind_pools() 需要两个有效资源池：%s" % get_path())
		return
	if not _owns_pools and _health_pool == health_pool and _shield_pool == shield_pool:
		return

	_release_pools()
	_health_pool = health_pool
	_shield_pool = shield_pool
	_owns_pools = false
	_connect_pools()
	_refresh_depleted_state()

## 静默初始化：由 Pawn 在 `_ready()` 中用 PawnData 的静态配置调用。
func configure(new_max_health: float, new_max_shield: float) -> void:
	_ensure_pools()
	var health_max: float = maxf(new_max_health, 0.0)
	var shield_max: float = maxf(new_max_shield, 0.0)
	_health_pool.configure(_make_definition(HEALTH_RESOURCE_ID, HEALTH_DISPLAY_NAME, health_max))
	_shield_pool.configure(_make_definition(SHIELD_RESOURCE_ID, SHIELD_DISPLAY_NAME, shield_max))
	_depleted_emitted = false
	_refresh_depleted_state()

## 把运行时数值恢复到配置上限（初始化用，不发出变化信号）。
func reset() -> void:
	if _health_pool == null or _shield_pool == null:
		return
	_health_pool.reset()
	_shield_pool.reset()
	_depleted_emitted = false
	_refresh_depleted_state()

func is_depleted() -> bool:
	return _depleted

func is_alive() -> bool:
	return not _depleted and current_health > 0.0

## 扣血：先消耗护盾，再消耗生命。`amount` 应已由调用方完成防御结算。
## “先护盾、后生命”属于生命业务路由，不下沉到 `ResourcePoolComponent`。
func apply_damage(amount: float) -> void:
	if _depleted or not is_finite(amount) or amount <= 0.0:
		return
	if _health_pool == null or _shield_pool == null:
		return

	var remaining: float = amount
	if current_shield > 0.0:
		var absorbed: float = minf(current_shield, remaining)
		_shield_pool.decrease(absorbed)
		remaining -= absorbed

	if remaining > 0.0:
		_health_pool.decrease(remaining)

	_emit_state_changed()

## 治疗：按上限截断。已归零的单位不会被治疗（复活属于非范围）。
func heal(amount: float) -> void:
	if _depleted or not is_finite(amount) or amount <= 0.0 or _health_pool == null:
		return
	if _health_pool.increase(amount) <= 0.0:
		return
	_emit_state_changed()

## 增加护盾：按上限截断；`max_shield <= 0` 时是空操作。
func grant_shield(amount: float) -> void:
	if _depleted or not is_finite(amount) or amount <= 0.0 or _shield_pool == null:
		return
	if _shield_pool.increase(amount) <= 0.0:
		return
	_emit_state_changed()

func _emit_state_changed() -> void:
	health_state_changed.emit(self)
	_emit_depleted_if_needed()

func _emit_depleted_if_needed() -> void:
	if not _depleted or _depleted_emitted:
		return
	_depleted_emitted = true
	depleted.emit(self)

func _on_health_pool_value_changed(current_value: float, max_value: float, _delta: float, _source: StringName) -> void:
	_refresh_depleted_state()
	health_changed.emit(current_value, max_value)

func _on_shield_pool_value_changed(current_value: float, max_value: float, _delta: float, _source: StringName) -> void:
	_refresh_depleted_state()
	shield_changed.emit(current_value, max_value)

func _refresh_depleted_state() -> void:
	var has_pools: bool = _health_pool != null and _shield_pool != null
	_depleted = (not has_pools) or max_health <= 0.0 or current_health <= 0.0
	if not _depleted:
		_depleted_emitted = false

func _ensure_pools() -> void:
	if _health_pool != null or _shield_pool != null:
		return
	_health_pool = _create_internal_pool(INTERNAL_HEALTH_POOL_NAME)
	_shield_pool = _create_internal_pool(INTERNAL_SHIELD_POOL_NAME)
	_owns_pools = true
	_connect_pools()

func _create_internal_pool(pool_name: StringName) -> ResourcePoolComponent:
	var pool: ResourcePoolComponent = ResourcePoolComponent.new()
	pool.name = pool_name
	add_child(pool)
	return pool

func _connect_pools() -> void:
	if _health_pool != null and not _health_pool.value_changed.is_connected(_on_health_pool_value_changed):
		_health_pool.value_changed.connect(_on_health_pool_value_changed)
	if _shield_pool != null and not _shield_pool.value_changed.is_connected(_on_shield_pool_value_changed):
		_shield_pool.value_changed.connect(_on_shield_pool_value_changed)

func _release_pools() -> void:
	if _health_pool != null and is_instance_valid(_health_pool) and _health_pool.value_changed.is_connected(_on_health_pool_value_changed):
		_health_pool.value_changed.disconnect(_on_health_pool_value_changed)
	if _shield_pool != null and is_instance_valid(_shield_pool) and _shield_pool.value_changed.is_connected(_on_shield_pool_value_changed):
		_shield_pool.value_changed.disconnect(_on_shield_pool_value_changed)
	if _owns_pools:
		if _health_pool != null and is_instance_valid(_health_pool):
			_health_pool.queue_free()
		if _shield_pool != null and is_instance_valid(_shield_pool):
			_shield_pool.queue_free()
	_health_pool = null
	_shield_pool = null
	_owns_pools = false

func _make_definition(resource_id: StringName, display_name: String, max_value: float) -> ResourcePoolDefinition:
	var definition: ResourcePoolDefinition = ResourcePoolDefinition.new()
	definition.resource_id = resource_id
	definition.display_name = display_name
	definition.max_value = max_value
	definition.initial_ratio = 1.0
	return definition
