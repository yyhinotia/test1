extends SceneTree

## 自建 headless 验证：Pawn 信息卡（PawnInfoPanel）在真实分辨率下的矩形与文本可见性。
## 覆盖：绑定后的文本与资源行、精简/完整模式、无灵力单位隐藏灵力行、多分辨率下不越界且避开顶部 HUD。
## 运行方式：
##   godot --headless --path . --script res://test/headless/pawn_info_panel_display_test.gd

const PANEL_SCENE_PATH: String = "res://game/ui/pawn_info_panel.tscn"
const PLAYER_PAWN_SCENE_PATH: String = "res://game/pawns/player_pawn.tscn"
const ENEMY_PAWN_SCENE_PATH: String = "res://game/pawns/enemy_pawn.tscn"

const CONTENT_PATH: String = "Margin/Panel/Content"
const HEADER_SECTION_PATH: String = "Margin/Panel/Content/HeaderSection"
const VITAL_SECTION_PATH: String = "Margin/Panel/Content/VitalSection"
const ATTRIBUTE_SECTION_PATH: String = "Margin/Panel/Content/AttributeSection"
const BUILD_SECTION_PATH: String = "Margin/Panel/Content/BuildSection"
const CULTIVATION_SECTION_PATH: String = "Margin/Panel/Content/CultivationSection"
const CULTIVATION_LABEL_PATH: String = "Margin/Panel/Content/CultivationSection/CultivationLabel"
const CULTIVATION_PROGRESS_PATH: String = "Margin/Panel/Content/CultivationSection/CultivationProgress"
const NAME_LABEL_PATH: String = "Margin/Panel/Content/HeaderSection/NameLabel"
const IDENTITY_LABEL_PATH: String = "Margin/Panel/Content/HeaderSection/IdentityLabel"
const HEALTH_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/HealthRow/ValueLabel"
const SHIELD_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/ShieldRow/ValueLabel"
const SPIRIT_LABEL_PATH: String = "Margin/Panel/Content/VitalSection/SpiritRow/ValueLabel"
const SPIRIT_ROW_PATH: String = "Margin/Panel/Content/VitalSection/SpiritRow"
const ATTRIBUTE_LABEL_PATH: String = "Margin/Panel/Content/AttributeSection/AttributeLabel"
const BUILD_LABEL_PATH: String = "Margin/Panel/Content/BuildSection/BuildLabel"

## 顶部 HUD 实际占位下沿：HudMargin 上边距 16 + 内容最小高度 246 = 262（真实窗口实测，见 reports 证据）。
## 注意 main.tscn 里写的 offset_bottom = 222 只是设计值；MarginContainer 会被内容撑到最小高度，
## 因此“信息卡不与顶部 HUD 重叠”必须以实测下沿为准，而不是以 Scene 里的 offset 为准。
const TOP_HUD_BAND_BOTTOM: float = 262.0

## 左下角 Dock 的信息卡左边距/下边距；面板本身由主场景 Dock 负责定位，headless 测试复现该矩形。
const VIEWPORT_MARGIN: float = 16.0
## 正式分辨率：项目默认窗口 1152x648，另加两种常见窗口高度。
const RESOLUTIONS: Array[Vector2] = [Vector2(1152, 648), Vector2(1152, 720), Vector2(1152, 1036)]
## project.godot 未覆盖窗口尺寸时 Godot 的默认设计分辨率。
const PROJECT_DEFAULT_VIEWPORT: Vector2 = Vector2(1152, 648)

var _failures: Array[String] = []
var _check_count: int = 0
var _host: Control
var _panel: PawnInfoPanel
var _player: Pawn
var _enemy: Pawn


