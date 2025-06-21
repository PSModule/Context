$script:CompleteContextVaultName = {
    param(
        $commandName,
        $parameterName,
        $wordToComplete,
        $commandAst,
        $fakeBoundParameter
    )
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}
