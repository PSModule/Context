$script:Config = [pscustomobject]@{
    ConfigFolderPath = Join-Path -Path $HOME -ChildPath '.contextvaults'        # Parent directory for all vaults
    VaultsFolderPath = Join-Path -Path $HOME -ChildPath '.contextvaults/vaults' # Directory where vaults are stored
    Valuts = @{}
}


$vaults = @{
    'default' = [pscustomobject]@{
        Name        = 'default'
        Description = 'Default vault for Context'
        Path        = Join-Path -Path $script:Config.ConfigFolderPath -ChildPath 'default'
        Shard       = $script:Config.SeedShardFileName
        PrivateKey = $null                                             # Private key (populated on init)
        PublicKey = $null                                             # Public key (populated on init)
        SeedShardFileName = 'vault.shard'                                     # Seed shard path (relative to VaultPath)
    }
}
