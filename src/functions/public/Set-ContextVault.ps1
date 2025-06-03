function Set-ContextVault {
    <#
        .SYNOPSIS
        Creates or updates a context vault configuration.

        .DESCRIPTION
        Declaratively creates or updates a context vault configuration. If the vault exists,
        its configuration is updated with the provided parameters. If the vault does not exist,
        it is created with the specified configuration.

        .EXAMPLE
        Set-ContextVault -Name "MyModule" -Description "Vault for MyModule contexts"

        Creates a new vault named "MyModule" or updates its description if it already exists.

        .EXAMPLE
        Set-ContextVault -Name "GitHub" -Description "Updated description for GitHub vault"

        Updates the description of the existing "GitHub" vault.

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        This function provides declarative vault configuration management. Use New-ContextVault
        when you specifically need to create a new vault and want an error if it already exists.

        .LINK
        https://psmodule.io/Context/Functions/Set-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create or update.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # Description for the vault.
        [Parameter()]
        [string] $Description = ''
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

            $vaultExists = Test-Path $vaultPath
            $configExists = Test-Path $configPath

            if ($PSCmdlet.ShouldProcess($Name, 'Set context vault configuration')) {
                if ($vaultExists -and $configExists) {
                    # Update existing vault configuration
                    Write-Verbose "Updating configuration for existing vault [$Name]"
                    
                    try {
                        $existingConfig = Get-Content -Path $configPath | ConvertFrom-Json
                        
                        # Update the configuration with new values
                        $vaultConfig = @{
                            Name = $Name
                            Description = $Description
                            Created = $existingConfig.Created
                            Version = $existingConfig.Version
                            LastModified = Get-Date
                        }
                        
                        $vaultConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath
                        
                        Write-Verbose "Vault configuration for [$Name] updated successfully"
                    } catch {
                        Write-Warning "Failed to read existing vault configuration, recreating: $_"
                        # Fall back to creating new configuration
                        $vaultConfig = @{
                            Name = $Name
                            Description = $Description
                            Created = Get-Date
                            Version = '1.0'
                        }
                        $vaultConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath
                    }
                } elseif ($vaultExists) {
                    # Vault directory exists but no configuration - repair it
                    Write-Verbose "Repairing vault configuration for existing vault [$Name]"
                    
                    # Ensure context directory exists
                    if (-not (Test-Path $contextPath)) {
                        $null = New-Item -Path $contextPath -ItemType Directory -Force
                    }
                    
                    # Create configuration
                    $vaultConfig = @{
                        Name = $Name
                        Description = $Description
                        Created = (Get-Item $vaultPath).CreationTime
                        Version = '1.0'
                    }
                    $vaultConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath
                    
                    # Generate shard if missing
                    if (-not (Test-Path $shardPath)) {
                        $seedShardContent = [System.Guid]::NewGuid().ToString()
                        Set-Content -Path $shardPath -Value $seedShardContent -NoNewline
                    }
                    
                    Write-Verbose "Vault configuration for [$Name] repaired successfully"
                } else {
                    # Create new vault
                    Write-Verbose "Creating new vault [$Name]"
                    
                    # Create vault directories
                    $null = New-Item -Path $vaultPath -ItemType Directory -Force
                    $null = New-Item -Path $contextPath -ItemType Directory -Force

                    Write-Verbose "Generating encryption keys for vault [$Name]"
                    
                    # Generate unique encryption keys for this vault
                    $seedShardContent = [System.Guid]::NewGuid().ToString()
                    
                    # Save the seed shard
                    Set-Content -Path $shardPath -Value $seedShardContent -NoNewline

                    # Create vault configuration
                    $vaultConfig = @{
                        Name = $Name
                        Description = $Description
                        Created = Get-Date
                        Version = '1.0'
                    }

                    $vaultConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath

                    Write-Verbose "Context vault [$Name] created successfully"
                }

                # Read the final configuration to return consistent output
                $finalConfig = Get-Content -Path $configPath | ConvertFrom-Json
                
                # Count contexts in the vault
                $contextCount = 0
                if (Test-Path $contextPath) {
                    $contextCount = (Get-ChildItem -Path $contextPath -Filter "*.json" -File).Count
                }

                # Return vault information
                [PSCustomObject]@{
                    Name = $Name
                    Description = $finalConfig.Description
                    Path = $vaultPath
                    ContextPath = $contextPath
                    Created = [DateTime]$finalConfig.Created
                    LastModified = if ($finalConfig.PSObject.Properties['LastModified']) { [DateTime]$finalConfig.LastModified } else { $null }
                    Version = $finalConfig.Version
                    ContextCount = $contextCount
                }
            }
        } catch {
            Write-Error "Failed to set context vault '$Name': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}