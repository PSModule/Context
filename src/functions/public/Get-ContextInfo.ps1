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
        MyConfig           C:\Users\<username>\.contextvaults\Vaults\Contexts\feacc853-5bea-48d1-b751-41ce9768d48e.json
        MySecret           C:\Users\<username>\.contextvaults\Vaults\Contexts\3e223259-f242-4e97-91c8-f0fd054cfea7.json
        Data               C:\Users\<username>\.contextvaults\Vaults\Contexts\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json
        PSModule.GitHub    C:\Users\<username>\.contextvaults\Vaults\Contexts\feacc853-5bea-48d1-b751-41ce9768d48e.json
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
        ID                 Path
        --                 ----
        MyConfig           C:\Users\<username>\.contextvaults\Vaults\Contexts\feacc853-5bea-48d1-b751-41ce9768d48e.json
        MySecret           C:\Users\<username>\.contextvaults\Vaults\Contexts\3e223259-f242-4e97-91c8-f0fd054cfea7.json
        MySettings         C:\Users\<username>\.contextvaults\Vaults\Contexts\b7c01dbe-bccd-4c7e-b075-c5aac1c43b1a.json
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
        [ArgumentCompleter({ & $script:CompleteContextID @args })]
        [SupportsWildcards()]
        [string[]] $ID = '*',

        # The name of the vault to retrieve context info from. Supports wildcards.
        [Parameter()]
        [ArgumentCompleter({ & $script:CompleteContextVaultName @args })]
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
            $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
            Write-Verbose "[$stackPath] - Processing file: $($file.FullName)"
            $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
            foreach ($IDItem in $ID) {
                if ($contextInfo.ID -like $IDItem) {
                    $contextInfo
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
