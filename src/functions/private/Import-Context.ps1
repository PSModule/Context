#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.2' }

filter Import-Context {
    <#
        .SYNOPSIS
        Imports the context vault into memory.

        .DESCRIPTION
        Imports all context files from the context vault directory into memory.
        Each context is decrypted using the configured private key and stored
        in the script-wide context collection for further use.

        .EXAMPLE
        Import-Context

        Output:
        ```powershell
        VERBOSE: Importing contexts from vault: [C:\Vault]
        VERBOSE: Found [3] contexts
        VERBOSE: Importing context: [123456]
        ```

        Imports all contexts from the context vault into memory.

        .OUTPUTS
        [pscustomobject].

        .NOTES
        Represents the imported context object containing ID, Path, and Context properties.

        .LINK
        https://psmodule.io/Sodium/Functions/Import-Context/
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param()

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
        if (-not $script:Config.Initialized) {
            Set-ContextVault
        }
    }

    process {
        try {
            Write-Verbose "Importing contexts from vault: [$($script:Config.VaultPath)]"
            $contextFiles = Get-ChildItem -Path $script:Config.VaultPath -Filter *.json -File -Recurse
            Write-Verbose "Found [$($contextFiles.Count)] contexts"
            $contextFiles | ForEach-Object {
                $contextInfo = Get-Content -Path $_.FullName | ConvertFrom-Json
                Write-Verbose "Importing context: [$($contextInfo.ID)]"
                Write-Verbose ($contextInfo | Format-List | Out-String)
                $params = @{
                    SealedBox  = $contextInfo.Context
                    PublicKey  = $script:Config.PublicKey
                    PrivateKey = $script:Config.PrivateKey
                }
                $context = ConvertFrom-SodiumSealedBox @params
                $script:Contexts[$contextInfo.ID] = [pscustomobject]@{
                    ID      = $contextInfo.ID
                    Path    = $contextInfo.Path
                    Context = ConvertFrom-ContextJson -JsonString $context
                }
            }
        } catch {
            Write-Error $_
            throw 'Failed to get context'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
