#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.2' }

function Get-Context {
    <#
        .SYNOPSIS
        Retrieves a context from the context vault.

        .DESCRIPTION
        Retrieves a context by reading and decrypting context files directly from the vault directory.
        If no ID is specified, all available contexts will be returned.
        Wildcards are supported to match multiple contexts.

        .EXAMPLE
        Get-Context

        Output:
        ```powershell
        Repositories      : {@{Languages=System.Object[]; IsPrivate=False; Stars=130;
                            CreatedDate=2/9/2024 10:45:11 AM; Name=Repo2}}
        AccessScopes      : {repo, user, gist, admin:org}
        AuthToken         : MyFirstSuperSecretToken
        TwoFactorMethods  : {TOTP, SMS}
        IsTwoFactorAuth   : True
        ApiRateLimits     : @{ResetTime=2/9/2025 11:15:11 AM; Remaining=4985; Limit=5000}
        UserPreferences   : @{CodeReview=System.Object[]; Notifications=; Theme=dark; DefaultBranch=main}
        SessionMetaData   : @{Device=Windows-PC; Location=; BrowserInfo=; SessionID=sess_abc123}
        LastLoginAttempts : {@{Success=True; Timestamp=2/9/2025 9:45:11 AM; IP=192.168.1.101}, @{Success=False}}
        ID                : GitHub/User-3
        Username          : john_doe
        LoginTime         : 2/9/2025 10:45:11 AM

        Repositories      : {@{Languages=System.Object[]; IsPrivate=False; Stars=130;
                            CreatedDate=2/9/2024 10:45:11 AM; Name=Repo2}}
        AccessScopes      : {repo, user, gist, admin:org}
        AuthToken         : MySuperSecretToken
        TwoFactorMethods  : {TOTP, SMS}
        IsTwoFactorAuth   : True
        ApiRateLimits     : @{ResetTime=2/9/2025 11:15:11 AM; Remaining=4985; Limit=5000}
        UserPreferences   : @{CodeReview=System.Object[]; Notifications=; Theme=dark; DefaultBranch=main}
        SessionMetaData   : @{Device=Windows-PC; Location=; BrowserInfo=; SessionID=sess_abc123}
        LastLoginAttempts : {@{Success=True; Timestamp=2/9/2025 9:45:11 AM; IP=192.168.1.101}, @{Success=False}}
        ID                : GitHub/User-8
        Username          : jane_doe
        LoginTime         : 2/9/2025 10:45:11 AM
        ```

        Retrieves all contexts from the context vault (directly from disk).

        .EXAMPLE
        Get-Context -Vault 'MyModule'

        Retrieves all contexts from the 'MyModule' vault.

        .EXAMPLE
        Get-Context -ID 'MySecret' -Vault 'MyModule'

        Retrieves the context called 'MySecret' from the 'MyModule' vault.

        .EXAMPLE
        'My*' | Get-Context -Vault 'MyModule'

        Output:
        ```powershell
        ID        : MyConfig
        Config    : {ConfigKey=ConfigValue}

        ID        : MySecret
        Key       : EncryptedValue
        AuthToken : EncryptedToken
        Favorite  : {Color=Blue; Number=7}

        ID        : MySettings
        Setting   : {SettingKey=SettingValue}
        Config    : {ConfigKey=ConfigValue}
        YourData  : {DataKey=DataValue}
        ```

        Retrieves all contexts that start with 'My' from the context vault (directly from disk).

        .EXAMPLE
        Get-Context -Vault 'MyModule' -ID 'default' -Type 'Module'

        Retrieves the default module context from the 'MyModule' vault.

        .EXAMPLE
        Get-Context -Vault 'MyModule' -Type 'Module'

        Retrieves all module contexts from the 'MyModule' vault.

        .OUTPUTS
        [System.Object]

        .NOTES
        Returns a list of contexts matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding stored properties.
        
        The -Type parameter determines whether to retrieve User contexts (default) or Module contexts.
        Module contexts are stored in the 'module' subdirectory, while User contexts are stored 
        in the 'user' subdirectory of each vault.

        .LINK
        https://psmodule.io/Context/Functions/Get-Context/
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault. Supports wildcards.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $ID = '*',

        # The name of the vault to store the context in.
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $Vault = '*',

        # The type of context to retrieve: 'User' or 'Module'.
        [Parameter()]
        [ValidateSet('User', 'Module')]
        [string] $Type = 'User'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        # Special handling for Module contexts: if no specific ID is given, get the active context
        if ($Type -eq 'Module' -and $ID.Count -eq 1 -and $ID[0] -eq '*') {
            foreach ($vaultName in $Vault) {
                $vaultObject = Get-ContextVault -Name $vaultName -ErrorAction SilentlyContinue
                if ($vaultObject) {
                    $activeContextName = Get-ActiveModuleContext -VaultPath $vaultObject.Path
                    Write-Verbose "[$stackPath] - Getting active module context '$activeContextName' for vault '$vaultName'"
                    $activeContext = Get-Context -ID $activeContextName -Vault $vaultName -Type 'Module'
                    if ($activeContext) {
                        $activeContext
                    }
                }
            }
            return
        }

        $contextInfos = Get-ContextInfo -ID $ID -Vault $Vault -Type $Type -ErrorAction Stop
        foreach ($contextInfo in $contextInfos) {
            Write-Verbose "Retrieving context - ID: [$($contextInfo.ID)], Vault: [$($contextInfo.Vault)], Type: [$Type]"
            try {
                if (-not (Test-Path -Path $contextInfo.Path)) {
                    Write-Warning "Context file does not exist: $($contextInfo.Path)"
                    continue
                }
                $keys = Get-ContextVaultKeyPair -Vault $contextInfo.Vault
                $params = @{
                    SealedBox  = $contextInfo.Context
                    PublicKey  = $keys.PublicKey
                    PrivateKey = $keys.PrivateKey
                }
                $contextObj = ConvertFrom-SodiumSealedBox @params
                ConvertFrom-ContextJson -JsonString $contextObj
            } catch {
                Write-Warning "Failed to read or decrypt context file: $($contextInfo.Path). Error: $_"
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
