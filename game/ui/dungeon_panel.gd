class_name DungeonPanel
extends VBoxContainer

## 秘境进度面板（INC-UI-015）：只呈现「当前深度 / 累计收益 / 是否等待抉择」，
## 并把「继续深入」「见好就收」「重新开始秘境」变成三个信号。
##
## 面板不持有 DungeonRun、不读取秘境定义以外的游戏状态、不改任何收益数值；
## 是否真的能推进 / 撤退 / 重启由 DungeonRun 决定。

## 等待抉择时由玩家点击「继续深入」发出；面板不判断还有没有下一间。
signal advance_requested()
## 等待抉择时由玩家点击「见好就收」发出；面板不结算收益。
signal retreat_requested()
## 点击「开始秘境 / 重新开始秘境」发出；本局进行中时面板会禁用该入口，信号只表示玩家想开一局新的秘境。
signal restart_requested()

const EMPTY_STATUS: String = "秘境未开始"
const EMPTY_DEPTH_TEXT: String = "深度：-"
const EMPTY_REWARD_TEXT: String = "已获灵石：-"

@onready var _title_label: Label = $TitleLabel
@onready var _depth_label: Label = $DepthLabel
@onready var _reward_label: Label = $RewardLabel
@onready var _status_label: Label = $StatusLabel
@onready var _advance_button: Button = $AdvanceButton
@onready var _retreat_button: Button = $RetreatButton
@onready var _restart_button: Button = $RestartButton

var _dungeon: DungeonDefinition
var _depth: int = 0
var _room_count: int = 0
var _earned_spirit_stones: int = 0
var _awaiting_decision: bool = false
var _can_restart: bool = false
## set_status 可能在入树前被调用，先记住文本，_ready 时再落到 Label。
var _status_text: String = EMPTY_STATUS


func _ready() -> void:
	if not _advance_button.pressed.is_connected(_on_advance_pressed):
		_advance_button.pressed.connect(_on_advance_pressed)
	if not _retreat_button.pressed.is_connected(_on_retreat_pressed):
		_retreat_button.pressed.connect(_on_retreat_pressed)
	if not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
	_refresh_all()


## 绑定秘境定义；null / 未配置秘境会清空进度并禁用全部入口。
func set_dungeon(dungeon: DungeonDefinition) -> void:
	if dungeon == null or not dungeon.is_configured():
		_dungeon = null
		_depth = 0
		_room_count = 0
		_earned_spirit_stones = 0
		_awaiting_decision = false
		_can_restart = false
	else:
		_dungeon = dungeon
	_refresh_all()


func set_depth(depth: int, room_count: int) -> void:
	_depth = maxi(depth, 0)
	_room_count = maxi(room_count, 0)
	_refresh_all()


func set_reward(earned_spirit_stones: int) -> void:
	_earned_spirit_stones = maxi(earned_spirit_stones, 0)
	_refresh_all()


func set_status(text: String) -> void:
	_status_text = text
	if _status_label != null:
		_status_label.text = text


## 等待抉择与「本局已结算」互斥：任何一方为真都会清掉另一方，避免出现互相矛盾的可点状态。
func set_awaiting_decision(value: bool) -> void:
	_awaiting_decision = value
	if value:
		_can_restart = false
	_refresh_buttons()


func set_can_restart(value: bool) -> void:
	_can_restart = value
	if value:
		_awaiting_decision = false
	_refresh_buttons()


func get_dungeon() -> DungeonDefinition:
	return _dungeon


func get_status_text() -> String:
	return _status_text


func get_depth_text() -> String:
	if _depth_label == null:
		return _compose_depth_text()
	return _depth_label.text


func get_reward_text() -> String:
	if _reward_label == null:
		return _compose_reward_text()
	return _reward_label.text


func is_awaiting_decision() -> bool:
	return _awaiting_decision


func is_can_restart() -> bool:
	return _can_restart


## 三个入口都先做自身可交互性兜底：即使程序化触发 pressed，也不在非法状态转发。
func _on_advance_pressed() -> void:
	if _dungeon == null or not _awaiting_decision:
		return
	advance_requested.emit()


func _on_retreat_pressed() -> void:
	if _dungeon == null or not _awaiting_decision:
		return
	retreat_requested.emit()


func _on_restart_pressed() -> void:
	if _dungeon == null or not _can_restart:
		return
	restart_requested.emit()


func _refresh_all() -> void:
	_refresh_texts()
	_refresh_buttons()


func _refresh_texts() -> void:
	if _title_label != null:
		if _dungeon == null:
			_title_label.text = "秘境"
		else:
			_title_label.text = "%s（满额 %d 灵石）" % [_dungeon.display_name, _dungeon.get_max_reward()]
	if _depth_label != null:
		_depth_label.text = _compose_depth_text()
	if _reward_label != null:
		_reward_label.text = _compose_reward_text()
	if _restart_button != null:
		# 未产生过进度时是首次入口，产生过进度后才是「重新开始」。
		_restart_button.text = "开始秘境" if _depth <= 0 else "重新开始秘境"
	if _status_label != null:
		_status_label.text = _status_text


func _refresh_buttons() -> void:
	var decision_ready: bool = _dungeon != null and _awaiting_decision
	if _advance_button != null:
		_advance_button.disabled = not decision_ready
	if _retreat_button != null:
		_retreat_button.disabled = not decision_ready
	if _restart_button != null:
		_restart_button.disabled = not (_dungeon != null and _can_restart)


func _compose_depth_text() -> String:
	if _dungeon == null:
		return EMPTY_DEPTH_TEXT
	return "深度：%d / %d" % [_depth, _room_count]


func _compose_reward_text() -> String:
	if _dungeon == null:
		return EMPTY_REWARD_TEXT
	return "已获灵石：%d" % _earned_spirit_stones
