#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.7.1' }

[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Pester grouping syntax: known issue.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '',
    Justification = 'Used to create a secure string for testing.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingWriteHost', '',
    Justification = 'Log outputs to GitHub Actions logs.'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidLongLines', '',
    Justification = 'Long test descriptions and skip switches'
)]
[CmdletBinding()]
param()

BeforeAll {
    # Clean up any existing test vaults
    Get-ContextVault | Remove-ContextVault -Confirm:$false
}

AfterAll {
    # Clean up test vaults
    Get-ContextVault | Remove-ContextVault -Confirm:$false
}

Describe 'Module Contexts and User Contexts' {
    Context 'Vault Directory Structure' {
        BeforeEach {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It 'Should create module and user subdirectories for new vaults' {
            $vault = Set-ContextVault -Name 'TestModule' -PassThru
            $vault | Should -Not -BeNullOrEmpty
            
            $moduleDir = Join-Path $vault.Path 'module'
            $userDir = Join-Path $vault.Path 'user'
            
            Test-Path $moduleDir | Should -Be $true
            Test-Path $userDir | Should -Be $true
        }

        It 'Should migrate legacy vaults to new directory structure' {
            # Create a legacy vault structure manually
            $legacyVaultPath = Join-Path $script:Config.RootPath 'LegacyTest'
            New-Item -Path $legacyVaultPath -ItemType Directory -Force
            
            # Create a fake context file in the root
            $fakeContextPath = Join-Path $legacyVaultPath 'legacy-context.json'
            '{"ID":"legacy","Path":"' + $fakeContextPath + '","Vault":"LegacyTest","Context":"fake"}' | Set-Content -Path $fakeContextPath
            
            # Create shard file
            $shardPath = Join-Path $legacyVaultPath 'shard'
            'test-shard' | Set-Content -Path $shardPath
            
            # Call Set-ContextVault to trigger migration
            $vault = Set-ContextVault -Name 'LegacyTest' -PassThru
            
            # Check if directories were created
            $moduleDir = Join-Path $vault.Path 'module'
            $userDir = Join-Path $vault.Path 'user'
            Test-Path $moduleDir | Should -Be $true
            Test-Path $userDir | Should -Be $true
            
            # Check if the file was moved to user directory
            $migratedContextPath = Join-Path $userDir 'legacy-context.json'
            Test-Path $migratedContextPath | Should -Be $true
            
            # Check if original file was removed from root
            Test-Path $fakeContextPath | Should -Be $false
        }
    }

    Context 'Get-ContextDirectory Function' {
        BeforeAll {
            $testVaultPath = Join-Path $script:Config.RootPath 'TestVault'
            New-Item -Path $testVaultPath -ItemType Directory -Force
        }

        It 'Should return correct user directory path' {
            $userDir = Get-ContextDirectory -VaultPath $testVaultPath -Type 'User'
            $userDir | Should -Be (Join-Path $testVaultPath 'user')
        }

        It 'Should return correct module directory path' {
            $moduleDir = Get-ContextDirectory -VaultPath $testVaultPath -Type 'Module'
            $moduleDir | Should -Be (Join-Path $testVaultPath 'module')
        }

        It 'Should validate Type parameter' {
            { Get-ContextDirectory -VaultPath $testVaultPath -Type 'InvalidType' } | Should -Throw
        }
    }

    Context 'Active Module Context Management' {
        BeforeAll {
            $vault = Set-ContextVault -Name 'ActiveContextTest' -PassThru
        }

        AfterAll {
            Remove-ContextVault -Name 'ActiveContextTest' -Confirm:$false
        }

        It 'Should return default when no active context is set' {
            $activeContext = Get-ActiveModuleContext -VaultPath $vault.Path
            $activeContext | Should -Be 'default'
        }

        It 'Should set and get active module context' {
            Set-ActiveModuleContext -VaultPath $vault.Path -ContextName 'staging'
            $activeContext = Get-ActiveModuleContext -VaultPath $vault.Path
            $activeContext | Should -Be 'staging'
        }

        It 'Should handle missing active-context file gracefully' {
            # Remove the active-context file
            $activeContextFile = Join-Path $vault.Path 'module' 'active-context'
            if (Test-Path $activeContextFile) {
                Remove-Item $activeContextFile -Force
            }
            
            $activeContext = Get-ActiveModuleContext -VaultPath $vault.Path
            $activeContext | Should -Be 'default'
        }

        It 'Should handle corrupted active-context file gracefully' {
            $activeContextFile = Join-Path $vault.Path 'module' 'active-context'
            # Write invalid content
            [byte[]]@(0x00, 0xFF, 0x00) | Set-Content $activeContextFile -AsByteStream
            
            $activeContext = Get-ActiveModuleContext -VaultPath $vault.Path
            $activeContext | Should -Be 'default'
        }
    }

    Context 'Get-ContextInfo with Type Parameter' -Skip:$(-not (Get-Module Sodium -ListAvailable)) {
        BeforeAll {
            $vault = Set-ContextVault -Name 'ContextInfoTest' -PassThru
            
            # Create a user context
            Set-Context -ID 'UserTest' -Context @{ UserData = 'test' } -Vault 'ContextInfoTest' -Type 'User'
            
            # Create a module context
            Set-Context -ID 'ModuleTest' -Context @{ ModuleConfig = 'test' } -Vault 'ContextInfoTest' -Type 'Module'
        }

        AfterAll {
            Remove-ContextVault -Name 'ContextInfoTest' -Confirm:$false
        }

        It 'Should retrieve user contexts by default' {
            $contexts = Get-ContextInfo -Vault 'ContextInfoTest'
            $contexts | Should -Not -BeNullOrEmpty
            $contexts | Where-Object { $_.ID -eq 'UserTest' } | Should -Not -BeNullOrEmpty
        }

        It 'Should retrieve user contexts when Type is User' {
            $contexts = Get-ContextInfo -Vault 'ContextInfoTest' -Type 'User'
            $contexts | Should -Not -BeNullOrEmpty
            $contexts | Where-Object { $_.ID -eq 'UserTest' } | Should -Not -BeNullOrEmpty
        }

        It 'Should retrieve module contexts when Type is Module' {
            $contexts = Get-ContextInfo -Vault 'ContextInfoTest' -Type 'Module'
            $contexts | Should -Not -BeNullOrEmpty
            $contexts | Where-Object { $_.ID -eq 'ModuleTest' } | Should -Not -BeNullOrEmpty
        }

        It 'Should not return module contexts when querying for user contexts' {
            $contexts = Get-ContextInfo -Vault 'ContextInfoTest' -Type 'User'
            $contexts | Where-Object { $_.ID -eq 'ModuleTest' } | Should -BeNullOrEmpty
        }

        It 'Should not return user contexts when querying for module contexts' {
            $contexts = Get-ContextInfo -Vault 'ContextInfoTest' -Type 'Module'
            $contexts | Where-Object { $_.ID -eq 'UserTest' } | Should -BeNullOrEmpty
        }
    }

    Context 'Switch-ModuleContext Function' -Skip:$(-not (Get-Module Sodium -ListAvailable)) {
        BeforeAll {
            $vault = Set-ContextVault -Name 'SwitchTest' -PassThru
            
            # Create multiple module contexts
            Set-Context -ID 'default' -Context @{ Environment = 'production' } -Vault 'SwitchTest' -Type 'Module'
            Set-Context -ID 'staging' -Context @{ Environment = 'staging' } -Vault 'SwitchTest' -Type 'Module'
            Set-Context -ID 'development' -Context @{ Environment = 'development' } -Vault 'SwitchTest' -Type 'Module'
        }

        AfterAll {
            Remove-ContextVault -Name 'SwitchTest' -Confirm:$false
        }

        It 'Should switch to existing module context' {
            { Switch-ModuleContext -Vault 'SwitchTest' -ContextName 'staging' } | Should -Not -Throw
            $activeContext = Get-ActiveModuleContextName -Vault 'SwitchTest'
            $activeContext | Should -Be 'staging'
        }

        It 'Should fail to switch to non-existent module context' {
            { Switch-ModuleContext -Vault 'SwitchTest' -ContextName 'nonexistent' } | Should -Throw
        }

        It 'Should return context data when PassThru is specified' {
            $result = Switch-ModuleContext -Vault 'SwitchTest' -ContextName 'development' -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result.Environment | Should -Be 'development'
        }
    }

    Context 'Get-ActiveModuleContextName Function' -Skip:$(-not (Get-Module Sodium -ListAvailable)) {
        BeforeAll {
            $vault = Set-ContextVault -Name 'ActiveNameTest' -PassThru
            Set-Context -ID 'default' -Context @{ Config = 'default' } -Vault 'ActiveNameTest' -Type 'Module'
            Set-Context -ID 'testing' -Context @{ Config = 'testing' } -Vault 'ActiveNameTest' -Type 'Module'
        }

        AfterAll {
            Remove-ContextVault -Name 'ActiveNameTest' -Confirm:$false
        }

        It 'Should return the active module context name' {
            Switch-ModuleContext -Vault 'ActiveNameTest' -ContextName 'testing'
            $activeName = Get-ActiveModuleContextName -Vault 'ActiveNameTest'
            $activeName | Should -Be 'testing'
        }

        It 'Should return default when no active context is set' {
            # Reset to default by directly manipulating the file
            $vault = Get-ContextVault -Name 'ActiveNameTest'
            $activeContextFile = Join-Path $vault.Path 'module' 'active-context'
            Remove-Item $activeContextFile -Force -ErrorAction SilentlyContinue
            
            $activeName = Get-ActiveModuleContextName -Vault 'ActiveNameTest'
            $activeName | Should -Be 'default'
        }
    }
}