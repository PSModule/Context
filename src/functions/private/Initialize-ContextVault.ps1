#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }
#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretStore'; RequiredVersion = '1.0.6' }

function Initialize-ContextVault {
    <#
        .SYNOPSIS
        Initialize a context vault.

        .DESCRIPTION
        Initialize a context vault. If the vault does not exist, it will be created and registered.

        The SecretStore is created with the following parameters:
        - Authentication: None
        - PasswordTimeout: -1 (infinite)
        - Interaction: None
        - Scope: CurrentUser

        .EXAMPLE
        Initialize-ContextVault

        Initializes a context vault named 'ContextVault' using the 'Microsoft.PowerShell.SecretStore' module.
    #>
    [OutputType([Microsoft.PowerShell.SecretManagement.SecretVaultInfo])]
    [CmdletBinding()]
    param (
        # The name of the secret vault.
        [Parameter()]
        [string] $Name = $script:Config.Context.VaultName,

        # The type of the secret vault.
        [Parameter()]
        [string] $Type = $script:Config.Context.VaultType
    )
    $vault = Get-SecretVault | Where-Object { $_.ModuleName -eq $Type }
    if (-not $vault) {
        Write-Verbose "[$Type] - Configuring vault type"

        $vaultParameters = @{
            Authentication  = 'None'
            PasswordTimeout = -1
            Interaction     = 'None'
            Scope           = 'CurrentUser'
            WarningAction   = 'SilentlyContinue'
            Confirm         = $false
            Force           = $true
        }
        Reset-SecretStore @vaultParameters
        Write-Verbose "[$Type] - Done"

        Write-Verbose "[$Name] - Registering vault"
        $secretVault = @{
            Name         = $Name
            ModuleName   = $Type
            DefaultVault = $true
            Description  = 'SecretStore'
        }
        Register-SecretVault @secretVault
        Write-Verbose "[$Name] - Done"
    } else {
        Write-Verbose "[$Name] - Vault already registered"
    }

    Get-SecretVault | Where-Object { $_.ModuleName -eq $Type }

}
