<#
.SYNOPSIS
  RiderOS AI local regression suite (Phase 6, P6c).

.DESCRIPTION
  Runs every automated check of the repository and prints one summary table:

    backend  ruff check, ruff format --check, pytest + coverage gate (app/modules + app/core)
    mobile   flutter analyze, dart format check, flutter test --coverage + coverage gate on lib/
             (generated *.g.dart / *.freezed.dart and lib/l10n excluded)
    e2e      (only with -E2E) flutter drive journey on emulator-5554 with SQL checks

  Coverage gates are "measured value at the end of P6b minus 2 points" (HANDOFF 4.13, decision 8):
  backend 98% -> 96, mobile 96.7% -> 94.7. Raise them when coverage goes up; never lower them to pass.

  Every step runs even when an earlier one fails (use -FailFast to stop at the first failure).
  Exit code: 0 when every step passed, 1 otherwise.

  Needs: Docker Desktop (the backend tests use the compose "db" service; -E2E needs the whole stack),
  uv (on PATH or as "python -m uv"), Flutter on PATH. The backend suite runs with "uv run --locked", so
  an out-of-date uv.lock fails the run instead of being rewritten.

.EXAMPLE
  .\scripts\regression.ps1
.EXAMPLE
  .\scripts\regression.ps1 -Skip mobile
.EXAMPLE
  .\scripts\regression.ps1 -E2E
