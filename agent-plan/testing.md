# Testing 主题计划

> 最后修改：2026-09-25T21:14:43+08:00
> 主题：testing
> 规则来源：`../AGENTS.md`

## INC-TESTING-001：引入 GdUnit4 并建立三层自动化测试框架

- 状态：accepted
- 创建时间：2026-09-25T15:11:20+08:00
- 最后修改：2026-09-25T15:23:46+08:00
- 主题：testing
- 目标：为 test1 建立可命令行一键运行、按层组织、可接入 CI 的自动化测试框架，使每个代码 Increment 在请求用户验收前都能产出可复现、可回归的测试证据，落实 `AGENTS.md` §12.6 遗留的测试框架选型决策。
- 验收标准：
  - 测试框架选型有唯一结论，并记录 GdUnit4 / GUT / 自建 headless 三者的取舍依据（含实证结果）。
  - 框架可 headless 运行：一条命令跑完全部测试层级，退出码 0 表示全通过、非 0 表示存在失败。
  - 三层测试职责固定且各层至少有一个真实用例：`test/unit`（纯逻辑）、`test/integration`（系统组合）、`test/gameplay`（场景与玩法）。
  - 既有 `test/headless` 六个套件保持可运行，断言总数不低于基线 393 项（55 / 102 / 49 / 86 / 63 / 38）。
  - 产出机器可读报告（JUnit XML）与人类可读摘要，文档不写入本机 Godot 绝对路径。
  - `test/README.md` 记录目录约定、命名规则、运行方式与新增测试步骤。
- 范围：`addons/gdUnit4/**`、`test/**`（含 `test/README.md`、框架脚本与新增用例）。
- 非范围：把既有 `test/headless` 套件改写为 GdUnit4 风格；修改 `game/` 下业务代码；更改已验收的 Pawn/UI/资源契约；真实渲染截图类证据脚本 `test/tools/capture_health_bar_evidence.gd`。
- 依赖：Godot 4.7.2（本机已安装，headless 可用）；既有 `test/headless` 六个套件作为回归基线。
- 检索证据：
  - `git status --short --branch`：`main` 相对 `origin/main` ahead 1；工作区包含 `INC-CROSS-003`（awaiting_acceptance）与 `INC-CROSS-004`（in_progress）的未提交变更。
  - `git diff --unified=0 -- agent-plan/` 与 `git diff --cached --unified=0 -- agent-plan/`：`_index.md`、`_template.md`、`combat.md`、`core.md`、`pawns.md`、`ui.md` 共 6 个计划文件被修改（370 插入 / 11 删除），暂存区为空；据此识别到 INC-CROSS-003、INC-CROSS-004、INC-CORE-002、INC-UI-003、INC-UI-004、INC-PAWNS-004、INC-PAWNS-005、INC-COMBAT-002。
  - `git log --oneline -8`：最新提交为 `3bd28fb docs(process): require git diff based increment search`。
  - `git grep -n -E "INC-[A-Z]+-[0-9]{3}" -- agent-plan/`：testing 主题此前无任何 Increment，`_index.md` 中“测试”行状态为“未创建”，`AGENTS.md` §12.6 记载“当前项目尚未确定测试框架”。
  - 基线复跑（本次实测）：6 个 headless 套件退出码全为 0，合计 393 项断言，`CHECKS=55/102/49/86/63/38 FAILURES=0`。
  - 选型实证：GdUnit4 最新版本 `v6.2.1`（2026-08-20 发布，272 个文件 / 1.1 MB）；其 `project.godot` 声明 Godot 4.6 特性，与本项目 4.7.2 的兼容性待实证。
  - 依赖状态：本 Increment 无前置 Increment；`project.godot` 与 `AGENTS.md` 在工作区均未被修改，本次是这两个文件的唯一写入者。
- 风险：
  - GdUnit4 v6.2.1 面向 Godot 4.6，本项目为 4.7.2，存在不兼容风险。因此必须先做可行性实证，实证失败则回退自建 headless 框架，并把失败证据写入本 Increment。
  - 引入第三方 addon 带来许可证、维护状态与安全审计负担（`AGENTS.md` §12.4），需记录来源、版本、许可证与维护状态。
  - 若在 `project.godot` 中启用编辑器插件，可能影响并行进行中的 MCP 验证（`INC-CROSS-004`）。本 Increment 不启用编辑器插件、不修改 `project.godot`，以避开高冲突共享文件。
  - 与 `INC-CROSS-003` / `INC-CROSS-004` 并行：其 headless 套件必须继续可运行，框架改动不得降低既有断言数量或改变既有测试结论。
- 实现说明：
  - 选型实证（先证后用）：在 Godot 4.7.2 上实测 GdUnit4 `v6.2.1`（2026-08-20 发布，tag `v6.2.1`），headless 下三层用例一次跑通并产出 JUnit XML 与 HTML 报告，退出码语义明确（0 = 通过、100 = 存在失败），据此选定 GdUnit4。GUT 未引入：需额外覆盖一套与既有 headless 等价的能力，且报告为自定义格式；自建 headless 的优势（零依赖、逐条 CHECK、失败可精确定位）已由 `test/headless/` 保留，与 GdUnit4 互补而非替代。
  - 引入方式：以 vendored 方式锁定 `addons/gdUnit4/`（516 个文件 / 1.11 MB），不使用 Git submodule，避免网络依赖与版本漂移；不改动 addon 内部实现，不额外加包装层。
  - 兼容性要点：GdUnit4 的命令行参数必须原生传递，不能放在 `--` 之后；headless 运行必须显式加 `--ignoreHeadlessMode`，否则框架会因检测到 headless 模式而拒绝执行。
  - 三层用例：`test/unit` 共 20 例（`pawn_data_defaults_test.gd` 5、`resource_pool_definition_test.gd` 5、`resource_pool_math_test.gd` 10），只验证纯逻辑，不加载场景；`test/integration` 共 9 例（`health_damage_routing_test.gd`），验证 Pawn 与资源池之间的伤害与信号路由；`test/gameplay` 共 5 例（`main_scene_gameplay_test.gd`），在真实 `main.tscn` 上跑通选中 → 受伤 → HUD 与头顶资源条同步 → 死亡。
  - 统一入口：新增 `test/run_tests.ps1`，一条命令跑完三层 GdUnit4 与全部 `test/headless/*_test.gd`，逐套件打印 PASS/FAIL 并附失败上下文，把 GdUnit4 的 0/100 退出码归一化为 0/1；提供 `-Layer all|unit|integration|gameplay|headless`、`-Godot`、`-ReportDir` 参数。Godot 可执行文件必须由 `-Godot` 或 `GODOT_BIN` 提供，仓库内不记录本机绝对路径。
  - 输出解析：GdUnit4 控制台报告带 ANSI 颜色转义，必须先剥离转义序列再做正则解析，否则 `Overall Summary` 无法匹配。
  - 隔离并行工作：不修改 `project.godot`、不启用 GdUnit4 编辑器插件，测试只经 `GdUnitCmdTool.gd` 在 headless 下运行，避免干扰并行进行的 MCP 运行时验证。
- 变更文件：
  - 新增 `addons/gdUnit4/**`（516 个文件 / 1.11 MB，含 `LICENSE`、`plugin.cfg`）。
  - 新增 `test/unit/pawn_data_defaults_test.gd`、`test/unit/resource_pool_definition_test.gd`、`test/unit/resource_pool_math_test.gd` 及各自 `.uid`。
  - 新增 `test/integration/health_damage_routing_test.gd` 及 `.uid`。
  - 新增 `test/gameplay/main_scene_gameplay_test.gd` 及 `.uid`。
  - 新增 `test/run_tests.ps1`、`test/README.md`。
  - 修改 `.gitignore`：忽略可重建的 `reports/`。
  - 修改 `AGENTS.md`：§6 增加提交前统一测试门禁，§10 更新工程基线，§12.6 记录框架选型结论与用法约束。
  - 修改 `agent-plan/testing.md`、`agent-plan/_index.md`（登记本 Increment 与父级 `INC-CROSS-005`）。
  - 未修改 `project.godot`；未修改 `game/` 下任何业务代码。
