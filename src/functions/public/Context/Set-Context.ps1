#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context in the vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.

        .EXAMPLE
        Set-Context -Name 'MySecret'

        Create a context called 'MySecret' in the vault.

        .EXAMPLE
        Set-Context -Name 'MySecret' -Secret 'MySecret'

        Creates a context called 'MySecret' in the vault with the secret.

        .EXAMPLE
        Set-Context -Name 'MySecret' -Secret 'MySecret' -Variables @{ 'Key' = 'Value' }

        Creates a context called 'MySecret' in the vault with the secret and variables.
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The name of the context.
        [Parameter()]
        [Alias('Context', 'ContextName')]
        [string] $Name,

        # The secret of the context.
        [Parameter()]
        [object] $Secret = 'null',

        # The variables of the context.
        [Parameter()]
        [hashtable] $Variables
    )

    $contextVault = Get-ContextVault

    $param = @{
        Name  = $($script:Config.Name) + $Name
        Vault = $contextVault.Name
    }

    #Map secret based on type, to Secret or SecureStringSecret
    if ($Secret -is [System.Security.SecureString]) {
        $param['SecureStringSecret'] = $Secret
    } elseif ($Secret -is [System.String]) {
        $param['Secret'] = $Secret
    } else {
        throw 'Invalid secret type'
    }

    if ($Variables) {
        $param['Metadata'] = $Variables
    }
    if ($PSCmdlet.ShouldProcess('Set-Secret', $param)) {
        Set-Secret @param
    }
}
