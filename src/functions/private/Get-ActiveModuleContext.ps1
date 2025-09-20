function Get-ActiveModuleContext {
    <#
        .SYNOPSIS
        Gets the name of the active module context for a vault.

        .DESCRIPTION
        Reads the active module context name from the 'active-context' file in the module directory.
        If the file doesn't exist or is invalid, returns 'default'.

        .PARAMETER VaultPath
        The path to the vault directory.

        .EXAMPLE
        Get-ActiveModuleContext -VaultPath 'C:\Users\John\.contextvaults\MyVault'
        
        Returns the name of the active module context, or 'default' if none is set.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $VaultPath
    )

    $activeContextFile = Join-Path -Path $VaultPath -ChildPath 'module' | Join-Path -ChildPath 'active-context'
    
    if (Test-Path $activeContextFile) {
        try {
            $contextName = (Get-Content -Path $activeContextFile -Raw).Trim()
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

function Set-ActiveModuleContext {
    <#
        .SYNOPSIS
        Sets the active module context for a vault.

        .DESCRIPTION
        Writes the active module context name to the 'active-context' file in the module directory.

        .PARAMETER VaultPath
        The path to the vault directory.

        .PARAMETER ContextName
        The name of the context to set as active.

        .EXAMPLE
        Set-ActiveModuleContext -VaultPath 'C:\Users\John\.contextvaults\MyVault' -ContextName 'staging'
        
        Sets 'staging' as the active module context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $VaultPath,

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