# Testing 主题计划

> 最后修改：2026-09-26T02:09:20+08:00
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

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T20:47:54+08:00
- 最后修改：2026-09-25T23:05:40+08:00
- 主题：testing
- 重定义说明：本 Increment 原定义「4v4 闭环证据、同 Boss 再战对照与人工玩法验收剧本」于 2026-09-25T21:45:00+08:00 按用户 objective 重定义为「1v1 → 1vN 的 Build Replay 实验记录」；4v4 专用证据口径退役，原定义原文保留在 Git 历史 `b36e9c0`（`develop`）。
- 调整说明（2026-09-25T21:50:38+08:00）：按外部设计评审意见做两处收紧——① 把「重构后战斗是否真的发生变化」从只靠玩家自述改为「原话 + CombatEvent 客观对照判据」（Round 1 不得出现 `skill_cancelled`；Round 2 必须出现 `skill_stunned` → `skill_cancelled`，且该次危险技能伤害不结算；两轮序列相同即判 Failure 4）；② 保留三问硬门不变，新增非门控问题 Q4，用于观察「奖励是否是再战动机」。
- 目标：把父 Increment `INC-CROSS-019` 的 Gate 0 与五个玩法 Gate 变成可复核证据——自动化只证明机制成立（能学、能装、能切、定身能真实改变敌人状态、同遭遇可重复挑战、事件可记录），人工三问只采集玩家原话，回答「问题是否被描述、奖励是否与问题关联、是否主动重构、行为是否改变、能否解释原因」。
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
    - 客观对照判据（与玩家原话并列，不得只凭自述判定）：Round 1 处理危险窗口的事件序列为 `danger_window_opened` → `skill_hit`（或 `skill_blocked`），不得出现 `skill_cancelled`；Round 2 在 Build B 下处理同一窗口必须出现 `skill_stunned` → `skill_cancelled`，且该次危险技能伤害未结算。两轮应对序列相同即判定 Failure 4，即使玩家自述「换了打法」。
    - Gate D 证据口径：Gate D 必须同时满足「玩家原话说明用定身解决第一轮问题」与「CombatEvent 出现 `skill_cancelled`」；两者冲突时以事件序列为准，并记入已知问题。
    - 奖励记录只有定身术；灵石 / 装备 / 强化 / 随机掉落不得出现在第一轮奖励字段中。
  - 人工验收剧本（三问，开放提问、保留原话、不得诱导）：
    - 步骤：① 用 Build A 打完 1v1 → ② 首通获得定身术 → ③ 玩家自行决定是否切换 Build → ④ 用当前 Build 重打同一个 1v1。
    - Q1 第一轮战斗中，你觉得最麻烦的问题是什么？
    - Q2 拿到定身术后，你为什么选择 / 不选择换 Build？
    - Q3 第二次战斗和第一次相比，你具体改变了什么？
    - Q4（附加、非门控、可选记录）：如果这次没有拿到新能力，你还会主动再打一轮吗？该问题不参与 Gate 判定，仅作参考，仍须保留原话。
    - 记录格式：`ReplayIntent`（yes / no）、`BuildChange`（none / A→B / other）、`Reason`（tactical / numerical / curiosity / completion / other）、`PerceivedImpact`（none / low / medium / high）仅作为归档标签，必须同时保留玩家原话；不得用打分替代原话。
  - Gate 0（技术成立前置门，必须先成立；未通过不得进入人工验收）：1v1 危险窗口可稳定复现；1v2 / 1v3 为「敌方全灭才判胜、玩家单位死亡即失败」；定身可真实打断危险技能（`skill_stunned` → `skill_cancelled` 且伤害不结算）；Build A / B 可加载并当帧影响 SkillBar；同一遭遇可重复挑战且事件不跨局污染；`tests/` 场景入口可独立启动。
  - 五个玩法 Gate（父 Increment 验收硬门，缺一不可）：
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
- 检索证据（2026-09-25T22:42:10+08:00）：`git status --short` 工作区干净（HEAD `9be2198`，本地 = `origin/develop`）；`git diff --unified=0 -- agent-plan/` 与 `git diff --cached --unified=0 -- agent-plan/` 均无输出；`git log --oneline -3` 显示 `9be2198`（`INC-TESTING-012` 计划回写）→ `fd3eda8`（`INC-TESTING-012` 实现）→ `1cce5bf`（`INC-UI-018`）；`git grep -n -E "INC-TESTING-011|build_replay" -- agent-plan/ test/ docs/` 只命中本计划、父级索引与 `docs/build-gameplay-validation.md`，`test/tools/` 与 `test/gameplay/` 下没有任何 `build_replay` 产物，`test/tools/` 现有 4 份取证脚本（血条 / 信息卡 / 宗门面板 / Build 面板）；`tests/` 现有 5 个入口但没有 Replay 专用入口。依赖 `INC-COMBAT-009` / `INC-PAWNS-021` / `INC-WORLD-007` / `INC-UI-018` / `INC-TESTING-012` 均已实现并推送到 `develop`（仅 `INC-TESTING-011` 自身为 `planned`）。既有证据缺口：`test/integration/danger_window_combat_event_test.gd` 已证明「无控制必被命中」与「定身打断且零伤害」两条机制，但它用测试自造 PawnData，未在真实 `main.tscn` 上跑「首通解锁 → 主动切 Build B → 同一遭遇再战」的对照，也没有产出 Round 1 / Round 2 的 `build_replay_record`。历史记录（2026-09-25T21:50:38+08:00）执行 `git status --short`（工作区干净）、`git diff --unified=0 -- agent-plan/`（空）、`git diff --cached --unified=0 -- agent-plan/`（空）、`git log --oneline -- agent-plan/`（HEAD `0f8fb41`）与 `git grep -n -E "INC-(COMBAT-009|WORLD-007|TESTING-011)" -- agent-plan/`；结论：三个 Increment 均为 `planned`、未实现，可安全调整；`game/world/encounter_session.gd` 头部注释与 `_on_unit_died()` 仍为单点终局（敌人死亡即 PLAYER_WIN），证明 1vN 全灭判胜确实未实现。历史记录（2026-09-25T21:45:00+08:00） `git status --short`（工作区为 `INC-PAWNS-021` 实现与本批 plan 调整）、`git diff --unified=0 -- agent-plan/`（读取本批重定义）、`git log --oneline -5 -- agent-plan/`（最新 `1dbdba5`）与 `git grep -n "INC-TESTING-011"`；现有 gameplay 证据覆盖单单位宗门闭环、秘境闭环与 Build 决策对照，但没有「首通解锁 → 主动重构 → 同遭遇再战 → 行为变化」的实验记录。
- 风险：真实主场景测试容易受暂停、自动隐藏与活动单位残留影响，必须在 `after_test()` 清理，否则用例之间互相污染。第二个风险是把人工结论自动化替代，必须坚持「自动化只证明机制」。第三个风险是提问诱导，必须保持 Q1~Q3 原文并避免在问题里提示定身术与危险技能的关系。
- 实现说明：拆成「驱动层 + 用例 + 取证脚本 + 人工入口」四件可复核产物：① `test/tools/build_replay_driver.gd`（`class_name BuildReplayDriver`）：Replay 的唯一驱动层，用例与取证脚本都调它，避免两份对照代码漂移。流程为「先关默认秘境（入树前 `default_dungeon = null`，与 `tests/` 入口同序）→ `session.begin()` 正式 1v1 遭遇 → 用真实 `PlayerController` 跨物理帧走到定身施放距离（走位期间不推进会话，保证两轮同一个时间原点）→ 推进危险窗口 → Round 2 用 `Pawn.cast_skill()` 施放定身 → 走到原结算时刻之外确认没有补结算」，只读公开 API 与 `CombatEventLog`，不复制伤害 / 奖励 / 眩晕公式。② `test/gameplay/build_replay_loop_test.gd`：在真实 `main.tscn` 上跑脚本化 Replay，断言机制事实与客观对照判据（Round 1 无 `skill_cancelled`、Round 2 必须 `skill_stunned` → `skill_cancelled`、两轮序列相同即 Failure 4、事件日志不跨局累积、首通只解锁不装配、切换只经生产面板按钮且 SkillBar 跟随）。③ `test/tools/capture_build_replay_record.gd`：产出 `build_replay_record`（`.md` + `.json`，落不入库的 `.mcp/godot-runtime/screenshots/`），自动段写 Round 1 / Round 2 的事件序列、危险技能结算方式、承伤合计、战斗时长、首通奖励与面板切换裁决；人工段留 `待人工` 占位（Q1~Q4 原话、四个归档标签、Gate 0 与 Gate A~E），脚本只做机制自检，不代填结论。④ `tests/scenario_build_replay.tscn`：人工实验入口（未解锁定身术起局），把 §8 的四步剧本写进场景说明，并登记进 `test/tools/verify_scenario_entries.gd` 的入口体检清单。关键取舍：走位必须跨物理帧驱动——同一帧内手工连调 `move_and_slide()` 的实际位移远小于 `velocity * delta`（实测 4000 次步进只移动 175px），因此 `approach_target()` 改成 `await tree.physics_frame` 的真实走位；两轮的可比条件锁定为「站位与时机相同」，不比较输出。Round 1 / Round 2 的承伤与时长只作对照数据，明确不写成通过条件（docs §8）。
- 变更文件：新增 `test/tools/build_replay_driver.gd`（含 `.uid`）、`test/tools/capture_build_replay_record.gd`（含 `.uid`）、`test/gameplay/build_replay_loop_test.gd`（含 `.uid`）、`tests/scenario_build_replay.tscn`；修改 `test/tools/verify_scenario_entries.gd`（入口体检清单加 `build_replay` 一行）、`tests/README.md`（入口清单加一行 + 取证脚本运行方式）、`test/README.md`（`test/tools` 行补驱动层说明）、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 测试证据：① 单套件 `& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/gameplay/build_replay_loop_test.gd -rd res://reports/gdunit/debug_replay --ignoreHeadlessMode`：`Statistics: 2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`，两个用例 PASSED。② 取证脚本（真实窗口）`& $env:GODOT_BIN --path . --script res://test/tools/capture_build_replay_record.gd`：`BUILD_REPLAY_CAPTURE_DONE FAILURES=0`，退出码 0。产出记录的可复核事实：Round 1 `danger_window_opened → skill_cast → skill_hit`（承伤 生命 5.0 / 护盾 40.0，事件时钟 10.20s），Round 2 `danger_window_opened → skill_cast → skill_stunned → skill_cancelled`（承伤 0.0 / 0.0，事件时钟 10.30s），两轮序列不同故 Failure 4 未触发；首通 `known_before ["sword_strike","guard_true_qi"] → known_after [...,"binding_spell"]` 且 `auto_equipped_by_reward=false`；面板裁决 `accepted=true reason=""`，切换后装配 `["sword_strike","binding_spell"]` 且技能栏含 `binding_spell`。③ 入口体检（真实窗口）`& $env:GODOT_BIN --path . --script res://test/tools/verify_scenario_entries.gd`：`SCENARIO_ENTRY_CHECK_DONE FAILURES=0`（6 个入口各加载两次，含新增 `build_replay`）。④ 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`：`RESULT: PASS`（GdUnit4 397 cases 0 failures、headless 10 suites / 549 assertions / 0 failing suites、exit 0）。⑤ 人工轮：待用户按 `tests/scenario_build_replay.tscn` 剧本实机跑一次并回答三问（本轮不计入自动证据）。
- 验证状态：验证通过（机制层 + 客观对照判据；Gate A~E 属人工轮）
- 验证时间：2026-09-25T23:05:40+08:00
- 已知问题：① Gate A~E 与四个归档标签必须由玩家原话填写，本轮只交付机制事实与记录骨架——`build_replay_record` 的人工段仍为「待人工」，不得由自动化代填；② 脚本化 Replay 与真实人工 Replay 可能不一致（脚本走位到定身距离后停手，人工玩家会有普通攻击与走位差异），两者冲突时以人工轮为准并记入已知问题；③ 抓取脚本未纳入 `run_tests.ps1` 门禁（需要真实窗口且耗时约 12s），属于提交前手工步骤；④ `approach_target()` 依赖真实物理帧（约 4s 实时/轮），单套件约 14s，比既有 gameplay 套件慢；⑤ 既有测试债务不变（`main_scene_sect_test.gd` 324 orphans、`sect_panel_test.gd` 288 orphans）。
- 用户验收：待验收
- 验收时间：待验收
- Git：`develop` / `d6bd273`
- 备注：Gate A~E 的顺序不可颠倒：玩家先发现问题，才可能理解奖励与问题的关联，才可能主动重构，才可能改变行为并解释原因。

## INC-TESTING-012：场景化测试入口拆分到 `tests/`

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T21:14:43+08:00
- 最后修改：2026-09-25T22:33:49+08:00
- 主题：testing
- 重定义说明：本 Increment 原定义（为 4v4 技术 Slice 提供 2v2 / 3v3 / 4v4 与多选编队场景入口）于 2026-09-25T21:45:00+08:00 按用户 objective「每个不同场景的测试入口拆分出来，不要都放在 main 中」重定义为 1v1 / 1v2 / 1v3 / Build 切换 / 首通解锁场景入口。
- 调整说明（2026-09-25T22:22:00+08:00）：`INC-WORLD-007` 为实现阶段的可玩性，把三份试剑遭遇（`build_test_1v1/1v2/1v3`）**临时**接进了 `game/main/main.tscn` 的遭遇面板（提交 `e591f33`）。按用户硬要求「每个不同场景的测试入口拆分到 `tests/`，不要都放在 `main` 中」，本 Increment 必须把这批临时条目从 `main.tscn` 移出并改为 `tests/` 场景入口；移出后 `main.tscn` 只保留正式遭遇（`encounter_trial_puppet` / `encounter_iron_guard` / `encounter_blood_blade`），`test/gameplay/main_scene_encounter_test.gd` 的面板断言同步回到「三份正式遭遇」。
- 目标：把「每个不同测试场景一个独立入口」落成仓库结构，使 `main.tscn` 只保留正式游戏入口职责，所有测试专用场景、参数与资源引用都下沉到新增的 `tests/` 目录，并让每个场景有独立的可复现启动命令。
- 验收标准：
  - 新增 `tests/` 目录与 `tests/README.md`，README 写明目录规范、每个入口的场景用途、启动命令（命令行 / MCP）与与 `test/` 的职责边界。
  - 每个场景一个独立入口 `.tscn`（必要时附 `.gd`），至少覆盖：1v1 战斗问题窗口验证、1v2 遭遇验证、1v3 遭遇验证、Build A/B 切换面板验证、1v1 首通解锁定身术验证。
  - 测试专用节点、测试专用参数与测试专用资源引用全部下沉到 `tests/` 场景；`main.tscn` 不再为测试内嵌专用引用（含 `INC-WORLD-007` 临时接入的三份试剑遭遇），也不接受测试专用启动参数。
  - `main.tscn` 继续作为正式游戏入口，加载后进入正常秘境流程；测试入口不得改变正式入口行为。
  - `test/`（GdUnit4 自动化断言）与 `tests/`（场景化可交互入口）职责边界写清楚，并在 `test/README.md` 交叉引用。
  - 每个入口在真实窗口下可加载、可重复打开且无脚本错误；重复运行不重复解锁技能、不残留活动单位。
- 范围：新增 `tests/`（场景、脚本、README）、`AGENTS.md` §5.1 与 §12.6 的目录规范条目（已随本批生效）、`test/README.md` 的交叉说明、`game/main/main.tscn` 的测试条目回退（移出三份试剑遭遇）、`test/gameplay/main_scene_encounter_test.gd` 的同步断言、`agent-plan/testing.md` 与 `_index.md` 的回写。
- 非范围：替换 GdUnit4 自动化断言、引入新测试框架、修改正式游戏玩法规则。
- 依赖：`INC-WORLD-007`（提供 1v1 / 1v2 / 1v3 遭遇数据）、`INC-UI-018`（提供 Build 切换面板）、`INC-COMBAT-009`（提供问题窗口）、`INC-PAWNS-021`（提供技能解锁 API）。
- 检索证据：2026-09-25T21:45:00+08:00 执行 `git status --short`、`git diff --unified=0 -- agent-plan/`、`git log --oneline -5 -- agent-plan/`（最新 `1dbdba5`）与 `git grep -n "INC-TESTING-012"`；编号已占用且归属本批，仓库根目录当前没有 `tests/` 目录。
- 风险：目录名 `tests/` 与既有 `test/` 只差一个字母，容易混用；必须在两份 README 与 Agent 规则里显式写明职责边界，否则后续 Agent 可能把自动化断言写进 `tests/` 或把场景入口写进 `test/`。第二个风险是测试入口悄悄改正式入口行为，必须由「`main.tscn` 不含测试专用引用」这一条守住。
- 实现说明：新增 `tests/scenario_entry.gd` 作为全部入口的唯一脚本：`scenario_id` / `scenario_title` / `scenario_instructions` / `encounter` / `pre_learn_binding_spell` / `pre_equip_build_b` / `select_player_on_start` 全部由场景导出，`_ready()` 先关掉默认秘境（`dungeon_run.default_dungeon = null`，只作用于本运行实例），再 `session.begin(encounter)`、按导出开关施加前置条件（只动 Pawn 运行时投影：`learn_active_skill()` / `set_active_skill_loadout()`）、`main.call("_set_selected_pawn", ...)`，最后把窗口标题写成 `test1 · tests/<id> · <title>` 并 `print("SCENARIO_READY ", ...)`，便于人工和脚本直接核对「我跑的是哪个入口」。5 个入口各一个 `.tscn`：`scenario_build_test_1v1`（Build A 打问题窗口）、`scenario_build_test_1v2`（预解锁定身术 / 未装配）、`scenario_build_test_1v3`（预解锁）、`scenario_build_loadout_switch`（预解锁，验右下角面板）、`scenario_first_clear_reward`（不解锁，验首通奖励）。`game/main/main.tscn` 移出 `INC-WORLD-007` 临时接入的三份试剑遭遇（`ext_resource` 28/29/30 与 `EncounterPanel.encounters` 的三条条目），只保留 `encounter_trial_puppet` / `encounter_iron_guard` / `encounter_blood_blade` 三份正式遭遇。`test/README.md` 增加 `../tests` 交叉引用与「## 与 `tests/` 的分工」章节。`test/gameplay/main_scene_encounter_test.gd` 的面板断言回到三份正式遭遇并新增 `assert_int(buttons.size()).is_equal(3)`。新增 `test/tools/verify_scenario_entries.gd` 做入口体检：逐入口加载两次（首次 + 重复打开），核对 id / 遭遇 / 敌我人数 / 状态 RUNNING / 定身术解锁状态（期望集合为静态预设 `["sword_strike","guard_true_qi"]`，`pre_learn_binding_spell` 时再追加 `"binding_spell"`）/ 窗口标题 / 释放后无残留，报告落 `.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt`。
- 变更文件：新增 `tests/scenario_entry.gd`（含 `.uid`）、`tests/scenario_build_test_1v1.tscn`、`tests/scenario_build_test_1v2.tscn`、`tests/scenario_build_test_1v3.tscn`、`tests/scenario_build_loadout_switch.tscn`、`tests/scenario_first_clear_reward.tscn`、`tests/README.md`、`test/tools/verify_scenario_entries.gd`（含 `.uid`）；修改 `game/main/main.tscn`（移出三份临时试剑遭遇与 3 条 `ext_resource`）、`test/README.md`、`test/gameplay/main_scene_encounter_test.gd`、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 测试证据：入口体检（真实窗口，非 headless）`& $env:GODOT_BIN --path . --script res://test/tools/verify_scenario_entries.gd` → `SCENARIO_ENTRY_CHECK_DONE FAILURES=0`，5 个入口首次与重复打开两次结果一致（1v1 玩家 1 / 敌人 1、1v2 敌人 2、1v3 敌人 3、状态均为 RUNNING、窗口标题含 `tests/<id>`、重复解锁按 id 去重、无残留活动单位）；报告 `.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt`。受影响套件 gameplay 层 60 cases / 0 errors / 0 failures。统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 395 cases / 0 failures；headless 10 suites / 549 assertions / 0 failing suites；exit 0）。`game/main/main.tscn` 已用 `git diff` 确认不再含任何测试专用引用。
- 验证状态：验证通过
- 验证时间：2026-09-25T22:33:49+08:00
- 已知问题：`tests/` 与既有 `test/` 只差一个字母，已由 `tests/README.md`、`test/README.md` 与 `AGENTS.md` §5.1 / §12.6 三处显式划线，但仍是后续 Agent 最容易混用的地方。入口体检脚本需要真实窗口（`--headless` 下 dummy 窗口固定 64x64，不满足布局与窗口标题核对），因此未纳入 `run_tests.ps1`，属于提交前的手工步骤。测试入口在 `_ready()` 里改写 `default_dungeon`，只影响 `tests/` 场景内的运行实例，不写回 `.tres`。
- 用户验收：待验收
- 验收时间：待验收
- Git：`develop` / `fd3eda8`
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 只调整测试入口的组织方式，不改变玩法规则与战斗数值。

