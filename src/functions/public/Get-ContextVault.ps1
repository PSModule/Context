function Get-ContextVault {
    <#
        .SYNOPSIS
        Retrieves information about context vaults.

        .DESCRIPTION
        Retrieves information about context vaults. If no name is specified, 
        all available vaults will be returned. Supports wildcard matching.

        .EXAMPLE
        Get-ContextVault

        Lists all available context vaults.

        .EXAMPLE
        Get-ContextVault -Name "MyModule"

        Gets information about the "MyModule" vault.

        .EXAMPLE
        Get-ContextVault -Name "My*"

        Gets information about all vaults starting with "My".

        .OUTPUTS
        [PSCustomObject[]]

        .NOTES
        Returns vault metadata including name, description, path, and creation date.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextVault/
    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve. Supports wildcards.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [AllowEmptyString()]
        [SupportsWildcards()]
        [string[]] $Name = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $vaultsBasePath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults"
            
            if (-not (Test-Path $vaultsBasePath)) {
                Write-Verbose "No vaults directory found at: $vaultsBasePath"
                return
            }

            foreach ($namePattern in $Name) {
                Write-Verbose "Retrieving vaults matching pattern: [$namePattern]"
                
                $vaultDirs = Get-ChildItem -Path $vaultsBasePath -Directory | Where-Object { $_.Name -like $namePattern }
                
                foreach ($vaultDir in $vaultDirs) {
                    $configPath = Join-Path -Path $vaultDir.FullName -ChildPath $script:Config.VaultConfigPath
                    $contextPath = Join-Path -Path $vaultDir.FullName -ChildPath $script:Config.ContextPath
                    
                    try {
                        if (Test-Path $configPath) {
                            $config = Get-Content -Path $configPath | ConvertFrom-Json
                            
                            # Count contexts in the vault
                            $contextCount = 0
                            if (Test-Path $contextPath) {
                                $contextCount = (Get-ChildItem -Path $contextPath -Filter "*.json" -File).Count
                            }
                            
                            [PSCustomObject]@{
                                Name = $vaultDir.Name
                                Description = $config.Description
                                Path = $vaultDir.FullName
                                ContextPath = $contextPath
                                Created = [DateTime]$config.Created
                                Version = $config.Version
                                ContextCount = $contextCount
                            }
                        } else {
                            # Vault directory exists but no config - might be legacy or corrupted
                            Write-Warning "Vault directory exists but no configuration found: $($vaultDir.FullName)"
                            [PSCustomObject]@{
                                Name = $vaultDir.Name
                                Description = "(No configuration found)"
                                Path = $vaultDir.FullName
                                ContextPath = $contextPath
                                Created = $vaultDir.CreationTime
                                Version = "Unknown"
                                ContextCount = 0
                            }
                        }
                    } catch {
                        Write-Warning "Failed to read vault configuration for '$($vaultDir.Name)': $_"
                    }
                }
            }
        } catch {
            Write-Error "Failed to retrieve context vaults: $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}