- 测试证据：
  - 统一入口全量复跑（2026-09-25T15:21:35+08:00，`pwsh -File test/run_tests.ps1`，Godot 路径经 `GODOT_BIN` 提供）：
    - `[GdUnit4] unit ... PASS (20 cases)`、`[GdUnit4] integration ... PASS (9 cases)`、`[GdUnit4] gameplay ... PASS (5 cases)`，汇总 `GdUnit4  : 34 cases, 0 failures`。
    - 9 个 headless 套件全部 PASS：`health_bar_visibility_test.gd` 46、`health_component_test.gd` 55、`health_pool_authority_test.gd` 33、`hud_spirit_display_test.gd` 8、`pawn_resource_pools_test.gd` 49、`pawn_status_bars_integration_test.gd` 37、`resource_bar_test.gd` 86、`resource_pool_component_test.gd` 102、`spirit_pool_test.gd` 64；汇总 `headless : 9 suites, 480 assertions, 0 failing suites`。
    - 结束输出 `RESULT: PASS`，退出码 0。
  - 门禁有效性验证：临时插入一个必然失败的用例后，runner 输出 `RESULT: FAIL` 且退出码为 1，证明退出码能真实反映失败；探针用例已删除，不残留在变更文件中。
  - 回归强度对比：引入前基线为 6 个 headless 套件 393 项断言；引入后为 9 个套件 480 项断言（期间并行 Increment 也在增长），断言总数未下降。
  - 报告产物：`reports/gdunit/<层>/report_N/` 下生成 `results.xml`（JUnit）与 `index.html`，可重建，已加入 `.gitignore`。
  - 安全审计（§12.4）：全量扫描 `addons/gdUnit4` 的外部调用，命中 `OS.shell_open`（仅编辑器内的帮助、问题反馈与更新链接）、`OS.execute("dotnet", ...)`（仅 C# 路径，本工程为 GDScript，不触发）、`OS.create_process`（重启 Godot 自身）、`HTTPRequest` / `TCPServer` / `StreamPeerTCP`（编辑器更新检查与 TcpNode 进程间 IPC）。headless GDScript 测试路径不存在任意命令执行或代码下载执行；编辑器插件未在 `project.godot` 启用。
- 验证状态：验证通过
- 验证时间：2026-09-25T15:21:53+08:00
- 已知问题：
  - 测试过程中发现 2 处 Pawn 业务行为属于“设计取舍待确认”。按“不在本 Increment 内顺手改 `game/`”的约束只做记录、未修复，需在对应主题下另立 Increment：
    1. `game/pawns/pawn.gd:217` 的 `maxf(1.0, raw_attack - data.defense)` 使伤害存在 1.0 保底：攻击力低于防御时仍会造成 1.0 伤害，防御无法完全吸收弱攻击。
    2. `game/pawns/pawn.gd:247-249` 的 `die()` 会设置 `collision_shape.disabled = true`、`collision_layer = 0`、`collision_mask = 0`，死亡单位不再阻挡攻击；这与 `INC-CROSS-001` 记录的“`collision_layer = 0` 出现两次”不一致，需确认是否为预期语义。
  - 早期记录的另两条疑点经复核已不成立并撤回：`HealthComponent.apply_damage` 实际按“先护盾、后生命”正确路由（`game/pawns/health_component.gd:112-125`）；`is_hide_countdown_running()` 位于 `pawn_health_bar.gd` / `pawn_status_bars.gd`，且被既有 headless 套件断言为预期行为，并非缺陷。
  - `test/headless` 的套件数与断言总数会随并行 Increment 持续变化，本 Increment 以“不低于基线且全部通过”为验收口径。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `b11c9b0`
- 备注：父 Increment 为 `INC-CROSS-005`。本 Increment 只建立测试基础设施与用例骨架，不修改 `game/` 下业务逻辑；如测试过程中发现业务缺陷，另立对应主题 Increment 处理，不在本 Increment 内顺手修复。

## INC-TESTING-002：修正自动隐藏计时的墙钟断言下界

- 状态：accepted
- 创建时间：2026-09-25T16:19:12+08:00
- 最后修改：2026-09-25T16:19:12+08:00
- 主题：testing
- 来源：`INC-PAWNS-010` / `INC-UI-007` / `INC-CORE-004` 批次执行统一门禁时，`test/run_tests.ps1 -Layer all` 退出码 1，失败点是两套与本次功能无关的 headless 套件。
- 目标：修掉“自动隐藏 ≈2 秒”运行态断言中过于贴边的墙钟下界，使统一门禁不再因机器负载出现假失败，同时不降低对 2.0 秒语义的验证强度。
- 验收标准：
  - `test/headless/health_bar_visibility_test.gd` 与 `test/headless/pawn_status_bars_integration_test.gd` 的运行态计时断言不再以 1900ms 作为硬下界，且注释写明放宽理由与替代覆盖。
  - 精确的 2.0 秒语义仍由 `tick()` 驱动的确定性用例覆盖，断言强度不下降：`_test_countdown_reset_on_repeated_change`（`bar.tick()` 逐帧推进）等用例负责“最后一次变化 2.0 秒后隐藏”与“重复变化重置倒计时”的精确判定。
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 退出码 0，且两套件断言数不变（46 / 37）。
- 范围：`test/headless/health_bar_visibility_test.gd`、`test/headless/pawn_status_bars_integration_test.gd`。
- 非范围：`game/` 下任何业务代码；`PawnStatusBars` 的隐藏时长与实现；`test/run_tests.ps1` 的调度与超时策略；`INC-TESTING-001` 已完成的三层框架结构。
- 依赖：`INC-TESTING-001`（统一测试入口，已验收）。
- 检索证据：
  - `git status --short --branch` → `## main...origin/main [ahead 1]`，工作区含 `INC-CROSS-003`…`INC-CROSS-007` 与本批次的未提交实现。
  - `git diff --unified=0 -- agent-plan/` → 确认 `INC-TESTING-001` 已占用；本 Increment 取新号 `INC-TESTING-002`。
  - `Select-String -Path test\headless\health_bar_visibility_test.gd,test\headless\pawn_status_bars_integration_test.gd -Pattern 'main.tscn|load\('` → 两套件只加载 `resource_bar.tscn` 与 Pawn 场景，**均不加载 `main.tscn`**，证明失败与本批次的信息卡接线无关。
  - 失败证据（连续 4 次复跑）：`FAILED: 运行态：隐藏耗时应接近 2 秒，实际 1898 ms / 277 帧`、`1898 ms`、`1871 ms / 273 帧`、`1892 ms / 276 帧`，均落在硬下界 1900ms 之下 2~29ms；把两套件单独运行时（机器负载较低）退出码 0。
  - 负载来源：Godot 编辑器 PID 11224 持续持有本项目，5 秒采样消耗 1.53s CPU（约 30% 单核），持续重扫描 / 重导入新增文件。
- 风险：放宽下界会削弱“不得提前隐藏”的约束（例如实现若把 2.0 秒误改成 1.6 秒将不再被抓到）。因此保留 1500ms 下界并明确写清：精确语义由 `tick()` 用例负责，运行态断言只证明“不是立即隐藏、也不是永不隐藏”。
- 实现说明：
  - 根因：倒计时由 `PawnStatusBars._process(delta) → tick(delta)` 驱动，而计时起点是“伤害触发帧”；触发帧自身的 `delta` 会被立即计入倒计时，因此当该帧因加载 / 建场景变长（负载下可达 100ms 以上）时，墙钟耗时必然短于 2000ms。这是测量口径问题，不是隐藏时长实现问题。
  - 处置：把两处 `elapsed_msec >= 1900 and elapsed_msec <= 3500` 改为 `>= 1500 and <= 3500`，并在断言前写明原因、替代覆盖与保留意图。上界 3500ms 不变，仍能抓住“隐藏过晚 / 不再隐藏”。
  - 刻意不改业务代码：`PawnStatusBars` 的 2.0 秒行为已被 `INC-CROSS-002` 验收，本次只修测试的测量口径。
- 变更文件：
  - 修改 `test/headless/health_bar_visibility_test.gd`（`_test_runtime_visibility_timing` 的墙钟下界与注释）。
  - 修改 `test/headless/pawn_status_bars_integration_test.gd`（`_test_runtime_hide_timing` 的墙钟下界与注释）。
- 测试证据：
  - 修改前：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: FAIL`，退出码 1，`headless : 10 suites, 541 assertions, 1 failing suites`（`health_bar_visibility_test.gd` 或 `pawn_status_bars_integration_test.gd`，取决于调度顺序，均为同一计时断言）。
  - 修改后：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`，退出码 0；`GdUnit4 : 105 cases, 0 failures`（unit 52 / integration 33 / gameplay 20）、`headless : 10 suites, 541 assertions, 0 failing suites`。
  - 断言数不变：`health_bar_visibility_test.gd` 46 项、`pawn_status_bars_integration_test.gd` 37 项，与修改前一致（只改判定口径，不删检查项）。
  - 单套件复核：两台套件单独运行 `CHECKS=46 FAILURES=0` 与 `CHECKS=37 FAILURES=0`；在 1900ms 硬下界下也能通过，说明失败确实由机器负载而非逻辑造成。
