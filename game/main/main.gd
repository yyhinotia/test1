extends Node2D

const PAWN_CLICK_RADIUS: float = 30.0

## 宗门可参悟功法目录：由 main.tscn 注入，主场景只负责把目录交给面板并转发选择。
@export var sect_techniques: Array[TechniqueDefinition] = []

## 单位与控制器引用在换遭遇时会被整体替换，因此不能用 @onready 一次性捕获；
## 统一由 _refresh_pawn_references() 在 encounter_started 时刷新（INC-CORE-008）。
var player_pawn: Pawn
var enemy_pawn: Pawn
var player_controller: PlayerController
var ai_controller: AIController

@onready var encounter_session: EncounterSession = $EncounterSession
@onready var encounter_panel: EncounterPanel = $HUD/BottomLeftDock/EncounterPanel
@onready var dungeon_run: DungeonRun = $DungeonRun
@onready var dungeon_panel: DungeonPanel = $HUD/BottomLeftDock/DungeonPanel
@onready var sect_state: SectState = $SectState
@onready var sect_panel: SectPanel = $HUD/BottomLeftDock/SectPanel
@onready var instructions_label: Label = $HUD/HudMargin/HudPanel/HudContent/InstructionsLabel
@onready var selected_label: Label = $HUD/HudMargin/HudPanel/HudContent/SelectedLabel
@onready var order_label: Label = $HUD/HudMargin/HudPanel/HudContent/OrderLabel
@onready var skill_label: Label = $HUD/HudMargin/HudPanel/HudContent/SkillLabel
@onready var build_label: Label = $HUD/HudMargin/HudPanel/HudContent/BuildLabel
@onready var pause_state_label: Label = $HUD/PauseStateLabel
@onready var pause_overlay: Control = $HUD/PauseOverlay
@onready var info_panel: PawnInfoPanel = $HUD/BottomLeftDock/PawnInfoPanel
@onready var skill_bar: SkillBar = $HUD/BottomLeftDock/SkillBar
@onready var build_loadout_panel: BuildLoadoutPanel = $HUD/BuildLoadoutPanel

var _selected_pawn: Pawn
## 目标高亮由主场景统一持有，确保切换技能、取消、确认和单位死亡时都能清理旧引用。
var _targeting_highlighted_pawn: Pawn
## 同一局秘境只允许把收益入账一次；run_started 时重置，防止重复广播造成重复入账。
var _dungeon_reward_committed: bool = false

func _ready() -> void:
	_connect_encounter_signals()
	_connect_dungeon_signals()
	_connect_sect_signals()
	sect_panel.bind_state(sect_state)
	sect_panel.set_learnable_techniques(sect_techniques)
	if not skill_bar.skill_requested.is_connected(_on_skill_bar_skill_requested):
		skill_bar.skill_requested.connect(_on_skill_bar_skill_requested)
	if not skill_bar.targeting_started.is_connected(_on_skill_targeting_started):
		skill_bar.targeting_started.connect(_on_skill_targeting_started)
	if not skill_bar.targeting_cancelled.is_connected(_on_skill_targeting_cancelled):
		skill_bar.targeting_cancelled.connect(_on_skill_targeting_cancelled)
	_set_paused(false)
	# 开机默认打谁由世界层数据决定：优先进入秘境第 1 间房（DungeonRun.default_dungeon），
	# 未配置秘境时回落到单场遭遇（EncounterSession.initial_encounter）；main.gd 只负责发起。
	if not dungeon_run.start_default_dungeon():
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
	# 秘境进行中不接受单场重开：否则会绕过 DungeonRun 直接重置当前房间的损耗。
	if dungeon_run.is_active():
		return
	encounter_session.restart()


## 起局唯一入口：先让瞄准/高亮失效（旧单位已退场），再整体刷新引用与选中态，最后更新面板文本。
func _on_encounter_started(encounter: EncounterDefinition, _player: Pawn, _enemy: Pawn) -> void:
	_cancel_skill_targeting()
	_refresh_pawn_references()
	sect_state.bind_cultivator(player_pawn)
	encounter_panel.set_active_encounter(encounter)
	encounter_panel.set_running(true)
	# 秘境进行中额外锁住「重新挑战」：单场重开会白送一次满状态，破坏损耗累积。
	encounter_panel.set_restart_locked(dungeon_run.is_active())
	# INC-UI-018：Build 切换只允许发生在两轮战斗之间，战斗中锁定（面板保留读数但不接受点击）。
	build_loadout_panel.set_switch_locked(true)
	encounter_panel.set_status(
		"%s：%s" % [EncounterSession.get_outcome_label(EncounterSession.State.RUNNING), encounter.display_name]
	)


