$script:Config = [pscustomobject]@{
    Initialized      = $false                                             # Has the vault been initialized?
    VaultPath        = Join-Path -Path $HOME -ChildPath '.contextvault'  # Legacy vault directory path (for backward compatibility)
    ContextVaultsPath = Join-Path -Path $HOME -ChildPath '.contextvaults' # New multi-vault base directory path
    SeedShardPath    = 'shard'                                           # Seed shard path (relative to each vault)
    VaultConfigPath  = 'config.json'                                     # Vault config path (relative to each vault)
    ContextPath      = 'Context'                                         # Context subdirectory (relative to each vault)
    PrivateKey       = $null                                             # Private key (populated on init)
    PublicKey        = $null                                             # Public key (populated on init)
    CurrentVault     = $null                                             # Currently active vault name
    VaultKeys        = @{}                                               # Cache for vault-specific keys (VaultName = @{PrivateKey, PublicKey})
}