## INC-TESTING-013：Stage 2（1v1 / 1v2 / 1v3）运行时终局收敛与重开清洁证据

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T23:30:00+08:00
- 最后修改：2026-09-25T23:55:00+08:00
- 主题：testing
- 目标：为 `INC-CROSS-019` §27「技术」退出条件中的「1v1 可稳定运行 / 1v2 / 1v3 可稳定运行 / 同一遭遇可以重复挑战」补上真实运行时证据——三份 Build 验证遭遇用正式 `EncounterSession` 与真实控制器跑到终局，并可重复开局而不残留。
- 验收标准：
  - 新增 gameplay 用例，逐份跑 `build_test_1v1` / `build_test_1v2` / `build_test_1v3`：玩家单位 1，敌方单位 1 / 2 / 3，单位容器内单位数与敌人数量一致。
  - 每份遭遇在固定 60fps 时间步下必须跑到终局（`PLAYER_WIN` 或 `ENEMY_WIN`），不得停在 `RUNNING`；不得用直接致死调用来伪造终局。
  - 1v2 / 1v3 下主目标死亡后，玩家控制器必须能改打下一个存活敌人（`order_attack`），直到敌方全灭或玩家死亡。
  - 终局后 `restart()` 同一遭遇：玩家满血、未处于定身、事件记录清空、敌我人数与首次一致、上一局单位不再留在容器内。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 为 `RESULT: PASS`。
