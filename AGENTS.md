# AGENTS.md — test1 Godot 项目开发约束

> 适用范围：本仓库根目录（Godot 项目 test1）及其全部子目录  
> 项目定位：修仙 RPG + 宗门经营 + 秘境探索 + 暂停式实时战术战斗  
> 设计源：`docs/project_summary.md`  
> 引擎版本：Godot `4.7.2.stable`  
> 文档最后修改：`2026-09-25T21:14:43+08:00`

## 0. 指令优先级

发生冲突时按以下顺序执行：

1. 用户当前回合的明确指令。
2. 本文件。
3. `docs/project_summary.md` 中的设计约束。
4. 上层目录或全局 `AGENTS.md`。
5. 通用 Godot/GDScript 最佳实践。

如果用户的要求会破坏本文件中的强制流程，必须先指出冲突，并在获得用户明确确认后再执行。

---

### 0.1 工作流总图

```text
                         AGENTS.md
                             │
              ┌──────────────┴──────────────┐
              ↓                             ↓
         agent-plan/                       Git
       开发意图/过程                    稳定版本
              │                             ↑
              ↓                             │
         Increment                          │
              │                             │
              ↓                             │
      Implementation                        │
              │                             │
              ↓                             │
        Validation                          │
              │                             │
              ↓                             │
     User Acceptance ───────────────────────┘
              │
              ↓
         Git Commit
```

这条流程的含义：

- `AGENTS.md` 是项目最高层开发约束。
- `agent-plan/` 记录开发意图、范围、过程、验证和验收状态。
- `Increment` 是代码任务的最小可追踪单元。
- `Implementation` 只能实现 Increment 范围内的内容。
- `Validation` 必须产生可复核的证据。
- `User Acceptance` 是代码进入稳定版本的唯一入口。
- 只有验收通过后，才执行 `Git Commit`，形成稳定版本。

### 0.2 三条硬门

1. **Plan Gate**：没有 Increment，不得开始代码实现。
2. **Validation Gate**：没有验证证据，不得请求用户验收。
3. **Acceptance/Git Gate**：没有用户明确验收，不得提交到稳定主分支。

### 0.3 双轨一致性

项目同时维护两条轨道：

- `agent-plan/` 轨道：回答“为什么做、做什么、做到哪、如何验证、是否验收”。
- `Git` 轨道：回答“哪一个已验收的版本是稳定版本”。

两条轨道必须一致：

- 每个提交除初始化提交外，都应关联一个 Increment ID。
- 不允许出现没有 Plan 记录的代码提交。
- 不允许 Plan 标记为 `accepted`，但 Git 没有对应提交。
- 不允许代码已经提交，但 Plan 仍停留在 `in_progress` 或 `validated`。
- 未验收的变更只能存在于工作区或 `inc/...` 特性分支，不得进入稳定 `main`。

### 0.4 阶段与产物对应表

| 阶段 | 产物位置 | 必须满足 |
|---|---|---|
| 规则约束 | `AGENTS.md` | 明确开发规则和硬门 |
| 意图与过程 | `agent-plan/<theme>.md` | 每个代码任务有主题归属 |
| 工作单元 | `Increment` | 有编号、范围、验收标准和时间 |
| 实现 | 工作区代码/场景/资源 | 不超出 Increment 范围 |
| 验证 | 测试命令、日志、截图、MCP 结果 | 有可复核证据 |
| 用户验收 | `agent-plan` 验收记录 | 用户明确接受 |
| 稳定版本 | Git Commit | 关联 Increment，进入已验收历史 |

## 1. 核心原则

### 1.1 Plan First

任何会改变运行工程的代码编写任务，都必须先更新 `agent-plan/`，再修改代码。禁止先写代码、后补计划。

### 1.2 No Increment, No Code

没有对应的 Increment，不得编写或修改代码、场景、资源、脚本、着色器、导入配置或运行相关工程设置。

### 1.3 Evidence Over Claims

“完成”必须有可验证证据：命令输出、Godot MCP 验证结果、测试结果、运行截图、错误日志或明确的人工验收步骤。不得只写“应该可以运行”。

### 1.4 Acceptance Gate

代码任务完成不等于已验收。只有用户明确表示“验收通过”“可以”“接受”“OK”或等价意思，任务才可进入 `accepted` 状态。

### 1.5 Git After Acceptance

用户验收通过后，必须把对应 Increment 的代码、场景、资源和 `agent-plan` 变更纳入 Git 版本管理。不得把未验收的实现直接提交到稳定主分支。

---

## 2. 什么任务算“代码编写任务”

以下变更全部算代码编写任务，必须建立或更新 Increment：

- `.gd`、`.cs`、`.gdshader`、`.glsl` 等源码。
- `.tscn`、`.scn`、`.tres`、`.res` 等场景与资源。
- `project.godot` 中会改变运行时行为的配置。
- InputMap、Autoload、碰撞层、渲染、显示、导出预设等工程配置。
- `.import` 导入设置及其关联的导入策略。
- `addons/` 下的编辑器插件或运行时插件。
- `test/`、`tests/` 下的自动化测试与测试夹具。
- 会改变游戏行为的工具脚本、构建脚本和编辑器脚本。

