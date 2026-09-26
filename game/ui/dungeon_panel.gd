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
## 秘境选择区（INC-UI-020）：由主场景注入可选项，玩家点击把「想进哪个秘境」变成信号；
## 面板不持有 DungeonRun，也不判断本局是否进行中——可点性只由面板自身的既有状态（未开局 / 已结算）决定。
signal dungeon_selected(dungeon: DungeonDefinition)

const EMPTY_STATUS: String = "秘境未开始"
const EMPTY_DEPTH_TEXT: String = "深度：-"
const EMPTY_REWARD_TEXT: String = "已获灵石：-"
const EMPTY_PROBLEM_TEXT: String = "本层问题：-"
const EMPTY_OPTION_TEXT: String = "(未配置秘境)"
## 首通解锁提示（INC-UI-022）：空字符串表示没有要展示的解锁事实，此时整行隐藏。
const EMPTY_UNLOCK_TEXT: String = ""

@onready var _title_label: Label = $TitleLabel
@onready var _depth_label: Label = $DepthLabel
@onready var _reward_label: Label = $RewardLabel
@onready var _problem_label: Label = $ProblemLabel
@onready var _unlock_label: Label = $UnlockLabel
@onready var _status_label: Label = $StatusLabel
@onready var _advance_button: Button = $AdvanceButton
@onready var _retreat_button: Button = $RetreatButton
@onready var _restart_button: Button = $RestartButton
@onready var _options_container: VBoxContainer = $DungeonOptions

var _dungeon: DungeonDefinition
var _depth: int = 0
var _room_count: int = 0
var _earned_spirit_stones: int = 0
var _awaiting_decision: bool = false
var _can_restart: bool = false
## set_status 可能在入树前被调用，先记住文本，_ready 时再落到 Label。
var _status_text: String = EMPTY_STATUS
## 同理：本层问题文案也可能在入树前被写入，先记住再落到 Label。
var _problem_text: String = EMPTY_PROBLEM_TEXT
## 同理：解锁提示也可能在入树前被写入，先记住再落到 Label。
var _unlock_text: String = EMPTY_UNLOCK_TEXT
## 秘境选项由主场景注入（INC-UI-020）：面板不硬编码任何资源路径，也不缓存游戏进度。
var _dungeon_options: Array[DungeonDefinition] = []
var _option_buttons: Array[Button] = []


func _ready() -> void:
	if not _advance_button.pressed.is_connected(_on_advance_pressed):
		_advance_button.pressed.connect(_on_advance_pressed)
	if not _retreat_button.pressed.is_connected(_on_retreat_pressed):
		_retreat_button.pressed.connect(_on_retreat_pressed)
	if not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
	_rebuild_option_buttons()
	_apply_unlock_text()
	_refresh_all()


## 注入可选择的秘境列表（INC-UI-020）：按传入顺序生成按钮，空列表回退到空态。
## 允许在入树前调用：此时只记住数据，_ready 再落成控件。
func set_dungeon_options(options: Array[DungeonDefinition]) -> void:
	_dungeon_options = options.duplicate()
	_rebuild_option_buttons()


func get_option_button_count() -> int:
	return _option_buttons.size()


func get_option_button(index: int) -> Button:
	if index < 0 or index >= _option_buttons.size():
		return null
	return _option_buttons[index]


## 绑定秘境定义；null / 未配置秘境会清空进度并禁用全部入口。
func set_dungeon(dungeon: DungeonDefinition) -> void:
	if dungeon == null or not dungeon.is_configured():
		_dungeon = null
		_depth = 0
		_room_count = 0
		_earned_spirit_stones = 0
		_awaiting_decision = false
		_can_restart = false
		_problem_text = EMPTY_PROBLEM_TEXT
	else:
		_dungeon = dungeon
	_refresh_all()


func set_depth(depth: int, room_count: int) -> void:
	_depth = maxi(depth, 0)
	_room_count = maxi(room_count, 0)
	_refresh_all()


