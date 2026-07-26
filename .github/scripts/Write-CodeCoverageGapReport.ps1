<#
    .SYNOPSIS
    Creates a coverage-gap report from Process-PSModule code coverage artifacts.

    .DESCRIPTION
    Reads all *-CodeCoverage-Report.json files under a root folder, summarizes the
    current coverage status, groups missed commands into high-level categories, and
    writes both markdown and JSON outputs for workflow logs, step summaries, and
    uploaded artifacts.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidLongLines', '',
    Justification = 'Report recommendation strings are clearer when kept intact.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSProvideCommentHelp', '',
    Scope = 'Function',
    Target = 'Get-MissedCommandCategory',
    Justification = 'Private helper in a workflow reporting script.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSProvideCommentHelp', '',
    Scope = 'Function',
    Target = 'Get-RecommendedScenario',
    Justification = 'Private helper in a workflow reporting script.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSProvideCommentHelp', '',
    Scope = 'Function',
    Target = 'ConvertTo-MarkdownTable',
    Justification = 'Private helper in a workflow reporting script.'
)]
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $CoverageRoot,

    [Parameter(Mandatory)]
    [string] $ReportOutputPath,

    [Parameter()]
    [string] $RunId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MissedCommandCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject] $Command
    )

    $commandText = [string]$Command.Command

    if (
        $commandText -match 'Write-Debug' -or
        $commandText -match 'Import-PowerShellDataFile' -or
        $commandText -match '\$script:PSModuleInfo' -or
        $commandText -match '\[classes\]' -or
        $commandText -match 'return \$this\.Name' -or
        $commandText -match '\$this\.(ID|Path|Vault|Context|Name)\s*='
    ) {
        return 'Module bootstrap and type initialization'
    }

    if (
        $commandText -match 'Get-Module -Name Sodium' -or
        $commandText -match 'Import-Module -Name Sodium' -or
        $commandText -match 'Get-Command -Name \$commandName' -or
        $commandText -match 'Loaded Sodium version' -or
        $commandText -match 'Required Sodium command'
    ) {
        return 'Dependency loading and validation edge cases'
    }

    if (
        $commandText -match 'Get-ContentNonLocking' -or
        $commandText -match 'IO error reading file' -or
        $commandText -match 'Fallback also failed' -or
        $commandText -match 'Error reading file'
    ) {
        return 'File I/O recovery and error handling'
    }

    if (
        $commandText -match 'ContextFileIndexCache' -or
        $commandText -match '\.Remove\(' -or
        $commandText -match 'if \(\$null -eq \$script:ContextFileIndexCache'
    ) {
        return 'Cache initialization and eviction edge cases'
    }

    if (
        $commandText -match 'CompletionResult' -or
        $commandText -match 'wordToComplete' -or
        $commandText -match 'fakeBoundParameter' -or
        $commandText -match 'Get-ContextInfo -Vault \$vault' -or
        $commandText -match 'Get-ContextVault -ErrorAction SilentlyContinue'
    ) {
        return 'Shell completion and discovery helpers'
    }

    if (
        $commandText -match 'Write-Verbose' -or
        $commandText -match 'Format-List' -or
        $commandText -match 'Out-String -Stream'
    ) {
        return 'Verbose and diagnostic-only output'
    }

    if (
        $commandText -match 'ConvertTo-SecureString -String' -or
        $commandText -match 'Convert-ContextHashtableToObjectRecursive' -or
        $commandText -match 'Failed to convert hashtable to object' -or
        $commandText -match 'Failed to convert JSON to object' -or
        $commandText -match 'Failed to convert context object to hashtable' -or
        $commandText -match 'Failed to convert object to JSON'
    ) {
        return 'Serialization and conversion edge cases'
    }

    if (
        $commandText -match 'An ID is required' -or
        $commandText -match 'Get-Context -ID \$ID -Vault \$Vault' -or
        $commandText -match 'Context file does not exist' -or
        $commandText -match 'Write-Warning' -or
        $commandText -match 'continue$' -or
        $commandText -match 'throw '
    ) {
        return 'Validation, warnings, and pass-thru user flows'
    }

    return 'Residual potential user-facing gap'
}

