function Set-ActiveModuleContext {
    <#
        .SYNOPSIS
        Sets the active module context for a vault.

        .DESCRIPTION
        Writes the active module context name to the 'active-context' file in the module directory.

        .EXAMPLE
        Set-ActiveModuleContext -VaultPath 'C:\Users\John\.contextvaults\MyVault' -ContextName 'staging'
        
        Sets 'staging' as the active module context.
    #>
    [CmdletBinding()]
    param(
        # The path to the vault directory.
        [Parameter(Mandatory)]
        [string] $VaultPath,

        # The name of the context to set as active.
        [Parameter(Mandatory)]
        [string] $ContextName
    )

    $moduleDir = Join-Path -Path $VaultPath -ChildPath 'module'
    $activeContextFile = Join-Path -Path $moduleDir -ChildPath 'active-context'
    
    # Ensure module directory exists
    if (-not (Test-Path $moduleDir)) {
        $null = New-Item -Path $moduleDir -ItemType Directory -Force
    }
    
    try {
        Set-Content -Path $activeContextFile -Value $ContextName -NoNewline
        Write-Verbose "Set active module context to: $ContextName"
    } catch {
        throw "Failed to set active context: $_"
    }
}