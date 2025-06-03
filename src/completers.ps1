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
Register-ArgumentCompleter -CommandName ('New-ContextVault', 'Get-ContextVault', 'Remove-ContextVault', 'Rename-ContextVault', 'Reset-ContextVault') -ParameterName 'Name' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', "Vault: $($_.Name) - $($_.Description)")
    }
}

# Vault parameter completion for context functions
Register-ArgumentCompleter -CommandName ('Get-Context', 'Set-Context', 'Remove-Context', 'Rename-Context', 'Get-ContextInfo', 'Move-Context') -ParameterName 'Vault' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', "Vault: $($_.Name) - $($_.Description)")
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

# NewName completion for Rename-ContextVault (exclude existing vault names)
Register-ArgumentCompleter -CommandName 'Rename-ContextVault' -ParameterName 'NewName' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    # Provide common naming suggestions
    @('Module1', 'Module2', 'GitHub', 'Azure', 'AWS', 'Production', 'Development', 'Testing') | 
    Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', "Suggested vault name")
    }
}