## 结算只改面板文本：胜负由 EncounterSession 判定，主场景不复制状态机。
func _on_encounter_finished(encounter: EncounterDefinition, outcome: int) -> void:
	# 秘境进行中时单场入口保持锁定：清空一间房不等于本局结束。
	encounter_panel.set_running(dungeon_run.is_active())
	# INC-UI-018：战斗结束后解锁 Build 切换，让玩家先看到问题再自己决定要不要重构。
	build_loadout_panel.set_switch_locked(false)
	encounter_panel.set_status("%s：%s" % [EncounterSession.get_outcome_label(outcome), encounter.display_name])
	_update_hud()


## 秘境接线（INC-CORE-009）：只做信号转发与引用刷新，不新增房间 / 收益判定。
func _connect_dungeon_signals() -> void:
	if not dungeon_panel.advance_requested.is_connected(_on_dungeon_advance_requested):
		dungeon_panel.advance_requested.connect(_on_dungeon_advance_requested)
	if not dungeon_panel.retreat_requested.is_connected(_on_dungeon_retreat_requested):
		dungeon_panel.retreat_requested.connect(_on_dungeon_retreat_requested)
	if not dungeon_panel.restart_requested.is_connected(_on_dungeon_restart_requested):
		dungeon_panel.restart_requested.connect(_on_dungeon_restart_requested)
	if not dungeon_run.run_started.is_connected(_on_dungeon_run_started):
		dungeon_run.run_started.connect(_on_dungeon_run_started)
	if not dungeon_run.room_cleared.is_connected(_on_dungeon_room_cleared):
		dungeon_run.room_cleared.connect(_on_dungeon_room_cleared)
	if not dungeon_run.run_finished.is_connected(_on_dungeon_run_finished):
		dungeon_run.run_finished.connect(_on_dungeon_run_finished)


## 「继续深入」：面板只表示玩家想继续，能不能推进由 DungeonRun 判定。
func _on_dungeon_advance_requested() -> void:
	dungeon_run.advance()


## 「见好就收」：收益是否保留由 DungeonRun 决定，主场景不复制结算规则。
func _on_dungeon_retreat_requested() -> void:
	dungeon_run.retreat()


## 「重新开始秘境」：只把当前秘境定义交回 DungeonRun，进度与收益由它自己重置。
func _on_dungeon_restart_requested() -> void:
	var dungeon: DungeonDefinition = dungeon_run.get_active_dungeon()
	if dungeon == null:
		dungeon = dungeon_run.default_dungeon
	dungeon_run.start(dungeon)


## 进入一间房（含第一间与继续深入）：面板刷新为「本层进行中」，抉择入口先关掉。
func _on_dungeon_run_started(_dungeon: DungeonDefinition, _room_index: int) -> void:
	_dungeon_reward_committed = false
	_refresh_dungeon_panel()
	dungeon_panel.set_awaiting_decision(false)
	dungeon_panel.set_can_restart(false)
	dungeon_panel.set_status(_compose_dungeon_status(dungeon_run.get_state()))


## 清空一间房：深度与累计收益刷新为 DungeonRun 的事实，非终局房打开「继续 / 撤退」。
func _on_dungeon_room_cleared(_dungeon: DungeonDefinition, _room_index: int, _reward: int, _total: int) -> void:
	_refresh_dungeon_panel()
	dungeon_panel.set_awaiting_decision(dungeon_run.is_awaiting_decision())
	dungeon_panel.set_status(_compose_dungeon_status(dungeon_run.get_state()))


## 本局唯一一次终局：面板显示结局与最终灵石，重开入口打开，单场入口恢复可用。
func _on_dungeon_run_finished(_dungeon: DungeonDefinition, outcome: int, earned_spirit_stones: int) -> void:
	if not _dungeon_reward_committed:
		_dungeon_reward_committed = true
		sect_state.deposit_spirit_stones(earned_spirit_stones)
	_refresh_dungeon_panel()
	dungeon_panel.set_awaiting_decision(false)
	dungeon_panel.set_can_restart(true)
	dungeon_panel.set_status(
		"%s：最终灵石 %d" % [DungeonRun.get_outcome_label(outcome), earned_spirit_stones]
	)
	encounter_panel.set_restart_locked(false)
	encounter_panel.set_running(false)
	_update_hud()


