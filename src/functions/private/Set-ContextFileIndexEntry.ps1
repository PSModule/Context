function Set-ContextFileIndexEntry {
    <#
        .SYNOPSIS
        Adds or updates a context entry in the in-memory vault index.

        .DESCRIPTION
        Stores or updates an ID-to-file-path mapping in the in-memory cache for a vault.

        .EXAMPLE
        Set-ContextFileIndexEntry -Vault 'MyVault' -ID 'MyContext' -Path 'C:\vault\abc.json'

        Updates the in-memory index for the given vault.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'This private helper only mutates an in-memory cache.'
    )]
    [CmdletBinding()]
    param(
        # The vault name.
        [Parameter(Mandatory)]
        [string] $Vault,

        # The context ID.
        [Parameter(Mandatory)]
        [string] $ID,

        # The metadata file path.
        [Parameter(Mandatory)]
        [string] $Path
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        if ($null -eq $script:ContextFileIndexCache) {
            $script:ContextFileIndexCache = @{}
        }
    }

    process {
        if (-not $script:ContextFileIndexCache.ContainsKey($Vault)) {
            $vaultIndex = [System.Collections.Generic.Dictionary[string, string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
            $script:ContextFileIndexCache[$Vault] = $vaultIndex
        }

        $script:ContextFileIndexCache[$Vault][$ID] = $Path
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
