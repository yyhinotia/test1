# tests/ 场景化测试入口

> 规则来源：`../AGENTS.md` §5.1 / §12.6（场景化测试入口统一放在 `tests/`）
> 父 Increment：`INC-CROSS-019`（Build 玩法验证），由 `INC-TESTING-012` 建立

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

每个入口都会把窗口标题写成 `test1 · tests/<场景 id> · <场景名>`，人工记录时可以直接对照标题确认自己跑的是哪个入口。

## 运行方式

命令行（把 `$env:GODOT_BIN` 指向本机 Godot 4.7.x 可执行文件，仓库内不记录绝对路径）：

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

## 新增入口的要求

1. 新增一个场景就新增一个 `tests/scenario_<场景>.tscn`，导出参数写在场景里（不要新增一份入口脚本）。
2. 只允许引用 `game/` 下已有的正式资源；需要新数据时先改 `game/` 并在对应主题的 `agent-plan/<主题>.md` 里立 Increment。
3. 入口必须可重复打开、可重复挑战：不重复解锁技能、不残留上一局的活动单位。
4. 同步更新本 README 的入口清单，并在 `test/README.md` 保持交叉引用。
