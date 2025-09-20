function Get-ActiveModuleContextName {
    <#
        .SYNOPSIS
        Gets the name of the currently active module context for a vault.

        .DESCRIPTION
        Returns the name of the currently active module context for the specified vault.
        If no active context is set or the file is missing, returns 'default'.

        .EXAMPLE
        Get-ActiveModuleContextName -Vault 'MyModule'

        Returns the name of the active module context for 'MyModule' vault.

        .OUTPUTS
        [System.String]

        .NOTES
        This function reads the active context name from the vault's metadata,
        falling back to 'default' if not set.

        .LINK
        https://psmodule.io/Context/Functions/Get-ActiveModuleContextName/
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The name of the vault to check.
        [Parameter(Mandatory)]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $vaultObject = Get-ContextVault -Name $Vault
        $activeContextName = Get-ActiveModuleContext -VaultPath $vaultObject.Path
        Write-Verbose "[$stackPath] - Active module context for vault '$Vault': '$activeContextName'"
        return $activeContextName
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}