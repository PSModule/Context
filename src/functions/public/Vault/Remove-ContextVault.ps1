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
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'By Name')]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # The vault object to remove.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'As ContextVault')]
        [ContextVault[]] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'By Name' {
                foreach ($vaultName in $Name) {
                    $vaults = Get-ContextVault -Name $vaultName

                    foreach ($vaultItem in $vaults) {
                        Write-Verbose "Removing ContextVault [$($vaultItem.Name)] at path [$($vaultItem.Path)]"
                        if ($PSCmdlet.ShouldProcess("ContextVault: [$($vaultItem.Name)]", 'Remove')) {
                            Remove-Item -Path $vaultItem.Path -Recurse -Force
                            Write-Verbose "ContextVault [$($vaultItem.Name)] removed successfully."
                        }
                    }
                }
            }
            'As ContextVault' {
                $Vault.Name | Remove-ContextVault
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
