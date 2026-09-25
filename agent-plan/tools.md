# 工具与仓库管理

> 最后修改：2026-09-25T13:44:10+08:00  
> 主题：tools  
> 规则来源：`../AGENTS.md`

## INC-TOOLS-001：初始化 Git 仓库并配置 origin

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T13:14:56+08:00
- 最后修改：2026-09-25T13:39:23+08:00
- 主题：tools
- 目标：将 `test_1` 初始化为 Git 仓库，默认分支为 `main`，并配置 GitHub origin 地址。
- 验收标准：
  - 项目根目录存在 `.git` 仓库。
  - 当前分支为 `main`。
  - `origin` 指向 `git@github.com:yyhinotia/test1.git`。
  - 不执行 push、不创建提交、不修改业务代码。
- 范围：`git init -b main`、`git remote add origin ...`、`git remote -v` 验证。
- 非范围：首次提交、远程推送、Git LFS、SSH key 配置、仓库内容清理。
- 依赖：用户提供的 origin 地址；本机 Git `2.54.0.windows.1`。
- 风险：远程仓库是否已创建、SSH 权限是否可用，需要通过实际 push 或连接测试确认；本次只验证本地 remote 配置。
- 实现说明：已执行 `git init -b main`，并配置 `origin` 为 `git@github.com:yyhinotia/test1.git`。
- 变更文件：`.git/config`、`agent-plan/tools.md`、`agent-plan/_index.md`。
- 测试证据：
  - `git branch --show-current` -> `main`
  - `git remote -v` -> `origin git@github.com:yyhinotia/test1.git (fetch/push)`
  - `git status --short --branch` -> `No commits yet on main`
  - 复验（SSH 连通性）：ssh -T git@github.com 返回 Hi yyhinotia! You have successfully authenticated...，说明当前 SSH 密钥有该账号的读取权限。
  - 复验（远程可达）：git ls-remote origin 退出码 0 且无任何 refs，说明 git@github.com:yyhinotia/test1.git 存在且为空仓库，首次 push 即为初始提交。
  - 复验（上游关联）：branch.main.remote=origin、branch.main.merge=refs/heads/main 已写入 .git/config，首次 git push 无需额外参数。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:39:23+08:00
- 已知问题：尚未创建首次提交；尚未 push。SSH 连通性已复验通过。
- 用户验收：未验收
- 验收时间：
- Git：分支 `main` / remote `origin` / 暂无提交
- 备注：用户验收前不执行首次提交和 push；本轮未改动任何 Godot 业务文件。

## INC-TOOLS-002：首次提交基线与素材入库策略

- 状态：awaiting_acceptance
- 创建时间：2026-09-25T13:41:00+08:00
- 最后修改：2026-09-25T13:44:10+08:00
- 主题：tools
- 目标：在用户验收 INC-CROSS-001 后，把已验收的实现与 agent-plan 记录一次性纳入 Git 稳定版本，并在提交前确定 art/ 素材的入库策略。
- 验收标准：
  - 首次提交只包含本次验收范围内的实现、场景、资源与 agent-plan 记录。
  - .godot/ 与 .mcp/ 不入库（已由 .gitignore 覆盖），运行截图等缓存不进入版本历史。
  - art/ 素材的入库方式有明确结论（是否使用 Git LFS），并记录依据。
  - 提交信息遵循 <type>(<scope>): <summary> [INC-THEME-NNN]。
  - 提交后把 commit hash 写回 agent-plan，并同步 _index.md。
  - 推送到 origin 之前取得用户明确授权。
- 范围：Git 暂存与提交、.gitignore 与 .gitattributes 的只读核对、agent-plan/tools.md 与 agent-plan/_index.md 的记录。
- 非范围：远程推送（需单独授权）、历史重写、LFS 全量迁移、素材删除或重命名、素材许可证处理。
- 依赖：INC-CROSS-001 及四个子 Increment 的用户验收结论；用户对 art/ 入库方式的决策。
- 风险：若先以普通 Git 提交 35.56 MB 素材、之后再切换 LFS，需要重写已推送历史；因此必须在首次提交前确定策略。
- 实现说明：
  - 体量实测（2026-09-25）：art/ 共 2998 个文件、35.56 MB，其中 PNG 1495 个（34.02 MB）、.png.import 1495 个（1.49 MB）、json/txt/md 共 8 个；最大单文件 2.77 MB（art/wuxia_shield_icons/spritesheet/3_wuxia_shield_icons_spritesheet_128x128.png）；超过 10 MB 的文件 0 个。
  - 六个素材包体量：Xianxia_Pixel_Pack 21.09 MB、wuxia_shield_icons 7.75 MB、wuxia_weapon_icons 6.51 MB、mini_meadow_upload_bundle 0.15 MB、EverRogueTileset 2.0 0.04 MB、FREE RPG SKILL ICONS 16x16 0.01 MB。
  - .import 完整性实测：1495 个 PNG 与 1495 个 .png.import 一一配对，缺失 0 个、孤儿 0 个、0 字节导入文件 0 个。
  - 其余纳入版本管理的内容共 38 个文件、83.7 KB（脚本、场景、资源、文档）。
  - 策略建议：单文件与仓库体量都远低于常见托管阈值（单文件 100 MB、仓库 1 GB），首次提交可不引入 Git LFS；若后续素材增长到数百 MB 或出现接近 50 MB 的单文件，再以独立 Increment 引入 LFS。
- 变更文件：首次提交共 3039 个文件（art/ 2998、game/ 26、agent-plan/ 7、docs/ 1、根目录 7），本次文档提交仅改 agent-plan/tools.md 与 agent-plan/_index.md。
- 测试证据：
  - 暂存复核：git diff --cached --name-only 共 3039 个文件；art/ 2998、game/ 26、agent-plan/ 7、docs/ 1、根目录 7；.godot/ 与 .mcp/ 命中 0 个；工作区无未暂存残留。
  - 体量复核：git diff --cached --shortstat 为 3039 files changed, 64536 insertions(+)。
  - 安全检查：对全部 60 个非 art 待提交文件扫描本地绝对路径与密钥关键词，并移除 AGENTS.md 中 2 处本地绝对路径后复查为 0 命中。
  - 首次提交：d7c2e1e（feat(pawns): add pawn MVP with movement, combat, HUD and pause [INC-CROSS-001]，完整 hash d7c2e1eca5d7890237b2cb439666aec9dde11255）。
  - 提交后 git status --short --branch 为空，工作区干净。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:43:51+08:00
- 已知问题：art/EverRogueTileset 2.0 缺许可证、FREE RPG SKILL ICONS 16x16 非 CC0、像素素材过滤未统一为 Nearest，均不在本 Increment 处理。
- 用户验收：未验收
- 验收时间：
- Git：分支 `main`，commit `d7c2e1e`，尚未 push
- 备注：本 Increment 不修改任何业务代码，只处理版本入库策略与记录。
