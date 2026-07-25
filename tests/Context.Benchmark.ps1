#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.5' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Benchmark scripts should emit visible progress and result output.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSProvideCommentHelp', '',
    Scope = 'Function',
    Target = 'Measure-BenchmarkMeasurement',
    Justification = 'Private helper function in a test script.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseConsistentIndentation', '',
    Justification = 'Aligned hashtable literals trigger a false positive in this script.'
)]
[CmdletBinding()]
param(
    # Number of iterations per scenario.
    [Parameter()]
    [int] $Iterations = 1000,

    # Vault name used during the benchmark (cleaned up automatically).
    [Parameter()]
    [string] $BenchmarkVault = 'Benchmark-Perf-Vault',

    # Optional module path to import before benchmarking.
    [Parameter()]
    [string] $ContextModulePath
)

Set-StrictMode -Version Latest

if ($ContextModulePath) {
    Import-Module -Name $ContextModulePath -Force -ErrorAction Stop
}

$loadedContextModule = Get-Module -Name Context | Sort-Object Version -Descending | Select-Object -First 1
if (-not $loadedContextModule) {
    throw 'Import the Context module under test before running this benchmark, or pass -ContextModulePath.'
}

function Measure-BenchmarkMeasurement {
    param(
        [scriptblock] $ScriptBlock,
        [int] $Iterations
    )

    $samples = [System.Collections.Generic.List[double]]::new($Iterations)
    for ($i = 0; $i -lt $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock | Out-Null
        $stopwatch.Stop()
        $samples.Add($stopwatch.Elapsed.TotalMilliseconds * 1000)
    }

    $sorted = $samples | Sort-Object
    $mid = [int] ($Iterations / 2)

    return [pscustomobject]@{
        Median_µs = [Math]::Round($sorted[$mid], 1)
        Min_µs    = [Math]::Round(($sorted | Select-Object -First 1), 1)
        Max_µs    = [Math]::Round(($sorted | Select-Object -Last 1), 1)
    }
}

try {
    Remove-ContextVault -Name $BenchmarkVault -Confirm:$false -ErrorAction SilentlyContinue
} catch {
    Write-Verbose "Benchmark setup cleanup skipped: $($_.Exception.Message)"
}

Set-ContextVault -Name $BenchmarkVault | Out-Null

$results = [System.Collections.Generic.List[pscustomobject]]::new()

Write-Host "Running Context benchmark ($Iterations iterations each)..." -ForegroundColor Cyan
Write-Host "Benchmarking Context module: $($loadedContextModule.Path)" -ForegroundColor Cyan

$seed = 'BenchmarkSeedValue'
$kpStats = Measure-BenchmarkMeasurement -Iterations $Iterations -ScriptBlock {
    New-SodiumKeyPair -Seed $seed
}
$results.Add([pscustomobject]@{
    Scenario   = 'New-SodiumKeyPair -Seed'
    Iterations = $Iterations
    Median_µs  = $kpStats.Median_µs
    Min_µs     = $kpStats.Min_µs
    Max_µs     = $kpStats.Max_µs
})

$sealStats = Measure-BenchmarkMeasurement -Iterations $Iterations -ScriptBlock {
    Set-Context -ID 'bench-ctx' -Context @{ Value = 'benchmark' } -Vault $BenchmarkVault
}
$results.Add([pscustomobject]@{
    Scenario   = 'Set-Context (seal)'
    Iterations = $Iterations
    Median_µs  = $sealStats.Median_µs
    Min_µs     = $sealStats.Min_µs
    Max_µs     = $sealStats.Max_µs
})

Set-Context -ID 'bench-ctx' -Context @{ Value = 'benchmark' } -Vault $BenchmarkVault
$openStats = Measure-BenchmarkMeasurement -Iterations $Iterations -ScriptBlock {
    Get-Context -ID 'bench-ctx' -Vault $BenchmarkVault
}
$results.Add([pscustomobject]@{
    Scenario   = 'Get-Context (open/decrypt)'
    Iterations = $Iterations
    Median_µs  = $openStats.Median_µs
    Min_µs     = $openStats.Min_µs
    Max_µs     = $openStats.Max_µs
})

try {
    Remove-ContextVault -Name $BenchmarkVault -Confirm:$false -ErrorAction SilentlyContinue
} catch {
    Write-Verbose "Benchmark cleanup skipped: $($_.Exception.Message)"
}

Write-Host ''
Write-Host '=== Context Benchmark Results ===' -ForegroundColor Green
$results | Format-Table -AutoSize
$results
