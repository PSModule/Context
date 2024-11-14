#Requires -Modules @{ ModuleName = 'DynamicParams'; RequiredVersion = '1.1.8' }
#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

function Get-Context {
    <#
        .SYNOPSIS
        Retrieves a context from the context vault.

        .DESCRIPTION
        Retrieves contexts from a specified context vault. You can specify the name of the context to retrieve or use a wildcard pattern to retrieve
        multiple contexts. If no name is specified, all contexts from the context vault will be retrieved.
        Optionally, you can choose to retrieve the contexts as plain text by providing the -AsPlainText switch.

        .PARAMETER Name
        The name of the context to retrieve from the vault. Supports wildcard patterns.

        .EXAMPLE
        Get-Context

        Get all contexts from the context vault.

        .EXAMPLE
        Get-Context -Name 'MySecret'

        Get the context called 'MySecret' from the vault.

        .EXAMPLE
        Get-Context -Name 'My*'

        Get all contexts that match the pattern 'My*' from the vault.
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        # Switch to retrieve the contexts as plain text.
        [Parameter()]
        [switch] $AsPlainText
    )

    dynamicparam {
        $dynamicParamDictionary = New-DynamicParamDictionary

        $nameParam = @{
            Name                   = 'Name'
            Alias                  = 'Context', 'ContextName'
            Type                   = [string]
            SupportsWildcards      = $true
            ValidateSet            = (Get-Context).Name
            DynamicParamDictionary = $dynamicParamDictionary
        }
        New-DynamicParam @nameParam

        return $dynamicParamDictionary
    }

    begin {
        $Name = $PSBoundParameters.Name
    }

    process {
        $contextVault = Get-ContextVault

        Write-Verbose "Retrieving contexts from vault [$($contextVault.Name)]"
        $contexts = Get-SecretInfo -Vault $contextVault.Name | Where-Object { $_.Name -like "$($script:Config.Name)*" }
        if (-not $contexts) {
            Write-Error $_
            throw "No context found in vault [$($contextVault.Name)]"
        }

        if ($Name) {
            Write-Verbose "Filtering contexts with name pattern [$Name]"
            $contexts = $contexts | Where-Object { $_.Name -like $Name }
        }

        Write-Verbose "Found [$($contexts.Count)] contexts in context vault [$($contextVault.Name)]"
        foreach ($context in $contexts) {
            [pscustomobject](
                $context.Metadata + @{
                    Name   = $context.Name -replace "^$($script:Config.Name)"
                    Secret = Get-Secret -Name $context.Name -Vault $contextVault.Name -AsPlainText:$AsPlainText
                }
            )
        }
    }
}
