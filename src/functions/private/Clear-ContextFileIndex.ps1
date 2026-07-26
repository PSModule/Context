function Clear-ContextFileIndex {
    <#
        .SYNOPSIS
        Clears in-memory vault index entries.

        .DESCRIPTION
        Removes one or more vault entries from the in-memory context file index cache.

        .EXAMPLE
        Clear-ContextFileIndex -Vault 'MyVault'

        Clears the in-memory index for 'MyVault'.
    #>
    [CmdletBinding()]
    param(
        # One or more vault names to clear from cache.
        [Parameter(Mandatory)]
        [string[]] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        if ($null -eq $script:ContextFileIndexCache) {
            return
        }

        foreach ($vaultName in $Vault) {
            $null = $script:ContextFileIndexCache.Remove($vaultName)
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