- 范围：新增 `test/gameplay/build_test_stage2_stability_test.gd`（含 `.uid`）；`test/README.md` 补一行层内说明；`agent-plan/testing.md`、`agent-plan/_index.md` 回写。
- 非范围：不改玩法数值、不改遭遇数据、不改 `EncounterSession` / 控制器 / 技能实现；不替代 `INC-TESTING-011` 的人工玩法轮；不产生任何「好玩 / 不好玩」结论。
- 依赖：`INC-WORLD-007`（固定 1v1 / 1v2 / 1v3 遭遇）、`INC-COMBAT-009`（敌方全灭才判胜 + CombatEvent）、`INC-PAWNS-021`（Build / Loadout）、`INC-TESTING-012`（`tests/` 人工入口）。
- 检索证据：2026-09-25T23:30:00+08:00 执行 `git status --short`（无输出）、`git diff --unified=0 -- agent-plan/` 与 `git diff --cached --unified=0 -- agent-plan/`（均无输出）、`git log --oneline -8 -- agent-plan/`（最新 `78dc351`）、`git grep -n -E "INC-TESTING-0(1[1-9]|2[0-9])" -- agent-plan/`（`INC-TESTING-013` 未被占用）与 `git grep -n "build_test_1v"`（`build_test_encounter_catalog_test.gd` 只查数据目录、`verify_scenario_entries.gd` 只查入口加载、`first_clear_reward_test.gd` 用直接致死抹掉敌人）。结论：§27 技术项的 1v2 / 1v3 目前只有「数据目录 + 入口能加载」两类证据，缺真实运行时终局证据，故新建本 Increment。
- 风险：1vN 终局收敛依赖 AI 与数值，若 60s 内不分胜负会产生 flaky；用固定时间步 + 明确终局上限，超时即判失败，不截断结果冒充胜负。若修复过程中需要改动 `game/` 下实现即为越界，须另立 Increment。
- 实现说明：新增 `test/gameplay/build_test_stage2_stability_test.gd`，只用正式 `EncounterSession` + 真实 `Pawn` / `PlayerController` / `AIController` 跑到终局，不另建第二套战斗规则：① 阵容口径先核对（玩家 1 个单位，敌方 1 / 2 / 3，单位容器内单位数 = 敌人数 + 1）；② 关掉引擎物理帧后按固定 60fps 手工步进，玩家只通过 `PlayerController.order_attack()` 下命令，主目标死亡后改打下一个存活敌人（`retargets` 记录实际换目标次数），敌人用 `AIController.update_controller()` 推进，事件时钟与危险窗口由会话自己的 `_physics_process()` 单独推进；③ 断言只盯「是否收敛到终局」「终局语义是否正确（胜 = 敌方全灭，负 = 玩家单位死亡）」「终局是否写进 CombatEvent」「重开是否清洁」；④ 承伤 / 时长只打印不参与断言，不产生平衡与「好不好玩」结论。刻意不做的事：不用 `take_damage()` 直接抹掉敌人来伪造终局（`first_clear_reward_test.gd` 的做法在本 Increment 不可接受），也不给玩家脚本化技能循环（避免把「机制收敛」和「AI 打法」混在一起）。`test/README.md` 只补一条手工步进的陷阱说明，不改分层约定。
- 变更文件：新增 `test/gameplay/build_test_stage2_stability_test.gd`（含 `.uid`）；修改 `test/README.md`（已知陷阱补一条）、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 测试证据：① 单套件 `& $env:GODOT_BIN --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/gameplay/build_test_stage2_stability_test.gd -rd res://reports/gdunit/debug_stage2 --ignoreHeadlessMode`：`Statistics: 2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`，exit 0。过程事实（两次独立运行）：1v1 `state=失败 seconds=16.68 / 18.43`，1v2 `state=胜利 seconds=12.32 / 12.25 retargets=2 enemies_alive=0`，1v3 `state=失败 seconds=9.93 / 9.95 enemies_alive=2`；重开轮 1v1 `15.07s`、1v2 `11.87 / 11.98s`、1v3 `9.90 / 9.92s`。三份遭遇都在 10~19 秒内收敛到终局，其中 1v2 的胜利发生在主目标死亡后换目标打掉第二名敌人（`retargets=2`），运行时证明 1vN 的目标切换与「敌方全灭才判胜」。② 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all`：`RESULT: PASS`（GdUnit4 399 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing suites、exit 0；gameplay 层由 62 增至 64 cases）。③ `git status --short` 只有本 Increment 的预期变更。
- 验证状态：验证通过
- 验证时间：2026-09-25T23:55:00+08:00
- 已知问题：① 本用例不保证逐帧可重复：手工步进下 `move_and_slide()` 的位移由引擎物理步给出，同一份遭遇的终局时长跨进程会在 15~19 秒之间波动（断言上限 60 秒，余量充足），因此它只证明「能在预算内收敛」，不证明「耗时固定」；② 驱动里玩家只做普通攻击、不施放主动技能，1v1 / 1v3 的记录结果是玩家落败——这属于编排口径而非难度结论，能否打赢仍以人工轮与 `INC-TESTING-011` 为准；③ 既有测试债务不变（`main_scene_sect_test.gd` 324 orphans、`sect_panel_test.gd` 288 orphans）。
- 用户验收：未验收
- 验收时间：
- Git：`develop` / `6d7b388`
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 只补 Stage 2 的运行时稳定性证据。

## INC-TESTING-014：人工轮 CombatEvent 取证（实机每局应对序列落盘）

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T23:01:35+08:00
- 最后修改：2026-09-25T23:01:35+08:00
- 主题：testing
- 目标：给 `INC-CROSS-019` §20 Gate D 的「原话 + 事件佐证」补上人工轮一侧的事件证据——玩家在 `tests/scenario_build_replay.tscn` 实机打完后，每局结算自动把只读事实（事件序列、结算方式、事件时钟、装配状态）追加到本地记录文件，供人工原话与事件对照。
- 验收标准：
  - `tests/scenario_build_replay.tscn` 打开后，玩家每打完一局（`encounter_finished`）就追加一段：局内序号、遭遇 id、结算结果、事件时钟、事件数量、已掌握 / 已装配技能、玩家残余生命与护盾，以及 `CombatEventLog.describe()` 的完整事件行（含 `combat_end`）。
  - 只写事实、不写结论：记录器只读 `EncounterSession` 公开 API 与 `CombatEventLog`，不复制伤害 / 奖励 / 胜负规则，也不填任何 Gate / Failure 结论。
  - 未打完整局时不写文件（自动化的入口体检不得污染人工记录）。
  - 记录路径可导出（默认 `.mcp/godot-runtime/screenshots/human_replay_events.md`，该目录不入库）；自动化自检使用独立路径，不污染人工记录。
  - 新增自动化用例覆盖「每局落盘 + 第二局追加」这条链路；统一门禁 `RESULT: PASS`。
- 范围：`tests/scenario_entry.gd`（新增只读记录器与两个导出参数）、`tests/scenario_build_replay.tscn`（打开记录开关）、`tests/README.md`（写清记录器职责与文件位置）、新增 `test/gameplay/human_round_record_test.gd`（含 `.uid`）、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 非范围：不改玩法数值、不改 `game/` 下实现；不替玩家填 Q1~Q4 与 Gate 结论；不替代 `INC-TESTING-011` 的脚本化机制事实记录。
- 依赖：`INC-COMBAT-009`（CombatEvent / CombatEventLog）、`INC-WORLD-007`（遭遇与首通奖励）、`INC-TESTING-012`（`tests/` 入口架构）、`INC-TESTING-011`（人工轮剧本与记录骨架）。
- 检索证据（2026-09-25T23:01:35+08:00）：`git log --oneline -3` 最新为 `dbf5f50`；读取 `tests/scenario_entry.gd`、`tests/README.md`、`test/tools/capture_build_replay_record.gd` 与 `game/combat/events/combat_event_log.gd` 后确认：人工入口当时只有 `SCENARIO_READY` 打印，没有任何 CombatEvent 落盘，`build_replay_record.md` 的机制事实全部来自脚本化 Replay——Gate D 要求的「事件佐证」因此没有绑定人工轮，故新建本 Increment。
- 风险：记录器写在 `tests/` 侧，必须守住「只读事实、不下结论」的边界，否则会越过人工轮由人给出结论的硬要求；记录文件落在不入库的 `.mcp/` 下，重跑入口才能重建。
- 实现说明：
  - `tests/scenario_entry.gd` 新增 `record_combat_events` / `record_path` 导出参数，默认只给 `tests/scenario_build_replay.tscn` 开启；新增 `entry_ready` 就绪标志，入口完成全部异步摆放并挂上 `encounter_finished` 后才置位，避免自动化在记录器挂载前结算第一局。
  - `_on_round_finished_record()` 只读 `EncounterSession.get_player_pawn()` / `get_known_active_skills()` / `get_equipped_active_skills()` 与 `CombatEventLog.describe()`；记录头使用真实场景文件名 `scenario_build_replay.tscn`，每局追加写，不覆盖历史。
  - `tests/README.md` 补记记录器职责与 `.mcp/godot-runtime/screenshots/human_replay_events.md` 落点；新增 `test/gameplay/human_round_record_test.gd` 覆盖「未结算不写」「首局落盘」「重开第二局追加」。
- 变更文件：
  - `tests/scenario_entry.gd`
  - `tests/scenario_build_replay.tscn`
  - `tests/README.md`
  - `test/gameplay/human_round_record_test.gd`
  - `test/gameplay/human_round_record_test.gd.uid`
  - `agent-plan/testing.md`
  - `agent-plan/_index.md`
- 测试证据：
  - 单套件：`& <godot> --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/gameplay/human_round_record_test.gd -rd res://reports/gdunit/debug_human_record_final --ignoreHeadlessMode` → `2 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans`，exit 0；控制台出现 `HUMAN_ROUND 1 ...` 与 `HUMAN_ROUND 2 ...`，证明第二局是追加而非覆盖。
  - 入口体检：`& <godot> --headless --path . --script res://test/tools/verify_scenario_entries.gd` → `SCENARIO_ENTRY_CHECK_DONE FAILURES=0`（6 入口 × 2 次），记录开关未破坏既有入口。
  - 统一门禁：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 401 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing suites，exit 0）。层内仍报告既有 orphan 债务（integration 288 / gameplay 324 个 orphans），本次 errors / failures 均为 0，未新增 orphan。
