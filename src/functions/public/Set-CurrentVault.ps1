function Set-CurrentVault {
    <#
        .SYNOPSIS
        Sets the default context vault.

        .DESCRIPTION
        Sets the specified vault as the default vault for context operations.
        When no vault is explicitly specified in context functions,
        the default vault will be used.

        .PARAMETER Name
        The name of the vault to set as default.

        .EXAMPLE
        Set-CurrentVault -Name "PersonalVault"

        Sets "PersonalVault" as the default vault for context operations.

        .OUTPUTS
        None.

        .NOTES
        The default vault setting is persisted in the vault configuration file.
        All subsequent context operations will use this vault unless explicitly overridden.

        .LINK
        https://psmodule.io/Context/Functions/Set-CurrentVault/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to set as default
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            # Load vault configuration
            $vaultConfig = Get-VaultConfig
            
            # Check if vault exists
            if (-not $vaultConfig.Vaults -or -not ($vaultConfig.Vaults.PSObject.Properties.Name -contains $Name)) {
                throw "Vault '$Name' does not exist. Use Get-ContextVault to see available vaults."
            }

            if ($PSCmdlet.ShouldProcess($Name, 'Set as default vault')) {
                # Update default vault
                $vaultConfig.DefaultVault = $Name
                
                # Save configuration
                Set-VaultConfig -VaultConfig $vaultConfig
                
                # Update script config
                $script:Config.CurrentVault = $Name
                
                Write-Verbose "Set '$Name' as the default vault"
            }

        } catch {
            Write-Error "Failed to set default vault: $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}