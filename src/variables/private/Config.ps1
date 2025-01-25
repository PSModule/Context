$script:Config = [pscustomobject]@{
    Initialized  = $false                             # $script:Config.Initialized
    SecretPrefix = 'Context:'                         # $script:Config.SecretPrefix
    VaultName    = 'ContextVault'                     # $script:Config.VaultName
    VaultType    = 'Microsoft.PowerShell.SecretStore' # $script:Config.VaultType
}
