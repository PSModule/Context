function Get-ContextVault {
    <#
        .SYNOPSIS
        Lists all available context vaults.

        .DESCRIPTION
        Retrieves information about all configured context vaults,
        including their names, paths, and creation dates.
        Shows which vault is currently set as the default.

        .EXAMPLE
        Get-ContextVault

        Output:
        ```powershell
        Name      Path                                   Created                 IsDefault
        ----      ----                                   -------                 ---------
        Work      C:\Users\User\.contextvaults\Work      2024-01-15 10:30:00 AM  True
        Personal  C:\Users\User\.contextvaults\Personal  2024-01-15 11:15:00 AM  False
        ```

        Lists all available context vaults.

        .EXAMPLE
        Get-ContextVault -Name "Work"

        Output:
        ```powershell
        Name      Path                               Created                 IsDefault
        ----      ----                               -------                 ---------
        Work      C:\Users\User\.contextvaults\Work  2024-01-15 10:30:00 AM  True
        ```

        Gets information about a specific vault.

        .OUTPUTS
        [PSCustomObject[]]

        .NOTES
        Shows all registered vaults with their metadata and default status.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextVault/
    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        # The name of a vault.
        [Parameter()]
        [SupportsWildcards()]
        [string] $Name = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        Write-Debug "Retrieving vaults from: [$($script:Config.VaultsFolderPath)]"
        if (-not (Test-Path -Path $script:Config.VaultsFolderPath)) {
            Write-Verbose "Vaults folder does not exist: [$($script:Config.VaultsFolderPath)]"
            return @()
        }

        Get-ChildItem -Path $script:Config.VaultsFolderPath -Directory | Where-Object { $_.Name -like $Name } | ForEach-Object {
            $vaultConfigPath = Join-Path -Path $_.FullName -ChildPath 'config.json'
            if (Test-Path -Path $vaultConfigPath) {
                Get-Content -Path $vaultConfigPath | ConvertFrom-Json
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