function Get-RecommendedScenario {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Category
    )

    switch ($Category) {
        'Module bootstrap and type initialization' {
            'Verify whether module import/type-construction paths need explicit coverage or should be excluded as non-user bootstrap code.'
        }
        'Dependency loading and validation edge cases' {
            'Add isolated tests for no-Sodium, older-Sodium, and missing-command sessions if those environment guards are intended to stay under coverage.'
        }
        'File I/O recovery and error handling' {
            'Add fault-injection tests for shard/context read failures to cover the non-locking fallback and terminal throw branches.'
        }
        'Cache initialization and eviction edge cases' {
            'Add direct or indirect tests that hit empty-cache clear/remove paths and cache invalidation without prior warmup.'
        }
        default {
            'Add a user-flow test that reaches this missed command through a public cmdlet rather than a private helper.'
        }
    }
}

function ConvertTo-MarkdownTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]] $Rows,

        [Parameter(Mandatory)]
        [string[]] $Columns
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return @('| Status | Details |', '| --- | --- |', '| info | No rows |')
    }

    $header = '| ' + ($Columns -join ' | ') + ' |'
    $separator = '| ' + (($Columns | ForEach-Object { '---' }) -join ' | ') + ' |'
    $lines = foreach ($row in $Rows) {
        $values = foreach ($column in $Columns) {
            $value = $row.$column
            if ($null -eq $value) {
                ''
            } else {
                ([string]$value).Replace("`r", ' ').Replace("`n", '<br>')
            }
        }
        '| ' + ($values -join ' | ') + ' |'
    }

    return @($header, $separator) + $lines
}

$reportRoot = Resolve-Path -Path $CoverageRoot -ErrorAction SilentlyContinue
$reportDirectory = New-Item -Path $ReportOutputPath -ItemType Directory -Force
$markdownPath = Join-Path -Path $reportDirectory.FullName -ChildPath 'CodeCoverage-MissedPaths.md'
$jsonPath = Join-Path -Path $reportDirectory.FullName -ChildPath 'CodeCoverage-MissedPaths.json'

$reportFiles = @()
if ($reportRoot) {
    $reportFiles = Get-ChildItem -Path $reportRoot.Path -Recurse -Filter '*-CodeCoverage-Report.json' | Sort-Object FullName
}

$report = [ordered]@{
    RunId               = $RunId
    GeneratedAtUtc      = [DateTime]::UtcNow.ToString('o')
    CoverageArtifacts   = @()
    MissedCommandGroups = @()
    Recommendation      = ''
}

if ($reportFiles.Count -eq 0) {
    $report.Recommendation = (
        'No code coverage artifacts were found. ' +
        'Investigate the coverage upload path before changing the threshold.'
    )
    $runLabel = 'Run: unknown'
    if ($RunId) {
        $runLabel = "Run: $RunId"
    }
    $markdown = @(
        '# Code coverage missed-path report',
        '',
        $runLabel,
        '',
        'No `*-CodeCoverage-Report.json` artifacts were found.',
        '',
        '**Recommendation:** Investigate artifact publication before adjusting coverage requirements.'
    )

    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM
    $markdown | Set-Content -Path $markdownPath -Encoding utf8NoBOM
    $markdown | ForEach-Object { Write-Output $_ }
    if ($env:GITHUB_STEP_SUMMARY) {
        $markdown | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding utf8NoBOM
    }
    return
}

$coverageRows = [System.Collections.Generic.List[object]]::new()
$uniqueMissedCommands = @{}

foreach ($reportFile in $reportFiles) {
    $coverage = Get-Content -Path $reportFile.FullName -Raw | ConvertFrom-Json
    $artifactName = $reportFile.Directory.Name
    $missedCommands = @($coverage.CommandsMissed)

    $artifactRecord = [pscustomobject]@{
        Artifact              = $artifactName
        CoveragePercent       = [math]::Round([double]$coverage.CoveragePercent, 2)
        CoveragePercentTarget = [double]$coverage.CoveragePercentTarget
        CommandsAnalyzed      = [int]$coverage.CommandsAnalyzedCount
        CommandsExecuted      = [int]$coverage.CommandsExecutedCount
        CommandsMissed        = [int]$coverage.CommandsMissedCount
        FilesAnalyzed         = [int]$coverage.FilesAnalyzedCount
    }
    $report.CoverageArtifacts += $artifactRecord
    $coverageRows.Add([pscustomobject]@{
            Artifact = $artifactRecord.Artifact
            Coverage = '{0}%' -f $artifactRecord.CoveragePercent
            Target   = '{0}%' -f $artifactRecord.CoveragePercentTarget
            Missed   = $artifactRecord.CommandsMissed
            Files    = $artifactRecord.FilesAnalyzed
        })

    foreach ($missedCommand in $missedCommands) {
        $key = '{0}|{1}|{2}' -f $artifactName, $missedCommand.Line, $missedCommand.Command
        if (-not $uniqueMissedCommands.ContainsKey($key)) {
            $category = Get-MissedCommandCategory -Command $missedCommand
            $uniqueMissedCommands[$key] = [pscustomobject]@{
                Artifact = $artifactName
                Line     = [int]$missedCommand.Line
                Command  = [string]$missedCommand.Command
                Category = $category
            }
        }
    }
}

