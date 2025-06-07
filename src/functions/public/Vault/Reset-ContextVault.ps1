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
        [ArgumentCompleter({ Complete-ContextVaultName @args })]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # The vault object to reset.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'As ContextVault')]
        [ContextVault[]] $InputObject
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'By Name' {
                foreach ($vaultName in $Name) {
                    foreach ($vault in ($vaults | Where-Object { $_.Name -like $vaultName })) {
                        Write-Verbose "Resetting ContextVault [$($vault.Name)] at path [$($vault.Path)]"
                        if ($PSCmdlet.ShouldProcess("ContextVault: [$($vault.Name)]", 'Reset')) {
                            Remove-ContextVault -Name $($vault.Name) -Confirm:$false
                            Set-ContextVault -Name $($vault.Name)
                            Write-Verbose "ContextVault [$($vault.Name)] reset successfully."
                        }
                    }
                }
            }
            'As ContextVault' {
                $InputObject.Name | Reset-ContextVault
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
