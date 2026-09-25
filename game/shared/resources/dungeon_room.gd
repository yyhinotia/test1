class_name DungeonRoom
extends Resource

## 秘境单间房的静态定义（INC-WORLD-003）。
##
## 房间只回答「这一间打谁、清空后给多少灵石、它是不是终局 Boss」，
## 不持有运行时状态、不负责推进、不做胜负判定。

@export var display_name: String = "房间"
## 本间的遭遇定义；遭遇再引用正式敌人档案，房间层不复制敌人数值。
@export var encounter: EncounterDefinition
## 清空本间后累加的灵石奖励；MVP 阶段只有一种可累加货币。
@export var reward_spirit_stones: int = 0
## 是否为秘境终局房；一个合法秘境恰好有一个 Boss 房并在最后一间。
@export var is_boss: bool = false


## 房间可直接进入：名称 / 遭遇 / 非负奖励三者齐备。
func is_configured() -> bool:
	if display_name.strip_edges().is_empty():
		return false
	if encounter == null or not encounter.is_configured():
		return false
	return reward_spirit_stones >= 0


## 对手展示名；未配置遭遇时返回空串，由 UI 决定占位文案。
func get_enemy_display_name() -> String:
	if encounter == null:
		return ""
	return encounter.get_enemy_display_name()


## 奖励的安全读取：负值按 0 处理，避免调用方拿到非法收益。
func get_reward() -> int:
	return maxi(reward_spirit_stones, 0)
