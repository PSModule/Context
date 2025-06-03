function Get-ContextInfo {
    <#
        .SYNOPSIS
        Retrieves info about a context from the context vault.

        .DESCRIPTION
        Retrieves info about context files directly from the vault directory on disk.
        If no ID is specified, all available info on contexts will be returned.
        Wildcards are supported to match multiple contexts.
        Only metadata (ID and Path) is returned without decrypting the context contents.

        .EXAMPLE
        Get-ContextInfo

        Output:
        ```powershell
        ID   : MySettings
        Path : ...\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json

        ID   : MyConfig
        Path : ...\feacc853-5bea-48d1-b751-41ce9768d48e.json

        ID   : MySecret
        Path : ...\3e223259-f242-4e97-91c8-f0fd054cfea7.json

        ID   : Data
        Path : ...\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json

        ID   : PSModule.GitHub
        Path : ...\feacc853-5bea-48d1-b751-41ce9768d48e.json
        ```

        Retrieves all contexts from the context vault (directly from disk).

        .EXAMPLE
        Get-ContextInfo -ID 'MySecret'

        Output:
        ```powershell
        ID   : MySecret
        Path : ...\3e223259-f242-4e97-91c8-f0fd054cfea7.json
        ```

        Retrieves the context called 'MySecret' from the context vault (directly from disk).

        .EXAMPLE
        'My*' | Get-ContextInfo

        Output:
        ```powershell
        ID   : MyConfig
        Path : .../feacc853-5bea-48d1-b751-41ce9768d48e.json

        ID   : MySecret
        Path : .../3e223259-f242-4e97-91c8-f0fd054cfea7.json

        ID   : MySettings
        Path : .../b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json
        ```

        Retrieves all contexts that start with 'My' from the context vault (directly from disk).

        .OUTPUTS
        [System.Object]

        .NOTES
        Returns a list of context information matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding path to where the context is stored on disk.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextInfo/
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault. Supports wildcards.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [AllowEmptyString()]
        [SupportsWildcards()]
        [string[]] $ID = '*',

        # The name of the vault to retrieve context info from.
        [Parameter()]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"

        if ($Vault) {
            # Initialize the specified vault
            Set-ContextVault -Name $Vault
        } elseif (-not $script:Config.Initialized) {
            # Fall back to legacy vault if no vault specified
            Set-ContextVault
        }
    }

    process {
        Write-Verbose "Retrieving context info - ID: [$ID] from vault: [$(if ($Vault) { $Vault } else { 'legacy' })]"
        
        # Determine the search path
        if ($Vault) {
            $searchPath = Join-Path -Path $script:Config.ContextVaultsPath -ChildPath "Vaults" | Join-Path -ChildPath $Vault | Join-Path -ChildPath $script:Config.ContextPath
        } else {
            $searchPath = $script:Config.VaultPath
        }

        if (-not (Test-Path $searchPath)) {
            Write-Verbose "Search path does not exist: $searchPath"
            return
        }

        foreach ($item in $ID) {
            # Read context files directly from disk instead of using in-memory cache
            $contextFiles = Get-ChildItem -Path $searchPath -Filter *.json -File -Recurse
            foreach ($file in $contextFiles) {
                try {
                    $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
                    if ($contextInfo.ID -like $item) {
                        # Return only metadata (ID and Path), don't decrypt the Context property
                        [PSCustomObject]@{
                            ID   = $contextInfo.ID
                            Path = $contextInfo.Path
                        }
                    }
                } catch {
                    Write-Warning "Failed to read context file: $($file.FullName). Error: $_"
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
