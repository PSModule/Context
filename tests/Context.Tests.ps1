[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'Test code only'
)]
[CmdletBinding()]
param()

BeforeAll {
    Get-ContextVault | Remove-ContextVault -Confirm:$false
    # Create two vaults for multi-vault tests
    Set-ContextVault -Name 'VaultA'
    Set-ContextVault -Name 'VaultB'
}

AfterAll {
    Get-ContextVault | Remove-ContextVault -Confirm:$false
}

Describe 'Context' {
    Context 'Set-Context' {
        It "Set-Context -ID 'TestID1' -Vault 'VaultA'" {
            { Set-Context -ID 'TestID1' -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestID1' -Vault 'VaultA'
            Write-Verbose ($result | Out-String) -Verbose
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID1'
        }
        It "Set-Context -ID 'TestID2' -Context @{} -Vault 'VaultA'" {
            { Set-Context -ID 'TestID2' -Context @{} -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestID2' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID2'
        }
        It "Set-Context -ID 'TestID2' -Context @{} - Again -Vault 'VaultA'" {
            { Set-Context -ID 'TestID2' -Context @{} -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestID2' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID2'
        }
        It "Set-Context -ID 'john_doe' -Context [advanced object] -Vault 'VaultA'" {
            $contextData = [PSCustomObject]@{
                Username          = 'john_doe'
                AuthToken         = 'ghp_12345ABCDE67890FGHIJ' | ConvertTo-SecureString -AsPlainText -Force #gitleaks:allow
                LoginTime         = Get-Date
                IsTwoFactorAuth   = $true
                TwoFactorMethods  = @('TOTP', 'SMS')
                LastLoginAttempts = @(
                    [PSCustomObject]@{
                        Timestamp = (Get-Date).AddHours(-1)
                        IP        = '192.168.1.101' | ConvertTo-SecureString -AsPlainText -Force
                        Success   = $true
                    },
                    [PSCustomObject]@{
                        Timestamp = (Get-Date).AddDays(-1)
                        IP        = '203.0.113.5' | ConvertTo-SecureString -AsPlainText -Force
                        Success   = $false
                    }
                )
                UserPreferences   = @{
                    Theme         = 'dark'
                    DefaultBranch = 'main'
                    Notifications = [PSCustomObject]@{
                        Email = $true
                        Push  = $false
                        SMS   = $true
                    }
                    CodeReview    = @('PR Comments', 'Inline Suggestions')
                }
                Repositories      = @(
                    [PSCustomObject]@{
                        Name        = 'Repo1'
                        IsPrivate   = $true
                        CreatedDate = (Get-Date).AddMonths(-6)
                        Stars       = 42
                        Languages   = @('Python', 'JavaScript')
                    },
                    [PSCustomObject]@{
                        Name        = 'Repo2'
                        IsPrivate   = $false
                        CreatedDate = (Get-Date).AddYears(-1)
                        Stars       = 130
                        Languages   = @('C#', 'HTML', 'CSS')
                    }
                )
                AccessScopes      = @('repo', 'user', 'gist', 'admin:org')
                ApiRateLimits     = [PSCustomObject]@{
                    Limit     = 5000
                    Remaining = 4985
                    ResetTime = (Get-Date).AddMinutes(30)
                }
                SessionMetaData   = [PSCustomObject]@{
                    SessionID   = 'sess_abc123'
                    Device      = 'Windows-PC'
                    Location    = [PSCustomObject]@{
                        Country = 'USA'
                        City    = 'New York'
                    }
                    BrowserInfo = [PSCustomObject]@{
                        Name    = 'Chrome'
                        Version = '118.0.1'
                    }
                }
            }

            { Set-Context -ID 'john_doe' -Context $contextData -Vault 'VaultA' } | Should -Not -Throw
            $context = Get-Context -ID 'john_doe' -Vault 'VaultA'
            $context | Should -Not -BeNullOrEmpty
            $context.ID | Should -Be 'john_doe'
            $context.Username | Should -Be 'john_doe'
            $context.AuthToken | Should -BeOfType [System.Security.SecureString]
            $context.AuthToken | ConvertFrom-SecureString -AsPlainText | Should -Be 'ghp_12345ABCDE67890FGHIJ'
            $context.LoginTime | Should -BeOfType [System.DateTime]
            $context.IsTwoFactorAuth | Should -Be $true
            $context.TwoFactorMethods | Should -Be @('TOTP', 'SMS')
            $context.LastLoginAttempts | Should -BeOfType [PSCustomObject]
            $context.LastLoginAttempts.Count | Should -Be 2
            $context.UserPreferences | Should -BeOfType [PSCustomObject]
            $context.UserPreferences.Theme | Should -Be 'dark'
            $context.UserPreferences.DefaultBranch | Should -Be 'main'
            $context.UserPreferences.Notifications | Should -BeOfType [PSCustomObject]
            $context.UserPreferences.Notifications.Email | Should -Be $true
            $context.UserPreferences.Notifications.Push | Should -Be $false
            $context.UserPreferences.Notifications.SMS | Should -Be $true
            $context.UserPreferences.CodeReview | Should -Be @('PR Comments', 'Inline Suggestions')
            $context.Repositories | Should -BeOfType [PSCustomObject]
            $context.Repositories.Count | Should -Be 2
            $context.AccessScopes | Should -BeOfType [PSCustomObject]
            $context.AccessScopes.Count | Should -Be 4
            $context.ApiRateLimits | Should -BeOfType [PSCustomObject]
            $context.ApiRateLimits.Limit | Should -Be 5000
            $context.ApiRateLimits.Remaining | Should -Be 4985
            $context.ApiRateLimits.ResetTime | Should -BeOfType [System.DateTime]
            $context.SessionMetaData | Should -BeOfType [PSCustomObject]
            $context.SessionMetaData.SessionID | Should -Be 'sess_abc123'
            $context.SessionMetaData.Device | Should -Be 'Windows-PC'
            $context.SessionMetaData.Location | Should -BeOfType [PSCustomObject]
            $context.SessionMetaData.Location.Country | Should -Be 'USA'
            $context.SessionMetaData.Location.City | Should -Be 'New York'
            $context.SessionMetaData.BrowserInfo | Should -BeOfType [PSCustomObject]
            $context.SessionMetaData.BrowserInfo.Name | Should -Be 'Chrome'
            $context.SessionMetaData.BrowserInfo.Version | Should -Be '118.0.1'
        }
        # It "Get-Context -> Update -> Set-Context - Updates the context" {
        #     Set-Context -ID 'JimmyDoe' -Context @{
        #         Name  = 'Jimmy Doe'
        #         Email = 'JD@example.com'
        #     }
        #     $context = Get-Context -ID 'JimmyDoe'
        #     $context.Name = 'Jimmy Doe Jr.'
        #     $context | Set-Context
        # }
    }

    Context 'Get-Context' {
        It 'Get-Context - Should return all contexts in VaultA' {
            Write-Verbose (Get-Context -Vault 'VaultA' | Out-String) -Verbose
            (Get-Context -Vault 'VaultA').Count | Should -Be 3
        }
        It "Get-Context -ID '*' - Should return all contexts in VaultA" {
            Write-Verbose (Get-Context -ID '*' -Vault 'VaultA' | Out-String) -Verbose
            (Get-Context -ID '*' -Vault 'VaultA').Count | Should -Be 3
        }
        It "Get-Context -ID 'TestID*' - Should return all contexts in VaultA" {
            Write-Verbose (Get-Context -ID 'TestID*' -Vault 'VaultA' | Out-String) -Verbose
            (Get-Context -ID 'TestID*' -Vault 'VaultA').Count | Should -Be 2
        }
        It "Get-Context -ID '' - Should return no contexts in VaultA" {
            Write-Verbose (Get-Context -ID '' -Vault 'VaultA' | Out-String) -Verbose
            { Get-Context -ID '' -Vault 'VaultA' } | Should -Not -Throw
            Get-Context -ID '' -Vault 'VaultA' | Should -BeNullOrEmpty
        }
        It 'Get-Context -ID $null - Should return no contexts in VaultA' {
            Write-Verbose (Get-Context -ID $null -Vault 'VaultA' | Out-String) -Verbose
            { Get-Context -ID $null -Vault 'VaultA' } | Should -Not -Throw
            Get-Context -ID $null -Vault 'VaultA' | Should -BeNullOrEmpty
        }
    }

    Context 'Remove-Context' {
        It "Remove-Context -ID 'AContextID' - Should remove the context from VaultA" {
            Get-Context -Vault 'VaultA' | Remove-Context -Vault 'VaultA'
            { 1..10 | ForEach-Object {
                    Set-Context -Context @{} -ID "Temp$_" -Vault 'VaultA'
                }
            } | Should -Not -Throw
            (Get-Context -ID 'Temp*' -Vault 'VaultA').Count | Should -Be 10
            { 1..10 | ForEach-Object {
                    Remove-Context -ID "Temp$_" -Vault 'VaultA'
                }
            } | Should -Not -Throw
            (Get-Context -ID 'Temp*' -Vault 'VaultA').Count | Should -Be 0
        }
        It "Remove-Context -ID 'NonExistentContext' - Should not throw in VaultA" {
            { Remove-Context -ID 'NonExistentContext' -Vault 'VaultA' } | Should -Not -Throw
        }
        It "'john_doe' | Remove-Context - Should remove the context from VaultA" {
            { 'john_doe' | Remove-Context -Vault 'VaultA' } | Should -Not -Throw
            Get-Context -ID 'john_doe' -Vault 'VaultA' | Should -BeNullOrEmpty
        }
    }

    Context 'Rename-Context' {
        BeforeEach {
            # Ensure no contexts exist before starting tests
            Get-Context -Vault 'VaultA' | Remove-Context -Vault 'VaultA'
        }

        AfterEach {
            # Cleanup any contexts created during tests
            Get-Context -Vault 'VaultA' | Remove-Context -Vault 'VaultA'
        }

        It 'Renames the context successfully in VaultA' {
            $ID = 'TestContext'
            $newID = 'RenamedContext'

            Set-Context -ID $ID -Vault 'VaultA'

            # Rename the context
            Rename-Context -ID $ID -NewID $newID -Vault 'VaultA'

            # Verify the old context no longer exists
            Get-Context -ID $ID -Vault 'VaultA' | Should -BeNullOrEmpty
            Get-Context -ID $newID -Vault 'VaultA' | Should -Not -BeNullOrEmpty
        }

        It 'Throws an error when renaming a non-existent context in VaultA' {
            { Rename-Context -ID 'NonExistentContext' -NewID 'NewContext' -Vault 'VaultA' } | Should -Throw
        }

        It 'Renaming a context to an existing context throws without force in VaultA' {
            $existingID = 'ExistingContext'

            Set-Context -ID $existingID -Vault 'VaultA'
            Set-Context -ID 'TestContext' -Vault 'VaultA'

            # Attempt to rename the context to an existing context
            { Rename-Context -ID 'TestContext' -NewID $existingID -Vault 'VaultA' } | Should -Throw
        }

        It 'Sets a context where the ID is in the context data in VaultA' {
            $contextData = [PSCustomObject]@{
                ID   = 'TestContext'
                Data = 'Some data'
            }

            { Set-Context -Context $contextData -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestContext' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestContext'
            $result.Data | Should -Be 'Some data'
        }

        It 'Renaming a context to an existing context does not throw with force in VaultA' {
            $existingID = 'ExistingContext'

            Set-Context -ID $existingID -Vault 'VaultA'
            Set-Context -ID 'TestContext' -Vault 'VaultA'

            # Attempt to rename the context to an existing context
            { Rename-Context -ID 'TestContext' -NewID $existingID -Vault 'VaultA' -Force } | Should -Not -Throw
        }
    }

    Context 'Pipeline Input support' {
        It 'Get-Context supports pipeline input as strings in VaultA' {
            Set-Context -ID 'PipeContext1' -Context @{ Dummy = 1 } -Vault 'VaultA'
            Set-Context -ID 'PipeContext2' -Context @{ Dummy = 2 } -Vault 'VaultA'
            $result = 'PipeContext1', 'PipeContext2' | Get-Context -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Contain 'PipeContext1'
            $result.ID | Should -Contain 'PipeContext2'
        }
        It 'Get-Context supports pipeline input by property name in VaultA' {
            Set-Context -ID 'PipeContext3' -Context @{ Dummy = 3 } -Vault 'VaultA'
            $obj = [PSCustomObject]@{ ID = 'PipeContext3' }
            $result = $obj | Get-Context -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'PipeContext3'
        }
        # Get-ContextInfo tests below intentionally omit -Vault for legacy/default behavior
        It 'Get-ContextInfo supports pipeline input as strings' {
            Set-Context -ID 'PipeInfo1' -Context @{ Dummy = 1 } -Vault 'VaultA'
            Set-Context -ID 'PipeInfo2' -Context @{ Dummy = 2 } -Vault 'VaultA'
            $result = 'PipeInfo1', 'PipeInfo2' | Get-ContextInfo
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Contain 'PipeInfo1'
            $result.ID | Should -Contain 'PipeInfo2'
            $result | ForEach-Object { $_.PSObject.Properties.Name | Should -BeIn @('ID', 'Path') }
        }
        It 'Get-ContextInfo supports pipeline input by property name' {
            Set-Context -ID 'PipeInfo3' -Context @{ Dummy = 3 } -Vault 'VaultA'
            $obj = [PSCustomObject]@{ ID = 'PipeInfo3' }
            $result = $obj | Get-ContextInfo
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'PipeInfo3'
            $result | ForEach-Object { $_.PSObject.Properties.Name | Should -BeIn @('ID', 'Path') }
        }
        It 'Get-ContextInfo can retrieve info from multiple vaults' {
            # Set contexts in both VaultA and VaultB
            Set-Context -ID 'MultiVault1' -Context @{ Dummy = 'A' } -Vault 'VaultA'
            Set-Context -ID 'MultiVault2' -Context @{ Dummy = 'B' } -Vault 'VaultB'
            $result = Get-ContextInfo -ID 'MultiVault*' -Vault @('VaultA', 'VaultB')
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Contain 'MultiVault1'
            $result.ID | Should -Contain 'MultiVault2'
        }
    }
}
