#!/usr/bin/env pwsh
<#
.SYNOPSIS
    test1 项目统一自动化测试入口（Windows / PowerShell）。

.DESCRIPTION
    一条命令跑完两类测试并汇总退出码：
      - GdUnit4 三层测试：test/unit、test/integration、test/gameplay
      - 自建 headless 回归套件：test/headless/*_test.gd
    退出码 0 表示全部通过，非 0 表示存在失败用例或执行错误。

    需要提供 Godot 可执行文件：用 -Godot 参数或 GODOT_BIN 环境变量指定。
    仓库内不记录本机 Godot 绝对路径。

.EXAMPLE
    pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN

.EXAMPLE
    pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer unit

.EXAMPLE
    pwsh -File test/run_tests.ps1 -Godot $env:GODOT_BIN -Layer headless
#>
[CmdletBinding()]
param(
    [ValidateSet('all', 'unit', 'integration', 'gameplay', 'headless')]
    [string]$Layer = 'all',

    [string]$Godot = $env:GODOT_BIN,

    [string]$ReportDir = 'reports/gdunit'
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$gdUnitLayers = @('unit', 'integration', 'gameplay')

if ([string]::IsNullOrWhiteSpace($Godot)) {
    Write-Host 'ERROR: 未提供 Godot 可执行文件。请使用 -Godot <path> 或设置 GODOT_BIN 环境变量。' -ForegroundColor Red
    exit 2
}
if (-not (Test-Path -LiteralPath $Godot -PathType Leaf)) {
    Write-Host "ERROR: Godot 可执行文件不存在：$Godot" -ForegroundColor Red
    exit 2
}

function Invoke-Godot {
    param([string[]]$GodotArgs)
    $output = & $Godot @GodotArgs 2>&1 | Out-String
    # GdUnit4 的控制台报告带 ANSI 颜色转义，必须先剥离再做文本解析。
    $clean = $output -replace "\x1B\[[0-9;?]*[ -/]*[@-~]", ''
    return [pscustomobject]@{ Output = $clean; ExitCode = $LASTEXITCODE }
}

## 打印失败用例及其后续上下文行，便于直接读出断言差异（期望值 / 实际值）。
function Show-FailureContext {
    param(
        [string]$Text,
        [int]$ContextLines = 3,
        [int]$MaxMatches = 4
    )
    $lines = $Text -split "`n"
    $shown = 0
    for ($i = 0; $i -lt $lines.Count -and $shown -lt $MaxMatches; $i++) {
        if ($lines[$i] -match 'FAILED|SCRIPT ERROR|Parse Error|^ERROR: .*test') {
            $shown += 1
            $last = [Math]::Min($i + $ContextLines, $lines.Count - 1)
            $lines[$i..$last] |
                Where-Object { $_ -notmatch 'Failed to open log file' } |
                ForEach-Object { Write-Host "           $($_.Trim())" -ForegroundColor DarkRed }
        }
    }
}

$gdUnitTotal = 0
$gdUnitFailures = 0
$gdUnitBroken = @()
$headlessSuites = 0
$headlessAssertions = 0
$headlessFailures = @()
$ranAny = $false

Write-Host '=== test1 自动化测试 ===' -ForegroundColor Cyan
Write-Host "Godot : $Godot"
Write-Host "Layer : $Layer"
Write-Host ''

if ($Layer -eq 'all' -or $Layer -in $gdUnitLayers) {
    $layersToRun = if ($Layer -eq 'all') { $gdUnitLayers } else { @($Layer) }
    foreach ($current in $layersToRun) {
        $ranAny = $true
        $target = "res://test/$current"
        $result = Invoke-Godot @('--headless', '--path', $projectRoot, '-s',
            'res://addons/gdUnit4/bin/GdUnitCmdTool.gd',
            '-a', $target, '-rd', "res://$ReportDir/$current", '--ignoreHeadlessMode')

        $summary = [regex]::Match($result.Output, 'Overall Summary:\s*(\d+) test cases\s*\|\s*(\d+) errors\s*\|\s*(\d+) failures')
        if (-not $summary.Success) {
            $headlessFailures += "GdUnit4/$current (无测试摘要，退出码 $($result.ExitCode))"
            $gdUnitBroken += $current
            Write-Host ("[GdUnit4] {0,-12} ... ERROR (exit={1})" -f $current, $result.ExitCode) -ForegroundColor Red
            Show-FailureContext -Text $result.Output
            Write-Host '           --- 原始输出末尾 ---' -ForegroundColor DarkRed
            ($result.Output -split "`n" | Where-Object { $_.Trim() -ne '' -and $_ -notmatch 'Failed to open log file' } |
                Select-Object -Last 12) | ForEach-Object { Write-Host "           $($_.Trim())" -ForegroundColor DarkRed }
            continue
        }

        $cases = [int]$summary.Groups[1].Value
        $errors = [int]$summary.Groups[2].Value
        $failures = [int]$summary.Groups[3].Value
        $gdUnitTotal += $cases
        $gdUnitFailures += ($errors + $failures)

        if ($result.ExitCode -eq 0 -and $failures -eq 0 -and $errors -eq 0) {
            Write-Host ("[GdUnit4] {0,-12} ... PASS ({1} cases)" -f $current, $cases) -ForegroundColor Green
        }
        else {
            Write-Host ("[GdUnit4] {0,-12} ... FAIL ({1} cases, {2} errors, {3} failures)" -f $current, $cases, $errors, $failures) -ForegroundColor Red
            Show-FailureContext -Text $result.Output
        }
    }
}

if ($Layer -eq 'all' -or $Layer -eq 'headless') {
    $ranAny = $true
    $suitesDir = Join-Path $projectRoot 'test/headless'
    $suites = Get-ChildItem -Path $suitesDir -Filter '*_test.gd' -File | Sort-Object Name
    Write-Host ''
    foreach ($suite in $suites) {
        $headlessSuites += 1
        $target = "res://test/headless/$($suite.Name)"
        $result = Invoke-Godot @('--headless', '--path', $projectRoot, '--script', $target)

        $match = [regex]::Match($result.Output, 'CHECKS=(\d+) FAILURES=(\d+)')
        $checks = if ($match.Success) { [int]$match.Groups[1].Value } else { 0 }
        $failures = if ($match.Success) { [int]$match.Groups[2].Value } else { 0 }
        $headlessAssertions += $checks

        if ($result.ExitCode -eq 0 -and $match.Success -and $failures -eq 0) {
            Write-Host ("[headless] {0,-42} ... PASS (CHECKS={1} FAILURES=0)" -f $suite.Name, $checks) -ForegroundColor Green
        }
        else {
            $headlessFailures += "headless/$($suite.Name) (exit=$($result.ExitCode))"
            Write-Host ("[headless] {0,-42} ... FAIL (exit={1}, CHECKS={2}, FAILURES={3})" -f $suite.Name, $result.ExitCode, $checks, $failures) -ForegroundColor Red
            Show-FailureContext -Text $result.Output
        }
    }
}

if (-not $ranAny) {
    Write-Host "ERROR: 未选择任何测试层级（Layer=$Layer）。" -ForegroundColor Red
    exit 2
}

$totalFailures = $gdUnitFailures + $headlessFailures.Count

Write-Host ''
Write-Host '---------------------------------------------'
Write-Host ("GdUnit4  : {0} cases, {1} failures" -f $gdUnitTotal, $gdUnitFailures)
Write-Host ("headless : {0} suites, {1} assertions, {2} failing suites" -f $headlessSuites, $headlessAssertions, $headlessFailures.Count)
if ($headlessFailures.Count -gt 0) {
    foreach ($failure in $headlessFailures) { Write-Host "  - $failure" -ForegroundColor Red }
}

if ($totalFailures -eq 0) {
    Write-Host 'RESULT: PASS' -ForegroundColor Green
    exit 0
}

Write-Host 'RESULT: FAIL' -ForegroundColor Red
exit 1
