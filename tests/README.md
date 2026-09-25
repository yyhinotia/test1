# tests/ 场景化测试入口

> 规则来源：`../AGENTS.md` §5.1 / §12.6（场景化测试入口统一放在 `tests/`）
> 父 Increment：`INC-CROSS-019`（Build 玩法验证），由 `INC-TESTING-012` 建立
>
> **先看这条**：编辑器按 F5 跑的是项目主场景 `game/main/main.tscn`（默认进入试炼傀儡秘境 + 完整 HUD），
> 看起来会和旧的傀儡测试一模一样——那不是测试入口。测试入口必须运行 `tests/scenario_*.tscn`：
> 编辑器内按 **F6** 运行当前场景，或用 `tests/run_scenario.ps1`（见下）。
> 跑对时屏幕右下角一定有测试横幅，跑错时一定没有。

## 这个目录是什么

`tests/` 放**可交互的测试场景入口**：每个入口把游戏摆到一个确定的状态（哪一场遭遇、前置条件是什么），
然后由人来操作并观察结果。它不做断言，也不产出通过 / 失败结论。

```text
tests/      场景化测试入口：点开就能跑一个确定的场景   ← 本目录
test/       自动化断言：unit / integration / gameplay + headless 回归
```

职责边界（两边都不要越界）：

- 断言、统计、CI 门禁一律写在 `test/`（GdUnit4 或 headless 套件），不得写进 `tests/`。
- 测试专用节点、专用参数与专用资源引用一律放在 `tests/` 场景或 `tests/*.gd` 里；
  `game/main/main.tscn` 只保留正式游戏入口职责，不得为测试内嵌专用引用。
- 测试入口**只做状态摆放**：不复制战斗 / 奖励 / Build 规则，规则仍然只在 `game/` 下。
- 需要人工判断的结论（例如「玩家是否愿意重构 Build」）只能由人给出，自动化与入口脚本都不得代替。

## 入口清单

| 入口 | 场景 | 前置条件 | 要观察什么 |
|---|---|---|---|
| `tests/scenario_build_test_1v1.tscn` | 1v1 镇狱影傀 | Build A（御剑斩 + 护体真气） | 每 8 秒的危险窗口无法被打断，只能硬吃——这是「第一轮的战斗问题」 |
| `tests/scenario_build_test_1v2.tscn` | 1v2（赤拳战修 + 灵弓修者） | 定身术已解锁（未装配） | 双目标取舍：先杀谁、定身谁 |
| `tests/scenario_build_test_1v3.tscn` | 1v3（近战 + 远程 + 同一个镇狱影傀 Boss） | 定身术已解锁（未装配） | 危险窗口仍在，同时多了必须先取舍的两个威胁 |
| `tests/scenario_build_loadout_switch.tscn` | 1v1 与 Build 切换面板 | 定身术已解锁（未装配） | 右下角面板：Build A「当前 Build」、Build B「可切换」；必须玩家主动点击才切换 |
| `tests/scenario_first_clear_reward.tscn` | 1v1 首通奖励 | 未解锁定身术 | 打完这一场后奖励只有定身术，面板从「未解锁：定身术」变成「可切换」（不自动装配） |
| `tests/scenario_build_replay.tscn` | Build Replay 实验（1v1 全流程） | 未解锁定身术 | `INC-TESTING-011` 的人工剧本：① Build A 打完 → ② 首通只拿定身术 → ③ 自己决定是否换 Build → ④ 再战同一遭遇；三问原话与 Gate 结论填进 `build_replay_record` |

每个入口都会把窗口标题写成 `test1 · tests/<场景 id> · <场景名>`，人工记录时可以直接对照标题确认自己跑的是哪个入口。

## 测试呈现：只保留 Build 验收相关 UI

6 个入口都只验证 Build，因此 `tests/scenario_entry.gd` 默认把与 Build 无关的正式 HUD 菜单隐藏起来：

- 隐藏：遭遇选择按钮（`EncounterPanel/Buttons`）、秘境面板（`DungeonPanel`）、宗门面板（`SectPanel`）。
- 保留：Build 切换面板、技能栏、单位信息卡、当前遭遇与结算状态、**「重新挑战」**（人工轮 Round 2 与 Gate 0「同一遭遇可重复挑战」的入口）、暂停遮罩。

隐藏只改可见性，不删除节点，也不改 `game/` 下任何实现；需要完整 HUD 的非 Build 测试场景，在自己的 `.tscn` 里把 `hide_non_build_panels` 设为 `false`。

## 测试自证：怎么确认自己跑对了（INC-TESTING-017）

三档 1v1 / 1v2 / 1v3 共用同一张占位图（`game/pawns/art/pawn_placeholder.svg`），
光看「屏幕上有几个小人」很容易怀疑自己跑的是不是同一个场景，因此入口在运行时自证三件事：

1. **测试横幅**（右下角 Build 面板正上方，节点 `ScenarioBannerLayer/ScenarioBanner/BannerLabel`）：
   `[测试入口] tests/<文件>` + 场景标题 + `遭遇：<display_name>（<encounter id>）· 敌方 N：<名单>`，
   结算后追加 `本局结果：<胜负>`。**跑 `main.tscn` 时不会出现这条横幅**，这是「跑对 / 跑错」最快的判据。
2. **敌我名牌与配色**（`ScenarioNameplate`，挂在每个 Pawn 上）：玩家为 `玩家 · <display_name>`（绿），
   敌人为 `敌 · <display_name>`，按名单顺序取色（红 / 黄 / 紫 / 青）。名牌在每次开局后重建，
   按「重新挑战」重开后仍然存在。
