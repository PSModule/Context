#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function New-ContextVault {
    <#
        .SYNOPSIS
        Creates a new context vault.

        .DESCRIPTION
        Creates a new named context vault with its own encryption domain and isolated storage.
        Each vault is stored under $HOME/.contextvaults/Vaults/<VaultName>/ and has its own
        encryption keys, context storage, and configuration.

        .EXAMPLE
        New-ContextVault -Name "MyModule"

        Creates a new context vault named "MyModule".

        .EXAMPLE
        New-ContextVault -Name "GitHub" -Description "Vault for GitHub-related contexts"

        Creates a new context vault named "GitHub" with a description.

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        Each vault maintains its own encryption keys and context storage for security isolation.

        .LINK
        https://psmodule.io/Context/Functions/New-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create.
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # Optional description for the vault.
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

            if (Test-Path $vaultPath) {
                throw "Vault '$Name' already exists at: $vaultPath"
            }

            if ($PSCmdlet.ShouldProcess($Name, 'Create context vault')) {
                Write-Verbose "Creating vault directory structure for [$Name]"
                
                # Create vault directories
                $null = New-Item -Path $vaultPath -ItemType Directory -Force
                $null = New-Item -Path $contextPath -ItemType Directory -Force

                Write-Verbose "Generating encryption keys for vault [$Name]"
                
                # Generate unique encryption keys for this vault
                $machineShard = [System.Environment]::MachineName
                $userShard = [System.Environment]::UserName
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

                # Return vault information
                [PSCustomObject]@{
                    Name = $Name
                    Description = $Description
                    Path = $vaultPath
                    ContextPath = $contextPath
                    Created = $vaultConfig.Created
                }
            }
        } catch {
            Write-Error "Failed to create context vault '$Name': $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}