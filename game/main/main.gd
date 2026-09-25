extends Node2D

const PAWN_CLICK_RADIUS: float = 30.0

## 单位与控制器引用在换遭遇时会被整体替换，因此不能用 @onready 一次性捕获；
## 统一由 _refresh_pawn_references() 在 encounter_started 时刷新（INC-CORE-008）。
var player_pawn: Pawn
var enemy_pawn: Pawn
var player_controller: PlayerController
var ai_controller: AIController

@onready var encounter_session: EncounterSession = $EncounterSession
@onready var encounter_panel: EncounterPanel = $HUD/BottomLeftDock/EncounterPanel
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
## 目标高亮由主场景统一持有，确保切换技能、取消、确认和单位死亡时都能清理旧引用。
var _targeting_highlighted_pawn: Pawn

func _ready() -> void:
	_connect_encounter_signals()
	if not skill_bar.skill_requested.is_connected(_on_skill_bar_skill_requested):
		skill_bar.skill_requested.connect(_on_skill_bar_skill_requested)
	if not skill_bar.targeting_started.is_connected(_on_skill_targeting_started):
		skill_bar.targeting_started.connect(_on_skill_targeting_started)
	if not skill_bar.targeting_cancelled.is_connected(_on_skill_targeting_cancelled):
		skill_bar.targeting_cancelled.connect(_on_skill_targeting_cancelled)
	_set_paused(false)
	# 开机默认打谁由世界层数据（EncounterSession.initial_encounter）决定，
	# main.gd 只负责发起并等 encounter_started 回来刷新引用。
	encounter_session.start_initial_encounter()
	_update_hud()


## 遭遇接线（INC-CORE-008 的全部新增职责）：只做信号转发与引用刷新，不新增战斗/秘境判定。
func _connect_encounter_signals() -> void:
	if not encounter_panel.encounter_selected.is_connected(_on_encounter_selected):
		encounter_panel.encounter_selected.connect(_on_encounter_selected)
	if not encounter_panel.restart_requested.is_connected(_on_encounter_restart_requested):
		encounter_panel.restart_requested.connect(_on_encounter_restart_requested)
	if not encounter_session.encounter_started.is_connected(_on_encounter_started):
		encounter_session.encounter_started.connect(_on_encounter_started)
	if not encounter_session.encounter_finished.is_connected(_on_encounter_finished):
		encounter_session.encounter_finished.connect(_on_encounter_finished)


func _on_encounter_selected(encounter: EncounterDefinition) -> void:
	encounter_session.begin(encounter)


func _on_encounter_restart_requested() -> void:
	encounter_session.restart()


## 起局唯一入口：先让瞄准/高亮失效（旧单位已退场），再整体刷新引用与选中态，最后更新面板文本。
func _on_encounter_started(encounter: EncounterDefinition, _player: Pawn, _enemy: Pawn) -> void:
	_cancel_skill_targeting()
	_refresh_pawn_references()
	encounter_panel.set_active_encounter(encounter)
	encounter_panel.set_running(true)
	encounter_panel.set_status(
		"%s：%s" % [EncounterSession.get_outcome_label(EncounterSession.State.RUNNING), encounter.display_name]
	)


## 结算只改面板文本：胜负由 EncounterSession 判定，主场景不复制状态机。
func _on_encounter_finished(encounter: EncounterDefinition, outcome: int) -> void:
	encounter_panel.set_running(false)
	encounter_panel.set_status("%s：%s" % [EncounterSession.get_outcome_label(outcome), encounter.display_name])
	_update_hud()


## 换遭遇后的唯一引用刷新点：单位 / 控制器 / HUD 信号 / 选中态一起更新，避免悬空引用。
func _refresh_pawn_references() -> void:
	# 选中态跟随「玩家身份」而不是跟随某个节点实例：换遭遇前选中的是玩家，换完仍然选中玩家；
	# 换遭遇前没有选中（例如刚进场景）就保持不选中，避免开局凭空多出一个选中单位。
	var keep_player_selection: bool = _selected_pawn != null and _selected_pawn == player_pawn
	_disconnect_pawn_signals()
	player_pawn = encounter_session.get_player_pawn()
	enemy_pawn = encounter_session.get_enemy_pawn()
	player_controller = player_pawn.get_controller() as PlayerController if player_pawn != null else null
	ai_controller = enemy_pawn.get_controller() as AIController if enemy_pawn != null else null
	_connect_pawn_signals()
	_set_selected_pawn(player_pawn if keep_player_selection else null)


