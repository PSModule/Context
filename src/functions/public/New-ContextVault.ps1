#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.2' }

function New-ContextVault {
    <#
        .SYNOPSIS
        Creates a new context vault.

        .DESCRIPTION
        Creates a new named context vault for storing encrypted contexts.
        Each vault has its own encryption key and storage directory.
        If this is the first vault created, it becomes the default vault.

        .PARAMETER Name
        The name of the vault to create.

        .PARAMETER Path
        Optional custom path for the vault directory. If not specified,
        the vault will be created in ~/.contextvaults/<Name>/.

        .EXAMPLE
        New-ContextVault -Name "WorkVault"

        Creates a new vault named "WorkVault" in the default location.

        .EXAMPLE
        New-ContextVault -Name "PersonalVault" -Path "C:\Secrets\"

        Creates a new vault named "PersonalVault" at the specified custom path.

        .OUTPUTS
        [PSCustomObject] Information about the created vault.

        .NOTES
        The first vault created automatically becomes the default vault.
        Each vault has its own unique encryption keys for security isolation.

        .LINK
        https://psmodule.io/Context/Functions/New-ContextVault/
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        # Optional custom path for the vault directory
        [Parameter()]
        [string] $Path
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        # Load current vault configuration
        $vaultConfig = Get-VaultConfig
        
        # Check if vault already exists
        if ($vaultConfig.Vaults.PSObject.Properties.Name -contains $Name) {
            throw "Vault '$Name' already exists"
        }

        # Determine vault path
        if ($Path) {
            $vaultPath = Join-Path -Path $Path -ChildPath $Name
        } else {
            $vaultPath = Join-Path -Path $script:Config.VaultsPath -ChildPath $Name
        }

        Write-Verbose "Creating vault '$Name' at path: [$vaultPath]"

        if ($PSCmdlet.ShouldProcess($Name, 'Create context vault')) {
            try {
                # Create vault directory
                if (-not (Test-Path $vaultPath)) {
                    Write-Verbose "Creating vault directory: [$vaultPath]"
                    $null = New-Item -Path $vaultPath -ItemType Directory -Force
                }

                # Create unique seed shard for this vault
                $seedShardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.SeedShardPath
                if (-not (Test-Path $seedShardPath)) {
                    Write-Verbose "Creating unique seed shard for vault '$Name'"
                    $keys = New-SodiumKeyPair
                    Set-Content -Path $seedShardPath -Value "$($keys.PrivateKey)$($keys.PublicKey)"
                }

                # Add vault to configuration
                $vaultInfo = [PSCustomObject]@{
                    Name = $Name
                    Path = $vaultPath
                    Created = Get-Date
                }

                # Create new vaults object with the additional vault
                if (-not $vaultConfig.Vaults) {
                    $vaultConfig.Vaults = @{}
                }
                
                # Convert to hashtable for easier manipulation
                $vaultsHashtable = @{}
                if ($vaultConfig.Vaults -is [PSCustomObject]) {
                    foreach ($property in $vaultConfig.Vaults.PSObject.Properties) {
                        $vaultsHashtable[$property.Name] = $property.Value
                    }
                } else {
                    $vaultsHashtable = $vaultConfig.Vaults
                }
                
                # Add the new vault
                $vaultsHashtable[$Name] = $vaultInfo
                
                # Convert back to PSCustomObject
                $vaultConfig.Vaults = [PSCustomObject]$vaultsHashtable

                # Set as default vault if this is the first vault
                if (-not $vaultConfig.DefaultVault) {
                    $vaultConfig.DefaultVault = $Name
                    Write-Verbose "Set '$Name' as default vault (first vault created)"
                }

                # Save configuration
                Set-VaultConfig -VaultConfig $vaultConfig

                # Update script config
                $script:Config.Vaults[$Name] = $vaultInfo

                Write-Verbose "Successfully created vault '$Name'"
                return $vaultInfo

            } catch {
                Write-Error "Failed to create vault '$Name': $_"
                throw
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}