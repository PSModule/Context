#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.SecretManagement'; RequiredVersion = '1.1.2' }

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
            Write-Verbose "Importing contexts: [$($script:Config.SecretPrefix)*] from vault: $($script:Config.VaultName)"
            $secretInfos = Get-SecretInfo -Name "$($script:Config.SecretPrefix)*" -Vault $script:Config.VaultName -Verbose:$false
            Write-Verbose "Found [$($secretInfos.Count)] secrets"
            $secretInfos | ForEach-Object {
                Write-Verbose "- [$($_.Name)]"
                $secretJson = $_ | Get-Secret -AsPlainText -Verbose:$false
                $script:Contexts[$_.Name] = ConvertFrom-ContextJson -JsonString $secretJson
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
