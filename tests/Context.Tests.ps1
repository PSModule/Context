[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test code only'
)]
[CmdletBinding()]
param()

BeforeAll {
    $secrets = Get-SecretInfo -Verbose
    Write-Verbose "Secrets: $($secrets.Count)" -Verbose
    Write-Verbose ($secrets | Format-Table | Out-String) -Verbose
    $secrets | Remove-Secret -Verbose
    $vault = Get-SecretVault -Verbose
    Write-Verbose "Vault: $($vault.Count)" -Verbose
    Write-Verbose ($vault | Format-Table | Out-String) -Verbose
    $vault | Unregister-SecretVault -Verbose
}

Describe 'Functions' {
    Context 'Function: Set-Context' {
        It "Set-Context -ID 'TestID1'" {
            { Set-Context -ID 'TestID1' } | Should -Not -Throw
            $contextInfo = Get-ContextInfo
            Write-Verbose ($contextInfo | Out-String) -Verbose
            $contextInfo.Count | Should -Be 1
            $contextInfo[0].ID | Should -Be 'TestID1'
            $contextInfo[0].SecretName | Should -Be 'Context:TestID1'


            $result = Get-Context -ID 'TestID1'
            Write-Verbose ($result | Out-String) -Verbose
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID1'
        }
        It "Set-Context -ID 'TestID2' -Context @{}" {
            { Set-Context -ID 'TestID2' -Context @{} } | Should -Not -Throw
            $contextInfo = Get-ContextInfo
            Write-Verbose ($contextInfo | Out-String) -Verbose
            $contextInfo.Count | Should -Be 2

            $result = Get-Context -ID 'TestID2'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID2'
        }
        It "Set-Context -ID 'TestID2' -Context @{} - Again" {
            { Set-Context -ID 'TestID2' -Context @{} } | Should -Not -Throw
            $result = Get-Context -ID 'TestID2'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID2'
        }
    }

    Context 'Function: Get-Context' {
        It 'Get-Context - Should return all contexts' {
            Write-Verbose (Get-Context | Out-String) -Verbose
            (Get-Context).Count | Should -Be 2
        }
        It "Get-Context -ID '*' - Should return all contexts" {
            Write-Verbose (Get-Context -ID '*' | Out-String) -Verbose
            (Get-Context -ID '*').Count | Should -Be 2
        }
        It "Get-Context -ID 'TestID*' - Should return all contexts" {
            Write-Verbose (Get-Context -ID 'TestID*' | Out-String) -Verbose
            (Get-Context -ID 'TestID*').Count | Should -Be 2
        }
        It "Get-Context -ID '' - Should return no contexts" {
            Write-Verbose (Get-Context -ID '' | Out-String) -Verbose
            { Get-Context -ID '' } | Should -Not -Throw
            Get-Context -ID '' | Should -BeNullOrEmpty
        }
        It 'Get-Context -ID $null - Should return no contexts' {
            Write-Verbose (Get-Context -ID $null | Out-String) -Verbose
            { Get-Context -ID $null } | Should -Not -Throw
            Get-Context -ID $null | Should -BeNullOrEmpty
        }
    }

    Context 'Function: Remove-Context' {
        It "Remove-Context -ID 'AContextID' - Should remove the context" {
            Get-SecretInfo | Remove-Secret

            { 1..10 | ForEach-Object {
                    Set-Context -Context @{} -ID "Temp$_"
                }
            } | Should -Not -Throw

            (Get-Context -ID 'Temp*').Count | Should -Be 10

            { 1..10 | ForEach-Object {
                    Remove-Context -ID "Temp$_"
                }
            } | Should -Not -Throw
            (Get-Context -ID 'Temp*').Count | Should -Be 0
        }
    }

    Context 'Function: Rename-Context' {
        BeforeEach {
            # Ensure no contexts exist before starting tests
            Get-Context | ForEach-Object {
                Remove-Context -ID $_.ID
            }
        }

        AfterEach {
            # Cleanup any contexts created during tests
            Get-Context | ForEach-Object {
                Remove-Context -ID $_.ID
            }
        }

        It 'Renames the context successfully' {
            $ID = 'TestContext'
            $newID = 'RenamedContext'

            Set-Context -ID $ID

            # Rename the context
            Rename-Context -ID $ID -NewID $newID

            # Verify the old context no longer exists
            Get-Context -ID $ID | Should -BeNullOrEmpty
            Get-Context -ID $newID | Should -Not -BeNullOrEmpty
        }

        It 'Throws an error when renaming a non-existent context' {
            { Rename-Context -ID 'NonExistentContext' -NewID 'NewContext' } | Should -Throw
        }

        It 'Renaming a context to an existing context throws without force' {
            $existingID = 'ExistingContext'

            Set-Context -ID $existingID
            Set-Context -ID 'TestContext'

            # Attempt to rename the context to an existing context
            { Rename-Context -ID 'TestContext' -NewID $existingID } | Should -Throw
        }

        It 'Renaming a context to an existing context does not throw with force' {
            $existingID = 'ExistingContext'

            Set-Context -ID $existingID
            Set-Context -ID 'TestContext'

            # Attempt to rename the context to an existing context
            { Rename-Context -ID 'TestContext' -NewID $existingID -Force } | Should -Not -Throw
        }
    }
}
