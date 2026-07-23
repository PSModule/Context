function Get-ContextVaultKeyPair {
    <#
        .SYNOPSIS
        Retrieves the public and private keys from the context vault.

        .DESCRIPTION
        Retrieves the public and private keys used for encrypting contexts in the context vault.
        The keys are stored in a secure manner and can be used to encrypt or decrypt contexts.

        .EXAMPLE
        Get-ContextVaultKeyPair

        Output:
        ```powershell
        PublicKey  : <public key>
        PrivateKey : <private key>
        ```

        Retrieves the public and private keys from the context vault.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve the keys from.
        [Parameter(Mandatory)]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
        Assert-ContextSodiumModule
        if ($null -eq $script:ContextVaultKeyPairCache) {
            $script:ContextVaultKeyPairCache = @{}
        }
    }

    process {
        $vaultObject = Set-ContextVault -Name $Vault -PassThru
        $shardPath = Join-Path -Path $vaultObject.Path -ChildPath $script:Config.ShardFileName

        # Use non-locking file reading to allow concurrent access
        try {
            $fileShard = (Get-ContentNonLocking -Path $shardPath).Trim()
        } catch {
            throw "[$stackPath] - Unable to read shard file '$shardPath': $($_.Exception.Message)"
        }

        if ($script:ContextVaultKeyPairCache.ContainsKey($vaultObject.Name)) {
            $cachedEntry = $script:ContextVaultKeyPairCache[$vaultObject.Name]
            if ($cachedEntry.Shard -eq $fileShard) {
                return $cachedEntry.Keys
            }
        }

        $machineShard = [System.Environment]::MachineName
        $userShard = [System.Environment]::UserName
        #$userInputShard = Read-Host -Prompt 'Enter a seed shard' # Eventually 4 shards. +1 for user input.
        $seed = $machineShard + $userShard + $fileShard # + $userInputShard
        $keys = New-SodiumKeyPair -Seed $seed
        $script:ContextVaultKeyPairCache[$vaultObject.Name] = [pscustomobject]@{
            Shard = $fileShard
            Keys  = $keys
        }
        return $keys
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