## 面板刷新的唯一入口：秘境定义、深度、收益都从 DungeonRun 读，主场景不自己算。
func _refresh_dungeon_panel() -> void:
	var dungeon: DungeonDefinition = dungeon_run.get_active_dungeon()
	if dungeon == null:
		return
	dungeon_panel.set_dungeon(dungeon)
	dungeon_panel.set_depth(dungeon_run.get_depth(), dungeon_run.get_room_count())
	dungeon_panel.set_reward(dungeon_run.get_earned_spirit_stones())


## 秘境状态文案：状态词来自 DungeonRun，层名来自当前房间定义，主场景只拼接。
func _compose_dungeon_status(outcome: int) -> String:
	var room: DungeonRoom = dungeon_run.get_current_room()
	var room_name: String = room.display_name if room != null else "-"
	return "%s：%s" % [DungeonRun.get_outcome_label(outcome), room_name]


## 宗门接线（INC-CORE-010）：只把面板的七个玩家意图转发给 SectState，
## 收益入账与修士绑定都发生在既有信号回调里，主场景不判断资源是否足够。
func _connect_sect_signals() -> void:
	if not sect_panel.upgrade_requested.is_connected(_on_sect_upgrade_requested):
		sect_panel.upgrade_requested.connect(_on_sect_upgrade_requested)
	if not sect_panel.cultivate_requested.is_connected(_on_sect_cultivate_requested):
		sect_panel.cultivate_requested.connect(_on_sect_cultivate_requested)
	if not sect_panel.harvest_requested.is_connected(_on_sect_harvest_requested):
		sect_panel.harvest_requested.connect(_on_sect_harvest_requested)
	if not sect_panel.learn_requested.is_connected(_on_sect_learn_requested):
		sect_panel.learn_requested.connect(_on_sect_learn_requested)
	if not sect_panel.strengthen_requested.is_connected(_on_sect_strengthen_requested):
		sect_panel.strengthen_requested.connect(_on_sect_strengthen_requested)
	if not sect_panel.refine_pill_requested.is_connected(_on_sect_refine_pill_requested):
		sect_panel.refine_pill_requested.connect(_on_sect_refine_pill_requested)
	if not sect_panel.use_pill_requested.is_connected(_on_sect_use_pill_requested):
		sect_panel.use_pill_requested.connect(_on_sect_use_pill_requested)


func _on_sect_upgrade_requested(facility_id: StringName) -> void:
	sect_state.upgrade_facility(facility_id)


func _on_sect_cultivate_requested() -> void:
	sect_state.cultivate()


func _on_sect_harvest_requested() -> void:
	sect_state.harvest_spirit_field()


## 面板只发功法 id；主场景把它映射回注入的正式目录，失败由 SectState 统一返回 false。
func _on_sect_learn_requested(technique_id: StringName) -> void:
	for technique: TechniqueDefinition in sect_techniques:
		if technique != null and technique.id == technique_id:
			sect_state.learn_technique_from_pavilion(technique)
			return


func _on_sect_strengthen_requested() -> void:
	sect_state.strengthen_weapon()


func _on_sect_refine_pill_requested() -> void:
	sect_state.refine_pill()


func _on_sect_use_pill_requested() -> void:
	sect_state.use_pill()

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

## 左键是唯一的世界交互入口（INC-CORE-013）：TARGETING 期间确认技能目标，其余情况按命中对象分流。
func _handle_select(screen_position: Vector2) -> void:
	# TARGETING 优先于普通选中：合法点击确认一次技能命令，非法/空白点击保持瞄准但不改选中。
	if skill_bar.is_targeting():
		_handle_targeting_click(screen_position)
		return

	# 命中任意存活单位（含敌方）一律进入选中态：敌方信息由信息卡承担，命令仍只由玩家自己的单位执行。
	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn != null:
		_set_selected_pawn(hit_pawn)
		return

	# 空白地：选中玩家单位时下达移动命令，否则只清空选中，不产生任何命令副作用。
	if _can_command_player():
		player_controller.order_move(_screen_to_world(screen_position))
		_update_hud()
		return
	_set_selected_pawn(null)