func _initialize() -> void:
	await process_frame
	_host = Control.new()
	_host.size = _configured_viewport_size()
	root.add_child(_host)
	_panel = (load(PANEL_SCENE_PATH) as PackedScene).instantiate() as PawnInfoPanel
	_host.add_child(_panel)
	_player = (load(PLAYER_PAWN_SCENE_PATH) as PackedScene).instantiate() as Pawn
	_enemy = (load(ENEMY_PAWN_SCENE_PATH) as PackedScene).instantiate() as Pawn
	root.add_child(_player)
	root.add_child(_enemy)
	await _settle()
	print("DESIGN_SIZE=", _host.size, " ROOT_SIZE=", root.size)

	_check_initial_state()
	await _check_player_binding()
	await _check_compact_mode()
	await _check_enemy_without_spirit()
	await _check_layout_at_resolutions()
	_check_unbind()
	_report()


## 项目设计分辨率：headless 下根视口尺寸不可靠（实测为 64x64），布局验证以 project.godot 配置为准。
func _configured_viewport_size() -> Vector2:
	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width",
		int(PROJECT_DEFAULT_VIEWPORT.x)))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height",
		int(PROJECT_DEFAULT_VIEWPORT.y)))
	return Vector2(float(width), float(height))


## 等待布局稳定：容器改尺寸后需要若干帧才会把新矩形下发给子控件。
func _settle() -> void:
	for _frame: int in 3:
		await process_frame


## 初始状态：未绑定、不可见。
func _check_initial_state() -> void:
	_check(not _panel.is_bound(), "初始状态不应绑定任何单位")
	_check(not _panel.visible, "初始状态信息卡应隐藏")
	_check(not _panel.is_visible_in_tree(), "初始状态信息卡不应出现在可见树中")


## 绑定真实玩家单位：身份/资源/属性/Build 文本与矩形都要成立。
func _check_player_binding() -> void:
	_panel.bind_pawn(_player)
	await _settle()
	_layout_panel()
	await _settle()
	_check(_panel.is_bound(), "绑定后 is_bound() 应为 true")
	_check(_panel.visible and _panel.is_visible_in_tree(), "绑定玩家后信息卡应可见")

	var name_label: Label = _panel.get_node(NAME_LABEL_PATH)
	var identity_label: Label = _panel.get_node(IDENTITY_LABEL_PATH)
	_check(name_label.text == "测试修士", "姓名应取真实数据，实际 %s" % name_label.text)
	_check("炼气" in identity_label.text and "三层" in identity_label.text,
		"身份区应含大境界与小境界，实际 %s" % identity_label.text)
	_check("金灵根" in identity_label.text, "身份区应显示灵根，实际 %s" % identity_label.text)
	_check("剑修" in identity_label.text, "身份区应显示由功法派生的 Build 标签，实际 %s" % identity_label.text)

	var health_label: Label = _panel.get_node(HEALTH_LABEL_PATH)
	var shield_label: Label = _panel.get_node(SHIELD_LABEL_PATH)
	var spirit_label: Label = _panel.get_node(SPIRIT_LABEL_PATH)
	_check(health_label.text == "气血  120 / 120", "气血行应取真实资源池数值，实际 %s" % health_label.text)
	_check(shield_label.text == "护体  40 / 40", "护体行应取真实资源池数值，实际 %s" % shield_label.text)
	_check(spirit_label.text == "灵力  100 / 100", "灵力行应取真实资源池数值，实际 %s" % spirit_label.text)
	_check((_panel.get_node(SPIRIT_ROW_PATH) as HBoxContainer).visible, "有灵力池的单位应显示灵力行")

	var attribute_label: Label = _panel.get_node(ATTRIBUTE_LABEL_PATH)
	var build_label: Label = _panel.get_node(BUILD_LABEL_PATH)
	_check("攻击" in attribute_label.text and "移速" in attribute_label.text,
		"属性区应显示核心属性，实际 %s" % attribute_label.text)
	_check("功法" in build_label.text and "御剑斩" in build_label.text,
		"Build 区应显示功法与主动技能，实际 %s" % build_label.text)
	_check("武器  1 / 1" in build_label.text and "青锋剑（剑 · 金）" in build_label.text,
		"Build 区应显示武器槽与“类型 · 五行”标签，实际 %s" % build_label.text)

	var cultivation_section: VBoxContainer = _panel.get_node(CULTIVATION_SECTION_PATH)
	var cultivation_label: Label = _panel.get_node(CULTIVATION_LABEL_PATH)
	var cultivation_progress: ProgressBar = _panel.get_node(CULTIVATION_PROGRESS_PATH)
	_check(cultivation_section.visible, "有下一境界的单位应显示修为区")
	_check(cultivation_label.text == "修为  0%  0 / 100  → 筑基",
		"修为区应显示当前进度与下一境界，实际 %s" % cultivation_label.text)
	_check(is_zero_approx(cultivation_progress.value), "初始修为进度条应为 0")

	_layout_panel()
	_check_inside_viewport("玩家绑定")
	_check_clears_top_hud("玩家绑定")
	_check_anchored_to_bottom_left("玩家绑定")
	_check_content_fits("玩家完整模式")


