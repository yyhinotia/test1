extends Node2D

const PAWN_CLICK_RADIUS: float = 30.0

@onready var player_pawn: Pawn = $Pawns/PlayerPawn
@onready var enemy_pawn: Pawn = $Pawns/EnemyPawn
@onready var player_controller: PlayerController = player_pawn.get_controller() as PlayerController
@onready var ai_controller: AIController = enemy_pawn.get_controller() as AIController
@onready var instructions_label: Label = $HUD/HudMargin/HudPanel/HudContent/InstructionsLabel
@onready var selected_label: Label = $HUD/HudMargin/HudPanel/HudContent/SelectedLabel
@onready var order_label: Label = $HUD/HudMargin/HudPanel/HudContent/OrderLabel
@onready var skill_label: Label = $HUD/HudMargin/HudPanel/HudContent/SkillLabel
@onready var build_label: Label = $HUD/HudMargin/HudPanel/HudContent/BuildLabel
@onready var pause_state_label: Label = $HUD/PauseStateLabel
@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var info_panel: PawnInfoPanel = $HUD/BottomLeftDock/PawnInfoPanel
@onready var skill_bar: SkillBar = $HUD/BottomLeftDock/SkillBar

var _selected_pawn: Pawn

func _ready() -> void:
	player_controller.bind(player_pawn)
	ai_controller.bind(enemy_pawn)
	ai_controller.set_target(player_pawn)

	if not skill_bar.skill_requested.is_connected(_on_skill_bar_skill_requested):
		skill_bar.skill_requested.connect(_on_skill_bar_skill_requested)
	_set_paused(false)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return

	for index: int in range(1, 7):
		if event.is_action_pressed("cast_skill_%d" % index):
			_handle_cast_skill_slot(index - 1)
			get_viewport().set_input_as_handled()
			return

	if event.is_action_pressed("cast_skill"):
		_handle_cast_skill()
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

## Q 键技能入口：保持既有兼容行为，默认选择第一个已配置主动技能。
## 命令记录在控制器里，暂停期间也可下达，恢复运行后由控制器接近并施放。
func _handle_cast_skill() -> void:
	if _selected_pawn != player_pawn or not player_pawn.is_alive():
		return
	if not player_controller.order_skill():
		return
	_update_hud()

## 数字键技能入口：按技能栏顺序解析具体技能，对不存在/未配置的槽位保持完全无操作。
func _handle_cast_skill_slot(index: int) -> void:
	if player_pawn.data == null:
		return
	var skills: Array[ActiveSkillDefinition] = player_pawn.data.get_active_skills()
	if index < 0 or index >= skills.size():
		return
	_request_selected_skill(skills[index])

## 技能栏点击与数字键共用唯一命令路由；控制器负责目标、冷却与灵力的最终裁决。
func _request_selected_skill(skill: ActiveSkillDefinition) -> void:
	if _selected_pawn != player_pawn or not player_pawn.is_alive():
		return
	if not player_controller.order_skill_instance(skill):
		return
	_update_hud()

func _on_skill_bar_skill_requested(skill: ActiveSkillDefinition) -> void:
	_request_selected_skill(skill)

func _pawn_at_screen_position(screen_position: Vector2) -> Pawn:
	var world_position: Vector2 = _screen_to_world(screen_position)
	for child: Node in $Pawns.get_children():
		var candidate: Pawn = child as Pawn
		if candidate != null and candidate.is_alive() and world_position.distance_to(candidate.global_position) <= PAWN_CLICK_RADIUS:
			return candidate
	return null

func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position

## 选中状态是唯一接入点：同一个分支里同步信息卡的绑定 / 解绑，避免两条状态流各自维护。
func _set_selected_pawn(new_selection: Pawn) -> void:
	if _selected_pawn != null and is_instance_valid(_selected_pawn):
		_selected_pawn.set_selected(false)
	_selected_pawn = new_selection
	if _selected_pawn != null and is_instance_valid(_selected_pawn) and _selected_pawn.is_alive():
		_selected_pawn.set_selected(true)
		info_panel.bind_pawn(_selected_pawn)
		skill_bar.bind_pawn(_selected_pawn)
	else:
		_selected_pawn = null
		info_panel.unbind()
		skill_bar.unbind()
	_update_hud()

## 暂停是唯一接入点：暂停时信息卡给完整信息，战斗中给精简信息。
func _set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_overlay.visible = value
	pause_state_label.text = "游戏已暂停" if value else "实时运行中"
	info_panel.set_compact(not value)
	_update_hud()

