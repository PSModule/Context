#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.2' }

function Set-ContextVault {
    <#
        .SYNOPSIS
        Sets the context vault.

        .DESCRIPTION
        Sets the context vault. If the vault does not exist, it will be initialized.
        Once the context vault is set, it will be imported into memory.
        The vault consists of multiple security shards, including a machine-specific shard,
        a user-specific shard, and a seed shard stored within the vault directory.

        .EXAMPLE
        Set-ContextVault

        Initializes or loads the context vault, setting up necessary key pairs.

        .OUTPUTS
        None.

        .NOTES
        This function modifies the script-scoped configuration and imports the vault.

        .LINK
        https://psmodule.io/Context/Functions/Set-ContextVault
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            Write-Verbose "Loading context vault from [$($script:Config.VaultPath)]"
            $vaultExists = Test-Path $script:Config.VaultPath
            Write-Verbose "Vault exists: $vaultExists"

            if (-not $vaultExists) {
                Write-Verbose 'Initializing new vault'
                $null = New-Item -Path $script:Config.VaultPath -ItemType Directory
            }

            Write-Verbose 'Checking for existing seed shard'
            $seedShardPath = Join-Path -Path $script:Config.VaultPath -ChildPath $script:Config.SeedShardPath
            $seedShardExists = Test-Path $seedShardPath
            Write-Verbose "Seed shard exists: $seedShardExists"

            if (-not $seedShardExists) {
                Write-Verbose 'Creating new seed shard'
                $keys = New-SodiumKeyPair
                Set-Content -Path $seedShardPath -Value "$($keys.PrivateKey)$($keys.PublicKey)"
            }

            $seedShard = Get-Content -Path $seedShardPath
            $machineShard = [System.Environment]::MachineName
            $userShard = [System.Environment]::UserName
            #$userInputShard = Read-Host -Prompt 'Enter a seed shard' # Eventually 4 shards. +1 for user input.
            $seed = $machineShard + $userShard + $seedShard + $userInputShard
            $keys = New-SodiumKeyPair -Seed $seed
            $script:Config.PrivateKey = $keys.PrivateKey
            $script:Config.PublicKey = $keys.PublicKey
            Write-Verbose 'Vault initialized'
            $script:Config.Initialized = $true
        } catch {
            Write-Error $_
            throw 'Failed to initialize context vault'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
        Import-Context
    }
}
