#Requires -Modules @{ ModuleName = 'DynamicParams'; RequiredVersion = '1.1.8' }
#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

filter Remove-Context {
    <#
        .SYNOPSIS
        Remove a context from the context vault.

        .DESCRIPTION
        This function removes a context from the vault. It supports removing a single context by name,
        multiple contexts using wildcard patterns, and can also accept input from the pipeline.
        If the specified context(s) exist, they will be removed from the vault.

        .PARAMETER Name
        The name of the secret vault.

        .EXAMPLE
        Remove-Context -Name 'MySecret'

        Removes the context called 'MySecret' from the vault.

        .EXAMPLE
        'MySecret*' | Remove-Context

        Removes all contexts matching the pattern 'MySecret*' from the vault.

        .EXAMPLE
        Get-Context -Name 'MySecret*' | Remove-Context

        Retrieves all contexts matching the pattern 'MySecret*' and removes them from the vault.
    #>
    [OutputType([void])]
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    dynamicparam {
        $dynamicParamDictionary = New-DynamicParamDictionary

        $nameParam = @{
            Name                            = 'Name'
            Alias                           = 'Context', 'ContextName'
            Type                            = [string]
            Mandatory                       = $true
            ValueFromPipeline               = $true
            ValueFromPipelineByPropertyName = $true
            ValidateSet                     = (Get-Context).Name
            DynamicParamDictionary          = $dynamicParamDictionary
        }
        New-DynamicParam @nameParam

        return $dynamicParamDictionary
    }

    begin {
        $Name = $PSBoundParameters.Name
    }

    process {
        $contextVault = Get-ContextVault

        $contexts = Get-Context -Name $Name

        foreach ($context in $contexts) {
            if ($PSCmdlet.ShouldProcess('Remove-Secret', $context.Name)) {
                Remove-Secret -Name $context.Name -Vault $contextVault.Name
            }
        }
    }
}
