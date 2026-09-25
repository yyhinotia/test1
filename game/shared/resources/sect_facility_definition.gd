class_name SectFacilityDefinition
extends Resource

## 宗门设施静态定义（INC-SECT-001）：回答「这座设施是什么、能升到几级、升级要多少灵石、
## 单次转化消耗什么、每级产出多少」。
##
## 本资源不持有任何运行时数值：设施等级、库存在 `SectState` 里，本类只提供只读的数值派生规则。
## 六座设施（洞府 / 聚灵阵 / 灵田 / 丹房 / 炼器房 / 藏经阁）来自 `docs/project_summary.md` §十八 ⑤，
## 本类不引入人口、食物、住房、满意度等 Colony Sim 概念。

enum FacilityKind {
	CAVE_DWELLING,      ## 洞府：修炼场所，决定打坐的修为效率倍率
	SPIRIT_ARRAY,       ## 聚灵阵：每次打坐产出的修为来源
	SPIRIT_FIELD,       ## 灵田：收获灵草
	ALCHEMY_ROOM,       ## 丹房：灵草 → 丹药
	FORGE_ROOM,         ## 炼器房：灵石 → 武器强化等级
	SCRIPTURE_PAVILION, ## 藏经阁：灵石 → 参悟新功法
}

## 设施类别的唯一顺序来源：面板、校验与测试都按此顺序遍历，避免各处各自维护顺序。
const ALL_KINDS: Array[int] = [
	FacilityKind.CAVE_DWELLING,
	FacilityKind.SPIRIT_ARRAY,
	FacilityKind.SPIRIT_FIELD,
	FacilityKind.ALCHEMY_ROOM,
	FacilityKind.FORGE_ROOM,
	FacilityKind.SCRIPTURE_PAVILION,
]

## 升级花费的不可用哨兵：负数表示「该等级不能升级」（越界或已满级）。
const UPGRADE_COST_UNAVAILABLE: int = -1

@export var id: StringName = &"facility"
@export var display_name: String = "设施"
@export var kind: FacilityKind = FacilityKind.CAVE_DWELLING
@export_multiline var description: String = ""
## 从 0 级升到 1 级的灵石花费；实际花费随等级线性递增。
@export_range(0, 1000000, 1, "or_greater") var base_upgrade_cost: int = 10
## 每高一级额外增加的灵石花费。
@export_range(0, 1000000, 1, "or_greater") var upgrade_cost_growth: int = 5
## 等级上限；等级从 1 起算，1 表示已建成但未强化。
@export_range(1, 100, 1, "or_greater") var max_level: int = 3
## 修士需要达到的最低境界 tier 才能升级本设施；1 表示炼气期即可。
@export_range(1, 100, 1, "or_greater") var required_realm_tier: int = 1
## 单次转化消耗的灵石（藏经阁参悟 / 炼器房强化）；0 表示该设施不消耗灵石。
@export_range(0, 1000000, 1, "or_greater") var spirit_stone_cost: int = 0
## 单次转化消耗的灵草（丹房炼丹）；0 表示该设施不消耗灵草。
@export_range(0, 1000000, 1, "or_greater") var herb_cost: int = 0
## 每级产出：聚灵阵 = 每次打坐修为、灵田 = 每次收获灵草、丹房 = 每次炼丹丹药数。
## 洞府 = 0（它的作用是打坐效率倍率，不是直接产出），炼器房 / 藏经阁 = 1（每次转化一份）。
@export_range(0, 1000000, 1, "or_greater") var yield_per_level: int = 1

## 设施可直接使用：至少要有 id 与显示名，否则面板与库存都会出现无名条目。
func is_configured() -> bool:
	if String(id).strip_edges().is_empty():
		return false
	return not display_name.strip_edges().is_empty()


## 从 `level` 级升到 `level + 1` 级需要的灵石；越界或已满级返回 `UPGRADE_COST_UNAVAILABLE`。
func get_upgrade_cost(level: int) -> int:
	if not can_upgrade(level):
		return UPGRADE_COST_UNAVAILABLE
	return maxi(base_upgrade_cost, 0) + maxi(upgrade_cost_growth, 0) * level


## 该等级还能不能升级：负数与已满级都不可升级。
func can_upgrade(level: int) -> bool:
	return level >= 0 and level < maxi(max_level, 1)


## 该等级的实际产出；负等级按 0 截断，负产出配置同样按 0 处理。
func get_yield(level: int) -> int:
	return maxi(level, 0) * maxi(yield_per_level, 0)


## 设施类别的中文标签；未知取值回退为占位文案，不返回空串。
func get_kind_label() -> String:
	return kind_label(kind)


## 类别标签唯一来源：面板、日志与测试都通过它取文案。
static func kind_label(kind_value: int) -> String:
	match kind_value:
		FacilityKind.CAVE_DWELLING:
			return "洞府"
		FacilityKind.SPIRIT_ARRAY:
			return "聚灵阵"
		FacilityKind.SPIRIT_FIELD:
			return "灵田"
		FacilityKind.ALCHEMY_ROOM:
			return "丹房"
		FacilityKind.FORGE_ROOM:
			return "炼器房"
		FacilityKind.SCRIPTURE_PAVILION:
			return "藏经阁"
		_:
			return "未知设施"
