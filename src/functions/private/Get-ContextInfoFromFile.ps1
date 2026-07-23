function Get-ContextInfoFromFile {
    <#
        .SYNOPSIS
        Reads and parses a context metadata file.

        .DESCRIPTION
        Reads a context metadata file from disk and returns a ContextInfo object.
        The returned Path always points to the actual file on disk, not the metadata payload.

        .EXAMPLE
        Get-ContextInfoFromFile -Path 'C:\Users\Jane\.contextvaults\MyVault\abc.json' -Vault 'MyVault'

        Parses the context metadata file and returns a ContextInfo instance.

        .OUTPUTS
        [ContextInfo]
    #>
    [OutputType([ContextInfo])]
    [CmdletBinding()]
    param(
        # Full path to the context metadata file.
        [Parameter(Mandatory)]
        [string] $Path,

        # The vault name the file belongs to.
        [Parameter(Mandatory)]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $content = Get-ContentNonLocking -Path $Path
        $rawContextInfo = $content | ConvertFrom-Json -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($rawContextInfo.ID)) {
            throw "Context metadata file '$Path' does not contain a valid ID."
        }

        [ContextInfo]::new([pscustomobject]@{
            ID      = [string]$rawContextInfo.ID
            Path    = $Path
            Vault   = $Vault
            Context = [string]$rawContextInfo.Context
        })
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
