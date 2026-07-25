[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Compatibility test scripts should emit visible progress and result output.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidLongLines', '',
    Justification = 'Embedded child-process commands are clearer when kept intact.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSProvideCommentHelp', '',
    Scope = 'Function',
    Target = 'Assert-Equal',
    Justification = 'Private assertion helper in a test script.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSProvideCommentHelp', '',
    Scope = 'Function',
    Target = 'Assert-Null',
    Justification = 'Private assertion helper in a test script.'
)]
<#
    .SYNOPSIS
    Cross-version compatibility test: Sodium 2.2.2 written data readable by Sodium 2.2.5.

    .DESCRIPTION
    Two-part test:

    PART 1 - Crypto stability
      Verifies that New-SodiumKeyPair -Seed produces identical keys in both Sodium versions,
      and that a sealed box produced by 2.2.2 is decryptable by 2.2.5.

    PART 2 - Full stack (Context on-disk format)
      Uses Context 8.1.3 (Sodium 2.2.2) to write a vault and contexts to disk, then uses
      Sodium 2.2.5 directly to re-derive the same keys, read the raw JSON files, and
      decrypt the stored sealed boxes.

    Each phase runs in a child pwsh process to ensure clean module state.
#>
[CmdletBinding()]
param(
    [string] $VaultName = 'XVersionCompat-Test'
)

$ErrorActionPreference = 'Stop'
$tempDir = Join-Path $env:TEMP "sodium-compat-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir | Out-Null

$cryptoResultFile = Join-Path $tempDir 'crypto.json'
$writeResultFile = Join-Path $tempDir 'write.json'
$readResultFile = Join-Path $tempDir 'read.json'

$pass = 0
$fail = 0

function Assert-Equal {
    param($Name, $Expected, $Actual)

    if ("$Actual" -eq "$Expected") {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        Write-Host "         expected : $Expected" -ForegroundColor Red
        Write-Host "         actual   : $Actual" -ForegroundColor Red
        $script:fail++
    }
}

function Assert-Null {
    param($Name, $Actual)

    if ($null -eq $Actual -or "$Actual" -eq '') {
        Write-Host "  [PASS] $Name (null/empty as expected)" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "  [FAIL] $Name - expected null/empty, got: [$Actual]" -ForegroundColor Red
        $script:fail++
    }
}

Write-Host ''
Write-Host '=== Cross-Version Sodium Compatibility Test ===' -ForegroundColor Cyan
Write-Host "Temp dir : $tempDir"
Write-Host ''

Write-Host '--- Part 1a: Seal message + derive keys with Sodium 2.2.2 ---' -ForegroundColor Yellow

