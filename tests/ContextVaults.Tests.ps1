[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test code only'
)]
[CmdletBinding()]
param()

BeforeAll {
    Get-ContextVault | Remove-ContextVault -Confirm:$false
}

Describe 'ContextVault Management Functions' {
    Context 'Set-ContextVault' {
        It 'Should create a new vault with basic parameters' {
            $vaultName = "TestVault1-$(Get-Random)"

            # Create the vault
            $result = Set-ContextVault -Name $vaultName -Description "Test vault"

            # Verify the result
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $vaultName
            $result.Description | Should -Be "Test vault"
            $result.Path | Should -Exist

            # Verify directory structure
            $vaultPath = Join-Path -Path $script:Config.RootPath -ChildPath "Vaults" | Join-Path -ChildPath $vaultName
            $ContextFolderName = Join-Path -Path $vaultPath -ChildPath $script:Config.ContextFolderName
            $shardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.SeedShardFileName
            $configPath = Join-Path -Path $vaultPath -ChildPath $script:Config.VaultConfigPath

            $vaultPath | Should -Exist
            $ContextFolderName | Should -Exist
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
            Set-ContextVault -Name $vaultName | Should -Not -BeNullOrEmpty

            # Try to create another vault with the same name
            { Set-ContextVault -Name $vaultName } | Should -Throw
        }
    }

    Context 'Get-ContextVault' {
        BeforeAll {
            # Create test vaults
            Set-ContextVault -Name "TestVault3" -Description "Test vault 3"
            Set-ContextVault -Name "TestVault4" -Description "Test vault 4"
            Set-ContextVault -Name "AnotherVault" -Description "Different vault"
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
            Set-ContextVault -Name "TestVault5" -Description "Vault to rename"
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
            Set-ContextVault -Name "TestVault6" -Description "Source vault"
            Set-ContextVault -Name "TestVault7" -Description "Target vault"

            { Rename-ContextVault -Name "TestVault6" -NewName "TestVault7" } | Should -Throw
        }
    }

    Context 'Remove-ContextVault' {
        BeforeAll {
            Set-ContextVault -Name "TestVaultToRemove" -Description "Vault to be removed"
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
            $vaultPath = Join-Path -Path $script:Config.RootPath -ChildPath "Vaults" | Join-Path -ChildPath $vaultName
            $vaultPath | Should -Not -Exist
        }

        It 'Should throw error when removing non-existent vault' {
            { Remove-ContextVault -Name "NonExistentVault" -Confirm:$false } | Should -Throw
        }
    }

    Context 'Set-ContextVault' {
        BeforeEach {
            # Clean up any test vaults before each test
            $testVaultPath = Join-Path -Path $script:Config.RootPath -ChildPath "Vaults"
            if (Test-Path $testVaultPath) {
                Get-ChildItem -Path $testVaultPath -Directory | Where-Object {
                    $_.Name -like "SetTestVault*"
                } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Should create a new vault when it does not exist' {
            $vaultName = "SetTestVault1-$(Get-Random)"

            # Create the vault using Set-ContextVault
            $result = Set-ContextVault -Name $vaultName -Description "Test vault description"

            # Verify the vault was created
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $vaultName
            $result.Description | Should -Be "Test vault description"
            $result.Path | Should -Exist
            $result.ContextFolderName | Should -Exist
            $result.Created | Should -BeOfType [DateTime]
            $result.ContextCount | Should -Be 0

            # Verify vault can be retrieved
            $retrievedVault = Get-ContextVault -Name $vaultName
            $retrievedVault | Should -Not -BeNullOrEmpty
            $retrievedVault.Name | Should -Be $vaultName
            $retrievedVault.Description | Should -Be "Test vault description"
        }

        It 'Should update existing vault configuration' {
            $vaultName = "SetTestVault2-$(Get-Random)"

            # Create initial vault
            $initialResult = Set-ContextVault -Name $vaultName -Description "Initial description"
            $initialResult | Should -Not -BeNullOrEmpty

            # Update the vault description
            $updatedResult = Set-ContextVault -Name $vaultName -Description "Updated description"

            # Verify the vault was updated
            $updatedResult | Should -Not -BeNullOrEmpty
            $updatedResult.Name | Should -Be $vaultName
            $updatedResult.Description | Should -Be "Updated description"
            $updatedResult.Path | Should -Exist
            $updatedResult.Created | Should -Be $initialResult.Created
            $updatedResult.LastModified | Should -Not -BeNullOrEmpty
            $updatedResult.LastModified | Should -BeOfType [DateTime]

            # Verify the change persisted
            $retrievedVault = Get-ContextVault -Name $vaultName
            $retrievedVault.Description | Should -Be "Updated description"
        }

        It 'Should handle vault directory without configuration file' {
            $vaultName = "SetTestVault3-$(Get-Random)"
            $vaultPath = Join-Path -Path $script:Config.RootPath -ChildPath "Vaults" | Join-Path -ChildPath $vaultName

            # Create vault directory without configuration
            $null = New-Item -Path $vaultPath -ItemType Directory -Force

            # Set-ContextVault should repair the configuration
            $result = Set-ContextVault -Name $vaultName -Description "Repaired vault"

            # Verify the vault was repaired
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be $vaultName
            $result.Description | Should -Be "Repaired vault"
            $result.Path | Should -Exist
            $result.ContextFolderName | Should -Exist

            # Verify configuration file was created
            $configPath = Join-Path -Path $vaultPath -ChildPath $script:Config.VaultConfigPath
            $configPath | Should -Exist
        }

        It 'Should be idempotent when called multiple times' {
            $vaultName = "SetTestVault4-$(Get-Random)"

            # Call Set-ContextVault multiple times
            $result1 = Set-ContextVault -Name $vaultName -Description "Test description"
            $result2 = Set-ContextVault -Name $vaultName -Description "Test description"
            $result3 = Set-ContextVault -Name $vaultName -Description "Test description"

            # All results should be consistent
            $result1.Name | Should -Be $vaultName
            $result2.Name | Should -Be $vaultName
            $result3.Name | Should -Be $vaultName

            $result1.Description | Should -Be "Test description"
            $result2.Description | Should -Be "Test description"
            $result3.Description | Should -Be "Test description"

            # Created time should remain the same, LastModified should be updated
            $result1.Created | Should -Be $result2.Created
            $result2.Created | Should -Be $result3.Created
        }
    }
}

AfterAll {
    # Clean up test vaults
    $testVaultPath = Join-Path -Path $script:Config.RootPath -ChildPath "Vaults"
    if (Test-Path $testVaultPath) {
        Get-ChildItem -Path $testVaultPath -Directory | Where-Object { $_.Name -like "Test*" -or $_.Name -like "*Test*" -or $_.Name -like "Another*" -or $_.Name -like "Renamed*" -or $_.Name -like "SetTestVault*" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