以下任务通常不单独触发 Increment，但如果伴随代码变更则必须一起记录：

- 纯文档修订。
- 纯美术素材归档。
- 许可证、来源说明和 README 更新。
- `agent-plan` 自身的修订。

---

## 3. `agent-plan/` 强制工作流

### 3.1 目录结构

`agent-plan/` 必须采用“一个主题一个文件”的方式：

```text
agent-plan/
  _index.md          # 所有主题、活跃 Increment 和 Git 记录的总索引
  _template.md       # Increment 模板
  ui.md              # UI、HUD、菜单、主题、布局
  combat.md          # 战斗、技能、伤害、状态、目标选择
  pawns.md           # 角色、修士、NPC、敌人、单位基类
  cultivation.md     # 境界、功法、突破、修炼
  sect.md            # 宗门、建筑、生产、研究
  world.md           # 地图、秘境、事件、探索
  inventory.md       # 装备、物品、背包、炼丹、炼器
  save.md            # 存档、读档、迁移、序列化
  audio.md           # 音频、音乐、音效
  core.md            # 全局服务、Autoload、事件总线、基础架构
  tools.md           # 编辑器工具、构建、导入、自动化
  testing.md         # 测试、调试、验收夹具
```

规则：

- 主题文件名统一使用稳定的 ASCII slug，例如 `combat.md`。
- 文档标题可以使用中文，例如“战斗系统”。
- 跨主题任务必须在 `_index.md` 建立父 Increment，并在所有受影响主题文件中建立子 Increment。
- 不允许把新功能随意塞进 `misc.md` 或 `other.md`。找不到主题时，先新增主题文件并登记到 `_index.md`。

### 3.2 Increment 编号

格式：

```text
INC-<THEME>-NNN
```

示例：

- `INC-UI-001`
- `INC-COMBAT-003`
- `INC-PAWNS-012`

要求：

- 编号在同一主题内单调递增，永不复用。
- 被取消、拒绝或替代的 Increment 保留原文，状态改为 `rejected` 或 `superseded`。
- 跨主题父 Increment 使用 `INC-CROSS-<NNN>`。

### 3.3 每个 Increment 的必填字段

每个 Increment 至少包含以下字段：

```markdown
## INC-COMBAT-001：实现暂停式战斗时间轴

- 状态：planned | in_progress | blocked | validated | awaiting_acceptance | accepted | rejected | superseded
- 创建时间：2026-09-25T13:05:27+08:00
- 最后修改：2026-09-25T13:05:27+08:00
- 主题：combat
- 目标：用一句话说明要改变什么玩家体验或系统能力。
- 验收标准：可测试、可观察、无歧义的条件。
- 范围：允许修改的目录、文件和系统。
- 非范围：明确不处理的内容，防止范围膨胀。
- 依赖：前置 Increment、资源、插件或设计决策。
- 检索证据：执行过的 `git status` / `git diff` 命令，以及检索到的 Increment、父 Increment、依赖状态和工作区变更。
- 风险：兼容性、性能、存档、资源许可或架构风险。
- 实现说明：关键设计决策和偏离原计划的理由。
- 变更文件：代码与资源路径列表。
- 测试证据：命令、Godot MCP 验证结果、截图、日志或人工步骤。
- 验证状态：未验证 | 验证通过 | 验证失败
- 验证时间：
- 已知问题：尚未解决的问题和影响范围。
- 用户验收：未验收 | 已验收 | 已拒绝，记录验收时间。
- Git：分支、commit hash、tag 或 PR 链接。
- 备注：其他需要保留的信息。
```

### 3.4 时间记录规则

所有时间必须使用 ISO 8601 并带时区：

```text
YYYY-MM-DDTHH:mm:ss+08:00
```

必须记录：

- Increment 创建时间。
- 每次修改 Increment 时的最后修改时间。
- 用户验收或拒绝时间。
- Git 提交时间和 commit hash。
- 影响存档格式、资源格式或工程配置的破坏性变更时间。

只写日期不够，必须写到秒和时区。

### 3.5 状态机

```text
planned
  -> in_progress
  -> validated
  -> awaiting_acceptance
  -> accepted
  -> rejected
  -> superseded

blocked = in_progress 的中断状态，解除后返回 in_progress
```

规则：

- 未开始：`planned`。
- 正在实现：`in_progress`。
- 被外部问题阻塞：`blocked`，必须写清阻塞原因和解除条件。
- 验证通过但尚未请求验收：`validated`。
- 已请求用户验收，正在等待明确结论：`awaiting_acceptance`。
- 用户明确通过：`accepted`。
- 用户明确否决：`rejected`。
- 被新方案替代：`superseded`，必须链接替代 Increment。
- `accepted` 之前禁止把实现声称为“已完成”。

### 3.6 每次代码任务的标准流程