## Pawn 信号原先写在 main.tscn 的固定节点连接里；单位改为运行时创建后，接线随引用刷新一起搬运。
func _connect_pawn_signals() -> void:
	if player_pawn != null:
		if not player_pawn.died.is_connected(_on_pawn_died):
			player_pawn.died.connect(_on_pawn_died)
		if not player_pawn.health_changed.is_connected(_on_health_changed):
			player_pawn.health_changed.connect(_on_health_changed)
		if not player_pawn.shield_changed.is_connected(_on_shield_changed):
			player_pawn.shield_changed.connect(_on_shield_changed)
		if not player_pawn.spirit_changed.is_connected(_on_spirit_changed):
			player_pawn.spirit_changed.connect(_on_spirit_changed)
		if not player_pawn.state_changed.is_connected(_on_player_state_changed):
			player_pawn.state_changed.connect(_on_player_state_changed)
		if not player_pawn.skill_cast.is_connected(_on_player_skill_cast):
			player_pawn.skill_cast.connect(_on_player_skill_cast)
		if not player_pawn.skill_cooldown_changed.is_connected(_on_player_skill_cooldown_changed):
			player_pawn.skill_cooldown_changed.connect(_on_player_skill_cooldown_changed)
	if enemy_pawn != null and not enemy_pawn.died.is_connected(_on_pawn_died):
		enemy_pawn.died.connect(_on_pawn_died)


func _disconnect_pawn_signals() -> void:
	if player_pawn != null and is_instance_valid(player_pawn):
		_disconnect_if_connected(player_pawn.died, _on_pawn_died)
		_disconnect_if_connected(player_pawn.health_changed, _on_health_changed)
		_disconnect_if_connected(player_pawn.shield_changed, _on_shield_changed)
		_disconnect_if_connected(player_pawn.spirit_changed, _on_spirit_changed)
		_disconnect_if_connected(player_pawn.state_changed, _on_player_state_changed)
		_disconnect_if_connected(player_pawn.skill_cast, _on_player_skill_cast)
		_disconnect_if_connected(player_pawn.skill_cooldown_changed, _on_player_skill_cooldown_changed)
	if enemy_pawn != null and is_instance_valid(enemy_pawn):
		_disconnect_if_connected(enemy_pawn.died, _on_pawn_died)


func _disconnect_if_connected(signal_ref: Signal, target: Callable) -> void:
	if signal_ref.is_connected(target):
		signal_ref.disconnect(target)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("cancel_targeting") and skill_bar.is_targeting():
		_cancel_skill_targeting()
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

	# 目标选择期间只更新悬停反馈，不把鼠标移动解释为移动/攻击命令。
	if event is InputEventMouseMotion and skill_bar.is_targeting():
		_update_target_highlight(event.position)
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
	# TARGETING 优先于普通选中：合法点击确认一次技能命令，非法/空白点击保持瞄准但不改选中。
	if skill_bar.is_targeting():
		_handle_targeting_click(screen_position)
		return

	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn != null and hit_pawn == player_pawn and hit_pawn.is_alive():
		_set_selected_pawn(hit_pawn)
	else:
		_set_selected_pawn(null)

func _handle_command(screen_position: Vector2) -> void:
	# 右键在目标选择期间只取消，不下达移动/普通攻击命令。
	if skill_bar.is_targeting():
		_cancel_skill_targeting()
		return
	if player_pawn == null or _selected_pawn != player_pawn or not player_pawn.is_alive():
		return

	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn != null and hit_pawn != player_pawn and hit_pawn.is_alive():
		player_controller.order_attack(hit_pawn)
	else:
		player_controller.order_move(_screen_to_world(screen_position))
	_update_hud()

## Q 键技能入口：默认选择第一个已配置主动技能，并统一经过 SkillBar 的 SELF/TARGETING 分流。
func _handle_cast_skill() -> void:
	if player_pawn == null or player_pawn.data == null:
		return
	_request_selected_skill(player_pawn.data.get_primary_active_skill())

## 数字键技能入口：按技能栏顺序解析具体技能，对不存在/未配置的槽位保持完全无操作。
func _handle_cast_skill_slot(index: int) -> void:
	if player_pawn == null or player_pawn.data == null:
		return
	var skills: Array[ActiveSkillDefinition] = player_pawn.data.get_active_skills()
	if index < 0 or index >= skills.size():
		return
	_request_selected_skill(skills[index])

