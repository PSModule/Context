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
        ID        : Default
        Context   : {Property1=Value1, Property2=Value2}
        ```

        Retrieves all contexts from the context vault (in memory).

        .EXAMPLE
        Get-Context -ID 'MySecret'

        Output:
        ```powershell
        ID        : MySecret
        Context   : {Key=EncryptedValue}
        ```

        Retrieves the context called 'MySecret' from the context vault (in memory).

        .EXAMPLE
        Get-Context -ID 'My*'

        Output:
        ```powershell
        ID        : MyConfig
        Context   : {ConfigKey=ConfigValue}
        ```

        Retrieves all contexts that start with 'My' from the context vault (in memory).

        .OUTPUTS
        System.Object. Returns a list of contexts matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding stored properties.

        .LINK
        https://psmodule.io/Context/Functions/Get-Context/
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault. Supports wildcards.
        [Parameter()]
        [AllowEmptyString()]
        [SupportsWildcards()]
        [string] $ID = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"

        if (-not $script:Config.Initialized) {
            Set-ContextVault
        }
    }

    process {
        try {
            Write-Debug "Retrieving contexts - ID: [$ID]"
            $script:Contexts.Values | Where-Object { $_.ID -like $ID } | Select-Object -ExpandProperty Context

        } catch {
            Write-Error $_
            throw 'Failed to get context'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