- 验证状态：验证通过
- 验证时间：2026-09-25T16:19:12+08:00
- 已知问题：
  - 两处运行态断言仍是墙钟口径，只是容差变大；若上游把隐藏时长改成别的量级，`tick()` 用例仍会失败，但运行态断言可能滞后。
  - Godot 编辑器 PID 11224 的持续负载是本次假失败的触发条件；负载消失后该断言在 1900ms 下也能通过，因此本次放宽是“消除对负载的敏感”，不是“掩盖实现缺陷”。
  - `INC-TESTING-001` 记录的 2 处 Pawn 业务疑点（伤害 1.0 保底、死亡后碰撞归零）仍未处置，不受本 Increment 影响。
- 用户验收：已验收
- 验收时间：2026-09-25T16:50:57+08:00
- Git：`main` / `ab4755d`
- 备注：父 Increment 为 `INC-CROSS-005`。本 Increment 只修测试的测量口径，不修改 `game/` 下任何业务代码。

## INC-TESTING-003：技能栏与左下角布局证据

- 状态：accepted
- 创建时间：2026-09-25T17:01:58+08:00
- 最后修改：2026-09-25T17:17:48+08:00
- 主题：testing
- 目标：扩展真实窗口取证与回归断言，覆盖 SkillBar 状态、2~6 槽位数量、左下 Dock 方向、信息卡/技能栏/顶部 HUD/暂停遮罩的几何关系。
- 验收标准：
  - 取证脚本在 16:9、16:10、窄屏三档窗口下输出 Dock、信息卡、技能栏、顶部 HUD、暂停标签和暂停遮罩的矩形证据。
  - 断言信息卡与技能栏均位于视口内、互不重叠、不与顶部 HUD 或暂停标签重叠；`CONTENT_FITS=true`；暂停遮罩绘制顺序仍在 Dock 之后。
  - 通过构造不同境界容量验证 SkillBar 槽位数 2/3/4/5/6 的自动排列，不建立境界专用 UI。
  - 测试证据包含真实窗口报告路径、截图文件、GdUnit4/headless 汇总和退出码；`.mcp/` 产物不入库。
- 范围：`test/tools/capture_pawn_info_panel_evidence.gd`、必要的 headless/gameplay 测试、`test/README.md`（如运行方式变化）。
- 非范围：修改业务技能逻辑、引入新测试框架、CI 平台接入。
- 依赖：`INC-UI-011`、`INC-CORE-005`。
- 检索证据：已执行 `git status --short --branch`（`main...origin/main`，仅 `docs/战斗技能ui.md` 未跟踪）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（暂存区为空）、`git log --oneline -- agent-plan/`（最新计划提交 `ae16ef9`）与 `git grep -n -E "INC-[A-Z]+-[0-9]{3}" -- agent-plan/`（UI 最高 `INC-UI-009`、战斗最高 `INC-COMBAT-003`、Pawns 最高 `INC-PAWNS-012`、Core 最高 `INC-CORE-004`、Testing 最高 `INC-TESTING-002`）。Graphify 图谱缺失且本机缺少 `networkx`，本轮以 Godot MCP 场景树 + 定向源码读取补足结构基线；主场景当前 `HUD/PawnInfoPanel` 为右下锚定，尚无 SkillBar / SkillSlot。；现有取证脚本只覆盖信息卡三档布局。
- 风险：真实窗口尺寸在不同 DPI 下可能延迟生效，需要保留重试与失败报告；headless 不能替代多分辨率视觉结论。
- 实现说明：沿用现有脚本的 print + 报告文件 + PNG 模式，仅扩大测量对象与断言范围；业务失败另立 Increment。
- 变更文件：`test/tools/capture_pawn_info_panel_evidence.gd`。
- 测试证据：真实窗口取证 `EXIT=0 FAILURES=0`，报告 `res://.mcp/godot-runtime/screenshots/pawn_info_panel_evidence_report.txt`，6 张 PNG；容量 2/3/4/5/6 → SLOTS=2/3/4/5/6、SLOT_SIZE=(64,64)；1152x648、1152x720、800x720 三档 COMBAT/PAUSED 均满足 DOCK_INSIDE/PANEL_INSIDE/BAR_INSIDE、PANEL_BAR_OVERLAP=false、CONTENT_FITS=true、BOTTOM_ALIGNED=true、PANEL_LEFT_OF_BAR=true、DRAWN_ABOVE_DOCK=true；统一门禁 160 cases、0 failures，headless 549 assertions、0 failing。
- 验证状态：验证通过
- 验证时间：2026-09-25T17:17:48+08:00
- 已知问题：无。
- 用户验收：已验收
- 验收时间：2026-09-25T17:17:48+08:00
- Git：`main` / `cecc91d`
- 备注：父 Increment 为 `INC-CROSS-011`。

## INC-TESTING-004：三种技能战术差异与 Build 变化证据

- 状态：accepted
- 创建时间：2026-09-25T17:31:30+08:00
- 最后修改：2026-09-25T17:57:16+08:00
- 主题：testing
- 来源：`docs/build-mvp.md` MVP-5 的“不同 Build 产生不同战斗过程”验收问题。
- 目标：用可重复的测试场景证明御剑斩、护体真气、定身术不是同一伤害技能换皮，并证明两槽 Build 至少产生三种可区分的战斗过程指标，而不是只验证“三个技能都能成功施放”。
- 验收标准：
  - 构造同一敌人、同一初始位置和同一操作脚本，分别运行输出+生存、输出+控制、生存+控制三种 2 槽 Build。
  - 记录并断言至少三类过程指标：有效生命/护盾曲线、敌人失效时间、玩家施法/普攻次数或资源消耗；三种 Build 不得只有名称不同而轨迹完全一致。
  - 至少有一个对抗场景中“输出+生存”与“输出+控制”产生可区分的最优策略；测试不得以最终胜负作为唯一断言，因为 Build 的价值在于过程差异。
  - 证据包含自动化命令、用例名、断言摘要、失败时的轨迹输出；不要求本 Increment 制作正式平衡数值。
- 范围：新增/扩展 GdUnit4 gameplay/integration 测试、必要的测试专用 Build 构造函数与轨迹记录器。
- 非范围：正式数值平衡、玩家 Build 编辑器、存档、网络同步、AI 难度调参。
- 依赖：`INC-PAWNS-014`、`INC-COMBAT-005`、`INC-COMBAT-006`、`INC-CORE-006`。
- 检索证据：`git diff --unified=0 -- agent-plan/` 确认 `INC-PAWNS-014` / `INC-COMBAT-005` / `INC-COMBAT-006` / `INC-UI-012` 已落库；`INC-CORE-006` 实现后数字键/Q/技能格已统一进入目标路由。现有测试只覆盖单技能效果与命令接线，没有跨 Build 的固定时间步过程轨迹测试。
- 风险：确定性测试必须避免墙钟和渲染帧依赖；目标寻路/移动造成的微小浮点差异需要容差或离散事件记录；测试不能替业务层伪造效果。
- 实现说明：新增 `build_tactical_trajectory_test.gd`，加载正式御剑斩 / 护体真气 / 定身术资源，按固定 `DELTA = 1/60`、720 步、同一“槽位 0 完成后执行槽位 1”脚本运行三套 2 槽 Build；使用真实 Pawn、资源池、PlayerController/AIController、技能信号与伤害/眩晕结算，逐步记录有效生命、护盾、敌人失效时间、灵力消耗、施法/普攻次数和敌人有效生命。测试专用敌人只拉长生命到 600、去掉护盾以避免最终死亡截断过程，不改业务平衡数据。
- 变更文件：`test/gameplay/build_tactical_trajectory_test.gd`、`test/gameplay/build_tactical_trajectory_test.gd.uid`。
- 测试证据：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 于 2026-09-25T17:55:34+08:00 返回 192 cases / 0 failures（unit 87 / integration 67 / gameplay 38）与 headless 10 suites / 549 assertions / 0 failing；专项 `build_tactical_trajectory_test.gd` 返回 1 case / 0 failures，轨迹摘要为：输出+生存 `shield_max=30, stun=0.0s, spirit=55, damage=422.4, min_effective=73`；输出+控制 `shield_max=0, stun=2.0s, spirit=60, damage=422.4, min_effective=57`；生存+控制 `shield_max=30, stun=2.0s, spirit=65, damage=375.0, min_effective=87`。测试同时断言 12 个固定采样点上的有效生命曲线确实不同，且输出+生存在生存下限上优于输出+控制、输出+控制在敌人失效时间上优于前者。
- 验证状态：验证通过（2026-09-25T17:55:34+08:00）
- 验证时间：2026-09-25T17:55:34+08:00
- 已知问题：本用例是固定场景的确定性过程证据，不是正式平衡结论；数值仍可能随后续战斗调参改变。
- 用户验收：已验收（2026-09-25T17:31:30+08:00，用户授权“验收通过，分increment提交”）
- 验收时间：2026-09-25T17:31:30+08:00
- Git：`main` / `a895e2b`
- 备注：父 Increment 为 `INC-CROSS-012`；本 Increment 是父级 Gameplay 验收的核心证据层。

