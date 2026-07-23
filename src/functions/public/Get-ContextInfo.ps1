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
        $idPatterns = [System.Collections.Generic.List[System.Management.Automation.WildcardPattern]]::new()
        $exactIds = [System.Collections.Generic.List[string]]::new()
        $hasWildcardId = $false

        foreach ($idItem in $ID) {
            if ([string]::IsNullOrWhiteSpace($idItem)) {
                continue
            }

            $wildcardPattern = [System.Management.Automation.WildcardPattern]::new($idItem, [System.Management.Automation.WildcardOptions]::IgnoreCase)
            $null = $idPatterns.Add($wildcardPattern)

            if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($idItem)) {
                $hasWildcardId = $true
                continue
            }

            if (-not $exactIds.Contains($idItem)) {
                $null = $exactIds.Add($idItem)
            }
        }

        if ($idPatterns.Count -eq 0) {
            return
        }

        $vaults = foreach ($vaultName in $Vault) {
            Get-ContextVault -Name $vaultName -ErrorAction Stop
        }
        Write-Verbose "[$stackPath] - Found $($vaults.Count) vault(s) matching '$($Vault -join ', ')'."

        foreach ($vaultObject in $vaults) {
            $contextIndex = Get-ContextFileIndex -Vault $vaultObject.Name -VaultPath $vaultObject.Path

            if (-not $hasWildcardId -and $exactIds.Count -gt 0) {
                foreach ($exactId in $exactIds) {
                    $contextPath = $null
                    if (-not $contextIndex.TryGetValue($exactId, [ref]$contextPath)) {
                        continue
                    }

                    if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) {
                        Remove-ContextFileIndexEntry -Vault $vaultObject.Name -ID $exactId
                        continue
                    }

                    try {
                        $contextInfo = Get-ContextInfoFromFile -Path $contextPath -Vault $vaultObject.Name -ErrorAction Stop
                        Set-ContextFileIndexEntry -Vault $vaultObject.Name -ID $contextInfo.ID -Path $contextInfo.Path
                    } catch {
                        Write-Warning "[$stackPath] - Error reading context file '$contextPath': $($_.Exception.Message)"
                        Remove-ContextFileIndexEntry -Vault $vaultObject.Name -ID $exactId
                        continue
                    }

                    if ($contextInfo.ID -like $exactId) {
                        $contextInfo
                    } else {
                        Remove-ContextFileIndexEntry -Vault $vaultObject.Name -ID $exactId
                    }
                }

                continue
            }

            $files = Get-ChildItem -Path $vaultObject.Path -Filter *.json -File
            Write-Verbose "[$stackPath] - Found $($files.Count) context file(s) in vault [$($vaultObject.Name)]."

            foreach ($file in $files) {
                try {
                    $contextInfo = Get-ContextInfoFromFile -Path $file.FullName -Vault $vaultObject.Name -ErrorAction Stop
                    Set-ContextFileIndexEntry -Vault $vaultObject.Name -ID $contextInfo.ID -Path $contextInfo.Path
                } catch {
                    Write-Warning "[$stackPath] - Error reading context file '$($file.FullName)': $($_.Exception.Message)"
                    continue
                }

                if ($VerbosePreference -eq 'Continue') {
                    Write-Verbose "[$stackPath] - Processing file: $($file.FullName)"
                    $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath] $_" }
                }

                foreach ($pattern in $idPatterns) {
                    if ($pattern.IsMatch($contextInfo.ID)) {
                        $contextInfo
                        break
                    }
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
