class_name PawnInfoModel
extends RefCounted

## Pawn 信息卡的只读读模型：把静态配置（`PawnData`）与运行时数值（由调用方传入的字典）
## 整理成可直接渲染的快照，并派生稳定文案。本类不持有节点、不订阅信号、不修改任何数据。
##
## 数据边界（对应 `docs/pawns信息ui.md` 的统一数据契约）：
##   - 静态部分：姓名、境界、小境界、灵根、属性与 Build 配置（功法 / 武器 / 主动 / 被动）全部来自 `PawnData`。
##   - 运行时部分：气血/护体/灵力与 Build 容量占用由调用方（`PawnInfoPanel`）以字典传入，
##     因为运行时数值只存在于 `Pawn/Resources/*` 的 `ResourcePoolComponent`，不写入 `.tres`。
##   - 本类不实现 Build 校验规则：容量与校验结论由 `RealmDefinition` / `BuildValidator` 提供后传入。

const UNKNOWN_TEXT: String = "—"
const NO_BUILD_TAG: String = "无功法"
const BUILD_UNAVAILABLE_TEXT: String = "Build：不适用（未配置境界）"
const CULTIVATION_MAX_REALM_TEXT: String = "修为：已至最高境界"

const HEALTH_KEY: String = "health"
const SHIELD_KEY: String = "shield"
const SPIRIT_KEY: String = "spirit"

## 资源行显示名：采用信息卡需求文档的用词（气血 / 护体 / 灵力）。
const RESOURCE_LABELS: Dictionary = {
	HEALTH_KEY: "气血",
	SHIELD_KEY: "护体",
	SPIRIT_KEY: "灵力",
}

## 单位可能拥有的资源行顺序：气血 → 护体 → 灵力。
const RESOURCE_KEYS: Array[String] = [HEALTH_KEY, SHIELD_KEY, SPIRIT_KEY]


## 攻击间隔（秒/次）派生攻速（次/秒）；非正数视为没有攻速数据。
static func get_attack_speed(attack_interval: float) -> float:
	if attack_interval <= 0.0:
		return 0.0
	return 1.0 / attack_interval


## Build 标签由已装备功法与主动技能的显示名派生（例如“剑修 · 御剑斩”）。
## 不新增冗余字段，避免标签与真实 Build 数据漂移。
static func get_build_tag(techniques: Array[TechniqueDefinition], skill: ActiveSkillDefinition) -> String:
	var parts: Array[String] = []
	for technique: TechniqueDefinition in techniques:
		if technique != null and not technique.display_name.strip_edges().is_empty():
			parts.append(technique.display_name)
	if skill != null and not skill.display_name.strip_edges().is_empty():
		parts.append(skill.display_name)
	if parts.is_empty():
		return NO_BUILD_TAG
	return " · ".join(PackedStringArray(parts))


## 构建快照。runtime 缺失的键按“该资源/容量未提供”处理，不会回填假数据。
static func build_snapshot(data: PawnData, runtime: Dictionary = {}) -> Dictionary:
	var has_data: bool = data != null
	var realm: RealmDefinition = null
	var techniques: Array[TechniqueDefinition] = []
	var weapon: WeaponDefinition = null
	var skill: ActiveSkillDefinition = null
	var skill_names: Array[String] = []
	var name_text: String = UNKNOWN_TEXT
	var faction_text: String = UNKNOWN_TEXT
	var sub_realm_text: String = UNKNOWN_TEXT
	var spirit_root_text: String = UNKNOWN_TEXT
	var attack: float = 0.0
	var defense: float = 0.0
	var attack_interval: float = 0.0
	var move_speed: float = 0.0
	if has_data:
		name_text = data.display_name
		faction_text = String(data.faction)
		sub_realm_text = _text_or_unknown(data.sub_realm)
		spirit_root_text = _text_or_unknown(String(data.spirit_root))
		realm = data.realm
		techniques.assign(data.techniques)
		weapon = data.weapon
		skill = data.get_primary_active_skill()
		skill_names = _skill_names(data.get_active_skills())
		attack = data.attack
		defense = data.defense
		attack_interval = data.attack_interval
		move_speed = data.move_speed

	var has_realm: bool = realm != null and realm.is_configured()
	var vitals: Dictionary = {}
	for key: String in RESOURCE_KEYS:
		vitals[key] = _read_vital(runtime, key)

	var passive_names: Array[String] = []
	var realm_text: String = realm.display_name if has_realm else UNKNOWN_TEXT

	return {
		"identity": {
			"name": name_text,
			"faction": faction_text,
			"realm": realm_text,
			"sub_realm": sub_realm_text,
			"spirit_root": spirit_root_text,
			"build_tag": get_build_tag(techniques, skill),
			"has_realm": has_realm,
		},
		"vitals": vitals,
		"attributes": {
			"attack": attack,
			"defense": defense,
			"attack_speed": get_attack_speed(attack_interval),
			"move_speed": move_speed,
		},
		"build": {
			"has_realm": has_realm,
			"technique": _read_slot(runtime, "technique", _technique_names(techniques)),
			"weapon": _read_slot(runtime, "weapon", _weapon_names(weapon)),
			"active_skill": _read_slot(runtime, "active_skill", skill_names),
			"passive_skill": _read_slot(runtime, "passive_skill", passive_names),
			"error_summary": String(runtime.get("build_error_summary", "")),
		},
		"cultivation": _read_cultivation(runtime),
	}


