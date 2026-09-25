class_name BuildValidator
extends RefCounted

## Build 容量与冲突校验器：纯逻辑、无副作用，不装备也不卸载任何东西。
## 规则来源 `docs/project_summary.md` §六；当前覆盖容量超限、同类重复、功法互斥、境界门槛、条目未配置五项，
## 这五项对功法 / 武器 / 主动技能 / 被动技能一致适用；
## 五行关系 / 属性要求 / 技能前置留给后续 Increment。
##
## 设计取舍：缺少境界时只报一条 `missing_realm`，并跳过容量与门槛判定。
## 因为容量来源于境界，缺少境界时任何“超限”结论都是伪错误，会把真正的原因埋掉。

const KIND_REALM: StringName = &"realm"

## 校验入口。返回值永远非空：空 Build 在有效境界下是合法的，缺少境界则是一条错误。
static func validate(loadout: BuildLoadout) -> BuildValidationResult:
	var result: BuildValidationResult = BuildValidationResult.new()
	if loadout == null:
		# 连汇总对象都没有时同样只报“缺境界”，调用方只需要处理一种无效原因。
		result.add_error(
			BuildValidationResult.CODE_MISSING_REALM,
			KIND_REALM,
			BuildValidationResult.ENTRY_ID_NONE,
			"未配置境界，无法计算 Build 容量"
		)
		return result

	var realm_ready: bool = loadout.realm != null and loadout.realm.is_configured()
	if not realm_ready:
		result.add_error(
			BuildValidationResult.CODE_MISSING_REALM,
			KIND_REALM,
			BuildValidationResult.ENTRY_ID_NONE,
			"未配置境界，无法计算 Build 容量"
		)

	_validate_entries(loadout, RealmDefinition.KIND_TECHNIQUE, realm_ready, result)
	_validate_entries(loadout, RealmDefinition.KIND_WEAPON, realm_ready, result)
	_validate_entries(loadout, RealmDefinition.KIND_ACTIVE_SKILL, realm_ready, result)
	_validate_entries(loadout, RealmDefinition.KIND_PASSIVE_SKILL, realm_ready, result)
	return result

## 逐类校验：容量按类别独立计算，重复、门槛与互斥按条目顺序报错，保证同一输入的错误顺序稳定。
static func _validate_entries(
		loadout: BuildLoadout,
		kind: StringName,
		realm_ready: bool,
		result: BuildValidationResult
	) -> void:
	var capacity: int = loadout.get_capacity(kind)
	var used: int = 0
	var seen_ids: Array[StringName] = []
	var seen_techniques: Array[TechniqueDefinition] = []

	for entry: Variant in loadout.get_entries(kind):
		if entry == null:
			result.add_error(
				BuildValidationResult.CODE_UNCONFIGURED_ENTRY,
				kind,
				BuildValidationResult.ENTRY_ID_NONE,
				"%s存在空条目" % _kind_label(kind)
			)
			continue

		used += 1
		var entry_id: StringName = _entry_id(entry)
		if not _entry_is_configured(entry):
			result.add_error(
				BuildValidationResult.CODE_UNCONFIGURED_ENTRY,
				kind,
				entry_id,
				"%s条目未配置" % _kind_label(kind)
			)
			continue

		if seen_ids.has(entry_id):
			result.add_error(
				BuildValidationResult.CODE_DUPLICATE_ENTRY,
				kind,
				entry_id,
				"%s重复：%s" % [_kind_label(kind), _entry_display_name(entry)]
			)
		else:
			seen_ids.append(entry_id)

		if realm_ready and _required_tier(entry) > loadout.realm.tier:
			result.add_error(
				BuildValidationResult.CODE_REALM_TOO_LOW,
				kind,
				entry_id,
				"%s需要%s，当前%s" % [
					_entry_display_name(entry),
					_tier_label(_required_tier(entry)),
					loadout.realm.display_name,
				]
			)

		if entry is TechniqueDefinition:
			var technique: TechniqueDefinition = entry as TechniqueDefinition
			_check_technique_conflict(technique, seen_techniques, result)
			seen_techniques.append(technique)

	# 容量超限放在最后报：先让调用方看到“哪个条目有问题”，再看“整类装不下”。
	if realm_ready and used > capacity:
		result.add_error(
			BuildValidationResult.CODE_OVER_CAPACITY,
			kind,
			BuildValidationResult.ENTRY_ID_NONE,
			"%s超出容量：%d / %d" % [_kind_label(kind), used, capacity]
		)

