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
