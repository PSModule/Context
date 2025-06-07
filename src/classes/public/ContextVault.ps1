class ContextVault {
    [string] $Name
    [string] $Path

    ContextVault() {}

    ContextVault([string] $name, [string] $path) {
        $this.Name = $name
        $this.Path = $path
    }

    [string] ToString() {
        return $this.Name
    }
}