## 精简模式（战斗中）只保留身份与资源区；完整模式恢复属性区与 Build 区。
func _check_compact_mode() -> void:
	# 显隐变化需要容器重排后再测量内容矩形。
	var header_section: VBoxContainer = _panel.get_node(HEADER_SECTION_PATH)
	var vital_section: VBoxContainer = _panel.get_node(VITAL_SECTION_PATH)
	var attribute_section: VBoxContainer = _panel.get_node(ATTRIBUTE_SECTION_PATH)
	var build_section: VBoxContainer = _panel.get_node(BUILD_SECTION_PATH)
	var cultivation_section: VBoxContainer = _panel.get_node(CULTIVATION_SECTION_PATH)

	_panel.set_compact(true)
	await _settle()
	_check(_panel.is_compact(), "set_compact(true) 后 is_compact() 应为 true")
	_check(not attribute_section.visible, "精简模式应隐藏属性区")
	_check(not build_section.visible, "精简模式应隐藏 Build 区")
	_check(not cultivation_section.visible, "精简模式应隐藏修为区")
	_check(header_section.visible, "精简模式应保留身份区")
	_check(vital_section.visible, "精简模式应保留资源区")
	_check_content_fits("玩家精简模式")

	_panel.set_compact(false)
	await _settle()
	_check(not _panel.is_compact(), "set_compact(false) 后 is_compact() 应为 false")
	_check(attribute_section.visible, "完整模式应恢复属性区")
	_check(build_section.visible, "完整模式应恢复 Build 区")
	_check(cultivation_section.visible, "完整模式应恢复修为区")


## 无灵力池、无境界的单位：隐藏灵力行，Build 区只给“不适用”。
func _check_enemy_without_spirit() -> void:
	_panel.bind_pawn(_enemy)
	await _settle()
	_layout_panel()
	await _settle()
	_check(_panel.get_bound_pawn() == _enemy, "重新绑定后 get_bound_pawn() 应指向新单位")
	_check(not (_panel.get_node(SPIRIT_ROW_PATH) as HBoxContainer).visible, "无灵力上限的单位不应显示灵力行")

	var health_label: Label = _panel.get_node(HEALTH_LABEL_PATH)
	_check(health_label.text == "气血  180 / 180", "敌人气血行应取自身预设数值，实际 %s" % health_label.text)

	var build_label: Label = _panel.get_node(BUILD_LABEL_PATH)
	_check(build_label.text == PawnInfoModel.BUILD_UNAVAILABLE_TEXT,
		"未配置境界的单位 Build 区应给出不适用结论，实际 %s" % build_label.text)
	_check(not (_panel.get_node(CULTIVATION_SECTION_PATH) as VBoxContainer).is_visible_in_tree(),
		"无境界单位不应显示修为区")
	_check((_panel.get_node(CULTIVATION_LABEL_PATH) as Label).text.is_empty(),
		"无境界单位的修为文案应为空")
	_check_content_fits("敌人完整模式")