1. 按 §3.7 的 Git Diff 优先检索协议确定本任务对应的 Increment；可以读取 `agent-plan/_index.md`、主题文件，也允许读取 `agent-plan/` 下的全部计划文件。
2. 新建或修改 Increment，填写检索证据、目标、范围、验收标准、风险和时间。
3. 将状态改为 `in_progress`，更新时间。
4. 只修改 Increment 范围内的文件。
5. 运行静态检查、编辑器验证、运行测试或人工冒烟测试。
6. 验证通过后，将状态改为 `validated`，并更新变更文件、测试证据、已知问题和最后修改时间。
7. 状态改为 `awaiting_acceptance`，向用户请求验收，并等待用户明确结论。
8. 用户验收后，记录验收时间，状态改为 `accepted`；用户拒绝则改为 `rejected` 并记录原因。
9. 执行 Git 提交，记录分支和 commit hash。
10. 更新 `_index.md`，确保主题索引、状态和 Git 记录一致。

### 3.7 Increment 检索协议（Git Diff 优先）

`agent-plan/` 允许全量读取；不得把“一个主题一个文件”解释为“只能读 `_index.md` 和当前主题文件”。检索 Increment 时，先用 Git Diff 找出真实变化，再结合索引、主题文件和必要的全量计划内容确认上下文。

#### 3.7.1 工作区检索（开始实现前必做）

在仓库根目录执行：

```text
git status --short
git diff --unified=0 -- agent-plan/
git diff --cached --unified=0 -- agent-plan/
```

要求：

- 从 `git diff` 的新增/删除行中搜索 `INC-[A-Z]+-[0-9]{3}`，识别被新增、修改、取消或替代的 Increment。
- 没有未提交 diff 时，继续执行历史检索，不得仅凭记忆或单个索引表开始实现。
- 工作区存在多个主题的 plan 变更时，只选择当前任务需要的 Increment，不得把其他未验收变更混入实现或提交。

#### 3.7.2 历史与全量检索

```text
git log --oneline -- agent-plan/
git diff <已验收基线>..HEAD --unified=0 -- agent-plan/
git grep -n -E "INC-[A-Z]+-[0-9]{3}" -- agent-plan/
```

如果 diff 不足以确认父子关系、依赖或验收标准，允许直接读取 `agent-plan/` 下全部主题文件；全量读取是合法上下文，不视为越界。

#### 3.7.3 检索结论

开始写代码前，必须把以下内容写入当前 Increment 的 `检索证据` 字段和 `实现说明`：

- 执行过的 Git Diff 命令及结果摘要。
- 当前 Increment ID、父 Increment（如有）和主题文件。
- 依赖 Increment 的状态；只有依赖满足 Plan Gate 才能开始。
- 允许修改的文件范围；超出范围的内容另立 Increment。
- 如果存在多个候选 Increment，优先遵循父 Increment 指定的子 Increment 顺序；没有父级顺序时，按依赖 DAG 选择，优先选择依赖已满足且编号最小的 Increment。

历史已验收 Increment 不要求回填 `检索证据`；自本规则生效后，新建或修改 Increment 时必须填写。

---

## 4. 验收与 Git 版本管理

### 4.1 验收定义

满足以下条件才算用户验收：

- 用户明确表示接受。
- Increment 的验收标准逐条满足。
- 测试证据已写入 `agent-plan/<theme>.md`。
- 用户已知晓所有已知问题和未覆盖范围。
- 没有把未测试的功能描述成已完成。

“看起来可以”“应该没问题”“我先看看”不算验收通过。

### 4.2 验收后的 Git 规则

用户验收通过后：

1. 确认当前目录是 Git 仓库。
2. 如果还不是仓库，先执行 `git init -b main`，并按用户要求建立基线提交。
3. 创建或切换到 `inc/INC-<THEME>-<NNN>` 特性分支，或经用户同意直接在 `main` 提交。
4. 只暂存本 Increment 相关的代码、场景、资源、测试和 `agent-plan` 文件。
5. 使用清晰的提交信息：

```text
<type>(<scope>): <summary> [INC-THEME-NNN]
```

示例：

```text
feat(combat): add paused real-time combat timeline [INC-COMBAT-001]
fix(ui): correct toast anchoring [INC-UI-004]
```

6. 提交后记录 commit hash 到 `agent-plan/_index.md` 和对应主题文件。由于提交无法记录自身 hash，应在提交后追加一次 `docs(plan): record ...` 文档提交，或使用 Git tag / PR 记录；已推送的提交不得为了写入自身 hash 而 amend。
7. 未配置远程仓库时，不要擅自推送；需要推送时先取得用户确认。
8. 不把 `.godot/`、导出产物、临时日志、密钥或用户数据提交到 Git。

### 4.3 Git 禁止事项

- 未验收的代码不得直接提交到 `main`。
- 不得用 `git reset --hard`、`git clean -fdx`、强推等破坏性命令清理工作区，除非用户明确要求。
- 不得把大型二进制素材直接加入仓库而不检查体积；必要时使用 Git LFS 或先询问用户。
- 不得提交 `.godot/` 缓存、构建输出、编辑器临时文件、API 密钥或本地路径配置。
- 不得未经用户确认重写已推送的提交历史。

---

## 5. Godot 4.7 开发规范

### 5.1 工程与目录

