class_name WeaponDefinition
extends Resource

## 武器静态配置：回答“这把武器是什么类型、属于什么五行、需要什么境界”。
## 本资源不参与战斗结算与属性计算，只作为 Build 校验与信息卡展示的唯一数据来源；
## 武器数值、特效、掉落与装备流程属于后续 Increment。

const ELEMENT_METAL: StringName = &"metal"
const ELEMENT_WOOD: StringName = &"wood"
const ELEMENT_WATER: StringName = &"water"
const ELEMENT_FIRE: StringName = &"fire"
const ELEMENT_EARTH: StringName = &"earth"
## 五行顺序的唯一来源：标签映射与成员判定都从这里派生，避免多处各写一份列表。
const ALL_ELEMENTS: Array[StringName] = [
	ELEMENT_METAL,
	ELEMENT_WOOD,
	ELEMENT_WATER,
	ELEMENT_FIRE,
	ELEMENT_EARTH,
]

const TYPE_SWORD: StringName = &"sword"
const TYPE_ARTIFACT: StringName = &"artifact"
const TYPE_BLADE: StringName = &"blade"

## 显示层标签：五行与武器类型的中文文案只在这里维护一份，数据资源只存标识。
const ELEMENT_LABELS: Dictionary = {
	ELEMENT_METAL: "金",
	ELEMENT_WOOD: "木",
	ELEMENT_WATER: "水",
	ELEMENT_FIRE: "火",
	ELEMENT_EARTH: "土",
}

const TYPE_LABELS: Dictionary = {
	TYPE_SWORD: "剑",
	TYPE_ARTIFACT: "法器",
	TYPE_BLADE: "刀",
}

const UNKNOWN_ELEMENT_TEXT: String = "无属性"
const UNKNOWN_TYPE_TEXT: String = "未分类"

@export var id: StringName = &"weapon"
@export var display_name: String = "武器"
## 武器类型标识（sword / artifact / blade）；未知标识只影响显示文案，不参与校验。
@export var weapon_type: StringName = TYPE_SWORD
## 五行标识；留空表示这把武器没有五行属性（例如凡铁），不参与后续五行相容判定。
@export var element: StringName = &""
## 装备所需的最低境界 tier；语义与功法 / 被动一致，1 表示炼气期即可装备。
@export_range(1, 100, 1, "or_greater") var required_realm_tier: int = 1
@export var description: String = ""


func is_configured() -> bool:
	return not String(id).strip_edges().is_empty()


## 是否配置了合法五行；空值或未知标识都返回 false，调用方可据此决定是否显示五行标签。
func has_element() -> bool:
	return ALL_ELEMENTS.has(element)


func get_element_label() -> String:
	return element_label(element)


func get_type_label() -> String:
	return type_label(weapon_type)


## 五行标签的唯一来源；未知或空标识返回占位文案而不是空串，避免 UI 出现空白标签。
static func element_label(value: StringName) -> String:
	return String(ELEMENT_LABELS.get(value, UNKNOWN_ELEMENT_TEXT))


## 类型标签：已知类型返回中文；未知但非空时回退为原标识，完全为空时返回占位。
static func type_label(value: StringName) -> String:
	var known: String = String(TYPE_LABELS.get(value, ""))
	if not known.is_empty():
		return known
	var trimmed: String = String(value).strip_edges()
	if trimmed.is_empty():
		return UNKNOWN_TYPE_TEXT
	return trimmed