func _update_hud() -> void:
	instructions_label.text = "左键：选择玩家 Pawn    右键：移动/攻击目标    1~6：主动技能    Q：默认技能    空格：暂停/恢复"
	if _selected_pawn == null:
		selected_label.text = "未选中单位"
		order_label.text = "指令：-"
		skill_label.text = "技能：-"
		build_label.text = "Build：-"
		return

	var selected_lines: Array[String] = [
		_selected_pawn.data.display_name,
		"阵营：%s" % _selected_pawn.data.faction,
		"HP：%.0f / %.0f    护盾：%.0f / %.0f" % [
			_selected_pawn.current_health,
			_selected_pawn.data.max_health,
			_selected_pawn.current_shield,
			_selected_pawn.data.max_shield,
		],
	]
	if _selected_pawn.max_spirit > 0.0:
		selected_lines.append("灵力：%.0f / %.0f" % [_selected_pawn.current_spirit, _selected_pawn.max_spirit])
	selected_lines.append("状态：%s" % _selected_pawn.get_state_label())
	selected_label.text = "\n".join(selected_lines)
	order_label.text = "指令：%s" % player_controller.get_order_description()
	skill_label.text = _describe_active_skill(_selected_pawn)
	build_label.text = _describe_build(_selected_pawn)

## HUD Build 行完全只读：境界、功法/主动/被动占用与容量，Build 有问题时直接给出首条原因。
## 容量与占用来自 Pawn.get_build_loadout()，规则来自 BuildValidator，UI 不重复实现任何规则。
func _describe_build(pawn: Pawn) -> String:
	if pawn == null or pawn.data == null:
		return "Build：-"
	var realm: RealmDefinition = pawn.get_realm()
	if realm == null or not realm.is_configured():
		return "境界：无    Build：不适用"

	var loadout: BuildLoadout = pawn.get_build_loadout()
	var line: String = "境界：%s    功法 %d / %d    主动 %d / %d    被动 %d / %d" % [
		realm.display_name,
		loadout.get_used_slots(RealmDefinition.KIND_TECHNIQUE),
		loadout.get_capacity(RealmDefinition.KIND_TECHNIQUE),
		loadout.get_used_slots(RealmDefinition.KIND_ACTIVE_SKILL),
		loadout.get_capacity(RealmDefinition.KIND_ACTIVE_SKILL),
		loadout.get_used_slots(RealmDefinition.KIND_PASSIVE_SKILL),
		loadout.get_capacity(RealmDefinition.KIND_PASSIVE_SKILL),
	]
	var validation: BuildValidationResult = pawn.get_build_validation()
	if validation.has_errors():
		line += "    Build：%s" % validation.get_summary()
	return line

func _on_health_changed(changed_pawn: Pawn, _current_health: float, _max_health: float) -> void:
	if changed_pawn == _selected_pawn:
		_update_hud()

func _on_shield_changed(changed_pawn: Pawn, _current_shield: float, _max_shield: float) -> void:
	if changed_pawn == _selected_pawn:
		_update_hud()

func _on_spirit_changed(changed_pawn: Pawn, _current_spirit: float, _max_spirit: float) -> void:
	if changed_pawn == _selected_pawn:
		_update_hud()

func _on_player_state_changed(_changed_pawn: Pawn, _new_state: int) -> void:
	_update_hud()

## HUD 技能行完全只读：技能名、Q 键位、灵力消耗、剩余冷却与不可用原因。
## 资源与冷却数值仍由 Pawn / ResourcePoolComponent 持有，这里只做展示。
func _describe_active_skill(pawn: Pawn) -> String:
	if pawn == null or pawn.data == null or pawn.data.get_primary_active_skill() == null:
		return "技能：无"
	var skill: ActiveSkillDefinition = pawn.data.get_primary_active_skill()
	if not skill.is_configured():
		return "技能：无"

	var cost: float = skill.get_normalized_spirit_cost()
	var header: String = "技能：[Q] %s    消耗 %.0f 灵力" % [skill.display_name, cost]
	var remaining: float = pawn.get_skill_cooldown_remaining(skill.id)
	if remaining > 0.0:
		return "%s    冷却中 %.1fs" % [header, remaining]
	if cost > 0.0 and pawn.current_spirit < cost:
		return "%s    灵力不足 %.0f / %.0f" % [header, pawn.current_spirit, pawn.max_spirit]
	return "%s    可用" % header

func _on_player_skill_cooldown_changed(changed_pawn: Pawn, _skill_id: StringName, _remaining: float) -> void:
	if changed_pawn == _selected_pawn:
		_update_hud()

func _on_player_skill_cast(changed_pawn: Pawn, _skill: ActiveSkillDefinition, _target: Pawn) -> void:
	if changed_pawn == _selected_pawn or changed_pawn == player_pawn:
		_update_hud()

func _on_pawn_died(changed_pawn: Pawn) -> void:
	if changed_pawn == _selected_pawn:
		# 选中单位阵亡：复用选中路由，信息卡与 HUD 同步清理。
		_set_selected_pawn(null)
		return
	_update_hud()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false