#>
[CmdletBinding()]
param(
    [ValidateSet('backend', 'mobile')]
    [string[]]$Skip = @(),
    [switch]$E2E,
    [switch]$FailFast,
    [double]$BackendCoverageGate = 96.0,
    [double]$MobileCoverageGate = 94.7,
    [string]$Python = $(if ($env:RIDEROS_PYTHON) { $env:RIDEROS_PYTHON } else { 'python' })
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Results = New-Object System.Collections.Generic.List[object]
$script:Stop = $false

function Add-Result([string]$Suite, [string]$Step, [bool]$Ok, [double]$Seconds, [string]$Note) {
    $Results.Add([pscustomobject]@{
            Suite   = $Suite
            Step    = $Step
            Result  = $(if ($Ok) { 'PASS' } else { 'FAIL' })
            Seconds = [math]::Round($Seconds, 1)
            Note    = $Note
        })
    if (-not $Ok -and $FailFast) { $script:Stop = $true }
}

# Runs a native command in $Dir; the step passes when the exit code is 0.
function Invoke-Step([string]$Suite, [string]$Step, [string]$Dir, [scriptblock]$Command) {
    if ($script:Stop) { return $false }
    Write-Host ""
    Write-Host "==> [$Suite] $Step" -ForegroundColor Cyan
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    Push-Location $Dir
    $ok = $false
    try {
        # Windows PowerShell 5.1 turns native stderr (docker/flutter progress) into error records; with
        # 'Stop' that aborts the step. Judge by the exit code only, and print every line as plain text.
        # Write-Host (not the pipeline) so the output is not returned from this function, and it still
        # lands in a log when the script runs with *> redirection.
        $ErrorActionPreference = 'Continue'
        & $Command 2>&1 | ForEach-Object { Write-Host "$_" }
        $ok = ($LASTEXITCODE -eq 0)
    }
    catch {
        Write-Host $_ -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
    $note = $(if ($ok) { '' } else { "exit $LASTEXITCODE" })
    Add-Result $Suite $Step $ok $watch.Elapsed.TotalSeconds $note
    return $ok
}

# --- leave any active venv -------------------------------------------------------------------------
# A venv left active (e.g. ml/.venv) puts its python, which has no uv, first on PATH and makes uv warn.
# Drop it for this run, like "deactivate"; both values are restored at the end.
$savedVenv = $env:VIRTUAL_ENV
$savedPath = $env:PATH
if ($env:VIRTUAL_ENV) {
    $venvScripts = (Join-Path $env:VIRTUAL_ENV 'Scripts').TrimEnd('\')
    $env:PATH = (($env:PATH -split ';') | Where-Object { $_ -and $_.TrimEnd('\', '/').Replace('/', '\') -ne $venvScripts }) -join ';'
    $env:VIRTUAL_ENV = $null
}

# --- uv: prefer the uv executable, else "<python> -m uv", else "py -3 -m uv" -------------------------
function Test-UvCandidate([string[]]$Prefix) {
    $ErrorActionPreference = 'Continue'
    try {
        $exe = $Prefix[0]
        $rest = @($Prefix | Select-Object -Skip 1) + @('--version')
        & $exe @rest *> $null
        return ($LASTEXITCODE -eq 0)
    }
    catch { return $false }
}
$script:UvPrefix = $null
foreach ($candidate in @(@('uv'), @($Python, '-m', 'uv'), @('py', '-3', '-m', 'uv'))) {
    if (Get-Command $candidate[0] -ErrorAction SilentlyContinue) {
        if (Test-UvCandidate $candidate) { $script:UvPrefix = $candidate; break }
    }
}
if ($script:UvPrefix) { Write-Host "uv: $($script:UvPrefix -join ' ')" }

function Invoke-Uv {
    $exe = $script:UvPrefix[0]
    $rest = @($script:UvPrefix | Select-Object -Skip 1) + $args
    & $exe @rest
}

function Test-PythonSuite([string]$Suite, [string]$Dir, [string[]]$PytestArgs) {
    if ($null -eq $script:UvPrefix) {
        Add-Result $Suite 'uv' $false 0 "uv not found; set -Python or RIDEROS_PYTHON to an interpreter with uv"
        return
    }
    Invoke-Step $Suite 'ruff check' $Dir { Invoke-Uv run --locked ruff check . } | Out-Null
    Invoke-Step $Suite 'ruff format --check' $Dir { Invoke-Uv run --locked ruff format --check . } | Out-Null
    Invoke-Step $Suite 'pytest' $Dir { Invoke-Uv run --locked pytest @PytestArgs } | Out-Null
}

try {
    # --- backend ----------------------------------------------------------------------------------
    if ($Skip -notcontains 'backend') {
        $dbOk = Invoke-Step 'backend' 'compose db + valkey up (healthy)' $Root { docker compose up -d --wait db valkey }
        if ($dbOk) {
            Test-PythonSuite 'backend' (Join-Path $Root 'backend') @(
                '--cov=app/modules', '--cov=app/core', '--cov-report=term:skip-covered',
                "--cov-fail-under=$BackendCoverageGate"
            )
            $last = $Results[$Results.Count - 1]
            if ($last.Step -eq 'pytest') { $last.Note = "coverage gate $BackendCoverageGate%" + $(if ($last.Note) { "; $($last.Note)" } else { '' }) }
        }
    }

    # --- mobile -----------------------------------------------------------------------------------
    if ($Skip -notcontains 'mobile') {
        $mobile = Join-Path $Root 'mobile'
        Invoke-Step 'mobile' 'flutter analyze' $mobile { flutter analyze } | Out-Null
        Invoke-Step 'mobile' 'dart format check' $mobile { dart format --output=none --set-exit-if-changed lib test integration_test test_driver } | Out-Null
        $testsOk = Invoke-Step 'mobile' 'flutter test --coverage' $mobile { flutter test --coverage }
        if ($testsOk -and -not $script:Stop) {
            $lcov = Join-Path $mobile 'coverage\lcov.info'
            $found = 0; $hit = 0; $skipFile = $false
            foreach ($line in [System.IO.File]::ReadLines($lcov)) {
                if ($line.StartsWith('SF:')) {
                    $path = $line.Substring(3).Replace('\', '/')
                    $skipFile = ($path -match '\.g\.dart$|\.freezed\.dart$|(^|/)lib/l10n/')
                }
                elseif (-not $skipFile -and $line.StartsWith('LF:')) { $found += [int]$line.Substring(3) }
                elseif (-not $skipFile -and $line.StartsWith('LH:')) { $hit += [int]$line.Substring(3) }
            }
            $pct = $(if ($found -gt 0) { [math]::Round(100.0 * $hit / $found, 2) } else { 0 })
            $ok = ($found -gt 0 -and $pct -ge $MobileCoverageGate)
            Write-Host "mobile lib/ coverage: $pct% ($hit/$found lines), gate $MobileCoverageGate%"
            Add-Result 'mobile' 'coverage gate' $ok 0 "$pct% ($hit/$found) vs gate $MobileCoverageGate%"
        }
    }

    # --- e2e (opt-in) -----------------------------------------------------------------------------
    if ($E2E) {
        Invoke-Step 'e2e' 'flutter drive app_journey' (Join-Path $Root 'mobile') {
            flutter drive --driver=test_driver/integration_test.dart `
                --target=integration_test/app_journey_test.dart -d emulator-5554
        } | Out-Null
    }
}
finally {
    $env:VIRTUAL_ENV = $savedVenv
    $env:PATH = $savedPath
}

# --- summary --------------------------------------------------------------------------------------
Write-Host ""
Write-Host "==================== Regression summary ====================" -ForegroundColor Cyan
$Results | Format-Table -AutoSize Suite, Step, Result, Seconds, Note | Out-String -Width 200 | Write-Host
$failed = @($Results | Where-Object { $_.Result -eq 'FAIL' })
if ($script:Stop) { Write-Host "Stopped at the first failure (-FailFast)." -ForegroundColor Yellow }
if ($failed.Count -gt 0) {
    Write-Host "REGRESSION FAILED: $($failed.Count) step(s)" -ForegroundColor Red
    exit 1
}
Write-Host "REGRESSION PASSED: $($Results.Count) step(s)" -ForegroundColor Green
exit 0