- 所有项目资源路径使用 `res://`。
- 代码中不得写死 `E:\...`、`C:\...` 等绝对路径。
- 运行时用户数据写入 `user://`，并设计存档版本与迁移机制。
- 当前项目处于空白工程阶段：没有场景、没有脚本、没有主场景。
- 新增目录优先采用功能域组织，例如：

```text
res://
  game/
    ui/
    combat/
    pawns/
    cultivation/
    sect/
    world/
    inventory/
    save/
  shared/
    core/
    resources/
    utils/
  test/          # GdUnit4 自动化断言（unit / integration / gameplay / headless）
  tests/         # 场景化测试入口（每个测试场景一个 .tscn，可选配套 .gd）
  addons/
  art/
  docs/
  agent-plan/
```

`test/` 与 `tests/` 的职责边界：

- `test/`：GdUnit4 自动化断言与 `test/run_tests.ps1` 统一门禁；分层职责见 §6 与 `test/README.md`。
- `tests/`：场景化测试入口，每个测试场景一个独立 `.tscn`（必要时附 `.gd`），例如 4v4 Boss 玩法验证、2v2 / 3v3 技术验证、多选编队命令验证、Build 重配面板验证、首通奖励解锁验证。
- 测试专用节点、测试专用参数与测试专用资源引用必须放在 `tests/` 场景内；`main.tscn` 只保留正式游戏入口职责，不得为测试内嵌专用引用。
- 新增 `tests/` 场景必须同步更新 `tests/README.md`（目录规范与运行方式），并在 `test/README.md` 交叉引用。

### 5.2 GDScript 规范

- 使用 Godot 4.x 语法，不混用 Godot 3.x API。
- 文件名、函数名、变量名使用 `snake_case`。
- 类名、节点名、类型名使用 `PascalCase`。
- 常量使用 `UPPER_SNAKE_CASE`。
- 尽量使用静态类型：`var value: int`、`func run(input: String) -> void`。
- 节点引用优先使用 `@onready`，编辑器可配置数据使用 `@export`。
- 信号使用明确命名，优先使用类型化参数和 `Callable`。
- 避免一个脚本同时负责 UI、战斗、存档和资源加载；按职责拆分。
- 不要在 `_process()` 中轮询所有状态；优先事件、信号和 `_physics_process()`。
- 不为单个功能随意新增 Autoload。Autoload 仅用于真正的全局服务，并必须写入 `agent-plan/core.md`。

### 5.3 场景与资源

- 优先用 Godot 编辑器或 Godot MCP 工具创建和修改 `.tscn`、`.tres`。
- 手工修改 `.tscn` 后必须验证场景能加载，并检查节点路径、信号和资源引用。
- 场景根节点、脚本职责和依赖关系必须清晰；避免深层匿名节点。
- 可复用数据优先使用自定义 `Resource`，不要把大量配置硬编码在脚本中。
- 修改信号连接后必须调用 Godot 验证工具或启动场景确认没有断链。

### 5.4 输入、UI 和显示

- 输入必须通过 InputMap 动作读取，不得在业务代码中硬编码物理按键。
- UI 优先使用场景、Theme、Container、锚点和布局系统，避免大量硬编码坐标。
- 项目采用 `canvas_items` 拉伸和 `expand` 宽高比；新增 UI 必须同时验证 16:9、16:10 和窄屏表现。
- 像素素材统一使用 Nearest 过滤；不要让像素特效走线性过滤。
- 需要整数像素对齐时，明确记录缩放策略和测试分辨率。

### 5.5 物理与性能

- 明确使用 2D 或 3D 物理层，不得随意占用全部 Collision Layer/Mask。
- 战斗和 AI 不得依赖每帧全场景搜索。
- 优化前先用 Godot Profiler 或 MCP 性能工具采集证据。
- 引入对象池、批处理或缓存时，必须说明收益和复杂度成本。

### 5.6 存档、资源和数据

- 存档格式必须带版本号。
- 修改存档结构时必须提供迁移函数或明确说明不兼容。
- 不把运行时状态写进 `.tres` 源资源。
- 不修改已接受的资源接口而不记录破坏性变更。
- 所有外部素材必须记录来源、许可证、是否 AI 生成和允许用途。

---

## 6. 测试与验证

每个代码 Increment 至少执行适用的验证：

1. GDScript 解析和类型检查。
2. 场景加载和实例化检查。
3. 相关逻辑的单元测试或最小复现测试。
4. 运行时冒烟测试。
5. 用户验收路径的手动测试步骤。
6. 对 UI/视觉改动提供截图或视频证据。

提交前的统一自动化门禁（框架分层与新增测试步骤见 `test/README.md`）：

```powershell
pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN
```

- 退出码 `0` 表示全部通过；非 `0` 时必须把失败用例与关键输出摘录进 Increment，不得跳过。
- 三层职责：`test/unit`（纯逻辑）、`test/integration`（系统组合）、`test/gameplay`（场景与玩法）。新增或修改业务逻辑时必须补对应层用例；能落在下层的验证不要上推。
- `test/headless/` 的自建套件是历史回归基线，必须保持可运行，断言总数不得下降。
- 不得为了让测试变绿而修改断言期望值掩盖业务缺陷；发现业务缺陷应另立对应主题的 Increment，不在测试任务内顺手改 `game/` 业务代码。

