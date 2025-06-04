class ContextVault {
    [string] $Name
    [string] $Path
    [string] $ContextFolderPath
    [string] $ShardFilePath
    [string] $VaultConfigFilePath

    ContextVault() {}

    ContextVault([string] $name, [string] $path) {
        $this.Name = $name
        $this.Path = $path
    }

    ContextVault([string] $name, [string] $path, [string] $contextFolderPath, [string] $shardFilePath, [string] $vaultConfigFilePath) {
        $this.Name = $name
        $this.Path = $path
        $this.ContextFolderPath = $contextFolderPath
        $this.ShardFilePath = $shardFilePath
        $this.VaultConfigFilePath = $vaultConfigFilePath
    }
}
