#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.1.1' }

function Set-ContextVault {
    <#
        .SYNOPSIS
        Sets the context vault.

        .DESCRIPTION
        Sets the context vault. If the vault does not exist, it will be initialized.
        Once the ContextVault is set, it will be imported into memory.

        .EXAMPLE
        Set-ContextVault

        Sets the context vault.
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

            Write-Verbose 'Checking for existing seed shard exists'
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
