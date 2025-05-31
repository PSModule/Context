function Set-VaultConfig {
    <#
        .SYNOPSIS
        Sets the vault configuration to vaults.json.

        .DESCRIPTION
        Writes the vault configuration to the vaults.json file.
        Creates the vaults directory if it doesn't exist.

        .PARAMETER VaultConfig
        The vault configuration object to save.

        .OUTPUTS
        None.

        .NOTES
        This function persists vault metadata and default vault settings.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $VaultConfig
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        if (-not (Test-Path $script:Config.VaultsPath)) {
            Write-Verbose "Creating vaults directory: [$($script:Config.VaultsPath)]"
            $null = New-Item -Path $script:Config.VaultsPath -ItemType Directory -Force
        }

        $vaultConfigPath = Join-Path -Path $script:Config.VaultsPath -ChildPath $script:Config.VaultConfigFile
        
        if ($PSCmdlet.ShouldProcess($vaultConfigPath, 'Save vault configuration')) {
            try {
                $VaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $vaultConfigPath
                Write-Verbose "Saved vault configuration to [$vaultConfigPath]"
            } catch {
                Write-Error "Failed to save vault configuration: $_"
                throw
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}