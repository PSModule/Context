function Remove-ContextFileIndexEntry {
    <#
        .SYNOPSIS
        Removes a context entry from the in-memory vault index.

        .DESCRIPTION
        Removes an ID mapping from the in-memory index for a vault.

        .EXAMPLE
        Remove-ContextFileIndexEntry -Vault 'MyVault' -ID 'MyContext'

        Removes the mapping for the specified context ID.
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
        [string] $ID
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        if ($null -eq $script:ContextFileIndexCache -or -not $script:ContextFileIndexCache.ContainsKey($Vault)) {
            return
        }

        $null = $script:ContextFileIndexCache[$Vault].Remove($ID)
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
