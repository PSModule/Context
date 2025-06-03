function Set-ContextVault {
    <#
        .SYNOPSIS
        Sets the context vault.

        .DESCRIPTION
        Sets the specified context vault for use. If the vault does not exist, it will be created.
        Once the context vault is set, the keys will be prepared for use.
        Each vault consists of multiple security shards, including a machine-specific shard,
        a user-specific shard, and a seed shard stored within the vault directory.

        .EXAMPLE
        Set-ContextVault -Name "MyModule"

        Initializes or loads the "MyModule" context vault, setting up necessary key pairs.

        .EXAMPLE
        Set-ContextVault

        For backward compatibility, loads the legacy single vault if no name is specified.

        .OUTPUTS
        None.

        .NOTES
        This function modifies the script-scoped configuration and prepares the vault for use.

        .LINK
        https://psmodule.io/Context/Functions/Set-ContextVault
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to set. If not specified, uses legacy single vault.
        [Parameter()]
        [string] $Name
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            if ($Name) {
                # Multi-vault mode
                Write-Verbose "Loading context vault [$Name]"
                
                # Check if keys are already cached
                if ($script:Config.VaultKeys.ContainsKey($Name)) {
                    Write-Verbose "Using cached keys for vault [$Name]"
                    $cachedKeys = $script:Config.VaultKeys[$Name]
                    $script:Config.PrivateKey = $cachedKeys.PrivateKey
                    $script:Config.PublicKey = $cachedKeys.PublicKey
                    $script:Config.CurrentVault = $Name
                    $script:Config.Initialized = $true
                    return
                }

                $vaultPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults" | Join-Path -ChildPath $Name
                $contextPath = Join-Path -Path $vaultPath -ChildPath $script:Config.ContextPath
                $seedShardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.SeedShardPath
                $configPath = Join-Path -Path $vaultPath -ChildPath $script:Config.VaultConfigPath

                Write-Verbose "Vault path: $vaultPath"
                $vaultExists = Test-Path $vaultPath
                Write-Verbose "Vault exists: $vaultExists"

                if (-not $vaultExists) {
                    Write-Verbose "Creating new vault [$Name]"
                    New-ContextVault -Name $Name -Description "Auto-created vault for $Name"
                }

                Write-Verbose 'Checking for existing seed shard'
                $seedShardExists = Test-Path $seedShardPath
                Write-Verbose "Seed shard exists: $seedShardExists"

                if (-not $seedShardExists) {
                    Write-Verbose 'Creating new seed shard'
                    $seedShardContent = [System.Guid]::NewGuid().ToString()
                    Set-Content -Path $seedShardPath -Value $seedShardContent -NoNewline
                } else {
                    $seedShardContent = Get-Content -Path $seedShardPath -Raw
                }

                $machineShard = [System.Environment]::MachineName
                $userShard = [System.Environment]::UserName
                $seed = $machineShard + $userShard + $seedShardContent
                
                # Check if Sodium module is available
                try {
                    $keys = New-SodiumKeyPair -Seed $seed
                } catch {
                    Write-Warning "Sodium module not available. Vault created but encryption keys not generated."
                    $keys = @{ PrivateKey = $null; PublicKey = $null }
                }
                
                # Cache the keys for this vault
                $script:Config.VaultKeys[$Name] = @{
                    PrivateKey = $keys.PrivateKey
                    PublicKey = $keys.PublicKey
                }
                
                $script:Config.PrivateKey = $keys.PrivateKey
                $script:Config.PublicKey = $keys.PublicKey
                $script:Config.CurrentVault = $Name
                Write-Verbose "Vault [$Name] initialized"
                $script:Config.Initialized = $true
            } else {
                # Legacy single vault mode for backward compatibility
                Write-Verbose "Loading legacy context vault from [$($script:Config.VaultPath)]"
                $vaultExists = Test-Path $script:Config.VaultPath
                Write-Verbose "Legacy vault exists: $vaultExists"

                if (-not $vaultExists) {
                    Write-Verbose 'Initializing new legacy vault'
                    $null = New-Item -Path $script:Config.VaultPath -ItemType Directory
                }

                Write-Verbose 'Checking for existing seed shard'
                $seedShardPath = Join-Path -Path $script:Config.VaultPath -ChildPath 'vault.shard'
                $seedShardExists = Test-Path $seedShardPath
                Write-Verbose "Seed shard exists: $seedShardExists"

                if (-not $seedShardExists) {
                    Write-Verbose 'Creating new seed shard'
                    try {
                        $keys = New-SodiumKeyPair
                        Set-Content -Path $seedShardPath -Value "$($keys.PrivateKey)$($keys.PublicKey)"
                    } catch {
                        Write-Warning "Sodium module not available. Creating placeholder shard."
                        Set-Content -Path $seedShardPath -Value "placeholder-key-data-sodium-required"
                    }
                }

                $seedShard = Get-Content -Path $seedShardPath
                $machineShard = [System.Environment]::MachineName
                $userShard = [System.Environment]::UserName
                $seed = $machineShard + $userShard + $seedShard
                
                # Check if Sodium module is available
                try {
                    $keys = New-SodiumKeyPair -Seed $seed
                } catch {
                    Write-Warning "Sodium module not available. Legacy vault loaded but encryption keys not generated."
                    $keys = @{ PrivateKey = $null; PublicKey = $null }
                }
                $script:Config.PrivateKey = $keys.PrivateKey
                $script:Config.PublicKey = $keys.PublicKey
                $script:Config.CurrentVault = $null
                Write-Verbose 'Legacy vault initialized'
                $script:Config.Initialized = $true
            }
        } catch {
            Write-Error $_
            throw "Failed to initialize context vault$(if ($Name) { " '$Name'" })"
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
