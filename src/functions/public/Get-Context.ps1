filter Get-Context {
    <#
        .SYNOPSIS
        Geta a context.

        .DESCRIPTION
        Retrieves a context from the preloaded contexts that are in memory.
        If no name is specified, all contexts will be returned.

        .EXAMPLE
        Get-Context

        Get all contexts from the context vault (in memory).

        .EXAMPLE
        Get-Context -ID 'MySecret'

        Get the context called 'MySecret' from the context vault (in memory).
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault.
        [Parameter()]
        [SupportsWildcards()]
        [string] $ID
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
        if (-not $script:Config.Initialized) {
            Set-ContextVault
            Import-Context
        }
    }

    process {
        try {
            if (-not $PSBoundParameters.ContainsKey('ID')) {
                Write-Debug "Retrieving all contexts"
                $script:Contexts.Values
            } elseif ([string]::IsNullOrEmpty($ID)) {
                Write-Debug "Return 0 contexts"
                return
            } elseif ($ID.Contains('*')) {
                Write-Debug "Retrieving contexts like [$ID]"
                $script:Contexts.Values | Where-Object { $_.ID -like $ID }
            } else {
                Write-Debug "Retrieving context [$ID]"
                $script:Contexts.Values | Where-Object { $_.ID -eq $ID }
            }
        } catch {
            Write-Error $_
            throw 'Failed to get context'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
