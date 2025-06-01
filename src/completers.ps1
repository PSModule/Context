Register-ArgumentCompleter -CommandName 'Get-Context', 'Set-Context', 'Remove-Context', 'Rename-Context' -ParameterName 'ID' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter

    # Read context IDs directly from disk for tab completion
    if ($script:Config.Initialized -and (Test-Path $script:Config.VaultPath)) {
        $contextFiles = Get-ChildItem -Path $script:Config.VaultPath -Filter *.json -File -Recurse -ErrorAction SilentlyContinue
        $contextIds = @()
        foreach ($file in $contextFiles) {
            try {
                $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
                $contextIds += $contextInfo.ID
            } catch {
                # Skip invalid files
            }
        }
        $contextIds | Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
}
