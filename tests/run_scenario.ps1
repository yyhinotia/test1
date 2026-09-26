#!/usr/bin/env pwsh
<#
.SYNOPSIS
    按名字启动 tests/ 下的场景化测试入口（INC-TESTING-017）。

.DESCRIPTION
    这个脚本存在的唯一理由，是消除「按 F5 跑成项目主场景」这个坑：

      F5  ->  game/main/main.tscn                默认进入试炼傀儡秘境 + 完整 HUD（看起来就像旧的傀儡测试）
      F6  ->  当前打开的 tests/scenario_*.tscn   才走测试入口：隐藏非 Build 菜单，并显示测试横幅

    需要提供 Godot 可执行文件：用 -Godot 参数或 GODOT_BIN 环境变量指定。
    仓库内不记录本机 Godot 绝对路径。

.PARAMETER Scenario
    入口名。可用简写：1v1 / 1v2 / 1v3 / switch / loadout / first-clear / replay / problem，
    也可以直接给文件名（可省略 .tscn、tests/ 前缀与 scenario_ 前缀）。

.PARAMETER Godot
    Godot 4.7.x 可执行文件路径，默认取 GODOT_BIN。

.PARAMETER PauseOnStart
    开局即暂停，玩家按 Space 再开始实时战斗（INC-TESTING-015）。

.PARAMETER List
    只列出可用入口，不启动游戏。

.EXAMPLE
    pwsh -File tests/run_scenario.ps1 -Scenario 1v2 -Godot $env:GODOT_BIN

.EXAMPLE
    pwsh -File tests/run_scenario.ps1 -Scenario replay -PauseOnStart -Godot $env:GODOT_BIN

.EXAMPLE
    pwsh -File tests/run_scenario.ps1 -List
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Scenario = '',

    [string]$Godot = $env:GODOT_BIN,

    [switch]$PauseOnStart,

    [switch]$List
)

$ErrorActionPreference = 'Stop'

$testsDir = $PSScriptRoot
$projectRoot = Split-Path -Parent $testsDir

# 简写 -> 入口文件。名称只做路由，不构造任何状态：状态全部写在 .tscn 的导出参数里。
$shortcuts = [ordered]@{
    '1v1'         = 'scenario_build_test_1v1.tscn'
    '1v2'         = 'scenario_build_test_1v2.tscn'
    '1v3'         = 'scenario_build_test_1v3.tscn'
    'switch'      = 'scenario_build_loadout_switch.tscn'
    'loadout'     = 'scenario_build_loadout_switch.tscn'
    'first-clear' = 'scenario_first_clear_reward.tscn'
    'first_clear' = 'scenario_first_clear_reward.tscn'
    'replay'      = 'scenario_build_replay.tscn'
    'problem'     = 'scenario_problem_dungeon.tscn'
    'dungeon'     = 'scenario_problem_dungeon.tscn'
}

function Show-Scenarios {
    Write-Host 'tests/ 可用入口：' -ForegroundColor Cyan
    foreach ($item in $shortcuts.GetEnumerator()) {
        Write-Host ('  {0,-12} -> tests/{1}' -f $item.Key, $item.Value)
    }
    Write-Host '  也接受任意 tests/scenario_*.tscn 文件名。'
}

if ($List) {
    Show-Scenarios
    exit 0
}

if ([string]::IsNullOrWhiteSpace($Scenario)) {
    Write-Host 'ERROR: 未指定入口。请用 -Scenario <名字>，或用 -List 查看可用入口。' -ForegroundColor Red
    Show-Scenarios
    exit 2
}
if ([string]::IsNullOrWhiteSpace($Godot)) {
    Write-Host 'ERROR: 未提供 Godot 可执行文件。请使用 -Godot <path> 或设置 GODOT_BIN 环境变量。' -ForegroundColor Red
    exit 2
}
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    Write-Host "ERROR: Godot 可执行文件不存在：$Godot" -ForegroundColor Red
    exit 2
}

$key = $Scenario.Trim().ToLowerInvariant()
if ($shortcuts.Contains($key)) {
    $fileName = $shortcuts[$key]
} else {
    $fileName = Split-Path -Leaf $Scenario.Trim()
    if (-not $fileName.EndsWith('.tscn')) { $fileName = $fileName + '.tscn' }
    if (-not $fileName.StartsWith('scenario_')) { $fileName = 'scenario_' + $fileName }
}

$scenePath = Join-Path $testsDir $fileName
if (-not (Test-Path -LiteralPath $scenePath -PathType Leaf)) {
    Write-Host "ERROR: 找不到入口：tests/$fileName" -ForegroundColor Red
    Show-Scenarios
    exit 2
}

$godotArgs = @('--path', $projectRoot, "res://tests/$fileName")
if ($PauseOnStart) { $godotArgs += @('--', '--pause-on-start') }

Write-Host ('RUN  {0} {1}' -f $Godot, ($godotArgs -join ' ')) -ForegroundColor Cyan
if ($PauseOnStart) {
    Write-Host '开局暂停已开启：按 Space 开始实时战斗。' -ForegroundColor Yellow
}
& $Godot @godotArgs
exit $LASTEXITCODE
