function Reset-ContextVault {
    <#
        .SYNOPSIS
        Resets a context vault.

        .DESCRIPTION
        Resets an existing context vault by deleting all contexts and regenerating
        the encryption keys. The vault configuration and name are preserved.

        .EXAMPLE
        Reset-ContextVault -Name 'MyModule'

        Resets the 'MyModule' vault, deleting all contexts and regenerating encryption keys.

        .OUTPUTS
        [ContextVault]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Reset-ContextVault/
    #>
    [OutputType([ContextVault])]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to reset.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'By Name')]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # The vault object to reset.
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
                        if ($PSCmdlet.ShouldProcess("ContextVault: [$($vaultItem.Name)]", 'Reset')) {
                            Write-Verbose "Resetting ContextVault [$($vaultItem.Name)] at path [$($vaultItem.Path)]"
                            Remove-ContextVault -Name $($vaultItem.Name) -Confirm:$false
                            Set-ContextVault -Name $($vaultItem.Name)
                            Write-Verbose "ContextVault [$($vaultItem.Name)] reset successfully."
                        }
                    }
                }
            }
            'As ContextVault' {
                $Vault.Name | Reset-ContextVault
            }
        }

    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
