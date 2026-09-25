class_name EncounterDefinition
extends Resource

## 秘境遭遇的静态定义（INC-WORLD-001；INC-PAWNS-020 扩展多人对手）。
##
## 本资源只回答「玩家要进入哪一场遭遇、对手是谁」，不持有运行时状态、不实例化单位、不做奖励结算。
## 对手有两条路径：旧的单敌人档案 `enemy_profile`，以及多人队伍 `enemy_squad`；
## `enemy_squad` 非空且配置完成时优先，旧资源不因新增字段改变行为。

enum ThreatTag {
	BASELINE,
	ENDURANCE,
	BURST,
}

@export var id: StringName = &"encounter"
@export var display_name: String = "遭遇"
@export_multiline var description: String = ""
## 该遭遇的单一对手档案；遭遇必须引用正式敌人数据，不在遭遇里复制数值。
@export var enemy_profile: PawnData
## 可选敌方队伍；非空且配置完成时优先于 `enemy_profile`。
@export var enemy_squad: SquadDefinition
## 期望玩家上阵人数；0 表示按敌方人数取玩家队伍前 N 人（旧单敌人场景即 1 人）。
@export_range(0, 4, 1, "or_greater") var player_count: int = 0
## 威胁标签只用于玩家阅读与后续分组，不参与战斗结算。
@export var threat_tag: ThreatTag = ThreatTag.BASELINE
## 首通奖励（INC-WORLD-007）：本遭遇**首次由玩家获胜**时发放的技能；null 表示没有首通奖励。
## 本字段只描述「奖励是什么」，不记录「是否已发放」——发放状态由运行时的已掌握技能列表承担，
## 因此重复通关不会重复发放，解锁结果也随本代修士的运行时进度跨遭遇延续。
## 奖励只允许是技能：本实验用单一变量回答「新能力是否驱动 Build 重构」，不得顺手发资源。
@export var first_clear_skill_reward: ActiveSkillDefinition


## 遭遇是否可直接进入：id / 名称齐备，且单敌人档案或敌方队伍至少一条可用。
func is_configured() -> bool:
	if String(id).strip_edges().is_empty():
		return false
	if display_name.strip_edges().is_empty():
		return false
	return get_enemy_count() > 0


## 是否配置了可用的首通奖励：奖励技能存在且自身配置完整。
func has_first_clear_reward() -> bool:
	return first_clear_skill_reward != null and first_clear_skill_reward.is_configured()


## 是否使用多人敌方队伍（enemy_squad 非空且通过自身校验）。
func uses_enemy_squad() -> bool:
	return enemy_squad != null and enemy_squad.is_configured()


## 有序敌方成员档案：队伍优先，否则回退单敌人档案；两条路径都不可用时返回空数组。
func get_enemy_members() -> Array[PawnData]:
	var members: Array[PawnData] = []
	if uses_enemy_squad():
		members.assign(enemy_squad.members)
		return members
	if enemy_profile != null:
		members.append(enemy_profile)
	return members


func get_enemy_count() -> int:
	return get_enemy_members().size()


## 敌方默认站位；长度与 get_enemy_members() 一致（单敌人在原点）。
func get_enemy_spawn_offsets() -> Array[Vector2]:
	if uses_enemy_squad():
		return enemy_squad.get_spawn_offsets()
	var offsets: Array[Vector2] = []
	if enemy_profile != null:
		offsets.append(Vector2.ZERO)
	return offsets


## 对手 id：多人队伍返回队伍 id，单敌人返回档案 id，未配置返回空 StringName。
func get_enemy_profile_id() -> StringName:
	if uses_enemy_squad():
		return enemy_squad.id
	if enemy_profile == null:
		return &""
	return enemy_profile.id


## 对手展示名：多人队伍用队伍名，单敌人用档案名，未配置返回空串。
func get_enemy_display_name() -> String:
	if uses_enemy_squad():
		return enemy_squad.display_name
	if enemy_profile == null:
		return ""
	return enemy_profile.display_name


## 期望玩家上阵人数：显式 player_count 优先，否则按敌方人数（至少 1）。
## 可用玩家成员不足时由 EncounterSession 截断，不在数据层隐式补齐。
func get_requested_player_count() -> int:
	if player_count > 0:
		return player_count
	return maxi(get_enemy_count(), 1)


## 威胁标签的中文短标签，供面板与日志使用；未知取值回退到基线。
func get_threat_tag_label() -> String:
	match threat_tag:
		ThreatTag.ENDURANCE:
			return "长线"
		ThreatTag.BURST:
			return "爆发"
		_:
			return "基线"
