function Get-ContextVault {
    <#
        .SYNOPSIS
        Lists all available context vaults.

        .DESCRIPTION
        Retrieves information about all configured context vaults,
        including their names, paths, and creation dates.
        Shows which vault is currently set as the default.

        .PARAMETER Name
        Optional name filter to get information about a specific vault.

        .EXAMPLE
        Get-ContextVault

        Output:
        ```powershell
        Name         Path                          Created              IsDefault
        ----         ----                          -------              ---------
        WorkVault    C:\Users\User\.contextvaults\WorkVault    2024-01-15 10:30:00 AM    True
        PersonalVault C:\Users\User\.contextvaults\PersonalVault 2024-01-15 11:15:00 AM    False
        ```

        Lists all available context vaults.

        .EXAMPLE
        Get-ContextVault -Name "WorkVault"

        Output:
        ```powershell
        Name         Path                          Created              IsDefault
        ----         ----                          -------              ---------
        WorkVault    C:\Users\User\.contextvaults\WorkVault    2024-01-15 10:30:00 AM    True
        ```

        Gets information about a specific vault.

        .OUTPUTS
        [PSCustomObject[]] Array of vault information objects.

        .NOTES
        Shows all registered vaults with their metadata and default status.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextVault/
    #>
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param(
        # Optional name filter for a specific vault
        [Parameter()]
        [string] $Name
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            # Load vault configuration
            $vaultConfig = Get-VaultConfig
            
            if (-not $vaultConfig.Vaults -or $vaultConfig.Vaults.PSObject.Properties.Count -eq 0) {
                Write-Verbose "No vaults found"
                return @()
            }

            $results = @()
            
            foreach ($vaultProperty in $vaultConfig.Vaults.PSObject.Properties) {
                $vaultInfo = $vaultProperty.Value
                $vaultName = $vaultProperty.Name
                
                # Skip if Name filter is specified and doesn't match
                if ($Name -and $vaultName -ne $Name) {
                    continue
                }
                
                $result = [PSCustomObject]@{
                    Name = $vaultName
                    Path = $vaultInfo.Path
                    Created = $vaultInfo.Created
                    IsDefault = ($vaultName -eq $vaultConfig.DefaultVault)
                }
                
                $results += $result
            }
            
            # If Name was specified but no matching vault found
            if ($Name -and $results.Count -eq 0) {
                Write-Warning "Vault '$Name' not found"
            }
            
            return $results

        } catch {
            Write-Error "Failed to retrieve vault information: $_"
            throw
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}