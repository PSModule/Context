Register-ArgumentCompleter -CommandName ($script:FunctionsToExport) -Name Vault -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Get all vault names from the vault configuration
    Get-ContextVault | Where-Object { $_.Name -like "$wordToComplete*" } | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}