- 验证状态：验证通过
- 验证时间：2026-09-25T23:01:35+08:00
- 已知问题：① 记录文件为追加写，同一路径重复人工轮会累积历史局；正式人工轮开始前应删除旧文件或改用新的 `record_path`。② `.mcp/` 不入库，记录需重跑入口重建。③ 记录器只写事实，Gate D 结论仍必须由人工原话 + `skill_cancelled` 事件对照给出。④ 既有 orphan 债务（integration 288 / gameplay 324）与本次无关。
- 用户验收：未验收
- 验收时间：
- Git：develop / 3549aa1
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 只补人工轮的取证装置。

## INC-TESTING-015：人工轮可控开局（支持 --pause-on-start）

- 状态：accepted
- 创建时间：2026-09-25T23:07:54+08:00
- 最后修改：2026-09-26T00:19:06+08:00
- 主题：testing
- 目标：给 `tests/scenario_build_replay.tscn` 增加「启动即暂停」能力，避免人工轮在玩家未就绪时被实时战斗消耗，确保 Round 1 从满状态开始；玩家按 Space 后才开始实时战斗。
- 验收标准：
  - 使用 `-- --pause-on-start` 启动人工入口后，入口完成异步摆放并输出 `SCENARIO_READY`，随后处于暂停状态：HUD 显示「游戏已暂停」且暂停遮罩可见。
  - 玩家按 Space 可以恢复实时战斗；不传 `--pause-on-start` 时，既有入口行为不变，入口体检与自动化门禁不受影响。
  - 新增自动化用例验证 `pause_on_start = true` 时入口在 `entry_ready` 后暂停并可恢复；统一门禁 `RESULT: PASS`。
