$script:Config = [pscustomobject]@{
    Initialized   = $false                                           # Has the vault been initialized?
    VaultPath     = Join-Path -Path $HOME -ChildPath '.contextvault' # Vault directory path
    SeedShardPath = 'vault.shard'                                    # Seed shard path (relative to VaultPath)
    PrivateKey    = $null                                            # Private key (populated on init)
    PublicKey     = $null                                            # Public key (populated on init)
}
