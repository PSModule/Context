function Remove-ContextVault {
    <#
        .SYNOPSIS
        Removes a context vault.

        .DESCRIPTION
        Removes an existing context vault and all its context data. This operation
        is irreversible and will delete all contexts stored in the vault.

        .EXAMPLE
        Remove-ContextVault -Name 'OldModule'

        Removes the 'OldModule' vault and all its contexts.

        .LINK
        https://psmodule.io/Context/Functions/Vault/Remove-ContextVault/
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to remove.
        [Parameter(Mandatory)]
        [string] $Name
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $vault = Get-ContextVaultInfo -Name $Name

        if (-not $vault) {
            Write-Error "Vault '$Name' does not exist."
            return
        }

        Write-Verbose "Removing ContextVault [$Name] at path [$($vault.VaultPath)]"
        if ($PSCmdlet.ShouldProcess("ContextVault: [$Name]", 'Remove')) {
            Remove-Item -Path $vault.VaultPath -Recurse -Force
            Write-Verbose "ContextVault [$Name] removed successfully."
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
