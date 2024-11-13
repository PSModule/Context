function Get-Context {
    <#
        .SYNOPSIS
        Retrieves a context from the context vault.

        .DESCRIPTION
        Retrieves contexts from a specified context vault. You can specify the name of the context to retrieve or use a wildcard pattern to retrieve
        multiple contexts. If no name is specified, all contexts from the context vault will be retrieved.
        Optionally, you can choose to retrieve the contexts as plain text by providing the -AsPlainText switch.

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
        # The name of the context to retrieve from the vault. Supports wildcard patterns.
        [Parameter()]
        [SupportsWildcards()]
        [Alias('Context', 'ContextName')]
        [string] $Name = '*',

        # Switch to retrieve the contexts as plain text.
        [Parameter()]
        [switch] $AsPlainText
    )

    $contextVault = Get-ContextVault

    Write-Verbose "Retrieving contexts from vault [$($contextVault.Name)]"
    $contexts = Get-SecretInfo -Vault $contextVault.Name
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
                Name   = $context.Name
                Secret = Get-Secret -Name $context.Name -Vault $contextVault.Name -AsPlainText:$AsPlainText
            }
        )
    }
}

# Register tab completer for the Name parameter
Register-ArgumentCompleter -CommandName Get-Context -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $null)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters # Suppress unused variable warning
    $contextVault = Get-SecretVault | Where-Object { $_.Name -eq $script:Config.Context.VaultName }
    if (-not $contextVault) {
        return
    }

    $contexts = Get-SecretInfo -Vault $contextVault.Name
    if (-not $contexts) {
        return
    }

    $contexts | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}