## 所有主动技能输入的唯一前置路由：SELF 直发，需要目标的技能进入 SkillBar TARGETING。
func _request_selected_skill(skill: ActiveSkillDefinition) -> void:
	if player_pawn == null or _selected_pawn != player_pawn or not player_pawn.is_alive():
		return
	if skill == null:
		return
	# Q/数字键与技能栏共用 Pawn 的容量投影；超容量技能在输入层保持零副作用。
	if not player_pawn.is_active_skill_enabled(skill):
		_update_hud()
		return
	skill_bar.request_skill(skill)
	_update_hud()

## SkillBar 已裁决为可直接施放的请求（当前为 SELF）：主场景只负责转交控制器。
func _on_skill_bar_skill_requested(skill: ActiveSkillDefinition) -> void:
	_order_selected_skill(skill)

## 目标确认的唯一控制器入口；成功后清理瞄准状态，失败时保留状态以便玩家重新选择。
func _order_selected_skill(skill: ActiveSkillDefinition, target: Pawn = null) -> bool:
	if player_pawn == null or _selected_pawn != player_pawn or not player_pawn.is_alive():
		return false
	if not player_controller.order_skill_instance(skill, target):
		return false
	_clear_target_highlight()
	if skill_bar.is_targeting():
		skill_bar.cancel_targeting()
	_update_hud()
	return true

## 左键确认：只接受 Pawn.is_valid_skill_target() 的最终裁决结果；非法点击不产生任何命令副作用。
func _handle_targeting_click(screen_position: Vector2) -> void:
	var skill: ActiveSkillDefinition = skill_bar.get_targeting_skill()
	if skill == null:
		_cancel_skill_targeting()
		return
	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn == null or player_pawn == null or not player_pawn.is_valid_skill_target(skill, hit_pawn):
		_clear_target_highlight()
		return
	if not _order_selected_skill(skill, hit_pawn):
		# 技能/目标在确认瞬间失效时自动取消，避免保留无法完成的旧瞄准状态。
		_cancel_skill_targeting()

## 悬停只更新表现层高亮，合法性始终询问 Pawn 的目标裁决，不在 Main 复制敌我规则。
func _update_target_highlight(screen_position: Vector2) -> void:
	var skill: ActiveSkillDefinition = skill_bar.get_targeting_skill()
	var candidate: Pawn = _pawn_at_screen_position(screen_position)
	if skill == null or candidate == null or player_pawn == null or not player_pawn.is_valid_skill_target(skill, candidate):
		_clear_target_highlight()
		return
	if _targeting_highlighted_pawn == candidate and candidate.is_target_highlight_visible():
		return
	_clear_target_highlight()
	candidate.set_target_highlight(true, true)
	_targeting_highlighted_pawn = candidate

func _clear_target_highlight() -> void:
	if _targeting_highlighted_pawn != null and is_instance_valid(_targeting_highlighted_pawn):
		_targeting_highlighted_pawn.set_target_highlight(false)
	_targeting_highlighted_pawn = null

func _cancel_skill_targeting() -> void:
	var was_targeting: bool = skill_bar.is_targeting()
	_clear_target_highlight()
	if was_targeting:
		skill_bar.cancel_targeting()
	_update_hud()

func _on_skill_targeting_started(_skill: ActiveSkillDefinition) -> void:
	_clear_target_highlight()
	_update_hud()

func _on_skill_targeting_cancelled() -> void:
	_clear_target_highlight()
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
	if skill_bar.is_targeting():
		instructions_label.text = "目标选择：左键合法目标确认    右键/Esc 取消    空格：暂停/恢复"
	else:
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
	if player_controller == null:
		order_label.text = "指令：-"
	else:
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
	if not pawn.is_active_skill_enabled(skill):
		return "%s    Build 禁用：超出主动技能容量" % header
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
	# 当前高亮目标或施法者死亡时，目标选择必须在任何后续命令前自动失效。
	if skill_bar.is_targeting() and (
		changed_pawn == player_pawn or changed_pawn == _targeting_highlighted_pawn
	):
		_cancel_skill_targeting()
	if changed_pawn == _selected_pawn:
		# 选中单位阵亡：复用选中路由，信息卡与 HUD 同步清理。
		_set_selected_pawn(null)
		return
	_update_hud()

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false