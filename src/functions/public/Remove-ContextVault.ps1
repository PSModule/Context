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
        try {
            # Load vault configuration
            $vaultConfig = Get-VaultConfig
            
            # Check if vault exists
            if (-not $vaultConfig.Vaults -or -not ($vaultConfig.Vaults.PSObject.Properties.Name -contains $VaultName)) {
                Write-Warning "Vault '$VaultName' does not exist"
                return
            }

            $vaultInfo = $vaultConfig.Vaults.$VaultName
            $confirmMessage = "Remove vault '$VaultName' and all its contexts from '$($vaultInfo.Path)'"
            
            if ($Force -or $PSCmdlet.ShouldProcess($VaultName, $confirmMessage)) {
                Write-Verbose "Removing vault '$VaultName' from path: [$($vaultInfo.Path)]"
                
                # Remove vault directory and all contents
                if (Test-Path $vaultInfo.Path) {
                    Remove-Item -Path $vaultInfo.Path -Recurse -Force
                    Write-Verbose "Removed vault directory: [$($vaultInfo.Path)]"
                }

                # Remove from in-memory contexts (if any from this vault are loaded)
                $contextsToRemove = @()
                foreach ($contextKey in $script:Contexts.Keys) {
                    $contextPath = $script:Contexts[$contextKey].Path
                    if ($contextPath -and $contextPath.StartsWith($vaultInfo.Path)) {
                        $contextsToRemove += $contextKey
                    }
                }
                
                foreach ($contextKey in $contextsToRemove) {
                    $null = $script:Contexts.TryRemove($contextKey, [ref]$null)
                    Write-Verbose "Removed context '$contextKey' from memory"
                }

                # Remove from vault configuration
                $vaultConfig.Vaults.PSObject.Properties.Remove($VaultName)
                
                # Clear default vault if this was the default
                if ($vaultConfig.DefaultVault -eq $VaultName) {
                    $vaultConfig.DefaultVault = $null
                    $script:Config.CurrentVault = $null
                    Write-Warning "Removed default vault. Use Set-CurrentVault to set a new default."
                }

                # Remove from script config
                if ($script:Config.Vaults.ContainsKey($VaultName)) {
                    $script:Config.Vaults.Remove($VaultName)
                }

                # Save configuration
                Set-VaultConfig -VaultConfig $vaultConfig
                
                Write-Verbose "Successfully removed vault '$VaultName'"
            }

        } catch {
            Write-Error "Failed to remove vault '$VaultName': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}