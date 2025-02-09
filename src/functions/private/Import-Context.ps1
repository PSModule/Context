#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.1' }

filter Import-Context {
    <#
        .SYNOPSIS
        Imports the context vault into memory.

        .DESCRIPTION
        Imports the context vault into memory.

        .EXAMPLE
        Import-Context

        Imports all contexts from the context vault into memory.
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
                    ID       = $contextInfo.ID
                    FileName = $contextInfo.FileName
                    Context  = ConvertFrom-ContextJson -JsonString $context
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