优先使用现有 Godot MCP 能力：

- `validate`：验证脚本、场景、结构和信号。
- `run_project`：启动运行时。
- `get_debug_output`：读取错误和日志。
- `take_screenshot`：记录视觉结果。
- `stop_project`：结束运行时并释放会话。
- `check_project`：检查项目与运行时状态。

如果 Godot MCP 在当前会话不可用（工具调用返回 unsupported，或桥接端口无法连接），允许改用等价的 Godot CLI headless 验证，但必须在 Increment 中写明替代原因和影响范围：

- 脚本与场景加载：运行 `godot --headless --path <项目目录> --quit-after <帧数>`，退出码 0 视为加载通过；也可以运行 `test/` 下的自建 headless 测试脚本，退出码 0 视为通过，非 0 必须把输出摘录进 Increment。
- 逻辑与计时验证：优先写成可重复执行的 headless 断言脚本，而不是只靠人工观察。
- 使用 CLI 替代 MCP 时，“测试证据”必须同时记录：替代原因、执行命令、退出码和关键输出。
- 本仓库文档不得写入 Godot 可执行文件的本地绝对路径，只记录调用方式。

如果某个验证无法执行，必须在 Increment 中写明“未执行原因、影响范围和补偿验证”。

---

## 7. 素材、导入和许可证

- 像素 PNG 默认使用 Nearest 过滤；导入后要检查实际显示效果。
- `.import` 文件应与资源一起版本管理，不要手工删除后不重新导入。
- `.godot/`、`.godot/imported/` 等缓存不提交 Git。
- 不得擅自替换、删除或重命名 `art/` 下的素材，除非 Increment 明确包含该工作。
- `EverRogueTileset 2.0` 当前缺少许可证，禁止在正式构建中默认使用。
- `FREE RPG SKILL ICONS 16x16` 不是 CC0，禁止转售、再分发和据为己有。
- `Xianxia_Pixel_Pack` 含 Gemini 生成内容，使用和发布时必须保留 AI 披露和 CC0 许可证文件。
- 新增素材必须记录：来源 URL、作者、许可证、AI 参与情况、商用限制、文件校验信息。

---

## 8. 禁止事项

- 禁止无 Increment 直接改代码。
- 禁止不更新时间戳。
- 禁止先实现再补计划。
- 禁止未验收就提交到 `main`。
- 禁止把 `.godot/`、构建产物、密钥或本地绝对路径提交到 Git。
- 禁止擅自升级 Godot 主版本或修改核心工程配置。
- 禁止在没有许可证依据的情况下使用或发布素材。
- 禁止用破坏性 Git 命令清理用户工作区。
- 禁止把未经测试的行为描述为“已完成”或“没问题”。

---

## 9. Definition of Done

一个代码增量只有同时满足以下条件才算真正完成：

- 存在对应的 `agent-plan/<theme>.md` Increment。
- 创建时间、最后修改时间、验收时间和 Git 记录完整。
- 实际变更没有超出 Increment 范围。
- 静态检查、场景验证和适用的运行时测试已执行，并记录验证状态和验证时间。
- 验收标准逐条有证据。
- 已知问题和不覆盖范围已明确写出。
- 用户明确验收通过。
- Git commit 已创建并记录 hash。
- `agent-plan/_index.md` 已同步更新。

---

## 10. 当前工程基线（首次读取时必须检查）

