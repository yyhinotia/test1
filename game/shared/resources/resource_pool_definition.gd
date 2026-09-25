class_name ResourcePoolDefinition
extends Resource

## 资源池的静态定义。此 Resource 只描述配置，不保存任何运行时当前值。
## 业务规则（护盾优先吸收、生命死亡、灵力是否允许施法）由上层系统解释。

enum DepletedBehavior {
	NONE,
	BLOCKS_ACTIONS,
	TERMINAL,
}

@export var resource_id: StringName = &"resource"
@export var display_name: String = "Resource"
@export_range(0.0, 1000000.0, 0.1, "or_greater") var max_value: float = 100.0
@export_range(0.0, 1.0, 0.001) var initial_ratio: float = 1.0

## 仅声明是否允许自动再生；基础组件不自行 tick，具体恢复策略由上层决定。
@export var auto_regenerate: bool = false
@export var depleted_behavior: DepletedBehavior = DepletedBehavior.NONE

func get_normalized_max_value() -> float:
	return maxf(max_value, 0.0)

func get_initial_value() -> float:
	return get_normalized_max_value() * clampf(initial_ratio, 0.0, 1.0)
