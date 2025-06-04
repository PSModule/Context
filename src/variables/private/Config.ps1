$script:Config = [pscustomobject]@{
    RootPath          = Join-Path -Path $HOME -ChildPath '.contextvaults'        # Base directory for context vaults
    VaultsPath        = Join-Path -Path $HOME -ChildPath '.contextvaults/Vaults' # Vaults subdirectory (relative to base directory)
    ContextFolderName = 'Contexts'                                               # Context subdirectory (relative to each vault)
    SeedShardFileName = 'shard'                                                  # Seed shard path (relative to each vault)
}