## INC-TESTING-005：Build 容量一致的自动化证据

- 状态：accepted
- 创建时间：2026-09-25T18:00:42+08:00
- 最后修改：2026-09-25T18:10:00+08:00
- 主题：testing
- 目标：为“所有技能可见、超容量禁用、任何入口都不能施放”的选择提供跨 unit / integration / gameplay 的可重复证据，而不是只验证 BuildValidator 的错误码。
- 验收标准：
  - 单元测试覆盖 Pawn 容量投影：容量 0 / 1 / 2 / 4、超容量索引、无境界兼容、完整 loadout 仍报告 `over_capacity`。
  - 集成测试覆盖 SkillSlotState/SkillBar 的 DISABLED 状态、点击无请求、`request_skill()` 拒绝、PlayerController/AI 不消费超容量技能。
  - gameplay 测试构造同一玩家 4 个技能但炼气容量 2：前 2 个可用，后 2 个 DISABLED；点击/快捷键/直接 cast 均无灵力、冷却、HP/Shield、位置或 controller 命令副作用。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP validate 与 `git diff --check` 全部通过。
- 范围：`test/unit`、`test/integration`、`test/gameplay` 中新增或扩展的容量一致性测试。
- 非范围：正式 Build 编辑器、存档迁移、平衡调参、网络同步。
- 依赖：`INC-PAWNS-015`、`INC-COMBAT-007`、`INC-UI-013`、`INC-CORE-007`。
- 检索证据：已执行 `git status --short`（工作区干净，`main...origin/main`）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）与 `git log --oneline -5 -- agent-plan/`（当前计划基线 `cbccdb8`）；全量检索确认现有最高主题编号为 PAWNS-014 / COMBAT-006 / UI-012 / CORE-006 / TESTING-004，CROSS-012 已验收，无未完成 planned Increment。 `git grep` 实测：`BuildValidator` 已能报告 `over_capacity`，但 `Pawn.can_cast_skill()` 不检查容量，`PlayerController.order_skill_instance()` 只检查 known skill，`AIController` 直接遍历 `data.get_active_skills()`，`SkillBar.refresh()` 用 `max(capacity, skills.size())` 显示全部技能却未把多余技能置为 DISABLED。因此“校验能发现错误”与“运行时实际禁止错误 Build”之间仍有缺口。
- 风险：必须保持既有正常 Build（炼气 2/2）行为不变；不得让无境界的怪物/傀儡因缺少 Build 容量而失去天生技能；不得只修 UI 而留下控制器或 AI 旁路；不得静默截断技能列表。
- 实现说明：测试使用隔离的 `PawnData` / `RealmDefinition` 副本构造超容量场景，不改动正式玩家预设；断言容量内行为不回归。
- 变更文件：`test/unit/pawn_active_skill_capacity_test.gd`、`test/unit/skill_slot_state_test.gd`、`test/integration/active_skill_execution_test.gd`、`test/integration/skill_bar_test.gd`、`test/integration/skill_targeting_ui_test.gd`、`test/gameplay/main_scene_gameplay_test.gd`。
- 测试证据：统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 返回 PASS：GdUnit4 207 cases / 0 failures（unit 94 / integration 73 / gameplay 40），headless 10 suites / 549 assertions / 0 failing suites。三层专项覆盖容量投影、UI DISABLED/请求拦截、控制器/AI 旁路拒绝、主场景快捷键/HUD 与 4 技能 / 2 容量玩法场景。Godot MCP `validate` 对 13 个本次变更脚本/测试目标返回 `valid: true`、`errors: []`；`git diff --check` 无输出。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:10:00+08:00
- 已知问题：无新增阻塞。未覆盖正式 Build 编辑器、存档迁移、数值平衡与 AOE；均属于非范围。
- 用户验收：已验收
- 验收时间：2026-09-25T18:10:00+08:00
- Git：`main` / `f79b627`（文档证据提交）
- 备注：父 Increment 为 `INC-CROSS-013`；本 Increment 是父级验收的核心证据层。

## INC-TESTING-006：Build 决策差异证据（威胁档案 × 三套 Build 的终局对照）

- 状态：accepted
- 创建时间：2026-09-25T18:20:31+08:00
- 最后修改：2026-09-25T18:30:17+08:00
- 主题：testing
- 来源：`docs/build-mvp.md` MVP-5「不同 Build 是否产生不同战斗过程」，以及用户 2026-09-25 建议优先级 5。
- 目标：用可重复的固定时间步玩法证据回答「输出/生存/控制三类技能是否真的产生决策」——在三套两槽 Build 与两类敌人威胁档案的组合上跑到**终局**，记录胜负、击杀耗时、剩余有效生命、灵力消耗、护盾峰值、敌人失效时长与双方普通攻击次数，并证明最优 Build 随遭遇改变（不存在单一统治解）。
- 验收标准：
  - 新增 gameplay 证据用例，固定 60fps 时间步驱动真实 `Pawn` / `PlayerController` / `AIController` / `SkillEffectResolver`；测试内不得复制或自造伤害、护盾、眩晕公式。
  - 组合覆盖：≥2 个敌人威胁档案 × 3 套两槽 Build（输出+生存 / 输出+控制 / 生存+控制）+ 1 个「无主动技能」对照；每个组合跑到一方死亡或明确的上限步数，并把指标表 `print` 出来。
  - 断言 1「技能不是装饰」：三套 Build 相对无技能对照在终局指标上占优（击杀更快或剩余有效生命更高）。
  - 断言 2「无单一统治解」：存在档案 A 使某套 Build 严格最优，存在档案 B 使另一套 Build 严格最优；这是 MVP-5 的核心结论。
  - 断言 3「三类技能签名可区分」：至少一个档案中护盾峰值显著大于 0 而敌人失效时长接近 0；另一个档案中敌人失效时长显著大于 0 而护盾峰值为 0。
  - 断言 4「决策代价可观测」：在主导档案中，最优 Build 与最差 Build 的剩余有效生命差值大于下限阈值，错误选择会被惩罚。
  - 断言只表达**关系与下限**（谁优于谁、差值大于多少），不得硬编码伤害数字或把平衡公式写进测试；阈值集中定义为常量并注明含义。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP `validate` 与 `git diff --check` 全部通过。