- 范围：`tests/scenario_entry.gd`（新增 `pause_on_start` 导出参数与 `--pause-on-start` 用户参数识别）、`test/gameplay/human_round_record_test.gd`（新增可控开局用例）、`tests/README.md`（记录人工轮启动命令）、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 非范围：不改玩法数值、不改 `game/` 下实现；不自动开始或结束战斗；不替代人工 Q1~Q4 与 Gate 结论。
- 依赖：`INC-TESTING-012`（`tests/` 入口架构）、`INC-TESTING-014`（人工轮记录器）。
- 检索证据（2026-09-25T23:07:54+08:00）：`git status --short --branch` 工作区干净，`develop = origin/develop`；读取 `tests/scenario_entry.gd`、`game/main/main.gd` 的 `_set_paused()` / `_unhandled_input()` 与 `tests/README.md` 后确认：入口没有暂停开局能力，`scenario_build_replay.tscn` 打开后立即实时运行；MCP 桥接启动期间无人操作时第一局会自动失败并写入无效记录（本轮已实测并清理），因此需要可控开局。
- 风险：暂停整个 SceneTree 会影响依赖 `await_idle_frame()` 的 GdUnit 用例；自动化用例必须使用 `process_always` 计时器并在断言后立刻恢复 `get_tree().paused = false`，避免挂住测试框架。
- 实现说明：`tests/scenario_entry.gd` 新增导出参数 `pause_on_start` 与用户参数识别 `OS.get_cmdline_user_args().has("--pause-on-start")`；入口在完成异步摆放、输出 `SCENARIO_READY` 并置 `entry_ready = true` 之后，复用生产暂停入口 `main.call("_set_paused", true)` 进入暂停，并额外打印 `SCENARIO_PAUSED`。恢复仍走生产路径：玩家按 Space 由 `main.gd` 的既有输入处理解除暂停。入口只做「摆放 + 按需暂停」，不复制暂停语义、不改数值。
- 变更文件：`tests/scenario_entry.gd`、`test/gameplay/human_round_record_test.gd`、`tests/README.md`、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 测试证据：单套件 `& <godot> --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/gameplay/human_round_record_test.gd -rd res://reports/gdunit/single --ignoreHeadlessMode` → `Statistics: 3 test cases | 0 errors | 0 failures | 0 flaky | 0 skipped | 0 orphans | PASSED 573ms`，其中 `test_pause_on_start_pauses_after_entry_is_ready` PASSED（断言 `get_tree().paused` 在 `entry_ready` 后为 true，并在 `_set_paused(false)` 后恢复 false），exit 0；统一门禁 `pwsh -File test/run_tests.ps1 -Layer all` → `RESULT: PASS`（GdUnit4 402 cases / 0 failures；headless 10 suites / 549 assertions / 0 failing），exit 0。
- 验证状态：验证通过（暂停时机、可恢复性与既有入口行为不变均由自动化覆盖；`--pause-on-start` 命令行路径未单独自动化，仍属人工轮现场项）
- 验证时间：2026-09-26T00:19:06+08:00
- 已知问题：① 暂停是 `get_tree().paused = true`，GdUnit 用例必须在断言后立即恢复，否则会挂住测试框架（用例内已处理）；② 暂停遮罩与提示文本沿用生产 HUD，本 Increment 不新增提示；③ 既有 orphan 债务（integration 288 / gameplay 324）与本次无关。
- 用户验收：已验收（用户 2026-09-26T02:09:20+08:00 原话「本次验收通过」）
- 验收时间：2026-09-26T02:09:20+08:00
- Git：develop / b5550ce
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 只补人工轮的可控开局，不改变战斗规则。

## INC-TESTING-016：测试入口聚焦 Build（隐藏非 Build 菜单）

- 状态：accepted
- 创建时间：2026-09-25T23:49:00+08:00
- 最后修改：2026-09-25T23:52:10+08:00
- 主题：testing
- 目标：`tests/` 下的 6 个入口都只验证 Build，但打开后会带出正式入口的完整 HUD——遭遇选择按钮、秘境面板、宗门面板与本次验收无关，既占用屏幕也增加误操作面。本 Increment 让测试入口默认隐藏这些非 Build 菜单，只保留 Gate 0 与人工轮需要的技能栏 / 信息卡 / Build 面板 / 战斗状态 / 「重新挑战」。
- 验收标准：
  - 6 个入口打开后：`HUD/BottomLeftDock/EncounterPanel/Buttons`（遭遇选择按钮）、`HUD/BottomLeftDock/DungeonPanel`（秘境）、`HUD/BottomLeftDock/SectPanel`（宗门）不可见。
  - 同时保留：`HUD/BuildLoadoutPanel`、`HUD/BottomLeftDock/SkillBar`、`HUD/BottomLeftDock/PawnInfoPanel`、`HUD/BottomLeftDock/EncounterPanel/RestartButton`（人工轮 Round 2 与 Gate 0「同一遭遇可重复挑战」的入口）仍可见。
  - 只改可见性，不删节点：`game/main/main.gd` 的 `@onready` 引用与既有 `main_scene_*` 集成测试不受影响；`game/` 下代码与数值零改动。
  - `test/tools/verify_scenario_entries.gd` 新增上述可见性断言，6 入口 × 2 次 `FAILURES=0`；统一门禁 `RESULT: PASS`。
