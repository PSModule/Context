[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test code only'
)]
[CmdletBinding()]
param()

BeforeAll {
    # Clean up any existing contexts and vaults for testing
    if (Get-Command Get-ContextInfo -ErrorAction SilentlyContinue) {
        $contexts = Get-ContextInfo -Verbose
        Write-Verbose "Existing contexts: $($contexts.Count)" -Verbose
        if ($contexts) {
            $contexts | Remove-Context -Verbose
        }
    }
    
    # Clean up vault directories for fresh test
    $vaultsPath = Join-Path -Path $HOME -ChildPath '.contextvaults'
    $legacyVaultPath = Join-Path -Path $HOME -ChildPath '.contextvault'
    if (Test-Path $vaultsPath) {
        Remove-Item -Path $vaultsPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $legacyVaultPath) {
        Remove-Item -Path $legacyVaultPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Remove-Module -Name Context -Force -Verbose -ErrorAction SilentlyContinue
    Import-Module -Name Context -Force -Verbose -Version 999.0.0
}

Describe 'Multi-Vault Functions' {
    Context 'Function: New-ContextVault' {
        It "Creates a new vault successfully" {
            { New-ContextVault -Name "TestVault1" } | Should -Not -Throw
            $vaults = Get-ContextVault
            $vaults | Should -Not -BeNullOrEmpty
            $vaults.Name | Should -Contain "TestVault1"
            $vaults | Where-Object { $_.Name -eq "TestVault1" } | Select-Object -ExpandProperty IsDefault | Should -Be $true
        }
        
        It "Creates a second vault and first remains default" {
            { New-ContextVault -Name "TestVault2" } | Should -Not -Throw
            $vaults = Get-ContextVault
            $vaults.Count | Should -Be 2
            $defaultVault = $vaults | Where-Object { $_.IsDefault -eq $true }
            $defaultVault.Name | Should -Be "TestVault1"
        }
        
        It "Throws error when creating vault with existing name" {
            { New-ContextVault -Name "TestVault1" } | Should -Throw "*already exists*"
        }
    }
    
    Context 'Function: Get-ContextVault' {
        It "Lists all vaults" {
            $vaults = Get-ContextVault
            $vaults.Count | Should -Be 2
            $vaults.Name | Should -Contain "TestVault1"
            $vaults.Name | Should -Contain "TestVault2"
        }
        
        It "Gets specific vault by name" {
            $vault = Get-ContextVault -Name "TestVault1"
            $vault | Should -Not -BeNullOrEmpty
            $vault.Name | Should -Be "TestVault1"
            $vault.IsDefault | Should -Be $true
        }
        
        It "Returns empty when vault doesn't exist" {
            { Get-ContextVault -Name "NonExistentVault" } | Should -Not -Throw
        }
    }
    
    Context 'Function: Set-CurrentVault' {
        It "Sets vault as default successfully" {
            { Set-CurrentVault -Name "TestVault2" } | Should -Not -Throw
            $vaults = Get-ContextVault
            $defaultVault = $vaults | Where-Object { $_.IsDefault -eq $true }
            $defaultVault.Name | Should -Be "TestVault2"
        }
        
        It "Throws error when setting non-existent vault as default" {
            { Set-CurrentVault -Name "NonExistentVault" } | Should -Throw "*does not exist*"
        }
    }
    
    Context 'Multi-Vault Context Operations' {
        It "Sets context in specific vault" {
            { Set-Context -ID "TestID1" -Context @{ Data = "Vault2Data" } -VaultName "TestVault2" } | Should -Not -Throw
            $context = Get-Context -ID "TestID1" -VaultName "TestVault2"
            $context | Should -Not -BeNullOrEmpty
            $context.Data | Should -Be "Vault2Data"
        }
        
        It "Sets context in different vault with same ID" {
            { Set-Context -ID "TestID1" -Context @{ Data = "Vault1Data" } -VaultName "TestVault1" } | Should -Not -Throw
            $context1 = Get-Context -ID "TestID1" -VaultName "TestVault1"
            $context2 = Get-Context -ID "TestID1" -VaultName "TestVault2"
            
            $context1.Data | Should -Be "Vault1Data"
            $context2.Data | Should -Be "Vault2Data"
        }
        
        It "Gets context from default vault when no vault specified" {
            $context = Get-Context -ID "TestID1"  # Should use TestVault2 (current default)
            $context.Data | Should -Be "Vault2Data"
        }
        
        It "Removes context from specific vault" {
            { Remove-Context -ID "TestID1" -VaultName "TestVault1" } | Should -Not -Throw
            Get-Context -ID "TestID1" -VaultName "TestVault1" | Should -BeNullOrEmpty
            Get-Context -ID "TestID1" -VaultName "TestVault2" | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'Function: Remove-ContextVault' {
        It "Removes vault successfully" {
            { Remove-ContextVault -VaultName "TestVault1" -Force } | Should -Not -Throw
            $vaults = Get-ContextVault
            $vaults.Name | Should -Not -Contain "TestVault1"
        }
        
        It "Handles removal of non-existent vault gracefully" {
            { Remove-ContextVault -VaultName "NonExistentVault" -Force } | Should -Not -Throw
        }
    }
}

Describe 'Backward Compatibility' {
    BeforeAll {
        # Clean up for backward compatibility tests
        $vaultsPath = Join-Path -Path $HOME -ChildPath '.contextvaults'
        $legacyVaultPath = Join-Path -Path $HOME -ChildPath '.contextvault'
        if (Test-Path $vaultsPath) {
            Remove-Item -Path $vaultsPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $legacyVaultPath) {
            Remove-Item -Path $legacyVaultPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Remove-Module -Name Context -Force -ErrorAction SilentlyContinue
        Import-Module -Name Context -Force -Version 999.0.0
    }
    
    Context 'Legacy vault migration' {
        It "Creates default vault when no vaults exist" {
            { Set-Context -ID "LegacyTest" -Context @{ Data = "LegacyData" } } | Should -Not -Throw
            $vaults = Get-ContextVault
            $vaults | Should -Not -BeNullOrEmpty
            $vaults.Name | Should -Contain "default"
            $vaults | Where-Object { $_.Name -eq "default" } | Select-Object -ExpandProperty IsDefault | Should -Be $true
        }
        
        It "Functions work without specifying vault name" {
            $context = Get-Context -ID "LegacyTest"
            $context | Should -Not -BeNullOrEmpty
            $context.Data | Should -Be "LegacyData"
        }
    }
}