## 本层考查的战斗问题（INC-WORLD-008）：标签由 DungeonRoom 从问题型映射而来，面板只做展示，
## 不判断问题的含义，也不据此改变任何可点状态。空数组表示本层没有声明问题型。
func set_room_problem_labels(labels: Array[String]) -> void:
	_problem_text = _compose_problem_text(labels)
	if _problem_label != null:
		_problem_label.text = _problem_text


## 首通解锁提示（INC-UI-022）：只展示「刚刚解锁了什么」这一只读事实。
## 面板不判断是否首次、不自动装配、不改变任何按钮可点状态；重复通关由上层决定不写入新文案。
func set_unlock_notice(text: String) -> void:
	_unlock_text = text
	_apply_unlock_text()


func clear_unlock_notice() -> void:
	set_unlock_notice(EMPTY_UNLOCK_TEXT)


func get_unlock_notice() -> String:
	return _unlock_text


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


func get_problem_text() -> String:
	if _problem_label == null:
		return _problem_text
	return _problem_label.text


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
	if _problem_label != null:
		_problem_label.text = _problem_text
	if _restart_button != null:
		# 未产生过进度时是首次入口，产生过进度后才是「重新开始」。
		_restart_button.text = "开始秘境" if _depth <= 0 else "重新开始秘境"
	if _status_label != null:
		_status_label.text = _status_text


## 空文案时整行隐藏（不占位），因此没有解锁事实时秘境面板的布局与新增本行之前一致。
func _apply_unlock_text() -> void:
	if _unlock_label == null:
		return
	_unlock_label.text = _unlock_text
	_unlock_label.visible = not _unlock_text.is_empty()


func _refresh_buttons() -> void:
	var decision_ready: bool = _dungeon != null and _awaiting_decision
	if _advance_button != null:
		_advance_button.disabled = not decision_ready
	if _retreat_button != null:
		_retreat_button.disabled = not decision_ready
	if _restart_button != null:
		_restart_button.disabled = not (_dungeon != null and _can_restart)
	var options_editable: bool = _dungeon == null or _can_restart
	for index in _option_buttons.size():
		var dungeon: DungeonDefinition = _dungeon_options[index] if index < _dungeon_options.size() else null
		var selectable: bool = options_editable and dungeon != null and dungeon.is_configured()
		_option_buttons[index].disabled = not selectable


func _compose_depth_text() -> String:
	if _dungeon == null:
		return EMPTY_DEPTH_TEXT
	return "深度：%d / %d" % [_depth, _room_count]


func _compose_reward_text() -> String:
	if _dungeon == null:
		return EMPTY_REWARD_TEXT
	return "已获灵石：%d" % _earned_spirit_stones


## 重建选项按钮：入树前调用只记住数据，_ready 时再落成控件（避免 @onready 空引用）。
func _rebuild_option_buttons() -> void:
	if _options_container == null:
		return
	for button: Button in _option_buttons:
		if is_instance_valid(button):
			_options_container.remove_child(button)
			button.queue_free()
	_option_buttons.clear()
	_options_container.visible = not _dungeon_options.is_empty()
	for index in _dungeon_options.size():
		var dungeon: DungeonDefinition = _dungeon_options[index]
		var button: Button = Button.new()
		button.name = "DungeonOption%d" % (index + 1)
		button.text = dungeon.display_name if dungeon != null and dungeon.is_configured() else EMPTY_OPTION_TEXT
		button.pressed.connect(_on_dungeon_option_pressed.bind(dungeon))
		_options_container.add_child(button)
		_option_buttons.append(button)
	_refresh_buttons()


## 选择入口只在「还没开局」或「本局已结算」时可点：进行中与等待抉择都锁定，
## 与既有「重新开始秘境」入口共用 _can_restart 这一事实，不引入第二套状态机。
func _on_dungeon_option_pressed(dungeon: DungeonDefinition) -> void:
	if dungeon == null or not dungeon.is_configured():
		return
	if _dungeon != null and not _can_restart:
		return
	dungeon_selected.emit(dungeon)


## 多个问题时用「 + 」连接，保持与房间定义中的组合语义一致；空数组回退到占位文案。
func _compose_problem_text(labels: Array[String]) -> String:
	if labels.is_empty():
		return EMPTY_PROBLEM_TEXT
	return "本层问题：" + " + ".join(labels)
