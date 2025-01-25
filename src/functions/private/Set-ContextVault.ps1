#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }
#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretStore'; RequiredVersion = '1.0.6' }

function Set-ContextVault {
    <#
        .SYNOPSIS
        Sets the context vault.

        .DESCRIPTION
        Sets the context vault. If the vault does not exist, it will be created and registered.

        The SecretStore is created with the following parameters:
        - Authentication: None
        - PasswordTimeout: -1 (infinite)
        - Interaction: None
        - Scope: CurrentUser

        .EXAMPLE
        Set-ContextVault

        Sets a context vault named 'ContextVault' using the 'Microsoft.PowerShell.SecretStore' module.

        .EXAMPLE
        Set-ContextVault -Name 'MyVault' -Type 'MyModule'

        Sets a context vault named 'MyVault' using the 'MyModule' module.

        .EXAMPLE
        Set-ContextVault -PassThru

        Sets a context vault using the default values and returns the secret vault object.
    #>
    [OutputType([Microsoft.PowerShell.SecretManagement.SecretVaultInfo])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The name of the context vault.
        [Parameter()]
        [string] $Name = $script:Config.VaultName,

        # The type of the context vault.
        [Parameter()]
        [string] $Type = $script:Config.VaultType,

        # Pass the vault through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $vault = Get-SecretVault -Verbose:$false | Where-Object { $_.ModuleName -eq $Type }
            if (-not $vault) {
                Write-Debug "[$Type] - Configuring vault type"

                $vaultParameters = @{
                    Authentication  = 'None'
                    PasswordTimeout = -1
                    Interaction     = 'None'
                    Scope           = 'CurrentUser'
                    WarningAction   = 'SilentlyContinue'
                    Confirm         = $false
                    Force           = $true
                    Verbose         = $false
                }
                if ($PSCmdlet.ShouldProcess('SecretStore', 'Reset')) {
                    Reset-SecretStore @vaultParameters
                }
                Write-Debug "[$Type] - Done"
                Write-Debug "[$Name] - Registering vault"
                $secretVault = @{
                    Name         = $Name
                    ModuleName   = $Type
                    DefaultVault = $true
                    Description  = 'SecretStore'
                    Verbose      = $false
                }
                if ($PSCmdlet.ShouldProcess('SecretVault', 'Register')) {
                    $vault = Register-SecretVault @secretVault -PassThru
                }
                Write-Debug "[$Name] - Done"
            }
            $script:Config.VaultName = $vault.Name
            Write-Debug "Connected to context vault [$($script:Config.VaultName)]"
            $script:Config.Initialized = $true
        } catch {
            Write-Error $_
            throw 'Failed to initialize context vault'
        }
        if ($PassThru) {
            $vault
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
