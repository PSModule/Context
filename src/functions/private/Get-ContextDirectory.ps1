function Get-ContextDirectory {
    <#
        .SYNOPSIS
        Gets the appropriate directory path for a context based on its type.

        .DESCRIPTION
        Returns the directory path where contexts of the specified type should be stored.
        For User contexts, returns the 'user' subdirectory.
        For Module contexts, returns the 'module' subdirectory.

        .EXAMPLE
        Get-ContextDirectory -VaultPath 'C:\Users\John\.contextvaults\MyVault' -Type 'User'
        
        Returns: C:\Users\John\.contextvaults\MyVault\user

        .EXAMPLE
        Get-ContextDirectory -VaultPath 'C:\Users\John\.contextvaults\MyVault' -Type 'Module'
        
        Returns: C:\Users\John\.contextvaults\MyVault\module
    #>
    [CmdletBinding()]
    param(
        # The path to the vault directory.
        [Parameter(Mandatory)]
        [string] $VaultPath,

        # The type of context: 'User' or 'Module'.
        [Parameter(Mandatory)]
        [ValidateSet('User', 'Module')]
        [string] $Type
    )

    $subdirectory = if ($Type -eq 'Module') { 'module' } else { 'user' }
    return Join-Path -Path $VaultPath -ChildPath $subdirectory
}