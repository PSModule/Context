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
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'By Name')]
        [SupportsWildcards()]
        [string[]] $Name,

        # The vault object to remove.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'As ContextVault')]
        [ContextVault[]] $InputObject
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        $vaults = Get-ContextVault
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'By Name' {
                foreach ($vaultName in $Name) {
                    foreach ($vault in ($vaults | Where-Object { $_.Name -like $vaultName })) {
                        Write-Verbose "Removing ContextVault [$($vault.Name)] at path [$($vault.Path)]"
                        if ($PSCmdlet.ShouldProcess("ContextVault: [$($vault.Name)]", 'Remove')) {
                            Remove-Item -Path $vault.Path -Recurse -Force
                            Write-Verbose "ContextVault [$($vault.Name)] removed successfully."
                        }
                    }
                }
            }
            'As ContextVault' {
                $InputObject.Name | Remove-ContextVault
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
