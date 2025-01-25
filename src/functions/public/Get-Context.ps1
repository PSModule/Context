function Get-Context {
    <#
        .SYNOPSIS
        Gets a context.

        .DESCRIPTION
        Gets a context from the loaded contexts that are in memory.
        If no name is specified, all contexts will be returned.

        .EXAMPLE
        Get-Context

        Get all contexts from the context vault (in memory).

        .EXAMPLE
        Get-Context -ID 'MySecret'

        Get the context called 'MySecret' from the context vault (in memory).

        .EXAMPLE
        Get-Context -ID 'My*'

        Get all contexts that start with 'My' from the context vault (in memory).
    #>
    [OutputType([object])]
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    param(
        # The name of the context to retrieve from the vault.
        [Parameter(
            Mandatory,
            ParameterSetName = 'ByID'
        )]
        [AllowEmptyString()]
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
            switch ($PSCmdlet.ParameterSetName) {
                'ByID' {
                    Write-Debug "Retrieving contexts like [$ID]"
                    return $script:Contexts.Values | Where-Object { $_.ID -like $ID }
                }
                '__AllParameterSets' {
                    Write-Debug 'Retrieving all contexts'
                    return $script:Contexts.Values
                }
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
