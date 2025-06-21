$contextVaultNameCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter
    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}

$contextVaultFunctions = ($script:PSModuleInfo.FunctionsToExport | Where-Object { $_ -like '*ContextVault*' })

Register-ArgumentCompleter -CommandName $script:PSModuleInfo.FunctionsToExport -ParameterName 'Vault' -ScriptBlock $contextVaultNameCompleter
Register-ArgumentCompleter -CommandName $contextVaultFunctions -ParameterName 'Name' -ScriptBlock $contextVaultNameCompleter
