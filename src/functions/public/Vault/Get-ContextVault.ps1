function Get-ContextVault {
    <#
        .SYNOPSIS
        Retrieves context vaults.

        .DESCRIPTION
        Retrieves context vaults. If no name is specified, all available vaults will be returned. Supports wildcard matching.

        .EXAMPLE
        Get-ContextVault

        Lists all available context vaults.

        .EXAMPLE
        Get-ContextVault -Name 'MyModule'

        Gets information about the 'MyModule' vault.

        .EXAMPLE
        Get-ContextVault -Name 'My*'

        Gets information about all vaults starting with 'My'.

        .OUTPUTS
        [PSCustomObject[]]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Get-ContextVault/
    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve. Supports wildcards.
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $Name = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        Get-ChildItem $script:Config.VaultsPath -Directory | Where-Object { $_.Name -like $Name } | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
