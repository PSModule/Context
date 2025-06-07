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
            Write-Host ($result | Out-String)
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
    }

    Context 'Get-Context' {
        It 'Get-Context - Should return all contexts in VaultA' {
            Write-Host (Get-Context -Vault 'VaultA' | Out-String)
            (Get-Context -Vault 'VaultA').Count | Should -Be 3
        }
        It "Get-Context -ID '*' - Should return all contexts in VaultA" {
            Write-Host (Get-Context -ID '*' -Vault 'VaultA' | Out-String)
            (Get-Context -ID '*' -Vault 'VaultA').Count | Should -Be 3
        }
        It "Get-Context -ID 'TestID*' - Should return all contexts in VaultA" {
            Write-Host (Get-Context -ID 'TestID*' -Vault 'VaultA' | Out-String)
            (Get-Context -ID 'TestID*' -Vault 'VaultA').Count | Should -Be 2
        }
        It "Get-Context -ID '' - Should return no contexts in VaultA" {
            Write-Host (Get-Context -ID '' -Vault 'VaultA' | Out-String)
            { Get-Context -ID '' -Vault 'VaultA' } | Should -Not -Throw
            Get-Context -ID '' -Vault 'VaultA' | Should -BeNullOrEmpty
        }
        It 'Get-Context -ID $null - Should return no contexts in VaultA' {
            Write-Host (Get-Context -ID $null -Vault 'VaultA' | Out-String)
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
            Get-Context -Vault 'VaultA' | Remove-Context -Vault 'VaultA'
        }

        AfterEach {
            Get-Context -Vault 'VaultA' | Remove-Context -Vault 'VaultA'
        }

        It 'Renames the context successfully in VaultA' {
            $ID = 'TestContext'
            $newID = 'RenamedContext'

            Set-Context -ID $ID -Vault 'VaultA'
            Rename-Context -ID $ID -NewID $newID -Vault 'VaultA'
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
            { Rename-Context -ID 'TestContext' -NewID $existingID -Vault 'VaultA' -Force } | Should -Not -Throw
        }
    }

    Context 'Get-ContextInfo' {
        BeforeAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false

            Set-Context -ID 'TestID1' -Vault 'VaultA'
            Set-Context -ID 'TestID2' -Vault 'VaultA'
            Set-Context -ID 'TestID3' -Vault 'VaultA'
            Set-Context -ID 'TestID1' -Vault 'VaultB'
            Set-Context -ID 'TestID2' -Vault 'VaultB'
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It 'Should return all contexts' {
            $results = Get-ContextInfo
            $results | Should -Not -BeNullOrEmpty
            $results | Should -HaveCount 5
            $results | ForEach-Object { $_ | Should -BeOfType [PSCustomObject] }
        }

        It 'Should return all contexts in VaultA' {
            $results = Get-ContextInfo -Vault 'VaultA'
            $results | Should -Not -BeNullOrEmpty
            $results | Should -HaveCount 3
            $results | ForEach-Object { $_ | Should -BeOfType [PSCustomObject] }
        }

        It 'Should return specific context by ID in VaultA' {
            $result = Get-ContextInfo -ID 'TestID1' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID1'
        }

        It 'Should return multiple contexts matching wildcard ID in VaultA' {
            $results = Get-ContextInfo -ID 'TestID*' -Vault 'VaultA'
            $results | Should -HaveCount 3
            $results.ID | Should -Contain 'TestID1'
            $results.ID | Should -Contain 'TestID2'
            $results.ID | Should -Contain 'TestID3'
        }

        It 'Should return no results for non-existent context ID in VaultA' {
            $result = Get-ContextInfo -ID 'NonExistentContext' -Vault 'VaultA'
            $result | Should -BeNullOrEmpty
        }
    }
}
