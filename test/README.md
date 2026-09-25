# test1 自动化测试

> 框架：GdUnit4 `v6.2.1`（`addons/gdUnit4/`，MIT License，© 2023 Mike Schulze）+ 自建 headless 断言脚本
> 统一入口：`test/run_tests.ps1`
> 规则来源：`../AGENTS.md` §6 / §12.4 / §12.6

## 目录约定

| 目录 | 层级 | 职责 | 运行方式 |
|---|---|---|---|
| `test/unit` | 单元 | 纯逻辑：单个类或资源的算术、边界与信号契约。不加载场景，不依赖节点树。 | GdUnit4 |
| `test/integration` | 集成 | 系统组合：Pawn、资源池、状态条等 2~3 个组件之间的真实信号链路。 | GdUnit4 |
| `test/gameplay` | 玩法 | 场景层：在真实 `main.tscn` 上跑通玩家可见的整条链路（选中 → 受伤 → HUD 与头顶资源条同步 → 死亡）。 | GdUnit4 |
| `test/headless` | 回归 | 自建 headless 断言套件（`extends SceneTree`），逐条 CHECK 的回归基线。 | `--script` 直跑 |
| `test/tools` | 工具 | 不参与测试发现的证据脚本，例如真实窗口多分辨率截图与报告生成；`build_replay_driver.gd` 是 Build Replay 的共用驱动层（用例与取证脚本都调它）。 | 手动 |
| `../tests` | 场景入口 | 可交互的测试场景（每个场景一个 `.tscn`）：只负责把游戏摆到确定状态，不做断言、不产出通过结论。 | Godot 直接打开，见 `../tests/README.md` |
| `reports/` | 产物 | GdUnit4 生成的 JUnit XML 与 HTML 报告。**可重建、不入库**（已在 `.gitignore` 忽略）。 | 自动生成 |

分层原则：**能在单元层验证的，不要放到集成层；能在集成层验证的，不要放到玩法层。** 越靠下的层越快、越稳定，失败原因也越好定位。

## 命名规则

- GdUnit4 用例：`test/<层>/<被测主题>_test.gd`，例如 `test/unit/resource_pool_math_test.gd`。
- 文件首行必须是 `extends GdUnitTestSuite`，类名与文件名保持一致。
- 测试方法必须用 `test_` 前缀并返回 `void`；Godot 只发现这类方法。
- headless 套件：`test/headless/<主题>_test.gd`，`extends SceneTree`，必须按 `CHECKS=<n> FAILURES=<n>` 格式打印汇总，runner 依赖该格式解析结果。
- 一个文件只测一个主题；方法名描述**行为**而不是实现，例如 `test_depleted_and_restored_emit_once_per_transition`。

## 运行方式

统一入口需要一个 Godot 可执行文件，通过参数或环境变量提供（仓库内不记录本机绝对路径，见 `AGENTS.md` §8）：

```powershell
# 全量：三层 GdUnit4 + 全部 headless 套件
pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN

# 只跑某一层
pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer unit

# 只跑既有 headless 回归
pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer headless
```

`-Layer` 取值：`all`（默认）、`unit`、`integration`、`gameplay`、`headless`。

退出码：**0 = 全部通过；1 = 存在失败用例或失败套件；2 = 参数或环境错误**（未提供 Godot、路径不存在、未选择层级）。可直接用于 CI 或提交前门禁。

### 底层调用

排查 runner 自身问题时，需要知道它实际执行的命令：

```powershell
# GdUnit4 单个层级（integration / gameplay 同理）
<godot> --headless --path . -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd `
        -a res://test/unit -rd res://reports/gdunit/unit --ignoreHeadlessMode

# 单个 headless 套件
<godot> --headless --path . --script res://test/headless/spirit_pool_test.gd
```

GdUnit4 的参数必须**原生传递**，不能放在 `--` 之后；`--ignoreHeadlessMode` 不可省略，否则 GdUnit4 会因检测到 headless 模式而拒绝执行。GdUnit4 自身的退出码约定是 **0 = 通过、100 = 存在失败**，runner 会把两者归一化为 0/1。

## 新增一个测试

1. 确认已有对应 Increment（`AGENTS.md` §1.2：No Increment, No Code）。
2. 按被测对象选层，按上面的命名规则新建 `test/<层>/<主题>_test.gd`。
3. 用 GdUnit4 断言 API 写用例：

```gdscript
extends GdUnitTestSuite

const APPROX: float = 0.001


func test_configure_applies_initial_ratio() -> void:
	var pool: ResourcePoolComponent = ResourcePoolComponent.new()
	auto_free(pool)

	pool.configure(definition)

	assert_float(pool.current_value).is_equal_approx(60.0, APPROX)
	assert_int(pool.max_value).is_equal(120)
```

4. 跑 `pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer <你的层>`，全绿后再扩大范围。
5. 把执行命令、退出码与关键输出摘录进对应 Increment 的“测试证据”。

本仓库实测可用的断言与辅助方法：`assert_int` / `assert_float` / `assert_str` / `assert_bool` / `assert_array` / `assert_object` / `assert_that`；浮点用 `is_equal_approx(期望值, 容差)`（**容差参数不能省**）；数组用 `has_size` / `contains` / `contains_exactly` / `is_empty`；字符串用 `contains` / `is_equal` / `has_length`；套件辅助方法有 `auto_free`、`add_child`、`await_idle_frame`、`await_millis`、`before_test`、`after_test`。

## 与 `tests/` 的分工

- `test/`（本目录）：自动化断言与回归门禁，结论是「通过 / 失败」，用于提交前门禁。
- `tests/`：可交互的测试场景入口（每个场景一个 `.tscn`），结论由人工给出，用于玩法验收与手工复现。
- 两边都不放彼此的产物：断言脚本不写进 `tests/`，场景入口与测试专用参数也不写进 `test/` 或 `game/main/main.tscn`。
- 入口清单与运行方式见 `../tests/README.md`。
## 已知陷阱

- **GDScript lambda 按值捕获基本类型。** 在信号回调里对 `int` / `float` 这类局部变量自增不会影响外部变量，计数会永远是 0；要改成往 `Array`（引用类型）里 `append`。本仓库早期用例踩过这个坑。
- **暂停 SceneTree 会挂住 GdUnit4 的 awaiter。** `get_tree().paused = true` 之后不能再 `await`，否则用例直接死锁；暂停相关用例要写成同步断言，并在 `after_test()` 里恢复 `paused = false` 兜底。
- **GdUnit4 的控制台输出带 ANSI 颜色转义**，直接对原始输出做正则解析会匹配失败，必须先剥离转义序列（`run_tests.ps1` 已处理）。
- **`--headless` 的 dummy 窗口固定为 64x64**，逻辑视口会退化成方形；多分辨率 UI 验证必须走真实窗口（见 `test/tools/`），不能只靠 headless 断言。

## 相关文档

- 框架选型与取舍依据：`agent-plan/testing.md`（`INC-TESTING-001`）
- 测试与验证的强制要求：`AGENTS.md` §6
- 第三方插件审计要求：`AGENTS.md` §12.4
- 场景化测试入口（人工验收用）：`../tests/README.md`
- 各主题的验收标准：`agent-plan/<主题>.md`