- 范围：`test/gameplay/`（新增用例）、`test/README.md`（如需说明新增证据用例）。
- 非范围：遭遇选择 UI、Build 编辑器、AOE、Buff/Debuff 叠加、正式平衡表、网络同步、存档迁移、UI 美化。
- 依赖：`INC-PAWNS-016`（威胁档案）、`INC-COMBAT-008`（价值标定）、`INC-TESTING-004`（既有固定轨迹证据，均已验收或同批完成）。
- 检索证据：已执行 `git status --short --branch`（`main...origin/main`，工作区干净）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）与 `git log --oneline -6 -- agent-plan/`（`c442822`）；`git grep` 确认最高编号 TESTING-005 已验收。既有 `test/gameplay/build_tactical_trajectory_test.gd` 的操作策略是固定脚本「先槽位 0 后槽位 1」，且只观察固定 12 秒窗口内的过程指标，不产生任何终局结论，因此它**不能**回答「最优选择是否随遭遇改变」；本 Increment 与之互补，不替代它。
- 风险：该用例直接依赖数值平衡，后续任何调参都可能让阈值失效；因此必须只用关系型断言与集中常量，并在 `已知问题` 中写明「阈值随 `INC-COMBAT-008` 标定更新」。另一风险是把差异写成测试自造场景而脱离真实数据——必须只加载 `game/pawns/data/` 下的正式资源。
- 实现说明：新增 `test/gameplay/build_decision_differentiation_test.gd`，固定 60fps 时间步驱动真实场景/控制器/结算器，把「3 份敌人档案 × 3 套两槽 Build」加上每份档案一个「无主动技能」对照，全部跑到一方死亡（上限 60s，超时如实记为 timeout）。决策策略是唯一一套确定性策略（低血先补盾 → 优先压制敌人行动 → 否则输出），对全部 Build 一视同仁，因此差异只能来自 Build 组合与敌人档案。为了让「生存」技能可观测，护盾收益不用峰值而用**技能实际授予量**（监听 `shield_changed` 只累计正向增量，起始 40 点预设护盾不计入），因为玩家初始满盾会让峰值恒为 40 而掩盖差异。优劣判定规则写在 `_is_better()`：先看是否获胜，再看剩余有效生命比，最后看耗时。终局优劣先由 `_is_better()`（先胜负、再余命、后耗时）给出「本次最优解」，但该字典序隐含「余命优先于耗时」的口径假设；为避免结论被口径绑架，本用例另加断言 5 与一组支配关系辅助方法（`_dominates()` / `_is_strictly_dominated()` / `_non_dominated_ids()`）：只有当某 Build 在「余命」与「耗时」两轴上都不劣、且至少一轴严格更优时，才算被严格支配。这样「哪些选择是明确错误」不依赖加权或字典序，取舍项与错误项被分开表达。
- 变更文件：`test/gameplay/build_decision_differentiation_test.gd`（新增）。
- 测试证据：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer gameplay` 通过（41 cases / 0 failures）；统一门禁 `-Layer all` 返回 GdUnit4 210 cases / 0 failures（unit 96 / integration 73 / gameplay 41）与 headless 10 suites / 549 assertions / 0 failing suites。终局指标表（胜/负、击杀耗时、剩余有效生命比、灵力消耗、授予护盾、敌人失效时长）：

| 档案 | Build | 结果 | 耗时 | 余命比 | 灵力 | 授予护盾 | 敌人失效 |
|---|---|---|---|---|---|---|---|
| 试炼傀儡 180+20 / 攻12 / 1.1s | 输出+生存 | 胜 | 3.68s | 0.869 | 50 | 0 | 0.0s |
| 试炼傀儡 | 输出+控制 | 胜 | 3.82s | 0.913 | 85 | 0 | 2.0s |
| 试炼傀儡 | 生存+控制 | 胜 | 6.20s | 0.825 | 35 | 0 | 2.0s |
| 试炼傀儡 | 无技能对照 | 胜 | 6.07s | 0.781 | 0 | 0 | 0.0s |
| 铁壁傀儡 520+80 / 攻16 / 1.6s | 输出+生存 | 胜 | 15.72s | 0.3125 | 100 | 0 | 0.0s |
| 铁壁傀儡 | 输出+控制 | 胜 | 19.03s | 0.24375 | 85 | 0 | 2.0s |
| 铁壁傀儡 | 生存+控制 | 胜 | 22.22s | 0.3625 | 100 | 30 | 4.0s |
| 铁壁傀儡 | 无技能对照 | 胜 | 22.12s | 0.0375 | 0 | 0 | 0.0s |
| 血刃刺客 140 / 攻60 / 1.5s | 输出+生存 | 胜 | 2.78s | 0.500 | 80 | 30 | 0.0s |
| 血刃刺客 | 输出+控制 | 胜 | 2.83s | 0.65625 | 85 | 0 | 2.0s |
| 血刃刺客 | 生存+控制 | 胜 | 4.55s | 0.500 | 65 | 30 | 2.0s |
| 血刃刺客 | 无技能对照 | 败 | 3.50s | 0.000 | 0 | 0 | 0.0s |

  非支配集合（断言 5 的实测输出，`non_dominated`）：试炼傀儡 `["output+survival", "output+control"]`；铁壁傀儡 `["output+survival", "survival+control"]`；血刃刺客 `["output+survival", "output+control"]`。严格支配关系：铁壁傀儡下「输出+控制」（余命 0.244、19.03s）被「生存+控制」（余命 0.363）严格支配；血刃刺客下「生存+控制」（余命 0.500、4.55s）被「输出+控制」（余命 0.656）严格支配——同一个「输出+控制」在长线遭遇里是明确错误选择，在爆发遭遇里是最优解。

  五条断言实测结论：(1) 技能不是装饰——血刃刺客档案下无主动技能对照直接战败（余命 0），铁壁傀儡档案下无技能只剩 3.75% 余命，而三套 Build 全胜；(2) 无单一统治解——长线档案最优为「生存+控制」，爆发档案最优为「输出+控制」，最优 Build 随遭遇改变；(3) 三类技能签名可区分——爆发档案下「输出+生存」授予护盾 30 且敌人失效 0.0s，「输出+控制」授予护盾 0 且敌人失效 2.0s；(4) 决策代价可观测——三个档案的余命比差距分别为 8.75 / 11.88 / 15.63 个百分点，均超过 5 个百分点的下限；(5) 取舍不依赖评价口径——每个档案都存在 ≥2 个互不支配的 Build，且被严格支配的「错误选择」随遭遇改变。

  可重复性：同一条直跑命令连续两次执行的 12 组指标完全一致（含步数与余命比），本表为 2026-09-25 复跑记录。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:28:15+08:00
- 已知问题：① 余命与耗时之间存在真实取舍：铁壁傀儡档案下「输出+生存」击杀最快（15.72s，比「生存+控制」快 6.50s）但余命更低（0.3125 对 0.3625），二者互不支配，因此结论读作「存在取舍」而不是「绝对唯一最优」；断言 5 用支配关系而非加权排名，正是为了把「明确错误的选择」（铁壁档案的「输出+控制」、爆发档案的「生存+控制」）与「取舍项」分开表达，使结论不依赖口径选择。② 本用例只跑唯一一套确定性策略；实测另一套「输出优先」策略在全部 12 个组合上结果完全相同，说明施放顺序在当前数值下不改变结论，更复杂的策略差异留待后续 Increment。③ 耗时字段由模拟步数换算（`end_step × 1/60`），与固定轨迹证据一样对策略/数值改动敏感；本表数值已由连续两次完全一致的重跑确认，不应与更早一次（用例定稿前）的耗时记录直接比较。④ 阈值（决策差距 5 个百分点、技能收益 5 个百分点）与 `INC-COMBAT-008` 的标定绑定，后续调参必须同步复核。
- 用户验收：已验收
- 验收时间：2026-09-25T18:28:15+08:00
- Git：`main` / `bd1c577`
- 备注：父 Increment 为 `INC-CROSS-014`；本 Increment 是父级的核心证据层。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」（承接「验收通过，分increment提交」），按 AGENTS.md §4.1 记录为明确验收。

## INC-TESTING-007：遭遇闭环自动化证据（选择 → 换敌 → 终局 → 结果）

- 状态：accepted
- 创建时间：2026-09-25T18:33:02+08:00
- 最后修改：2026-09-25T18:52:41+08:00
- 主题：testing
- 目标：用自动化证据证明「玩家可在实机场景里选择不同秘境遭遇，并得到不同敌人与可读结果」，而不是只在测试内直接构造敌人；同时防止换遭遇流程回归成悬空引用或重复结算。
- 验收标准：
  - gameplay 用例在**真实 `main.tscn`** 上运行：通过遭遇面板信号选择 ≥2 份不同遭遇，断言 `Pawns` 下的敌人 `PawnData.id` 与被选遭遇定义的 `enemy_profile.id` 一致，且旧敌人已从场景树移除。
  - 断言结算路径：把对局推进到一方死亡（固定时间步），断言面板状态文本出现「胜利」或「失败」且与 `EncounterSession.get_state()` 一致；结算后重复触发死亡不会再次改变结果（幂等）。
  - 断言引用完整性：换遭遇后主场景的玩家单位是新的存活单位，选中态、技能栏、信息卡绑定的都是新单位（`is_instance_valid` 且路径属于 `Pawns` 容器）。
  - 断言「结果不依赖测试自造数值」：敌人档案必须来自 `game/world/data/encounters/` 的正式遭遇资源。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP `validate` 与 `git diff --check` 全部通过。
- 范围：`test/gameplay/main_scene_encounter_test.gd`（新增；若与 `INC-CORE-008` 的用例重名则以本 Increment 的跨遭遇/结算断言为准并合并为一个文件）。
- 非范围：房间推进与 Boss 流程、奖励结算、存档、网络同步、UI 美化、性能压测。
- 依赖：`INC-WORLD-001`、`INC-WORLD-002`、`INC-UI-014`、`INC-CORE-008`。
- 检索证据：同 `INC-WORLD-001` 的检索结论；既有 gameplay 层已建立两种证据模式——`INC-TESTING-004` 的固定窗口过程轨迹与 `INC-TESTING-006` 的终局对照，本 Increment 沿用「固定时间步 + 真实场景 + 断言关系」的写法，不复制战斗公式。
- 风险：真实主场景用例会触发全局暂停、HUD 与 CanvasLayer，若不做清理可能污染同批其他用例；必须在用例结束前恢复暂停状态、解绑选中 Pawn。另一风险是把断言写成依赖具体数值（例如铁壁傀儡必须赢），必须以「结果与状态一致」为断言，而不是固定胜负。
- 实现说明：证据全部建立在真实 `main.tscn` 上（加载主场景并 `add_child`），不手工拼装敌人或复制战斗公式：换遭遇通过面板按钮的真实 `pressed` 信号驱动，随后断言 `Pawns` 下敌人 `PawnData.id` 等于被选遭遇 `enemy_profile.id`，并断言旧敌人已离开容器且 `is_queued_for_deletion()` 为真；结算断言走「把对局推进到一方死亡（固定时间步）」，而不是硬编码胜负，断言面板状态文本与 `EncounterSession.get_state()` 一致；幂等性通过重复触发死亡信号验证不会产生第二次结果广播。用例结束前恢复暂停状态并解绑选中 Pawn，避免污染同批其他用例（真实主场景用例会触发全局暂停、HUD 与 CanvasLayer）。
- 变更文件：`test/gameplay/main_scene_encounter_test.gd`（新增）、`test/gameplay/main_scene_encounter_test.gd.uid`（新增）。
- 测试证据：
  - 新增 gameplay 用例 `test/gameplay/main_scene_encounter_test.gd`：5 个用例 —— `test_main_scene_boots_into_default_encounter`、`test_every_panel_button_maps_to_a_formal_encounter_resource`、`test_pressing_button_swaps_enemy_and_keeps_all_references_on_new_units`、`test_settlement_matches_panel_status_and_repeats_once`、`test_player_can_switch_encounter_after_defeat`。
  - gameplay 层单跑：46 cases / 0 failures / 0 orphans，退出码 0。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`：GdUnit4 241 cases（unit 102 / integration 93 / gameplay 46）、0 failures；headless 10 suites / 549 assertions / 0 failing suites；退出码 0。
  - `git diff --check` 无输出。
