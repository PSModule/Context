Register-ArgumentCompleter -CommandName 'Get-Context', 'Set-Context', 'Remove-Context', 'Rename-Context' -ParameterName 'ID' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    # Use Get-ContextInfo to get available context IDs for tab completion
    try {
        $contextInfos = Get-ContextInfo -ErrorAction SilentlyContinue
        $contextInfos | Where-Object { $_.ID -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_.ID, $_.ID, 'ParameterValue', $_.ID)
            }
    } catch {
        # Silently fail if Get-ContextInfo is not available or vault is not accessible
    }
}