- 项目路径：本仓库根目录（Git 仓库与 project.godot 所在目录）。
- 项目名：`test1`。
- 当前已有 `game/main/main.tscn` 主场景，以及 Pawn MVP 的脚本、场景和资源配置。
- 当前已是 Git 仓库，默认分支 `main`，remote 为 `origin`；`INC-CROSS-001`、`INC-CROSS-002` 与 `INC-PAWNS-003` 已完成提交并 push 到 `origin/main`。
- art/ 下有 6 套素材包、2998 个文件、35.56 MB：PNG 1495 张（34.02 MB）与 .png.import 1495 个（1.49 MB），最大单文件 2.77 MB，无超过 10 MB 的文件。
- art/ 下 1495 张 PNG 与 1495 个 .png.import 已一一配对，缺失 0 个、孤儿 0 个（2026-09-25 复核；早期“约 327 张缺少导入记录”的基线已过期）。
- 像素素材过滤策略需要统一为 Nearest：project.godot 目前未设置 rendering/textures/canvas_textures/default_texture_filter，仍是引擎默认线性过滤；MVP 场景只使用占位 SVG，因此不影响本次验收。
- `EverRogueTileset 2.0` 缺少许可证。
- `agent-plan/` 已建立 `_index.md`、`_template.md`、`pawns.md`、`combat.md`、`ui.md`、`core.md` 和 `tools.md`。
- 首个 Pawn MVP（`INC-CROSS-001` 及 `INC-PAWNS-001/COMBAT-001/UI-001/CORE-001`）已通过用户验收，并在 `main` 上提交为 `d7c2e1e`。
- 2026-09-25T13:52:23+08:00 已按用户授权完成首次 push：`origin/main` = `567b6e7`；`INC-TOOLS-001`、`INC-TOOLS-002` 已登记验收。
- `docs/血条ui需求.txt` 是用户提供的血条 UI 需求输入（“变化时显示 + 延迟自动隐藏”），对应父 Increment `INC-CROSS-002`；需求文档中的“① HealthComponent”登记为 `INC-PAWNS-003`（已验收 2026-09-25T14:16:35+08:00，已提交为 `a873c3f`）。
- Godot MCP 在当前 Codex 会话已恢复并可用；运行时验证优先使用 MCP，CLI headless 与 `test/headless/` 自建脚本作为可重复回归和 MCP 不可用时的等价后备。
- Pawn 场景结构自 `INC-PAWNS-005` 起为 `Pawn/HealthBarAnchor(Node2D, y = -46)/StatusBars`（`game/ui/pawn_status_bars.tscn` 实例）；资源条组默认隐藏，任一已绑定资源变化时显示，最后一次变化 2 秒后隐藏。旧 `game/ui/pawn_health_bar.tscn` 仅作为兼容组件保留，不再由 Pawn 实例化。
- 生命/护盾运行时数值自 `INC-PAWNS-004` 起由 `Pawn/Resources/Health` 与 `Pawn/Resources/Shield`（`ResourcePoolComponent`）持有；自 `INC-PAWNS-006` 起 Pawn 直接订阅资源池的 `value_changed` / `depleted`，兼容门面不再承担生命周期事件桥，`HealthComponent` 仍提供先护盾后生命的兼容路由。`Pawn.current_health` / `current_shield` 仍是只读代理，灵力由按需创建的 `Pawn/Resources/Spirit` 持有；Pawn 仍向外转发 `health_changed` / `shield_changed` / `spirit_changed`，参数与顺序不变。
- 自建验证脚本现有 10 个 headless 套件：`resource_pool_component_test.gd`（102）、`resource_bar_test.gd`（86）、`spirit_pool_test.gd`（64）、`pawn_info_panel_display_test.gd`（69）、`health_component_test.gd`（55）、`pawn_resource_pools_test.gd`（49）、`health_bar_visibility_test.gd`（46）、`pawn_status_bars_integration_test.gd`（37）、`health_pool_authority_test.gd`（33）、`hud_spirit_display_test.gd`（8），合计 549 项；另有 `test/tools/capture_health_bar_evidence.gd` 与 `test/tools/capture_pawn_info_panel_evidence.gd` 负责真实窗口多分辨率截图与报告（输出到不入库的 `.mcp/godot-runtime/screenshots/`，需重跑脚本再生成）。
- 自 `INC-TESTING-001` 起已引入 GdUnit4 `v6.2.1`（`addons/gdUnit4/`，MIT License）作为统一测试框架：`test/unit` 71 例、`test/integration` 39 例、`test/gameplay` 20 例，共 130 个用例，与上述 10 个 headless 套件由 `test/run_tests.ps1` 统一驱动（退出码 0 = 全通过）。GdUnit4 编辑器插件未在 `project.godot` 中启用，测试只走 headless 命令；`reports/` 为可重建产物，不入库。
- 自 `INC-CROSS-006` 起玩家主动技能闭环可用：`project.godot` 的 `cast_skill`（Q）仅在选中存活玩家且存在有效敌方目标时调用 `PlayerController.order_skill()`；控制器先接近 `ActiveSkillDefinition.get_effective_cast_range()` 再调用 `Pawn.cast_skill()`，成功后清除技能命令并保留普攻目标，灵力不足/冷却中则回退普通攻击且无副作用。HUD `SkillLabel` 显示技能名、Q 键位、灵力消耗、剩余冷却与不可用原因（未选中 `技能：-`、无技能 `技能：无`）。
- `INC-CROSS-002` 已通过用户验收：血条改为“生命状态变化时显示、最后一次变化 2 秒后隐藏”；16:9（1152x648）/ 16:10（1152x720）/ 窄屏（窗口 800x720 → 逻辑视口 1152x1036）三档真实渲染验证通过，已提交为 `e233120`；证据报告为 `.mcp/godot-runtime/screenshots/health_bar_evidence_report.txt`（`.mcp/` 不入库，需重跑脚本再生成）。
- 自 `INC-CROSS-007` 起境界与 Build 容量可用：`RealmDefinition`（炼气→化神，容量 1/2/1 … 5/6/5）是 Build 容量的唯一来源；`TechniqueDefinition` / `PassiveSkillDefinition` 提供流派、境界门槛与互斥标签；`BuildValidator.validate(BuildLoadout)` 以结构化错误码覆盖缺境界、容量超限、同类重复、功法互斥、境界不足与条目未配置；`Pawn.get_realm()` / `get_build_loadout()` / `get_build_validation()` 均为只读接口，HUD `BuildLabel` 显示 `境界：<名>    功法 a / N    主动 b / N    被动 c / N`（无境界显示 `境界：无    Build：不适用`，未选中显示 `Build：-`），面板 `HudMargin.offset_bottom = 222`。
- 已裁决的基线差异（原 2026-09-25T15:47:47+08:00，2026-09-25T16:19:12+08:00 处理）：`game/pawns/data/enemy_pawn.tres` 被外部（编辑器保存）把 `max_health` 由 80.0 改为 180.0，并带上 `uid` 与 `Color` 规范化。按“登记数据基线、不回退用户数据”的结论登记为 `INC-PAWNS-009`（`awaiting_acceptance`），同步 `test/unit/pawn_data_defaults_test.gd` 与 `test/headless/hud_spirit_display_test.gd` 的期望值为 180.0 / `HP：180 / 180`，统一门禁已恢复退出码 0。
- 自 `INC-CROSS-008` 起 Pawn 信息卡可用：`game/ui/pawn_info_model.gd`（`PawnInfoModel`，纯静态读模型）与 `game/ui/pawn_info_panel.gd` / `.tscn`（`PawnInfoPanel`，`bind_pawn()` / `unbind()` / `is_bound()` / `get_snapshot()` / `set_compact()` 与 `pawn_bound` / `pawn_unbound` / `refreshed` 信号）构成只读信息卡；主场景把唯一实例挂在 `HUD/PawnInfoPanel`（位于 `PauseOverlay` 之前，暂停遮罩仍覆盖它），`main.gd` 的 `_set_selected_pawn()` 负责绑定/解绑、`_set_paused()` 负责 `set_compact(not value)`。面板锚定右下角、`offset_top = -370`（高 354、宽 356、边距 16）。
- 自 `INC-CROSS-009` 起修为进度链路可用：`RealmDefinition.next_realm` / `breakthrough_exp` 串起炼气→筑基→金丹→元婴→化神（非终点原型阈值 100.0，化神无下一境界）；`Pawn/CultivationProgress`（`CultivationProgressComponent`）是当前修为与突破阈值的唯一运行时状态源，`Pawn.get_cultivation_snapshot()` / `gain_cultivation_exp()` 提供只读快照与受控增加，`cultivation_changed` / `cultivation_ready` 驱动信息卡刷新；`PawnInfoPanel` 完整模式显示修为文案与 `CultivationSection` 进度条，精简模式隐藏。实际突破仍未实现。
- `INC-UI-008` 为在固定 356x354 信息卡内容纳修为区，把 `Content` separation 设为 2、各 Section separation 设为 2、`CultivationProgress` 最小高度设为 8、Margin 上下边距设为 7；这些值通过 1152x648 / 1152x720 / 800x720（逻辑视口 1152x1036）真实窗口验证。`INC-UI-009` 为容纳第四行 Build 行，进一步移除 `CultivationSection` 的 `CultivationSeparator` 与 `CultivationTitleLabel`（修为行文案自带“修为”前缀，信息不丢失），面板仍固定 356x354 并再次通过三档真实窗口取证。后续增删信息卡节点必须重新跑 `test/tools/capture_pawn_info_panel_evidence.gd`，不得只改固定 offset 后宣称通过。
- 自 `INC-CROSS-010` 起 Build 分层补齐武器一层：`WeaponDefinition`（`game/shared/resources/weapon_definition.gd`，字段 `id` / `display_name` / `weapon_type` / `element` / `required_realm_tier` / `description`）是武器唯一静态契约，五行标签只有 `ELEMENT_LABELS` 一个来源（类型 `sword` / `artifact` / `blade` → 剑 / 法器 / 刀，未知回退原值或 `无属性`）；`RealmDefinition.KIND_WEAPON` / `weapon_slots` 让 `ALL_KINDS` 覆盖功法 / 武器 / 主动 / 被动四类槽位，五个境界的 `weapon_slots` 固定为 1 且不随境界递增；`PawnData.weapon` 是唯一装备入口（沿用 `active_skill` 的“单入口字段 + 汇总数组”约定），`BuildLoadout.weapons` / `get_weapon()` 只是只读汇总，`BuildValidator` 判定顺序固定为 功法 → 武器 → 主动 → 被动；信息卡 Build 区显示四行 `功法 / 武器 / 主动 / 被动`，武器行形如 `武器  1 / 1    青锋剑（剑 · 金）`。武器目前只参与 Build 校验与信息卡展示，不参与战斗结算与属性加成，五行也不参与相容 / 克制校验。
- 顶部 HUD 实测占位（`INC-CROSS-008` 记录）：`HudMargin` 的内容最小高度 246 会覆盖 Scene 里 `offset_bottom = 222` 的设计值，实际下沿为 y=262（`16 + 246`）。信息卡避让间距必须按 262 计算；若后续 HUD 增删行，需要重新实测。
- 自 `INC-TESTING-002` 起：`health_bar_visibility_test.gd` / `pawn_status_bars_integration_test.gd` 的“约 2 秒自动隐藏”运行态断言下界由 1900ms 放宽到 1500ms（上界 3500ms 不变）。原因是倒计时从触发帧起算、该帧 delta 会被立即计入，机器负载下实测 1871~1898ms 会假失败；精确的 2.0 秒语义仍由 `tick()` 驱动的确定性用例负责。
- 已知工具限制：`--headless` 的 dummy 窗口固定为 64x64，逻辑视口会退化成 1152x1152，因此多分辨率 UI 验证必须使用真实窗口渲染；Windows 版 Godot 是 GUI 子系统进程，必须用 `Start-Process -Wait` 才能取得退出码与 stdout，否则会静默脱离。
- 这些是已知基线问题，不得在无对应 Increment 的情况下顺手修复。

