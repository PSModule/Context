function Get-ActiveModuleContext {
    <#
        .SYNOPSIS
        Gets the name of the active module context for a vault.

        .DESCRIPTION
        Reads the active module context name from the 'active-context' file in the module directory.
        If the file doesn't exist or is invalid, returns 'default'.

        .EXAMPLE
        Get-ActiveModuleContext -VaultPath 'C:\Users\John\.contextvaults\MyVault'
        
        Returns the name of the active module context, or 'default' if none is set.
    #>
    [CmdletBinding()]
    param(
        # The path to the vault directory.
        [Parameter(Mandatory)]
        [string] $VaultPath
    )

    $activeContextFile = Join-Path -Path $VaultPath -ChildPath 'module' | Join-Path -ChildPath 'active-context'
    
    if (Test-Path $activeContextFile) {
        try {
            $contextName = (Get-ContentNonLocking -Path $activeContextFile).Trim()
            if ([string]::IsNullOrWhiteSpace($contextName)) {
                return 'default'
            }
            return $contextName
        } catch {
            Write-Warning "Failed to read active context file: $_"
            return 'default'
        }
    }
    
    return 'default'
}