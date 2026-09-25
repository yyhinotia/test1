extends Node2D

const PAWN_CLICK_RADIUS: float = 30.0

@onready var player_pawn: Pawn = $Pawns/PlayerPawn
@onready var enemy_pawn: Pawn = $Pawns/EnemyPawn
@onready var player_controller: PlayerController = player_pawn.get_controller() as PlayerController
@onready var ai_controller: AIController = enemy_pawn.get_controller() as AIController
@onready var instructions_label: Label = $HUD/HudMargin/HudPanel/HudContent/InstructionsLabel
@onready var selected_label: Label = $HUD/HudMargin/HudPanel/HudContent/SelectedLabel
@onready var order_label: Label = $HUD/HudMargin/HudPanel/HudContent/OrderLabel
@onready var pause_state_label: Label = $HUD/PauseStateLabel
@onready var pause_overlay: Control = $HUD/PauseOverlay

var _selected_pawn: Pawn

func _ready() -> void:
	player_controller.bind(player_pawn)
	ai_controller.bind(enemy_pawn)
	ai_controller.set_target(player_pawn)

	_set_paused(false)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.is_action_pressed("select"):
			_handle_select(event.position)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("command"):
			_handle_command(event.position)
			get_viewport().set_input_as_handled()

func _handle_select(screen_position: Vector2) -> void:
	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn == player_pawn and hit_pawn.is_alive():
		_set_selected_pawn(hit_pawn)
	else:
		_set_selected_pawn(null)

func _handle_command(screen_position: Vector2) -> void:
	if _selected_pawn != player_pawn or not player_pawn.is_alive():
		return

	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn != null and hit_pawn != player_pawn and hit_pawn.is_alive():
		player_controller.order_attack(hit_pawn)
	else:
		player_controller.order_move(_screen_to_world(screen_position))
	_update_hud()

func _pawn_at_screen_position(screen_position: Vector2) -> Pawn:
	var world_position: Vector2 = _screen_to_world(screen_position)
	for child: Node in $Pawns.get_children():
		var candidate: Pawn = child as Pawn
		if candidate != null and candidate.is_alive() and world_position.distance_to(candidate.global_position) <= PAWN_CLICK_RADIUS:
			return candidate
	return null

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position

func _set_selected_pawn(new_selection: Pawn) -> void:
	if _selected_pawn != null and is_instance_valid(_selected_pawn):
		_selected_pawn.set_selected(false)
	_selected_pawn = new_selection
	if _selected_pawn != null and is_instance_valid(_selected_pawn) and _selected_pawn.is_alive():
		_selected_pawn.set_selected(true)
	else:
		_selected_pawn = null
	_update_hud()

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_overlay.visible = value
	pause_state_label.text = "游戏已暂停" if value else "实时运行中"
	_update_hud()

func _update_hud() -> void:
	instructions_label.text = "左键：选择玩家 Pawn    右键：移动/攻击目标    空格：暂停/恢复"
	if _selected_pawn == null:
		selected_label.text = "未选中单位"
		order_label.text = "指令：-"
		return

	selected_label.text = "%s\n阵营：%s\nHP：%.0f / %.0f    护盾：%.0f / %.0f\n状态：%s" % [
		_selected_pawn.data.display_name,
		_selected_pawn.data.faction,
		_selected_pawn.current_health,
		_selected_pawn.data.max_health,
		_selected_pawn.current_shield,
		_selected_pawn.data.max_shield,
		_selected_pawn.get_state_label(),
	]
	order_label.text = "指令：%s" % player_controller.get_order_description()

func _on_health_changed(changed_pawn: Pawn, _current_health: float, _max_health: float) -> void:
	if changed_pawn == _selected_pawn:
		_update_hud()

func _on_shield_changed(changed_pawn: Pawn, _current_shield: float, _max_shield: float) -> void:
	if changed_pawn == _selected_pawn:
		_update_hud()

func _on_player_state_changed(_changed_pawn: Pawn, _new_state: int) -> void:
	_update_hud()

func _on_pawn_died(changed_pawn: Pawn) -> void:
	if changed_pawn == _selected_pawn:
		_selected_pawn = null
	_update_hud()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false