<#
    Wringer — the verification gate.

    This is the definition of done. AGENTS.md §1.8: run it, paste the real
    output, and never adjust the script to make a task pass.

    Every stage reports PASS, FAIL, or SKIP.

      PASS  the stage ran and succeeded
      FAIL  the stage ran and failed — the task is not done
      SKIP  the stage does not exist yet; the code it checks has not been
            written. A SKIP is never a pass, and never fails a task.

    Usage, from the repository root:

        .\scripts\verify.ps1

    If PowerShell blocks the script, either run it with
    `pwsh -ExecutionPolicy Bypass -File .\scripts\verify.ps1`, or unblock
    your own scripts once with
    `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
#>

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$summary = [ordered]@{}

function Invoke-Stage {
    param(
        [Parameter(Mandatory)][string]      $Name,
        [Parameter(Mandatory)][scriptblock] $Action,
        [string]                            $Requires
    )

    Write-Host ""
    Write-Host "=== $Name ===" -ForegroundColor Cyan

    if ($Requires -and -not (Test-Path -LiteralPath $Requires)) {
        Write-Host "SKIP - '$Requires' does not exist yet" -ForegroundColor Yellow
        $summary[$Name] = 'SKIP'
        return
    }

    # Judge each stage on its own result, never on a leftover exit code.
    #
    # A native command that is missing from PATH fails as a *non-terminating*
    # error: it sets $? to $false but leaves $LASTEXITCODE untouched. Without
    # clearing it first, the stage inherits the previous stage's 0 and reports a
    # false PASS. So clear $LASTEXITCODE, capture $? immediately after the
    # action, and require a code of 0 to have been *set* by that action.
    #
    # A stage action must own its result explicitly: it runs a native command
    # whose exit code it means, or it ends with `exit <code>`. A stage that
    # leaves no exit code behind has not stated a result, and is reported FAIL
    # rather than passed — that is the contract in docs/DECISIONS.md ADR-011,
    # and it is what keeps a PowerShell-only stage script from passing by
    # accident.
    $global:LASTEXITCODE = $null
    $ok = $true
    try {
        & $Action
        $ok = $?
    }
    catch {
        $ok = $false
        Write-Host "      threw: $($_.Exception.Message)" -ForegroundColor Red
    }
    $code = $global:LASTEXITCODE

    if ($ok -and $null -ne $code -and $code -eq 0) {
        Write-Host "-- PASS: $Name" -ForegroundColor Green
        $summary[$Name] = 'PASS'
    }
    else {
        $detail = if ($null -ne $code) {
            "exit $code"
        } else {
            'no exit code - the stage must own its result (ADR-011)'
        }
        Write-Host "-- FAIL: $Name ($detail)" -ForegroundColor Red
        $summary[$Name] = 'FAIL'
    }
}

# ---------------------------------------------------------------------------
# Stages. Add new ones here as the project grows; keep the order cheap-to-slow.
# Adding a stage is a change to scripts/ — AGENTS.md rule 7 requires explicit
# approval for it, exactly as for any other edit to this file.
# ---------------------------------------------------------------------------

Invoke-Stage -Name 'Rust formatting' -Requires 'src-tauri/Cargo.toml' -Action {
    cargo fmt --manifest-path src-tauri/Cargo.toml -- --check
}

Invoke-Stage -Name 'Rust lints' -Requires 'src-tauri/Cargo.toml' -Action {
    cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings
}

Invoke-Stage -Name 'Rust tests' -Requires 'src-tauri/Cargo.toml' -Action {
    cargo test --manifest-path src-tauri/Cargo.toml
}

Invoke-Stage -Name 'JS lint' -Requires 'package.json' -Action {
    npm --silent run lint
}

Invoke-Stage -Name 'JS tests' -Requires 'package.json' -Action {
    npm --silent test
}

# No-network guard. Built by T-032; SKIPs until then.
Invoke-Stage -Name 'No network deps' -Requires 'scripts/check-no-network.ps1' -Action {
    & (Join-Path $root 'scripts/check-no-network.ps1')
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "===============================" -ForegroundColor Cyan
Write-Host " verify.ps1" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

foreach ($stage in $summary.GetEnumerator()) {
    $colour = switch ($stage.Value) {
        'PASS'  { 'Green' }
        'FAIL'  { 'Red' }
        default { 'Yellow' }
    }
    Write-Host ("  {0,-18} {1}" -f $stage.Key, $stage.Value) -ForegroundColor $colour
}

Write-Host ""

if (@($summary.Values | Where-Object { $_ -eq 'FAIL' }).Count -gt 0) {
    Write-Host "FAILED. Fix the cause; do not adjust this script to pass." -ForegroundColor Red
    exit 1
}

if ($summary.Values -contains 'SKIP') {
    Write-Host "All runnable stages passed. Skipped stages are not yet written." -ForegroundColor Green
    exit 0
}

Write-Host "All stages passed." -ForegroundColor Green
exit 0
