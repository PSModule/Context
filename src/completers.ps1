# Context ID completion for context functions
Register-ArgumentCompleter -CommandName ($script:PSModuleInfo.FunctionsToExport) -ParameterName 'ID' -ScriptBlock {
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

# Vault name completion for vault functions and context functions
Register-ArgumentCompleter -CommandName ($script:PSModuleInfo.FunctionsToExport | Where-Object {
        $_ -like '*-ContextVault' }) -ParameterName 'Name' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}

# Vault parameter completion for context functions
Register-ArgumentCompleter -CommandName ($script:PSModuleInfo.FunctionsToExport | Where-Object {
        $_ -like '*-Context' }) -ParameterName 'Vault' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}

# Source and Target vault completion for Move-Context
Register-ArgumentCompleter -CommandName 'Move-Context' -ParameterName 'SourceVault' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', "Source Vault: $($_.Name) - $($_.Description)")
    }
}

Register-ArgumentCompleter -CommandName 'Move-Context' -ParameterName 'TargetVault' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', "Target Vault: $($_.Name) - $($_.Description)")
    }
}
