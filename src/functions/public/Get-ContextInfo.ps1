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
        ID                 Path
        --                 ----
        MySettings         C:\Users\<username>\.contextvaults\Vaults\Contexts\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json

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
        [PSCustomObject]

        .NOTES
        Returns a list of context information matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding path to where the context is stored on disk.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextInfo/
    #>
    [OutputType([PSCustomObject])]
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
        $debug = $DebugPreference -eq 'Continue'
        if ($debug) {
            $stackPath = Get-PSCallStackPath
            Write-Debug "[$stackPath] - Start"
        }
    }

    process {
        $vaults = foreach ($vaultName in $Vault) {
            Get-ContextVault -Name $vaultName -ErrorAction Stop
        }
        if ($debug) {
            Write-Debug "[$stackPath] - Found $($vaults.Count) vault(s) matching '$($Vault -join ', ')'."
        }

        $files = foreach ($vaultObject in $vaults) {
            Get-ChildItem -Path $vaultObject.Path -Filter *.json -File
        }
        if ($debug) {
            Write-Debug "[$stackPath] - Found $($files.Count) context file(s) in vault(s)."
        }

        foreach ($file in $files) {
            $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
            if ($debug) {
                Write-Debug "[$stackPath] - Processing file: $($file.FullName)"
                $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug "[$stackPath] - $_" }
            }
            if ($contextInfo.ID -like $ID) {
                Write-Output $contextInfo
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
