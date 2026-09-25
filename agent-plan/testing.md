# Testing 主题计划

> 最后修改：2026-09-25T16:50:57+08:00
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

- 状态：planned
- 创建时间：2026-09-25T17:31:30+08:00
- 最后修改：2026-09-25T17:31:30+08:00
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
- 检索证据：待前置 Increment 计划落库后按 Git Diff 复核；当前没有跨 Build 的战斗过程轨迹测试。
- 风险：确定性测试必须避免墙钟和渲染帧依赖；目标寻路/移动造成的微小浮点差异需要容差或离散事件记录；测试不能替业务层伪造效果。
- 实现说明：测试只组装已存在的数据资源与控制器 API，记录事件/数值快照，不把平衡逻辑写进测试代码。
- 变更文件：待实现回填。
- 测试证据：待实现回填。
- 验证状态：未验证
- 已知问题：待实现回填。
- 用户验收：待验收
- Git：待验收后提交
- 备注：父 Increment 为 `INC-CROSS-012`；本 Increment 是父级 Gameplay 验收的核心证据层。
