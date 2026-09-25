class_name EncounterDefinition
extends Resource

## 秘境遭遇的静态定义（INC-WORLD-001）。
##
## 本资源只回答「玩家要进入哪一场遭遇、对手是谁」，不持有运行时状态、不实例化单位、不做奖励结算。
## 秘境房间推进、随机事件、掉落与 Boss 属于后续 Increment；MVP 阶段一场遭遇 = 一个敌人档案。

enum ThreatTag {
	BASELINE,
	ENDURANCE,
	BURST,
}

@export var id: StringName = &"encounter"
@export var display_name: String = "遭遇"
@export_multiline var description: String = ""
## 该遭遇的对手档案；遭遇必须引用正式敌人数据，不在遭遇里复制数值。
@export var enemy_profile: PawnData
## 威胁标签只用于玩家阅读与后续分组，不参与战斗结算。
@export var threat_tag: ThreatTag = ThreatTag.BASELINE


## 遭遇是否可直接进入：id / 名称 / 对手档案三者齐备才算配置完成。
func is_configured() -> bool:
	if String(id).strip_edges().is_empty():
		return false
	if display_name.strip_edges().is_empty():
		return false
	return get_enemy_profile_id() != &""


## 对手档案 id；未配置对手时返回空 StringName，调用方据此判断可用性。
func get_enemy_profile_id() -> StringName:
	if enemy_profile == null:
		return &""
	return enemy_profile.id


## 对手展示名；未配置对手时返回空串，由 UI 决定占位文案。
func get_enemy_display_name() -> String:
	if enemy_profile == null:
		return ""
	return enemy_profile.display_name


## 威胁标签的中文短标签，供面板与日志使用；未知取值回退到基线。
func get_threat_tag_label() -> String:
	match threat_tag:
		ThreatTag.ENDURANCE:
			return "长线"
		ThreatTag.BURST:
			return "爆发"
		_:
			return "基线"
