class ContextInfo {
    [string] $ID
    [string] $Path
    [string] $Vault
    [string] $Context

    ContextInfo() {}

    ContextInfo([PSCustomObject]$Object) {
        $this.ID = $Object.ID
        $this.Path = $Object.Path
        $this.Vault = $Object.Vault
        $this.Context = $Object.Context
    }
}
