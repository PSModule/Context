function Rename-ContextVault {
    <#
        .SYNOPSIS
        Renames a context vault.

        .DESCRIPTION
        Renames an existing context vault by moving its directory and updating
        its configuration. All contexts and encryption keys are preserved.

        .EXAMPLE
        Rename-ContextVault -Name "OldModule" -NewName "NewModule"

        Renames the "OldModule" vault to "NewModule".

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        The vault's encryption keys and all contexts are preserved during the rename operation.

        .LINK
        https://psmodule.io/Context/Functions/Rename-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The current name of the vault.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $Name,

        # The new name for the vault.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $NewName
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $vaultsBasePath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults"
            $currentVaultPath = Join-Path -Path $vaultsBasePath -ChildPath $Name
            $newVaultPath = Join-Path -Path $vaultsBasePath -ChildPath $NewName
            
            if (-not (Test-Path $currentVaultPath)) {
                throw "Vault '$Name' does not exist at: $currentVaultPath"
            }

            if (Test-Path $newVaultPath) {
                throw "A vault with name '$NewName' already exists at: $newVaultPath"
            }

            if ($PSCmdlet.ShouldProcess("$Name -> $NewName", 'Rename context vault')) {
                Write-Verbose "Renaming context vault from [$Name] to [$NewName]"
                
                # Move the vault directory
                Move-Item -Path $currentVaultPath -Destination $newVaultPath
                
                # Update the vault configuration
                $configPath = Join-Path -Path $newVaultPath -ChildPath $script:Config.VaultConfigPath
                if (Test-Path $configPath) {
                    $config = Get-Content -Path $configPath | ConvertFrom-Json
                    $config.Name = $NewName
                    $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath
                }
                
                # Update runtime configuration if this was the current vault
                if ($script:Config.CurrentVault -eq $Name) {
                    $script:Config.CurrentVault = $NewName
                }
                
                # Update vault keys cache
                if ($script:Config.VaultKeys.ContainsKey($Name)) {
                    $keys = $script:Config.VaultKeys[$Name]
                    $script:Config.VaultKeys.Remove($Name)
                    $script:Config.VaultKeys[$NewName] = $keys
                }
                
                Write-Verbose "Context vault renamed successfully from [$Name] to [$NewName]"
                
                # Return updated vault information
                Get-ContextVault -Name $NewName
            }
        } catch {
            Write-Error "Failed to rename context vault from '$Name' to '$NewName': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}