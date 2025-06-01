function Get-VaultConfig {
    <#
        .SYNOPSIS
        Gets the vault configuration from vaults.json.

        .DESCRIPTION
        Reads and returns the vault configuration from the vaults.json file.
        If the file doesn't exist, returns default configuration.

        .OUTPUTS
        [PSCustomObject] Vault configuration object.

        .NOTES
        This function handles vault metadata and default vault settings.
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param()

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $vaultConfigPath = Join-Path -Path $script:Config.VaultsPath -ChildPath $script:Config.VaultConfigFile
        
        if (Test-Path $vaultConfigPath) {
            try {
                $config = Get-Content -Path $vaultConfigPath | ConvertFrom-Json
                Write-Verbose "Loaded vault configuration from [$vaultConfigPath]"
                return $config
            } catch {
                Write-Warning "Failed to read vault configuration: $_"
                return [PSCustomObject]@{
                    DefaultVault = $null
                    Vaults = @{}
                }
            }
        } else {
            Write-Verbose "Vault configuration file not found, returning default configuration"
            return [PSCustomObject]@{
                DefaultVault = $null
                Vaults = @{}
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}