## 身份区四行：姓名 / 境界（含小境界）/ 灵根 / 流派。未配置项统一显示 `—`。
static func identity_lines(snapshot: Dictionary) -> Array[String]:
	var identity: Dictionary = snapshot.get("identity", {})
	var lines: Array[String] = []
	lines.append(String(identity.get("name", UNKNOWN_TEXT)))
	var realm_text: String = String(identity.get("realm", UNKNOWN_TEXT))
	var sub_realm_text: String = String(identity.get("sub_realm", UNKNOWN_TEXT))
	if bool(identity.get("has_realm", false)) and sub_realm_text != UNKNOWN_TEXT:
		lines.append("%s · %s" % [realm_text, sub_realm_text])
	else:
		lines.append(realm_text)
	lines.append("灵根：%s" % String(identity.get("spirit_root", UNKNOWN_TEXT)))
	lines.append("流派：%s" % String(identity.get("build_tag", NO_BUILD_TAG)))
	return lines


## 单个资源行文案；该资源不存在（无池或上限为 0）时返回空串，由调用方隐藏整行。
static func vital_line(snapshot: Dictionary, resource_key: String) -> String:
	var vitals: Dictionary = snapshot.get("vitals", {})
	var raw: Variant = vitals.get(resource_key)
	if not (raw is Dictionary):
		return ""
	var values: Dictionary = raw
	return "%s  %.0f / %.0f" % [
		String(RESOURCE_LABELS.get(resource_key, resource_key)),
		float(values.get("current", 0.0)),
		float(values.get("max", 0.0)),
	]


## 核心属性行：只显示当前有真实数据来源的属性；法强/暴击等待数据落地后再补。
static func attribute_line(snapshot: Dictionary) -> String:
	var attributes: Dictionary = snapshot.get("attributes", {})
	return "攻击 %.0f   防御 %.0f   攻速 %.2f   移速 %.0f" % [
		float(attributes.get("attack", 0.0)),
		float(attributes.get("defense", 0.0)),
		float(attributes.get("attack_speed", 0.0)),
		float(attributes.get("move_speed", 0.0)),
	]


