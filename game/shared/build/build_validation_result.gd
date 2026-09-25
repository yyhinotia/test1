class_name BuildValidationResult
extends RefCounted

## Build 校验结果：错误码与可读文案分离，规则测试断言错误码，HUD 只读 get_summary()。
## 每个错误项固定包含 code / kind / entry_id / message 四个键，便于后续 UI 或存档结构化消费。

const CODE_MISSING_REALM: StringName = &"missing_realm"
const CODE_OVER_CAPACITY: StringName = &"over_capacity"
const CODE_DUPLICATE_ENTRY: StringName = &"duplicate_entry"
const CODE_TECHNIQUE_CONFLICT: StringName = &"technique_conflict"
const CODE_REALM_TOO_LOW: StringName = &"realm_too_low"
const CODE_UNCONFIGURED_ENTRY: StringName = &"unconfigured_entry"

## 没有具体条目（例如整类容量超限、缺少境界）时使用的占位 id。
const ENTRY_ID_NONE: StringName = &""

var _errors: Array[Dictionary] = []

func add_error(code: StringName, kind: StringName, entry_id: StringName, message: String) -> void:
	_errors.append({
		"code": code,
		"kind": kind,
		"entry_id": entry_id,
		"message": message,
	})

func has_errors() -> bool:
	return not _errors.is_empty()

func is_valid() -> bool:
	return _errors.is_empty()

## 返回副本，避免调用方就地改写校验结果。
func get_errors() -> Array[Dictionary]:
	return _errors.duplicate()

## 错误码按发现顺序返回，供规则测试逐条断言，不依赖中文文案。
func get_error_codes() -> Array[StringName]:
	var codes: Array[StringName] = []
	for error: Dictionary in _errors:
		codes.append(error["code"])
	return codes

## HUD 摘要：无错误时为空串，否则给出首条错误文案；完整列表用 get_errors() 读取。
func get_summary() -> String:
	if _errors.is_empty():
		return ""
	return String(_errors[0]["message"])