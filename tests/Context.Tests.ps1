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
            { Set-Context -ID 'TestID2' -Context @{ NullProperty = $null; StringProperty = 'test' } -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestID2' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID2'
            $result.NullProperty | Should -BeNull
            $result.StringProperty | Should -Be 'test'
        }
        It "Set-Context -ID 'TestID2' -Context @{} - Again -Vault 'VaultA'" {
            { Set-Context -ID 'TestID2' -Context @{ NullProperty = $null; StringProperty = 'updated' } -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestID2' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestID2'
            $result.NullProperty | Should -BeNull
            $result.StringProperty | Should -Be 'updated'
        }
        It "Set-Context -ID 'john_doe' -Context [advanced object] -Vault 'VaultA'" {
            $contextData = [PSCustomObject]@{
                Username          = 'john_doe'
                AuthToken         = 'ghp_12345ABCDE67890FGHIJ' | ConvertTo-SecureString -AsPlainText -Force #gitleaks:allow
                LoginTime         = Get-Date
                MyNullValue       = $null
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
            $context.MyNullValue | Should -BeNull
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
        It "Set-Context -ID 'null_test' -Context [object with null values] -Vault 'VaultA'" {
            $contextData = [PSCustomObject]@{
                StringValue   = 'NotNull'
                NullValue1    = $null
                EmptyString   = ''
                ZeroValue     = 0
                FalseValue    = $false
                NullValue2    = $null
                ArrayWithNull = @('value1', $null, 'value3')
                NestedObject  = [PSCustomObject]@{
                    Property1 = 'value'
                    NullProp  = $null
                    Property2 = 42
                }
            }

            { Set-Context -ID 'null_test' -Context $contextData -Vault 'VaultA' } | Should -Not -Throw
            $context = Get-Context -ID 'null_test' -Vault 'VaultA'
            $context | Should -Not -BeNullOrEmpty
            $context.ID | Should -Be 'null_test'
            $context.StringValue | Should -Be 'NotNull'
            $context.NullValue1 | Should -BeNull
            $context.EmptyString | Should -Be ''
            $context.ZeroValue | Should -Be 0
            $context.FalseValue | Should -Be $false
            $context.NullValue2 | Should -BeNull
            $context.ArrayWithNull | Should -Not -BeNull
            $context.ArrayWithNull.Count | Should -Be 3
            $context.ArrayWithNull[0] | Should -Be 'value1'
            $context.ArrayWithNull[1] | Should -BeNull
            $context.ArrayWithNull[2] | Should -Be 'value3'
            $context.NestedObject | Should -Not -BeNull
            $context.NestedObject.Property1 | Should -Be 'value'
            $context.NestedObject.NullProp | Should -BeNull
            $context.NestedObject.Property2 | Should -Be 42
        }
    }

    Context 'Get-Context' {
        It 'Get-Context - Should return all contexts in VaultA' {
            Write-Host (Get-Context -Vault 'VaultA' | Out-String)
            (Get-Context -Vault 'VaultA').Count | Should -Be 4
        }
        It "Get-Context -ID '*' - Should return all contexts in VaultA" {
            Write-Host (Get-Context -ID '*' -Vault 'VaultA' | Out-String)
            (Get-Context -ID '*' -Vault 'VaultA').Count | Should -Be 4
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
        It 'Get-Context -ID array - Should return only specified contexts in VaultA' {
            $ids = @('TestID1', 'TestID2')
            $results = Get-Context -ID $ids -Vault 'VaultA'
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 2
            $results.ID | Should -Contain 'TestID1'
            $results.ID | Should -Contain 'TestID2'
            $results.ID | Should -Not -Contain 'TestID3'
        }
        It 'Get-Context -ID single - Should not have output leakage (returns only one context)' {
            $id = 'TestID1'
            $results = Get-Context -ID $id -Vault 'VaultA'
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 1
            $results.ID | Should -Be $id
        }
        It 'Get-Context -ID single (nonexistent) - Should not have output leakage (returns nothing)' {
            $id = 'NonExistentContext'
            $results = Get-Context -ID $id -Vault 'VaultA'
            $results | Should -BeNullOrEmpty
        }
        It 'Get-Context -ID array with one valid and one invalid - Should not have output leakage (returns only valid)' {
            $ids = @('TestID1', 'NonExistentContext')
            $results = Get-Context -ID $ids -Vault 'VaultA'
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 1
            $results.ID | Should -Be 'TestID1'
        }
        It 'Get-Context -ID with whitespace or null - Should not have output leakage (returns nothing)' {
            $results = Get-Context -ID '   ' -Vault 'VaultA'
            $results | Should -BeNullOrEmpty
            $results = Get-Context -ID $null -Vault 'VaultA'
            $results | Should -BeNullOrEmpty
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
                ID        = 'TestContext'
                Data      = 'Some data'
                NullValue = $null
            }

            { Set-Context -Context $contextData -Vault 'VaultA' } | Should -Not -Throw
            $result = Get-Context -ID 'TestContext' -Vault 'VaultA'
            $result | Should -Not -BeNullOrEmpty
            $result.ID | Should -Be 'TestContext'
            $result.Data | Should -Be 'Some data'
            $result.NullValue | Should -BeNull
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
            $results | ForEach-Object { $_ | Should -BeOfType [ContextInfo] }
        }

        It 'Should return all contexts in VaultA' {
            $results = Get-ContextInfo -Vault 'VaultA'
            $results | Should -Not -BeNullOrEmpty
            $results | Should -HaveCount 3
            $results | ForEach-Object { $_ | Should -BeOfType [ContextInfo] }
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

        It 'Should return only specified contexts for multiple IDs in VaultA' {
            $ids = @('TestID1', 'TestID2')
            $results = Get-ContextInfo -ID $ids -Vault 'VaultA'
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 2
            $results.ID | Should -Contain 'TestID1'
            $results.ID | Should -Contain 'TestID2'
            $results.ID | Should -Not -Contain 'TestID3'
        }
    }

    Context 'Context Type Parameter Integration' {
        BeforeAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
            
            # Create contexts of both types
            Set-Context -ID 'UserCtx1' -Context @{ UserData = 'test1' } -Vault 'TypeTestVault' -Type 'User'
            Set-Context -ID 'UserCtx2' -Context @{ UserData = 'test2' } -Vault 'TypeTestVault' -Type 'User'
            Set-Context -ID 'ModuleCtx1' -Context @{ ModuleConfig = 'config1' } -Vault 'TypeTestVault' -Type 'Module'
            Set-Context -ID 'ModuleCtx2' -Context @{ ModuleConfig = 'config2' } -Vault 'TypeTestVault' -Type 'Module'
        }

        AfterAll {
            Get-ContextVault | Remove-ContextVault -Confirm:$false
        }

        It "Set-Context should create contexts in appropriate subdirectories" {
            $vault = Get-ContextVault -Name 'TypeTestVault'
            
            # Check user contexts
            $userContexts = Get-ContextInfo -Vault 'TypeTestVault' -Type 'User'
            $userContexts | Should -HaveCount 2
            $userContexts.ID | Should -Contain 'UserCtx1'
            $userContexts.ID | Should -Contain 'UserCtx2'
            
            # Check module contexts
            $moduleContexts = Get-ContextInfo -Vault 'TypeTestVault' -Type 'Module'
            $moduleContexts | Should -HaveCount 2
            $moduleContexts.ID | Should -Contain 'ModuleCtx1'
            $moduleContexts.ID | Should -Contain 'ModuleCtx2'
        }

        It "Get-Context should respect Type parameter" {
            # Test User type (default)
            $userCtx = Get-Context -ID 'UserCtx1' -Vault 'TypeTestVault'
            $userCtx | Should -Not -BeNullOrEmpty
            $userCtx.ID | Should -Be 'UserCtx1'
            $userCtx.UserData | Should -Be 'test1'

            # Test explicit User type
            $userCtx2 = Get-Context -ID 'UserCtx2' -Vault 'TypeTestVault' -Type 'User'
            $userCtx2 | Should -Not -BeNullOrEmpty
            $userCtx2.ID | Should -Be 'UserCtx2'
            $userCtx2.UserData | Should -Be 'test2'

            # Test Module type
            $moduleCtx = Get-Context -ID 'ModuleCtx1' -Vault 'TypeTestVault' -Type 'Module'
            $moduleCtx | Should -Not -BeNullOrEmpty
            $moduleCtx.ID | Should -Be 'ModuleCtx1'
            $moduleCtx.ModuleConfig | Should -Be 'config1'
        }

        It "Get-Context should not find contexts of wrong type" {
            # Should not find module context when searching user contexts
            $result = Get-Context -ID 'ModuleCtx1' -Vault 'TypeTestVault' -Type 'User'
            $result | Should -BeNullOrEmpty

            # Should not find user context when searching module contexts
            $result = Get-Context -ID 'UserCtx1' -Vault 'TypeTestVault' -Type 'Module'
            $result | Should -BeNullOrEmpty
        }

        It "Remove-Context should respect Type parameter" {
            # Create test contexts
            Set-Context -ID 'RemoveTest' -Context @{ Data = 'user' } -Vault 'TypeTestVault' -Type 'User'
            Set-Context -ID 'RemoveTest' -Context @{ Data = 'module' } -Vault 'TypeTestVault' -Type 'Module'

            # Remove user context
            { Remove-Context -ID 'RemoveTest' -Vault 'TypeTestVault' -Type 'User' } | Should -Not -Throw

            # Module context should still exist
            $moduleCtx = Get-Context -ID 'RemoveTest' -Vault 'TypeTestVault' -Type 'Module'
            $moduleCtx | Should -Not -BeNullOrEmpty
            $moduleCtx.Data | Should -Be 'module'

            # User context should be gone
            $userCtx = Get-Context -ID 'RemoveTest' -Vault 'TypeTestVault' -Type 'User'
            $userCtx | Should -BeNullOrEmpty
        }

        It "Rename-Context should respect Type parameter" {
            # Create test contexts
            Set-Context -ID 'RenameTest' -Context @{ Data = 'user' } -Vault 'TypeTestVault' -Type 'User'
            Set-Context -ID 'RenameTest' -Context @{ Data = 'module' } -Vault 'TypeTestVault' -Type 'Module'

            # Rename user context
            { Rename-Context -ID 'RenameTest' -NewID 'RenamedUser' -Vault 'TypeTestVault' -Type 'User' } | Should -Not -Throw

            # Module context should still exist with original name
            $moduleCtx = Get-Context -ID 'RenameTest' -Vault 'TypeTestVault' -Type 'Module'
            $moduleCtx | Should -Not -BeNullOrEmpty
            $moduleCtx.Data | Should -Be 'module'

            # User context should exist with new name
            $userCtx = Get-Context -ID 'RenamedUser' -Vault 'TypeTestVault' -Type 'User'
            $userCtx | Should -Not -BeNullOrEmpty
            $userCtx.Data | Should -Be 'user'

            # Old user context should be gone
            $oldUserCtx = Get-Context -ID 'RenameTest' -Vault 'TypeTestVault' -Type 'User'
            $oldUserCtx | Should -BeNullOrEmpty
        }
    }
}
