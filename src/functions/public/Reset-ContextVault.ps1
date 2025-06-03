#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function Reset-ContextVault {
    <#
        .SYNOPSIS
        Resets a context vault.

        .DESCRIPTION
        Resets an existing context vault by deleting all contexts and regenerating
        the encryption keys. The vault configuration and name are preserved.

        .EXAMPLE
        Reset-ContextVault -Name "MyModule"

        Resets the "MyModule" vault, deleting all contexts and regenerating encryption keys.

        .EXAMPLE
        Reset-ContextVault -Name "MyModule" -Force

        Resets the "MyModule" vault without confirmation prompts.

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        This operation permanently deletes all contexts in the vault and generates new encryption keys.

        .LINK
        https://psmodule.io/Context/Functions/Reset-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to reset.
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
            $contextPath = Join-Path -Path $vaultPath -ChildPath $script:Config.ContextPath
            $shardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.SeedShardPath
            $configPath = Join-Path -Path $vaultPath -ChildPath $script:Config.VaultConfigPath
            
            if (-not (Test-Path $vaultPath)) {
                throw "Vault '$Name' does not exist at: $vaultPath"
            }

            # Get current vault info
            $vaultInfo = Get-ContextVault -Name $Name
            $contextCount = $vaultInfo.ContextCount

            $confirmMessage = "Reset vault '$Name' and delete all its $contextCount context(s)"
            
            if ($Force) {
                $PSCmdlet.ConfirmImpact = 'None'
            }

            if ($PSCmdlet.ShouldProcess($Name, $confirmMessage)) {
                Write-Verbose "Resetting context vault [$Name]"
                
                # Remove all context files
                if (Test-Path $contextPath) {
                    Get-ChildItem -Path $contextPath -Filter "*.json" -File | Remove-Item -Force
                    Write-Verbose "Removed all context files from vault [$Name]"
                }
                
                # Generate new encryption keys
                Write-Verbose "Generating new encryption keys for vault [$Name]"
                $seedShardContent = [System.Guid]::NewGuid().ToString()
                Set-Content -Path $shardPath -Value $seedShardContent -NoNewline
                
                # Clear cached keys
                if ($script:Config.VaultKeys.ContainsKey($Name)) {
                    $script:Config.VaultKeys.Remove($Name)
                }
                
                # Reset current vault if this was it
                if ($script:Config.CurrentVault -eq $Name) {
                    $script:Config.PrivateKey = $null
                    $script:Config.PublicKey = $null
                    $script:Config.Initialized = $false
                }
                
                Write-Verbose "Context vault [$Name] reset successfully"
                
                # Return updated vault information
                Get-ContextVault -Name $Name
            }
        } catch {
            Write-Error "Failed to reset context vault '$Name': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}