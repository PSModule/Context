function Switch-ModuleContext {
    <#
        .SYNOPSIS
        Switches the active module context for a vault.

        .DESCRIPTION
        Changes the active module context for the specified vault. The context must already exist.
        This affects which module context is returned when using Get-Context with -Type Module
        without specifying a specific ID.

        .PARAMETER Vault
        The name of the vault containing the module contexts.

        .PARAMETER ContextName
        The name of the module context to set as active.

        .PARAMETER PassThru
        Return information about the newly active context.

        .EXAMPLE
        Switch-ModuleContext -Vault 'MyModule' -ContextName 'staging'

        Switches the active module context to 'staging' for the 'MyModule' vault.

        .EXAMPLE
        Switch-ModuleContext -Vault 'MyModule' -ContextName 'default' -PassThru

        Switches back to the default module context and returns the context data.

        .OUTPUTS
        [PSCustomObject] (when -PassThru is specified)

        .NOTES
        The specified context must exist before it can be set as active.
        If the context doesn't exist, an error will be thrown.

        .LINK
        https://psmodule.io/Context/Functions/Switch-ModuleContext/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault containing the module contexts.
        [Parameter(Mandatory)]
        [string] $Vault,

        # The name of the module context to set as active.
        [Parameter(Mandatory)]
        [string] $ContextName,

        # Return information about the newly active context.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        # Verify the context exists
        $contextInfo = Get-ContextInfo -ID $ContextName -Vault $Vault -Type 'Module'
        if (-not $contextInfo) {
            throw "Module context '$ContextName' not found in vault '$Vault'"
        }

        $vaultObject = Get-ContextVault -Name $Vault
        if ($PSCmdlet.ShouldProcess("vault '$Vault'", "Switch active module context to '$ContextName'")) {
            Set-ActiveModuleContext -VaultPath $vaultObject.Path -ContextName $ContextName
            Write-Verbose "[$stackPath] - Switched active module context to '$ContextName'"

            if ($PassThru) {
                Get-Context -ID $ContextName -Vault $Vault -Type 'Module'
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}

function Get-ActiveModuleContextName {
    <#
        .SYNOPSIS
        Gets the name of the currently active module context for a vault.

        .DESCRIPTION
        Returns the name of the currently active module context for the specified vault.
        If no active context is set or the file is missing, returns 'default'.

        .PARAMETER Vault
        The name of the vault to check.

        .EXAMPLE
        Get-ActiveModuleContextName -Vault 'MyModule'

        Returns the name of the active module context for 'MyModule' vault.

        .OUTPUTS
        [System.String]

        .NOTES
        This function reads the active context name from the vault's metadata,
        falling back to 'default' if not set.

        .LINK
        https://psmodule.io/Context/Functions/Get-ActiveModuleContextName/
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The name of the vault to check.
        [Parameter(Mandatory)]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $vaultObject = Get-ContextVault -Name $Vault
        $activeContextName = Get-ActiveModuleContext -VaultPath $vaultObject.Path
        Write-Verbose "[$stackPath] - Active module context for vault '$Vault': '$activeContextName'"
        return $activeContextName
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}