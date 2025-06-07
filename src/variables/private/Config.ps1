$script:Config = [pscustomobject]@{
    RootPath      = Join-Path -Path $HOME -ChildPath '.contextvaults'        # Base directory for context vaults
    ShardFileName = 'shard'                                                  # Shard path (relative to each vault)
}
