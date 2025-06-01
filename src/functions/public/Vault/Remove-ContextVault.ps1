function Remove-ContextVault {
    <#
        .SYNOPSIS
        Removes a context vault.

        .DESCRIPTION
        Removes a context vault and all its associated contexts and files.
        If the removed vault was the default vault, no default will be set.

        .PARAMETER VaultName
        The name of the vault to remove.

        .PARAMETER Force
        Forces removal without confirmation prompts.

        .EXAMPLE
        Remove-ContextVault -VaultName "OldVault"

        Removes the vault named "OldVault" and all its contexts.

        .EXAMPLE
        Remove-ContextVault -VaultName "OldVault" -Force

        Forcefully removes the vault without confirmation prompts.

        .OUTPUTS
        None.

        .NOTES
        This operation permanently deletes the vault directory and all contexts within it.
        Use with caution as this action cannot be undone.

        .LINK
        https://psmodule.io/Context/Functions/Remove-ContextVault/
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to remove
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $VaultName,

        # Forces removal without confirmation
        [Parameter()]
        [switch] $Force
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
