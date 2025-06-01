function Get-ContextInfo {
    <#
        .SYNOPSIS
        Retrieves info about a context from the in-memory context vault.

        .DESCRIPTION
        Retrieves info about context from the loaded contexts stored in memory.
        If no ID is specified, all available info on contexts will be returned.
        Wildcards are supported to match multiple contexts.

        .EXAMPLE
        Get-ContextInfo

        Output:
        ```powershell
        ID   : MySettings
        Path : ...\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json

        ID   : MyConfig
        Path : ...\feacc853-5bea-48d1-b751-41ce9768d48e.json

        ID   : MySecret
        Path : ...\3e223259-f242-4e97-91c8-f0fd054cfea7.json

        ID   : Data
        Path : ...\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json

        ID   : PSModule.GitHub
        Path : ...\feacc853-5bea-48d1-b751-41ce9768d48e.json
        ```

        Retrieves all contexts from the context vault (in memory).

        .EXAMPLE
        Get-ContextInfo -ID 'MySecret'

        Output:
        ```powershell
        ID   : MySecret
        Path : ...\3e223259-f242-4e97-91c8-f0fd054cfea7.json
        ```

        Retrieves the context called 'MySecret' from the context vault (in memory).

        .EXAMPLE
        'My*' | Get-ContextInfo

        Output:
        ```powershell
        ID   : MyConfig
        Path : .../feacc853-5bea-48d1-b751-41ce9768d48e.json

        ID   : MySecret
        Path : .../3e223259-f242-4e97-91c8-f0fd054cfea7.json

        ID   : MySettings
        Path : .../b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json
        ```

        Retrieves all contexts that start with 'My' from the context vault (in memory).

        .OUTPUTS
        [System.Object]

        .NOTES
        Returns a list of context information matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding path to where the context is stored on disk.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextInfo/
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
        [string[]] $ID = '*',

        # The name of the vault to retrieve context info from.
        [Parameter()]
        [string] $VaultName
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"

        if (-not $script:Config.Initialized) {
            if ($VaultName) {
                Set-ContextVault -VaultName $VaultName
            } else {
                Set-ContextVault
            }
        } elseif ($VaultName -and $VaultName -ne $script:Config.CurrentVault) {
            # Switch to specified vault
            Set-ContextVault -VaultName $VaultName
        }
    }

    process {
        Write-Verbose "Retrieving context info - ID: [$ID]"
        foreach ($item in $ID) {
            $script:Contexts.Values | Where-Object { $_.ID -like $item } | Select-Object -ExcludeProperty Context
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