## 右键不再是移动入口（INC-CORE-013）：只保留取消瞄准与「对敌方单位下达普通攻击」两条职责。
func _handle_command(screen_position: Vector2) -> void:
	# 右键在目标选择期间只取消，不下达移动/普通攻击命令。
	if skill_bar.is_targeting():
		_cancel_skill_targeting()
		return
	if not _can_command_player():
		return

	var hit_pawn: Pawn = _pawn_at_screen_position(screen_position)
	if hit_pawn == null or hit_pawn == player_pawn or not hit_pawn.is_alive():
		# 右键点地面 / 己方不再产生任何命令：移动只能通过左键点击地面下达。
		return
	player_controller.order_attack(hit_pawn)
	_update_hud()

## 命令前置条件只有一个来源：玩家自己的单位被选中且存活；选中敌方时任何命令都不会误发。
func _can_command_player() -> bool:
	return player_pawn != null and _selected_pawn == player_pawn and player_pawn.is_alive()

## Q 键技能入口：默认选择第一个已装配主动技能，并统一经过 SkillBar 的 SELF/TARGETING 分流。
func _handle_cast_skill() -> void:
	if player_pawn == null or player_pawn.data == null:
		return
	var equipped: Array[ActiveSkillDefinition] = player_pawn.get_equipped_active_skills()
	_request_selected_skill(equipped[0] if not equipped.is_empty() else null)

## 数字键技能入口：按技能栏顺序解析具体技能，对不存在/未配置的槽位保持完全无操作。
func _handle_cast_skill_slot(index: int) -> void:
	if player_pawn == null or player_pawn.data == null:
		return
	# 数字键按装配顺序解析槽位，禁止直接消费 PawnData.active_skills。
	var skills: Array[ActiveSkillDefinition] = player_pawn.get_equipped_active_skills()
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

## 选中状态是唯一接入点：同一个分支里同步信息卡、玩家专属面板与 HUD 订阅，避免多条状态流各自维护。
## 选中敌方是合法状态（INC-UI-019）：信息卡照常绑定，但技能栏 / Build 面板只属于玩家自己的单位。
func _set_selected_pawn(new_selection: Pawn) -> void:
	if _selected_pawn != null and is_instance_valid(_selected_pawn):
		_selected_pawn.set_selected(false)
	_selected_pawn = new_selection
	if _selected_pawn != null and is_instance_valid(_selected_pawn) and _selected_pawn.is_alive():
		_selected_pawn.set_selected(true)
		_watch_selected_pawn_signals(_selected_pawn)
		info_panel.bind_pawn(_selected_pawn)
		if _binds_player_panels(_selected_pawn):
			skill_bar.bind_pawn(_selected_pawn)
			build_loadout_panel.bind_pawn(_selected_pawn)
		else:
			skill_bar.unbind()
			build_loadout_panel.unbind()
	else:
		_selected_pawn = null
		info_panel.unbind()
		skill_bar.unbind()
		build_loadout_panel.unbind()
	_update_hud()

## 玩家专属面板（技能栏 / Build 面板）只跟随玩家自己的单位；选中敌方时全部解绑，避免越权入口。
func _binds_player_panels(pawn: Pawn) -> bool:
	return pawn != null and pawn == player_pawn

## 选中态决定 HUD 订阅：任意被选中的单位都要在资源 / 状态变化时刷新选中行。
## 这里只做幂等追加连接、不反向断开：回调内部按 `changed_pawn == _selected_pawn` 过滤，
## 而未被选中的旧单位会在阵亡 / 换遭遇时随节点一起销毁，连接随之释放。
func _watch_selected_pawn_signals(pawn: Pawn) -> void:
	_connect_signal_if_needed(pawn.health_changed, _on_health_changed)
	_connect_signal_if_needed(pawn.shield_changed, _on_shield_changed)
	_connect_signal_if_needed(pawn.spirit_changed, _on_spirit_changed)
	_connect_signal_if_needed(pawn.state_changed, _on_player_state_changed)
	_connect_signal_if_needed(pawn.died, _on_pawn_died)

func _connect_signal_if_needed(source: Signal, target: Callable) -> void:
	if not source.is_connected(target):
		source.connect(target)

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
		instructions_label.text = "左键：选择单位 / 移动到地面    右键：取消瞄准 / 攻击敌方    1~6：主动技能    Q：默认技能    空格：暂停/恢复"
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
	# 指令行表达的是玩家自己单位的当前命令；选中敌方或未选中时不得借用玩家指令，避免信息串台。
	if player_controller == null or _selected_pawn != player_pawn:
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