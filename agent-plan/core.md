# Core 主题计划

> 最后修改：2026-09-25T13:42:33+08:00  
> 主题：core  
> 规则来源：`../AGENTS.md`

## INC-CORE-001：建立可运行主场景与暂停输入

- 状态：accepted
- 创建时间：2026-09-25T13:21:58+08:00
- 最后修改：2026-09-25T13:42:33+08:00
- 主题：core
- 目标：建立第一个可启动的 Godot 主场景，并让 RTS 基本输入和暂停由统一入口处理。
- 验收标准：
  - 项目启动后进入 `res://game/main/main.tscn`，并能看到两个 Pawn。
  - `select`、`command`、`toggle_pause` 使用 InputMap，不在业务脚本中硬编码物理按键。
  - 左键只负责选择，右键只负责移动或攻击指令。
  - Space 可以暂停/恢复，暂停期间 Pawn 移动与攻击完全停止。
  - 主场景不直接实现 Pawn 战斗算法，只负责组装和分发命令。
- 范围：`project.godot` 的主场景和 InputMap 配置、`game/main/main.gd`、`game/main/main.tscn`、`game/shared/core/**`。
- 非范围：Autoload、全局事件总线、存档、设置菜单、相机控制、场景切换和大规模单位管理。
- 依赖：`INC-PAWNS-001`；Godot 4.7 InputMap；已有项目显示/拉伸配置。
- 风险：暂停时如果误停止 HUD 和输入处理，玩家无法在暂停状态下达命令；本 Increment 让主场景在暂停时继续处理输入，Pawn/Controller 保持可暂停。
- 实现说明：
  - `project.godot` 配置主场景、1152x648 逻辑视口和 `select`、`command`、`toggle_pause` 三个 InputMap 动作。
  - 主场景负责选中玩家 Pawn、把右键位置解析成移动/攻击目标，并调用 `PlayerController`。
  - `Main.process_mode = ALWAYS` 用于暂停时继续处理 HUD 和输入；Pawn/Controller 设置为 `PROCESS_MODE_PAUSABLE`，暂停时停止物理与 AI。
  - 命中检测只在鼠标事件发生时遍历 `Pawns` 子节点，不在每帧扫描全场景。
  - 主场景根节点由 root 改名为 Main，避免保留 MCP 默认节点名，并便于运行态按 /root/Main 定位场景。
- 变更文件：
  - `project.godot`
  - `game/main/main.gd`
  - `game/main/main.tscn`
  - `game/shared/core/physics_layers.gd`
- 测试证据：
  - `InputMap` 运行态读取：`select`、`command`、`toggle_pause` 均存在且各自有 1 个事件。
  - 暂停移动中的玩家：暂停前位置约为 `(831.37, 408.28)`，暂停 1 秒后位置完全不变；恢复后位置变为 `(828.96, 408.17)` 并继续移动。
  - 暂停移动中的敌人：暂停前位置约为 `(679.58, 356.55)`，暂停 1 秒后位置完全不变；恢复后位置变为 `(681.10, 356.98)`。
  - 暂停后 `PauseStateLabel` 和 `PauseOverlay` 正确切换，恢复时覆盖层消失。
  - `validate`：主脚本、Pawn 脚本、四个场景和主场景信号检查全部通过；运行日志无错误。
  - 复验（运行态）：current_scene 根节点名称为 Main；InputMap 的 select、command、toggle_pause 三个动作各存在 1 个事件。
  - 复验（暂停冻结）：暂停瞬间玩家位置 (769.16, 347.91)、敌人位置 (426.34, 282.52)，等待 1.2 秒后两者数值完全不变；再次按 Space 恢复后位置继续变化（玩家 767.11 到 618.94，敌人 427.81 到 534.74）。
- 验证状态：验证通过
- 验证时间：2026-09-25T13:42:33+08:00
- 已知问题：两个 Pawn 由主场景直接实例化，尚未建立通用单位管理器、相机和场景切换。
- 用户验收：已验收
- 验收时间：2026-09-25T13:42:33+08:00
- Git：main / 待记录 commit hash
- 备注：此 Increment 是 `INC-CROSS-001` 的子 Increment。