- 范围：`tests/scenario_entry.gd`（新增 `hide_non_build_panels` 导出参数与隐藏逻辑）、`test/tools/verify_scenario_entries.gd`（可见性断言）、`tests/README.md`（记录呈现口径）、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 非范围：不改 `game/` 下任何节点 / 脚本 / 数值；不删除节点（`queue_free` 会让 `main.gd` 的 `@onready` 引用失效）；不改变 Build / 战斗 / 奖励规则；不代替人工 Gate A~E 结论。
- 依赖：`INC-TESTING-012`（`tests/` 入口架构）、`INC-TESTING-015`（人工轮可控开局，与本项同在人工轮开始前收敛呈现）、`INC-CROSS-019`。
- 检索证据（2026-09-25T23:49:00+08:00）：`git status --short --branch` 显示 `develop...origin/develop`，工作区含 `INC-TESTING-015` 未提交改动与若干非本 Increment 改动；`git grep -n "INC-TESTING-016" -- agent-plan/` 无命中（016 未被占用）；读取 `game/main/main.tscn` 与 `game/ui/encounter_panel.gd` / `game/ui/dungeon_panel.gd` / `game/ui/sect_panel.gd` 确认三处面板的节点路径，并确认「重新挑战」的既有语义是 `main.gd::_on_encounter_restart_requested()` → `encounter_session.restart()`。
- 风险：① 选择「隐藏」而不是「删除」是刻意的——删除会让 `main.gd` 的 `@onready var encounter_panel / dungeon_panel / sect_panel` 指向已释放节点，并破坏既有集成测试；② 若后续新增需要秘境 / 宗门 / 遭遇选择入口的非 Build 测试场景，把该场景的 `hide_non_build_panels` 设为 `false` 即可恢复完整 HUD。
- 实现说明：`tests/scenario_entry.gd` 新增 `NON_BUILD_UI_PATHS` 常量与 `hide_non_build_panels` 导出参数（默认 `true`）：入口把 `main.tscn` 实例加入树并等一帧后调用 `_hide_non_build_panels()`，对 `HUD/BottomLeftDock/EncounterPanel/Buttons`（换敌按钮）、`HUD/BottomLeftDock/DungeonPanel`、`HUD/BottomLeftDock/SectPanel` 只做 `visible = false`。刻意不 `queue_free`：`game/main/main.gd` 用 `@onready var encounter_panel / dungeon_panel / sect_panel` 持有这些节点，删除会让引用失效并破坏既有 `main_scene_*` 集成测试；隐藏也不改 `game/` 下任何代码与数值。`EncounterPanel` 只隐藏换敌按钮，保留 `TitleLabel`（当前遭遇）、`StatusLabel`（结算结果）与 `RestartButton`（重新挑战）——后者是 Gate 0「同一遭遇可重复挑战」与人工轮 Round 2 的入口。`test/tools/verify_scenario_entries.gd` 新增 `HIDDEN_IN_BUILD_ENTRY` / `VISIBLE_IN_BUILD_ENTRY` 两组路径与 `_check_build_focus()`，6 个入口每次加载都断言「非 Build 菜单隐藏 + Build 验收 UI 保留」。`tests/README.md` 新增「测试呈现」一节记录该口径与 `hide_non_build_panels = false` 的退出方式。
- 变更文件：`tests/scenario_entry.gd`、`test/tools/verify_scenario_entries.gd`、`tests/README.md`、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 测试证据：
  - 入口体检：`& <godot> --headless --path . --script res://test/tools/verify_scenario_entries.gd` → `SCENARIO_ENTRY_CHECK_DONE FAILURES=0`（6 入口 × 2 次），每个入口打印 `BUILD_FOCUS=<scene> HIDDEN=3 VISIBLE=4`；报告写入 `.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt`（不入库）。
  - 真实窗口可见控件核对：MCP `run_project(scene="tests/scenario_build_test_1v1.tscn", background=true)` + `get_ui_elements`，可见 Button 只有「重新挑战」与 Build A/B 的 `UseButton`；可见面板只有 HUD 标签 / `PawnInfoPanel` / `SkillBar` / `EncounterPanel` 的「当前遭遇：试剑·1v1」「进行中：试剑·1v1」/ `BuildLoadoutPanel`；没有换敌按钮、`DungeonPanel`（秘境）、`SectPanel`（宗门）控件。截图 `.mcp/godot-runtime/screenshots/screenshot_1790351508_059.png`（2560×1434，不入库）。
  - 统一门禁：`pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 402 cases / 0 failures：unit 161 + integration 174 + gameplay 67；headless 10 suites / 549 assertions / 0 failing suites），exit 0。层内仍打印既有 orphan 债务（integration 288 / gameplay 324），本次 errors / failures 均为 0。
- 验证状态：验证通过
- 验证时间：2026-09-25T23:52:10+08:00
- 已知问题：① 这只是测试入口的呈现收敛，正式入口 `game/main/main.tscn` 的完整 HUD 不变；② 换敌入口在 Build 验收入口里按设计不可见，若后续需要换敌做对照，另立 Increment 或把该场景的 `hide_non_build_panels` 设为 `false`；③ 既有 orphan 债务（integration 288 / gameplay 324）与本次无关；④ 提交前工作区还含 `INC-TESTING-015` 未提交改动与若干非本 Increment 改动（`AGENTS.md`、`project.godot`、`trial_dungeon.tres`、`build_decision_differentiation_test.gd`、部分 `tests/*.tscn` 的 UID 重存），需按验收结果分 Increment 处理。
- 用户验收：已验收（用户 2026-09-26T02:09:20+08:00 原话「本次验收通过」）
- 验收时间：2026-09-26T02:09:20+08:00
- Git：develop / b5550ce
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 只收敛测试入口的呈现，正式入口 `game/main/main.tscn` 的完整 HUD 不变。

## INC-TESTING-017：测试入口自证与敌我标识（横幅 + 名牌）

- 状态：accepted
- 创建时间：2026-09-26T00:10:56+08:00
- 最后修改：2026-09-26T00:19:06+08:00
- 主题：testing
- 目标：实机验收反馈「1v1 / 1v2 / 1v3 和旧的傀儡测试看起来完全一样，宗门等无关 UI 也没隐藏」。运行时复核确认主因是**运行入口错位**：按 F5 跑的是项目主场景 `main.tscn`，它默认进入 `DungeonRun.default_dungeon = trial_dungeon`（第一间即试炼傀儡）并保留完整 HUD；只有运行 `tests/scenario_*.tscn`（编辑器内按 F6 运行当前场景）才会走测试入口，由 `tests/scenario_entry.gd` 隐藏非 Build 菜单。其次确认一个客观原因：所有 Pawn 共用 `game/pawns/art/pawn_placeholder.svg` 且没有任何名称标识，1v1 / 1v2 / 1v3 在视觉上确实只差单位数量。本 Increment 让测试入口自证身份，并给敌我单位加运行时标识，使「跑错入口」一眼可辨、三档遭遇一眼可分。
- 验收标准：
  - 6 个入口运行时出现测试横幅：`[测试入口] tests/<文件>` + 场景标题 + 遭遇 `display_name` + 敌方名单与人数；跑 `main.tscn` 时不会出现该横幅。
  - 每个敌方 Pawn 头顶显示 `PawnData.display_name` 名牌并按名单配色；玩家 Pawn 头顶显示「玩家」；`EncounterSession.restart()` 后再战，名牌仍然存在。
  - 1v1 / 1v2 / 1v3 运行时可读出 1 / 2 / 3 个不同敌方名单：`["镇狱影傀"]` / `["赤拳战修", "灵弓修者"]` / `["赤拳战修", "灵弓修者", "镇狱影傀"]`。
  - `tests/run_scenario.ps1` 可按名字启动指定入口（含 `-PauseOnStart`）。
  - 非 Build 菜单仍隐藏；入口体检 `FAILURES=0`；统一门禁 `RESULT: PASS`。
- 范围：`tests/scenario_entry.gd`（横幅 / 名牌 / 配色 / 名单报告）、`test/tools/verify_scenario_entries.gd`（名单与横幅断言）、`tests/README.md`（运行方式与自证口径）、新增 `tests/run_scenario.ps1`（启动封装）、`agent-plan/testing.md`、`agent-plan/_index.md`。
- 非范围：不改 `game/` 下正式 HUD / Pawn 场景 / 数值；不新增美术资源（继续使用占位图，只在测试入口做运行时配色与名牌）；不改变 Build / 战斗 / 奖励规则；不代替人工 Gate A~E 结论。
- 依赖：`INC-TESTING-016`（测试入口 Build 聚焦）、`INC-TESTING-012`（`tests/` 入口架构）、`INC-CROSS-019`。
- 检索证据（2026-09-26T00:10:56+08:00）：`git grep -n "INC-TESTING-017" -- agent-plan/` 无命中（017 未被占用）。运行时复核：MCP `run_project()`（不传 scene，等价 F5）→ `encounter=encounter_trial_puppet`、`enemies=["试炼傀儡"]`、`EncounterPanel/Buttons` / `DungeonPanel` / `SectPanel` 全部 `visible=true`、窗口标题 `test1`；MCP `run_project(scene="tests/scenario_build_test_1v1.tscn")` → `get_ui_elements` 无换敌 / 秘境 / 宗门控件，窗口标题 `test1 · tests/build_test_1v1 · 1v1 战斗问题窗口`；读取 `game/pawns/pawn.tscn` 与 `game/world/data/encounters/build_test_1v*.tres` 确认三档遭遇数据确实不同（1 / 2 / 3 名敌人：镇狱影傀 / 赤拳战修 + 灵弓修者 / 再加镇狱影傀），但所有 Pawn 共用同一张占位图且无名字节点。
- 风险：① 名牌与横幅是 `tests/` 自建的运行时节点，必须挂在 `encounter_started` 上重建，否则 `restart()` 后新 Pawn 没有名牌；② 运行时配色只改 `Sprite2D.modulate`，不写场景文件，正式游戏视觉不变；③ `tests/run_scenario.ps1` 只做启动封装，不改任何规则。
- 实现说明：① 测试横幅：`tests/scenario_entry.gd` 新增 `_install_scenario_banner()`，在入口下挂 `CanvasLayer(layer = 20)` → `ScenarioBanner`（`PanelContainer`，`mouse_filter = IGNORE`，锚在右下角 Build 面板正上方，offsets `-312 / -304 / -16 / -208`）→ `BannerLabel`（`AUTOWRAP_WORD_SMART`，字号 13）；文本为 `[测试入口] tests/<场景文件>` + `scenario_title` + `遭遇：<display_name>（<encounter id>） · 敌方 N：<名单>`，结算后追加 `本局结果：<胜负>`；`_update_banner_text()` 在安装时、每次 `encounter_started` 与 `encounter_finished` 各刷新一次，因此重开后「本局结果」会被清掉。② 敌我标识：`_refresh_unit_markers()` 在每次 `encounter_started` 重建（重开会换掉整批 Pawn 实例），`_apply_unit_marker()` 只做两件事——把 `Visual/Sprite2D.modulate` 按名单顺序染色（玩家绿 `(0.55, 1.0, 0.72)`，敌人红 / 黄 / 紫 / 青四色），并在 Pawn 下挂 `Label(ScenarioNameplate)`（`position = (-80, -124)`、宽 160、字号 14、黑色描边 4），文案 `敌 · <display_name>` / `玩家 · <display_name>`。③ 可读名单：`get_scenario_report()` 增加 `enemy_names`。④ 健康检查抓到的真实缺陷：横幅最初只写 `display_name`（`试剑·1v1`），体检按 `encounter id` 断言直接 FAIL，据此把横幅改成 `display_name（encounter id）` 双写，体检才从 `FAILURES=3` 收敛到 0。⑤ 体检脚本按新口径重写并统一 TAB 缩进：`EXPECTED_ENTRIES` 每项增加 `enemy_names`（1v1 `["镇狱影傀"]` / 1v2 `["赤拳战修", "灵弓修者"]` / 1v3 `["赤拳战修", "灵弓修者", "镇狱影傀"]`），新增 `_check_self_identification()`（横幅存在且含场景文件名 / encounter id / 每个敌方名字；名牌数与名单一致，玩家名牌恰好 1 个）与 `_count_nameplates()`（`find_children(..., owned = false)`，运行时节点没有 owner），并在二次加载断言「敌方名单不变 + 名牌已重建」。⑥ `tests/run_scenario.ps1`（新增）：名字路由（`1v1 / 1v2 / 1v3 / switch / loadout / first-clear / replay` 或直接给文件名）+ `-List` + `-PauseOnStart` + `-Godot`（默认 `GODOT_BIN`），用法错误 exit 2，正常运行转交 Godot 退出码；路由只做场景定位，状态仍全部写在 `.tscn` 导出参数里。⑦ `tests/README.md`：新增顶部「先看这条」警示与「运行方式：认准 F6 / 启动脚本，不要用 F5」对照表（列出 F5 / F6 / 脚本 / MCP 四种启动方式实际跑的场景）、「测试自证」章节（横幅、名牌、`enemy_names`、三档名单表）与「新增入口要求」第 5 条（新入口必须补 `EXPECTED_ENTRIES`）。
- 变更文件：`tests/scenario_entry.gd`（横幅 / 名牌 / 配色 / `enemy_names`）、`test/tools/verify_scenario_entries.gd`（名单 + 横幅 + 名牌断言，缩进规范化）、`tests/README.md`（F5/F6 警示、自证口径、启动脚本用法）、新增 `tests/run_scenario.ps1`、`agent-plan/testing.md`、`agent-plan/_index.md`。不改 `game/` 与任何数值。
- 测试证据：① 入口体检 `& <godot> --headless --path . --script res://test/tools/verify_scenario_entries.gd` → `SCENARIO_ENTRY_CHECK_DONE FAILURES=0`，exit 0；报告 `.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt` 逐项给出 `SELF_ID=... BANNER=... ENEMY_PLATES=1/2/3 PLAYER_PLATES=1` 与 `REPEAT_ENTRY=... PLATES=1/2/3`（重开重建名牌）。② 真实窗口（MCP `run_project(scene=...)`，2.214× stretch 缩放）：`tests/scenario_build_test_1v2.tscn` → 横幅 `[测试入口] tests/scenario_build_test_1v2.tscn / 1v2 双目标取舍 / 遭遇：试剑·1v2（build_test_1v2） · 敌方 2：赤拳战修 / 灵弓修者`，名牌 `玩家 · 测试修士` + `敌 · 赤拳战修` + `敌 · 灵弓修者`，可见性 `EncounterPanel/Buttons = hidden`、`DungeonPanel = hidden`、`SectPanel = hidden`、`BuildLoadoutPanel = VISIBLE`、`RestartButton = VISIBLE`，窗口标题 `test1 · tests/build_test_1v2 · 1v2 双目标取舍`；`tests/scenario_build_test_1v3.tscn` → 横幅 `试剑·1v3（build_test_1v3） · 敌方 3：赤拳战修 / 灵弓修者 / 镇狱影傀` + 3 个敌方名牌（三色）+ 1 个玩家名牌。③ 重开路径：真实点击「重新挑战」后 `EncounterSession._state` 由 3（结算）回到 1（进行中），横幅去掉「本局结果」行，名牌数量与文案不变（证明按 `encounter_started` 重建）。④ 反向对照（本次实机反馈的根因）：MCP `run_project()` 不传 scene（等价按 F5）→ 场景 `res://game/main/main.tscn`、遭遇 `encounter_trial_puppet` / `试炼傀儡`、`banner_layers_found = 0`、`nameplates_found = 0`、`SectPanel / DungeonPanel / EncounterPanel/Buttons` 全为 `VISIBLE`、窗口标题 `test1`——与用户描述完全一致，确认「看起来和旧傀儡测试一样且没隐藏宗门 UI」= 跑的是项目主场景而不是测试入口。⑤ 启动脚本：`pwsh -File tests/run_scenario.ps1 -List` exit 0；`-Scenario 1v2` / `-Scenario replay -PauseOnStart` / `-Scenario first_clear_reward.tscn` 经桩程序核对实参分别为 `--path <repo> res://tests/scenario_build_test_1v2.tscn`、`... scenario_build_replay.tscn -- --pause-on-start`、`... scenario_first_clear_reward.tscn`；未知名与缺 `-Godot` 均 exit 2 并打印可用入口。⑥ 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 402 cases / 0 failures；headless 10 suites / 549 assertions / 0 failing suites），exit 0；另单跑 `test/gameplay/human_round_record_test.gd` → `3 test cases | 0 errors | 0 failures | 0 orphans`。
- 验证状态：验证通过（横幅 / 名牌 / 名单三条自证链路均有自动化断言与真实窗口读数；F5 反向对照证明根因；启动脚本路由经桩程序核对；统一门禁 PASS）
- 验证时间：2026-09-26T00:19:06+08:00
- 已知问题：① F5 仍然跑 `game/main/main.tscn`（默认试炼傀儡秘境 + 完整 HUD），本轮只做到「跑错时屏幕上没有横幅、跑对时一定有」，没有改正式入口；要彻底消除误跑需要用户决定是否更换项目主场景或加启动提示，属独立 Increment。② 横幅与名牌都是运行时节点，编辑器里三个入口场景本身仍是「空 `Node2D` + 导出参数」，差异只在导出参数与运行时表现，静态看 `.tscn` 看不出区别是设计使然。③ 点「重新挑战」后选中态被清空，信息卡 / 技能栏会隐藏，需要玩家再点一次自己的 Pawn 才恢复读数（沿用正式入口既有行为，不在本 Increment 范围；名牌不受影响，快捷键仍可用）。④ 本次实测发现 MCP `click_element` 在当前 stretch 缩放下按画布坐标点击会落空，需用 `get_screen_position()` 换算成窗口像素（画布 1156×648 → 窗口 2560×1434，缩放 ≈2.214）；这是 MCP 桥接的坐标口径问题，与游戏侧无关，已记入本卡以免下次误判。⑤ 测试报告器对 stderr 的日志轮转提示会打出 `[GdUnit4] <层> ... FAIL (N cases, 0 errors, 0 failures)` 这类噪声行，以最终 `RESULT: PASS` 与 0 failures 为准。⑥ 既有 orphan 债务（integration 288 / gameplay 324）与本次无关。
- 用户验收：已验收（用户 2026-09-26T02:09:20+08:00 原话「本次验收通过」）
- 验收时间：2026-09-26T02:09:20+08:00
- Git：develop / b5550ce
- 备注：父 Increment 为 `INC-CROSS-019`；本 Increment 解决「看不出跑的是哪个入口」与「三档遭遇在占位图下不可分辨」，属于验收可用性修复；`INC-TESTING-016` 的隐藏机制本身已在运行时复核通过。

## INC-TESTING-018：输入模型测试矩阵（左键移动 / 敌方选中 / 右键不移动）

- 状态：accepted
- 创建时间：2026-09-26T00:45:00+08:00
- 最后修改：2026-09-26T01:48:20+08:00
- 主题：testing
- 目标：把新的鼠标操作模型锁进自动化测试，防止回退成「右键移动」或「点敌方无反应」。
- 验收标准：
  - gameplay 套件覆盖：左键点己方单位 → 选中该单位；左键点空白地 → `指令：移动到 (…)`；左键点敌方单位 → `PawnInfoPanel` 绑定该敌方且 `SkillBar` 解绑。
  - gameplay 套件覆盖：非 TARGETING 右键点空白地不产生移动命令；右键点敌方单位仍然下达 `攻击 <display_name>`（保留 `INC-COMBAT-001` 的普通攻击能力）。
  - gameplay 套件覆盖：TARGETING 期间右键仍然只取消瞄准，不产生移动 / 攻击副作用。
  - 统一门禁 `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` 为 `RESULT: PASS`，新增用例计入 cases 总数且 `0 failures`。
- 范围：`test/gameplay/main_scene_skill_targeting_test.gd`（鼠标路由用例改写与新增）、必要时 `test/gameplay/main_scene_gameplay_test.gd` 的既有断言同步。
- 非范围：新增测试框架或层级、真实窗口取证脚本改造、`test/tools/**` 重构、既有 orphan 测试债务清理（gameplay 324 / integration 288）、`tests/` 场景入口改动。
- 依赖：`INC-CORE-013`（新的输入路由）、`INC-UI-019`（敌方选中后的 UI 口径）、`INC-TESTING-001`（GdUnit4 三层门禁）、`INC-TESTING-012`（`test/` 与 `tests/` 的职责边界）。
- 检索证据：2026-09-26T00:42+08:00 执行 `git status --short` 与编号占用检索（`INC-TESTING-018` 无命中）；`git grep -n "MOUSE_BUTTON_LEFT|MOUSE_BUTTON_RIGHT" -- test/ tests/` 定位到鼠标输入只集中在 `test/gameplay/main_scene_skill_targeting_test.gd`；`git grep -n "移动到" -- test/` 命中唯一旧契约断言 `main_scene_skill_targeting_test.gd:188`，即本次必须改写的用例。
- 风险：① 旧用例 `test_right_click_cancels_without_move_command` 直接断言右键移动的旧行为，属于必须改写的契约变更而不是回归；② 若把「左键点敌方」写成同时下达攻击命令，会与「点敌方只看信息」冲突，用例必须显式证明没有命令副作用；③ 左键移动的断言依赖 `PlayerController.get_order_description()` 文案，改文案会连带失败。
- 实现说明：
  - 旧契约用例 `test_right_click_cancels_without_move_command` 整体改写为 `test_right_click_cancels_targeting_and_never_orders_move`：先证明 TARGETING 期间右键只取消，再显式断言非 TARGETING 右键点地面 `order_label` 与取消前完全一致且不含 `移动到`。
  - 新增 `test_left_click_friendly_pawn_selects_player`、`test_left_click_ground_orders_move_for_selected_player`、`test_left_click_enemy_selects_it_and_binds_enemy_info_ui`、`test_right_click_enemy_keeps_attack_order` 四个用例，全部走真实 `main.tscn` + 真实 `PlayerController`，不复制敌我 / 目标合法性规则；鼠标事件用既有 `_send_mouse_button()` 直接投给 `_unhandled_input`，坐标用 `main.get_canvas_transform() * world` 换算。
  - 新增常量 `SELECTED_LABEL_PATH`、`BUILD_PANEL_PATH` 复用主场景既有节点路径；用例里「不产生命令」用 `PlayerController.get_order_description()` 前后比对判定，而不是只看 HUD 文案。
- 变更文件：
  - `test/gameplay/main_scene_skill_targeting_test.gd`（新增 2 个节点路径常量；替换 1 个旧用例并新增 4 个用例）
- 测试证据：
  - `pwsh -File test/run_tests.ps1 -Godot <godot> -Layer all` → `RESULT: PASS`（GdUnit4 406 cases / 0 failures、headless 10 suites / 549 assertions / 0 failing suites，exit 0；改动前 402 cases，本次净增 4 个用例）
  - 用例数变化核对：改动前 402 → 现在 406（删除 1 个断言旧契约的 `test_right_click_cancels_without_move_command`、新增 5 个用例：左键点己方 / 左键点地面 / 左键点敌方 / 右键不移动 / 右键攻击），门禁以 406 cases、0 failures / 0 errors 为准。
  - 真实窗口冒烟（`tests/scenario_build_test_1v2.tscn`，MCP `run_project` background 模式，2560x1434窗口 / 1156x648 画布）：冻结控制器后逐个点击复核——左键点己方 → `PawnInfoPanel` 绑定玩家 + 技能栏绑定可见 + `指令：待命`；左键点空白地 → `指令：移动到 (320, 520)`；左键点敌方 `赤拳战修` → 信息卡绑定该敌方且 `visible=true`、技能栏解绑且 `visible=false`、Build 面板解绑（按钮 disabled / `未绑定单位`）、`SelectedLabel` = `赤拳战修 / 阵营：enemy / HP：200 / 200 护盾：20 / 20 / 状态：待命`、`OrderLabel` = `指令：-`、控制器指令描述不变（零命令副作用）、敌方 `SelectionIndicator.visible=true` 而玩家为 false；左键点第二名敌人 `灵弓修者` → 信息卡跟随新目标；右键点空白地 → 指令仍为 `移动到 (320, 520)`（不产生新移动命令）；右键点敌方 → `指令：攻击 赤拳战修`（普通攻击入口保留）
  - 真实 OS 级鼠标输入（MCP `simulate_input`，窗口像素坐标）：左键点敌方 (788,589) → `Main._selected_pawn` = `EnemyPawn`；左键点己方 (1926,907) → `PlayerPawn`；左键点空白地 (708,1151) → `指令：移动到 (320, 520)`；右键点另一处空白地 (1550,332) → 指令仍是 `移动到 (320, 520)`（未下达新移动命令）；右键点敌方 → `指令：攻击 赤拳战修`
  - 说明：真实窗口冒烟里第一局是在 AI 活跃状态下被打到玩家阵亡后才检查的，因此复核改用 `session.restart()` + `set_physics_process(false)` 的冻结条件重做，避免把「玩家已阵亡」误读为路由缺陷。
- 验证状态：验证通过
- 验证时间：2026-09-26T00:57:00+08:00
- 已知问题：
  - 本套件只覆盖鼠标输入路由，未覆盖手柄 / 键位重绑定（项目当前无手柄输入映射）。
  - 既有 orphan 债务未清理（gameplay 324 / integration 288），统一门禁里 `integration` / `gameplay` 行的 `FAIL` 标签为既有 stderr 噪音（同行为 `0 errors | 0 failures`）。
  - 真实窗口点击取证脚本未新增；本次取证用的是 MCP `simulate_input` + `run_script` 的组合，尚未沉淀为可重跑的 `test/tools/**` 脚本。
- 用户验收：已验收
- 验收时间：2026-09-26T01:48:20+08:00
- Git：develop / `3955517`
- 备注：父 Increment 为 `INC-CROSS-020`；本 Increment 只改测试与断言，不改生产代码，也不修改既有 orphan 债务。

## INC-TESTING-019：Skill × Enemy 交互矩阵（同一 Build 面对不同问题）

- 状态：planned
- 创建时间：2026-09-26T01:56:11+08:00
- 最后修改：2026-09-26T01:56:11+08:00
- 主题：testing
- 目标：把「技能池变大之后 Build 玩法是否真的成立」变成可复核的客观证据——用同一 Build 跑不同问题型敌人，比较通关耗时 / 灵力消耗 / 剩余生命，证明「不同敌人让不同技能的价值发生变化」，而不是「面板伤害高的技能永远更优」。
- 验收标准：
  - 建立技能 × 敌人的交互矩阵用例：对每一类问题型敌人，至少记录「适用技能」与「不适用技能」各一组客观量（通关耗时 / 剩余生命 / 灵力消耗）。
  - 出现至少 2 组「换技能后差异可复现」的证据（同一敌人、同一初始状态，仅替换一个技能，客观量差异超出噪声）。
  - 反向对照成立：若两个技能只差数值（同为单体伤害、倍率高低），其客观量差异不构成「Build 差异」，用例必须显式区分「数值升级」与「Build 变化」。
  - 用例不依赖人工操作，可在统一门禁里重复运行；人工轮（`INC-TESTING-014` / `INC-TESTING-015` 的入口）只用于开放式提问，不承担客观对照。
  - 统一门禁 `test/run_tests.ps1 -Layer all` → `RESULT: PASS`。
- 范围：`test/gameplay/` 或 `test/integration/` 下新增交互矩阵用例、必要的确定性驱动脚本（沿用 `test/tools/build_replay_driver.gd` 的模式）、`tests/README.md`。
- 非范围：替代人工验收结论、平衡性定稿、随机化压力测试、存档 / 联网测试、Boss 分阶段测试。
- 依赖：`INC-COMBAT-010`（新效果类型）、`INC-PAWNS-022`（技能池与槽位）、`INC-COMBAT-011`（问题型敌人）、`INC-WORLD-008`（问题房间），以及既有的 `INC-TESTING-011`（Build Replay 记录）与 `INC-CROSS-019` 的客观对照判据。
- 检索证据：2026-09-26T01:56+08:00 `git grep` 确认 `INC-TESTING` 已用至 018；现有 `test/unit/tactical_skill_catalog_test.gd` 与 `test/gameplay/build_decision_differentiation_test.gd` 已经做过「技能价值轴」的标称对照，但对照对象是数据字段而不是运行时不同敌人，且只有 3 个技能；`test/tools/build_replay_driver.gd` 提供了可复用的确定性驱动先例。
- 风险：① 运行时对照容易受 AI 时序与帧率影响，必须冻结控制器或使用确定性驱动，否则结论不可比；② 「客观量差异」需要先定噪声阈值，否则会把随机波动当成 Build 差异；③ 本项跨越 4 个前置 Increment，任一前项未落地时不能提前给出结论。
- 实现说明：
- 变更文件：
- 测试证据：
- 验证状态：未验证
- 验证时间：
- 已知问题：
- 用户验收：未验收
- 验收时间：
- Git：待提交
- 备注：父 Increment 为 `INC-CROSS-021`；本项只产出客观对照证据，玩家是否「自然形成 Build」仍由人工轮与实际试玩回答。
