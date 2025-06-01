Register-ArgumentCompleter -CommandName ($script:PSModuleInfo.FunctionsToExport) -ParameterName 'ID' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $contextInfos = Get-ContextInfo -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $contextInfos | Where-Object { $_.ID -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.ID, $_.ID, 'ParameterValue', $_.ID)
    }
}