3. **可读的敌方名单**（`get_scenario_report()["enemy_names"]`）：人工与自动化读同一个字段，不用靠数人头。

三档遭遇的名单（`test/tools/verify_scenario_entries.gd` 逐项断言，含横幅与名牌）：

| 入口 | encounter id | display_name | 敌方名单 |
|---|---|---|---|
| `tests/scenario_build_test_1v1.tscn` | `build_test_1v1` | 试剑·1v1 | 镇狱影傀 |
| `tests/scenario_build_test_1v2.tscn` | `build_test_1v2` | 试剑·1v2 | 赤拳战修 / 灵弓修者 |
| `tests/scenario_build_test_1v3.tscn` | `build_test_1v3` | 试剑·1v3 | 赤拳战修 / 灵弓修者 / 镇狱影傀（与 1v1 同一个 Boss） |

名牌与配色只存在于 `tests/` 的运行时实例上，不写进 `.tscn`，也不改 `game/` 下的正式表现。

## 运行方式：认准 F6 / 启动脚本，不要用 F5

| 启动方式 | 实际跑起来的场景 | 结果 |
|---|---|---|
| 编辑器按 **F5**（运行项目） | `game/main/main.tscn` | ❌ 不是测试入口：默认进试炼傀儡秘境，带完整 HUD（换敌 / 秘境 / 宗门菜单都在） |
| 编辑器按 **F6**（运行当前场景） | 当前打开的 `tests/scenario_*.tscn` | ✅ 走 `tests/scenario_entry.gd`：隐藏非 Build 菜单、显示测试横幅 |
| `tests/run_scenario.ps1 -Scenario <名字>` | 指定的 `tests/scenario_*.tscn` | ✅ 同上，且不必在编辑器里切场景 |
| MCP `run_project(scene="tests/scenario_*.tscn")` | 指定的 `tests/scenario_*.tscn` | ✅ 同上 |

推荐用启动脚本（按名字定位入口，顺带避免跑错场景）：

```powershell
pwsh -File tests/run_scenario.ps1 -List                                              # 看有哪些入口
pwsh -File tests/run_scenario.ps1 -Scenario 1v2 -Godot $env:GODOT_BIN                # 简写：1v1 / 1v2 / 1v3 / switch / first-clear / replay
pwsh -File tests/run_scenario.ps1 -Scenario replay -PauseOnStart -Godot $env:GODOT_BIN
```

直接调 Godot（把 `$env:GODOT_BIN` 指向本机 Godot 4.7.x 可执行文件，仓库内不记录绝对路径）：

```powershell
# 单个入口
& $env:GODOT_BIN --path . res://tests/scenario_build_test_1v1.tscn

# 换一个场景就换一个入口，互不影响
& $env:GODOT_BIN --path . res://tests/scenario_build_loadout_switch.tscn
```

MCP（Godot MCP 工具）：

```text
run_project(projectPath="<仓库根>", scene="tests/scenario_build_test_1v1.tscn")
```

自动化体检（一次性加载全部入口并核对前置条件，不产出玩法结论）：

```powershell
& $env:GODOT_BIN --path . --script res://test/tools/verify_scenario_entries.gd
```

报告写入 `.mcp/godot-runtime/screenshots/tests_scenario_entries_report.txt`（该目录不入库）。

Build Replay 实验（`INC-TESTING-011`）的机制事实与记录骨架由取证脚本生成：

```powershell
& $env:GODOT_BIN --path . --script res://test/tools/capture_build_replay_record.gd
```

产出 `.mcp/godot-runtime/screenshots/build_replay_record.md` / `.json`（不入库，需重跑脚本再生成）。
脚本只填「机制事实」（Round 1 / Round 2 的事件序列、结算方式、承伤与时长），三问原话与 Gate A~E 必须由玩家填写。

Build Replay 人工轮（`INC-TESTING-014`）在 `tests/scenario_build_replay.tscn` 上开启只读事件记录：
每局结算（`encounter_finished`）会自动追加一段到 `.mcp/godot-runtime/screenshots/human_replay_events.md`，
内容包括局号、遭遇 id、结算结果、事件时钟、事件数量、玩家残余生命 / 护盾、已掌握 / 已装配技能与完整事件行。
记录器只写事实；Q1~Q4 原话、Gate A~E 与 Failure 1~5 结论仍然只能由人工填写。该记录文件同样不入库，需重跑入口重建。

人工轮建议使用可控开局，避免玩家未就绪时第一局被实时消耗：

```powershell
& $env:GODOT_BIN --path . res://tests/scenario_build_replay.tscn -- --pause-on-start
```

入口完成 `SCENARIO_READY` 后进入暂停，HUD 显示「游戏已暂停」；按 Space 后才开始实时战斗。

## 新增入口的要求

1. 新增一个场景就新增一个 `tests/scenario_<场景>.tscn`，导出参数写在场景里（不要新增一份入口脚本）。
2. 只允许引用 `game/` 下已有的正式资源；需要新数据时先改 `game/` 并在对应主题的 `agent-plan/<主题>.md` 里立 Increment。
3. 入口必须可重复打开、可重复挑战：不重复解锁技能、不残留上一局的活动单位。
4. 同步更新本 README 的入口清单，并在 `test/README.md` 保持交叉引用。
5. 同步在 `test/tools/verify_scenario_entries.gd` 的 `EXPECTED_ENTRIES` 里补一条（含 `enemy_names`），
   否则新入口不在体检范围内，横幅 / 名牌也不会被断言保护。