---

## 11. 本文件的维护

- 修改本文件属于流程变更，必须记录最后修改时间。
- 修改流程规则时，应同步更新 `agent-plan/_index.md` 中的流程版本记录。
- 如果新增主题、目录规范、测试工具或 Git 策略，应优先更新本文件，再执行相关代码任务。
---

## 12. Godot 4.7 补充约束

### 12.1 UID、导入文件和资源引用

- Godot 4.4+ 会为部分脚本和着色器生成 `.uid` 文件；`.uid` 应随对应资源一起提交 Git，不得手工删除或随意重建。
- 由编辑器生成的 `uid://` 引用不得手工批量改写。需要移动或重命名资源时，优先使用 Godot 编辑器的移动/重命名能力。
- `.png.import`、`.uid` 等资源元数据属于工程源文件；`.godot/`、`.godot/imported/` 属于可重建缓存。
- `.tscn`、`.tres` 发生合并冲突时，禁止凭猜测手工解决。必须用 Godot 打开、检查节点路径、资源 UID、信号连接和脚本附加关系，再做验证。
- 同一场景同一时间只允许一个 Agent 修改，避免 `.tscn` 冲突和节点路径失效。

### 12.2 警告、类型和错误

- 不引入新的 GDScript 解析错误、场景加载错误或信号断链。
- 新增警告必须消除，或在 Increment 的“已知问题”中说明原因和影响。
- 静态类型应提高可读性和安全性，不得为了通过类型检查而加入掩盖运行时错误的强制转换。
- 缺失节点、缺失资源、无效 UID、无效信号连接一律视为阻塞问题，不得当作“小问题”跳过。