## Build 区：境界容量与占用 + 已装备名称；未配置境界时只给一条“不适用”。
## 校验存在错误时追加首条原因，完整列表仍由 `BuildValidationResult.get_errors()` 提供。
static func build_lines(snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var build: Dictionary = snapshot.get("build", {})
	if not bool(build.get("has_realm", false)):
		lines.append(BUILD_UNAVAILABLE_TEXT)
		return lines
	var technique_slot: Dictionary = build.get("technique", {})
	var weapon_slot: Dictionary = build.get("weapon", {})
	var active_slot: Dictionary = build.get("active_skill", {})
	var passive_slot: Dictionary = build.get("passive_skill", {})
	lines.append(_slot_line("功法", technique_slot))
	lines.append(_slot_line("武器", weapon_slot))
	lines.append(_slot_line("主动", active_slot))
	lines.append(_slot_line("被动", passive_slot))
	var summary: String = String(build.get("error_summary", "")).strip_edges()
	if not summary.is_empty():
		lines.append("校验：%s" % summary)
	return lines


static func _slot_line(label: String, slot: Dictionary) -> String:
	var names: Array = slot.get("names", [])
	var name_text: String = UNKNOWN_TEXT
	if not names.is_empty():
		name_text = ", ".join(PackedStringArray(names))
	return "%s  %d / %d    %s" % [label, int(slot.get("used", 0)), int(slot.get("max", 0)), name_text]


## 修为区：有下一境界时返回“百分比 / 当前 / 所需 / 下一境界”；终点境界单独提示。
## 没有境界或没有修为快照的单位返回空串，由面板隐藏整个区域。
static func cultivation_line(snapshot: Dictionary) -> String:
	var cultivation: Dictionary = snapshot.get("cultivation", {})
	if not bool(cultivation.get("available", false)):
		return ""
	if bool(cultivation.get("terminal", false)):
		return CULTIVATION_MAX_REALM_TEXT
	var current_exp: float = float(cultivation.get("current_exp", 0.0))
	var required_exp: float = maxf(float(cultivation.get("required_exp", 0.0)), 0.0)
	if required_exp <= 0.0:
		return ""
	var ratio: float = clampf(float(cultivation.get("ratio", 0.0)), 0.0, 1.0)
	var next_realm: String = String(cultivation.get("next_realm", UNKNOWN_TEXT))
	var text: String = "修为  %d%%  %.0f / %.0f  → %s" % [
		int(round(ratio * 100.0)),
		current_exp,
		required_exp,
		next_realm,
	]
	if bool(cultivation.get("ready", false)):
		text += "  （可突破）"
	return text


## 进度条值域固定为 0..1；终点或缺失数据返回 0。
static func cultivation_ratio(snapshot: Dictionary) -> float:
	var cultivation: Dictionary = snapshot.get("cultivation", {})
	if not bool(cultivation.get("available", false)) or bool(cultivation.get("terminal", false)):
		return 0.0
	return clampf(float(cultivation.get("ratio", 0.0)), 0.0, 1.0)
static func _read_cultivation(runtime: Dictionary) -> Dictionary:
	var raw: Variant = runtime.get("cultivation")
	if not (raw is Dictionary):
		return {"available": false, "terminal": false, "current_exp": 0.0, "required_exp": 0.0, "ratio": 0.0}
	var values: Dictionary = raw
	var realm_name: String = String(values.get("realm_name", "")).strip_edges()
	if realm_name.is_empty():
		return {"available": false, "terminal": false, "current_exp": 0.0, "required_exp": 0.0, "ratio": 0.0}
	var has_next: bool = bool(values.get("has_next_realm", false))
	if not has_next:
		return {"available": true, "terminal": true, "current_exp": 0.0, "required_exp": 0.0, "ratio": 0.0}
	var required_exp: float = maxf(float(values.get("required_exp", 0.0)), 0.0)
	var current_exp: float = clampf(float(values.get("current_exp", 0.0)), 0.0, required_exp)
	return {
		"available": true,
		"terminal": false,
		"realm": realm_name,
		"next_realm": _text_or_unknown(String(values.get("next_realm_name", ""))),
		"current_exp": current_exp,
		"required_exp": required_exp,
		"ratio": (current_exp / required_exp) if required_exp > 0.0 else 0.0,
		"ready": bool(values.get("ready", false)) and required_exp > 0.0 and current_exp >= required_exp,
	}

static func _read_vital(runtime: Dictionary, key: String) -> Variant:
	var raw: Variant = runtime.get(key)
	if not (raw is Dictionary):
		return null
	var values: Dictionary = raw
	var max_value: float = maxf(float(values.get("max", 0.0)), 0.0)
	if max_value <= 0.0:
		return null
	return {
		"current": clampf(float(values.get("current", 0.0)), 0.0, max_value),
		"max": max_value,
	}


## slot 的 used/max 来自调用方（真实容量由 RealmDefinition 唯一决定）；缺省时 used 取已装备名称数。
static func _read_slot(runtime: Dictionary, prefix: String, names: Array[String]) -> Dictionary:
	return {
		"used": int(runtime.get(prefix + "_used", names.size())),
		"max": maxi(int(runtime.get(prefix + "_max", 0)), 0),
		"names": names,
	}


static func _technique_names(techniques: Array[TechniqueDefinition]) -> Array[String]:
	var names: Array[String] = []
	for technique: TechniqueDefinition in techniques:
		if technique != null and not technique.display_name.strip_edges().is_empty():
			names.append(technique.display_name)
	return names


static func _skill_names(skills: Array[ActiveSkillDefinition]) -> Array[String]:
	var names: Array[String] = []
	for skill: ActiveSkillDefinition in skills:
		if skill != null and not skill.display_name.strip_edges().is_empty():
			names.append(skill.display_name)
	return names


## 武器条目文案：名称 + “类型 · 五行”标签；未配置五行的武器只显示类型，不给缺数据的条目补假属性。
static func _weapon_names(weapon: WeaponDefinition) -> Array[String]:
	var names: Array[String] = []
	if weapon == null or weapon.display_name.strip_edges().is_empty():
		return names
	names.append("%s（%s）" % [weapon.display_name, _weapon_tag(weapon)])
	return names


## 武器标签：类型与五行文案都由 `WeaponDefinition` 提供，读模型不重复维护标签表。
static func _weapon_tag(weapon: WeaponDefinition) -> String:
	var type_text: String = weapon.get_type_label()
	if not weapon.has_element():
		return type_text
	return "%s · %s" % [type_text, weapon.get_element_label()]


static func _text_or_unknown(value: String) -> String:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return UNKNOWN_TEXT
	return trimmed