## 分辨率扫描：信息卡必须始终贴右下角、不越界、不压顶部 HUD、内容不溢出。
func _check_layout_at_resolutions() -> void:
	_panel.bind_pawn(_player)
	_panel.set_compact(false)
	for resolution: Vector2 in RESOLUTIONS:
		_host.size = resolution
		await _settle()
		_layout_panel()
		await _settle()
		var context: String = "%dx%d" % [int(resolution.x), int(resolution.y)]
		_check_inside_viewport(context)
		_check_clears_top_hud(context)
		_check_anchored_to_bottom_left(context)
		_check_content_fits(context)


## 解绑：回到未绑定、不可见状态。
func _check_unbind() -> void:
	_panel.unbind()
	_check(not _panel.is_bound(), "解绑后 is_bound() 应为 false")
	_check(not _panel.visible, "解绑后信息卡应隐藏")



## headless 下没有主场景 Dock；按主场景同等的左/下 16px 规则摆放面板，以验证组合后的可见矩形。
func _layout_panel() -> void:
	_panel.position = Vector2(
		VIEWPORT_MARGIN,
		maxf(TOP_HUD_BAND_BOTTOM, _host.size.y - VIEWPORT_MARGIN - _panel.size.y)
	)


func _check_inside_viewport(context: String) -> void:
	var rect: Rect2 = _panel.get_global_rect()
	var viewport_rect: Rect2 = Rect2(Vector2.ZERO, _host.size)
	_check(rect.position.x >= viewport_rect.position.x and rect.position.y >= viewport_rect.position.y,
		"%s：信息卡左/上边缘越出视口（%s）" % [context, rect])
	_check(rect.end.x <= viewport_rect.end.x + 0.5 and rect.end.y <= viewport_rect.end.y + 0.5,
		"%s：信息卡右/下边缘越出视口（%s）" % [context, rect])


func _check_clears_top_hud(context: String) -> void:
	var rect: Rect2 = _panel.get_global_rect()
	_check(rect.position.y >= TOP_HUD_BAND_BOTTOM,
		"%s：信息卡上边缘应避开顶部 HUD（y=%s < %s）" % [context, rect.position.y, TOP_HUD_BAND_BOTTOM])


func _check_anchored_to_bottom_left(context: String) -> void:
	var rect: Rect2 = _panel.get_global_rect()
	_check(absf(rect.position.x - VIEWPORT_MARGIN) <= 0.5,
		"%s：信息卡左边缘应贴左下 Dock 起点（%s != %s）" % [context, rect.position.x, VIEWPORT_MARGIN])
	_check(absf(rect.end.y - (_host.size.y - VIEWPORT_MARGIN)) <= 0.5,
		"%s：信息卡下边缘应贴视口底部（%s != %s）" % [context, rect.end.y, _host.size.y - VIEWPORT_MARGIN])


func _check_content_fits(context: String) -> void:
	var content_rect: Rect2 = (_panel.get_node(CONTENT_PATH) as Control).get_global_rect()
	var panel_rect: Rect2 = _panel.get_global_rect()
	_check(content_rect.end.y <= panel_rect.end.y + 0.5,
		"%s：内容高度溢出面板（内容底部 %s / 面板底部 %s）" % [context, content_rect.end.y, panel_rect.end.y])
	_check(content_rect.end.x <= panel_rect.end.x + 0.5,
		"%s：内容宽度溢出面板（内容右侧 %s / 面板右侧 %s）" % [context, content_rect.end.x, panel_rect.end.x])


func _check(condition: bool, message: String) -> void:
	_check_count += 1
	if not condition:
		_failures.append(message)


func _report() -> void:
	print("CHECKS=", _check_count, " FAILURES=", _failures.size())
	if _failures.is_empty():
		print("PAWN_INFO_PANEL_DISPLAY_TEST_OK")
		quit(0)
	else:
		for failure: String in _failures:
			print("FAILED: ", failure)
		quit(1)