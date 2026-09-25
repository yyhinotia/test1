# AGENTS.md — test1 Godot 项目开发约束

> 适用范围：本仓库根目录（Godot 项目 test1）及其全部子目录  
> 项目定位：修仙 RPG + 宗门经营 + 秘境探索 + 暂停式实时战术战斗  
> 设计源：`docs/project_summary.md`  
> 引擎版本：Godot `4.7.2.stable`  
> 文档最后修改：`2026-09-25T14:10:35+08:00`

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

1. 判断主题，读取 `agent-plan/_index.md` 和相关主题文件。
2. 新建或修改 Increment，填写目标、范围、验收标准、风险和时间。
3. 将状态改为 `in_progress`，更新时间。
4. 只修改 Increment 范围内的文件。
5. 运行静态检查、编辑器验证、运行测试或人工冒烟测试。
6. 验证通过后，将状态改为 `validated`，并更新变更文件、测试证据、已知问题和最后修改时间。
7. 状态改为 `awaiting_acceptance`，向用户请求验收，并等待用户明确结论。
8. 用户验收后，记录验收时间，状态改为 `accepted`；用户拒绝则改为 `rejected` 并记录原因。
9. 执行 Git 提交，记录分支和 commit hash。
10. 更新 `_index.md`，确保主题索引、状态和 Git 记录一致。

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
  test/
  addons/
  art/
  docs/
  agent-plan/
```

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
- 当前已是 Git 仓库，默认分支 `main`，remote 为 `origin`，但尚无提交。
- art/ 下有 6 套素材包、2998 个文件、35.56 MB：PNG 1495 张（34.02 MB）与 .png.import 1495 个（1.49 MB），最大单文件 2.77 MB，无超过 10 MB 的文件。
- art/ 下 1495 张 PNG 与 1495 个 .png.import 已一一配对，缺失 0 个、孤儿 0 个（2026-09-25 复核；早期“约 327 张缺少导入记录”的基线已过期）。
- 像素素材过滤策略需要统一为 Nearest：project.godot 目前未设置 rendering/textures/canvas_textures/default_texture_filter，仍是引擎默认线性过滤；MVP 场景只使用占位 SVG，因此不影响本次验收。
- `EverRogueTileset 2.0` 缺少许可证。
- `agent-plan/` 已建立 `_index.md`、`_template.md`、`pawns.md`、`combat.md`、`ui.md`、`core.md` 和 `tools.md`。
- 首个 Pawn MVP（`INC-CROSS-001` 及 `INC-PAWNS-001/COMBAT-001/UI-001/CORE-001`）已通过用户验收，并在 `main` 上提交为 `d7c2e1e`。
- 2026-09-25T13:52:23+08:00 已按用户授权完成首次 push：`origin/main` = `567b6e7`；`INC-TOOLS-001`、`INC-TOOLS-002` 已登记验收。
- `docs/血条ui需求.txt` 是用户提供的血条 UI 需求输入（“变化时显示 + 延迟自动隐藏”），对应父 Increment `INC-CROSS-002`；需求文档中的“① HealthComponent”登记为 `INC-PAWNS-003`（planned）。
- 2026-09-25T13:55 起本会话 Godot MCP 工具调用返回 unsupported，改用 Godot CLI headless 与 `test/headless/` 自建脚本验证；MCP 恢复后应优先回到 MCP。
- Pawn 场景结构自 `INC-PAWNS-002` 起为 `Pawn/HealthBarAnchor(Node2D, y = -46)/HealthBar`（`game/ui/pawn_health_bar.tscn` 实例）；血条默认隐藏，只在生命状态变化时显示，最后一次变化 2 秒后隐藏。
- 自建验证脚本位于 `test/headless/health_bar_visibility_test.gd`（逻辑与运行态计时断言）与 `test/tools/capture_health_bar_evidence.gd`（截图证据）；项目仍未引入 GUT 或 GdUnit。
- `INC-CROSS-002` 已通过用户验收：血条改为“生命状态变化时显示、最后一次变化 2 秒后隐藏”；16:9（1152x648）/ 16:10（1152x720）/ 窄屏（窗口 800x720 → 逻辑视口 1152x1036）三档真实渲染验证通过，已提交为 `e233120`；证据报告为 `.mcp/godot-runtime/screenshots/health_bar_evidence_report.txt`（`.mcp/` 不入库，需重跑脚本再生成）。
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

- 当前项目尚未确定测试框架。第一个引入测试的 Increment 必须先选择并记录 GUT、GdUnit 或自建 headless 测试方案的取舍。
- 没有测试框架时，不得声称“已做单元测试”；只能写实际执行的 Godot 验证或人工冒烟测试。
- 多个 Agent 并行开发时，一个主题文件、一个场景、一个 Autoload 或一个共享资源同一时间只能有一个写入者。
- `project.godot`、`agent-plan/_index.md`、全局事件总线和共享资源属于高冲突文件，修改前必须先确认没有其他 Agent 正在写入。