$groupedMisses = $uniqueMissedCommands.Values | Group-Object Category | Sort-Object Name
$groupRows = [System.Collections.Generic.List[object]]::new()
$candidateScenarioRows = [System.Collections.Generic.List[object]]::new()

foreach ($group in $groupedMisses) {
    $sampleCommands = $group.Group |
        Sort-Object Artifact, Line |
        Select-Object -First 5 |
        ForEach-Object { '{0}:{1} {2}' -f $_.Artifact, $_.Line, $_.Command }

    $reportGroup = [pscustomobject]@{
        Category       = $group.Name
        Count          = $group.Count
        SampleCommands = $sampleCommands
        Recommendation = Get-RecommendedScenario -Category $group.Name
    }
    $report.MissedCommandGroups += $reportGroup

    $groupRows.Add([pscustomobject]@{
            Category = $reportGroup.Category
            Count    = $reportGroup.Count
            Examples = ($sampleCommands -join '<br>')
        })

    $candidateScenarioRows.Add([pscustomobject]@{
            Category     = $reportGroup.Category
            NextScenario = $reportGroup.Recommendation
        })
}

$userFlowGroup = $report.MissedCommandGroups | Where-Object {
    $_.Category -in @(
        'Validation, warnings, and pass-thru user flows',
        'Residual potential user-facing gap'
    )
}
if ($null -ne $userFlowGroup -and @($userFlowGroup).Count -gt 0) {
    $report.Recommendation = 'Keep the 85% threshold and add tests for the remaining potential user-facing gaps before considering any reduction.'
} else {
    $report.Recommendation = (
        'The remaining misses are concentrated in bootstrap, dependency-guard, cache-edge, ' +
        'and fault-injection paths. If those are not considered user flows, consider lowering ' +
        'the threshold or excluding bootstrap/debug-only code from coverage.'
    )
}

$markdown = [System.Collections.Generic.List[string]]::new()
$null = $markdown.Add('# Code coverage missed-path report')
$null = $markdown.Add('')
if ($RunId) {
    $null = $markdown.Add("Run: $RunId")
    $null = $markdown.Add('')
}
$null = $markdown.Add('## Coverage artifacts')
$tableLines = ConvertTo-MarkdownTable -Rows $coverageRows.ToArray() -Columns @('Artifact', 'Coverage', 'Target', 'Missed', 'Files')
foreach ($line in $tableLines) {
    $null = $markdown.Add([string]$line)
}
$null = $markdown.Add('')
$null = $markdown.Add('## Missed command groups')
$tableLines = ConvertTo-MarkdownTable -Rows $groupRows.ToArray() -Columns @('Category', 'Count', 'Examples')
foreach ($line in $tableLines) {
    $null = $markdown.Add([string]$line)
}
$null = $markdown.Add('')
$null = $markdown.Add('## Candidate next scenarios')
$tableLines = ConvertTo-MarkdownTable -Rows $candidateScenarioRows.ToArray() -Columns @('Category', 'NextScenario')
foreach ($line in $tableLines) {
    $null = $markdown.Add([string]$line)
}
$null = $markdown.Add('')
$null = $markdown.Add('## Recommendation')
$null = $markdown.Add($report.Recommendation)

$report | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM
$markdown | Set-Content -Path $markdownPath -Encoding utf8NoBOM

Write-Output '=== Code coverage missed-path report ==='
$markdown | ForEach-Object { Write-Output $_ }

if ($env:GITHUB_STEP_SUMMARY) {
    $markdown | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding utf8NoBOM
}
