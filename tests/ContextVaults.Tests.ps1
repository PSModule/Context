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
    Get-ContextVault | Remove-ContextVault -Confirm:$false
}

AfterAll {
    Get-ContextVault | Remove-ContextVault -Confirm:$false
}

Describe 'ContextVault' {
    Context 'Set-ContextVault' {
        BeforeAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It 'Should create a new vault with a single name parameter' {
            $result = Set-ContextVault -Name 'test-vault1' -PassThru
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [ContextVault]
            $result.Name | Should -Be 'test-vault1'
            $result.Path | Should -Not -BeNullOrEmpty
        }

        It 'Should create multiple vaults from array parameter' {
            $results = Set-ContextVault -Name 'test-vault2', 'test-vault3' -PassThru
            $results | Should -HaveCount 2
            $results | ForEach-Object { $_ | Should -BeOfType [ContextVault] }
            $results[0].Name | Should -Be 'test-vault2'
            $results[1].Name | Should -Be 'test-vault3'
        }

        It 'Should accept pipeline input for vault creation' {
            $results = 'test-pipeline1', 'test-pipeline2' | Set-ContextVault -PassThru
            $results | Should -HaveCount 2
            $results | ForEach-Object { $_ | Should -BeOfType [ContextVault] }
            $results.Name | Should -Contain 'test-pipeline1'
            $results.Name | Should -Contain 'test-pipeline2'
        }

        It 'Should not throw when setting an existing vault' {
            { Set-ContextVault -Name 'test-vault1' } | Should -Not -Throw
        }
    }

    Context 'Get-ContextVault' {
        BeforeAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
            Set-ContextVault -Name 'get-test1'
            Set-ContextVault -Name 'get-test2'
            Set-ContextVault -Name 'other-test1'
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It 'Should return all vaults when no name is specified' {
            $results = Get-ContextVault
            $results | Should -Not -BeNullOrEmpty
            $results | Should -HaveCount 3
            $results | ForEach-Object { $_ | Should -BeOfType [ContextVault] }
        }

        It 'Should return a specific vault by exact name' {
            $result = Get-ContextVault -Name 'get-test1'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [ContextVault]
            $result.Name | Should -Be 'get-test1'
        }

        It 'Should return multiple vaults with wildcard matching' {
            $results = Get-ContextVault -Name 'get-*'
            $results | Should -HaveCount 2
            $results.Name | Should -Contain 'get-test1'
            $results.Name | Should -Contain 'get-test2'
        }

        It 'Should return multiple vaults with array of names' {
            $vaultNames = @('get-test1', 'other-test1')
            $results = Get-ContextVault -Name $vaultNames
            $results | Should -HaveCount 2
            $results.Name | Should -Contain 'get-test1'
            $results.Name | Should -Contain 'other-test1'
        }

        It 'Should return empty results for non-existent vault names' {
            $result = Get-ContextVault -Name 'nonexistent-vault'
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-ContextVault' {
        BeforeEach {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
            Set-ContextVault -Name 'remove-test1'
            Set-ContextVault -Name 'remove-test2'
            Set-ContextVault -Name 'remove-test3'
            Set-ContextVault -Name 'keep-test1'
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }


        It 'Should remove a specific vault by name' {
            Remove-ContextVault -Name 'remove-test1' -Confirm:$false
            $result = Get-ContextVault -Name 'remove-test1'
            $result | Should -BeNullOrEmpty
        }

        It 'Should remove multiple vaults using wildcards' {
            Remove-ContextVault -Name 'remove-*' -Confirm:$false
            $results = Get-ContextVault -Name 'remove-*'
            $results | Should -BeNullOrEmpty

            # Verify other vaults are still present
            $kept = Get-ContextVault -Name 'keep-*'
            $kept | Should -Not -BeNullOrEmpty
        }

        It 'Should remove vaults using pipeline input from names' {
            'remove-test2', 'remove-test3' | Remove-ContextVault -Confirm:$false
            $results = Get-ContextVault -Name @('remove-test2', 'remove-test3')
            $results | Should -BeNullOrEmpty
        }

        It 'Should remove vaults using pipeline input from Get-ContextVault' {
            Get-ContextVault -Name 'remove-*' | Remove-ContextVault -Confirm:$false
            $results = Get-ContextVault -Name 'remove-*'
            $results | Should -BeNullOrEmpty
        }

        It 'Should not throw when removing non-existent vault' {
            { Remove-ContextVault -Name 'nonexistent-vault' -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Reset-ContextVault' {
        BeforeAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
            Set-ContextVault -Name 'reset-test1'
            Set-ContextVault -Name 'reset-test2'
            Set-ContextVault -Name 'reset-other'
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It 'Should reset a specific vault by name' {
            { Reset-ContextVault -Name 'reset-test1' -Confirm:$false } | Should -Not -Throw
            $result = Get-ContextVault -Name 'reset-test1'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should reset multiple vaults using wildcards' {
            { Reset-ContextVault -Name 'reset-*' -Confirm:$false } | Should -Not -Throw
            $results = Get-ContextVault -Name 'reset-*'
            $results | Should -Not -BeNullOrEmpty
            $results | Should -HaveCount 3
        }

        It 'Should reset vaults using pipeline input from vault objects' {
            { Get-ContextVault -Name 'reset-other' | Reset-ContextVault -Confirm:$false } | Should -Not -Throw
            $result = Get-ContextVault -Name 'reset-other'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should not throw when resetting non-existent vault' {
            { Reset-ContextVault -Name 'nonexistent-vault' -Confirm:$false } | Should -Not -Throw
        }
    }

    Context 'Pipeline and Combined Operations' {
        BeforeAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
            'pipeline-test1', 'pipeline-test2', 'pipeline-test3' | Set-ContextVault
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It 'Should support pipeline operations with variables' {
            $testVaults = @('pipeline-var1', 'pipeline-var2')
            $results = $testVaults | Set-ContextVault -PassThru
            $results | Should -HaveCount 2

            $getResults = Get-ContextVault -Name $testVaults
            $getResults | Should -HaveCount 2

            $getResults | Remove-ContextVault -Confirm:$false
            $checkResults = Get-ContextVault -Name $testVaults
            $checkResults | Should -BeNullOrEmpty
        }

        It 'Should get vaults and pass to reset through pipeline' {
            $vaults = Get-ContextVault -Name 'pipeline-test*'
            $vaults | Should -HaveCount 3

            { $vaults | Reset-ContextVault -Confirm:$false } | Should -Not -Throw

            $resetVaults = Get-ContextVault -Name 'pipeline-test*'
            $resetVaults | Should -HaveCount 3
        }

        It 'Should process arrays of vault names through the pipeline' {
            $vaultBatch = @('batch-test1', 'batch-test2', 'batch-test3')
            $vaultBatch | Set-ContextVault

            $results = Get-ContextVault -Name 'batch-*'
            $results | Should -HaveCount 3

            $results | Remove-ContextVault -Confirm:$false
            $checkResults = Get-ContextVault -Name 'batch-*'
            $checkResults | Should -BeNullOrEmpty
        }
    }
}