- 验证状态：验证通过
- 验证时间：2026-09-25T18:52:41+08:00
- 已知问题：断言写在「关系一致性」上（结果与状态一致、敌人 `id` 与遭遇定义一致），刻意不锁定具体胜负与耗时数值，因此敌人数值再平衡不会让本用例假失败，但也不会拦住数值回归（数值回归由 `INC-TESTING-006` 的终局对照负责）。真实窗口截图 / 多分辨率证据未在本 Increment 产出。
- 用户验收：已验收
- 验收时间：2026-09-25T18:52:41+08:00
- Git：`main` / `e2a0594`（+ `INC-CROSS-015` 计划回写提交）
- 备注：父 Increment 为 `INC-CROSS-015`；本 Increment 是父级验收的证据层。验收依据：用户 2026-09-25 指令「推送，保持本地远端一致」，按 `AGENTS.md` §4.1 与本仓库 `INC-CROSS-011`~ `INC-CROSS-014` 的既有约定记录为明确验收。

## INC-TESTING-008：秘境「贪不贪」闭环证据（深度 / 收益 / 撤退 / 阵亡）

- 状态：accepted
- 创建时间：2026-09-25T18:53:57+08:00
- 最后修改：2026-09-25T19:15:13+08:00
- 主题：testing
- 目标：用自动化证据回答「继续深入是否真的成为一个有风险的选择」：同一次秘境里，深入与撤退必须产生不同的终局状态与不同收益，且战败必须让本局收益归零——而不是只有几行文案不同。
- 验收标准：
  - gameplay 用例在**真实 `main.tscn`** 上运行：断言开机进入秘境第 1 间；清空第 1 间后进入等待决策，收益等于第 1 间定义的 `reward_spirit_stones`。
  - 「见好就收」路径：触发撤退后 `DungeonRun` 进入 `RETREATED`，收益保留，且不再产生新的对局。
  - 「继续深入」路径：触发继续后深度 +1、敌人换成第 2 间定义的档案，并且玩家单位携带的是上一间剩余的生命 / 灵力（断言小于满值），证明风险真的累积而非每间满血重置。
  - 「阵亡」路径：让玩家在某一间死亡后 `DungeonRun` 进入 `DEFEATED`、收益归零，且面板状态与 `DungeonRun` 状态一致。
  - 收益一律从 `game/world/data/dungeons/` 的正式秘境资源读取，用例不硬编码奖励数值；断言关系（深度递增、收益累加、战败归零）而不是固定胜负。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`、Godot MCP `validate` 与 `git diff --check` 全部通过。
- 范围：`test/gameplay/main_scene_dungeon_test.gd`（新增；若与 `INC-CORE-009` 的用例重名则合并为一个文件，语义以本 Increment 的跨房间 / 收益断言为准）。
- 非范围：完整通关全部房间的耗时压测、Boss 数值平衡验证、多分辨率截图、随机事件与奖励表。
- 依赖：`INC-PAWNS-017`、`INC-WORLD-003`、`INC-WORLD-004`、`INC-UI-015`、`INC-CORE-009`。
- 检索证据：同一轮检索（工作区干净、无 pending Increment）；`INC-TESTING-007` 已确立「真实主场景 + 面板按钮驱动 + 固定时间步 + 关系断言」的写法，本 Increment 沿用同一模式，把断言从「一次遭遇」扩展到「一次秘境」。
- 风险：秘境用例会连续创建多个单位（每间房重建玩家与敌人），若换房间后不补帧会留下孤儿节点导致退出码非零；必须沿用 `INC-TESTING-007` 的 `await_idle_frame()` 与暂停恢复护栏。另一风险是把断言写成「必须通关」，因此本 Increment 只断言状态机与收益关系。
- 实现说明：新增 `test/gameplay/main_scene_dungeon_test.gd`，在真实 `main.tscn` 上以「程序化按下主场景面板按钮 = 玩家点击」驱动，终局只走真实死亡路径；房间数 / 敌人档案 / 灵石收益全部从 `game/world/data/dungeons/trial_dungeon.tres` 读取，用例只断言关系。6 个用例分别锁定：开机进入第 1 间且单场入口与「重新挑战」被锁；清空第 1 间进入等待抉择且收益等于该间定义奖励；「见好就收」保留收益、不创建新对局且结算后推进无效；「重新开始秘境」回到第 1 间满状态且收益清零；「继续深入」后深度 +1、敌人换成第 2 间档案、玩家单位被重建但生命 / 灵力带着上一间损耗（小于满值）；战败 `DEFEATED` 收益归零并与面板文案一致。
- 变更文件：`test/gameplay/main_scene_dungeon_test.gd`（新增）。
- 测试证据：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer gameplay` → PASS（52 cases / 0 failures）；`-Layer all` → PASS（GdUnit4 272 cases / 0 failures；headless 10 suites / 549 assertions / 0 failing；退出码 0）。Godot MCP `validate`（`test/gameplay/main_scene_dungeon_test.gd`）= `valid: true`。
- 验证状态：验证通过
- 验证时间：2026-09-25T19:15:13+08:00
- 已知问题：用例用 `ResourcePoolComponent.decrease()` 制造「上一间的剩余生命 / 灵力」这一前置状态，因此它锁定的是「损耗必须延续」的机制，而不是某一次随机战斗的具体数值；完整通关耗时、Boss 数值平衡与多分辨率验证属于非范围。
- 用户验收：已验收（依据用户 2026-09-25 指令「分批incre单独推送后继续开发」：本批按 Increment 单独提交并推送）
- 验收时间：2026-09-25T19:15:13+08:00
- Git：`main` / `8880733`
- 备注：父 Increment 为 `INC-CROSS-016`；本 Increment 是父级验收的证据层。

## INC-TESTING-009：宗门闭环证据（收益 → 修炼 / 制作 / 强化 → 再战）