## 功法互斥：与任一已读功法共享互斥标签即报错，错误归属于后出现的那个功法。
static func _check_technique_conflict(
		technique: TechniqueDefinition,
		seen: Array[TechniqueDefinition],
		result: BuildValidationResult
	) -> void:
	for previous: TechniqueDefinition in seen:
		# 同一个功法重复装备属于“重复”规则，不算互斥；否则同一错误会被报两次。
		if previous.id == technique.id:
			continue
		var tag: StringName = technique.get_shared_conflict_tag(previous)
		if not String(tag).is_empty():
			result.add_error(
				BuildValidationResult.CODE_TECHNIQUE_CONFLICT,
				RealmDefinition.KIND_TECHNIQUE,
				technique.id,
				"功法互斥：%s与%s不可同时修习" % [technique.display_name, previous.display_name]
			)
			return

static func _entry_id(entry: Variant) -> StringName:
	if entry is WeaponDefinition:
		return (entry as WeaponDefinition).id
	if entry is TechniqueDefinition:
		return (entry as TechniqueDefinition).id
	if entry is PassiveSkillDefinition:
		return (entry as PassiveSkillDefinition).id
	if entry is ActiveSkillDefinition:
		return (entry as ActiveSkillDefinition).id
	return BuildValidationResult.ENTRY_ID_NONE

static func _entry_display_name(entry: Variant) -> String:
	if entry is WeaponDefinition:
		return (entry as WeaponDefinition).display_name
	if entry is TechniqueDefinition:
		return (entry as TechniqueDefinition).display_name
	if entry is PassiveSkillDefinition:
		return (entry as PassiveSkillDefinition).display_name
	if entry is ActiveSkillDefinition:
		return (entry as ActiveSkillDefinition).display_name
	return "条目"

static func _entry_is_configured(entry: Variant) -> bool:
	if entry is WeaponDefinition:
		return (entry as WeaponDefinition).is_configured()
	if entry is TechniqueDefinition:
		return (entry as TechniqueDefinition).is_configured()
	if entry is PassiveSkillDefinition:
		return (entry as PassiveSkillDefinition).is_configured()
	if entry is ActiveSkillDefinition:
		return (entry as ActiveSkillDefinition).is_configured()
	return false

## 境界门槛：技能定义当前没有门槛字段，功法 / 武器 / 被动参与判定。
static func _required_tier(entry: Variant) -> int:
	if entry is WeaponDefinition:
		return (entry as WeaponDefinition).required_realm_tier
	if entry is TechniqueDefinition:
		return (entry as TechniqueDefinition).required_realm_tier
	if entry is PassiveSkillDefinition:
		return (entry as PassiveSkillDefinition).required_realm_tier
	return 1

static func _kind_label(kind: StringName) -> String:
	match kind:
		RealmDefinition.KIND_TECHNIQUE:
			return "功法"
		RealmDefinition.KIND_WEAPON:
			return "武器"
		RealmDefinition.KIND_ACTIVE_SKILL:
			return "主动技能"
		RealmDefinition.KIND_PASSIVE_SKILL:
			return "被动技能"
		_:
			return "条目"

static func _tier_label(tier: int) -> String:
	match tier:
		1:
			return "炼气"
		2:
			return "筑基"
		3:
			return "金丹"
		4:
			return "元婴"
		5:
			return "化神"
		_:
			return "第 %d 重境界" % tier