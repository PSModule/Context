$script:Config = [pscustomobject]@{
    Initialized     = $false                                             # Has the vault been initialized?
    VaultsPath      = Join-Path -Path $HOME -ChildPath '.contextvaults' # Parent directory for all vaults
    VaultPath       = Join-Path -Path $HOME -ChildPath '.contextvault'  # Legacy single vault path (for backward compatibility)
    CurrentVault    = $null                                             # Name of the current/default vault
    SeedShardPath   = 'vault.shard'                                    # Seed shard path (relative to VaultPath)
    VaultConfigFile = 'vaults.json'                                    # Vault configuration file name
    PrivateKey      = $null                                             # Private key (populated on init)
    PublicKey       = $null                                             # Public key (populated on init)
    Vaults          = @{}                                              # Dictionary of vault configurations
}
