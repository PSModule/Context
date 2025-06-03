function Remove-ContextVault {
    <#
        .SYNOPSIS
        Removes a context vault.

        .DESCRIPTION
        Removes an existing context vault and all its context data. This operation
        is irreversible and will delete all contexts stored in the vault.

        .EXAMPLE
        Remove-ContextVault -Name "OldModule"

        Removes the "OldModule" vault and all its contexts.

        .EXAMPLE
        Remove-ContextVault -Name "OldModule" -Force

        Removes the "OldModule" vault without confirmation prompts.

        .OUTPUTS
        None

        .NOTES
        This operation permanently deletes the vault and all its contents.

        .LINK
        https://psmodule.io/Context/Functions/Remove-ContextVault/
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to remove.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $Name,

        # Skip confirmation prompts.
        [Parameter()]
        [switch] $Force
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $vaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults" | Join-Path -ChildPath $Name
            
            if (-not (Test-Path $vaultPath)) {
                throw "Vault '$Name' does not exist at: $vaultPath"
            }

            # Get vault info for confirmation message
            $vaultInfo = Get-ContextVault -Name $Name
            $contextCount = $vaultInfo.ContextCount

            $confirmMessage = "Remove vault '$Name' and all its $contextCount context(s)"

            if ($PSCmdlet.ShouldProcess($Name, $confirmMessage)) {
                Write-Verbose "Removing context vault [$Name] and all its contents"
                
                # Remove vault directory and all contents
                Remove-Item -Path $vaultPath -Recurse -Force
                
                # Clear from cache if it was the current vault
                if ($script:Config.CurrentVault -eq $Name) {
                    $script:Config.CurrentVault = $null
                    $script:Config.PrivateKey = $null
                    $script:Config.PublicKey = $null
                    $script:Config.Initialized = $false
                }
                
                # Remove from vault keys cache
                if ($script:Config.VaultKeys.ContainsKey($Name)) {
                    $script:Config.VaultKeys.Remove($Name)
                }
                
                Write-Verbose "Context vault [$Name] removed successfully"
            }
        } catch {
            Write-Error "Failed to remove context vault '$Name': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}