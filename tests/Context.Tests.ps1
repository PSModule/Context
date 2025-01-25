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
    Import-Module -Name Context -Force -Verbose
}

Describe 'Functions' {
    Context 'Function: Set-Context' {
        It "Set-Context -ID 'TestID1'" {
            { Set-Context -ID 'TestID1' } | Should -Not -Throw
            $result = Get-Context -ID 'TestID1'
            Write-Verbose ($result | Out-String) -Verbose
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID1'
        }
        It "Set-Context -ID 'TestID2' -Context @{}" {
            { Set-Context -ID 'TestID2' -Context @{} } | Should -Not -Throw
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

        It "Set-Context -ID 'john_doe' -Context [advanced object]" {
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

            { Set-Context -ID 'john_doe' -Context $contextData } | Should -Not -Throw
            $context = Get-Context -ID 'john_doe'
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
            $context.UserPreferences | Should -BeOfType [System.Collections.Hashtable]
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
            'john_doe' | Remove-Context
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
