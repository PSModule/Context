function Get-Context {
    <#
        .SYNOPSIS
        Retrieves a context from the in-memory context vault.

        .DESCRIPTION
        Retrieves a context from the loaded contexts stored in memory.
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

        Retrieves all contexts from the context vault (in memory).

        .EXAMPLE
        Get-Context -ID 'MySecret'

        Retrieves the context called 'MySecret' from the vault.

        .EXAMPLE
        'My*' | Get-Context

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

        Retrieves all contexts that start with 'My' from the context vault (in memory).

        .OUTPUTS
        [System.Object]

        .NOTES
        Returns a list of contexts matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding stored properties.

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
        [AllowEmptyString()]
        [SupportsWildcards()]
        [string[]] $ID = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"

        if (-not $script:Config.Initialized) {
            Set-ContextVault
        }
    }

    process {
        Write-Verbose "Retrieving contexts - ID: [$($ID -join ', ')]"
        foreach ($item in $ID) {
            Write-Verbose "Retrieving contexts - ID: [$item]"
            $script:Contexts.Values | Where-Object { $_.ID -like $item } | Select-Object -ExpandProperty Context
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