### 12.3 导出与发布

- `export_presets.cfg` 如创建成功，应纳入 Git 管理。
- 签名密钥、证书、密码、导出凭据不得提交 Git。
- `build/`、`export/`、导出二进制包、临时日志和 `.godot/` 不得提交 Git。
- 修改导出预设、平台设置、渲染方式或打包流程，均属于代码编写任务，必须建立 Increment。
- 发布构建必须在 `agent-plan/tools.md` 或 `docs/` 中记录可复现步骤和已知限制。

### 12.4 插件、编辑器脚本和第三方依赖

- 新增 `addons/`、第三方库、编辑器插件前，必须记录来源、版本、许可证、维护状态和安全风险。
- 不得无说明地修改第三方插件内部实现；优先使用包装层、配置层或向上游提交补丁。
- `@tool` 脚本可能在编辑器内执行。首次引入时必须进行 headless 编辑器启动检查，并在 Increment 中记录执行范围和副作用。
- 不执行来源不明、未锁定版本或要求危险系统权限的插件脚本。

### 12.5 本地化、可访问性和输入

- 面向玩家的文本应优先使用 `tr()` 和翻译键，避免在 UI 脚本中散落硬编码文案。
- UI 必须考虑字体缩放、分辨率变化、安全区域、键盘导航和手柄导航。
- 不得只依赖颜色表达状态；重要状态必须有文字、图标或形状辅助。
- 输入动作必须通过 InputMap 配置，并保留键位重绑定或手柄适配的扩展空间。

### 12.6 测试框架与并行开发

- 测试框架已确定为 **GdUnit4 `v6.2.1`**：`addons/gdUnit4/`，MIT License（© 2023 Mike Schulze），来源 https://github.com/godot-gdunit-labs/gdUnit4 。选型结论与 GdUnit4 / GUT / 自建 headless 三者的取舍实证记录在 `agent-plan/testing.md` 的 `INC-TESTING-001`；引入时的来源、版本、许可证、维护状态与安全审计结论同见该 Increment（§12.4）。
- 统一入口为 `test/run_tests.ps1`，一条命令跑完三层 GdUnit4 用例与全部 `test/headless/*_test.gd`；退出码 `0` 表示全通过。分层职责、命名规则与新增测试步骤见 `test/README.md`。
- GdUnit4 编辑器插件未在 `project.godot` 中启用；测试只通过 `GdUnitCmdTool.gd` 在 headless 下运行，避免影响并行进行的 MCP 运行时验证。
- 引入新的测试依赖或插件必须重新执行 §12.4 的审计。
- 不得声称未实际执行的测试结果；没有对应测试时只能写实际执行的 Godot 验证或人工冒烟测试。
- 场景化测试入口统一放在 `tests/`，与自动化断言层 `test/` 分开；新增测试场景必须放进 `tests/`，不得往 `main.tscn` 里加测试专用节点或参数。
- 多个 Agent 并行开发时，一个主题文件、一个场景、一个 Autoload 或一个共享资源同一时间只能有一个写入者。
- `project.godot`、`agent-plan/_index.md`、全局事件总线和共享资源属于高冲突文件，修改前必须先确认没有其他 Agent 正在写入。
