function Complete-ContextID {
    <#
        .SYNOPSIS
        Completion function for Context ID parameter.

        .DESCRIPTION
        Provides tab completion for Context IDs, optionally filtered by vault.
    #>
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vault = $fakeBoundParameter['Vault']
    $contextInfos = if ($vault) {
        Get-ContextInfo -Vault $vault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    } else {
        Get-ContextInfo -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    }
    $contextInfos | Where-Object { $_.ID -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.ID, $_.ID, 'ParameterValue', $_.ID)
    }
}
