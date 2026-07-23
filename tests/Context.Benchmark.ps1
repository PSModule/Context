#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.5' }

<#
    .SYNOPSIS
    Performance benchmark for the Context module's core crypto operations.

    .DESCRIPTION
    Measures the time (in microseconds) per iteration for the three operations that every
    Set-Context / Get-Context call executes: key-pair derivation, seal (encrypt), and
    open (decrypt). Each scenario is repeated $Iterations times and the median is reported.

    Run from the repo root after importing the module:

        Import-Module ./src -Force
        pwsh -NoProfile -File tests/Context.Benchmark.ps1

    .OUTPUTS
    PSCustomObject - one row per scenario with Scenario, Iterations, Median_µs, Min_µs, Max_µs.
#>
[CmdletBinding()]
param(
    # Number of iterations per scenario.
    [Parameter()]
    [int] $Iterations = 1000,

    # Vault name used during the benchmark (cleaned up automatically).
    [Parameter()]
    [string] $BenchmarkVault = 'Benchmark-Perf-Vault'
)

Set-StrictMode -Version Latest

function Measure-MedianMicroseconds {
    param(
        [scriptblock] $ScriptBlock,
        [int] $Iterations
    )

    $samples = [System.Collections.Generic.List[double]]::new($Iterations)
    for ($i = 0; $i -lt $Iterations; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock | Out-Null
        $sw.Stop()
        $samples.Add($sw.Elapsed.TotalMilliseconds * 1000)
    }
    $sorted = $samples | Sort-Object
    $mid = [int]($Iterations / 2)
    return [pscustomobject]@{
        Median_µs = [Math]::Round($sorted[$mid], 1)
        Min_µs    = [Math]::Round(($sorted | Select-Object -First 1), 1)
        Max_µs    = [Math]::Round(($sorted | Select-Object -Last 1), 1)
    }
}

# Ensure bench vault exists and is clean
try {
    Remove-ContextVault -Name $BenchmarkVault -Confirm:$false -ErrorAction SilentlyContinue
} catch {}
Set-ContextVault -Name $BenchmarkVault | Out-Null

$results = [System.Collections.Generic.List[pscustomobject]]::new()

Write-Host "Running Context benchmark ($Iterations iterations each)..." -ForegroundColor Cyan

# --- Key-pair derivation (New-SodiumKeyPair with seed) ---
$seed = 'BenchmarkSeedValue'
$kpStats = Measure-MedianMicroseconds -Iterations $Iterations -ScriptBlock {
    New-SodiumKeyPair -Seed $seed
}
$results.Add([pscustomobject]@{
    Scenario   = 'New-SodiumKeyPair -Seed'
    Iterations = $Iterations
    Median_µs  = $kpStats.Median_µs
    Min_µs     = $kpStats.Min_µs
    Max_µs     = $kpStats.Max_µs
})

# --- Seal (encrypt via Set-Context) ---
$sealStats = Measure-MedianMicroseconds -Iterations $Iterations -ScriptBlock {
    Set-Context -ID 'bench-ctx' -Context @{ Value = 'benchmark' } -Vault $BenchmarkVault
}
$results.Add([pscustomobject]@{
    Scenario   = 'Set-Context (seal)'
    Iterations = $Iterations
    Median_µs  = $sealStats.Median_µs
    Min_µs     = $sealStats.Min_µs
    Max_µs     = $sealStats.Max_µs
})

# --- Open (decrypt via Get-Context) ---
Set-Context -ID 'bench-ctx' -Context @{ Value = 'benchmark' } -Vault $BenchmarkVault
$openStats = Measure-MedianMicroseconds -Iterations $Iterations -ScriptBlock {
    Get-Context -ID 'bench-ctx' -Vault $BenchmarkVault
}
$results.Add([pscustomobject]@{
    Scenario   = 'Get-Context (open/decrypt)'
    Iterations = $Iterations
    Median_µs  = $openStats.Median_µs
    Min_µs     = $openStats.Min_µs
    Max_µs     = $openStats.Max_µs
})

# Cleanup
try {
    Remove-ContextVault -Name $BenchmarkVault -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

Write-Host ''
Write-Host '=== Context Benchmark Results ===' -ForegroundColor Green
$results | Format-Table -AutoSize
$results
