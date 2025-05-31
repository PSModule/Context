#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.2' }

function Set-ContextVault {
    <#
        .SYNOPSIS
        Sets the context vault.

        .DESCRIPTION
        Sets the context vault. If the vault does not exist, it will be initialized.
        Once the context vault is set, it will be imported into memory.
        The vault consists of multiple security shards, including a machine-specific shard,
        a user-specific shard, and a seed shard stored within the vault directory.
        Supports both legacy single vault and new multi-vault configurations.

        .PARAMETER VaultName
        Optional name of the vault to set. If not specified, uses the default vault.
        For backward compatibility, if no vaults are configured, initializes legacy vault.

        .EXAMPLE
        Set-ContextVault

        Initializes or loads the default context vault, setting up necessary key pairs.

        .EXAMPLE
        Set-ContextVault -VaultName "WorkVault"

        Initializes or loads the specified vault "WorkVault".

        .OUTPUTS
        None.

        .NOTES
        This function modifies the script-scoped configuration and imports the vault.
        Provides backward compatibility with legacy single vault setups.

        .LINK
        https://psmodule.io/Context/Functions/Set-ContextVault
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Optional name of the vault to set
        [Parameter()]
        [string] $VaultName
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            # Check for legacy vault migration or multi-vault setup
            $vaultConfig = Get-VaultConfig
            $legacyVaultExists = Test-Path $script:Config.VaultPath
            $multiVaultsExist = $vaultConfig.Vaults -and $vaultConfig.Vaults.PSObject.Properties.Count -gt 0

            # Determine which vault to use
            $targetVaultName = $null
            $targetVaultPath = $null

            if ($VaultName) {
                # Specific vault requested
                if (-not $multiVaultsExist -or -not ($vaultConfig.Vaults.PSObject.Properties.Name -contains $VaultName)) {
                    throw "Vault '$VaultName' does not exist. Use New-ContextVault to create it first."
                }
                $targetVaultName = $VaultName
                $targetVaultPath = $vaultConfig.Vaults.$VaultName.Path
            } elseif ($multiVaultsExist -and $vaultConfig.DefaultVault) {
                # Use default vault from multi-vault setup
                $targetVaultName = $vaultConfig.DefaultVault
                $targetVaultPath = $vaultConfig.Vaults.($vaultConfig.DefaultVault).Path
            } elseif ($legacyVaultExists -and -not $multiVaultsExist) {
                # Legacy vault exists, migrate to multi-vault
                Write-Verbose "Legacy vault detected, migrating to multi-vault structure"
                $targetVaultName = "default"
                $targetVaultPath = $script:Config.VaultPath
                
                # Migrate legacy vault to multi-vault structure
                if (-not (Test-Path $script:Config.VaultsPath)) {
                    $null = New-Item -Path $script:Config.VaultsPath -ItemType Directory -Force
                }
                
                $defaultVaultPath = Join-Path -Path $script:Config.VaultsPath -ChildPath "default"
                if (-not (Test-Path $defaultVaultPath)) {
                    Write-Verbose "Moving legacy vault to multi-vault structure"
                    Move-Item -Path $script:Config.VaultPath -Destination $defaultVaultPath
                }
                
                # Update configuration
                $vaultInfo = [PSCustomObject]@{
                    Name = "default"
                    Path = $defaultVaultPath
                    Created = Get-Date
                }
                
                if (-not $vaultConfig.Vaults) {
                    $vaultConfig.Vaults = [PSCustomObject]@{}
                }
                $vaultConfig.Vaults | Add-Member -MemberType NoteProperty -Name "default" -Value $vaultInfo
                $vaultConfig.DefaultVault = "default"
                Set-VaultConfig -VaultConfig $vaultConfig
                
                $targetVaultPath = $defaultVaultPath
            } else {
                # No vaults exist, create default vault
                Write-Verbose "No vaults found, creating default vault"
                New-ContextVault -Name "default"
                $vaultConfig = Get-VaultConfig
                $targetVaultName = "default"
                $targetVaultPath = $vaultConfig.Vaults.default.Path
            }

            Write-Verbose "Loading context vault '$targetVaultName' from [$targetVaultPath]"
            $vaultExists = Test-Path $targetVaultPath
            Write-Verbose "Vault exists: $vaultExists"

            if (-not $vaultExists) {
                Write-Verbose 'Initializing new vault'
                $null = New-Item -Path $targetVaultPath -ItemType Directory
            }

            Write-Verbose 'Checking for existing seed shard'
            $seedShardPath = Join-Path -Path $targetVaultPath -ChildPath $script:Config.SeedShardPath
            $seedShardExists = Test-Path $seedShardPath
            Write-Verbose "Seed shard exists: $seedShardExists"

            if (-not $seedShardExists) {
                Write-Verbose 'Creating new seed shard'
                $keys = New-SodiumKeyPair
                Set-Content -Path $seedShardPath -Value "$($keys.PrivateKey)$($keys.PublicKey)"
            }

            $seedShard = Get-Content -Path $seedShardPath
            $machineShard = [System.Environment]::MachineName
            $userShard = [System.Environment]::UserName
            #$userInputShard = Read-Host -Prompt 'Enter a seed shard' # Eventually 4 shards. +1 for user input.
            $seed = $machineShard + $userShard + $seedShard + $userInputShard
            $keys = New-SodiumKeyPair -Seed $seed
            $script:Config.PrivateKey = $keys.PrivateKey
            $script:Config.PublicKey = $keys.PublicKey
            $script:Config.CurrentVault = $targetVaultName
            $script:Config.VaultPath = $targetVaultPath  # Update current vault path
            Write-Verbose "Vault '$targetVaultName' initialized"
            $script:Config.Initialized = $true
        } catch {
            Write-Error $_
            throw 'Failed to initialize context vault'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
        Import-Context
    }
}