$part1aScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Sodium -RequiredVersion 2.2.2 -Force
`$seed = 'CompatibilityTestSeedValue'
`$plaintext = 'Hello from Sodium 2.2.2'
`$kp = New-SodiumKeyPair -Seed `$seed
`$box22 = ConvertTo-SodiumSealedBox -Message `$plaintext -PublicKey `$kp.PublicKey
`$result = @{
    PublicKey = `$kp.PublicKey
    PrivateKey = `$kp.PrivateKey
    SealedBox22 = `$box22
    Plaintext = `$plaintext
}
`$result | ConvertTo-Json | Set-Content '$cryptoResultFile'
Write-Host "Keys derived and message sealed with Sodium 2.2.2"
"@

pwsh -NoProfile -Command $part1aScript
if (-not (Test-Path $cryptoResultFile)) {
    throw 'Part 1a failed: no result file'
}

$c22 = Get-Content $cryptoResultFile -Raw | ConvertFrom-Json
Write-Host "  PublicKey  (2.2.2): $($c22.PublicKey)"
Write-Host "  PrivateKey (2.2.2): $($c22.PrivateKey)"

Write-Host ''
Write-Host '--- Part 1b: Verify keys + unseal 2.2.2 message with Sodium 2.2.5 ---' -ForegroundColor Yellow

$part1bScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Sodium -RequiredVersion 2.2.5 -Force
`$seed = 'CompatibilityTestSeedValue'
`$kp25 = New-SodiumKeyPair -Seed `$seed
`$box22 = '$($c22.SealedBox22)'
`$pubKey = '$($c22.PublicKey)'
`$privKey = '$($c22.PrivateKey)'
`$decrypted = ConvertFrom-SodiumSealedBox -SealedBox `$box22 -PublicKey `$pubKey -PrivateKey `$privKey
`$box25 = ConvertTo-SodiumSealedBox -Message 'Hello from Sodium 2.2.5' -PublicKey `$kp25.PublicKey
`$rt25 = ConvertFrom-SodiumSealedBox -SealedBox `$box25 -PublicKey `$kp25.PublicKey -PrivateKey `$kp25.PrivateKey
`$result = @{
    PublicKey25 = `$kp25.PublicKey
    PrivateKey25 = `$kp25.PrivateKey
    Decrypted22msg = `$decrypted
    Roundtrip25msg = `$rt25
}
`$result | ConvertTo-Json | Set-Content ('$cryptoResultFile' -replace '\.json', '-25.json')
Write-Host "Keys derived and 2.2.2 box decrypted with Sodium 2.2.5"
"@

$cryptoResult25File = $cryptoResultFile -replace '\.json', '-25.json'
pwsh -NoProfile -Command $part1bScript
if (-not (Test-Path $cryptoResult25File)) {
    throw 'Part 1b failed: no result file'
}

$c25 = Get-Content $cryptoResult25File -Raw | ConvertFrom-Json
Write-Host "  PublicKey  (2.2.5): $($c25.PublicKey25)"
Write-Host "  PrivateKey (2.2.5): $($c25.PrivateKey25)"
Write-Host "  Decrypted 2.2.2 msg: $($c25.Decrypted22msg)"
Write-Host "  2.2.5 roundtrip msg: $($c25.Roundtrip25msg)"
Write-Host ''

Write-Host '--- Part 1 Assertions ---' -ForegroundColor Yellow
Assert-Equal 'Key derivation: PublicKey identical' $c22.PublicKey $c25.PublicKey25
Assert-Equal 'Key derivation: PrivateKey identical' $c22.PrivateKey $c25.PrivateKey25
Assert-Equal '2.2.2 sealed box decryptable by 2.2.5' $c22.Plaintext $c25.Decrypted22msg
Assert-Equal '2.2.5 roundtrip works' 'Hello from Sodium 2.2.5' $c25.Roundtrip25msg

Write-Host ''
Write-Host '--- Part 2a: Write vault + contexts with Context 8.1.3 (Sodium 2.2.2) ---' -ForegroundColor Yellow

$part2aScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Sodium -RequiredVersion 2.2.2 -Force
Import-Module Context -Force
Get-ContextVault -Name '$VaultName' -ErrorAction SilentlyContinue | Remove-ContextVault -Confirm:`$false -ErrorAction SilentlyContinue
Set-ContextVault -Name '$VaultName' | Out-Null
Set-Context -ID 'compat-simple' -Context @{ Greeting = 'Hello'; Number = 42 } -Vault '$VaultName'
Set-Context -ID 'compat-secure' -Context @{ Token = ('secret123' | ConvertTo-SecureString -AsPlainText -Force) } -Vault '$VaultName'
Set-Context -ID 'compat-nulls' -Context @{ Present = 'yes'; Absent = `$null } -Vault '$VaultName'
`$vault = Get-ContextVault -Name '$VaultName'
`$shardPath = Join-Path `$vault.Path 'shard'
`$result = @{
    VaultPath = `$vault.Path
    ShardPath = `$shardPath
    ShardContent = (Get-Content `$shardPath -Raw).Trim()
    MachineName = [System.Environment]::MachineName
    UserName = [System.Environment]::UserName
    ContextFiles = (Get-ChildItem `$vault.Path -Filter '*.json' | Select-Object -ExpandProperty FullName)
}
`$result | ConvertTo-Json -Depth 5 | Set-Content '$writeResultFile'
Write-Host "Vault and contexts written with Context 8.1.3 / Sodium 2.2.2"
"@

pwsh -NoProfile -Command $part2aScript
if (-not (Test-Path $writeResultFile)) {
    throw 'Part 2a failed: no result file'
}

$wr = Get-Content $writeResultFile -Raw | ConvertFrom-Json
Write-Host "  VaultPath    : $($wr.VaultPath)"
Write-Host "  ContextFiles : $($wr.ContextFiles.Count) json files"
Write-Host ''
Write-Host '--- Part 2b: Decrypt raw vault files using Sodium 2.2.5 directly ---' -ForegroundColor Yellow

$part2bScript = @"
`$ErrorActionPreference = 'Stop'
Import-Module Sodium -RequiredVersion 2.2.5 -Force
`$seed = '$($wr.MachineName)' + '$($wr.UserName)' + '$($wr.ShardContent)'
`$kp = New-SodiumKeyPair -Seed `$seed
`$contextFiles = '$($wr.ContextFiles -join "','")' -split "','"
`$results = @{}
foreach (`$file in `$contextFiles) {
    `$json = Get-Content `$file -Raw | ConvertFrom-Json
    `$plain = ConvertFrom-SodiumSealedBox -SealedBox `$json.Context -PublicKey `$kp.PublicKey -PrivateKey `$kp.PrivateKey
    `$results[`$json.ID] = `$plain | ConvertFrom-Json -AsHashtable
}
`$results | ConvertTo-Json -Depth 10 | Set-Content '$readResultFile'
Write-Host "Raw vault files decrypted with Sodium 2.2.5"
"@

pwsh -NoProfile -Command $part2bScript
if (-not (Test-Path $readResultFile)) {
    throw 'Part 2b failed: no result file'
}

$rd = Get-Content $readResultFile -Raw | ConvertFrom-Json

Write-Host '--- Part 2 Assertions ---' -ForegroundColor Yellow
Assert-Equal 'compat-simple: Greeting' 'Hello' $rd.'compat-simple'.Greeting
Assert-Equal 'compat-simple: Number' '42' $rd.'compat-simple'.Number
Assert-Equal 'compat-secure: Token (SecureString prefix)' '[SECURESTRING]secret123' $rd.'compat-secure'.Token
Assert-Equal 'compat-nulls: Present' 'yes' $rd.'compat-nulls'.Present
Assert-Null 'compat-nulls: Absent' $rd.'compat-nulls'.Absent

Write-Host ''
try {
    $cleanupCommand = @(
        "Import-Module Sodium -RequiredVersion 2.2.2 -Force; "
        "Import-Module Context -Force; "
        "Get-ContextVault -Name '$VaultName' -ErrorAction SilentlyContinue | "
        "Remove-ContextVault -Confirm:`$false -ErrorAction SilentlyContinue"
    ) -join ''
    pwsh -NoProfile -Command $cleanupCommand 2>&1 | Out-Null
} catch {
    Write-Verbose "Compatibility cleanup skipped: $($_.Exception.Message)"
}

Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

$total = $pass + $fail
Write-Host ''
if ($fail -eq 0) {
    Write-Host "=== RESULT: ALL $total ASSERTIONS PASSED ===" -ForegroundColor Green
    Write-Host '    Sodium 2.2.2 -> 2.2.5: key derivation is identical, on-disk contract is preserved.' -ForegroundColor Green
} else {
    Write-Host "=== RESULT: $fail/$total ASSERTIONS FAILED - BREAKING CHANGE DETECTED ===" -ForegroundColor Red
}
