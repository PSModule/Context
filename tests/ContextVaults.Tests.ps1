[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test code only'
)]
[CmdletBinding()]
param()

BeforeAll {
    # Import required modules and functions for testing
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    
    # Load the config first
    . (Join-Path $ModuleRoot 'src/variables/private/Config.ps1')
    
    # Load utility functions
    . (Join-Path $ModuleRoot 'src/functions/private/Utilities/PowerShell/Get-PSCallStackPath.ps1')
    
    # Load vault management functions
    . (Join-Path $ModuleRoot 'src/functions/public/New-ContextVault.ps1')
    . (Join-Path $ModuleRoot 'src/functions/public/Get-ContextVault.ps1')
    . (Join-Path $ModuleRoot 'src/functions/public/Remove-ContextVault.ps1')
    . (Join-Path $ModuleRoot 'src/functions/public/Rename-ContextVault.ps1')
    . (Join-Path $ModuleRoot 'src/functions/public/Reset-ContextVault.ps1')
    
    # Clean up any existing test vaults
    $testVaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults"
    if (Test-Path $testVaultPath) {
        Get-ChildItem -Path $testVaultPath -Directory | Where-Object { 
            $_.Name -like "Test*" -or $_.Name -like "*Test*" -or $_.Name -like "Another*" -or $_.Name -like "Renamed*" 
        } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'ContextVault Management Functions' {
    Context 'New-ContextVault' {
        BeforeEach {
            # Clean up any test vaults before each test
            $testVaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults"
            if (Test-Path $testVaultPath) {
                Get-ChildItem -Path $testVaultPath -Directory | Where-Object { 
                    $_.Name -like "TestVault*" 
                } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It 'Should create a new vault with basic parameters' {
            $vaultName = "TestVault1-$(Get-Random)"
            
            # Create the vault
            $result = New-ContextVault -Name $vaultName -Description "Test vault"
            
            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $vaultName
            $result.Description | Should -Be "Test vault"
            $result.Path | Should -Exist
            
            # Verify directory structure
            $vaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults" | Join-Path -ChildPath $vaultName
            $contextPath = Join-Path -Path $vaultPath -ChildPath $script:Config.ContextPath
            $shardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.SeedShardPath
            $configPath = Join-Path -Path $vaultPath -ChildPath $script:Config.VaultConfigPath
            
            $vaultPath | Should -Exist
            $contextPath | Should -Exist
            $shardPath | Should -Exist
            $configPath | Should -Exist
            
            # Verify config content
            $config = Get-Content -Path $configPath | ConvertFrom-Json
            $config.Name | Should -Be $vaultName
            $config.Description | Should -Be "Test vault"
        }
        
        It 'Should throw error when creating vault with existing name' {
            $vaultName = "TestVault2-$(Get-Random)"
            
            # Create the first vault
            New-ContextVault -Name $vaultName | Should -Not -BeNullOrEmpty
            
            # Try to create another vault with the same name
            { New-ContextVault -Name $vaultName } | Should -Throw
        }
    }
    
    Context 'Get-ContextVault' {
        BeforeAll {
            # Create test vaults
            New-ContextVault -Name "TestVault3" -Description "Test vault 3"
            New-ContextVault -Name "TestVault4" -Description "Test vault 4"
            New-ContextVault -Name "AnotherVault" -Description "Different vault"
        }
        
        It 'Should get all vaults when no name specified' {
            $vaults = Get-ContextVault
            $vaults | Should -Not -BeNullOrEmpty
            ($vaults | Where-Object { $_.Name -like "Test*" }).Count | Should -BeGreaterOrEqual 3
        }
        
        It 'Should get specific vault by name' {
            $vault = Get-ContextVault -Name "TestVault3"
            $vault | Should -Not -BeNullOrEmpty
            $vault.Name | Should -Be "TestVault3"
            $vault.Description | Should -Be "Test vault 3"
        }
        
        It 'Should get vaults by wildcard pattern' {
            $vaults = Get-ContextVault -Name "Test*"
            $vaults | Should -Not -BeNullOrEmpty
            $vaults.Count | Should -BeGreaterOrEqual 2
            $vaults | ForEach-Object { $_.Name | Should -BeLike "Test*" }
        }
    }
    
    Context 'Rename-ContextVault' {
        BeforeAll {
            New-ContextVault -Name "TestVault5" -Description "Vault to rename"
        }
        
        It 'Should rename a vault successfully' {
            $oldName = "TestVault5"
            $newName = "RenamedTestVault5"
            
            # Rename the vault
            $result = Rename-ContextVault -Name $oldName -NewName $newName
            
            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $newName
            
            # Verify old vault no longer exists
            Get-ContextVault -Name $oldName | Should -BeNullOrEmpty
            
            # Verify new vault exists
            $vault = Get-ContextVault -Name $newName
            $vault | Should -Not -BeNullOrEmpty
            $vault.Name | Should -Be $newName
        }
        
        It 'Should throw error when renaming to existing vault name' {
            New-ContextVault -Name "TestVault6" -Description "Source vault"
            New-ContextVault -Name "TestVault7" -Description "Target vault"
            
            { Rename-ContextVault -Name "TestVault6" -NewName "TestVault7" } | Should -Throw
        }
    }
    
    Context 'Remove-ContextVault' {
        BeforeAll {
            New-ContextVault -Name "TestVaultToRemove" -Description "Vault to be removed"
        }
        
        It 'Should remove a vault successfully' {
            $vaultName = "TestVaultToRemove"
            
            # Verify vault exists before removal
            Get-ContextVault -Name $vaultName | Should -Not -BeNullOrEmpty
            
            # Remove the vault
            Remove-ContextVault -Name $vaultName -Confirm:$false
            
            # Verify vault no longer exists
            Get-ContextVault -Name $vaultName | Should -BeNullOrEmpty
            
            # Verify directory was removed
            $vaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults" | Join-Path -ChildPath $vaultName
            $vaultPath | Should -Not -Exist
        }
        
        It 'Should throw error when removing non-existent vault' {
            { Remove-ContextVault -Name "NonExistentVault" -Confirm:$false } | Should -Throw
        }
    }
}

AfterAll {
    # Clean up test vaults
    $testVaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults"
    if (Test-Path $testVaultPath) {
        Get-ChildItem -Path $testVaultPath -Directory | Where-Object { $_.Name -like "Test*" -or $_.Name -like "*Test*" -or $_.Name -like "Another*" -or $_.Name -like "Renamed*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}