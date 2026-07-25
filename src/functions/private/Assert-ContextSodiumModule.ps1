function Assert-ContextSodiumModule {
    <#
        .SYNOPSIS
        Ensures the required Sodium module version is available for context cryptography.

        .DESCRIPTION
        Validates that Sodium v2.2.5 or newer is loaded in the current session.
        Imports Sodium v2.2.5 if needed, and verifies required commands exist.

        .EXAMPLE
        Assert-ContextSodiumModule

        Ensures Sodium cryptography commands are available before encryption or decryption.
    #>
    [CmdletBinding()]
    param()

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        if ($script:ContextSodiumModuleReady) {
            return
        }

        $minimumVersion = [version]'2.2.5'
        $loadedSodium = Get-Module -Name Sodium | Sort-Object Version -Descending | Select-Object -First 1

        if ($loadedSodium -and $loadedSodium.Version -lt $minimumVersion) {
            $message = "Loaded Sodium version [$($loadedSodium.Version)] is older than required version [$minimumVersion]. "
            $message += "Start a new PowerShell session and import Sodium $minimumVersion."
            throw $message
        }

        if (-not $loadedSodium) {
            Import-Module -Name Sodium -RequiredVersion $minimumVersion -ErrorAction Stop
        }

        $requiredCommands = @(
            'New-SodiumKeyPair',
            'ConvertTo-SodiumSealedBox',
            'ConvertFrom-SodiumSealedBox'
        )

        foreach ($commandName in $requiredCommands) {
            if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
                throw "Required Sodium command '$commandName' is not available after loading the module."
            }
        }

        $script:ContextSodiumModuleReady = $true
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
