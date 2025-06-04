class ContextVault {
    [string] $Name
    [string] $Path

    ContextVault([string] $name, [string] $path) {
        $this.Name = $name
        $this.Path = $path
    }
}
