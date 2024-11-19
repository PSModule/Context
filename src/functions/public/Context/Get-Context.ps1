#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

filter Get-Context {
    <#
        .SYNOPSIS
        Retrieves a context from the context vault.

        .DESCRIPTION
        Retrieves a context from the context vault.
        If no name is specified, all contexts from the context vault will be retrieved.

        .EXAMPLE
        Get-Context

        Get all contexts from the context vault.

        .EXAMPLE
        Get-Context -ID 'MySecret'

        Get the context called 'MySecret' from the vault.
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault.
        [Parameter()]
        [Alias('ContextID', 'Name')]
        [string] $ID
    )

    $contextVault = Get-ContextVault

    if (-not $ID) {
        Write-Verbose "Retrieving all contexts from [$($contextVault.Name)]"
        $contexts = Get-SecretInfo -Vault $contextVault.Name | Select-Object -ExpandProperty Name
    } else {
        Write-Verbose "Retrieving context [$ID] from [$($contextVault.Name)]"
        $contexts = Get-SecretInfo -Vault $contextVault.Name -Name $ID | Select-Object -ExpandProperty Name
    }

    Write-Verbose "Found [$($contexts.Count)] contexts in [$($contextVault.Name)]"
    $contexts | ForEach-Object {
        Write-Verbose " - $_"
        Get-Secret -Name $_ -Vault $contextVault.Name -AsPlainText | ConvertFrom-Json -Depth 10
    }
}

Register-ArgumentCompleter -CommandName Get-Context -ParameterName ID -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $commandAst, $fakeBoundParameter

    Get-SecretInfo -Vault $script:Config.VaultName -Name "$wordToComplete*" -Verbose:$false |
        ForEach-Object {
            $contextID = $_.ContextID
            [System.Management.Automation.CompletionResult]::new($contextID, $contextID, 'ParameterValue', $contextID)
        }
}