- 状态：accepted
- 创建时间：2026-09-25T19:22:00+08:00
- 最后修改：2026-09-25T20:04:47+08:00
- 主题：testing
- 目标：为「秘境收益 → 宗门产出 → 修士变强 → 再战」这条 MVP-⑤ 闭环提供可复核证据，回答 `docs/project_summary.md` §二十二 提出的问题：「玩家打完之后，会不会因为宗门/新 Build 而想再打一轮？」
- 验收标准：
  - 新增 `test/gameplay/sect_loop_test.gd`，在真实 `main.tscn` 上跑完整链路：进入秘境 → 清空至少一间房 → 结算收益入账宗门 → 用灵石升级设施 → 打坐产修为 → 灵田收草 → 炼丹 / 服丹恢复 → 强化武器后 `get_attack_power()` 提升 → 重新开始秘境时强化与修为仍然生效（宗门状态不随对局重置）。
  - 断言「宗门变强确实改变下一轮战斗数值」：强化后的 `get_attack_power()` 高于强化前，且同一玩家单位的真实 `try_attack()` 造成更高伤害；不使用伪造伤害或直接改数值。
  - 断言收尾一致性：一条 `run_finished` 只入账一次；战败局入账 0；入账后宗门库存与 `DungeonPanel` 显示不矛盾。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all` 退出码 0，且断言总数不低于 `INC-CROSS-016` 基线（GdUnit4 272 cases、headless 10 suites / 549 assertions），headless 套件数不减少。
  - 取证报告落 `.mcp/godot-runtime/screenshots/`（复用 `INC-UI-016` 的宗门面板真实窗口取证），报告里给出三档分辨率的通过结论。
- 范围：`test/gameplay/sect_loop_test.gd`（新增）、`agent-plan/testing.md`（本 Increment 记录）、必要时补 `test/headless/` 回归套件（只在既有断言不下降的前提下追加）。
- 非范围：修改 `game/` 下任何业务规则来迁就测试、调整既有断言期望值、移除既有 headless 套件、把 CROSS-016 的秘境断言改写为宗门断言。
- 依赖：`INC-CORE-010`、`INC-SECT-001`~`INC-SECT-003`、`INC-PAWNS-018`、`INC-UI-016`；闭环首轮失败暴露的会话层缺口由 `INC-WORLD-005` 修复。
- 检索证据（2026-09-25T19:55:22+08:00）：`git status --short` 工作区干净；`git diff --unified=0 -- agent-plan/` 与 `git diff --cached --unified=0 -- agent-plan/` 均无输出；`git log --oneline -- agent-plan/` 显示 `INC-CORE-010` 已以 `224b7f6` / `7706de2` 提交；`git grep -n -E "INC-TESTING-009|sect_loop" -- agent-plan/ test/` 只命中本计划与索引，`sect_loop_test.gd` 尚不存在。依赖 `INC-CORE-010`、`INC-SECT-001`~`003`、`INC-PAWNS-018`、`INC-UI-016` 均已验收。
- 风险：闭环用例横跨秘境 / 宗门 / Pawn / UI 四层，容易出现「测试写死了实现细节」；因此断言只落在对外契约（库存、等级、修为、攻击力、信号次数、`get_snapshot()`），不断言私有字段或节点内部结构。另一风险是把测试写太长导致定位困难，因此按链路节点拆成两个 `test_` 方法，共享同一份夹具。
- 实现说明：
  - 新增 `test/gameplay/sect_loop_test.gd`，只通过真实 `main.tscn`、真实面板按钮与真实死亡 / 结算路径驱动，数值一律从 `DungeonDefinition` / `SectState` / `Pawn` 公开 API 读取，不复制宗门公式。
  - 用例一 `test_complete_sect_loop_makes_the_restarted_run_stronger`：清 4 间 → 撤退入账 → 灵田升级 → 打坐 → 收草 → 炼丹 → 服丹 → 重开（断言修为 / 库存 / 设施延续）→ 在同一单位上比较强化前 / 后的真实 `try_attack()` 伤害差 = `FORGE_ATTACK_BONUS_PER_LEVEL` → 再清 1 间 → 撤退 → 再重开，断言强化等级、修为与攻击力仍高于未强化基线。
  - 用例二 `test_run_finished_is_deposited_once_and_defeat_deposits_zero`：撤退入账一次后重复广播 `run_finished` 不再重复入账；另起一局让玩家阵亡，断言收益与宗门库存均为 0、面板文案与库存一致。
  - 用例一同时在重开前后校验 `EncounterSession` 确实换了单位实例（`instance_id` 不同），把「成长延续」与「单位重建」两件事分开断言。
- 变更文件：
  - `test/gameplay/sect_loop_test.gd`（新增，含 `.uid`）
- 测试证据：
  - `& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/gameplay/sect_loop_test.gd -rd res://reports/debug_sect_loop --ignoreHeadlessMode`：退出码 0，`Overall Summary: 2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`，两个用例均 PASSED。
  - `pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer all`：退出码 0，`GdUnit4 : 324 cases, 0 failures`（unit 125 / integration 139 / gameplay 60）、`headless : 10 suites, 549 assertions, 0 failing suites`、`RESULT: PASS`，相对基线只增不减。
  - `& $env:GODOT_BIN --path . --script res://test/tools/capture_sect_panel_evidence.gd`：`SECT_PANEL_CAPTURE_DONE FAILURES=0`，三档分辨率 1152×648 / 1152×720 / 800×720 的 `PANEL_INSIDE=true`、`DOCK_INSIDE=true`、`TEXT_OVERFLOW=[]` 与截图写入 `.mcp/godot-runtime/screenshots/`（已忽略，不入库）。
- 验证状态：验证通过
- 验证时间：2026-09-25T20:04:47+08:00
- 已知问题：`INC-UI-016` 遗留的 `test/integration/sect_panel_test.gd` 在 GdUnit4 目录模式下报 288 orphans（该文件自身 0 failures / 0 errors），使该层进程退出码为 101；`run_tests.ps1` 汇总仍为 `RESULT: PASS`。该孤儿与本 Increment 无关，属既有测试整洁度债务。
- 用户验收：已验收
- 验收时间：2026-09-25T20:04:47+08:00
- 验收依据：用户指令「分批increment单独推送后继续开发」（2026-09-25），授权本批次按 Increment 分批提交并逐一推送。
- Git：`main` / `06200f2`
- 备注：父 Increment 为 `INC-CROSS-017`；本 Increment 是父级验收的证据层，真实主场景闭环用例也是 `INC-WORLD-005` 缺口的第一发现者。

## INC-TESTING-010：突破 → Build 重构 → 再战证据

- 状态：planned
- 创建时间：2026-09-25T20:11:34+08:00
- 最后修改：2026-09-25T20:11:34+08:00
- 主题：测试
- 目标：用真实主场景证明「修为达到阈值 → 玩家点击突破 → 境界与 Build 容量变化 → 跨房间 / 重开仍保持 → 新容量改变可用技能」这条核心循环成立。
- 验收标准：
  - gameplay 用例加载真实 `main.tscn`，通过真实信息卡按钮触发突破，不直接调用 `try_breakthrough()` 伪造入口。
  - 突破前容量为炼气期基线；突破后信息卡和 HUD 显示筑基期，功法 / 主动 / 被动容量按资源定义增加，下一境界与修为进度正确重置。
  - 连续切换房间 / 重开秘境后，新 Pawn 仍保持运行时境界与新容量，攻击和技能可用性不因换单位回退。
  - 用例记录命令、退出码、关键输出与失败前后差异，覆盖未就绪突破、终局境界和恢复不可达境界的负向路径。
- 范围：`test/gameplay/main_scene_breakthrough_test.gd`、`test/gameplay/main_scene_breakthrough_test.gd.uid`、必要时更新 `test/README.md` 的用例索引。
- 非范围：视觉特效、性能压测、4v4 战斗、存档持久化、随机化平衡测试。
- 依赖：`INC-CORE-011`、`INC-WORLD-006`。
- 检索证据：同 `INC-CULT-005`；现有 gameplay 用例覆盖宗门闭环与秘境闭环，但没有任何用例断言 `ready → realm change → capacity change`。
- 风险：真实主场景会启动默认秘境并持有全局暂停状态，用例必须在 `after_test()` 恢复暂停、清理活动单位；断言必须优先读取 Pawn / RealmDefinition 的公开 API，不能复制容量表。
- 实现说明：待实现。
- 变更文件：待实现。
- 测试证据：待实现。
- 验证状态：待验证
- 验证时间：待验证
- 已知问题：待实现。
- 用户验收：待验收
- 验收时间：待验收
- Git：待提交
- 备注：父 Increment 为 `INC-CROSS-018`；这是本批的玩法验收证据，而不是单纯 unit 覆盖。

## INC-TESTING-011：Build Replay 实验记录（自动化证据 + 人工三问）

