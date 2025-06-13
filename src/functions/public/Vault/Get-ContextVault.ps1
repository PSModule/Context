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
        ContextVault

        .LINK
        https://psmodule.io/Context/Functions/Vault/Get-ContextVault/
    #>
    [OutputType([ContextVault])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve. Supports wildcards.
        [Parameter()]
        [ArgumentCompleter({ Complete-ContextVaultName @args })]
        [SupportsWildcards()]
        [string[]] $Name = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        if (-not (Test-Path -Path $script:Config.RootPath)) {
            return
        }
        $vaults = Get-ChildItem $script:Config.RootPath -Directory
    }

    process {
        foreach ($nameItem in $Name) {
            foreach ($vault in ($vaults | Where-Object { $_.Name -like $nameItem })) {
                [ContextVault]::new($vault.Name, $vault.FullName)
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
