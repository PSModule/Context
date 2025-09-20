function Get-ContextInfo {
    <#
        .SYNOPSIS
        Retrieves info about a context from a context vault.

        .DESCRIPTION
        Retrieves info about contexts directly from a ContextVault.
        If no ID is specified, info on all contexts will be returned.
        Wildcards are supported to match multiple contexts.
        Only metadata (ID and Path) is returned without decrypting the context contents.

        .EXAMPLE
        Get-ContextInfo

        Output:
        ```powershell
        ID                 Vault
        --                 -----
        MySettings         MyVault
        MyConfig           MyVault
        MySecret           MyVault
        Data               MyVault
        PSModule.GitHub    MyVault
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
        ID                 Vault
        --                 -----
        MyConfig           MyVault
        MySecret           MyVault
        MySettings         MyVault
        ```

        Retrieves all contexts that start with 'My' from the context vault (directly from disk).

        .OUTPUTS
        [ContextInfo]

        .NOTES
        Returns a list of context information matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding path to where the context is stored on disk.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextInfo/
    #>
    [OutputType([ContextInfo])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault. Supports wildcards.
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $ID = '*',

        # The name of the vault to retrieve context info from. Supports wildcards.
        [Parameter()]
        [string[]] $Vault = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $vaults = foreach ($vaultName in $Vault) {
            Get-ContextVault -Name $vaultName -ErrorAction Stop
        }
        Write-Verbose "[$stackPath] - Found $($vaults.Count) vault(s) matching '$($Vault -join ', ')'."

        $files = foreach ($vaultObject in $vaults) {
            Get-ChildItem -Path $vaultObject.Path -Filter *.json -File
        }
        Write-Verbose "[$stackPath] - Found $($files.Count) context file(s) in vault(s)."

        foreach ($file in $files) {
            # Use robust file reading with explicit sharing to ensure no file locking during reads
            try {
                $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
                $contextInfo = $content | ConvertFrom-Json
            } catch [System.IO.IOException] {
                Write-Warning "[$stackPath] - IO error reading context file '$($file.FullName)': $($_.Exception.Message). Falling back to Get-Content."
                $contextInfo = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            } catch {
                Write-Warning "[$stackPath] - Error reading context file '$($file.FullName)': $($_.Exception.Message)"
                continue
            }
            Write-Verbose "[$stackPath] - Processing file: $($file.FullName)"
            $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
            foreach ($IDItem in $ID) {
                if ($contextInfo.ID -like $IDItem) {
                    [ContextInfo]::new($contextInfo)
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
