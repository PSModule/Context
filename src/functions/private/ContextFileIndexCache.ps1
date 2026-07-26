function Get-ContextFileIndex {
    <#
        .SYNOPSIS
        Gets a cached context file index for a vault.

        .DESCRIPTION
        Builds (or returns) an in-memory index of context IDs to metadata file paths for a vault.
        This avoids repeated full vault scans for exact-ID lookups in hot paths.

        .EXAMPLE
        Get-ContextFileIndex -Vault 'MyVault' -VaultPath 'C:\Users\Jane\.contextvaults\MyVault'

        Returns a dictionary where keys are context IDs and values are metadata file paths.

        .OUTPUTS
        [System.Collections.Generic.Dictionary[string,string]]
    #>
    [OutputType([System.Collections.Generic.Dictionary[string, string]])]
    [CmdletBinding()]
    param(
        # The vault name.
        [Parameter(Mandatory)]
        [string] $Vault,

        # The full path to the vault folder.
        [Parameter(Mandatory)]
        [string] $VaultPath,

        # Rebuilds the index from disk even if cached.
        [Parameter()]
        [switch] $Refresh
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        if ($null -eq $script:ContextFileIndexCache) {
            $script:ContextFileIndexCache = @{}
        }
    }

    process {
        if (-not $Refresh -and $script:ContextFileIndexCache.ContainsKey($Vault)) {
            return $script:ContextFileIndexCache[$Vault]
        }

        $index = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $files = Get-ChildItem -Path $VaultPath -Filter *.json -File -ErrorAction SilentlyContinue

        foreach ($file in $files) {
            try {
                $contextInfo = Get-ContextInfoFromFile -Path $file.FullName -Vault $Vault -ErrorAction Stop
                $index[$contextInfo.ID] = $contextInfo.Path
            } catch {
                Write-Warning "[$stackPath] - Failed to index context file '$($file.FullName)': $($_.Exception.Message)"
            }
        }

        $script:ContextFileIndexCache[$Vault] = $index
        return $index
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}

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