- 状态：planned
- 创建时间：2026-09-25T20:47:54+08:00
- 最后修改：2026-09-25T21:45:00+08:00
- 主题：testing
- 重定义说明：本 Increment 原定义「4v4 闭环证据、同 Boss 再战对照与人工玩法验收剧本」于 2026-09-25T21:45:00+08:00 按用户 objective 重定义为「1v1 → 1vN 的 Build Replay 实验记录」；4v4 专用证据口径退役，原定义原文保留在 Git 历史 `b36e9c0`（`develop`）。
- 目标：把父 Increment `INC-CROSS-019` 的五个 Gate 变成可复核证据——自动化只证明机制成立（能学、能装、能切、定身能真实改变敌人状态、同遭遇可重复挑战、事件可记录），人工三问只采集玩家原话，回答「问题是否被描述、奖励是否与问题关联、是否主动重构、行为是否改变、能否解释原因」。
- 验收标准：
  - 机制证据（自动化，不替代人工结论）：
    - 技能可以学习并进入 known skills，可以进入 equipped skills；Build A 与 Build B 均可加载。
    - Build B 的技能真实进入 SkillBar；切换装配后 `SkillBar` / 信息卡 / 技能输入当帧跟随。
    - 定身实际作用于敌人：目标进入 stun 状态，危险技能被取消且该次伤害不结算。
    - 战斗结束后可以再次进入同一遭遇，事件序列独立不跨局污染。
    - 自动化不得断言「玩家是否愿意重构」，只能断言机制事实。
  - 实验记录证据（Round 1 / Round 2 对照）：
    - 产出 `build_replay_record`：Round 1（Build A）与 Round 2（Build B）分别记录 CombatEvent 序列（`danger_window_opened` → `skill_hit` / `skill_cancelled` 等）、承伤合计与战斗时长。
    - 明确记录「第二轮不要求更快或更少掉血」，只要求玩家采用了不同的解决方案；不得把时长 / 承伤优劣写成通过条件。
    - 奖励记录只有定身术；灵石 / 装备 / 强化 / 随机掉落不得出现在第一轮奖励字段中。
  - 人工验收剧本（三问，开放提问、保留原话、不得诱导）：
    - 步骤：① 用 Build A 打完 1v1 → ② 首通获得定身术 → ③ 玩家自行决定是否切换 Build → ④ 用当前 Build 重打同一个 1v1。
    - Q1 第一轮战斗中，你觉得最麻烦的问题是什么？
    - Q2 拿到定身术后，你为什么选择 / 不选择换 Build？
    - Q3 第二次战斗和第一次相比，你具体改变了什么？
    - 记录格式：`ReplayIntent`（yes / no）、`BuildChange`（none / A→B / other）、`Reason`（tactical / numerical / curiosity / completion / other）、`PerceivedImpact`（none / low / medium / high）仅作为归档标签，必须同时保留玩家原话；不得用打分替代原话。
  - 五个 Gate（父 Increment 验收硬门，缺一不可）：
    - Gate A 玩家能描述第一轮的具体战斗问题（不是「挺难的」这类泛化描述）。
    - Gate B 玩家能理解定身术与第一轮问题的关联。
    - Gate C 玩家在没有强制要求的情况下主动选择 Build B。
    - Gate D 第二轮玩家主动使用定身术去解决第一轮遇到的问题。
    - Gate E 玩家能解释为什么这样改 Build。
  - 失败条件（任一命中即父级不得 `accepted`，且禁止继续扩 Build 系统）：
    - Failure 1 玩家觉得定身不错但不想换 Build。
    - Failure 2 玩家换了 Build，但第二轮仍按第一次的方式打。
    - Failure 3 换 Build 的原因是「因为你让我试试」，而不是第一轮的问题。
    - Failure 4 Build A / B 的实际战斗体验几乎完全一样。
    - Failure 5 玩家只关注数值更大，不关心技能交互与战术选择。
  - 三档分辨率 1152x648 / 1152x720 / 800x720 的真实窗口截图与布局量测无重叠 / 无溢出；命令、退出码、关键输出与失败前后差异留档。
- 范围：`tests/` 下的 1v1 Build Replay 场景入口与取证脚本、`test/gameplay/` 下的真实主场景机制闭环用例、`test/README.md` 与 `tests/README.md` 的索引说明、人工验收记录归档。
- 非范围：替代人工验收、1v2 / 1v3 的多目标决策结论（属于 `INC-CROSS-019` Stage 2）、正式平衡测试、随机化压力测试、AOE / 仇恨 / 存档 / 联网测试。
- 依赖：`INC-COMBAT-009`、`INC-PAWNS-021`、`INC-WORLD-007`、`INC-UI-018`、`INC-TESTING-012`；父 Increment `INC-CROSS-019`。
- 检索证据：2026-09-25T21:45:00+08:00 执行 `git status --short`（工作区为 `INC-PAWNS-021` 实现与本批 plan 调整）、`git diff --unified=0 -- agent-plan/`（读取本批重定义）、`git log --oneline -5 -- agent-plan/`（最新 `1dbdba5`）与 `git grep -n "INC-TESTING-011"`；现有 gameplay 证据覆盖单单位宗门闭环、秘境闭环与 Build 决策对照，但没有「首通解锁 → 主动重构 → 同遭遇再战 → 行为变化」的实验记录。
- 风险：真实主场景测试容易受暂停、自动隐藏与活动单位残留影响，必须在 `after_test()` 清理，否则用例之间互相污染。第二个风险是把人工结论自动化替代，必须坚持「自动化只证明机制」。第三个风险是提问诱导，必须保持 Q1~Q3 原文并避免在问题里提示定身术与危险技能的关系。
- 实现说明：待实现。
- 变更文件：待实现。
- 测试证据：待实现。
- 验证状态：待验证
- 验证时间：待验证
- 已知问题：待实现。
- 用户验收：待验收
- 验收时间：待验收
- Git：待提交
- 备注：Gate A~E 的顺序不可颠倒：玩家先发现问题，才可能理解奖励与问题的关联，才可能主动重构，才可能改变行为并解释原因。

## INC-TESTING-012：场景化测试入口拆分到 `tests/`

- 状态：planned
- 创建时间：2026-09-25T21:14:43+08:00
- 最后修改：2026-09-25T21:45:00+08:00
- 主题：testing
- 重定义说明：本 Increment 原定义（为 4v4 技术 Slice 提供 2v2 / 3v3 / 4v4 与多选编队场景入口）于 2026-09-25T21:45:00+08:00 按用户 objective「每个不同场景的测试入口拆分出来，不要都放在 main 中」重定义为 1v1 / 1v2 / 1v3 / Build 切换 / 首通解锁场景入口。
- 目标：把「每个不同测试场景一个独立入口」落成仓库结构，使 `main.tscn` 只保留正式游戏入口职责，所有测试专用场景、参数与资源引用都下沉到新增的 `tests/` 目录，并让每个场景有独立的可复现启动命令。
- 验收标准：
  - 新增 `tests/` 目录与 `tests/README.md`，README 写明目录规范、每个入口的场景用途、启动命令（命令行 / MCP）与与 `test/` 的职责边界。
  - 每个场景一个独立入口 `.tscn`（必要时附 `.gd`），至少覆盖：1v1 战斗问题窗口验证、1v2 遭遇验证、1v3 遭遇验证、Build A/B 切换面板验证、1v1 首通解锁定身术验证。
  - 测试专用节点、测试专用参数与测试专用资源引用全部下沉到 `tests/` 场景；`main.tscn` 不再为测试内嵌专用引用，也不接受测试专用启动参数。
  - `main.tscn` 继续作为正式游戏入口，加载后进入正常秘境流程；测试入口不得改变正式入口行为。
  - `test/`（GdUnit4 自动化断言）与 `tests/`（场景化可交互入口）职责边界写清楚，并在 `test/README.md` 交叉引用。
  - 每个入口在真实窗口下可加载、可重复打开且无脚本错误；重复运行不重复解锁技能、不残留活动单位。
- 范围：新增 `tests/`（场景、脚本、README）、`AGENTS.md` §5.1 与 §12.6 的目录规范条目（已随本批生效）、`test/README.md` 的交叉说明、`agent-plan/testing.md` 与 `_index.md` 的回写。
- 非范围：替换 GdUnit4 自动化断言、引入新测试框架、修改正式游戏玩法规则。
- 依赖：`INC-WORLD-007`（提供 1v1 / 1v2 / 1v3 遭遇数据）、`INC-UI-018`（提供 Build 切换面板）、`INC-COMBAT-009`（提供问题窗口）、`INC-PAWNS-021`（提供技能解锁 API）。
- 检索证据：2026-09-25T21:45:00+08:00 执行 `git status --short`、`git diff --unified=0 -- agent-plan/`、`git log --oneline -5 -- agent-plan/`（最新 `1dbdba5`）与 `git grep -n "INC-TESTING-012"`；编号已占用且归属本批，仓库根目录当前没有 `tests/` 目录。
- 风险：目录名 `tests/` 与既有 `test/` 只差一个字母，容易混用；必须在两份 README 与 Agent 规则里显式写明职责边界，否则后续 Agent 可能把自动化断言写进 `tests/` 或把场景入口写进 `test/`。第二个风险是测试入口悄悄改正式入口行为，必须由「`main.tscn` 不含测试专用引用」这一条守住。
- 实现说明：待实现。
- 变更文件：待实现。
- 测试证据：待实现。
- 验证状态：待验证
- 验证时间：待验证
- 已知问题：待实现。
- 用户验收：待验收
- 验收时间：待验收
- Git：待提交
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 只调整测试入口的组织方式，不改变玩法规则与战斗数值。
